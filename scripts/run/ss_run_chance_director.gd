class_name SSRunChanceDirector
extends RefCounted

const MISS_RECOVERY_THRESHOLD := 2
const BUDGET_MIN := 1
const BUDGET_MAX := 2

var data_registry
var last_roll: Dictionary = {}

func setup(registry) -> void:
	data_registry = registry

func roll_for_run(game_state, rng: RandomNumberGenerator) -> Dictionary:
	return _roll_for_run(game_state, rng)

func debug_roll_for_run_with_value(game_state, roll_value: float, budget_total: int = BUDGET_MIN) -> Dictionary:
	return _roll_for_run(game_state, null, clampf(roll_value, 0.0, 1.0), clampi(budget_total, BUDGET_MIN, BUDGET_MAX))

func _roll_for_run(game_state, rng: RandomNumberGenerator, forced_roll_value: Variant = null, forced_budget_total: int = 0) -> Dictionary:
	var state := _read_state(game_state)
	var current_day: int = int(state.get("current_day", 1))
	var last_roll_day: int = int(state.get("last_roll_day", 0))
	var cached: Dictionary = state.get("last_roll_result", {})
	if last_roll_day == current_day and not cached.is_empty():
		last_roll = cached.duplicate(true)
		last_roll["reused"] = true
		return last_roll.duplicate(true)

	var stored_chance_tier: int = maxi(0, int(state.get("chance_tier", 0)))
	var stored_miss_count: int = maxi(0, int(state.get("miss_count", 0)))
	var chance_tier := stored_chance_tier
	var miss_count := stored_miss_count
	var recovered_before_roll := false
	if miss_count >= MISS_RECOVERY_THRESHOLD:
		chance_tier = 0
		miss_count = 0
		recovered_before_roll = true
	var chance := _chance_for_tier(chance_tier)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var roll_value := float(forced_roll_value) if forced_roll_value != null else rng.randf()
	var active := roll_value < chance
	var budget_total := 0
	var next_chance_tier := chance_tier
	var next_miss_count := miss_count

	if active:
		budget_total = clampi(forced_budget_total, BUDGET_MIN, BUDGET_MAX) if forced_budget_total > 0 else rng.randi_range(BUDGET_MIN, BUDGET_MAX)
		next_chance_tier = chance_tier + 1
		next_miss_count = 0
	else:
		next_miss_count = miss_count + 1
		if next_miss_count > MISS_RECOVERY_THRESHOLD:
			next_chance_tier = 0
			next_miss_count = 0

	var result := {
		"day": current_day,
		"rolled": true,
		"active": active,
		"budget_total": budget_total,
		"budget_used": 0,
		"chance_tier": chance_tier,
		"chance": chance,
		"roll_value": roll_value,
		"miss_count_before": stored_miss_count,
		"effective_miss_count_before": miss_count,
		"recovered_before_roll": recovered_before_roll,
		"next_chance_tier": next_chance_tier,
		"next_miss_count": next_miss_count,
		"reused": false,
	}
	last_roll = result.duplicate(true)
	if game_state != null and game_state.has_method("apply_ss_roll_result"):
		game_state.apply_ss_roll_result(result)
	return result

func _read_state(game_state) -> Dictionary:
	if game_state != null and game_state.has_method("get_ss_roll_state"):
		return game_state.get_ss_roll_state()
	return {
		"current_day": 1,
		"chance_tier": 0,
		"miss_count": 0,
		"last_roll_day": 0,
		"last_roll_result": {},
	}

func _chance_for_tier(tier: int) -> float:
	if data_registry != null and data_registry.has_method("get_ss_chance_for_tier"):
		return data_registry.get_ss_chance_for_tier(tier)
	match maxi(0, tier):
		0:
			return 0.20
		1:
			return 0.10
		2:
			return 0.05
		3:
			return 0.025
		_:
			return 0.01

class_name SSLootDirector
extends RefCounted

const PITY_OPENED_CONTAINER_THRESHOLD := 8
const PITY_REMAINING_TIME_RATIO := 0.30

var data_registry
var run_context
var ss_run_active: bool = false
var ss_budget_total: int = 0
var ss_budget_used: int = 0
var opened_effective_container_count: int = 0
var debug_force_next_ss: bool = false
var debug_events: Array[Dictionary] = []

func setup(registry, context = null) -> void:
	data_registry = registry
	run_context = context
	_sync_context()

func begin_run(roll_result: Dictionary) -> void:
	ss_run_active = bool(roll_result.get("active", false))
	ss_budget_total = maxi(0, int(roll_result.get("budget_total", 0)))
	ss_budget_used = 0
	opened_effective_container_count = 0
	debug_force_next_ss = false
	debug_events.clear()
	_apply_roll_to_context(roll_result)
	_sync_context()

func try_generate_ss(container_def: Dictionary, ring: String, rng: RandomNumberGenerator) -> Dictionary:
	var type_id := String(container_def.get("type_id", ""))
	var chance := _container_chance(type_id)
	var is_effective_container := chance > 0.0
	var opened_before := opened_effective_container_count
	if not is_effective_container:
		_record_event("not_configured", type_id, ring, chance, 0.0, false, false, "")
		return {}

	var forced := _should_force_ss(type_id, opened_before)
	var roll_value := 0.0
	var hit := false
	if ss_run_active and ss_budget_used < ss_budget_total:
		if forced or debug_force_next_ss:
			hit = true
		else:
			roll_value = rng.randf()
			hit = roll_value < chance
	if debug_force_next_ss:
		debug_force_next_ss = false

	opened_effective_container_count += 1
	_sync_context()

	if not ss_run_active:
		_record_event("inactive", type_id, ring, chance, roll_value, false, false, "")
		return {}
	if ss_budget_used >= ss_budget_total:
		_record_event("budget_exhausted", type_id, ring, chance, roll_value, false, forced, "")
		return {}
	if not hit:
		_record_event("miss", type_id, ring, chance, roll_value, false, forced, "")
		return {}

	var stack := _pick_ss_stack(rng)
	if stack.is_empty():
		_record_event("pool_empty", type_id, ring, chance, roll_value, false, forced, "")
		return {}
	ss_budget_used += 1
	stack["source_container_type"] = type_id
	stack["source_ring"] = ring
	stack["ss_generated"] = true
	_sync_context()
	_record_event("hit", type_id, ring, chance, roll_value, true, forced, String(stack.get("item_id", "")))
	return stack

func debug_force_next_ss_drop() -> void:
	debug_force_next_ss = true

func debug_set_opened_effective_container_count(count: int) -> void:
	opened_effective_container_count = maxi(0, count)
	_sync_context()

func get_debug_snapshot() -> Dictionary:
	return {
		"ss_run_active": ss_run_active,
		"ss_budget_total": ss_budget_total,
		"ss_budget_used": ss_budget_used,
		"opened_effective_container_count": opened_effective_container_count,
		"remaining_time_ratio": _remaining_time_ratio(),
		"debug_events": debug_events.duplicate(true),
	}

func _container_chance(type_id: String) -> float:
	if data_registry == null or not data_registry.has_method("get_ss_container_chance"):
		return 0.0
	return data_registry.get_ss_container_chance(type_id)

func _should_force_ss(type_id: String, opened_before: int) -> bool:
	if not ss_run_active or ss_budget_used != 0:
		return false
	if data_registry == null or not data_registry.has_method("is_ss_pity_container"):
		return false
	if not data_registry.is_ss_pity_container(type_id):
		return false
	return opened_before >= PITY_OPENED_CONTAINER_THRESHOLD or _remaining_time_ratio() < PITY_REMAINING_TIME_RATIO

func _remaining_time_ratio() -> float:
	if run_context == null:
		return 1.0
	var duration := maxf(0.01, float(run_context.run_duration_seconds))
	var remaining := clampf(float(run_context.remaining_seconds), 0.0, duration)
	return remaining / duration

func _pick_ss_stack(rng: RandomNumberGenerator) -> Dictionary:
	if data_registry == null or not data_registry.has_method("pick_ss_item_stack"):
		return {}
	return data_registry.pick_ss_item_stack(rng)

func _apply_roll_to_context(roll_result: Dictionary) -> void:
	if run_context == null:
		return
	run_context.ss_roll_day = int(roll_result.get("day", 0))
	run_context.ss_roll_chance_tier = int(roll_result.get("chance_tier", 0))
	run_context.ss_roll_chance = float(roll_result.get("chance", 0.0))
	run_context.ss_roll_value = float(roll_result.get("roll_value", 0.0))
	run_context.ss_miss_count_before = int(roll_result.get("miss_count_before", 0))
	run_context.ss_next_chance_tier = int(roll_result.get("next_chance_tier", 0))
	run_context.ss_next_miss_count = int(roll_result.get("next_miss_count", 0))

func _sync_context() -> void:
	if run_context == null:
		return
	run_context.ss_run_active = ss_run_active
	run_context.ss_budget_total = ss_budget_total
	run_context.ss_budget_used = ss_budget_used
	run_context.ss_opened_container_count = opened_effective_container_count
	run_context.ss_debug_events = debug_events.duplicate(true)

func _record_event(event: String, type_id: String, ring: String, chance: float, roll_value: float, hit: bool, forced: bool, item_id: String) -> void:
	debug_events.append({
		"event": event,
		"type_id": type_id,
		"ring": ring,
		"chance": chance,
		"roll_value": roll_value,
		"hit": hit,
		"forced": forced,
		"item_id": item_id,
		"budget_used": ss_budget_used,
		"budget_total": ss_budget_total,
		"opened_effective_container_count": opened_effective_container_count,
	})
	if debug_events.size() > 30:
		debug_events.pop_front()
	_sync_context()

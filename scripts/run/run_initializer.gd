class_name RunInitializer
extends RefCounted

const RunContextScript := preload("res://scripts/run/run_context.gd")

signal run_context_created(context)
signal run_initialized(context)
signal initialization_failed(reason: String)

var last_failure_reason: String = ""

func create_context(
		config,
		spawn_position: Vector2,
		first_outpost_candidates: Array,
		second_outpost_candidates: Array):
	last_failure_reason = ""
	var failure_reason := _validate(config, first_outpost_candidates, second_outpost_candidates)
	if not failure_reason.is_empty():
		last_failure_reason = failure_reason
		initialization_failed.emit(failure_reason)
		return null

	var seed = int(config.get_seed())
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var first_outpost_id := _pick_candidate(first_outpost_candidates, rng)
	var second_outpost_id := _pick_candidate(second_outpost_candidates, rng)

	var context = RunContextScript.new()
	context.run_id = "run_%s_%s_%s" % [
		Time.get_datetime_string_from_system(false, true),
		Time.get_ticks_msec(),
		seed,
	]
	context.seed = seed
	context.elapsed_seconds = 0.0
	context.run_duration_seconds = config.run_duration_seconds
	context.remaining_seconds = config.run_duration_seconds
	context.is_time_expired = false
	context.player_spawn_position = spawn_position
	context.player_stability = config.max_stability
	context.player_inventory = []
	context.current_weight = 0.0
	context.weight_limit = config.base_weight_limit
	context.weight_stage = "LIGHT"
	context.weight_speed_multiplier = 1.0
	context.home_storage = _create_empty_slots(config.home_storage_slots)
	context.outpost_storage = {}
	context.selected_first_outpost_id = first_outpost_id
	context.selected_second_outpost_id = second_outpost_id
	context.selected_outposts = [first_outpost_id, second_outpost_id]
	context.selected_outpost_positions = {
		first_outpost_id: _candidate_position(first_outpost_candidates, first_outpost_id),
		second_outpost_id: _candidate_position(second_outpost_candidates, second_outpost_id),
	}
	context.selected_outpost_footprints = {
		first_outpost_id: _candidate_footprint_units(first_outpost_candidates, first_outpost_id),
		second_outpost_id: _candidate_footprint_units(second_outpost_candidates, second_outpost_id),
	}
	context.outpost_states = {
		first_outpost_id: "unrepaired",
		second_outpost_id: "unrepaired",
	}
	context.repaired_outpost_count = 0
	context.is_extraction_unlocked = false
	context.camera_mode = "observe"
	context.darkness_enabled = false
	context.active_safe_zone_id = "home"
	context.active_safe_zone_type = "home"
	context.stability_stage = "SAFE"
	context.vision_radius = 0.0

	run_context_created.emit(context)
	run_initialized.emit(context)
	return context

func _validate(
		config,
		first_outpost_candidates: Array,
		second_outpost_candidates: Array) -> String:
	if config == null:
		return "RunConfig is missing."
	if first_outpost_candidates.size() < config.first_outpost_candidate_count:
		return "First outpost candidate pool requires %s entries, got %s." % [
			config.first_outpost_candidate_count,
			first_outpost_candidates.size(),
		]
	if second_outpost_candidates.size() < config.second_outpost_candidate_count:
		return "Second outpost candidate pool requires %s entries, got %s." % [
			config.second_outpost_candidate_count,
			second_outpost_candidates.size(),
		]
	if config.home_storage_slots < 0:
		return "Home storage slot count cannot be negative."
	if config.first_outpost_storage_slots < 0 or config.second_outpost_storage_slots < 0:
		return "Outpost storage slot count cannot be negative."
	if config.max_stability <= 0.0:
		return "Max stability must be greater than zero."
	if config.base_weight_limit <= 0.0:
		return "Base weight limit must be greater than zero."
	if config.run_duration_seconds <= 0.0:
		return "Run duration must be greater than zero."
	return ""

func _pick_candidate(candidates: Array, rng: RandomNumberGenerator) -> String:
	var candidate = candidates[rng.randi_range(0, candidates.size() - 1)]
	if candidate is Dictionary:
		return str(candidate.get("id", ""))
	return str(candidate)

func _candidate_position(candidates: Array, candidate_id: String) -> Vector2:
	for candidate in candidates:
		if candidate is Dictionary and str(candidate.get("id", "")) == candidate_id:
			return candidate.get("position", Vector2.ZERO)
	return Vector2.ZERO

func _candidate_footprint_units(candidates: Array, candidate_id: String) -> Vector2:
	for candidate in candidates:
		if candidate is Dictionary and str(candidate.get("id", "")) == candidate_id:
			return candidate.get("footprint_units", Vector2.ZERO)
	return Vector2.ZERO

func _create_empty_slots(slot_count: int) -> Array:
	var slots: Array = []
	for _i in range(slot_count):
		slots.append(null)
	return slots

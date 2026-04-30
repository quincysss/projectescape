class_name RunDirector
extends Node

signal run_context_created(context)
signal run_initialized(context)
signal initialization_failed(reason: String)
signal debug_log(message: String)

const RunConfigScript := preload("res://scripts/run/run_config.gd")
const RunInitializerScript := preload("res://scripts/run/run_initializer.gd")
const RunStateMachineScript := preload("res://scripts/run/run_state_machine.gd")

@export var spawn_position: Vector2 = Vector2.ZERO
@export var first_outpost_candidates: Array = ["OutpostA_01", "OutpostA_02", "OutpostA_03"]
@export var second_outpost_candidates: Array = ["OutpostB_01", "OutpostB_02", "OutpostB_03", "OutpostB_04"]
@export var prefer_scene_points: bool = true

var config = RunConfigScript.new()
var context
var initializer = RunInitializerScript.new()
var state_machine

func _ready() -> void:
	state_machine = get_node_or_null("RunStateMachine")
	if state_machine == null:
		state_machine = RunStateMachineScript.new()
		state_machine.name = "RunStateMachine"
		add_child(state_machine)

	state_machine.phase_changed.connect(_on_phase_changed)
	state_machine.extraction_unlocked.connect(_on_extraction_unlocked)
	state_machine.run_finished.connect(_on_run_finished)
	state_machine.invalid_transition_requested.connect(_on_invalid_transition_requested)
	initializer.initialization_failed.connect(_on_initialization_failed)

func start_new_run() -> bool:
	_log("Starting new run.")
	state_machine.start_new_run()
	var scene_spawn_position := _resolve_spawn_position()
	var first_candidates := _resolve_outpost_candidates("first")
	var second_candidates := _resolve_outpost_candidates("second")
	context = initializer.create_context(
		config,
		scene_spawn_position,
		first_candidates,
		second_candidates
	)
	if context == null:
		return false

	run_context_created.emit(context)
	run_initialized.emit(context)
	_log("Run initialized: %s" % context.to_debug_dictionary())
	return state_machine.complete_initialization()

func on_home_exited() -> void:
	_log("Event: home_exited")
	state_machine.on_home_exited()
	if context:
		context.camera_mode = "transition_to_follow"
		context.darkness_enabled = true

func on_camera_transition_finished() -> void:
	_log("Event: camera_transition_finished")
	state_machine.on_camera_transition_finished()
	if context:
		context.camera_mode = "follow"
		context.darkness_enabled = true

func on_safe_zone_entered(zone_id: String = "home") -> void:
	_log("Event: safe_zone_entered %s" % zone_id)
	state_machine.on_safe_zone_entered(zone_id)
	if context:
		context.darkness_enabled = false
		context.camera_mode = "observe" if zone_id == "home" else "safe_zone"

func on_safe_zone_exited(zone_id: String = "home") -> void:
	_log("Event: safe_zone_exited %s" % zone_id)
	state_machine.on_safe_zone_exited(zone_id)
	if context:
		context.darkness_enabled = true
		context.camera_mode = "transition_to_follow"

func on_outpost_repair_started(outpost_id: String) -> void:
	_log("Event: outpost_repair_started %s" % outpost_id)
	state_machine.on_outpost_repair_started(outpost_id)

func on_outpost_repaired(outpost_id: String) -> void:
	_log("Event: outpost_repaired %s" % outpost_id)
	if context:
		context.outpost_states[outpost_id] = "repaired"
		context.repaired_outpost_count += 1
	state_machine.on_outpost_repaired(outpost_id)

func on_extraction_started() -> void:
	_log("Event: extraction_started")
	state_machine.on_extraction_started()

func on_extraction_completed() -> void:
	_log("Event: extraction_completed")
	state_machine.on_extraction_completed()

func on_extraction_interrupted() -> void:
	_log("Event: extraction_interrupted")
	state_machine.on_extraction_interrupted()

func on_player_dead(reason: String = "stability_depleted") -> void:
	_log("Event: player_dead %s" % reason)
	state_machine.on_player_dead(reason)

func get_debug_snapshot() -> Dictionary:
	var snapshot := {
		"state_machine": state_machine.get_state_snapshot() if state_machine else {},
		"context": context.to_debug_dictionary() if context else {},
	}
	return snapshot

func get_candidate_summary() -> Dictionary:
	return {
		"spawn_position": _resolve_spawn_position(),
		"first_outpost_candidates": _resolve_outpost_candidates("first"),
		"second_outpost_candidates": _resolve_outpost_candidates("second"),
	}

func _resolve_spawn_position() -> Vector2:
	if prefer_scene_points:
		var spawn_points := get_tree().get_nodes_in_group("player_spawn_points")
		if not spawn_points.is_empty() and spawn_points[0] is Node2D:
			return spawn_points[0].global_position
	return spawn_position

func _resolve_outpost_candidates(tier: String) -> Array:
	if not prefer_scene_points:
		return first_outpost_candidates if tier == "first" else second_outpost_candidates

	var group_name := "first_outpost_candidates" if tier == "first" else "second_outpost_candidates"
	var nodes := get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return first_outpost_candidates if tier == "first" else second_outpost_candidates

	var candidates: Array = []
	for node in nodes:
		var candidate_id := node.name
		if node.has_method("get_candidate_id"):
			candidate_id = node.get_candidate_id()
		var candidate_position := Vector2.ZERO
		if node is Node2D:
			candidate_position = node.global_position
		candidates.append({
			"id": candidate_id,
			"position": candidate_position,
		})
	return candidates

func _on_phase_changed(old_phase: int, new_phase: int) -> void:
	_log("Phase changed: %s -> %s" % [
		RunStateMachineScript.phase_name(old_phase),
		RunStateMachineScript.phase_name(new_phase),
	])

func _on_extraction_unlocked() -> void:
	if context:
		context.is_extraction_unlocked = true
	_log("Extraction unlocked.")

func _on_run_finished(result: int) -> void:
	_log("Run finished: %s" % RunStateMachineScript.result_name(result))

func _on_invalid_transition_requested(from_phase: int, to_phase: int, reason: String) -> void:
	_log("Invalid transition: %s -> %s, %s" % [
		RunStateMachineScript.phase_name(from_phase),
		RunStateMachineScript.phase_name(to_phase),
		reason,
	])

func _on_initialization_failed(reason: String) -> void:
	_log("Initialization failed: %s" % reason)
	initialization_failed.emit(reason)

func _log(message: String) -> void:
	print("[RunDirector] %s" % message)
	debug_log.emit(message)

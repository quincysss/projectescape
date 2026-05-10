class_name RunStateMachine
extends Node

signal phase_changed(old_phase: int, new_phase: int)
signal extraction_unlocked()
signal run_finished(result: int)
signal invalid_transition_requested(from_phase: int, to_phase: int, reason: String)

enum RunPhase {
	SPAWN,
	OBSERVE,
	LEAVE_HOME,
	SCAVENGE,
	RECOVER,
	OUTPOST_PUSH,
	GREED_DECISION,
	EXTRACT,
	SETTLEMENT,
	FAILED,
}

enum RunResult {
	NONE,
	EXTRACTED,
	DEAD,
	TIMEOUT_FAILED,
	ABORTED,
}

var current_phase: int = RunPhase.SPAWN
var previous_phase: int = RunPhase.SPAWN
var run_result: int = RunResult.NONE
var is_extraction_unlocked: bool = false
var repaired_outpost_count: int = 0
var is_player_in_safe_zone: bool = true
var is_player_alive: bool = true

var _has_active_run: bool = false
var _has_finished_run: bool = false
var _finished_emitted: bool = false

func start_new_run() -> void:
	_has_active_run = true
	_has_finished_run = false
	_finished_emitted = false
	current_phase = RunPhase.SPAWN
	previous_phase = RunPhase.SPAWN
	run_result = RunResult.NONE
	is_extraction_unlocked = false
	repaired_outpost_count = 0
	is_player_in_safe_zone = true
	is_player_alive = true
	print("[RunStateMachine] New run entered %s." % phase_name(current_phase))
	phase_changed.emit(RunPhase.SPAWN, RunPhase.SPAWN)

func complete_initialization() -> bool:
	return request_transition(RunPhase.OBSERVE, "run_initialized")

func request_transition(to_phase: int, reason: String = "") -> bool:
	var from_phase := current_phase
	var validation_reason := _validate_transition(from_phase, to_phase)
	if not validation_reason.is_empty():
		var full_reason := validation_reason
		if not reason.is_empty():
			full_reason += " requested_by=%s" % reason
		print("[RunStateMachine] Invalid transition %s -> %s: %s" % [
			phase_name(from_phase),
			phase_name(to_phase),
			full_reason,
		])
		invalid_transition_requested.emit(from_phase, to_phase, full_reason)
		return false

	previous_phase = from_phase
	current_phase = to_phase
	print("[RunStateMachine] Phase %s -> %s (%s)." % [
		phase_name(from_phase),
		phase_name(to_phase),
		reason,
	])
	phase_changed.emit(from_phase, to_phase)
	return true

func on_home_exited() -> bool:
	is_player_in_safe_zone = false
	if current_phase in [RunPhase.OBSERVE, RunPhase.RECOVER, RunPhase.GREED_DECISION]:
		return request_transition(RunPhase.LEAVE_HOME, "home_exited")
	return request_transition(RunPhase.SCAVENGE, "home_exited")

func on_camera_transition_finished() -> bool:
	if current_phase == RunPhase.LEAVE_HOME:
		return request_transition(RunPhase.SCAVENGE, "camera_transition_finished")
	return request_transition(RunPhase.SCAVENGE, "camera_transition_finished")

func on_safe_zone_entered(_zone_id: String = "") -> bool:
	is_player_in_safe_zone = true
	if current_phase == RunPhase.EXTRACT:
		return true
	if current_phase in [RunPhase.SCAVENGE, RunPhase.GREED_DECISION, RunPhase.OUTPOST_PUSH, RunPhase.LEAVE_HOME]:
		return request_transition(RunPhase.RECOVER, "safe_zone_entered")
	return true

func on_safe_zone_exited(_zone_id: String = "") -> bool:
	is_player_in_safe_zone = false
	if current_phase in [RunPhase.OBSERVE, RunPhase.RECOVER, RunPhase.GREED_DECISION]:
		return request_transition(RunPhase.LEAVE_HOME, "safe_zone_exited")
	return true

func on_outpost_repair_started(_outpost_id: String = "") -> bool:
	if current_phase in [RunPhase.SCAVENGE, RunPhase.RECOVER]:
		return request_transition(RunPhase.OUTPOST_PUSH, "outpost_repair_started")
	return request_transition(RunPhase.OUTPOST_PUSH, "outpost_repair_started")

func on_outpost_repaired(_outpost_id: String = "") -> bool:
	repaired_outpost_count += 1
	if repaired_outpost_count >= 2 and not is_extraction_unlocked:
		is_extraction_unlocked = true
		print("[RunStateMachine] Extraction unlocked.")
		extraction_unlocked.emit()
		if current_phase != RunPhase.FAILED and current_phase != RunPhase.SETTLEMENT:
			return request_transition(RunPhase.GREED_DECISION, "second_outpost_repaired")

	if is_player_in_safe_zone:
		return request_transition(RunPhase.RECOVER, "outpost_repaired")
	return request_transition(RunPhase.SCAVENGE, "outpost_repaired")

func on_extraction_started() -> bool:
	if not is_extraction_unlocked:
		_reject_transition(RunPhase.EXTRACT, "Extraction is not unlocked.")
		return false
	if not is_player_in_safe_zone:
		_reject_transition(RunPhase.EXTRACT, "Extraction requires a safe zone.")
		return false
	return request_transition(RunPhase.EXTRACT, "extraction_started")

func on_extraction_completed() -> bool:
	run_result = RunResult.EXTRACTED
	var transitioned := request_transition(RunPhase.SETTLEMENT, "extraction_completed")
	if transitioned:
		_finish_run_once()
	return transitioned

func on_extraction_interrupted() -> bool:
	if current_phase != RunPhase.EXTRACT:
		return request_transition(RunPhase.RECOVER, "extraction_interrupted")
	return request_transition(RunPhase.RECOVER, "extraction_interrupted")

func on_player_dead(reason: String = "stability_depleted") -> bool:
	if not is_player_alive:
		return false
	is_player_alive = false
	run_result = RunResult.DEAD
	var transitioned := request_transition(RunPhase.FAILED, reason)
	if transitioned:
		_finish_run_once()
	return transitioned

func on_run_timeout(reason: String = "time_expired") -> bool:
	if _has_finished_run:
		return false
	is_player_alive = false
	run_result = RunResult.TIMEOUT_FAILED
	var transitioned := request_transition(RunPhase.FAILED, reason)
	if transitioned:
		_finish_run_once()
	return transitioned

func get_state_snapshot() -> Dictionary:
	return {
		"previous_phase": phase_name(previous_phase),
		"current_phase": phase_name(current_phase),
		"run_result": result_name(run_result),
		"is_extraction_unlocked": is_extraction_unlocked,
		"repaired_outpost_count": repaired_outpost_count,
		"is_player_in_safe_zone": is_player_in_safe_zone,
		"is_player_alive": is_player_alive,
	}

func _validate_transition(from_phase: int, to_phase: int) -> String:
	if not _has_active_run:
		return "No active run."
	if _has_finished_run:
		return "Run already finished."
	if from_phase == to_phase:
		return ""
	if from_phase in [RunPhase.SETTLEMENT, RunPhase.FAILED]:
		return "Terminal phase cannot transition to exploration."
	if to_phase == RunPhase.FAILED:
		return ""
	if not is_player_alive:
		return "Dead player cannot enter non-failure phase."

	match from_phase:
		RunPhase.SPAWN:
			if to_phase == RunPhase.OBSERVE:
				return ""
		RunPhase.OBSERVE:
			if to_phase == RunPhase.LEAVE_HOME:
				return ""
		RunPhase.LEAVE_HOME:
			if to_phase in [RunPhase.SCAVENGE, RunPhase.RECOVER]:
				return ""
		RunPhase.SCAVENGE:
			if to_phase in [RunPhase.RECOVER, RunPhase.OUTPOST_PUSH, RunPhase.GREED_DECISION]:
				return ""
		RunPhase.RECOVER:
			if to_phase in [RunPhase.LEAVE_HOME, RunPhase.SCAVENGE, RunPhase.OUTPOST_PUSH, RunPhase.EXTRACT, RunPhase.GREED_DECISION]:
				return ""
		RunPhase.OUTPOST_PUSH:
			if to_phase in [RunPhase.RECOVER, RunPhase.SCAVENGE, RunPhase.GREED_DECISION]:
				return ""
		RunPhase.GREED_DECISION:
			if to_phase in [RunPhase.SCAVENGE, RunPhase.RECOVER, RunPhase.LEAVE_HOME, RunPhase.EXTRACT]:
				return ""
		RunPhase.EXTRACT:
			if to_phase in [RunPhase.SETTLEMENT, RunPhase.RECOVER]:
				return ""

	return "Transition not allowed."

func _finish_run_once() -> void:
	if _finished_emitted:
		return
	_has_finished_run = true
	_finished_emitted = true
	print("[RunStateMachine] Run finished with result %s." % result_name(run_result))
	run_finished.emit(run_result)

func _reject_transition(to_phase: int, reason: String) -> void:
	print("[RunStateMachine] Invalid transition %s -> %s: %s" % [
		phase_name(current_phase),
		phase_name(to_phase),
		reason,
	])
	invalid_transition_requested.emit(current_phase, to_phase, reason)

static func phase_name(phase: int) -> String:
	match phase:
		RunPhase.SPAWN:
			return "SPAWN"
		RunPhase.OBSERVE:
			return "OBSERVE"
		RunPhase.LEAVE_HOME:
			return "LEAVE_HOME"
		RunPhase.SCAVENGE:
			return "SCAVENGE"
		RunPhase.RECOVER:
			return "RECOVER"
		RunPhase.OUTPOST_PUSH:
			return "OUTPOST_PUSH"
		RunPhase.GREED_DECISION:
			return "GREED_DECISION"
		RunPhase.EXTRACT:
			return "EXTRACT"
		RunPhase.SETTLEMENT:
			return "SETTLEMENT"
		RunPhase.FAILED:
			return "FAILED"
		_:
			return "UNKNOWN"

static func result_name(result: int) -> String:
	match result:
		RunResult.NONE:
			return "NONE"
		RunResult.EXTRACTED:
			return "EXTRACTED"
		RunResult.DEAD:
			return "DEAD"
		RunResult.TIMEOUT_FAILED:
			return "TIMEOUT_FAILED"
		RunResult.ABORTED:
			return "ABORTED"
		_:
			return "UNKNOWN"

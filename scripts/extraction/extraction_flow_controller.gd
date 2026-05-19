class_name ExtractionFlowController
extends RefCounted

const REASON_MISSING_END_CONTROLLER := "missing_end_controller"
const REASON_PROGRESS_ACTIVE := "progress_active"
const REASON_PROGRESS_REJECTED := "progress_rejected"
const REASON_RUN_TERMINAL := "run_terminal"

var run_director
var run_end_controller
var hold_seconds: float = 3.0


func setup(p_run_director, p_run_end_controller, p_hold_seconds: float) -> void:
	run_director = p_run_director
	run_end_controller = p_run_end_controller
	hold_seconds = p_hold_seconds


func begin_extraction(interaction_progress_controller, on_completed: Callable, on_cancelled: Callable) -> Dictionary:
	if is_run_terminal():
		return {"accepted": false, "reason": REASON_RUN_TERMINAL, "message": ""}
	var validation := validate_extraction()
	if not bool(validation.get("accepted", false)):
		return validation
	if interaction_progress_controller == null:
		return {"accepted": true, "complete_immediately": true}
	if interaction_progress_controller.is_active():
		return {"accepted": false, "reason": REASON_PROGRESS_ACTIVE, "message": ""}
	if not interaction_progress_controller.begin(
		"extract",
		run_director,
		hold_seconds,
		on_completed,
		on_cancelled
	):
		return {"accepted": false, "reason": REASON_PROGRESS_REJECTED, "message": ""}
	if run_director != null and run_director.has_method("on_extraction_started"):
		run_director.on_extraction_started()
	return {"accepted": true, "held": true}


func complete_extraction(tree: SceneTree) -> Dictionary:
	if run_end_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_END_CONTROLLER, "message": ""}
	return run_end_controller.try_extract(tree)


func cancel_extraction() -> void:
	if run_director == null or not _is_current_run_phase("EXTRACT"):
		return
	if run_director.has_method("on_extraction_interrupted"):
		run_director.on_extraction_interrupted()


func can_continue_hold(hold_pressed: bool) -> bool:
	return (
		hold_pressed
		and run_director != null
		and run_director.context != null
		and bool(run_director.context.is_extraction_unlocked)
		and String(run_director.context.active_safe_zone_id) == "home"
		and not is_run_terminal()
	)


func validate_extraction() -> Dictionary:
	if run_end_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_END_CONTROLLER, "message": ""}
	return run_end_controller.validate_extraction()


func is_run_terminal() -> bool:
	return _current_phase_name() in ["SETTLEMENT", "FAILED"]


func _is_current_run_phase(phase_name: String) -> bool:
	return _current_phase_name() == phase_name


func _current_phase_name() -> String:
	if run_director == null or run_director.state_machine == null:
		return ""
	return RunStateMachine.phase_name(run_director.state_machine.current_phase)

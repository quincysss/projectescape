class_name OutpostRepairFlowController
extends RefCounted

const REASON_MISSING_REPAIR_CONTROLLER := "missing_repair_controller"
const REASON_PROGRESS_REJECTED := "progress_rejected"

var outpost_repair_controller
var default_repair_seconds: float = 1.5


func setup(p_outpost_repair_controller, p_default_repair_seconds: float) -> void:
	outpost_repair_controller = p_outpost_repair_controller
	default_repair_seconds = p_default_repair_seconds


func begin_repair(station, interaction_progress_controller, on_completed: Callable, on_cancelled: Callable) -> Dictionary:
	var validation := can_repair(station)
	if not bool(validation.get("accepted", false)):
		return validation
	if interaction_progress_controller == null:
		return {"accepted": false, "reason": REASON_PROGRESS_REJECTED}
	if not interaction_progress_controller.begin(
		"repair_outpost",
		station,
		default_repair_seconds,
		on_completed,
		on_cancelled
	):
		return {"accepted": false, "reason": REASON_PROGRESS_REJECTED}
	outpost_repair_controller.mark_repairing(station)
	return {"accepted": true}


func complete_repair(station) -> Dictionary:
	if outpost_repair_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_REPAIR_CONTROLLER, "message": ""}
	return outpost_repair_controller.repair(station)


func cancel_repair(station) -> void:
	if outpost_repair_controller == null:
		return
	outpost_repair_controller.cancel_repairing(station)


func can_continue_repair(station, hold_pressed: bool, nearest_interactable) -> bool:
	return hold_pressed and nearest_interactable == station and is_instance_valid(station)


func can_repair(station) -> Dictionary:
	if outpost_repair_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_REPAIR_CONTROLLER, "message": ""}
	return outpost_repair_controller.can_repair(station)

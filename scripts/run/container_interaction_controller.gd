class_name ContainerInteractionController
extends RefCounted

const REASON_INVALID_CONTAINER := "invalid_container"
const REASON_DEPLETED := "depleted"
const REASON_MISSING_LOOT_CONTROLLER := "missing_loot_controller"
const REASON_OPEN_REJECTED := "open_rejected"
const REASON_PROGRESS_REJECTED := "progress_rejected"

var container_spawn_controller
var loot_interaction_controller
var default_open_seconds: float = 0.8


func setup(p_container_spawn_controller, p_loot_interaction_controller, p_default_open_seconds: float) -> void:
	container_spawn_controller = p_container_spawn_controller
	loot_interaction_controller = p_loot_interaction_controller
	default_open_seconds = p_default_open_seconds


func begin_open(container, interaction_progress_controller, on_completed: Callable, on_cancelled: Callable) -> Dictionary:
	var validation := validate_open(container)
	if not bool(validation.get("accepted", false)):
		return validation
	if interaction_progress_controller == null:
		return {"accepted": false, "reason": REASON_PROGRESS_REJECTED}
	var open_seconds := float(container.payload.get("open_time", default_open_seconds))
	if not interaction_progress_controller.begin("open_container", container, open_seconds, on_completed, on_cancelled):
		return {"accepted": false, "reason": REASON_PROGRESS_REJECTED}
	return {"accepted": true, "held": true}


func complete_held_open(container) -> Dictionary:
	return open(container)


func cancel_held_open(container) -> void:
	pass


func can_continue_open(container, hold_pressed: bool, nearest_interactable) -> bool:
	return hold_pressed and nearest_interactable == container and is_instance_valid(container)


func open(container) -> Dictionary:
	var validation := validate_open(container)
	if not bool(validation.get("accepted", false)):
		return validation
	if container_spawn_controller != null:
		container_spawn_controller.ensure_container_rewards(container)
	if loot_interaction_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_LOOT_CONTROLLER}
	if not loot_interaction_controller.open_container(container):
		return {
			"accepted": false,
			"reason": REASON_OPEN_REJECTED,
			"message": loot_interaction_controller.last_prompt,
		}
	container.payload["has_been_opened"] = true
	container.payload["opened_by_player_id"] = "local_player"
	return {"accepted": true}


func validate_open(container) -> Dictionary:
	if container == null or not is_instance_valid(container):
		return {"accepted": false, "reason": REASON_INVALID_CONTAINER}
	if container.get("interact_type") != "container":
		return {"accepted": false, "reason": REASON_INVALID_CONTAINER}
	if _is_depleted(container):
		return {"accepted": false, "reason": REASON_DEPLETED}
	return {"accepted": true}


func _is_depleted(container) -> bool:
	return (
		container.payload.get("state", "") == "depleted"
		or (
			bool(container.payload.get("loot_generated", false))
			and container.payload.get("rewards", []).is_empty()
		)
	)

class_name RunActiveInteractionController
extends RefCounted

const INTERACTION_OPEN_CONTAINER := "open_container"
const INTERACTION_REPAIR_OUTPOST := "repair_outpost"
const INTERACTION_EXTRACT := "extract"

var container_interaction_controller
var outpost_repair_flow_controller
var extraction_flow_controller


func setup(p_container_interaction_controller, p_outpost_repair_flow_controller, p_extraction_flow_controller) -> void:
	container_interaction_controller = p_container_interaction_controller
	outpost_repair_flow_controller = p_outpost_repair_flow_controller
	extraction_flow_controller = p_extraction_flow_controller


func should_continue(interaction_id: String, target, context: Dictionary) -> bool:
	if bool(context.get("story_paused", false)):
		return false
	match interaction_id:
		INTERACTION_OPEN_CONTAINER:
			if container_interaction_controller != null:
				return container_interaction_controller.can_continue_open(
					target,
					bool(context.get("interact_pressed", false)),
					context.get("nearest_interactable", null)
				)
			return _is_same_active_target(target, context)
		INTERACTION_REPAIR_OUTPOST:
			if outpost_repair_flow_controller != null:
				return outpost_repair_flow_controller.can_continue_repair(
					target,
					bool(context.get("interact_pressed", false)),
					context.get("nearest_interactable", null)
				)
			return _is_same_active_target(target, context)
		INTERACTION_EXTRACT:
			if extraction_flow_controller != null:
				return extraction_flow_controller.can_continue_hold(bool(context.get("extract_pressed", false)))
			return false
		_:
			return false


func cancel_message(interaction_id: String) -> String:
	match interaction_id:
		INTERACTION_OPEN_CONTAINER:
			return "开箱中断。"
		INTERACTION_REPAIR_OUTPOST:
			return "修复中断。"
		INTERACTION_EXTRACT:
			return "撤离中断。"
		_:
			return "交互中断。"


func complete_message(interaction_id: String) -> String:
	match interaction_id:
		INTERACTION_OPEN_CONTAINER:
			return "容器已打开。"
		INTERACTION_REPAIR_OUTPOST:
			return "前哨站修复完成。"
		INTERACTION_EXTRACT:
			return "撤离完成。"
		_:
			return "交互完成。"


func _is_same_active_target(target, context: Dictionary) -> bool:
	return (
		bool(context.get("interact_pressed", false))
		and context.get("nearest_interactable", null) == target
		and is_instance_valid(target)
	)

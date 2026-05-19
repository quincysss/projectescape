class_name MaterialPickupFlowController
extends RefCounted

const REASON_INVALID_PICKUP := "invalid_pickup"
const REASON_MISSING_LOOT_CONTROLLER := "missing_loot_controller"
const REASON_MISSING_REMOVE_CALLBACK := "missing_remove_callback"

var loot_interaction_controller
var run_director
var remove_interactable_callback: Callable = Callable()


func setup(p_loot_interaction_controller, p_run_director, p_remove_interactable_callback: Callable) -> void:
	loot_interaction_controller = p_loot_interaction_controller
	run_director = p_run_director
	remove_interactable_callback = p_remove_interactable_callback


func pick_material(pickup) -> Dictionary:
	var validation := validate_pickup(pickup)
	if not bool(validation.get("accepted", false)):
		return validation
	if loot_interaction_controller == null:
		return {"accepted": false, "reason": REASON_MISSING_LOOT_CONTROLLER, "message": "材料拾取控制器不可用。"}
	if not remove_interactable_callback.is_valid():
		return {"accepted": false, "reason": REASON_MISSING_REMOVE_CALLBACK, "message": "材料拾取出口不可用。"}
	var item: Dictionary = pickup.payload.get("item", {}).duplicate(true)
	var outpost_id := String(pickup.payload.get("outpost_id", ""))
	var inventory_component = run_director.inventory_component if run_director != null else null
	if not loot_interaction_controller.pick_material_immediate(pickup, inventory_component, remove_interactable_callback):
		return {
			"accepted": false,
			"reason": "pickup_rejected",
			"message": loot_interaction_controller.last_prompt,
			"item": item,
			"outpost_id": outpost_id,
		}
	return {
		"accepted": true,
		"item": item,
		"outpost_id": outpost_id,
	}


func validate_pickup(pickup) -> Dictionary:
	if pickup == null or not is_instance_valid(pickup):
		return {"accepted": false, "reason": REASON_INVALID_PICKUP, "message": "材料不可用。"}
	if pickup.get("interact_type") != "material":
		return {"accepted": false, "reason": REASON_INVALID_PICKUP, "message": "材料不可用。"}
	if pickup.payload.get("item", {}).is_empty():
		return {"accepted": false, "reason": REASON_INVALID_PICKUP, "message": "材料已空。"}
	return {"accepted": true}

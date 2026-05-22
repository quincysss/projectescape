class_name LootInteractionController
extends RefCounted

const ItemTransferServiceScript := preload("res://scripts/inventory/item_transfer_service.gd")

var opened_interactable
var opened_loot: Array[Dictionary] = []
var last_prompt: String = ""
var transfer_service = ItemTransferServiceScript.new()

func open_container(container) -> bool:
	var rewards: Array = container.payload.get("rewards", [])
	if rewards.is_empty():
		last_prompt = "容器已空。"
		return false
	container.payload.state = "opened"
	opened_interactable = container
	opened_loot = []
	for item in rewards:
		opened_loot.append_array(_split_single_items(item))
	container.modulate = Color(0.45, 0.45, 0.45)
	last_prompt = ""
	return true

func open_material(pickup) -> bool:
	var item: Dictionary = pickup.payload.get("item", {})
	if item.is_empty():
		last_prompt = "材料已空。"
		return false
	opened_interactable = pickup
	opened_loot = _split_single_items(item)
	last_prompt = ""
	return true

func take_all_loot(inventory_component, remove_interactable: Callable) -> bool:
	var remaining: Array[Dictionary] = []
	for item in opened_loot:
		if inventory_component == null or not inventory_component.add_item(item):
			remaining.append(item)
	opened_loot = remaining
	if not opened_loot.is_empty():
		save_opened_loot_to_source()
		return false

	if is_instance_valid(opened_interactable):
		if opened_interactable.interact_type == "container":
			opened_interactable.payload.state = "depleted"
		remove_interactable.call(opened_interactable)
	close_without_saving()
	return true

func take_loot_at(index: int, inventory_component, remove_interactable: Callable) -> Dictionary:
	var result: Dictionary = transfer_service.transfer_index_to_inventory(opened_loot, index, inventory_component)
	if not result.accepted:
		last_prompt = _transfer_reason_text(str(result.reason))
		return result

	if opened_loot.is_empty():
		if is_instance_valid(opened_interactable):
			if opened_interactable.interact_type == "container":
				opened_interactable.payload.state = "depleted"
			remove_interactable.call(opened_interactable)
		close_without_saving()
		result.finished = true
		return result

	save_opened_loot_to_source()
	result.finished = false
	return result

func pick_material_immediate(pickup, inventory_component, remove_interactable: Callable) -> bool:
	var item: Dictionary = pickup.payload.get("item", {})
	if item.is_empty():
		last_prompt = "材料已空。"
		return false
	if inventory_component == null:
		last_prompt = "背包不可用。"
		return false
	if not inventory_component.add_item(item):
		last_prompt = "背包空间或负重不足。"
		return false
	remove_interactable.call(pickup)
	last_prompt = ""
	return true

func close() -> void:
	if is_instance_valid(opened_interactable) and not opened_loot.is_empty():
		save_opened_loot_to_source()
	close_without_saving()

func close_without_saving() -> void:
	opened_interactable = null
	opened_loot = []

func save_opened_loot_to_source() -> void:
	if not is_instance_valid(opened_interactable):
		return
	match opened_interactable.interact_type:
		"container":
			opened_interactable.payload.rewards = opened_loot.duplicate(true)
		"material":
			opened_interactable.payload.item = _merge_loot_for_source(opened_loot)

func _split_single_items(item: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var amount: int = max(1, int(item.get("amount", 1)))
	for _index in range(amount):
		var single := item.duplicate(true)
		single.amount = 1
		result.append(single)
	return result

func _merge_loot_for_source(loot: Array[Dictionary]) -> Dictionary:
	if loot.is_empty():
		return {}
	var merged := loot[0].duplicate(true)
	merged.amount = loot.size()
	return merged

func _transfer_reason_text(reason: String) -> String:
	match reason:
		"inventory_rejected":
			return "背包空间或负重不足。"
		"missing_inventory":
			return "背包不可用。"
		"invalid_item":
			return "道具不可用。"
		_:
			return "无法拿取该道具。"

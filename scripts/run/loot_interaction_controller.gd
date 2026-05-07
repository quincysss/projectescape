class_name LootInteractionController
extends RefCounted

var opened_interactable
var opened_loot: Array[Dictionary] = []
var last_prompt: String = ""

func open_container(container) -> bool:
	var rewards: Array = container.payload.get("rewards", [])
	if rewards.is_empty():
		last_prompt = "容器已空。"
		return false
	container.payload.state = "opened"
	opened_interactable = container
	opened_loot = []
	for item in rewards:
		opened_loot.append(item.duplicate(true))
	container.modulate = Color(0.45, 0.45, 0.45)
	last_prompt = ""
	return true

func open_material(pickup) -> bool:
	var item: Dictionary = pickup.payload.get("item", {})
	if item.is_empty():
		last_prompt = "材料已空。"
		return false
	opened_interactable = pickup
	opened_loot = [item.duplicate(true)]
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

func pick_material_immediate(pickup, inventory_component, remove_interactable: Callable) -> bool:
	var item: Dictionary = pickup.payload.get("item", {})
	if item.is_empty() or inventory_component == null:
		return false
	if not inventory_component.add_item(item):
		return false
	remove_interactable.call(pickup)
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
			opened_interactable.payload.item = opened_loot[0].duplicate(true) if not opened_loot.is_empty() else {}

extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_item_click_transfer()
	print("Run item click transfer verified." if ok else "Run item click transfer failed.")
	quit(0 if ok else 1)

func _verify_run_item_click_transfer() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state != null and game_state.has_method("create_profile"):
		game_state.create_profile("RunCatalogPickup")
		game_state.clear_collected_items_debug_only()
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.setup(64, 100.0)
	var container = _find_interactable(root, "container")
	if container == null:
		printerr("Expected a container.")
		return false
	root._open_container(container)
	var initial_loot_count: int = root.opened_loot.size()
	if initial_loot_count <= 0:
		printerr("Expected opened container loot.")
		return false
	var first_loot_item_id := String(root.opened_loot[0].get("item_id", ""))
	root._on_loot_item_meta_clicked("loot:0")
	if root.run_director.inventory_component.items.size() != 1:
		printerr("Expected clicked loot item to move into backpack.")
		return false
	if game_state != null and game_state.has_method("is_item_collected") and not game_state.is_item_collected(first_loot_item_id):
		printerr("Expected clicked run loot to light catalog item %s." % first_loot_item_id)
		return false
	if initial_loot_count > 1 and root.opened_loot.size() != initial_loot_count - 1:
		printerr("Expected only one clicked loot item to be removed from loot.")
		return false

	root._on_inventory_item_meta_clicked("inventory:0")
	if root.selected_inventory_index != 0 or root.run_director.inventory_component.items.size() != 1:
		printerr("Expected clicked backpack item to become selected before storage transfer.")
		return false
	root.deposit_button.pressed.emit()
	if root.run_director.inventory_component.items.size() != 0 or root.run_director.home_storage_component.items.size() != 1:
		printerr("Expected selected backpack item to move into home storage.")
		return false

	root._on_home_storage_item_meta_clicked("home:0")
	if root.run_director.inventory_component.items.size() != 1 or root.run_director.home_storage_component.items.size() != 0:
		printerr("Expected clicked home item to move back into backpack.")
		return false

	root.run_director.inventory_component.clear()
	root.run_director.home_storage_component.setup(4)
	if not root.run_director.inventory_component.add_item(_item("medical_patch", "医疗贴片", 0.2).merged({"quality": "B", "quality_color": Color("#6FA8DC")}, true)):
		printerr("Expected test item to enter backpack.")
		return false
	root._on_inventory_item_meta_clicked("inventory:0")
	root._refresh_ui()
	await process_frame
	var empty_slot := root.home_storage_label.get_child(2) as Button
	if empty_slot == null:
		printerr("Expected empty home storage slot to be clickable.")
		return false
	empty_slot.button_up.emit()
	var storage_slots: Array = root.run_director.home_storage_component.get_slots_snapshot()
	if not (storage_slots[2] is Dictionary) or String(storage_slots[2].get("item_id", "")) != "medical_patch":
		printerr("Expected selected backpack item to move into clicked home slot.")
		return false
	if not storage_slots[2].get("quality_color", Color.WHITE).is_equal_approx(Color("#6FA8DC")):
		printerr("Expected quality color to stay blue after depositing into home.")
		return false
	root._on_home_storage_item_meta_clicked("storage:2")
	if root.run_director.inventory_component.items.size() != 1:
		printerr("Expected clicked home slot item to return to backpack.")
		return false
	if not root.run_director.inventory_component.items[0].get("quality_color", Color.WHITE).is_equal_approx(Color("#6FA8DC")):
		printerr("Expected quality color to survive home storage round trip.")
		return false
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

func _item(item_id: String, display_name: String, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
		"quality_color": Color("#D8D6CE"),
	}

extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_inventory_discard()
	print("Run inventory discard verified." if ok else "Run inventory discard failed.")
	quit(0 if ok else 1)

func _verify_run_inventory_discard() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.setup(64, 100.0)
	root.run_director.inventory_component.add_item(_item("scrap_metal", "废铁片", 2.0))
	root.run_director.inventory_component.add_item(_item("wire_coil", "线圈", 3.0))
	root.run_director.on_safe_zone_exited("home")
	await process_frame
	await process_frame
	root._toggle_inventory_panel()
	await process_frame
	if not root.inventory_panel.visible:
		printerr("Expected backpack panel to open outside storage zones.")
		return false
	if root.discard_button == null or not root.discard_button.disabled:
		printerr("Expected discard button to start disabled without selection.")
		return false
	var interactable_count: int = root.interactables.size()
	var weight_before: float = root.run_director.inventory_component.get_current_weight()
	root._on_inventory_item_meta_clicked("inventory:0")
	await process_frame
	if root.selected_inventory_index != 0:
		printerr("Expected clicked backpack item to become selected.")
		return false
	if root.discard_button.disabled:
		printerr("Expected discard button to enable after selection.")
		return false
	root.discard_button.pressed.emit()
	await process_frame
	if root.run_director.inventory_component.items.size() != 1:
		printerr("Expected selected item to be removed from backpack.")
		return false
	if String(root.run_director.inventory_component.items[0].get("item_id", "")) != "wire_coil":
		printerr("Expected discard to remove only the selected item.")
		return false
	if root.selected_inventory_index != -1 or not root.discard_button.disabled:
		printerr("Expected discard to clear selection and disable the button.")
		return false
	if root.run_director.inventory_component.get_current_weight() >= weight_before:
		printerr("Expected discard to reduce backpack weight.")
		return false
	if root.interactables.size() != interactable_count:
		printerr("Expected discard to destroy the item without spawning world loot.")
		return false
	root.queue_free()
	return true

func _item(item_id: String, display_name: String, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
	}

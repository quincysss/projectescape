extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_inventory_discard()
	await _shutdown_audio()
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
	root.run_director.inventory_component.add_item(_item("scrap_metal", "Scrap Metal", 2.0, 3, 20))
	root.run_director.inventory_component.add_item(_item("wire_coil", "Wire Coil", 3.0))
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
	var first_slot := _first_button(root.inventory_label)
	if first_slot == null:
		printerr("Expected stacked backpack slot button.")
		return false
	var badge := first_slot.get_node_or_null("StackAmount") as Label
	if badge == null or badge.text != "x3":
		printerr("Expected stacked backpack slot to show x3.")
		return false
	if not first_slot.tooltip_text.contains("x3"):
		printerr("Expected stacked backpack tooltip to include stack amount.")
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
	if root.run_director.inventory_component.items.size() != 2:
		printerr("Expected stack discard to keep the remaining stack in backpack.")
		return false
	if String(root.run_director.inventory_component.items[0].get("item_id", "")) != "scrap_metal":
		printerr("Expected discard to keep the selected stack slot.")
		return false
	if int(root.run_director.inventory_component.items[0].get("amount", 0)) != 2:
		printerr("Expected discard to subtract one item from the selected stack.")
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
	await process_frame
	return true

func _item(item_id: String, display_name: String, weight: float, amount: int = 1, stack_limit: int = 1) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stackable": stack_limit > 1,
		"stack_limit": stack_limit,
		"item_type": "material",
		"quality": "C",
	}

func _first_button(control: Control) -> Button:
	if control == null:
		return null
	for child in control.get_children():
		if child is Button:
			return child
	return null

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

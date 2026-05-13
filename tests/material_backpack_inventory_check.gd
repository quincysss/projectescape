extends SceneTree

const InventoryComponentScript := preload("res://scripts/inventory/inventory_component.gd")

func _initialize() -> void:
	var ok := await _verify_material_backpack_inventory()
	print("Material backpack inventory verified." if ok else "Material backpack inventory failed.")
	quit(0 if ok else 1)

func _verify_material_backpack_inventory() -> bool:
	var inventory = InventoryComponentScript.new()
	get_root().add_child(inventory)
	inventory.setup(2, 10.0, 5)

	if not inventory.add_item(_supply_item("scrap_metal", 2.0)):
		printerr("Expected ordinary supply to enter supply backpack.")
		return false
	if not inventory.add_item(_outpost_material("outpost_fuse")):
		printerr("Expected outpost material to enter material backpack.")
		return false
	if inventory.items.size() != 1:
		printerr("Expected material to avoid supply slots, got supply size %d." % inventory.items.size())
		return false
	if inventory.repair_material_items.size() != 1:
		printerr("Expected one material backpack item, got %d." % inventory.repair_material_items.size())
		return false
	if inventory.repair_material_items[0].has("quality") or inventory.repair_material_items[0].has("quality_color"):
		printerr("Expected repair material backpack item to have no quality fields.")
		return false
	if not is_equal_approx(inventory.get_current_weight(), 2.0):
		printerr("Expected material backpack to avoid weight, got %.2f." % inventory.get_current_weight())
		return false

	for index in range(4):
		if not inventory.add_item(_outpost_material("outpost_filter_%d" % index)):
			printerr("Expected material slot %d to accept repair material." % index)
			return false
	if inventory.add_item(_outpost_material("overflow")):
		printerr("Expected sixth material item to be rejected by material backpack capacity.")
		return false
	if inventory.items.size() != 1:
		printerr("Expected overflow material rejection to leave supply slots unchanged.")
		return false

	inventory.queue_free()
	var ui_ok := await _verify_run_ui_material_backpack()
	if not ui_ok:
		return false
	return true

func _supply_item(item_id: String, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": item_id,
		"amount": 1,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
	}

func _outpost_material(item_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": item_id,
		"amount": 1,
		"weight_per_unit": 9.0,
		"stack_limit": 1,
		"repair_material_id": item_id,
	}

func _verify_run_ui_material_backpack() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.clear()
	root.run_director.debug_add_item(_outpost_material("outpost_fuse"))
	root._toggle_inventory_panel()
	root._refresh_ui()
	await process_frame

	if root.run_director.inventory_component.items.size() != 0:
		printerr("Expected outpost material to stay out of supply backpack in RunScene.")
		return false
	if root.run_director.inventory_component.repair_material_items.size() != 1:
		printerr("Expected RunScene material backpack to show one material.")
		return false
	if root.material_inventory_label == null or root.material_inventory_label.get_child_count() < 6:
		printerr("Expected material backpack grid to render five slots plus footer.")
		return false
	if not root.backpack_slot_label.text.contains("物资：0/"):
		printerr("Expected HUD supply label, got: %s" % root.backpack_slot_label.text)
		return false
	if not root.backpack_material_slot_label.text.contains("材料：1/"):
		printerr("Expected HUD material label, got: %s" % root.backpack_material_slot_label.text)
		return false

	root.queue_free()
	await process_frame
	return true

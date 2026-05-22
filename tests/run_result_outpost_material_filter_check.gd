extends SceneTree

const RunResultBuilderScript := preload("res://scripts/run/run_result_builder.gd")

class FakeDirector:
	extends RefCounted

	var inventory_component := InventoryComponent.new()
	var home_storage_component := InventoryComponent.new()
	var context = null
	var outpost_storage_items: Array[Dictionary] = []

	func _init() -> void:
		inventory_component.setup(16, 100.0)
		home_storage_component.setup(16, 100.0)

	func get_all_outpost_storage_items_snapshot() -> Array[Dictionary]:
		var snapshot: Array[Dictionary] = []
		for item in outpost_storage_items:
			snapshot.append(item.duplicate(true))
		return snapshot

func _initialize() -> void:
	var ok := _verify_run_only_outpost_materials_are_filtered()
	print("Run-only outpost material settlement filter verified." if ok else "Run-only outpost material settlement filter failed.")
	quit(0 if ok else 1)

func _verify_run_only_outpost_materials_are_filtered() -> bool:
	var director := FakeDirector.new()
	director.inventory_component.add_item(_item("scrap_metal"))
	director.inventory_component.add_item(_repair_material("outpost_fuse"))
	director.home_storage_component.add_item(_repair_material("outpost_filter"))
	director.outpost_storage_items.append(_item("wire_coil"))
	director.outpost_storage_items.append(_repair_material("outpost_servo_pack"))

	var builder = RunResultBuilderScript.new()
	var extracted: Dictionary = builder.build_extraction_result(director)
	var warehouse_items: Array = extracted.get("warehouse_items", [])
	if not _has_item(warehouse_items, "scrap_metal"):
		printerr("Expected ordinary material to be carried out.")
		return false
	for item_id in ["outpost_fuse", "outpost_filter", "outpost_servo_pack"]:
		if _has_item(warehouse_items, item_id):
			printerr("Expected %s to be filtered from extracted warehouse items." % item_id)
			return false

	var dead: Dictionary = builder.build_death_result(director)
	if _has_item(dead.get("warehouse_items", []), "outpost_filter"):
		printerr("Expected home-stored outpost material to be filtered from retained warehouse items.")
		return false
	if not _has_item(dead.get("warehouse_items", []), "wire_coil"):
		printerr("Expected ordinary outpost storage item to be retained on death.")
		return false
	if not _has_item(dead.get("lost_items", []), "outpost_fuse"):
		printerr("Expected backpack outpost material to be listed as lost on death.")
		return false
	return true

func _item(item_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": item_id,
		"amount": 1,
		"weight_per_unit": 0.1,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
	}

func _repair_material(item_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"repair_material_id": item_id,
		"display_name": item_id,
		"amount": 1,
		"weight_per_unit": 0.1,
		"stack_limit": 1,
	}

func _has_item(items: Array, item_id: String) -> bool:
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			return true
	return false

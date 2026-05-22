extends SceneTree

const RunResultBuilderScript := preload("res://scripts/run/run_result_builder.gd")

class FakeDirector:
	extends RefCounted

	var inventory_component := InventoryComponent.new()
	var home_storage_component := InventoryComponent.new()
	var context = null
	var outpost_items: Array[Dictionary] = []

	func _init() -> void:
		inventory_component.setup(8, 100.0)
		home_storage_component.setup(8, 100.0)

	func get_all_outpost_storage_items_snapshot() -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		for item in outpost_items:
			result.append(item.duplicate(true))
		return result

func _initialize() -> void:
	var ok := _verify_inventory_stacking_and_weight()
	if ok:
		ok = _verify_storage_stacking()
	if ok:
		ok = _verify_warehouse_queries_and_material_deduction()
	if ok:
		ok = _verify_shelf_removes_one_unit()
	if ok:
		ok = _verify_run_result_boundaries()
	print("Resource loop inventory/warehouse verified." if ok else "Resource loop inventory/warehouse failed.")
	quit(0 if ok else 1)

func _verify_inventory_stacking_and_weight() -> bool:
	var inventory := InventoryComponent.new()
	var weight := WeightComponent.new()
	inventory.weight_component = weight
	inventory.setup(2, 1.0)
	if not inventory.add_item(_item("scrap_metal", 12, 0.1, true, 10, "material", "C", ["craft"])):
		printerr("Expected stacked item pickup to succeed.")
		return false
	if inventory.items.size() != 2 or int(inventory.items[0].get("amount", 0)) != 10 or int(inventory.items[1].get("amount", 0)) != 2:
		printerr("Expected pickup to split into stack_limit-sized stacks: %s" % inventory.items)
		return false
	if not is_equal_approx(inventory.get_current_weight(), 1.2):
		printerr("Expected total weight to include all stacked units.")
		return false
	if weight.current_stage != WeightComponent.WeightStage.HEAVY or not is_equal_approx(weight.speed_multiplier, 0.8):
		printerr("Expected >100% weight to apply HEAVY speed multiplier.")
		return false
	if not inventory.add_item(_item("scrap_metal", 4, 0.1, true, 10, "material", "C", ["craft"])):
		printerr("Expected overweight pickup to be slot-gated, not weight-gated.")
		return false
	if weight.current_stage != WeightComponent.WeightStage.OVERLOADED or not is_equal_approx(weight.speed_multiplier, 0.55):
		printerr("Expected >150% weight to apply OVERLOADED speed multiplier.")
		return false
	var removed := inventory.remove_item_at(0, 2)
	if int(removed.get("amount", 0)) != 2 or not is_equal_approx(inventory.get_current_weight(), 1.4):
		printerr("Expected partial discard to reduce stacked weight.")
		return false
	return true

func _verify_storage_stacking() -> bool:
	var inventory := InventoryComponent.new()
	inventory.setup(2, 10.0)
	inventory.add_item(_item("scrap_metal", 6, 0.1, true, 10, "material", "C", ["craft"]))
	var storage := StorageContainer.new()
	storage.setup("home", "player", 1, false)
	if not storage.store_from_inventory(inventory, 0, 5):
		printerr("Expected storage to accept a partial stack.")
		return false
	if storage.get_items_snapshot().size() != 1 or int(storage.get_items_snapshot()[0].get("amount", 0)) != 5:
		printerr("Expected storage to keep one stacked entry.")
		return false
	if int(inventory.items[0].get("amount", 0)) != 1:
		printerr("Expected inventory stack to keep remainder after storage transfer.")
		return false
	return true

func _verify_warehouse_queries_and_material_deduction() -> bool:
	var warehouse := WarehouseManager.new()
	warehouse.set_capacity(4)
	var accepted := warehouse.add_items([
		_item("scrap_metal", 12, 0.1, true, 20, "material", "C", ["craft", "common"]),
		_item("scrap_metal", 5, 0.1, true, 20, "material", "C", ["craft", "common"]),
	])
	if accepted.size() != 2 or warehouse.get_used_slots() != 1 or warehouse.get_item_count("scrap_metal") != 17:
		printerr("Expected warehouse to stack matching materials.")
		return false
	if warehouse.get_items_by_category("material").size() != 1 or warehouse.get_items_by_quality("C").size() != 1 or warehouse.get_items_by_usage("craft").size() != 1:
		printerr("Expected warehouse category/quality/usage queries to find the material stack.")
		return false
	if not warehouse.has_materials({"scrap_metal": 7}):
		printerr("Expected warehouse material query to count stack amounts.")
		return false
	var consume_result := warehouse.consume_materials({"scrap_metal": 7})
	if not bool(consume_result.get("ok", false)) or warehouse.get_item_count("scrap_metal") != 10:
		printerr("Expected material deduction to remove units from stacks: %s" % consume_result)
		return false
	return true

func _verify_shelf_removes_one_unit() -> bool:
	var warehouse := WarehouseManager.new()
	warehouse.set_capacity(4)
	warehouse.add_items([_item("sale_good_repaired_filter", 3, 0.1, true, 10, "sale_good", "C", ["sale_good"])])
	var shelf: Array[Dictionary] = []
	var service := ShelfInventoryService.new()
	service.bind_dependencies(warehouse, shelf, 1)
	var groups := service.query_shelfable_sale_goods()
	if groups.is_empty() or int(groups[0].get("count", 0)) != 3:
		printerr("Expected shelf query to count stack amounts.")
		return false
	var result := service.move_group_to_shelf(String(groups[0].get("shelf_group_id", "")), 0)
	if not bool(result.get("ok", false)) or warehouse.get_item_count("sale_good_repaired_filter") != 2:
		printerr("Expected shelving to remove one unit from a warehouse stack: %s" % result)
		return false
	return true

func _verify_run_result_boundaries() -> bool:
	var director := FakeDirector.new()
	director.inventory_component.add_item(_item("scrap_metal", 3, 0.1, true, 20, "material", "C", ["craft"]))
	director.home_storage_component.add_item(_item("cloth_dirty", 2, 0.05, true, 20, "material", "C", ["craft"]))
	director.outpost_items.append(_item("wire_coil", 1, 0.12, true, 20, "material", "B", ["craft"]))
	var builder = RunResultBuilderScript.new()
	var extracted: Dictionary = builder.build_extraction_result(director)
	if not _has_item_amount(extracted.get("warehouse_items", []), "scrap_metal", 3):
		printerr("Expected backpack stack to enter warehouse on extraction.")
		return false
	var failed: Dictionary = builder.build_death_result(director)
	if _has_item_amount(failed.get("warehouse_items", []), "scrap_metal", 1):
		printerr("Expected backpack stack to be lost on failure.")
		return false
	if not _has_item_amount(failed.get("warehouse_items", []), "cloth_dirty", 2) or not _has_item_amount(failed.get("warehouse_items", []), "wire_coil", 1):
		printerr("Expected home and outpost storage to be retained on failure.")
		return false
	return true

func _item(item_id: String, amount: int, weight: float, stackable: bool, stack_limit: int, item_type: String, quality: String, tags: Array) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": item_id,
		"amount": amount,
		"weight_per_unit": weight,
		"stackable": stackable,
		"stack_limit": stack_limit,
		"item_type": item_type,
		"quality": quality,
		"tags": tags,
		"sellable": true,
		"sell_currency_id": "mine_coin",
		"sell_value": 10,
	}

func _has_item_amount(items: Array, item_id: String, amount: int) -> bool:
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id and int(item.get("amount", 0)) == amount:
			return true
	return false

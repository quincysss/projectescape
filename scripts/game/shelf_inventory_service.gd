class_name ShelfInventoryService
extends RefCounted

const DEFAULT_SLOT_COUNT := 3
const DailyDemandServiceScript := preload("res://scripts/game/daily_demand_service.gd")

var warehouse_manager: WarehouseManager
var shelf_items: Array[Dictionary] = []
var slot_count := DEFAULT_SLOT_COUNT
var demand_service = DailyDemandServiceScript.new()

func bind_dependencies(
	bound_warehouse_manager: WarehouseManager,
	bound_shelf_items: Array[Dictionary],
	bound_slot_count: int = DEFAULT_SLOT_COUNT
) -> void:
	warehouse_manager = bound_warehouse_manager
	shelf_items = bound_shelf_items
	slot_count = maxi(1, bound_slot_count)
	_ensure_slots()

func get_shelf_items() -> Array[Dictionary]:
	_ensure_slots()
	var result: Array[Dictionary] = []
	for item in shelf_items:
		result.append(item.duplicate(true) if item is Dictionary else {})
	return result

func query_shelfable_sale_goods() -> Array[Dictionary]:
	if warehouse_manager == null:
		return []
	var groups := {}
	var items := warehouse_manager.get_items_snapshot()
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if not _can_shelf_item(item):
			continue
		var item_id := String(item.get("item_id", ""))
		var unit_value := int(item.get("sell_value", 0))
		var currency_id := String(item.get("sell_currency_id", "mine_coin"))
		var group_id := "%s__%s__%d" % [item_id, currency_id, unit_value]
		if not groups.has(group_id):
			groups[group_id] = {
				"shelf_group_id": group_id,
				"item_id": item_id,
				"display_name": String(item.get("display_name", item_id)),
				"icon": String(item.get("icon", "")),
				"item_type": String(item.get("item_type", "")),
				"quality": String(item.get("quality", "")),
				"sell_currency_id": currency_id,
				"sell_value": unit_value,
				"count": 0,
				"warehouse_indexes": [],
			}
		groups[group_id].count += maxi(1, int(item.get("amount", 1)))
		groups[group_id].warehouse_indexes.append(index)
	var result: Array[Dictionary] = []
	for group in groups.values():
		result.append(Dictionary(group).duplicate(true))
	result.sort_custom(func(a, b):
		var value_delta := int(b.get("sell_value", 0)) - int(a.get("sell_value", 0))
		if value_delta != 0:
			return value_delta < 0
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return result

func move_group_to_shelf(shelf_group_id: String, slot_index: int) -> Dictionary:
	_ensure_slots()
	if warehouse_manager == null:
		return _fail("service_unavailable", "Shelf service unavailable.")
	if slot_index < 0 or slot_index >= slot_count:
		return _fail("invalid_slot", "Shelf slot does not exist.")
	if not _slot_is_empty(slot_index):
		return _fail("slot_occupied", "Shelf slot is occupied.")
	var group := _find_group(shelf_group_id)
	if group.is_empty():
		return _fail("item_not_found", "No shelfable warehouse item found.")
	var indexes: Array = Array(group.get("warehouse_indexes", []))
	if indexes.is_empty():
		return _fail("item_not_found", "No shelfable warehouse item found.")
	var item: Dictionary = warehouse_manager.remove_item_quantity_at_index(int(indexes[0]), 1)
	if item.is_empty():
		return _fail("remove_failed", "Shelf remove failed.")
	item["shelf_slot_index"] = slot_index
	item["amount"] = 1
	shelf_items[slot_index] = item
	return {"ok": true, "slot_index": slot_index, "item": item.duplicate(true), "message": "Shelved %s." % String(item.get("display_name", item.get("item_id", "")))}

func return_slot_to_warehouse(slot_index: int) -> Dictionary:
	_ensure_slots()
	if warehouse_manager == null:
		return _fail("service_unavailable", "Shelf service unavailable.")
	if slot_index < 0 or slot_index >= slot_count:
		return _fail("invalid_slot", "Shelf slot does not exist.")
	if _slot_is_empty(slot_index):
		return _fail("empty_slot", "Shelf slot is empty.")
	var item: Dictionary = shelf_items[slot_index].duplicate(true)
	item.erase("shelf_slot_index")
	var accepted := warehouse_manager.add_items([item])
	if accepted.size() != 1:
		return _fail("warehouse_full", "Warehouse has no space.")
	shelf_items[slot_index] = {}
	return {"ok": true, "slot_index": slot_index, "item": item, "message": "Returned %s." % String(item.get("display_name", item.get("item_id", "")))}

func pop_slot_for_sale(slot_index: int) -> Dictionary:
	_ensure_slots()
	if slot_index < 0 or slot_index >= slot_count or _slot_is_empty(slot_index):
		return {}
	var item: Dictionary = shelf_items[slot_index].duplicate(true)
	shelf_items[slot_index] = {}
	return item

func return_all_to_warehouse() -> Dictionary:
	_ensure_slots()
	if warehouse_manager == null:
		return _fail("service_unavailable", "Shelf service unavailable.")
	var returned := 0
	for slot_index in range(slot_count):
		if _slot_is_empty(slot_index):
			continue
		var result := return_slot_to_warehouse(slot_index)
		if not bool(result.get("ok", false)):
			return result
		returned += 1
	return {"ok": true, "returned": returned}

func has_shelf_goods() -> bool:
	_ensure_slots()
	for item in shelf_items:
		if item is Dictionary and not Dictionary(item).is_empty():
			return true
	return false

func has_warehouse_sale_goods() -> bool:
	return not query_shelfable_sale_goods().is_empty()

func _ensure_slots() -> void:
	while shelf_items.size() < slot_count:
		shelf_items.append({})
	while shelf_items.size() > slot_count:
		var tail: Dictionary = shelf_items.pop_back()
		if warehouse_manager != null and not tail.is_empty():
			tail.erase("shelf_slot_index")
			warehouse_manager.add_items([tail])

func _find_group(group_id: String) -> Dictionary:
	for group in query_shelfable_sale_goods():
		if String(group.get("shelf_group_id", "")) == group_id:
			return group
	return {}

func _slot_is_empty(slot_index: int) -> bool:
	return not (shelf_items[slot_index] is Dictionary) or Dictionary(shelf_items[slot_index]).is_empty()

func _can_shelf_item(item: Dictionary) -> bool:
	if String(item.get("item_id", "")).is_empty():
		return false
	if int(item.get("sell_value", 0)) <= 0:
		return false
	return demand_service.is_sale_good_item(item)

func _fail(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": code, "message": message}

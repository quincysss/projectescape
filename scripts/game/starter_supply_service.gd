class_name StarterSupplyService
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const PACK_PATH := "res://data/starter_supply/prologue_shop_starter_pack.json"

var data_registry = GameDataRegistryScript.new()
var data_loaded := false


func grant_prologue_shop_starter_pack(warehouse_manager: WarehouseManager) -> Dictionary:
	if warehouse_manager == null:
		return _fail("missing_warehouse", "Starter supply cannot be granted without warehouse access.")
	if not _ensure_data_loaded():
		return _fail("data_load_failed", "Starter supply data could not be loaded.")
	var pack := _load_pack()
	if pack.is_empty():
		return _fail("missing_pack", "Starter supply pack is missing or invalid.")

	var stacks: Array[Dictionary] = []
	for entry in Array(pack.get("items", [])):
		if not (entry is Dictionary):
			continue
		var item_id := String(entry.get("item_id", "")).strip_edges()
		var count := maxi(1, int(entry.get("count", 1)))
		var item := data_registry.get_item(item_id)
		if item.is_empty():
			return _fail("missing_item", "Starter supply item '%s' is not configured." % item_id)
		if _is_sale_good_item(item):
			return _fail("invalid_pack_item", "Starter supply pack must not grant sale_good item '%s'." % item_id)
		for _index in range(count):
			var stack := data_registry.make_item_stack(item_id, 1)
			if stack.is_empty():
				return _fail("invalid_item_stack", "Starter supply item '%s' cannot be stacked." % item_id)
			stack["source"] = String(pack.get("pack_id", "prologue_shop_starter_pack"))
			stacks.append(stack)
	if stacks.is_empty():
		return _fail("empty_pack", "Starter supply pack has no grantable items.")
	if not warehouse_manager.can_accept_items(stacks):
		return _fail("warehouse_full", "Warehouse does not have enough space for starter supply.")
	var accepted := warehouse_manager.add_items(stacks)
	if accepted.size() != stacks.size():
		return _fail("warehouse_add_failed", "Starter supply could not be fully added to warehouse.")
	return {
		"ok": true,
		"pack_id": String(pack.get("pack_id", "prologue_shop_starter_pack")),
		"granted_items": accepted,
	}


func _load_pack() -> Dictionary:
	if not FileAccess.file_exists(PACK_PATH):
		return {}
	var file := FileAccess.open(PACK_PATH, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return parsed if parsed is Dictionary else {}


func _ensure_data_loaded() -> bool:
	if data_loaded:
		return true
	data_loaded = data_registry.load_all()
	return data_loaded


func _is_sale_good_item(item: Dictionary) -> bool:
	if String(item.get("item_type", "")) == "sale_good":
		return true
	var tags = item.get("tags", "")
	if tags is Array:
		return Array(tags).has("sale_good")
	return String(tags).split(";", false).has("sale_good")


func _fail(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}

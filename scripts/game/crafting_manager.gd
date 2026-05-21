class_name CraftingManager
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")
const DEFAULT_CURRENCY_ID := "mine_coin"

var warehouse_manager: WarehouseManager
var currency_wallet: CurrencyWallet
var data_registry = GameDataRegistryScript.new()
var _data_loaded := false


func bind_dependencies(
	bound_warehouse_manager: WarehouseManager,
	bound_currency_wallet: CurrencyWallet
) -> void:
	warehouse_manager = bound_warehouse_manager
	currency_wallet = bound_currency_wallet


func query_recipes(_filters: Dictionary = {}) -> Array[Dictionary]:
	_ensure_data_loaded()
	var result: Array[Dictionary] = []
	for row in data_registry.get_crafting_recipe_rows():
		result.append(_make_recipe_view(row))
	result.sort_custom(func(a, b): return String(a.get("display_name", "")) < String(b.get("display_name", "")))
	return result


func get_craft_quote(recipe_id: String) -> Dictionary:
	_ensure_data_loaded()
	if warehouse_manager == null or currency_wallet == null:
		return _fail("service_unavailable", "制作所不可用。")
	var row := _find_recipe_row(recipe_id)
	if row.is_empty():
		return _fail("recipe_not_found", "制作配方不存在。")
	var requirements := _parse_item_requirements(String(row.get("required_items", "")))
	var output_item_id := String(row.get("output_item_id", ""))
	var output_count := maxi(1, int(row.get("output_count", 1)))
	var output_item := data_registry.get_item(output_item_id)
	if output_item.is_empty():
		return _fail("missing_output_item", "制作产物配置不存在。")
	var currency_id := _currency_id(row)
	var currency_amount := maxi(0, int(row.get("required_currency_amount", 0)))
	var missing_items := not warehouse_manager.has_items(requirements)
	var missing_currency := currency_wallet.get_currency_amount(currency_id) < currency_amount
	var can_craft := not missing_items and not missing_currency
	return {
		"ok": can_craft,
		"error": "" if can_craft else _quote_error(missing_items, missing_currency),
		"message": "可以制作。" if can_craft else _quote_message(missing_items, missing_currency),
		"recipe_id": recipe_id,
		"output_item_id": output_item_id,
		"display_name": String(output_item.get("name", output_item_id)),
		"output_count": output_count,
		"description": String(row.get("description", "")),
		"required_items": requirements,
		"requirement_details": _make_requirement_details(requirements),
		"required_currency_id": currency_id,
		"required_currency_amount": currency_amount,
		"current_currency_amount": currency_wallet.get_currency_amount(currency_id),
	}


func craft_recipe(recipe_id: String) -> Dictionary:
	var quote := get_craft_quote(recipe_id)
	if not bool(quote.get("ok", false)):
		return quote
	var requirements: Dictionary = quote.get("required_items", {})
	var consume_result: Dictionary = warehouse_manager.consume_items(requirements)
	if not bool(consume_result.get("ok", false)):
		return _fail(String(consume_result.get("reason", "consume_failed")), "制作材料扣除失败。")

	var currency_id := String(quote.get("required_currency_id", DEFAULT_CURRENCY_ID))
	var currency_amount := int(quote.get("required_currency_amount", 0))
	var spend_result := {"ok": true}
	if currency_amount > 0:
		spend_result = currency_wallet.spend_currency(currency_id, currency_amount, "craft:%s" % recipe_id)
	if not bool(spend_result.get("ok", false)):
		warehouse_manager.restore_removed_items(Array(consume_result.get("removed_entries", [])))
		return _fail(String(spend_result.get("reason", "currency_failed")), "制作货币扣除失败。")

	var output_item_id := String(quote.get("output_item_id", ""))
	var output_count := maxi(1, int(quote.get("output_count", 1)))
	var outputs: Array[Dictionary] = []
	for _index in range(output_count):
		var stack := data_registry.make_item_stack(output_item_id, 1)
		stack["source"] = "crafting"
		outputs.append(stack)
	var accepted := warehouse_manager.add_items(outputs)
	if accepted.size() != output_count:
		warehouse_manager.restore_removed_items(Array(consume_result.get("removed_entries", [])))
		if currency_amount > 0:
			currency_wallet.add_currency(currency_id, currency_amount, "craft_refund:%s" % recipe_id)
		return _fail("warehouse_full", "仓库空间不足，制作产物未入库。")
	var result := quote.duplicate(true)
	result["ok"] = true
	result["crafted_items"] = accepted
	result["message"] = "已制作：%s x%d。" % [String(quote.get("display_name", output_item_id)), output_count]
	return result


func _make_recipe_view(row: Dictionary) -> Dictionary:
	var quote := get_craft_quote(String(row.get("recipe_id", "")))
	var result := quote.duplicate(true)
	result["can_craft"] = bool(quote.get("ok", false))
	return result


func _find_recipe_row(recipe_id: String) -> Dictionary:
	for row in data_registry.get_crafting_recipe_rows():
		if String(row.get("recipe_id", "")) == recipe_id:
			return row.duplicate(true)
	return {}


func _make_requirement_details(requirements: Dictionary) -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	for item_id in requirements.keys():
		var id := String(item_id)
		var item := data_registry.get_item(id)
		var required := int(requirements[item_id])
		var owned := warehouse_manager.get_item_count(id) if warehouse_manager != null else 0
		details.append({
			"item_id": id,
			"display_name": String(item.get("name", id)),
			"required": required,
			"owned": owned,
			"enough": owned >= required,
		})
	return details


func _parse_item_requirements(value: String) -> Dictionary:
	var result := {}
	for part in TabDataLoaderScript.split_list(value):
		var cells := part.split(":", false, 1)
		if cells.size() != 2:
			continue
		var item_id := String(cells[0]).strip_edges()
		var count := maxi(0, int(String(cells[1]).strip_edges()))
		if item_id.is_empty() or count <= 0:
			continue
		result[item_id] = int(result.get(item_id, 0)) + count
	return result


func _currency_id(row: Dictionary) -> String:
	var currency_id := String(row.get("required_currency_id", DEFAULT_CURRENCY_ID))
	return DEFAULT_CURRENCY_ID if currency_id.is_empty() else currency_id


func _quote_error(missing_items: bool, missing_currency: bool) -> String:
	if missing_items and missing_currency:
		return "not_enough_items_and_currency"
	if missing_items:
		return "not_enough_items"
	if missing_currency:
		return "not_enough_currency"
	return ""


func _quote_message(missing_items: bool, missing_currency: bool) -> String:
	if missing_items and missing_currency:
		return "材料和矿币不足。"
	if missing_items:
		return "材料不足。"
	if missing_currency:
		return "矿币不足。"
	return "可以制作。"


func _ensure_data_loaded() -> bool:
	if _data_loaded:
		return true
	_data_loaded = data_registry.load_all()
	return _data_loaded


func _fail(code: String, message: String) -> Dictionary:
	return {"ok": false, "error": code, "message": message}

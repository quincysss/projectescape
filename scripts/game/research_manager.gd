class_name ResearchManager
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const DEFAULT_CURRENCY_ID := "mine_coin"
const EFFECT_PLAYER_MOVE_SPEED_MULTIPLIER := "player_move_speed_multiplier"

var warehouse_manager: WarehouseManager
var currency_wallet: CurrencyWallet
var research_levels: Dictionary = {}
var data_registry = GameDataRegistryScript.new()
var _data_loaded := false

func bind_dependencies(
	bound_warehouse_manager: WarehouseManager,
	bound_currency_wallet: CurrencyWallet,
	bound_research_levels: Dictionary
) -> void:
	warehouse_manager = bound_warehouse_manager
	currency_wallet = bound_currency_wallet
	research_levels = bound_research_levels

func query_research_items(_filters: Dictionary = {}) -> Array[Dictionary]:
	_ensure_data_loaded()
	var result: Array[Dictionary] = []
	for research_id in _get_research_ids():
		result.append(_make_research_view(research_id))
	return result

func get_research_quote(research_id: String) -> Dictionary:
	_ensure_data_loaded()
	if warehouse_manager == null or currency_wallet == null:
		return _fail("service_unavailable", "研究所不可用。")

	var row := _get_next_row(research_id)
	if row.is_empty():
		var max_row := _get_row_for_level(research_id, _get_max_level(research_id))
		if not max_row.is_empty():
			return _fail("max_level", "该研究已达到满级。")
		return _fail("research_not_found", "研究配置不存在。")

	var requirements := _parse_item_requirements(String(row.get("required_items", "")))
	var requirement_details := _make_requirement_details(requirements)
	var currency_id := _get_currency_id(row)
	var currency_amount := maxi(0, int(row.get("required_currency_amount", 0)))
	var missing_items := not warehouse_manager.has_items(requirements)
	var missing_currency := currency_wallet.get_currency_amount(currency_id) < currency_amount
	var can_research := not missing_items and not missing_currency
	return {
		"ok": can_research,
		"error": "" if can_research else _quote_error(missing_items, missing_currency),
		"message": "可以研究。" if can_research else _quote_message(missing_items, missing_currency),
		"research_id": research_id,
		"display_name": String(row.get("display_name", research_id)),
		"current_level": get_research_level(research_id),
		"next_level": int(row.get("level", 1)),
		"max_level": _get_max_level(research_id),
		"required_items": requirements,
		"requirement_details": requirement_details,
		"required_currency_id": currency_id,
		"required_currency_amount": currency_amount,
		"current_currency_amount": currency_wallet.get_currency_amount(currency_id),
		"effect_type": String(row.get("effect_type", "")),
		"effect_value": float(row.get("effect_value", 0.0)),
		"description": String(row.get("description", "")),
	}

func complete_research(research_id: String) -> Dictionary:
	var quote := get_research_quote(research_id)
	if not bool(quote.get("ok", false)):
		return quote

	var requirements: Dictionary = quote.get("required_items", {})
	var consume_result: Dictionary = warehouse_manager.consume_items(requirements)
	if not bool(consume_result.get("ok", false)):
		return _fail(String(consume_result.get("reason", "consume_failed")), "研究材料扣除失败。")

	var currency_id := String(quote.get("required_currency_id", DEFAULT_CURRENCY_ID))
	var currency_amount := int(quote.get("required_currency_amount", 0))
	var spend_result := {"ok": true}
	if currency_amount > 0:
		spend_result = currency_wallet.spend_currency(currency_id, currency_amount, "research:%s" % research_id)
	if not bool(spend_result.get("ok", false)):
		warehouse_manager.restore_removed_items(Array(consume_result.get("removed_entries", [])))
		return _fail(String(spend_result.get("reason", "currency_failed")), "研究货币扣除失败。")

	var next_level := int(quote.get("next_level", 1))
	research_levels[research_id] = next_level
	var result := quote.duplicate(true)
	result["ok"] = true
	result["completed_level"] = next_level
	result["message"] = "已完成研究：%s Lv.%d。" % [String(quote.get("display_name", research_id)), next_level]
	return result

func get_research_level(research_id: String) -> int:
	return clampi(int(research_levels.get(research_id, 0)), 0, _get_max_level(research_id))

func get_effect_value(effect_type: String, default_value: float = 1.0) -> float:
	_ensure_data_loaded()
	var value := default_value
	for research_id in _get_research_ids():
		var level := get_research_level(research_id)
		if level <= 0:
			continue
		var row := _get_row_for_level(research_id, level)
		if String(row.get("effect_type", "")) == effect_type:
			value = maxf(value, float(row.get("effect_value", default_value)))
	return value

func reset_research() -> void:
	research_levels.clear()

func _make_research_view(research_id: String) -> Dictionary:
	var current_level := get_research_level(research_id)
	var max_level := _get_max_level(research_id)
	var row := _get_next_row(research_id)
	var status := "AVAILABLE"
	if row.is_empty():
		row = _get_row_for_level(research_id, max_level)
		status = "COMPLETED"
	var quote := get_research_quote(research_id) if status != "COMPLETED" else {}
	var can_research := bool(quote.get("ok", false))
	if status != "COMPLETED" and not can_research:
		status = "LOCKED"
	return {
		"research_id": research_id,
		"display_name": String(row.get("display_name", research_id)),
		"category": String(row.get("category", "")),
		"current_level": current_level,
		"next_level": int(row.get("level", max_level)),
		"max_level": max_level,
		"status": status,
		"can_research": can_research,
		"required_items": quote.get("required_items", {}),
		"requirement_details": quote.get("requirement_details", []),
		"required_currency_id": String(quote.get("required_currency_id", _get_currency_id(row))),
		"required_currency_amount": int(quote.get("required_currency_amount", 0)),
		"current_currency_amount": int(quote.get("current_currency_amount", currency_wallet.get_currency_amount(_get_currency_id(row)) if currency_wallet != null else 0)),
		"effect_type": String(row.get("effect_type", "")),
		"effect_value": float(row.get("effect_value", 0.0)),
		"description": String(row.get("description", "")),
	}

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
	for part in TabDataLoader.split_list(value):
		var cells := part.split(":", false, 1)
		if cells.size() != 2:
			continue
		var item_id := String(cells[0]).strip_edges()
		var count := maxi(0, int(String(cells[1]).strip_edges()))
		if item_id.is_empty() or count <= 0:
			continue
		result[item_id] = int(result.get(item_id, 0)) + count
	return result

func _get_research_ids() -> Array[String]:
	var ids: Array[String] = []
	for row in data_registry.get_research_rows():
		var research_id := String(row.get("research_id", ""))
		if not research_id.is_empty() and not ids.has(research_id):
			ids.append(research_id)
	ids.sort()
	return ids

func _get_next_row(research_id: String) -> Dictionary:
	return _get_row_for_level(research_id, get_research_level(research_id) + 1)

func _get_row_for_level(research_id: String, level: int) -> Dictionary:
	for row in data_registry.get_research_rows():
		if String(row.get("research_id", "")) == research_id and int(row.get("level", 0)) == level:
			return row.duplicate(true)
	return {}

func _get_max_level(research_id: String) -> int:
	var max_level := 0
	for row in data_registry.get_research_rows():
		if String(row.get("research_id", "")) == research_id:
			max_level = maxi(max_level, int(row.get("max_level", row.get("level", 0))))
			max_level = maxi(max_level, int(row.get("level", 0)))
	return max_level

func _get_currency_id(row: Dictionary) -> String:
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
	return "可以研究。"

func _ensure_data_loaded() -> void:
	if _data_loaded:
		return
	_data_loaded = data_registry.load_all()

func _fail(code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error": code,
		"message": message,
	}

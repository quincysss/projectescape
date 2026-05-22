class_name ResearchManager
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const DEFAULT_CURRENCY_ID := "mine_coin"
const EFFECT_PLAYER_MOVE_SPEED_MULTIPLIER := "player_move_speed_multiplier"

# Kept only so older GameState binding code can keep the same call shape.
# Research must not read or consume warehouse materials; costs are mine_coin
# plus required_conditions only.
var _legacy_warehouse_manager: WarehouseManager
var currency_wallet: CurrencyWallet
var research_levels: Dictionary = {}
var condition_state: Dictionary = {}
var data_registry = GameDataRegistryScript.new()
var _data_loaded := false

func bind_dependencies(
	bound_warehouse_manager: WarehouseManager,
	bound_currency_wallet: CurrencyWallet,
	bound_research_levels: Dictionary,
	bound_condition_state: Dictionary = {}
) -> void:
	_legacy_warehouse_manager = bound_warehouse_manager
	currency_wallet = bound_currency_wallet
	research_levels = bound_research_levels
	condition_state = bound_condition_state

func query_research_items(_filters: Dictionary = {}) -> Array[Dictionary]:
	_ensure_data_loaded()
	var result: Array[Dictionary] = []
	for research_id in _get_research_ids():
		result.append(_make_research_view(research_id))
	return result

func get_research_quote(research_id: String) -> Dictionary:
	_ensure_data_loaded()
	if currency_wallet == null:
		return _fail("service_unavailable", "研究服务不可用。")

	var row := _get_next_row(research_id)
	if row.is_empty():
		var max_row := _get_row_for_level(research_id, _get_max_level(research_id))
		if not max_row.is_empty():
			return _fail("max_level", "研究已达最高等级。")
		return _fail("research_not_found", "研究配置不存在。")

	var conditions := _parse_required_conditions(String(row.get("required_conditions", "")))
	var condition_details := _make_condition_details(conditions)
	var currency_id := _get_currency_id(row)
	var currency_amount := maxi(0, int(row.get("required_currency_amount", 0)))
	var missing_conditions := _has_missing_conditions(condition_details)
	var missing_currency := currency_wallet.get_currency_amount(currency_id) < currency_amount
	var can_research := not missing_conditions and not missing_currency
	return {
		"ok": can_research,
		"error": "" if can_research else _quote_error(missing_conditions, missing_currency),
		"message": "可研究。" if can_research else _quote_message(missing_conditions, missing_currency),
		"research_id": research_id,
		"display_name": String(row.get("display_name", research_id)),
		"current_level": get_research_level(research_id),
		"next_level": int(row.get("level", 1)),
		"max_level": _get_max_level(research_id),
		"required_items": {},
		"requirement_details": [],
		"required_conditions": conditions,
		"condition_details": condition_details,
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

	var currency_id := String(quote.get("required_currency_id", DEFAULT_CURRENCY_ID))
	var currency_amount := int(quote.get("required_currency_amount", 0))
	var spend_result := {"ok": true}
	if currency_amount > 0:
		spend_result = currency_wallet.spend_currency(currency_id, currency_amount, "research:%s" % research_id)
	if not bool(spend_result.get("ok", false)):
		return _fail(String(spend_result.get("reason", "not_enough_currency")), "矿币不足。")

	var next_level := int(quote.get("next_level", 1))
	research_levels[research_id] = next_level
	var result := quote.duplicate(true)
	result["ok"] = true
	result["completed_level"] = next_level
	result["message"] = "研究完成：%s Lv.%d。" % [String(quote.get("display_name", research_id)), next_level]
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

func get_max_effect_value(effect_type: String, default_value: float = 1.0) -> float:
	_ensure_data_loaded()
	var value := default_value
	for row in data_registry.get_research_rows():
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
		"required_items": {},
		"requirement_details": [],
		"required_conditions": quote.get("required_conditions", []),
		"condition_details": quote.get("condition_details", []),
		"required_currency_id": String(quote.get("required_currency_id", _get_currency_id(row))),
		"required_currency_amount": int(quote.get("required_currency_amount", 0)),
		"current_currency_amount": int(quote.get("current_currency_amount", currency_wallet.get_currency_amount(_get_currency_id(row)) if currency_wallet != null else 0)),
		"effect_type": String(row.get("effect_type", "")),
		"effect_value": float(row.get("effect_value", 0.0)),
		"description": String(row.get("description", "")),
	}

func _parse_required_conditions(value: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for part in TabDataLoader.split_list(value):
		var condition := _parse_condition_token(part)
		if not condition.is_empty():
			result.append(condition)
	return result

func _parse_condition_token(token: String) -> Dictionary:
	var text := token.strip_edges()
	if text.is_empty():
		return {}

	var left := text
	var right := ""
	if text.contains(">="):
		var pieces := text.split(">=", false, 1)
		left = String(pieces[0]).strip_edges()
		right = String(pieces[1]).strip_edges()
	elif text.contains(":"):
		var pieces := text.split(":", false)
		left = String(pieces[0]).strip_edges()
		if pieces.size() >= 2:
			right = String(pieces[1]).strip_edges()
		if pieces.size() >= 3:
			right = "%s:%s" % [right, String(pieces[2]).strip_edges()]

	var condition_type := left.to_lower()
	match condition_type:
		"chapter", "required_chapter":
			return {"type": "chapter", "required": maxi(1, int(right))}
		"shop_level", "merchant_shop_level":
			return {"type": "shop_level", "required": maxi(1, int(right))}
		"research", "prerequisite_research", "prerequisite_research_id":
			var research_id := right
			var required_level := 1
			if right.contains(":"):
				var parts := right.split(":", false, 1)
				research_id = String(parts[0]).strip_edges()
				required_level = maxi(1, int(String(parts[1]).strip_edges()))
			if research_id.is_empty():
				return {}
			return {"type": "research", "id": research_id, "required": required_level}
		"task", "completed_task":
			return {} if right.is_empty() else {"type": "task", "id": right}
		"condition", "condition_id":
			return {} if right.is_empty() else {"type": "condition", "id": right}
		"fixture", "installed_fixture":
			return {} if right.is_empty() else {"type": "fixture", "id": right}
		_:
			if condition_type.begins_with("chapter_"):
				return {"type": "chapter", "required": maxi(1, int(condition_type.trim_prefix("chapter_")))}
			return {"type": "condition", "id": text}

func _make_condition_details(conditions: Array[Dictionary]) -> Array[Dictionary]:
	var details: Array[Dictionary] = []
	for condition in conditions:
		var detail := _make_condition_detail(condition)
		if not detail.is_empty():
			detail["enough"] = bool(detail.get("met", false))
			details.append(detail)
	return details

func _make_condition_detail(condition: Dictionary) -> Dictionary:
	var condition_type := String(condition.get("type", "condition"))
	var required := int(condition.get("required", 1))
	var id := String(condition.get("id", ""))
	match condition_type:
		"chapter":
			var current := int(condition_state.get("current_chapter", 1))
			return {
				"type": condition_type,
				"id": id,
				"display_name": "章节 >= %d" % required,
				"required": required,
				"current": current,
				"met": current >= required,
			}
		"shop_level":
			var current := int(condition_state.get("shop_level", 1))
			return {
				"type": condition_type,
				"id": id,
				"display_name": "店铺等级 >= %d" % required,
				"required": required,
				"current": current,
				"met": current >= required,
			}
		"research":
			var current := get_research_level(id)
			return {
				"type": condition_type,
				"id": id,
				"display_name": "研究 %s Lv.%d" % [id, required],
				"required": required,
				"current": current,
				"met": current >= required,
			}
		"task":
			var completed_tasks: Dictionary = condition_state.get("completed_tasks", {})
			var met := bool(completed_tasks.get(id, false))
			return {
				"type": condition_type,
				"id": id,
				"display_name": "任务完成：%s" % id,
				"required": 1,
				"current": 1 if met else 0,
				"met": met,
			}
		"fixture":
			var installed_fixtures: Dictionary = condition_state.get("installed_fixtures", {})
			var met := bool(installed_fixtures.get(id, false))
			return {
				"type": condition_type,
				"id": id,
				"display_name": "设施已安装：%s" % id,
				"required": 1,
				"current": 1 if met else 0,
				"met": met,
			}
		_:
			var met := bool(Dictionary(condition_state.get("conditions", {})).get(id, false))
			return {
				"type": condition_type,
				"id": id,
				"display_name": "条件达成：%s" % id,
				"required": 1,
				"current": 1 if met else 0,
				"met": met,
			}

func _has_missing_conditions(condition_details: Array[Dictionary]) -> bool:
	for detail in condition_details:
		if not bool(detail.get("met", false)):
			return true
	return false

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

func _quote_error(missing_conditions: bool, missing_currency: bool) -> String:
	if missing_conditions and missing_currency:
		return "conditions_not_met_and_not_enough_currency"
	if missing_conditions:
		return "conditions_not_met"
	if missing_currency:
		return "not_enough_currency"
	return ""

func _quote_message(missing_conditions: bool, missing_currency: bool) -> String:
	if missing_conditions and missing_currency:
		return "前置条件未满足，且矿币不足。"
	if missing_conditions:
		return "前置条件未满足。"
	if missing_currency:
		return "矿币不足。"
	return "可研究。"

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

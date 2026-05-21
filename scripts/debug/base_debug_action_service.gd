class_name BaseDebugActionService
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

var registry = GameDataRegistryScript.new()
var data_loaded := false
var load_error_message := ""

func add_currency(game_state: Node, amount: int = 500) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	var result: Dictionary = game_state.add_currency("mine_coin", amount, "debug_panel")
	return _message("已增加 %d 矿币。" % amount, "增加矿币失败。", result)

func add_sell_test_items(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	if not ensure_data_loaded():
		return _failure(load_error_message)
	var added := 0
	added += _add_item(game_state, "sale_good_repaired_filter", 2)
	added += _add_item(game_state, "sale_good_emergency_wrap", 2)
	added += _add_item(game_state, "sale_good_signal_lamp", 1)
	return {"ok": true, "message": "已加入 %d 个可售卖测试道具。" % added}

func refresh_shop(game_state: Node, level: int) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	var normalized_level := clampi(level, 1, 3)
	game_state.set_merchant_shop_level(normalized_level)
	var offers: Array = game_state.refresh_shop_stock()
	return {"ok": true, "message": "已刷新 Lv.%d 商人库存：%d 项。" % [normalized_level, offers.size()]}

func complete_next_research(game_state: Node, research_id: String) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	var fill_result := fill_next_research_costs(game_state, research_id)
	if not bool(fill_result.get("ok", false)):
		return fill_result
	var target_id := _target_research_id(research_id)
	var result: Dictionary = game_state.complete_research(target_id)
	return _message(String(result.get("message", "研究完成。")), String(result.get("message", "研究失败。")), result)

func reset_research(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	game_state.reset_research()
	return {"ok": true, "message": "已重置研究等级。"}

func reset_profile(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	var result: Dictionary = {}
	if game_state.has_method("reset_local_data_debug_only"):
		result = game_state.reset_local_data_debug_only()
	elif game_state.has_method("delete_profile_debug_only"):
		result = game_state.delete_profile_debug_only()
	else:
		return _failure("GameState 不支持重置本地数据。")
	if bool(result.get("ok", false)):
		return {"ok": true, "message": String(result.get("message", "已重置本地数据。"))}
	return _failure("重置本地数据失败：%s" % String(result.get("reason", result.get("error", "unknown"))))

func reset_story(game_state: Node) -> Dictionary:
	if game_state == null or not game_state.has_method("reset_story_flags"):
		return _failure("GameState 不支持重置剧情 flag。")
	game_state.reset_story_flags()
	return {"ok": true, "message": "已重置剧情 flag 与第一章状态。"}

func add_chapter_currency(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	game_state.add_currency("mine_coin", 100, "debug_chapter")
	return {"ok": true, "message": "已增加 100 矿币。"}

func advance_surface_day(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	game_state.reset_day(game_state.get_current_day() + 1)
	return {"ok": true, "message": "地表天数已 +1。"}

func force_chapter_complete(game_state: Node, manufacturing_unlock_cost: int) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	if game_state.has_method("activate_chapter_1_goal_debug"):
		game_state.activate_chapter_1_goal_debug()
	var missing := maxi(0, manufacturing_unlock_cost - game_state.get_currency_amount("mine_coin"))
	if missing > 0:
		game_state.add_currency("mine_coin", missing, "debug_force_chapter")
	var result: Dictionary = game_state.unlock_manufacturing_station()
	return _message(String(result.get("message", "强制完成第一章成功。")), String(result.get("message", "强制完成第一章失败。")), result)

func force_monster_next_run(game_state: Node) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	if game_state.has_method("debug_force_monster_presence_next_run"):
		game_state.debug_force_monster_presence_next_run()
	elif game_state.has_method("debug_force_scene_event_next_run"):
		game_state.debug_force_scene_event_next_run("monster_presence")
	else:
		return _failure("GameState 不支持强制场景事件。")
	return {"ok": true, "message": "下一次出发：本日必出怪物。"}

func fill_next_research_costs(game_state: Node, research_id: String) -> Dictionary:
	if game_state == null:
		return _failure("GameState 不可用。")
	if not ensure_data_loaded():
		return _failure(load_error_message)
	var target_id := _target_research_id(research_id)
	var quote: Dictionary = game_state.get_research_quote(target_id)
	if String(quote.get("error", "")) == "max_level":
		return _failure("%s 已满级，无需补齐。" % String(quote.get("display_name", target_id)))
	var added_items := 0
	for detail in Array(quote.get("requirement_details", [])):
		if not (detail is Dictionary):
			continue
		var item_id := String(detail.get("item_id", ""))
		var missing := maxi(0, int(detail.get("required", 0)) - int(detail.get("owned", 0)))
		added_items += _add_item(game_state, item_id, missing)
	var currency_id := String(quote.get("required_currency_id", "mine_coin"))
	var missing_currency := maxi(0, int(quote.get("required_currency_amount", 0)) - int(quote.get("current_currency_amount", 0)))
	if missing_currency > 0:
		game_state.add_currency(currency_id, missing_currency, "debug_research_costs")
	return {
		"ok": true,
		"message": "已补齐 %s 下一档：材料 +%d，矿币 +%d。" % [String(quote.get("display_name", target_id)), added_items, missing_currency],
	}

func ensure_data_loaded() -> bool:
	if data_loaded:
		return true
	data_loaded = registry.load_all()
	load_error_message = "" if data_loaded else "Debug 配置表加载失败：%s" % str(registry.load_errors)
	return data_loaded

func _target_research_id(research_id: String) -> String:
	return research_id if not research_id.is_empty() else "move_speed"

func _add_item(game_state: Node, item_id: String, count: int) -> int:
	if count <= 0 or item_id.is_empty():
		return 0
	var items: Array[Dictionary] = []
	for _index in range(count):
		var stack := registry.make_item_stack(item_id, 1)
		if not stack.is_empty():
			stack["source"] = "debug_panel"
			items.append(stack)
	var accepted: Array = game_state.add_to_warehouse(items)
	return accepted.size()

func _message(success_message: String, failure_message: String, result: Dictionary) -> Dictionary:
	var response := result.duplicate(true)
	response["result"] = result
	if bool(result.get("ok", false)):
		response["ok"] = true
		response["message"] = success_message
		return response
	response["ok"] = false
	response["message"] = failure_message
	return response

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

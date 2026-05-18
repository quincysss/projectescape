class_name BaseCraftingPanelController
extends RefCounted

var game_state: Node
var status_label: Label
var unlock_button: Button
var result_label: Label
var confirm_dialog: ConfirmationDialog
var unlock_cost := 5000


func setup(
	p_game_state: Node,
	p_status_label: Label,
	p_unlock_button: Button,
	p_result_label: Label,
	p_confirm_dialog: ConfirmationDialog,
	p_unlock_cost: int
) -> void:
	game_state = p_game_state
	status_label = p_status_label
	unlock_button = p_unlock_button
	result_label = p_result_label
	confirm_dialog = p_confirm_dialog
	unlock_cost = p_unlock_cost
	update_view()


func set_game_state(p_game_state: Node) -> void:
	game_state = p_game_state
	update_view()


func is_tab_available() -> bool:
	if game_state == null:
		return false
	return (
		bool(game_state.get("chapter_1_goal_active"))
		or bool(game_state.get("manufacturing_station_unlocked"))
		or bool(game_state.get("chapter_1_completed"))
	)


func update_view() -> void:
	if status_label == null or unlock_button == null:
		return
	if game_state == null:
		status_label.text = "制造所状态不可用。"
		unlock_button.disabled = true
		return

	var current_coin := _current_coin()
	var unlocked := bool(game_state.get("manufacturing_station_unlocked"))
	var goal_active := bool(game_state.get("chapter_1_goal_active"))
	if unlocked:
		status_label.text = "制造所已解锁。\n\n旧时代制造机已经接入哨所电力。也许，一切都还来得及。"
		unlock_button.visible = false
		_set_result("")
		return

	unlock_button.visible = true
	if not goal_active:
		status_label.text = "制造所尚未开放。\n\n先完成首次地面探索并返回基地。首次返回剧情结束后，第一章目标会正式开启。"
	else:
		status_label.text = "当前目标：购买旧时代制造机，解锁制造所\n\n出售可售物资，积攒 5000 矿币。制造所解锁后，也许妹妹还有救。\n\n矿币：%d / %d" % [
			current_coin,
			unlock_cost,
		]

	unlock_button.disabled = not _can_unlock()
	if not goal_active:
		_set_result("完成首次地面返回剧情后开放。")
	elif current_coin < unlock_cost:
		_set_result("还差 %d 矿币。去商人页签出售带回的道具。" % (unlock_cost - current_coin))
	else:
		_set_result("矿币已足够。确认购买旧时代制造机，解锁制造所。")


func request_unlock() -> bool:
	if game_state == null:
		return false
	if not _can_unlock():
		_set_result("矿币或章节目标条件不足。")
		update_view()
		return false
	if confirm_dialog != null:
		confirm_dialog.dialog_text = "确认解锁制造所？\n将消耗 %d 矿币。" % unlock_cost
		confirm_dialog.popup_centered()
	return true


func confirm_unlock() -> Dictionary:
	if game_state == null:
		return {"ok": false, "message": "制造所状态不可用。"}
	var result: Dictionary = game_state.unlock_manufacturing_station()
	_set_result(String(result.get("message", "制造所解锁失败。")))
	return result


func _can_unlock() -> bool:
	return bool(game_state.can_unlock_manufacturing_station()) if game_state != null and game_state.has_method("can_unlock_manufacturing_station") else false


func _current_coin() -> int:
	if game_state != null and game_state.has_method("get_currency_amount"):
		return int(game_state.get_currency_amount("mine_coin"))
	return 0


func _set_result(text: String) -> void:
	if result_label != null:
		result_label.text = text

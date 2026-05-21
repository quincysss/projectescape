class_name BaseCraftingPanelController
extends RefCounted

var game_state: Node
var status_label: Label
var unlock_button: Button
var result_label: Label
var confirm_dialog: ConfirmationDialog
var recipe_root: Control
var unlock_cost := 100
var selected_recipe_id := ""


func setup(
	p_game_state: Node,
	p_status_label: Label,
	p_unlock_button: Button,
	p_result_label: Label,
	p_confirm_dialog: ConfirmationDialog,
	p_unlock_cost: int,
	p_recipe_root: Control = null
) -> void:
	game_state = p_game_state
	status_label = p_status_label
	unlock_button = p_unlock_button
	result_label = p_result_label
	confirm_dialog = p_confirm_dialog
	unlock_cost = p_unlock_cost
	recipe_root = p_recipe_root
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
		status_label.text = "制作所状态不可用。"
		unlock_button.disabled = true
		_clear_recipe_root()
		return

	var current_coin := _current_coin()
	var unlocked := bool(game_state.get("manufacturing_station_unlocked"))
	var goal_active := bool(game_state.get("chapter_1_goal_active"))
	if unlocked:
		status_label.text = "制作所已解锁。\n\n选择配方，把仓库材料加工成白天店铺可上架的商品。"
		unlock_button.visible = false
		_set_result("")
		_set_recipe_cards()
		return

	unlock_button.visible = true
	_clear_recipe_root()
	if not goal_active:
		status_label.text = "制作所尚未开放。\n\n先完成首次地面探索并返回基地。首次返回剧情结束后，第一章目标会正式开启。"
	else:
		status_label.text = "当前目标：购买旧时代制造机，解锁制作所。\n\n出售可售物资，积攒 %d 矿币。制作所解锁后，可以把材料加工成白天店铺商品。\n\n矿币：%d / %d" % [
			unlock_cost,
			current_coin,
			unlock_cost,
		]

	unlock_button.disabled = not _can_unlock()
	if not goal_active:
		_set_result("完成首次地面返回剧情后开放。")
	elif current_coin < unlock_cost:
		_set_result("还差 %d 矿币。先完成白天营业结算。" % (unlock_cost - current_coin))
	else:
		_set_result("矿币已足够。确认购买旧时代制造机，解锁制作所。")


func request_unlock() -> bool:
	if game_state == null:
		return false
	if not _can_unlock():
		_set_result("矿币或章节目标条件不足。")
		update_view()
		return false
	if confirm_dialog != null:
		confirm_dialog.dialog_text = "确认解锁制作所？\n将消耗 %d 矿币。" % unlock_cost
		confirm_dialog.popup_centered()
	return true


func confirm_unlock() -> Dictionary:
	if game_state == null:
		return {"ok": false, "message": "制作所状态不可用。"}
	var result: Dictionary = game_state.unlock_manufacturing_station()
	_set_result(String(result.get("message", "制作所解锁失败。")))
	return result


func craft_selected(recipe_id: String = "") -> Dictionary:
	if game_state == null:
		return {"ok": false, "message": "制作所状态不可用。"}
	var resolved_id := recipe_id if not recipe_id.is_empty() else selected_recipe_id
	if resolved_id.is_empty():
		return {"ok": false, "message": "请先选择一个制作配方。"}
	var result: Dictionary = game_state.craft_recipe(resolved_id) if game_state.has_method("craft_recipe") else {"ok": false, "message": "制作系统不可用。"}
	_set_result(String(result.get("message", "制作失败。")))
	update_view()
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


func _set_recipe_cards() -> void:
	if recipe_root == null:
		return
	_clear_recipe_root()
	var recipes: Array = game_state.query_crafting_recipes() if game_state != null and game_state.has_method("query_crafting_recipes") else []
	recipe_root.custom_minimum_size = Vector2(620, maxf(260.0, float(maxi(1, recipes.size())) * 86.0))
	if recipes.is_empty():
		recipe_root.add_child(_make_section_label("暂无制作配方。", Vector2(0, 0), Vector2(520, 28), 15))
		return
	for index in range(recipes.size()):
		var recipe: Dictionary = recipes[index]
		var card := _make_recipe_card(recipe)
		card.position = Vector2(0.0, float(index) * 86.0)
		recipe_root.add_child(card)


func _make_recipe_card(recipe: Dictionary) -> Panel:
	var can_craft := bool(recipe.get("can_craft", false))
	var card := Panel.new()
	card.size = Vector2(620, 74)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.037, 0.037, 0.92), Color("#35C9D7") if can_craft else Color(0.25, 0.25, 0.23, 0.8), 1))
	var title := _make_section_label("%s x%d" % [String(recipe.get("display_name", "")), int(recipe.get("output_count", 1))], Vector2(12, 8), Vector2(270, 24), 16)
	card.add_child(title)
	var requirements: Array[String] = []
	for detail in Array(recipe.get("requirement_details", [])):
		if detail is Dictionary:
			requirements.append("%s %d/%d" % [
				String(detail.get("display_name", detail.get("item_id", ""))),
				int(detail.get("owned", 0)),
				int(detail.get("required", 0)),
			])
	var req_label := _make_section_label("材料：%s" % "，".join(requirements), Vector2(12, 36), Vector2(430, 24), 13)
	card.add_child(req_label)
	var button := Button.new()
	button.text = "制作"
	button.position = Vector2(506, 19)
	button.size = Vector2(86, 36)
	button.disabled = not can_craft
	button.pressed.connect(func():
		selected_recipe_id = String(recipe.get("recipe_id", ""))
		craft_selected(selected_recipe_id)
	)
	_style_button(button, true)
	card.add_child(button)
	return card


func _clear_recipe_root() -> void:
	if recipe_root == null:
		return
	for child in recipe_root.get_children():
		recipe_root.remove_child(child)
		child.queue_free()


func _make_section_label(text: String, pos: Vector2, label_size: Vector2, font_size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#D8D6CE"))
	return label


func _style_button(button: Button, important: bool) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#D8D6CE"))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.54, 0.50, 0.62))
	var border := Color("#D1B850") if important else Color("#35C9D7")
	button.add_theme_stylebox_override("normal", _panel_style(Color("#071116"), border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#121817"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.06, 0.06, 0.058, 0.55), Color("#4D575B"), 1))


func _panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

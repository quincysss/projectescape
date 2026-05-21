class_name BaseShopPanelController
extends RefCounted

const PHASE_DAY_PREP := "DAY_PREP"
const PHASE_SHOP_OPEN := "SHOP_OPEN"
const PHASE_SHOP_SETTLEMENT := "SHOP_SETTLEMENT"
const DAY_PANEL_POSITION := Vector2(1028, 154)

var game_state: Node
var ui_root: Control
var refresh_callback: Callable
var direct_departure_callback: Callable
var day_panel: Panel
var open_panel: Panel
var settlement_panel: Panel


func setup(
	p_game_state: Node,
	p_ui_root: Control,
	p_refresh_callback: Callable,
	p_direct_departure_callback: Callable = Callable()
) -> void:
	game_state = p_game_state
	ui_root = p_ui_root
	refresh_callback = p_refresh_callback
	direct_departure_callback = p_direct_departure_callback
	_build_surfaces()


func set_game_state(p_game_state: Node) -> void:
	game_state = p_game_state


func update_view(phase: String) -> void:
	if day_panel == null:
		return
	day_panel.visible = phase == PHASE_DAY_PREP and _is_shop_loop_unlocked()
	open_panel.visible = phase == PHASE_SHOP_OPEN
	settlement_panel.visible = phase == PHASE_SHOP_SETTLEMENT
	if day_panel.visible:
		_render_day_panel()
	if open_panel.visible:
		_render_open_panel()
	if settlement_panel.visible:
		_render_settlement_panel()


func _build_surfaces() -> void:
	if ui_root == null or day_panel != null:
		return
	day_panel = _make_panel("ShopDayPrepPanel", DAY_PANEL_POSITION, Vector2(244, 500), "今日订单")
	var day_title := day_panel.get_node_or_null("PanelTitle") as Label
	if day_title != null:
		day_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_root.add_child(day_panel)
	open_panel = _make_panel("ShopOpenPanel", Vector2(24, 154), Vector2(980, 500), "店铺营业")
	open_panel.visible = false
	ui_root.add_child(open_panel)
	settlement_panel = _make_panel("ShopSettlementPanel", Vector2(24, 154), Vector2(980, 500), "营业结算")
	settlement_panel.visible = false
	ui_root.add_child(settlement_panel)


func _render_day_panel() -> void:
	_clear_panel_body(day_panel)
	if game_state == null:
		day_panel.add_child(_make_label("GameState 不可用。", Vector2(16, 58), Vector2(200, 60), 14))
		return
	var demand_entries: Array = game_state.ensure_daily_demand() if game_state.has_method("ensure_daily_demand") else []
	var demand_text := _format_demand(demand_entries)
	var label := _make_label(demand_text, Vector2(18, 58), Vector2(208, 280), 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_panel.add_child(label)
	var hint := _make_label("在制造所制造货物。", Vector2(18, 342), Vector2(208, 70), 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_panel.add_child(hint)
	var button := Button.new()
	button.text = "开店营业"
	button.position = Vector2(34, 430)
	button.size = Vector2(176, 42)
	button.pressed.connect(_on_open_shop_pressed)
	_style_button(button, true)
	day_panel.add_child(button)


func _render_open_panel() -> void:
	_clear_panel_body(open_panel)
	if game_state == null:
		open_panel.add_child(_make_label("GameState 不可用。", Vector2(18, 58), Vector2(240, 40), 14))
		return
	var remaining := int(ceil(float(game_state.get_shop_time_remaining())))
	var countdown := _make_label("剩余时间：%02d:%02d" % [int(remaining / 60), remaining % 60], Vector2(760, 16), Vector2(180, 30), 18)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	open_panel.add_child(countdown)
	open_panel.add_child(_make_label("货台", Vector2(24, 58), Vector2(180, 26), 18))
	_render_shelf_slots(open_panel)
	open_panel.add_child(_make_label("可上架商品", Vector2(24, 236), Vector2(180, 26), 18))
	_render_shelfable_goods(open_panel)
	open_panel.add_child(_make_label("今日订单", Vector2(704, 58), Vector2(180, 26), 18))
	open_panel.add_child(_make_label(_format_demand(game_state.get_daily_demand_entries()), Vector2(704, 94), Vector2(232, 210), 14))
	open_panel.add_child(_make_label(_format_sales_log(game_state.get_shop_sales_records()), Vector2(704, 322), Vector2(232, 92), 13))
	var close_button := Button.new()
	close_button.text = "提前结束营业"
	close_button.position = Vector2(744, 430)
	close_button.size = Vector2(172, 42)
	close_button.pressed.connect(_on_finish_shop_pressed)
	_style_button(close_button, bool(game_state.should_highlight_early_close()))
	open_panel.add_child(close_button)


func _render_settlement_panel() -> void:
	_clear_panel_body(settlement_panel)
	if game_state == null:
		settlement_panel.add_child(_make_label("GameState 不可用。", Vector2(18, 58), Vector2(240, 40), 14))
		return
	var snapshot: Dictionary = game_state.get_shop_settlement_snapshot()
	var records: Array = snapshot.get("records", [])
	if records.is_empty():
		settlement_panel.add_child(_make_label("今日未售出商品。未售出的货台商品会退回仓库。", Vector2(34, 70), Vector2(520, 42), 16))
	else:
		var y := 72.0
		for record in records:
			if not (record is Dictionary):
				continue
			settlement_panel.add_child(_make_label(
				"%s x%d  单价 %d  小计 %d" % [
					String(record.get("display_name", "")),
					int(record.get("count", 1)),
					int(record.get("unit_price", 0)),
					int(record.get("subtotal", 0)),
				],
				Vector2(34, y),
				Vector2(620, 26),
				15
			))
			y += 32.0
	var total_label := _make_label("总收入：%d 矿币" % int(snapshot.get("total_earned", 0)), Vector2(34, 364), Vector2(300, 34), 22)
	settlement_panel.add_child(total_label)
	var close_button := Button.new()
	close_button.text = "出发"
	close_button.position = Vector2(724, 418)
	close_button.size = Vector2(180, 44)
	close_button.pressed.connect(_on_close_settlement_pressed)
	_style_button(close_button, true)
	settlement_panel.add_child(close_button)


func _render_shelf_slots(parent: Control) -> void:
	var shelf_items: Array = game_state.get_shelf_items()
	for index in range(3):
		var card := Panel.new()
		card.name = "ShelfSlot%d" % index
		card.position = Vector2(24 + float(index) * 214.0, 94)
		card.size = Vector2(196, 118)
		card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.037, 0.037, 0.94), Color("#35C9D7"), 1))
		var item: Dictionary = shelf_items[index] if index < shelf_items.size() and shelf_items[index] is Dictionary else {}
		var title := "空货台"
		var detail := "等待上架"
		if not item.is_empty():
			title = String(item.get("display_name", item.get("item_id", "")))
			detail = "售价基准 %d" % int(item.get("sell_value", 0))
		card.add_child(_make_label(title, Vector2(12, 12), Vector2(170, 26), 15))
		card.add_child(_make_label(detail, Vector2(12, 42), Vector2(170, 24), 13))
		if not item.is_empty():
			var button := Button.new()
			button.text = "下架"
			button.position = Vector2(58, 76)
			button.size = Vector2(78, 30)
			var slot_index := index
			button.pressed.connect(func(): _on_return_shelf_pressed(slot_index))
			_style_button(button, false)
			card.add_child(button)
		parent.add_child(card)


func _render_shelfable_goods(parent: Control) -> void:
	var goods: Array = game_state.query_shelfable_sale_goods()
	if goods.is_empty():
		parent.add_child(_make_label("仓库里暂无可上架的局外商品。先在制作所生产 sale_good。", Vector2(24, 272), Vector2(620, 42), 14))
		return
	var y := 270.0
	for group in goods:
		if not (group is Dictionary):
			continue
		var row := Panel.new()
		row.position = Vector2(24, y)
		row.size = Vector2(630, 44)
		row.add_theme_stylebox_override("panel", _panel_style(Color(0.028, 0.030, 0.030, 0.88), Color(0.18, 0.30, 0.31, 0.9), 1))
		row.add_child(_make_label("%s x%d  基准价 %d" % [
			String(group.get("display_name", "")),
			int(group.get("count", 0)),
			int(group.get("sell_value", 0)),
		], Vector2(12, 9), Vector2(390, 24), 14))
		var button := Button.new()
		button.text = "上架"
		button.position = Vector2(520, 7)
		button.size = Vector2(82, 30)
		var group_id := String(group.get("shelf_group_id", ""))
		button.pressed.connect(func(): _on_shelf_good_pressed(group_id))
		_style_button(button, true)
		row.add_child(button)
		parent.add_child(row)
		y += 50.0


func _on_open_shop_pressed() -> void:
	if game_state != null and game_state.has_method("start_shop_open"):
		game_state.start_shop_open()
	_call_refresh()


func _on_finish_shop_pressed() -> void:
	if game_state != null and game_state.has_method("finish_shop_open"):
		var finish_result: Dictionary = game_state.finish_shop_open("manual")
		if bool(finish_result.get("ok", false)):
			_call_refresh()
			return
	_call_refresh()


func _on_close_settlement_pressed() -> void:
	_close_settlement_and_depart()


func _close_settlement_and_depart() -> void:
	if game_state != null and game_state.has_method("close_shop_settlement_to_night"):
		var close_result: Dictionary = game_state.close_shop_settlement_to_night()
		if bool(close_result.get("ok", false)):
			if direct_departure_callback.is_valid():
				direct_departure_callback.call()
			else:
				_call_refresh()
			return
	_call_refresh()


func _on_shelf_good_pressed(group_id: String) -> void:
	if game_state == null:
		return
	var empty_slot := _first_empty_shelf_slot()
	if empty_slot < 0:
		return
	game_state.move_sale_good_to_shelf(group_id, empty_slot)
	_call_refresh()


func _on_return_shelf_pressed(slot_index: int) -> void:
	if game_state != null:
		game_state.return_shelf_item_to_warehouse(slot_index)
	_call_refresh()


func _first_empty_shelf_slot() -> int:
	var shelf_items: Array = game_state.get_shelf_items() if game_state != null else []
	for index in range(shelf_items.size()):
		if not (shelf_items[index] is Dictionary) or Dictionary(shelf_items[index]).is_empty():
			return index
	return -1


func _format_demand(entries: Array) -> String:
	if entries.is_empty():
		return "暂无需求数据。"
	var lines: Array[String] = []
	var max_count := mini(5, entries.size())
	for index in range(max_count):
		var entry: Dictionary = entries[index]
		lines.append("%d. %s  预估价 %d" % [
			int(entry.get("rank", index + 1)),
			String(entry.get("display_name", "")),
			int(entry.get("estimated_unit_price", 0)),
		])
	return "\n".join(lines)


func _format_sales_log(records: Array) -> String:
	if records.is_empty():
		return "成交记录：暂无"
	var lines: Array[String] = ["成交记录："]
	var start := maxi(0, records.size() - 3)
	for index in range(start, records.size()):
		var record: Dictionary = records[index]
		lines.append("%s +%d" % [String(record.get("display_name", "")), int(record.get("subtotal", 0))])
	return "\n".join(lines)


func _call_refresh() -> void:
	if refresh_callback.is_valid():
		refresh_callback.call()


func _is_shop_loop_unlocked() -> bool:
	if game_state == null:
		return false
	if game_state.has_method("is_shop_loop_unlocked"):
		return bool(game_state.is_shop_loop_unlocked())
	return bool(game_state.get("shop_loop_unlocked"))


func _clear_panel_body(panel: Panel) -> void:
	for child in panel.get_children():
		if String(child.name) == "PanelTitle":
			continue
		panel.remove_child(child)
		child.queue_free()


func _make_panel(node_name: String, pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.94), Color(0.26, 0.25, 0.23, 0.95), 1))
	var title_label := _make_label(title, Vector2(18, 12), Vector2(panel_size.x - 36.0, 30), 20)
	title_label.name = "PanelTitle"
	panel.add_child(title_label)
	return panel


func _make_label(text: String, pos: Vector2, label_size: Vector2, font_size: int = 15) -> Label:
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

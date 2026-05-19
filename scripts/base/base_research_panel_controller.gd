class_name BaseResearchPanelController
extends RefCounted

const RESEARCH_NODE_SIZE := 70.0
const RESEARCH_NODE_GAP := 116.0
const RESEARCH_ROW_HEIGHT := 106.0
const MATERIAL_SLOT_WIDTH := 64.0
const MATERIAL_SLOT_HEIGHT := 58.0
const MATERIAL_SLOT_GAP := 14.0
const MATERIAL_ROW_GAP := 14.0

var game_state: Node
var data_registry
var ensure_data_loaded_callback: Callable
var tooltip_view

var research_list: RichTextLabel
var research_button: Button
var research_quote_label: Label
var research_result_label: Label
var research_confirm_dialog: ConfirmationDialog
var research_tree_root: Control
var detail_title_label: Label
var detail_description_label: Label
var requirement_grid_root: Control
var currency_cost_label: Label

var selected_research_id := ""


func setup(
	p_game_state: Node,
	p_data_registry,
	p_ensure_data_loaded_callback: Callable,
	p_tooltip_view,
	p_research_list: RichTextLabel,
	p_research_button: Button,
	p_research_quote_label: Label,
	p_research_result_label: Label,
	p_research_confirm_dialog: ConfirmationDialog,
	p_research_tree_root: Control,
	p_detail_title_label: Label,
	p_detail_description_label: Label,
	p_requirement_grid_root: Control,
	p_currency_cost_label: Label
) -> void:
	game_state = p_game_state
	data_registry = p_data_registry
	ensure_data_loaded_callback = p_ensure_data_loaded_callback
	tooltip_view = p_tooltip_view
	research_list = p_research_list
	research_button = p_research_button
	research_quote_label = p_research_quote_label
	research_result_label = p_research_result_label
	research_confirm_dialog = p_research_confirm_dialog
	research_tree_root = p_research_tree_root
	detail_title_label = p_detail_title_label
	detail_description_label = p_detail_description_label
	requirement_grid_root = p_requirement_grid_root
	currency_cost_label = p_currency_cost_label
	update_selected_state()


func set_game_state(p_game_state: Node) -> void:
	game_state = p_game_state
	update_selected_state()


func set_selected_research_id(research_id: String) -> void:
	selected_research_id = research_id


func clear_selection() -> void:
	selected_research_id = ""
	update_selected_state()


func clear_result() -> void:
	if research_result_label != null:
		research_result_label.text = ""


func set_items_text(items: Array) -> void:
	if research_list == null:
		return
	research_list.clear()
	_set_research_tree(items)
	if items.is_empty():
		research_list.append_text("研究所：暂无研究项目")
		return
	var lines: Array[String] = ["研究所："]
	for item in items:
		if item is Dictionary:
			var research_id := String(item.get("research_id", ""))
			var name := String(item.get("display_name", research_id))
			var current_level := int(item.get("current_level", 0))
			var max_level := int(item.get("max_level", 0))
			var effect_text := _format_effect(String(item.get("effect_type", "")), float(item.get("effect_value", 0.0)))
			var status := String(item.get("status", "LOCKED"))
			var status_text := "可研究" if bool(item.get("can_research", false)) else "材料不足"
			if status == "COMPLETED":
				status_text = "已满级"
			lines.append("[url=research:%s]- %s Lv.%d/%d  %s  %s[/url]" % [
				research_id,
				name,
				current_level,
				max_level,
				effect_text,
				status_text,
			])
	research_list.append_text("\n".join(lines))


func handle_meta_clicked(meta: Variant) -> bool:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "research":
		return false
	select_research(parts[1])
	return true


func select_research(research_id: String) -> void:
	selected_research_id = research_id
	clear_result()
	update_selected_state()
	_set_research_tree(_query_research_items())


func update_selected_state() -> void:
	if game_state == null or selected_research_id.is_empty():
		selected_research_id = ""
		if research_button != null:
			research_button.disabled = true
		if research_quote_label != null:
			research_quote_label.text = "选择一个研究项目"
		_update_detail({})
		return
	var quote: Dictionary = game_state.get_research_quote(selected_research_id)
	var ok := bool(quote.get("ok", false))
	if research_button != null:
		research_button.disabled = not ok
	if quote.is_empty():
		if research_quote_label != null:
			research_quote_label.text = "选择一个研究项目"
		_update_detail({})
		return
	if research_quote_label != null:
		research_quote_label.text = format_quote(quote)
	_update_detail(quote)


func request_research() -> bool:
	if game_state == null or selected_research_id.is_empty():
		return false
	var quote: Dictionary = game_state.get_research_quote(selected_research_id)
	if not bool(quote.get("ok", false)):
		if research_result_label != null:
			research_result_label.text = String(quote.get("message", "研究条件不足。"))
		update_selected_state()
		return false
	if research_confirm_dialog != null:
		research_confirm_dialog.dialog_text = "%s\n\n确认后将消耗上列材料与矿币，无法撤销。" % format_quote(quote)
		research_confirm_dialog.popup_centered()
	return true


func confirm_research() -> Dictionary:
	if game_state == null or selected_research_id.is_empty():
		return {"ok": false, "message": "研究状态不可用。"}
	var result: Dictionary = game_state.complete_research(selected_research_id)
	if research_result_label != null:
		research_result_label.text = String(result.get("message", "研究失败。"))
	if bool(result.get("ok", false)):
		selected_research_id = ""
	return result


func format_quote(quote: Dictionary) -> String:
	var material_parts: Array[String] = []
	for detail in Array(quote.get("requirement_details", [])):
		if detail is Dictionary:
			material_parts.append("%s %d/%d" % [
				String(detail.get("display_name", detail.get("item_id", ""))),
				int(detail.get("owned", 0)),
				int(detail.get("required", 0)),
			])
	var currency_need := int(quote.get("required_currency_amount", 0))
	var currency_owned := int(quote.get("current_currency_amount", 0))
	var effect_text := _format_effect(String(quote.get("effect_type", "")), float(quote.get("effect_value", 0.0)))
	return "%s Lv.%d：%s；矿币 %d/%d；完成后%s。" % [
		String(quote.get("display_name", "")),
		int(quote.get("next_level", 0)),
		"、".join(material_parts),
		currency_owned,
		currency_need,
		effect_text,
	]


func _set_research_tree(items: Array) -> void:
	if research_tree_root == null:
		return
	for child in research_tree_root.get_children():
		research_tree_root.remove_child(child)
		child.queue_free()
	var rows_by_id := _research_rows_by_id()
	if rows_by_id.is_empty():
		research_tree_root.custom_minimum_size = Vector2(680, 120)
		research_tree_root.size = research_tree_root.custom_minimum_size
		research_tree_root.add_child(_make_label("研究配置不可用", Vector2(12, 12), Vector2(240, 28), 16, Color("#D8D6CE")))
		return
	var ordered_ids := _ordered_research_ids(rows_by_id, items)
	var max_nodes := 1
	for research_id in ordered_ids:
		max_nodes = maxi(max_nodes, Array(rows_by_id[research_id]).size())
	var content_width := maxf(680.0, 168.0 + float(maxi(max_nodes, 5) - 1) * RESEARCH_NODE_GAP + RESEARCH_NODE_SIZE + 24.0)
	var content_height := maxf(360.0, float(ordered_ids.size()) * RESEARCH_ROW_HEIGHT + 18.0)
	research_tree_root.custom_minimum_size = Vector2(content_width, content_height)
	research_tree_root.size = research_tree_root.custom_minimum_size

	for row_index in range(ordered_ids.size()):
		var research_id := String(ordered_ids[row_index])
		var rows: Array = rows_by_id[research_id]
		rows.sort_custom(func(a, b): return int(a.get("level", 0)) < int(b.get("level", 0)))
		if rows.is_empty():
			continue
		var row_y := float(row_index) * RESEARCH_ROW_HEIGHT
		var title := _line_title(rows[0])
		var title_label := _make_label(title, Vector2(10, row_y + 28.0), Vector2(136, 28), 16, Color("#D8D6CE"))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		research_tree_root.add_child(title_label)
		var current_level := _research_level(research_id)
		var quote: Dictionary = {}
		if game_state != null and game_state.has_method("get_research_quote"):
			quote = game_state.get_research_quote(research_id)
		for level_index in range(rows.size()):
			var row: Dictionary = rows[level_index]
			var node_x := 168.0 + float(level_index) * RESEARCH_NODE_GAP
			var node_y := row_y + 14.0
			var node := _make_research_node(research_id, row, current_level, quote)
			node.position = Vector2(node_x, node_y)
			research_tree_root.add_child(node)
			if level_index < rows.size() - 1:
				research_tree_root.add_child(_make_research_arrow(Vector2(node_x + RESEARCH_NODE_SIZE + 16.0, node_y + 18.0)))


func _make_research_node(research_id: String, row: Dictionary, current_level: int, quote: Dictionary) -> Button:
	var level := int(row.get("level", 0))
	var max_level := int(row.get("max_level", level))
	var button := Button.new()
	button.size = Vector2(RESEARCH_NODE_SIZE, RESEARCH_NODE_SIZE)
	button.text = _roman_level(level)
	button.tooltip_text = "%s\n%s\n%s" % [
		String(row.get("display_name", research_id)),
		String(row.get("description", "")),
		_format_effect(String(row.get("effect_type", "")), float(row.get("effect_value", 0.0))),
	]
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#F0EADF"))
	var is_completed := level <= current_level
	var is_next := level == current_level + 1
	var is_available := is_next and bool(quote.get("ok", false))
	var selected_level := clampi(current_level + 1, 1, max_level)
	var is_selected := selected_research_id == research_id and level == selected_level
	var fill := Color("#071116")
	var border := Color("#4D575B")
	if is_completed:
		fill = Color(0.12, 0.18, 0.15, 0.96)
		border = Color("#75C77B")
	elif is_available:
		fill = Color("#0B151A")
		border = Color("#35C9D7")
	elif is_next:
		fill = Color(0.11, 0.10, 0.08, 0.96)
		border = Color("#8B6B34")
	if is_selected:
		border = Color("#D1B850")
	button.add_theme_stylebox_override("normal", _circle_style(fill, border, 3 if is_selected else 2))
	button.add_theme_stylebox_override("hover", _circle_style(Color("#121817"), Color("#D1B850"), 3))
	button.add_theme_stylebox_override("pressed", _circle_style(Color("#121817"), Color("#D1B850"), 4))
	button.button_up.connect(func(): select_research(research_id))
	return button


func _make_research_arrow(pos: Vector2) -> Label:
	var arrow := Label.new()
	arrow.position = pos
	arrow.size = Vector2(42, 28)
	arrow.text = "->"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(arrow, 26, Color("#D8C3C8"))
	return arrow


func _update_detail(quote: Dictionary) -> void:
	if detail_title_label == null or detail_description_label == null or requirement_grid_root == null or currency_cost_label == null:
		return
	_clear_requirement_slots()
	if game_state == null or selected_research_id.is_empty() or quote.is_empty():
		detail_title_label.text = "研究所"
		detail_description_label.text = ""
		currency_cost_label.text = ""
		currency_cost_label.add_theme_color_override("font_color", Color("#D8D6CE"))
		if research_button != null:
			research_button.disabled = true
		return
	var row := _selected_detail_row()
	var title := _line_title(row) if not row.is_empty() else String(quote.get("display_name", selected_research_id))
	var description := String(row.get("description", quote.get("description", ""))) if not row.is_empty() else String(quote.get("description", ""))
	detail_title_label.text = title
	detail_description_label.text = description
	_set_requirement_slots(Array(quote.get("requirement_details", [])))
	if String(quote.get("error", "")) == "max_level":
		currency_cost_label.text = "已满级"
		currency_cost_label.add_theme_color_override("font_color", Color("#D1B850"))
		if research_button != null:
			research_button.disabled = true
		return
	var currency_need := int(quote.get("required_currency_amount", 0))
	var currency_owned := int(quote.get("current_currency_amount", 0))
	currency_cost_label.text = "矿币消耗：%d" % currency_need
	var currency_enough := currency_owned >= currency_need
	currency_cost_label.add_theme_color_override("font_color", Color("#D1B850") if currency_enough else Color("#B96B6B"))
	if research_button != null:
		research_button.disabled = not bool(quote.get("ok", false))


func _set_requirement_slots(details: Array) -> void:
	_clear_requirement_slots()
	if requirement_grid_root == null:
		return
	var visible_details := details.slice(0, mini(details.size(), 6))
	for index in range(visible_details.size()):
		var detail = visible_details[index]
		if not (detail is Dictionary):
			continue
		var detail_dict: Dictionary = detail
		var row := int(index / 3)
		var col := index % 3
		var slots_in_row := mini(3, visible_details.size() - row * 3)
		var row_width := float(slots_in_row) * MATERIAL_SLOT_WIDTH + float(slots_in_row - 1) * MATERIAL_SLOT_GAP
		var start_x := (requirement_grid_root.size.x - row_width) * 0.5
		var slot_pos := Vector2(
			start_x + float(col) * (MATERIAL_SLOT_WIDTH + MATERIAL_SLOT_GAP),
			float(row) * (MATERIAL_SLOT_HEIGHT + MATERIAL_ROW_GAP)
		)
		requirement_grid_root.add_child(_make_material_slot(detail_dict, slot_pos))


func _make_material_slot(detail: Dictionary, pos: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(MATERIAL_SLOT_WIDTH, MATERIAL_SLOT_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var enough := bool(detail.get("enough", false))
	panel.add_theme_stylebox_override("panel", _slot_style(Color("#071116"), Color("#35C9D7") if enough else Color("#8B4F4F"), 1))
	var material_name := String(detail.get("display_name", detail.get("item_id", "")))
	panel.tooltip_text = ""
	var item_id := String(detail.get("item_id", ""))
	var item_def: Dictionary = data_registry.get_item(item_id) if _ensure_data_loaded() and data_registry != null and data_registry.has_method("get_item") else {}
	var icon_path := String(item_def.get("icon", ""))
	var texture := _icon_texture(icon_path)
	if texture != null:
		var icon := TextureRect.new()
		icon.name = "ResearchMaterialIcon"
		icon.position = Vector2((panel.size.x - 28.0) * 0.5, 4.0)
		icon.size = Vector2(28.0, 28.0)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
	else:
		var name_label := Label.new()
		name_label.position = Vector2(4, 6)
		name_label.size = Vector2(panel.size.x - 8.0, 22)
		name_label.text = material_name
		name_label.clip_text = true
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_style_label(name_label, 10, Color("#D8D6CE"))
		panel.add_child(name_label)

	var count_label := Label.new()
	count_label.position = Vector2(4, 34)
	count_label.size = Vector2(panel.size.x - 8.0, 20)
	count_label.text = "%d/%d" % [int(detail.get("owned", 0)), int(detail.get("required", 0))]
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(count_label, 13, Color("#D8D6CE") if enough else Color("#D7A0A0"))
	panel.add_child(count_label)
	if tooltip_view != null:
		tooltip_view.bind(panel, {
			"item_id": item_id,
			"display_name": material_name,
		}, "research", {
			"context": "research",
			"owned_count": int(detail.get("owned", 0)),
			"required_count": int(detail.get("required", 0)),
			"show_requirement_state": true,
		})
	return panel


func _clear_requirement_slots() -> void:
	if requirement_grid_root == null:
		return
	for child in requirement_grid_root.get_children():
		requirement_grid_root.remove_child(child)
		child.queue_free()


func _selected_detail_row() -> Dictionary:
	if selected_research_id.is_empty() or not _ensure_data_loaded():
		return {}
	var current_level := _research_level(selected_research_id)
	var best_row: Dictionary = {}
	var max_level := 0
	for row in data_registry.get_research_rows():
		if String(row.get("research_id", "")) != selected_research_id:
			continue
		var level := int(row.get("level", 0))
		max_level = maxi(max_level, level)
		if level == current_level + 1:
			return row
		if level > int(best_row.get("level", 0)):
			best_row = row
	if current_level >= max_level:
		return best_row
	return best_row


func _research_rows_by_id() -> Dictionary:
	var result := {}
	if not _ensure_data_loaded():
		return result
	for row in data_registry.get_research_rows():
		var research_id := String(row.get("research_id", ""))
		if research_id.is_empty():
			continue
		if not result.has(research_id):
			result[research_id] = []
		result[research_id].append(row)
	return result


func _ordered_research_ids(rows_by_id: Dictionary, items: Array) -> Array[String]:
	var preferred: Array[String] = ["move_speed", "inventory_slots", "home_storage_slots", "outpost_storage_slots", "max_stability", "warehouse_capacity"]
	var ids: Array[String] = []
	for research_id in preferred:
		if rows_by_id.has(research_id):
			ids.append(research_id)
	for item in items:
		if item is Dictionary:
			var research_id := String(item.get("research_id", ""))
			if rows_by_id.has(research_id) and not ids.has(research_id):
				ids.append(research_id)
	var extra_ids: Array[String] = []
	for key in rows_by_id.keys():
		var research_id := String(key)
		if not ids.has(research_id):
			extra_ids.append(research_id)
	extra_ids.sort()
	ids.append_array(extra_ids)
	return ids


func _query_research_items() -> Array:
	if game_state != null and game_state.has_method("query_research_items"):
		return game_state.query_research_items()
	return []


func _research_level(research_id: String) -> int:
	if game_state != null and game_state.has_method("get_research_level"):
		return int(game_state.get_research_level(research_id))
	return 0


func _line_title(row: Dictionary) -> String:
	var display_name := String(row.get("display_name", row.get("research_id", "")))
	for suffix in [" I", " II", " III", " IV", " V"]:
		if display_name.ends_with(suffix):
			return display_name.substr(0, display_name.length() - suffix.length())
	return display_name


func _roman_level(level: int) -> String:
	match level:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
		_:
			return str(level)


func _format_effect(effect_type: String, effect_value: float) -> String:
	match effect_type:
		"player_move_speed_multiplier":
			return "移速 %.0f%%" % (effect_value * 100.0)
		"inventory_slots":
			return "背包 %d 格" % int(round(effect_value))
		"home_storage_slots":
			return "家箱 %d 格" % int(round(effect_value))
		"outpost_storage_slots":
			return "前哨箱 %d 格" % int(round(effect_value))
		"max_stability":
			return "稳定值 %.0f" % effect_value
		"warehouse_capacity":
			return "仓库 %d 格" % int(round(effect_value))
		"merchant_shop_level":
			return "商店 Lv.%d" % int(round(effect_value))
		_:
			return "%s %.2f" % [effect_type, effect_value]


func _ensure_data_loaded() -> bool:
	if ensure_data_loaded_callback.is_valid():
		return bool(ensure_data_loaded_callback.call())
	return data_registry != null


func _icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


func _make_label(text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _slot_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 5
	style.content_margin_top = 5
	style.content_margin_right = 5
	style.content_margin_bottom = 5
	return style


func _circle_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

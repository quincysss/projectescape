class_name BaseWarehousePanelController
extends RefCounted

var warehouse_panel: Panel
var warehouse_grid_root: Control
var warehouse_status_label: Label
var warehouse_label: RichTextLabel
var item_grid_view


func build_surface(ui_root: Control) -> Dictionary:
	if ui_root == null:
		return {}
	warehouse_panel = _make_base_panel("WarehouseGridPanel", Vector2(24, 154), Vector2(980, 500), "局外仓库")
	var warehouse_scroll := _make_scroll_area(Vector2(18, 58), Vector2(388, 394))
	warehouse_grid_root = Control.new()
	warehouse_grid_root.name = "WarehouseGrid"
	warehouse_scroll.add_child(warehouse_grid_root)
	warehouse_panel.add_child(warehouse_scroll)
	warehouse_status_label = _make_section_label("空仓位会显示为细框。每个格子只放一个道具。", Vector2(436, 62), Vector2(500, 96), 16)
	warehouse_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse_panel.add_child(warehouse_status_label)
	ui_root.add_child(warehouse_panel)
	return {
		"panel": warehouse_panel,
		"grid_root": warehouse_grid_root,
		"status_label": warehouse_status_label,
	}


func setup_views(
	p_warehouse_label: RichTextLabel,
	p_item_grid_view,
	p_grid_root: Control = null,
	p_status_label: Label = null
) -> void:
	warehouse_label = p_warehouse_label
	item_grid_view = p_item_grid_view
	if p_grid_root != null:
		warehouse_grid_root = p_grid_root
	if p_status_label != null:
		warehouse_status_label = p_status_label


func set_items(items: Array, capacity: int, max_capacity: int, source_id: String) -> void:
	if warehouse_label != null:
		warehouse_label.clear()
	_set_item_grid(warehouse_grid_root, items, max_capacity, source_id, capacity)
	if warehouse_status_label != null:
		warehouse_status_label.text = "仓库容量：%d/%d\n格子规则：每格 1 个道具，不堆叠。" % [items.size(), capacity]
	if warehouse_label == null:
		return
	if items.is_empty():
		warehouse_label.append_text("局外仓库：空（0/%d）" % capacity)
		return
	var lines: Array[String] = ["局外仓库：%d/%d" % [items.size(), capacity]]
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			var name := String(item.get("display_name", item.get("item_id", "")))
			var weight := float(item.get("weight_per_unit", 0.0))
			lines.append("[url=warehouse:%d]- 第 %d 格：%s  单重 %.2f[/url]" % [index, index + 1, name, weight])
	warehouse_label.append_text("\n".join(lines))


func show_selected_item(item: Dictionary) -> void:
	if warehouse_status_label == null or item.is_empty():
		return
	warehouse_status_label.text = "已选择：%s\n品质：%s\n格子规则：每格 1 个道具，不堆叠。" % [
		String(item.get("display_name", item.get("item_id", ""))),
		String(item.get("quality", "C")),
	]


func _set_item_grid(grid_root: Control, items: Array, capacity: int, source_id: String, unlocked_slots: int) -> void:
	if grid_root == null or item_grid_view == null:
		return
	item_grid_view.set_grid(grid_root, items, capacity, source_id, unlocked_slots)


func _make_base_panel(node_name: String, pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	panel.add_child(_make_section_label(title, Vector2(18, 12), Vector2(panel_size.x - 36.0, 30), 20))
	return panel


func _make_scroll_area(pos: Vector2, scroll_size: Vector2) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.position = pos
	scroll.size = scroll_size
	scroll.clip_contents = true
	scroll.set("horizontal_scroll_mode", 0)
	scroll.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.03, 0.78), Color(0.16, 0.20, 0.20, 0.9), 1))
	return scroll


func _make_section_label(text: String, pos: Vector2, label_size: Vector2, font_size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	_style_label(label, font_size, Color("#D8D6CE"))
	return label


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


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

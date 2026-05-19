class_name BaseCatalogPanelController
extends RefCounted

const CATALOG_COLUMNS := 4
const CATALOG_CARD_WIDTH := 208.0
const CATALOG_CARD_HEIGHT := 310.0
const CATALOG_CARD_GAP := 16.0

var catalog_panel: Panel
var catalog_grid_root: Control
var catalog_status_label: Label


func build_surface(ui_root: Control) -> Dictionary:
	if ui_root == null:
		return {}
	catalog_panel = _make_base_panel("CatalogPanel", Vector2(24, 154), Vector2(980, 500), "图鉴")
	catalog_panel.visible = false
	catalog_status_label = _make_section_label("", Vector2(780, 16), Vector2(170, 26), 15)
	catalog_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	catalog_panel.add_child(catalog_status_label)
	var catalog_scroll := _make_scroll_area(Vector2(18, 56), Vector2(928, 410))
	catalog_scroll.name = "CatalogScroll"
	catalog_grid_root = Control.new()
	catalog_grid_root.name = "CatalogGrid"
	catalog_scroll.add_child(catalog_grid_root)
	catalog_panel.add_child(catalog_scroll)
	ui_root.add_child(catalog_panel)
	return {
		"panel": catalog_panel,
		"grid_root": catalog_grid_root,
		"status_label": catalog_status_label,
	}


func set_items(items: Array) -> void:
	if catalog_grid_root == null:
		return
	for child in catalog_grid_root.get_children():
		catalog_grid_root.remove_child(child)
		child.queue_free()
	var rows := ceili(float(maxi(items.size(), 1)) / float(CATALOG_COLUMNS))
	var grid_width := float(CATALOG_COLUMNS) * CATALOG_CARD_WIDTH + float(CATALOG_COLUMNS - 1) * CATALOG_CARD_GAP
	var grid_height := float(rows) * CATALOG_CARD_HEIGHT + float(maxi(0, rows - 1)) * CATALOG_CARD_GAP
	catalog_grid_root.custom_minimum_size = Vector2(grid_width, grid_height)
	catalog_grid_root.size = catalog_grid_root.custom_minimum_size
	var collected_count := 0
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if bool(item.get("collected", false)):
			collected_count += 1
		var col := index % CATALOG_COLUMNS
		var row := int(index / CATALOG_COLUMNS)
		var card := _make_catalog_card(item, Vector2(CATALOG_CARD_WIDTH, CATALOG_CARD_HEIGHT))
		card.position = Vector2(
			float(col) * (CATALOG_CARD_WIDTH + CATALOG_CARD_GAP),
			float(row) * (CATALOG_CARD_HEIGHT + CATALOG_CARD_GAP)
		)
		catalog_grid_root.add_child(card)
	if catalog_status_label != null:
		catalog_status_label.text = "%d/%d" % [collected_count, items.size()]
	if items.is_empty():
		catalog_grid_root.add_child(_make_section_label("暂无图鉴记录", Vector2(18, 18), Vector2(220, 28), 16))


func _make_catalog_card(item: Dictionary, card_size: Vector2) -> Panel:
	var collected := bool(item.get("collected", false))
	var card := Panel.new()
	card.name = "CatalogCard_%s" % String(item.get("item_id", ""))
	card.size = card_size
	card.set_meta("item_id", String(item.get("item_id", "")))
	card.set_meta("catalog_collected", collected)
	var bg := Color(0.035, 0.033, 0.032, 0.96) if collected else Color(0.035, 0.037, 0.037, 0.88)
	var border := Color("#35C9D7") if collected else Color(0.16, 0.43, 0.47, 0.62)
	card.add_theme_stylebox_override("panel", _panel_style(bg, border, 2 if collected else 1))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2((card_size.x - 112.0) * 0.5, 22.0)
	icon.size = Vector2(112.0, 112.0)
	icon.texture = _icon_texture(String(item.get("icon", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1, 1.0 if collected else 0.58)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)

	var name_label := _make_section_label(String(item.get("display_name", item.get("item_id", ""))), Vector2(14, 150), Vector2(card_size.x - 28.0, 34), 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", _quality_name_color(String(item.get("quality", "C"))))
	card.add_child(name_label)

	var divider := ColorRect.new()
	divider.position = Vector2(20, 194)
	divider.size = Vector2(card_size.x - 40.0, 1)
	divider.color = Color(0.20, 0.72, 0.78, 0.62 if collected else 0.32)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(divider)

	var description_text := _format_catalog_description(String(item.get("description", "暂无记录。")), 12, 4)
	var description := _make_section_label(description_text, Vector2(18, 208), Vector2(card_size.x - 36.0, 72), 13)
	description.name = "Description"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_OFF
	description.clip_text = true
	description.add_theme_color_override("font_color", Color("#D8D6CE") if collected else Color("#8C9292"))
	card.add_child(description)

	var status := _make_section_label("(已获得)" if collected else "(未获得)", Vector2(18, card_size.y - 28.0), Vector2(card_size.x - 36.0, 18), 12)
	status.name = "CatalogStatusLabel"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color("#D1B850") if collected else Color("#6F7778"))
	card.add_child(status)
	return card


func _format_catalog_description(raw_text: String, max_chars_per_line: int, max_lines: int) -> String:
	var text := raw_text.strip_edges().replace("\r", " ").replace("\n", " ")
	while text.contains("  "):
		text = text.replace("  ", " ")
	if text.is_empty():
		text = "暂无记录。"
	var lines: Array[String] = []
	var line := ""
	var index := 0
	while index < text.length() and lines.size() < max_lines:
		var character := text.substr(index, 1)
		line += character
		if line.length() >= max_chars_per_line:
			lines.append(line.strip_edges())
			line = ""
		index += 1
	if not line.strip_edges().is_empty() and lines.size() < max_lines:
		lines.append(line.strip_edges())
	if index < text.length() and not lines.is_empty():
		var last_index := lines.size() - 1
		var last_line := lines[last_index]
		if last_line.length() >= 1:
			lines[last_index] = last_line.substr(0, maxi(0, max_chars_per_line - 1)).strip_edges() + "..."
	return "\n".join(lines)


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


func _icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


func _quality_name_color(quality: String) -> Color:
	match quality:
		"SS":
			return Color("#D84B55")
		"S":
			return Color("#D1B850")
		"A":
			return Color("#B9A9FF")
		"B":
			return Color("#6FA8DC")
		_:
			return Color("#D8D6CE")

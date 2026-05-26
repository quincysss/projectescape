class_name ItemGridView
extends RefCounted

const COLUMNS := 5
const SLOT_SIZE := 62.0
const SLOT_GAP := 10.0
const FOOTER_HEIGHT := 28.0

var tooltip_view
var slot_pressed_callback: Callable
var is_selected_callback: Callable
var currency_name_provider: Callable


func setup(
	p_tooltip_view,
	p_slot_pressed_callback: Callable,
	p_is_selected_callback: Callable,
	p_currency_name_provider: Callable
) -> void:
	tooltip_view = p_tooltip_view
	slot_pressed_callback = p_slot_pressed_callback
	is_selected_callback = p_is_selected_callback
	currency_name_provider = p_currency_name_provider


func set_grid(grid_root: Control, items: Array, capacity: int, source_id: String, unlocked_slots: int = -1) -> void:
	if grid_root == null:
		return
	if tooltip_view != null:
		tooltip_view.hide("grid_refresh")
	for child in grid_root.get_children():
		grid_root.remove_child(child)
		child.queue_free()
	capacity = maxi(capacity, items.size())
	if unlocked_slots < 0:
		unlocked_slots = capacity
	unlocked_slots = clampi(unlocked_slots, 0, capacity)
	var display_slots := maxi(capacity, 1)
	var rows := ceili(float(display_slots) / float(COLUMNS))
	var grid_width := float(COLUMNS) * SLOT_SIZE + float(COLUMNS - 1) * SLOT_GAP
	var grid_height := float(rows) * SLOT_SIZE + float(rows - 1) * SLOT_GAP + FOOTER_HEIGHT
	grid_root.custom_minimum_size = Vector2(grid_width, grid_height)
	grid_root.size = grid_root.custom_minimum_size
	for index in range(display_slots):
		var col := index % COLUMNS
		var row := int(index / COLUMNS)
		var slot_pos := Vector2(float(col) * (SLOT_SIZE + SLOT_GAP), float(row) * (SLOT_SIZE + SLOT_GAP))
		var item: Variant = items[index] if index < items.size() else null
		var locked := index >= unlocked_slots
		if item is Dictionary:
			grid_root.add_child(_make_item_slot(slot_pos, Vector2(SLOT_SIZE, SLOT_SIZE), item, index, source_id, locked))
		else:
			grid_root.add_child(_make_empty_slot(slot_pos, Vector2(SLOT_SIZE, SLOT_SIZE), locked))
	grid_root.add_child(_make_footer(Vector2(0, grid_height - FOOTER_HEIGHT + 4.0), Vector2(grid_width, 22), items.size(), unlocked_slots))


func _make_item_slot(pos: Vector2, slot_size: Vector2, item: Dictionary, index: int, source_id: String, locked: bool = false) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = slot_size
	button.text = ""
	button.clip_text = false
	button.tooltip_text = _slot_tooltip(item, source_id)
	button.set_meta("ui_click_sfx", "ui_item_click")
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", _quality_color(item))
	var meta_id := String(item.get("grid_meta_id", str(index)))
	var selected := _is_selected(source_id, meta_id, index)
	var border_color := Color("#D1B850") if selected else Color("#35C9D7")
	var border_width := 3 if selected else 2
	var normal_bg := Color("#151819") if locked else Color("#071116")
	var normal_border := Color("#4D575B") if locked else border_color
	button.disabled = locked
	button.set_meta("warehouse_slot_locked", locked)
	button.add_theme_stylebox_override("normal", _slot_style(normal_bg, normal_border, border_width))
	button.add_theme_stylebox_override("hover", _slot_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _slot_style(Color("#121817"), Color("#D1B850"), 3))
	button.add_theme_stylebox_override("disabled", _slot_style(Color("#151819"), Color("#4D575B"), 1))
	_add_item_slot_content(button, slot_size, item)
	if tooltip_view != null:
		tooltip_view.bind(button, item, source_id)
	if not locked:
		button.button_up.connect(func(): _dispatch_slot(source_id, meta_id, index))
	return button


func _make_empty_slot(pos: Vector2, slot_size: Vector2, locked: bool = false) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = slot_size
	panel.set_meta("warehouse_slot_locked", locked)
	var bg_color := Color("#151819") if locked else Color("#071116")
	var border_color := Color("#4D575B") if locked else Color("#354145")
	panel.add_theme_stylebox_override("panel", _slot_style(bg_color, border_color, 1))
	return panel


func _make_footer(pos: Vector2, footer_size: Vector2, used: int, capacity: int) -> Label:
	var footer := Label.new()
	footer.position = pos
	footer.size = footer_size
	footer.text = "容量：%d/%d" % [used, capacity]
	_style_label(footer, 15, Color("#8DB6B9"))
	return footer


func _add_item_slot_content(button: Button, slot_size: Vector2, item: Dictionary) -> void:
	var texture := _item_icon_texture(item)
	var label_height := clampf(slot_size.y * 0.28, 12.0, 18.0)
	var icon_size := maxf(18.0, minf(slot_size.x - 12.0, slot_size.y - label_height - 6.0))
	var content_height := icon_size + 2.0 + label_height
	var icon_pos := Vector2((slot_size.x - icon_size) * 0.5, maxf(2.0, (slot_size.y - content_height) * 0.38))
	if texture != null:
		var icon := TextureRect.new()
		icon.position = icon_pos
		icon.size = Vector2(icon_size, icon_size)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.position = icon_pos
		fallback.size = Vector2(icon_size, icon_size)
		fallback.text = String(item.get("quality", "C"))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 18)
		fallback.add_theme_color_override("font_color", _quality_color(item))
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(fallback)
	_add_slot_text_box(
		button,
		_slot_display_name(String(item.get("display_name", item.get("item_id", "")))),
		Vector2(3.0, minf(slot_size.y - label_height - 2.0, icon_pos.y + icon_size + 2.0)),
		Vector2(slot_size.x - 6.0, label_height),
		8,
		_quality_color(item)
	)
	_add_amount_badge(button, slot_size, item)


func _add_amount_badge(button: Button, slot_size: Vector2, item: Dictionary) -> void:
	var amount := maxi(1, int(item.get("amount", 1)))
	if amount <= 1:
		return
	var badge := Label.new()
	badge.name = "StackAmount"
	badge.text = "x%d" % amount
	badge.position = Vector2(slot_size.x - 30.0, 2.0)
	badge.size = Vector2(27.0, 16.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color("#F0ECE3"))
	badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	badge.add_theme_constant_override("shadow_offset_x", 1)
	badge.add_theme_constant_override("shadow_offset_y", 1)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)


func _add_slot_text_box(button: Button, text: String, pos: Vector2, box_size: Vector2, font_size: int, color: Color) -> void:
	var box := Control.new()
	box.position = pos
	box.size = box_size
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.custom_minimum_size = Vector2.ZERO
	label.position = Vector2(0.0, -4.0)
	label.size = Vector2(box_size.x, box_size.y + 8.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)


func _slot_tooltip(item: Dictionary, source_id: String) -> String:
	var name := String(item.get("display_name", item.get("item_id", "")))
	var quality := String(item.get("quality", "C"))
	var details := "\n".join(_stack_detail_lines(item, quality))
	match source_id:
		"sell":
			return "%s\n%s\n出售：%d %s" % [
				name,
				details,
				int(item.get("sell_value", 0)),
				_currency_name(String(item.get("sell_currency_id", "mine_coin"))),
			]
		"buy":
			return "%s\n%s\n购买：%d %s" % [
				name,
				details,
				int(item.get("buy_price", 0)),
				_currency_name(String(item.get("buy_currency_id", "mine_coin"))),
			]
		_:
			return "%s\n%s" % [name, details]
func _stack_detail_lines(item: Dictionary, quality: String) -> Array[String]:
	var amount := maxi(1, int(item.get("amount", 1)))
	var single_weight := maxf(0.0, float(item.get("weight_per_unit", item.get("weight", 0.0))))
	var stack_limit := maxi(1, int(item.get("stack_limit", 1)))
	var item_type := String(item.get("item_type", "material"))
	return [
		"数量：x%d" % amount,
		"品质：%s" % quality,
		"类别：%s" % item_type,
		"单件重量：%.2f" % single_weight,
		"总重量：%.2f" % (single_weight * float(amount)),
		"堆叠上限：%d" % stack_limit,
	]


func _dispatch_slot(source_id: String, meta_id: String, index: int) -> void:
	if slot_pressed_callback.is_valid():
		slot_pressed_callback.call(source_id, meta_id, index)


func _is_selected(source_id: String, meta_id: String, index: int) -> bool:
	if is_selected_callback.is_valid():
		return bool(is_selected_callback.call(source_id, meta_id, index))
	return false


func _currency_name(currency_id: String) -> String:
	if currency_name_provider.is_valid():
		return String(currency_name_provider.call(currency_id))
	match currency_id:
		"mine_coin":
			return "矿币"
		_:
			return currency_id


func _item_icon_texture(item: Dictionary) -> Texture2D:
	var icon_path := String(item.get("icon", ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


func _slot_display_name(name: String) -> String:
	if name.length() <= 6:
		return name
	return name.substr(0, 6)


func _quality_color(item: Dictionary) -> Color:
	var value = item.get("quality_color", Color.WHITE)
	if value is Color:
		return value
	match String(item.get("quality", "C")):
		"S":
			return Color("#D1B850")
		"A":
			return Color("#B9A9FF")
		"B":
			return Color("#6FA8DC")
		_:
			return Color("#D8D6CE")


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

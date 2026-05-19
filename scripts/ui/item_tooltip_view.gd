class_name ItemTooltipView
extends RefCounted

const HOVER_DELAY_SECONDS := 0.15
const MARGIN := 16.0

var owner_control: Control
var data_registry
var ensure_data_loaded_callback: Callable
var currency_name_provider: Callable

var tooltip_layer: Control
var tooltip_panel: Panel
var tooltip_icon: TextureRect
var tooltip_quality_marker: ColorRect
var tooltip_name_label: Label
var tooltip_price_label: Label
var tooltip_description_label: Label
var tooltip_timer: Timer

var _pending_item: Dictionary = {}
var _pending_context: Dictionary = {}
var _pending_anchor: Control
var _current_anchor: Control
var _current_item_id := ""


func setup(
	ui_root: Control,
	p_owner_control: Control,
	p_data_registry,
	p_ensure_data_loaded_callback: Callable,
	p_currency_name_provider: Callable
) -> void:
	if ui_root == null:
		return
	if tooltip_layer != null and is_instance_valid(tooltip_layer):
		return
	owner_control = p_owner_control
	data_registry = p_data_registry
	ensure_data_loaded_callback = p_ensure_data_loaded_callback
	currency_name_provider = p_currency_name_provider
	_build_layer(ui_root)


func bind(anchor: Control, item: Dictionary, source_id: String, context: Dictionary = {}) -> void:
	if anchor == null:
		return
	anchor.tooltip_text = ""
	anchor.mouse_filter = Control.MOUSE_FILTER_STOP
	var tooltip_context := context.duplicate(true)
	if not tooltip_context.has("context"):
		tooltip_context["context"] = source_id
	anchor.mouse_entered.connect(func(): _queue(item, anchor, tooltip_context))
	anchor.mouse_exited.connect(func(): hide_for_anchor(anchor, "mouse_exited"))


func hide_for_anchor(anchor: Control, reason: String = "") -> void:
	if anchor == _pending_anchor or anchor == _current_anchor:
		hide(reason)


func hide(_reason: String = "") -> void:
	if tooltip_timer != null:
		tooltip_timer.stop()
	_pending_item = {}
	_pending_context = {}
	_pending_anchor = null
	_current_anchor = null
	_current_item_id = ""
	if tooltip_panel != null:
		tooltip_panel.visible = false


func _build_layer(ui_root: Control) -> void:
	tooltip_layer = Control.new()
	tooltip_layer.name = "TooltipLayer"
	tooltip_layer.anchor_left = 0.0
	tooltip_layer.anchor_top = 0.0
	tooltip_layer.anchor_right = 1.0
	tooltip_layer.anchor_bottom = 1.0
	tooltip_layer.offset_left = 0.0
	tooltip_layer.offset_top = 0.0
	tooltip_layer.offset_right = 0.0
	tooltip_layer.offset_bottom = 0.0
	tooltip_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_layer.z_index = 100
	ui_root.add_child(tooltip_layer)

	tooltip_panel = Panel.new()
	tooltip_panel.name = "ItemTooltipPanel"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.033, 0.032, 0.95), Color("#2B8F99"), 1))
	tooltip_layer.add_child(tooltip_panel)

	tooltip_icon = TextureRect.new()
	tooltip_icon.name = "ItemTooltipIcon"
	tooltip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tooltip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tooltip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(tooltip_icon)

	tooltip_quality_marker = ColorRect.new()
	tooltip_quality_marker.name = "QualityMarker"
	tooltip_quality_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(tooltip_quality_marker)

	tooltip_name_label = _make_label("", 18, Color("#D8D6CE"))
	tooltip_name_label.name = "ItemTooltipName"
	tooltip_name_label.clip_text = true
	tooltip_panel.add_child(tooltip_name_label)

	tooltip_price_label = _make_label("", 15, Color("#D8D6CE"))
	tooltip_price_label.name = "ItemTooltipPrice"
	tooltip_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tooltip_price_label.clip_text = true
	tooltip_panel.add_child(tooltip_price_label)

	var divider := ColorRect.new()
	divider.name = "ItemTooltipDivider"
	var divider_color := Color("#2B8F99")
	divider_color.a = 0.72
	divider.color = divider_color
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(divider)

	tooltip_description_label = _make_label("", 14, Color("#D8D6CE"))
	tooltip_description_label.name = "ItemTooltipDescription"
	tooltip_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_panel.add_child(tooltip_description_label)

	tooltip_timer = Timer.new()
	tooltip_timer.name = "ItemTooltipDelayTimer"
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = HOVER_DELAY_SECONDS
	tooltip_timer.timeout.connect(_on_delay_timeout)
	tooltip_layer.add_child(tooltip_timer)


func _queue(item: Dictionary, anchor: Control, context: Dictionary = {}) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	_pending_item = item.duplicate(true)
	_pending_context = context.duplicate(true)
	_pending_anchor = anchor
	if tooltip_timer != null:
		tooltip_timer.start(HOVER_DELAY_SECONDS)


func _on_delay_timeout() -> void:
	if _pending_anchor == null or not is_instance_valid(_pending_anchor):
		hide("anchor_gone")
		return
	_show(_pending_item, _pending_anchor, _pending_context)


func _show(item: Dictionary, anchor: Control, context: Dictionary = {}) -> void:
	if tooltip_panel == null or anchor == null or not is_instance_valid(anchor):
		return
	var data := _build_data(item, context)
	if data.is_empty():
		hide("empty_data")
		return
	_current_anchor = anchor
	_current_item_id = String(data.get("item_id", ""))
	_apply_data(data)
	_position(anchor)
	tooltip_panel.visible = true


func _build_data(item: Dictionary, context: Dictionary = {}) -> Dictionary:
	var item_id := String(item.get("item_id", ""))
	if item_id.is_empty() and item.has("warehouse_item_id"):
		item_id = String(item.get("warehouse_item_id", ""))
	if item_id.is_empty():
		if OS.is_debug_build():
			push_warning("Item tooltip missing item_id for context %s." % String(context.get("context", "")))
			return {
				"item_id": "missing_item",
				"display_name": "未知道具",
				"quality": "C",
				"icon": "",
				"price_text": "不可出售",
				"sellable": false,
				"description": "Tooltip 缺少 item_id。",
			}
		return {}
	if not _ensure_data_loaded():
		return {}
	var definition: Dictionary = data_registry.get_item(item_id) if data_registry != null and data_registry.has_method("get_item") else {}
	if definition.is_empty():
		if OS.is_debug_build():
			push_warning("Item tooltip cannot find item_id: %s." % item_id)
			return {
				"item_id": item_id,
				"display_name": item_id,
				"quality": "C",
				"icon": String(item.get("icon", "")),
				"price_text": "不可出售",
				"sellable": false,
				"description": "items.tab 中没有这个道具定义。",
			}
		return {}
	var sellable := _parse_bool(definition.get("sellable", item.get("sellable", false)))
	var sell_value := int(definition.get("sell_value", item.get("sell_value", 0)))
	var currency_id := String(definition.get("sell_currency_id", item.get("sell_currency_id", "mine_coin")))
	var description := String(definition.get("description", item.get("description", "")))
	if description.strip_edges().is_empty():
		description = "暂无记录。"
	return {
		"item_id": item_id,
		"display_name": String(definition.get("name", item.get("display_name", item_id))),
		"quality": String(definition.get("quality", item.get("quality", "C"))),
		"icon": String(definition.get("icon", item.get("icon", ""))),
		"price_text": "%d%s" % [sell_value, _currency_name(currency_id)] if sellable and sell_value > 0 else "不可出售",
		"sellable": sellable and sell_value > 0,
		"description": description,
	}


func _apply_data(data: Dictionary) -> void:
	var panel_size := _tooltip_size()
	var icon_size := _icon_size()
	tooltip_panel.size = panel_size
	tooltip_icon.position = Vector2((panel_size.x - icon_size) * 0.5, 24.0)
	tooltip_icon.size = Vector2(icon_size, icon_size)
	tooltip_icon.texture = _icon_texture(String(data.get("icon", "")))
	tooltip_quality_marker.position = Vector2(18.0, icon_size + 54.0)
	tooltip_quality_marker.size = Vector2(5.0, 18.0)
	tooltip_quality_marker.color = _quality_color(String(data.get("quality", "C")))
	tooltip_name_label.position = Vector2(28.0, icon_size + 48.0)
	tooltip_name_label.size = Vector2(panel_size.x - 128.0, 30.0)
	tooltip_name_label.text = String(data.get("display_name", ""))
	tooltip_name_label.add_theme_color_override("font_color", _quality_color(String(data.get("quality", "C"))))
	tooltip_price_label.position = Vector2(panel_size.x - 96.0, icon_size + 50.0)
	tooltip_price_label.size = Vector2(78.0, 26.0)
	tooltip_price_label.text = String(data.get("price_text", ""))
	tooltip_price_label.add_theme_color_override("font_color", Color("#D8D6CE") if bool(data.get("sellable", false)) else Color("#7D8586"))
	var divider := tooltip_panel.get_node_or_null("ItemTooltipDivider") as ColorRect
	if divider != null:
		divider.position = Vector2(18.0, icon_size + 83.0)
		divider.size = Vector2(panel_size.x - 36.0, 1.0)
	tooltip_description_label.position = Vector2(18.0, icon_size + 118.0)
	tooltip_description_label.size = Vector2(panel_size.x - 36.0, panel_size.y - icon_size - 138.0)
	tooltip_description_label.text = String(data.get("description", ""))


func _position(anchor: Control) -> void:
	var viewport_size := _viewport_size()
	var panel_size := _tooltip_size()
	var anchor_rect := anchor.get_global_rect()
	var x := anchor_rect.position.x + anchor_rect.size.x + MARGIN
	if x + panel_size.x + MARGIN > viewport_size.x:
		x = anchor_rect.position.x - panel_size.x - MARGIN
	var y := anchor_rect.position.y
	x = clampf(x, MARGIN, maxf(MARGIN, viewport_size.x - panel_size.x - MARGIN))
	y = clampf(y, MARGIN, maxf(MARGIN, viewport_size.y - panel_size.y - MARGIN))
	var local_position := tooltip_layer.get_global_transform().affine_inverse() * Vector2(x, y)
	tooltip_panel.position = local_position


func _viewport_size() -> Vector2:
	if owner_control != null and is_instance_valid(owner_control):
		return owner_control.get_viewport_rect().size
	if tooltip_layer != null and is_instance_valid(tooltip_layer):
		return tooltip_layer.get_viewport_rect().size
	return Vector2(1280, 720)


func _tooltip_size() -> Vector2:
	var width := _viewport_size().x
	if width >= 1800.0:
		return Vector2(260.0, 300.0)
	if width >= 1500.0:
		return Vector2(240.0, 280.0)
	return Vector2(224.0, 260.0)


func _icon_size() -> float:
	var width := _viewport_size().x
	if width >= 1800.0:
		return 88.0
	if width >= 1500.0:
		return 80.0
	return 72.0


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _ensure_data_loaded() -> bool:
	if ensure_data_loaded_callback.is_valid():
		return bool(ensure_data_loaded_callback.call())
	return data_registry != null


func _currency_name(currency_id: String) -> String:
	if currency_name_provider.is_valid():
		return String(currency_name_provider.call(currency_id))
	match currency_id:
		"mine_coin":
			return "矿币"
		_:
			return currency_id


func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"


func _icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D


func _quality_color(quality: String) -> Color:
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

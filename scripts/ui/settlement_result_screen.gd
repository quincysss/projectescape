class_name SettlementResultScreen
extends Control

signal return_to_base_requested

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

var title_label: Label
var item_title_label: Label
var empty_label: Label
var item_list: VBoxContainer
var return_button: Button

var _result: Dictionary = {}
var _registry

func _ready() -> void:
	_build()

func show_result(result: Dictionary) -> void:
	_result = result.duplicate(true)
	if item_list == null:
		call_deferred("show_result", _result.duplicate(true))
		return
	_refresh()

func _build() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000

	var bg := ColorRect.new()
	bg.name = "BlackBackground"
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var content := Control.new()
	content.name = "SettlementContent"
	content.anchor_left = 0.5
	content.anchor_right = 0.5
	content.anchor_top = 0.5
	content.anchor_bottom = 0.5
	content.offset_left = -430.0
	content.offset_top = -310.0
	content.offset_right = 430.0
	content.offset_bottom = 310.0
	add_child(content)

	title_label = Label.new()
	title_label.name = "ResultTitleLabel"
	title_label.position = Vector2(0.0, 0.0)
	title_label.size = Vector2(860.0, 56.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color("#F0ECE3"))
	content.add_child(title_label)

	item_title_label = Label.new()
	item_title_label.name = "ItemTitleLabel"
	item_title_label.position = Vector2(0.0, 92.0)
	item_title_label.size = Vector2(860.0, 34.0)
	item_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_title_label.add_theme_font_size_override("font_size", 20)
	item_title_label.add_theme_color_override("font_color", Color("#D6C57B"))
	content.add_child(item_title_label)

	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.position = Vector2(70.0, 144.0)
	scroll.size = Vector2(720.0, 290.0)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.name = "ItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 8)
	scroll.add_child(item_list)

	empty_label = Label.new()
	empty_label.name = "EmptyItemLabel"
	empty_label.position = Vector2(70.0, 220.0)
	empty_label.size = Vector2(720.0, 48.0)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 18)
	empty_label.add_theme_color_override("font_color", Color("#9D9990"))
	content.add_child(empty_label)

	return_button = Button.new()
	return_button.name = "ReturnToBaseButton"
	return_button.text = "返回哨所"
	return_button.position = Vector2(330.0, 492.0)
	return_button.size = Vector2(200.0, 46.0)
	return_button.add_theme_font_size_override("font_size", 18)
	return_button.add_theme_color_override("font_color", Color("#F0ECE3"))
	return_button.add_theme_stylebox_override("normal", _panel_style(Color("#0A171B"), Color("#D1B850"), 1))
	return_button.add_theme_stylebox_override("hover", _panel_style(Color("#102329"), Color("#E3CA5D"), 1))
	return_button.add_theme_stylebox_override("pressed", _panel_style(Color("#071014"), Color("#A99232"), 1))
	return_button.pressed.connect(func(): return_to_base_requested.emit())
	content.add_child(return_button)

func _refresh() -> void:
	var success := String(_result.get("result_type", "")) == "EXTRACTED"
	title_label.text = "成功返回404哨所" if success else "你已被黑潮吞噬，将在404重塑躯体。"
	item_title_label.text = "本次获得的物资" if success else "本局带出的物资"
	return_button.text = "返回哨所"

	for child in item_list.get_children():
		child.queue_free()

	var grouped_items := _group_items(Array(_result.get("warehouse_items", [])))
	empty_label.visible = grouped_items.is_empty()
	empty_label.text = "" if success else "没有带回任何物资"
	if success and grouped_items.is_empty():
		empty_label.text = "没有获得物资"

	for item in grouped_items:
		item_list.add_child(_make_item_row(item))

func _group_items(items: Array) -> Array[Dictionary]:
	var grouped := {}
	for raw_item in items:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var item_id := String(item.get("item_id", ""))
		var display_name := String(item.get("display_name", item_id))
		var quality := "" if _is_repair_material_item(item) else String(item.get("quality", "C"))
		var source := _source_text(item)
		var status := _status_text(item)
		var icon := _icon_path(item)
		var key := "%s|%s|%s|%s|%s|%s" % [item_id, display_name, quality, source, status, icon]
		var amount := maxi(1, int(item.get("amount", 1)))
		if not grouped.has(key):
			var copy := item.duplicate(true)
			copy["amount"] = 0
			copy["settlement_source"] = source
			copy["settlement_status"] = status
			copy["icon"] = icon
			grouped[key] = copy
		var existing: Dictionary = grouped[key]
		existing["amount"] = int(existing.get("amount", 0)) + amount
		grouped[key] = existing

	var result: Array[Dictionary] = []
	for key in grouped.keys():
		var grouped_item: Dictionary = grouped[key]
		result.append(grouped_item.duplicate(true))
	result.sort_custom(func(a, b):
		var quality_a := _quality_rank(String(a.get("quality", "C")))
		var quality_b := _quality_rank(String(b.get("quality", "C")))
		if quality_a != quality_b:
			return quality_a > quality_b
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return result

func _make_item_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700.0, 66.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#080B0C"), Color("#27383D"), 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var texture := _item_icon_texture(item)
	if texture != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48.0, 48.0)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	else:
		row.add_child(_make_quality_fallback(item))

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(440.0, 48.0)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = String(item.get("display_name", item.get("item_id", "")))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", _quality_color(item))
	text_box.add_child(name_label)

	var meta_label := Label.new()
	if _is_repair_material_item(item):
		meta_label.text = "来源：%s  |  %s" % [_source_text(item), _status_text(item)]
	else:
		meta_label.text = "品质 %s  |  来源：%s  |  %s" % [
			String(item.get("quality", "C")),
			_source_text(item),
			_status_text(item),
		]
	meta_label.clip_text = true
	meta_label.add_theme_font_size_override("font_size", 13)
	meta_label.add_theme_color_override("font_color", Color("#AFA99D"))
	text_box.add_child(meta_label)

	var amount_label := Label.new()
	amount_label.custom_minimum_size = Vector2(86.0, 48.0)
	amount_label.text = "x%d" % maxi(1, int(item.get("amount", 1)))
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 18)
	amount_label.add_theme_color_override("font_color", Color("#F0ECE3"))
	row.add_child(amount_label)
	return panel

func _make_quality_fallback(item: Dictionary) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(48.0, 48.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#101416"), _quality_color(item), 1))

	var label := Label.new()
	label.text = "材" if _is_repair_material_item(item) else String(item.get("quality", "C"))
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", _quality_color(item))
	panel.add_child(label)
	return panel

func _item_icon_texture(item: Dictionary) -> Texture2D:
	var icon_path := _icon_path(item)
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	var resource := load(icon_path)
	return resource as Texture2D

func _icon_path(item: Dictionary) -> String:
	var icon_path := String(item.get("icon", ""))
	if not icon_path.is_empty():
		return icon_path
	_ensure_registry()
	if _registry == null:
		return ""
	var definition: Dictionary = _registry.get_item(String(item.get("item_id", "")))
	if definition.is_empty() and _is_repair_material_item(item):
		definition = _registry.get_repair_material(String(item.get("repair_material_id", item.get("item_id", ""))))
	return String(definition.get("icon", ""))

func _ensure_registry() -> void:
	if _registry != null:
		return
	_registry = GameDataRegistryScript.new()
	_registry.load_all()

func _source_text(item: Dictionary) -> String:
	var explicit := String(item.get("settlement_source", ""))
	if not explicit.is_empty():
		return explicit
	if item.has("source_container_type"):
		return "地表容器"
	if item.has("source"):
		match String(item.get("source", "")):
			"ss_container_loot":
				return "历史高阶来源"
			_:
				return String(item.get("source", "地表"))
	return "地表"

func _status_text(item: Dictionary) -> String:
	var explicit := String(item.get("settlement_status", ""))
	if not explicit.is_empty():
		return explicit
	return "已带回" if String(_result.get("result_type", "")) == "EXTRACTED" else "已保留"

func _quality_rank(quality: String) -> int:
	match quality:
		"S":
			return 4
		"A":
			return 3
		"B":
			return 2
		"C":
			return 1
		_:
			return 0

func _quality_color(item: Dictionary) -> Color:
	if _is_repair_material_item(item) and not item.has("quality_color"):
		return Color("#20B86B")
	var value = item.get("quality_color", null)
	if value is Color:
		return value
	match String(item.get("quality", "C")):
		"S":
			return Color("#F1CA3A")
		"A":
			return Color("#A56CFF")
		"B":
			return Color("#4DB4FF")
		_:
			return Color("#B8C1C4")

func _is_repair_material_item(item: Dictionary) -> bool:
	return not String(item.get("repair_material_id", "")).is_empty()

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
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

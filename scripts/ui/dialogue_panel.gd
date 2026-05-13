class_name DialoguePanel
extends Control

signal dialogue_finished(dialogue_id: String, skipped: bool)

const DialogueSpeakerRegistryScript := preload("res://scripts/dialogue/dialogue_speaker_registry.gd")
const DialoguePortraitControllerScript := preload("res://scripts/dialogue/dialogue_portrait_controller.gd")
const TYPE_CHARS_PER_SECOND := 32.0
const SPEAKER_NAME_FONT_SIZE := 22
const DIALOGUE_BORDER_COLOR := Color("#7F6A34")
const DIALOGUE_BG_LEFT := Color(0.0, 0.0, 0.0, 0.78)
const DIALOGUE_BG_RIGHT := Color(0.42, 0.41, 0.40, 0.56)
const DIALOGUE_BOX_SIZE := Vector2(1040.0, 270.0)
const PORTRAIT_MIN_HEIGHT := 430.0
const PORTRAIT_MAX_HEIGHT := 620.0
const PORTRAIT_ASPECT := 0.64
const PORTRAIT_SLOT_CENTER_X_RATIO := 0.60
const PORTRAIT_BOX_OVERLAP := 76.0
const PORTRAIT_BOTTOM_FADE_HEIGHT := 118.0

var dialogue_id := ""
var entries: Array = []
var entry_index := 0
var portrait_layer: Control
var left_portrait: TextureRect
var right_portrait: TextureRect
var portrait_bottom_fade: TextureRect
var speaker_label: Label
var body_label: Label
var hint_label: Label
var speaker_registry = DialogueSpeakerRegistryScript.new()
var portrait_controller = DialoguePortraitControllerScript.new()
var _sequence_speaker_ids: Array[String] = []
var _full_text := ""
var _visible_chars := 0.0
var _typing := false
var _finished := false

func _ready() -> void:
	_build()
	set_process(false)
	set_process_input(true)
	set_process_unhandled_input(false)
	visible = false

func play_sequence(sequence: Dictionary) -> void:
	dialogue_id = String(sequence.get("dialogue_id", ""))
	entries = Array(sequence.get("entries", []))
	_sequence_speaker_ids = _collect_sequence_speaker_ids(entries)
	entry_index = 0
	_finished = false
	visible = true
	set_process(true)
	grab_focus()
	_show_current_entry()

func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_chars += TYPE_CHARS_PER_SECOND * delta
	var next_count := mini(_full_text.length(), int(floor(_visible_chars)))
	body_label.text = _full_text.substr(0, next_count)
	if next_count >= _full_text.length():
		_typing = false
		body_label.text = _full_text

func _input(event: InputEvent) -> void:
	_handle_advance_input(event)

func _unhandled_input(event: InputEvent) -> void:
	_handle_advance_input(event)

func _handle_advance_input(event: InputEvent) -> void:
	if not visible or _finished:
		return
	if _is_space_pressed(event):
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		_advance()

func _build() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	var dim := ColorRect.new()
	dim.name = "DimLayer"
	dim.color = Color(0.04, 0.04, 0.04, 0.72)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)

	portrait_layer = Control.new()
	portrait_layer.name = "PortraitLayer"
	portrait_layer.anchor_right = 1.0
	portrait_layer.anchor_bottom = 1.0
	portrait_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_layer.z_index = 1
	add_child(portrait_layer)

	left_portrait = _make_portrait_view("LeftPortrait")
	portrait_layer.add_child(left_portrait)
	right_portrait = _make_portrait_view("RightPortrait")
	portrait_layer.add_child(right_portrait)
	portrait_bottom_fade = TextureRect.new()
	portrait_bottom_fade.name = "PortraitBottomFade"
	portrait_bottom_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_bottom_fade.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_bottom_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_bottom_fade.texture = _portrait_bottom_fade_texture()
	portrait_bottom_fade.visible = false
	portrait_bottom_fade.z_index = 4
	portrait_layer.add_child(portrait_bottom_fade)
	portrait_controller.setup(speaker_registry, left_portrait, right_portrait)
	_layout_portraits()

	var dialogue_box := Panel.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.anchor_left = 0.5
	dialogue_box.anchor_right = 0.5
	dialogue_box.anchor_top = 0.5
	dialogue_box.anchor_bottom = 0.5
	dialogue_box.offset_left = -DIALOGUE_BOX_SIZE.x * 0.5
	dialogue_box.offset_top = 28.0
	dialogue_box.offset_right = DIALOGUE_BOX_SIZE.x * 0.5
	dialogue_box.offset_bottom = 28.0 + DIALOGUE_BOX_SIZE.y
	dialogue_box.z_index = 5
	dialogue_box.add_theme_stylebox_override("panel", _panel_style(Color(0.0, 0.0, 0.0, 0.0), DIALOGUE_BORDER_COLOR, 2))
	add_child(dialogue_box)

	var gradient_bg := TextureRect.new()
	gradient_bg.name = "DialogueGradientBackground"
	gradient_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gradient_bg.anchor_right = 1.0
	gradient_bg.anchor_bottom = 1.0
	gradient_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gradient_bg.stretch_mode = TextureRect.STRETCH_SCALE
	gradient_bg.texture = _dialogue_gradient_texture()
	dialogue_box.add_child(gradient_bg)

	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.position = Vector2(28, 22)
	speaker_label.size = Vector2(DIALOGUE_BOX_SIZE.x - 56.0, 30)
	speaker_label.add_theme_font_size_override("font_size", SPEAKER_NAME_FONT_SIZE)
	speaker_label.add_theme_color_override("font_color", Color("#EFEDEA"))
	dialogue_box.add_child(speaker_label)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.position = Vector2(54, 68)
	body_label.size = Vector2(DIALOGUE_BOX_SIZE.x - 108.0, 128)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color("#F0EEEE"))
	dialogue_box.add_child(body_label)

	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.position = Vector2(DIALOGUE_BOX_SIZE.x - 240.0, DIALOGUE_BOX_SIZE.y - 52.0)
	hint_label.size = Vector2(206, 24)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.text = "SPACE 继续"
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.80, 0.62))
	dialogue_box.add_child(hint_label)

func _is_space_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE

func _show_current_entry() -> void:
	if entry_index >= entries.size():
		_finish(false)
		return
	var entry = entries[entry_index]
	if not (entry is Dictionary):
		entry_index += 1
		_show_current_entry()
		return
	var entry_dict: Dictionary = entry
	_update_portraits(entry_dict)
	speaker_label.text = "%s：" % _resolve_speaker_name(entry_dict)
	var speaker := speaker_registry.get_speaker(String(entry_dict.get("speaker_id", "")))
	speaker_label.add_theme_color_override("font_color", speaker.get("nameplate_color_value", Color("#EFEDEA")) as Color)
	_full_text = String(entry_dict.get("text", ""))
	_visible_chars = 0.0
	_typing = true
	body_label.text = ""

func _resolve_speaker_name(entry: Dictionary) -> String:
	var speaker_id := String(entry.get("speaker_id", ""))
	var speaker_name := String(entry.get("speaker_name", speaker_id))
	if speaker_id == "player" or speaker_name in ["主角", "玩家"]:
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			var username := String(game_state.get("username")).strip_edges()
			if not username.is_empty():
				return username
		return "玩家"
	var speaker := speaker_registry.get_speaker(speaker_id)
	return String(speaker.get("display_name", speaker_name))

func _advance() -> void:
	if _typing:
		_typing = false
		body_label.text = _full_text
		return
	entry_index += 1
	_show_current_entry()

func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	visible = false
	set_process(false)
	portrait_controller.hide_all()
	dialogue_finished.emit(dialogue_id, skipped)
	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and portrait_layer != null:
		_layout_portraits()

func _make_portrait_view(node_name: String) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.name = node_name
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.visible = false
	return portrait

func _layout_portraits() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)
	var portrait_height := clampf(viewport_size.y * 0.52, PORTRAIT_MIN_HEIGHT, PORTRAIT_MAX_HEIGHT)
	var portrait_width := portrait_height * PORTRAIT_ASPECT
	var dialogue_top := viewport_size.y * 0.5 + 28.0
	var portrait_bottom := dialogue_top + PORTRAIT_BOX_OVERLAP
	var portrait_top := portrait_bottom - portrait_height
	var portrait_left := viewport_size.x * PORTRAIT_SLOT_CENTER_X_RATIO - portrait_width * 0.5
	left_portrait.position = Vector2(portrait_left, portrait_top)
	left_portrait.size = Vector2(portrait_width, portrait_height)
	right_portrait.position = Vector2(portrait_left, portrait_top)
	right_portrait.size = Vector2(portrait_width, portrait_height)
	portrait_bottom_fade.position = Vector2(portrait_left, portrait_bottom - PORTRAIT_BOTTOM_FADE_HEIGHT)
	portrait_bottom_fade.size = Vector2(portrait_width, PORTRAIT_BOTTOM_FADE_HEIGHT)

func _collect_sequence_speaker_ids(source_entries: Array) -> Array[String]:
	var ids: Array[String] = []
	for entry in source_entries:
		if not (entry is Dictionary):
			continue
		var speaker_id := String((entry as Dictionary).get("speaker_id", "")).strip_edges()
		if speaker_id.is_empty() or ids.has(speaker_id):
			continue
		ids.append(speaker_id)
	return ids

func _update_portraits(entry: Dictionary) -> void:
	var viewport_size := get_viewport_rect().size
	portrait_controller.update_for_entry(entry, _sequence_speaker_ids, viewport_size)
	if portrait_bottom_fade != null:
		portrait_bottom_fade.visible = right_portrait != null and right_portrait.visible

func _panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _dialogue_gradient_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, DIALOGUE_BG_LEFT)
	gradient.set_color(1, DIALOGUE_BG_RIGHT)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(DIALOGUE_BOX_SIZE.x)
	texture.height = int(DIALOGUE_BOX_SIZE.y)
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.15)
	return texture

func _portrait_bottom_fade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.02, 0.02, 0.02, 0.72))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = int(PORTRAIT_BOTTOM_FADE_HEIGHT)
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	return texture

class_name DialoguePanel
extends Control

signal dialogue_finished(dialogue_id: String, skipped: bool)

const TYPE_CHARS_PER_SECOND := 32.0
const SPEAKER_NAME_FONT_SIZE := 22
const DIALOGUE_BORDER_COLOR := Color("#7F6A34")
const DIALOGUE_BG_LEFT := Color(0.0, 0.0, 0.0, 0.78)
const DIALOGUE_BG_RIGHT := Color(0.42, 0.41, 0.40, 0.56)
const DIALOGUE_BOX_SIZE := Vector2(660.0, 256.0)

var dialogue_id := ""
var entries: Array = []
var entry_index := 0
var speaker_label: Label
var body_label: Label
var hint_label: Label
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
	speaker_label.size = Vector2(604, 30)
	speaker_label.add_theme_font_size_override("font_size", SPEAKER_NAME_FONT_SIZE)
	speaker_label.add_theme_color_override("font_color", Color("#EFEDEA"))
	dialogue_box.add_child(speaker_label)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.position = Vector2(54, 68)
	body_label.size = Vector2(560, 112)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color("#F0EEEE"))
	dialogue_box.add_child(body_label)

	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.position = Vector2(420, 204)
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
	speaker_label.text = "%s：" % _resolve_speaker_name(entry_dict)
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
	return speaker_name

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
	dialogue_finished.emit(dialogue_id, skipped)
	queue_free()

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

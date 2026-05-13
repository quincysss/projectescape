extends Control

const INTRO_CINEMATIC_PLACEHOLDER_SECONDS := 2.0
const INTRO_CINEMATIC_CONFIG_PATH := "res://data/cinematics/opening_intro_cinematic.json"
const INTRO_CINEMATIC_DEFAULT_PATH := "res://assets/cinematics/source/opening_intro_cinematic_720p.mp4"
const INTRO_CINEMATIC_FALLBACK_PATH := "res://assets/cinematics/opening_intro_cinematic_720p.ogv"
const MAIN_MENU_BACKGROUND_VIDEO_PATH := "res://assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4"
const MAIN_MENU_BACKGROUND_FALLBACK_VIDEO_PATH := "res://assets/cinematics/main_menu/main_menu_background_loop_1080p.ogv"
const MAIN_MENU_LOGO_PATH := "res://assets/ui/logos/black_tide_project/processed/black_tide_project_logo_handpainted_alpha_bgfit_01.png"
const MAIN_MENU_CONTENT_POSITION := Vector2(34.0, 128.0)
const MAIN_MENU_CONTENT_SIZE := Vector2(780.0, 742.0)
const MAIN_MENU_LOGO_BOX_POSITION := Vector2(0.0, 0.0)
const MAIN_MENU_LOGO_BOX_SIZE := Vector2(780.0, 270.0)
const MAIN_MENU_BUTTON_POSITION_X := 172.0
const MAIN_MENU_START_BUTTON_Y := 486.0
const MAIN_MENU_SETTINGS_BUTTON_Y := 676.0
const MAIN_MENU_BUTTON_SIZE := Vector2(360.0, 72.0)

var _game_state: Node
var _main_menu_background_video_player: VideoStreamPlayer
var _username_overlay: Control
var _username_panel: Panel
var _username_edit: LineEdit
var _username_error: Label
var _username_confirm_button: Panel
var _intro_cinematic_overlay: Control
var _intro_cinematic_video_player: VideoStreamPlayer
var _intro_cinematic_finishing := false

func _ready() -> void:
	_game_state = get_node_or_null("/root/GameState")
	_play_base_safe_house_bgm()
	_build()

func _build() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_main_menu_background()
	_build_main_menu_content()
	_build_username_dialog()

func _build_main_menu_background() -> void:
	var bg := ColorRect.new()
	bg.name = "MainMenuBackgroundFallback"
	bg.color = Color("#090909")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_add_main_menu_background_video()

	var dim := ColorRect.new()
	dim.name = "MainMenuBackgroundDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.18)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

func _add_main_menu_background_video() -> void:
	var stream := _load_first_video_stream([
		MAIN_MENU_BACKGROUND_VIDEO_PATH,
		MAIN_MENU_BACKGROUND_FALLBACK_VIDEO_PATH,
	])
	if stream == null:
		return
	var video_player := VideoStreamPlayer.new()
	video_player.name = "MainMenuBackgroundVideo"
	video_player.stream = stream
	video_player.expand = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_object_property_if_exists(video_player, "volume_db", -80.0)
	video_player.finished.connect(func():
		if is_instance_valid(video_player):
			video_player.play()
	)
	add_child(video_player)
	_main_menu_background_video_player = video_player
	_fit_control_to_16x9_cover(video_player)
	video_player.play()

func _build_main_menu_content() -> void:
	var content := Control.new()
	content.name = "MainMenuContent"
	content.anchor_left = 0.0
	content.anchor_right = 0.0
	content.anchor_top = 0.0
	content.anchor_bottom = 0.0
	content.position = MAIN_MENU_CONTENT_POSITION
	content.size = MAIN_MENU_CONTENT_SIZE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	_build_main_menu_logo(content)

	var start_button := Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "开始游戏"
	start_button.position = Vector2(MAIN_MENU_BUTTON_POSITION_X, MAIN_MENU_START_BUTTON_Y)
	start_button.size = MAIN_MENU_BUTTON_SIZE
	_apply_main_menu_button_style(start_button)
	start_button.pressed.connect(_on_start_pressed)
	content.add_child(start_button)

	var settings_button := Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "设置"
	settings_button.position = Vector2(MAIN_MENU_BUTTON_POSITION_X, MAIN_MENU_SETTINGS_BUTTON_Y)
	settings_button.size = MAIN_MENU_BUTTON_SIZE
	_apply_main_menu_button_style(settings_button)
	settings_button.pressed.connect(_on_settings_pressed)
	content.add_child(settings_button)

	var version_label := Label.new()
	version_label.name = "VersionLabel"
	version_label.text = "v0.1"
	version_label.anchor_left = 1.0
	version_label.anchor_right = 1.0
	version_label.anchor_top = 1.0
	version_label.anchor_bottom = 1.0
	version_label.offset_left = -124
	version_label.offset_top = -48
	version_label.offset_right = -24
	version_label.offset_bottom = -22
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.add_theme_color_override("font_color", Color("#928B7B"))
	add_child(version_label)

func _build_main_menu_logo(parent: Control) -> void:
	var logo_box := Control.new()
	logo_box.name = "MainMenuLogoBox"
	logo_box.position = MAIN_MENU_LOGO_BOX_POSITION
	logo_box.size = MAIN_MENU_LOGO_BOX_SIZE
	logo_box.clip_contents = true
	logo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(logo_box)

	if ResourceLoader.exists(MAIN_MENU_LOGO_PATH):
		var texture := load(MAIN_MENU_LOGO_PATH)
		if texture is Texture2D:
			var logo := TextureRect.new()
			logo.name = "MainMenuLogoImage"
			logo.texture = texture
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_SCALE
			logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fit_texture_rect_inside_box(logo, texture, MAIN_MENU_LOGO_BOX_SIZE)
			logo_box.add_child(logo)
			return
	var logo_label := Label.new()
	logo_label.name = "MainMenuLogoFallbackLabel"
	logo_label.text = "黑潮计划"
	logo_label.anchor_right = 1.0
	logo_label.anchor_bottom = 1.0
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo_label.add_theme_font_size_override("font_size", 42)
	logo_label.add_theme_color_override("font_color", Color("#E6E1D8"))
	logo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	logo_label.add_theme_constant_override("shadow_offset_x", 2)
	logo_label.add_theme_constant_override("shadow_offset_y", 2)
	logo_box.add_child(logo_label)

func _fit_texture_rect_inside_box(rect: TextureRect, texture: Texture2D, box_size: Vector2) -> void:
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		rect.position = Vector2.ZERO
		rect.size = box_size
		return
	var scale: float = minf(box_size.x / texture_size.x, box_size.y / texture_size.y)
	var fitted_size: Vector2 = texture_size * scale
	rect.position = (box_size - fitted_size) * 0.5
	rect.size = fitted_size

func _apply_main_menu_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _main_menu_button_style(Color(0.01, 0.05, 0.06, 0.56), Color("#2F7F8D")))
	button.add_theme_stylebox_override("hover", _main_menu_button_style(Color(0.02, 0.12, 0.14, 0.66), Color("#35C9D7")))
	button.add_theme_stylebox_override("pressed", _main_menu_button_style(Color(0.0, 0.16, 0.18, 0.76), Color("#35C9D7")))
	button.add_theme_stylebox_override("focus", _main_menu_button_style(Color(0.01, 0.09, 0.11, 0.66), Color("#D8C64C")))
	button.add_theme_color_override("font_color", Color("#ECE8DE"))
	button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	button.add_theme_font_size_override("font_size", 22)

func _main_menu_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := _flat_panel_style(bg_color, border_color, 1)
	style.content_margin_left = 24
	style.content_margin_top = 12
	style.content_margin_right = 24
	style.content_margin_bottom = 12
	return style

func _build_username_dialog() -> void:
	_username_overlay = Control.new()
	_username_overlay.name = "UsernameOverlay"
	_username_overlay.visible = false
	_username_overlay.anchor_right = 1.0
	_username_overlay.anchor_bottom = 1.0
	_username_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_username_overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "UsernameBackgroundPlaceholder"
	backdrop.color = Color("#171211")
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	_username_overlay.add_child(backdrop)

	_username_panel = Panel.new()
	_username_panel.name = "UsernameProfilePanel"
	_username_panel.anchor_left = 0.5
	_username_panel.anchor_right = 0.5
	_username_panel.anchor_top = 0.5
	_username_panel.anchor_bottom = 0.5
	_username_panel.offset_left = -368.0
	_username_panel.offset_top = -193.0
	_username_panel.offset_right = 368.0
	_username_panel.offset_bottom = 193.0
	_username_panel.add_theme_stylebox_override("panel", _flat_panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	_username_overlay.add_child(_username_panel)

	var label := Label.new()
	label.name = "UsernamePromptLabel"
	label.text = "请输入用户名"
	label.position = Vector2(0, 142)
	label.size = Vector2(736, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#D8D6CE"))
	_username_panel.add_child(label)

	_username_edit = LineEdit.new()
	_username_edit.name = "UsernameEdit"
	_username_edit.placeholder_text = ""
	_username_edit.position = Vector2(242, 176)
	_username_edit.size = Vector2(252, 36)
	_username_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_username_edit.add_theme_stylebox_override("normal", _flat_panel_style(Color("#6C6867"), Color("#2F7F8D"), 1))
	_username_edit.add_theme_stylebox_override("focus", _flat_panel_style(Color("#706C6B"), Color("#35C9D7"), 1))
	_username_edit.add_theme_stylebox_override("read_only", _flat_panel_style(Color("#585453"), Color("#2F7F8D"), 1))
	_username_edit.add_theme_font_size_override("font_size", 16)
	_username_edit.add_theme_color_override("font_color", Color("#F0EDE4"))
	_username_edit.add_theme_color_override("caret_color", Color("#F0EDE4"))
	_username_edit.text_submitted.connect(func(_text): _on_username_confirmed())
	_username_panel.add_child(_username_edit)

	_username_error = Label.new()
	_username_error.name = "UsernameErrorLabel"
	_username_error.text = ""
	_username_error.position = Vector2(226, 224)
	_username_error.size = Vector2(284, 38)
	_username_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_username_error.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_username_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_username_error.add_theme_color_override("font_color", Color("#D98686"))
	_username_panel.add_child(_username_error)

	_username_confirm_button = Panel.new()
	_username_confirm_button.name = "UsernameConfirmButton"
	_username_confirm_button.position = Vector2(320, 272)
	_username_confirm_button.size = Vector2(96, 26)
	_username_confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_username_confirm_button.add_theme_stylebox_override("panel", _compact_button_style(Color("#061012"), Color("#2F7F8D")))
	_username_confirm_button.gui_input.connect(_on_username_confirm_button_input)
	_username_confirm_button.mouse_entered.connect(func():
		_username_confirm_button.add_theme_stylebox_override("panel", _compact_button_style(Color("#0B1D21"), Color("#35C9D7")))
	)
	_username_confirm_button.mouse_exited.connect(func():
		_username_confirm_button.add_theme_stylebox_override("panel", _compact_button_style(Color("#061012"), Color("#2F7F8D")))
	)
	_username_panel.add_child(_username_confirm_button)

	var confirm_label := Label.new()
	confirm_label.text = "确认"
	confirm_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_label.anchor_right = 1.0
	confirm_label.anchor_bottom = 1.0
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 12)
	confirm_label.add_theme_color_override("font_color", Color("#D8D6CE"))
	_username_confirm_button.add_child(confirm_label)

func _on_start_pressed() -> void:
	if _game_state == null:
		return
	if _game_state.has_method("has_profile") and _game_state.has_profile():
		if _game_state.has_method("load_profile"):
			_game_state.load_profile()
		if (
			_game_state.has_method("should_play_intro_cinematic")
			and _game_state.should_play_intro_cinematic()
		) or (
			_game_state.has_method("should_play_world_intro_dialogue")
			and _game_state.should_play_world_intro_dialogue()
		):
			_begin_new_profile_story_flow()
			return
		get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")
		return
	_username_edit.text = ""
	_username_error.text = ""
	_show_username_overlay()

func _on_username_confirmed() -> void:
	if _game_state == null or not _game_state.has_method("create_profile"):
		return
	var result: Dictionary = _game_state.create_profile(_username_edit.text)
	if not bool(result.get("ok", false)):
		_username_error.text = String(result.get("message", "请输入 2-12 个字符的用户名"))
		_show_username_overlay()
		return
	_username_overlay.visible = false
	_begin_new_profile_story_flow()

func _begin_new_profile_story_flow() -> void:
	if _game_state != null and _game_state.has_method("should_play_intro_cinematic") and _game_state.should_play_intro_cinematic():
		_show_intro_cinematic()
		return
	_enter_base_scene()

func _show_intro_cinematic() -> void:
	if is_instance_valid(_intro_cinematic_overlay):
		return
	_intro_cinematic_finishing = false
	_pause_bgm_for_intro_cinematic()
	_intro_cinematic_overlay = Control.new()
	_intro_cinematic_overlay.name = "OpeningCinematicOverlay"
	_intro_cinematic_overlay.anchor_right = 1.0
	_intro_cinematic_overlay.anchor_bottom = 1.0
	_intro_cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_intro_cinematic_overlay)

	var cinematic_config := _load_intro_cinematic_config()
	var bg := ColorRect.new()
	bg.name = "OpeningCinematicBackground"
	bg.color = Color("#050505")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_intro_cinematic_overlay.add_child(bg)

	var frame := ColorRect.new()
	frame.name = "OpeningCinematicPlaceholder16x9"
	frame.color = Color("#120E0E")
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	_intro_cinematic_overlay.add_child(frame)

	var placeholder_label := Label.new()
	placeholder_label.text = "开场影像占位"
	placeholder_label.anchor_left = 0.5
	placeholder_label.anchor_right = 0.5
	placeholder_label.anchor_top = 0.5
	placeholder_label.anchor_bottom = 0.5
	placeholder_label.offset_left = -160.0
	placeholder_label.offset_top = -18.0
	placeholder_label.offset_right = 160.0
	placeholder_label.offset_bottom = 18.0
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_font_size_override("font_size", 18)
	placeholder_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76, 0.45))
	_intro_cinematic_overlay.add_child(placeholder_label)
	var video_loaded := _add_intro_cinematic_video(cinematic_config, frame, placeholder_label)

	var skip_button := Button.new()
	skip_button.name = "SkipOpeningCinematicButton"
	skip_button.text = String(cinematic_config.get("skip_label", "跳过影像"))
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_top = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left = -164.0
	skip_button.offset_top = -72.0
	skip_button.offset_right = -36.0
	skip_button.offset_bottom = -34.0
	skip_button.pressed.connect(func(): _finish_intro_cinematic(true))
	_intro_cinematic_overlay.add_child(skip_button)

	if not video_loaded:
		var placeholder_config: Dictionary = cinematic_config.get("placeholder", {})
		var duration := float(placeholder_config.get("duration_seconds", INTRO_CINEMATIC_PLACEHOLDER_SECONDS))
		var timer := get_tree().create_timer(max(0.1, duration))
		timer.timeout.connect(func():
			if is_instance_valid(_intro_cinematic_overlay):
				_finish_intro_cinematic(false)
		)

func _finish_intro_cinematic(_skipped: bool) -> void:
	if _intro_cinematic_finishing:
		return
	_intro_cinematic_finishing = true
	if is_instance_valid(_intro_cinematic_video_player):
		_intro_cinematic_video_player.stop()
	_intro_cinematic_video_player = null
	_resume_bgm_after_intro_cinematic()
	if _game_state != null and _game_state.has_method("mark_intro_cinematic_seen"):
		_game_state.mark_intro_cinematic_seen()
	if is_instance_valid(_intro_cinematic_overlay):
		_intro_cinematic_overlay.queue_free()
	_intro_cinematic_overlay = null
	_enter_base_scene()

func _enter_base_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

func _play_base_safe_house_bgm() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_base_safe_house_bgm"):
		audio_manager.play_base_safe_house_bgm()

func _pause_bgm_for_intro_cinematic() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("pause_bgm"):
		audio_manager.pause_bgm()

func _resume_bgm_after_intro_cinematic() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("resume_bgm"):
		audio_manager.resume_bgm()

func _load_intro_cinematic_config() -> Dictionary:
	var fallback := {
		"resource_path": INTRO_CINEMATIC_DEFAULT_PATH,
		"fallback_resource_path": INTRO_CINEMATIC_FALLBACK_PATH,
		"placeholder": {
			"duration_seconds": INTRO_CINEMATIC_PLACEHOLDER_SECONDS,
		},
		"skip_label": "跳过影像",
	}
	if not FileAccess.file_exists(INTRO_CINEMATIC_CONFIG_PATH):
		return fallback
	var file := FileAccess.open(INTRO_CINEMATIC_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in fallback.keys():
			if not parsed.has(key):
				parsed[key] = fallback[key]
		return parsed
	return fallback

func _add_intro_cinematic_video(config: Dictionary, frame: ColorRect, placeholder_label: Label) -> bool:
	var stream := _load_first_video_stream(_intro_cinematic_video_paths(config))
	if stream == null:
		return false
	var video_player := VideoStreamPlayer.new()
	video_player.name = "OpeningCinematicVideoPlayer"
	video_player.stream = stream
	video_player.expand = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.finished.connect(func():
		_finish_intro_cinematic(false)
	)
	_intro_cinematic_overlay.add_child(video_player)
	_intro_cinematic_video_player = video_player
	_fit_control_to_16x9_cover(video_player)
	frame.visible = false
	placeholder_label.visible = false
	video_player.play()
	return true

func _intro_cinematic_video_paths(config: Dictionary) -> Array:
	var paths: Array = []
	_append_unique_video_path(paths, String(config.get("resource_path", "")))
	_append_unique_video_path(paths, String(config.get("fallback_resource_path", "")))
	var fallback_paths = config.get("fallback_resource_paths", [])
	if fallback_paths is Array:
		for fallback_path in fallback_paths:
			_append_unique_video_path(paths, String(fallback_path))
	_append_unique_video_path(paths, INTRO_CINEMATIC_DEFAULT_PATH)
	_append_unique_video_path(paths, INTRO_CINEMATIC_FALLBACK_PATH)
	return paths

func _append_unique_video_path(paths: Array, path: String) -> void:
	if path.is_empty() or paths.has(path):
		return
	paths.append(path)

func _load_first_video_stream(paths: Array) -> VideoStream:
	for path in paths:
		var stream := _load_video_stream(String(path))
		if stream != null:
			return stream
	return null

func _load_video_stream(path: String) -> VideoStream:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	if path.get_extension().to_lower() == "ogv" and not _is_ogg_theora_video(path):
		push_warning("Video is not a valid Ogg Theora file: %s" % path)
		return null
	var resource := ResourceLoader.load(path, "VideoStream")
	if resource is VideoStream:
		return resource
	resource = load(path)
	if resource is VideoStream:
		return resource
	push_warning("Video stream could not be loaded. MP4 playback requires the FFmpeg GDExtension: %s" % path)
	return null

func _is_ogg_theora_video(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var header := file.get_buffer(512)
	return _buffer_starts_with_ascii(header, "OggS") and _buffer_has_ascii(header, "theora")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_video_cover_rects()

func _refresh_video_cover_rects() -> void:
	if is_instance_valid(_main_menu_background_video_player):
		_fit_control_to_16x9_cover(_main_menu_background_video_player)
	if is_instance_valid(_intro_cinematic_video_player):
		_fit_control_to_16x9_cover(_intro_cinematic_video_player)

func _fit_control_to_16x9_cover(control: Control) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var width := viewport_size.x
	var height := width * 9.0 / 16.0
	if height < viewport_size.y:
		height = viewport_size.y
		width = height * 16.0 / 9.0
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = -width * 0.5
	control.offset_right = width * 0.5
	control.offset_top = -height * 0.5
	control.offset_bottom = height * 0.5

func _set_object_property_if_exists(object: Object, property_name: String, value: Variant) -> void:
	for property in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			object.set(property_name, value)
			return

func _buffer_starts_with_ascii(buffer: PackedByteArray, text: String) -> bool:
	var expected := text.to_ascii_buffer()
	if buffer.size() < expected.size():
		return false
	for index in range(expected.size()):
		if buffer[index] != expected[index]:
			return false
	return true

func _buffer_has_ascii(buffer: PackedByteArray, text: String) -> bool:
	var expected := text.to_ascii_buffer()
	if expected.is_empty() or buffer.size() < expected.size():
		return false
	for start in range(buffer.size() - expected.size() + 1):
		var matched := true
		for index in range(expected.size()):
			if buffer[start + index] != expected[index]:
				matched = false
				break
		if matched:
			return true
	return false

func _show_username_overlay() -> void:
	if _username_overlay == null:
		return
	_username_overlay.visible = true
	_username_edit.grab_focus()

func _on_username_confirm_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_play_ui_button_click()
		_on_username_confirmed()

func _play_ui_button_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_ui_button_click"):
		audio_manager.play_ui_button_click()

func _flat_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 8
	style.content_margin_top = 4
	style.content_margin_right = 8
	style.content_margin_bottom = 4
	return style

func _compact_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := _flat_panel_style(bg_color, border_color, 1)
	style.content_margin_left = 4
	style.content_margin_top = 0
	style.content_margin_right = 4
	style.content_margin_bottom = 0
	return style

func _on_settings_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "设置"
	dialog.dialog_text = "设置页将在后续版本开放。"
	add_child(dialog)
	dialog.popup_centered()

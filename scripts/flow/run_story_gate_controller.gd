class_name RunStoryGateController
extends RefCounted

const SECOND_DAY_BLACK_TIDE_TOKEN := "second_day_black_tide_reveal"
const SECOND_DAY_BLACK_TIDE_DIALOGUE_PATH := "res://setting/dialogues.tab#second_day_black_tide_reveal_dialogue"
const SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH := "res://assets/cinematics/source/second_day_black_tide_reveal_720p.mp4"
const SECOND_DAY_BLACK_TIDE_CINEMATIC_FALLBACK_PATH := "res://assets/cinematics/second_day_black_tide_reveal_720p.ogv"
const SECOND_DAY_BLACK_TIDE_PLACEHOLDER_SECONDS := 1.2
const WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID := "project-escape-second-day-black-tide-video"

var scene: Node
var ui_root: CanvasLayer
var game_state: Node
var dialogue_service
var dialogue_panel_scene: PackedScene
var web_video_bridge
var pause_service
var ui_refresh_callback: Callable

var gate_running: bool = false
var video_overlay: Control
var video_player: VideoStreamPlayer
var video_finish_timer: Timer
var active_dialogue_panel: Control

var _video_bgm_paused := false
var _web_video_active := false


func setup(
	p_scene: Node,
	p_ui_root: CanvasLayer,
	p_game_state: Node,
	p_dialogue_service,
	p_dialogue_panel_scene: PackedScene,
	p_web_video_bridge,
	p_pause_service,
	p_ui_refresh_callback: Callable
) -> void:
	scene = p_scene
	ui_root = p_ui_root
	game_state = p_game_state
	dialogue_service = p_dialogue_service
	dialogue_panel_scene = p_dialogue_panel_scene
	web_video_bridge = p_web_video_bridge
	pause_service = p_pause_service
	ui_refresh_callback = p_ui_refresh_callback


func cleanup() -> void:
	_web_video_active = false
	if web_video_bridge != null:
		web_video_bridge.remove(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID)
		web_video_bridge.set_canvas_transparent(false)
	_resume_bgm_after_video()
	release_pause(SECOND_DAY_BLACK_TIDE_TOKEN)


func prepare_initial_gate(run_context) -> void:
	if should_trigger_second_day_black_tide_story(run_context):
		acquire_pause(SECOND_DAY_BLACK_TIDE_TOKEN)


func maybe_start_run_story_gate(run_context) -> void:
	if gate_running:
		return
	if scene == null or not is_instance_valid(scene):
		return
	await scene.get_tree().process_frame
	if not should_trigger_second_day_black_tide_story(run_context):
		release_pause(SECOND_DAY_BLACK_TIDE_TOKEN)
		return
	gate_running = true
	acquire_pause(SECOND_DAY_BLACK_TIDE_TOKEN)
	await _play_second_day_black_tide_story()
	gate_running = false


func should_trigger_second_day_black_tide_story(run_context) -> bool:
	if game_state == null or run_context == null:
		return false
	var run_day_index := int(run_context.run_day_index)
	if game_state.has_method("should_play_second_day_black_tide_reveal"):
		return bool(game_state.should_play_second_day_black_tide_reveal(run_day_index))
	return run_day_index == 2 and not bool(game_state.get("second_day_black_tide_reveal_seen"))


func finish_second_day_black_tide_cinematic(_skipped: bool = false) -> void:
	_web_video_active = false
	if web_video_bridge != null:
		web_video_bridge.remove(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID)
		web_video_bridge.set_canvas_transparent(false)
	if is_instance_valid(video_finish_timer):
		video_finish_timer.stop()
	if is_instance_valid(video_player):
		video_player.stop()
	if is_instance_valid(video_overlay):
		video_overlay.queue_free()
	video_finish_timer = null
	video_player = null
	video_overlay = null
	_resume_bgm_after_video()


func update_web_video() -> void:
	if not _web_video_active or web_video_bridge == null:
		return
	if web_video_bridge.is_ended(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID):
		finish_second_day_black_tide_cinematic(false)


func acquire_pause(token: String) -> void:
	if pause_service == null or token.is_empty():
		return
	pause_service.acquire(token)


func release_pause(token: String) -> void:
	if pause_service == null or token.is_empty():
		return
	pause_service.release(token)


func is_paused() -> bool:
	return pause_service != null and pause_service.is_paused()


func refresh_video_cover() -> void:
	if is_instance_valid(video_player):
		_fit_control_to_16x9_cover(video_player)


func _play_second_day_black_tide_story() -> void:
	_show_second_day_black_tide_cinematic()
	while is_instance_valid(video_overlay):
		await scene.get_tree().process_frame
	await _play_run_story_dialogue(SECOND_DAY_BLACK_TIDE_DIALOGUE_PATH)
	if game_state != null and game_state.has_method("mark_second_day_black_tide_reveal_seen"):
		game_state.mark_second_day_black_tide_reveal_seen()
	release_pause(SECOND_DAY_BLACK_TIDE_TOKEN)
	if ui_refresh_callback.is_valid():
		ui_refresh_callback.call()


func _show_second_day_black_tide_cinematic() -> void:
	if is_instance_valid(video_overlay) or ui_root == null:
		return
	var overlay := Control.new()
	overlay.name = "SecondDayBlackTideCinematicOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	ui_root.add_child(overlay)
	video_overlay = overlay

	var background := ColorRect.new()
	background.name = "SecondDayBlackTideCinematicBackground"
	background.color = Color("#050505")
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	overlay.add_child(background)

	var frame := ColorRect.new()
	frame.name = "SecondDayBlackTideCinematicPlaceholder16x9"
	frame.color = Color("#120E0E")
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	overlay.add_child(frame)

	var placeholder_label := Label.new()
	placeholder_label.name = "SecondDayBlackTideCinematicPlaceholderLabel"
	placeholder_label.text = "暗潮影像同步中..."
	placeholder_label.anchor_left = 0.5
	placeholder_label.anchor_right = 0.5
	placeholder_label.anchor_top = 0.5
	placeholder_label.anchor_bottom = 0.5
	placeholder_label.offset_left = -180.0
	placeholder_label.offset_top = -18.0
	placeholder_label.offset_right = 180.0
	placeholder_label.offset_bottom = 18.0
	placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_label.add_theme_font_size_override("font_size", 18)
	placeholder_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76, 0.5))
	overlay.add_child(placeholder_label)

	var video_loaded := _add_second_day_black_tide_video(background, frame, placeholder_label)
	var skip_button := Button.new()
	skip_button.name = "SkipSecondDayBlackTideCinematicButton"
	skip_button.text = "跳过影像"
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_top = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left = -164.0
	skip_button.offset_top = -72.0
	skip_button.offset_right = -36.0
	skip_button.offset_bottom = -34.0
	skip_button.pressed.connect(func(): finish_second_day_black_tide_cinematic(true))
	overlay.add_child(skip_button)
	if video_loaded and OS.has_feature("web"):
		skip_button.visible = false

	if not video_loaded:
		push_warning("Second day black tide cinematic is missing or unsupported; continuing with placeholder.")
		video_finish_timer = Timer.new()
		video_finish_timer.one_shot = true
		video_finish_timer.wait_time = SECOND_DAY_BLACK_TIDE_PLACEHOLDER_SECONDS
		video_finish_timer.timeout.connect(func(): finish_second_day_black_tide_cinematic(false))
		overlay.add_child(video_finish_timer)
		video_finish_timer.start()


func _add_second_day_black_tide_video(background: ColorRect, frame: ColorRect, placeholder_label: Label) -> bool:
	if OS.has_feature("web") and web_video_bridge != null:
		var web_url: String = web_video_bridge.res_path_to_web_url(SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH)
		if not web_video_bridge.play(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID, web_url, false, false, true, true):
			return false
		_web_video_active = true
		background.visible = false
		frame.visible = false
		placeholder_label.visible = false
		_pause_bgm_for_video()
		return true

	var stream := _load_first_story_video_stream([
		SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH,
		SECOND_DAY_BLACK_TIDE_CINEMATIC_FALLBACK_PATH,
	])
	if stream == null:
		return false
	var player := VideoStreamPlayer.new()
	player.name = "SecondDayBlackTideCinematicVideoPlayer"
	player.stream = stream
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.finished.connect(func(): finish_second_day_black_tide_cinematic(false))
	video_overlay.add_child(player)
	video_player = player
	_fit_control_to_16x9_cover(player)
	background.visible = false
	frame.visible = false
	placeholder_label.visible = false
	_pause_bgm_for_video()
	player.play()
	return true


func _pause_bgm_for_video() -> void:
	if _video_bgm_paused:
		return
	var audio_manager := _get_audio_manager()
	if audio_manager != null and audio_manager.has_method("pause_bgm"):
		audio_manager.pause_bgm()
		_video_bgm_paused = true


func _resume_bgm_after_video() -> void:
	if not _video_bgm_paused:
		return
	_video_bgm_paused = false
	var audio_manager := _get_audio_manager()
	if audio_manager != null and audio_manager.has_method("resume_bgm"):
		audio_manager.resume_bgm()


func _get_audio_manager() -> Node:
	if scene == null or not is_instance_valid(scene):
		return null
	return scene.get_node_or_null("/root/AudioManager")


func _load_first_story_video_stream(paths: Array) -> VideoStream:
	for path in paths:
		var stream := _load_story_video_stream(String(path))
		if stream != null:
			return stream
	return null


func _load_story_video_stream(path: String) -> VideoStream:
	if OS.has_feature("web") and path.get_extension().to_lower() == "mp4":
		return null
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


func _buffer_starts_with_ascii(buffer: PackedByteArray, value: String) -> bool:
	var bytes := value.to_ascii_buffer()
	if buffer.size() < bytes.size():
		return false
	for index in range(bytes.size()):
		if buffer[index] != bytes[index]:
			return false
	return true


func _buffer_has_ascii(buffer: PackedByteArray, value: String) -> bool:
	var needle := value.to_ascii_buffer()
	if needle.is_empty() or buffer.size() < needle.size():
		return false
	for start in range(buffer.size() - needle.size() + 1):
		var found := true
		for offset in range(needle.size()):
			if buffer[start + offset] != needle[offset]:
				found = false
				break
		if found:
			return true
	return false


func _play_run_story_dialogue(path: String) -> void:
	if dialogue_service == null:
		push_warning("Run story dialogue service is missing.")
		return
	var sequence: Dictionary = dialogue_service.load_sequence(path)
	if sequence.is_empty():
		push_warning("Run story dialogue sequence is missing: %s" % path)
		return
	if dialogue_panel_scene == null or ui_root == null:
		push_warning("Run story dialogue panel is missing.")
		return
	var panel = dialogue_panel_scene.instantiate()
	panel.name = "RunStoryDialoguePanel"
	active_dialogue_panel = panel
	ui_root.add_child(panel)
	var dialogue_finished := false
	panel.dialogue_finished.connect(func(_dialogue_id: String, _skipped: bool):
		dialogue_finished = true
	)
	panel.tree_exiting.connect(func():
		if active_dialogue_panel == panel:
			active_dialogue_panel = null
	)
	panel.play_sequence(sequence)
	while not dialogue_finished and is_instance_valid(panel):
		await scene.get_tree().process_frame
	if active_dialogue_panel == panel:
		active_dialogue_panel = null


func _fit_control_to_16x9_cover(control: Control) -> void:
	var viewport := control.get_viewport()
	if viewport == null:
		return
	var viewport_size := viewport.get_visible_rect().size
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


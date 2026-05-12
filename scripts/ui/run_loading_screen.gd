class_name RunLoadingScreen
extends Control

signal loading_completed(run_scene: PackedScene)
signal loading_failed(reason: String)

const STAGES_PATH := "res://data/loading/run_loading_stages.json"
const TIPS_PATH := "res://data/loading/run_loading_tips.json"
const RUN_SCENE_PATH := "res://scenes/run/RunScene.tscn"

var title_label: Label
var stage_label: Label
var percent_label: Label
var tip_label: Label
var controls_label: Label
var mechanics_label: Label
var continue_label: Label
var progress_bar: ProgressBar
var target_progress := 0.0
var display_progress := 0.0
var force_fail := false
var slow_mode := false
var _loaded_run_scene: PackedScene
var _ready_to_continue := false

func _ready() -> void:
	_build()
	set_process(true)
	set_process_input(true)

func begin_loading(options: Dictionary = {}) -> void:
	if progress_bar == null:
		call_deferred("begin_loading", options.duplicate(true))
		return
	force_fail = bool(options.get("force_fail", false))
	slow_mode = bool(options.get("slow_mode", false))
	_ready_to_continue = false
	target_progress = 0.0
	display_progress = 0.0
	progress_bar.value = 0.0
	percent_label.text = "0%"
	stage_label.text = "校验出发装备..."
	tip_label.text = _pick_tip()
	continue_label.visible = false
	visible = true
	call_deferred("_run_loading")

func is_ready_to_continue() -> bool:
	return _ready_to_continue

func _process(delta: float) -> void:
	if progress_bar == null:
		return
	display_progress = minf(target_progress, move_toward(display_progress, target_progress, delta * 1.8))
	progress_bar.value = display_progress * 100.0
	percent_label.text = "%d%%" % int(floor(display_progress * 100.0))
	if _ready_to_continue:
		progress_bar.value = 100.0
		percent_label.text = "100%"

func _input(event: InputEvent) -> void:
	if not _ready_to_continue:
		return
	if not _is_continue_event(event):
		return
	_ready_to_continue = false
	get_viewport().set_input_as_handled()
	loading_completed.emit(_loaded_run_scene)
	queue_free()

func _build() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color("#11100E")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var frame := Panel.new()
	frame.name = "LoadingFrame"
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -460.0
	frame.offset_top = -260.0
	frame.offset_right = 460.0
	frame.offset_bottom = 260.0
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.052, 0.048, 0.96), Color("#7F6A34"), 2))
	add_child(frame)

	title_label = Label.new()
	title_label.text = "正在前往地面"
	title_label.position = Vector2(0, 36)
	title_label.size = Vector2(920, 42)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("#E8E1D4"))
	frame.add_child(title_label)

	stage_label = Label.new()
	stage_label.text = "校验出发装备..."
	stage_label.position = Vector2(0, 100)
	stage_label.size = Vector2(920, 32)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color("#C8B98D"))
	frame.add_child(stage_label)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(140, 152)
	progress_bar.size = Vector2(640, 18)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	frame.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.text = "0%"
	percent_label.position = Vector2(0, 184)
	percent_label.size = Vector2(920, 26)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 16)
	percent_label.add_theme_color_override("font_color", Color("#DED8CC"))
	frame.add_child(percent_label)

	continue_label = Label.new()
	continue_label.text = "按下任意按钮继续"
	continue_label.position = Vector2(0, 216)
	continue_label.size = Vector2(920, 30)
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_color_override("font_color", Color("#D1B850"))
	continue_label.visible = false
	frame.add_child(continue_label)

	var controls_title := _make_hint_title("操作提示", Vector2(104, 270), Vector2(180, 24))
	frame.add_child(controls_title)

	controls_label = _make_hint_body("WASD 移动    Tab 背包    F 拾取/交互    E 撤离", Vector2(104, 302), Vector2(712, 30))
	controls_label.name = "ControlsHintLabel"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(controls_label)

	var mechanics_title := _make_hint_title("地表规则", Vector2(104, 352), Vector2(180, 24))
	frame.add_child(mechanics_title)

	mechanics_label = _make_hint_body("暗潮会压缩视野，稳定值会持续下降；回到基地后稳定值会恢复。", Vector2(104, 384), Vector2(712, 44))
	mechanics_label.name = "MechanicsHintLabel"
	mechanics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mechanics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(mechanics_label)

	tip_label = _make_hint_body(_pick_tip(), Vector2(104, 446), Vector2(712, 38))
	tip_label.name = "LoadingTipLabel"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(tip_label)

func _run_loading() -> void:
	var start_ticks := Time.get_ticks_msec()
	for stage in _load_stages():
		if not (stage is Dictionary):
			continue
		var stage_dict: Dictionary = stage
		var stage_id := String(stage_dict.get("stage_id", ""))
		if stage_id == "ready_to_continue":
			continue
		stage_label.text = String(stage_dict.get("text", ""))
		target_progress = clampf(float(stage_dict.get("progress", target_progress)), 0.0, 0.99)
		if stage_id == "load_map":
			_loaded_run_scene = load(RUN_SCENE_PATH)
			if _loaded_run_scene == null:
				loading_failed.emit("run_scene_missing")
				queue_free()
				return
		if force_fail and stage_id == "init_loot":
			loading_failed.emit("debug_forced_failure")
			queue_free()
			return
		await _stage_wait()
	while Time.get_ticks_msec() - start_ticks < 1000:
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	target_progress = 1.0
	display_progress = 1.0
	progress_bar.value = 100.0
	percent_label.text = "100%"
	stage_label.text = "地面部署完成"
	tip_label.text = "先找菱形材料，修复前哨站，再撤离。"
	continue_label.visible = true
	_ready_to_continue = true

func _stage_wait() -> void:
	await get_tree().process_frame
	if slow_mode:
		await get_tree().create_timer(0.12).timeout

func _load_stages() -> Array:
	if not FileAccess.file_exists(STAGES_PATH):
		return []
	var file := FileAccess.open(STAGES_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Array else []

func _pick_tip() -> String:
	if not FileAccess.file_exists(TIPS_PATH):
		return "先找菱形材料，修复前哨站，再撤离。"
	var file := FileAccess.open(TIPS_PATH, FileAccess.READ)
	if file == null:
		return "先找菱形材料，修复前哨站，再撤离。"
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array and not parsed.is_empty():
		return String(parsed[randi() % parsed.size()])
	return "先找菱形材料，修复前哨站，再撤离。"

func _is_continue_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false

func _make_hint_title(text: String, pos: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#D1B850"))
	return label

func _make_hint_body(text: String, pos: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#D8D6CE"))
	return label

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

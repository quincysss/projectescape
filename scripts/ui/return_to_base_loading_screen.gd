class_name ReturnToBaseLoadingScreen
extends Control

signal return_completed
signal return_failed(reason: String)

const BASE_SCENE_PATH := "res://scenes/base/BaseScene.tscn"
const RETURN_STAGES := [
	{"stage_id": "lock_settlement", "text": "封存本局记录...", "progress": 0.10},
	{"stage_id": "transfer_items", "text": "整理带回物资...", "progress": 0.35},
	{"stage_id": "save_warehouse", "text": "同步哨所仓库...", "progress": 0.55},
	{"stage_id": "clear_run", "text": "关闭地表通道...", "progress": 0.75},
	{"stage_id": "load_base", "text": "返回404哨所...", "progress": 0.92},
	{"stage_id": "prewarm_base_ui", "text": "点亮哨所终端...", "progress": 0.98},
]

var title_label: Label
var stage_label: Label
var percent_label: Label
var tip_label: Label
var continue_label: Label
var progress_bar: ProgressBar

var target_progress := 0.0
var display_progress := 0.0
var slow_mode := false
var change_scene_on_continue := true

var _result: Dictionary = {}
var _game_state
var _ready_to_continue := false
var _running := false
var _committed := false

func _ready() -> void:
	_build()
	set_process(true)
	set_process_input(true)

func begin_return(result: Dictionary, game_state = null, options: Dictionary = {}) -> void:
	if progress_bar == null:
		call_deferred("begin_return", result.duplicate(true), game_state, options.duplicate(true))
		return
	_result = result.duplicate(true)
	_game_state = game_state
	slow_mode = bool(options.get("slow_mode", false))
	change_scene_on_continue = bool(options.get("change_scene", true))
	_ready_to_continue = false
	_running = false
	_committed = false
	target_progress = 0.0
	display_progress = 0.0
	progress_bar.value = 0.0
	percent_label.text = "0%"
	title_label.text = "正在返回404哨所"
	stage_label.text = "封存本局记录..."
	tip_label.text = _completion_tip()
	continue_label.visible = false
	visible = true
	call_deferred("_run_return_loading")

func is_ready_to_continue() -> bool:
	return _ready_to_continue

func has_committed_result() -> bool:
	return _committed

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
	return_completed.emit()
	if change_scene_on_continue:
		get_tree().change_scene_to_file(BASE_SCENE_PATH)
	queue_free()

func _build() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1100

	var bg := ColorRect.new()
	bg.name = "BlackBackground"
	bg.color = Color.BLACK
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var frame := Panel.new()
	frame.name = "ReturnLoadingFrame"
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -430.0
	frame.offset_top = -210.0
	frame.offset_right = 430.0
	frame.offset_bottom = 210.0
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.0, 0.0, 0.0, 0.0), Color("#1E2528"), 1))
	add_child(frame)

	title_label = Label.new()
	title_label.name = "ReturnTitleLabel"
	title_label.text = "正在返回404哨所"
	title_label.position = Vector2(0.0, 36.0)
	title_label.size = Vector2(860.0, 48.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("#F0ECE3"))
	frame.add_child(title_label)

	stage_label = Label.new()
	stage_label.name = "ReturnStageLabel"
	stage_label.text = "封存本局记录..."
	stage_label.position = Vector2(0.0, 112.0)
	stage_label.size = Vector2(860.0, 32.0)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color("#D6C57B"))
	frame.add_child(stage_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "ReturnProgressBar"
	progress_bar.position = Vector2(140.0, 172.0)
	progress_bar.size = Vector2(580.0, 18.0)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	frame.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.name = "ReturnPercentLabel"
	percent_label.text = "0%"
	percent_label.position = Vector2(0.0, 204.0)
	percent_label.size = Vector2(860.0, 26.0)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 16)
	percent_label.add_theme_color_override("font_color", Color("#DED8CC"))
	frame.add_child(percent_label)

	continue_label = Label.new()
	continue_label.name = "ReturnContinueLabel"
	continue_label.text = "按下任意按钮继续"
	continue_label.position = Vector2(0.0, 244.0)
	continue_label.size = Vector2(860.0, 30.0)
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_color_override("font_color", Color("#D1B850"))
	continue_label.visible = false
	frame.add_child(continue_label)

	tip_label = Label.new()
	tip_label.name = "ReturnTipLabel"
	tip_label.text = _completion_tip()
	tip_label.position = Vector2(90.0, 310.0)
	tip_label.size = Vector2(680.0, 44.0)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.add_theme_font_size_override("font_size", 15)
	tip_label.add_theme_color_override("font_color", Color("#AFA99D"))
	frame.add_child(tip_label)

func _run_return_loading() -> void:
	if _running:
		return
	_running = true
	for stage in RETURN_STAGES:
		if not (stage is Dictionary):
			continue
		var stage_dict: Dictionary = stage
		var stage_id := String(stage_dict.get("stage_id", ""))
		stage_label.text = String(stage_dict.get("text", ""))
		target_progress = clampf(float(stage_dict.get("progress", target_progress)), 0.0, 0.99)
		if stage_id == "save_warehouse":
			var commit_result := _commit_result_once()
			if not bool(commit_result.get("ok", false)):
				_show_failure(String(commit_result.get("reason", "commit_failed")), String(commit_result.get("message", "返回哨所失败。")))
				return
		await _stage_wait()

	target_progress = 1.0
	display_progress = 1.0
	progress_bar.value = 100.0
	percent_label.text = "100%"
	stage_label.text = "按下任意按钮继续"
	tip_label.text = _completion_tip()
	continue_label.visible = true
	_ready_to_continue = true

func _commit_result_once() -> Dictionary:
	if _committed:
		return {"ok": true, "already_committed": true}
	if _game_state == null:
		return {"ok": false, "reason": "missing_game_state", "message": "哨所记录不可用，无法同步本局物资。"}
	var capacity_check := _check_warehouse_capacity()
	if not bool(capacity_check.get("ok", true)):
		return capacity_check
	if _game_state.has_method("apply_run_result"):
		_game_state.apply_run_result(_result)
	elif _game_state.has_method("add_to_warehouse"):
		_game_state.add_to_warehouse(Array(_result.get("warehouse_items", [])))
	else:
		return {"ok": false, "reason": "missing_commit_api", "message": "哨所仓库接口不可用，无法同步本局物资。"}
	_committed = true
	return {"ok": true}

func _check_warehouse_capacity() -> Dictionary:
	var incoming := Array(_result.get("warehouse_items", []))
	var required_slots := _count_item_units(incoming)
	if required_slots <= 0:
		return {"ok": true}
	if not (_game_state.has_method("get_warehouse_capacity") and _game_state.has_method("get_warehouse_items_snapshot")):
		return {"ok": true}
	var used_slots := Array(_game_state.get_warehouse_items_snapshot()).size()
	var capacity := int(_game_state.get_warehouse_capacity())
	var available := maxi(0, capacity - used_slots)
	if required_slots > available:
		return {
			"ok": false,
			"reason": "warehouse_capacity_insufficient",
			"message": "哨所仓库容量不足，无法同步本局物资。需要 %d 格，剩余 %d 格。" % [required_slots, available],
		}
	return {"ok": true}

func _count_item_units(items: Array) -> int:
	var total := 0
	for item in items:
		if item is Dictionary:
			total += maxi(0, int(item.get("amount", 1)))
	return total

func _show_failure(reason: String, message: String) -> void:
	_running = false
	_ready_to_continue = false
	target_progress = display_progress
	stage_label.text = message
	tip_label.text = "本局结算尚未写入，请保留此画面并检查仓库容量或存档状态。"
	continue_label.visible = false
	return_failed.emit(reason)

func _stage_wait() -> void:
	await get_tree().process_frame
	if slow_mode:
		await get_tree().create_timer(0.12).timeout

func _completion_tip() -> String:
	return "物资已同步至哨所记录。" if String(_result.get("result_type", "")) == "EXTRACTED" else "躯体重塑完成，保留物资已同步。"

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

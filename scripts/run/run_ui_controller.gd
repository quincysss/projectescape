class_name RunUiController
extends RefCounted

const STABILITY_MAX := 100.0
const STABILITY_TICKS := [
	{"label": "100", "ratio": 0.0},
	{"label": "60", "ratio": 0.4},
	{"label": "35", "ratio": 0.65},
	{"label": "15", "ratio": 0.85},
	{"label": "0", "ratio": 1.0},
]

func build(scene) -> void:
	_build_character_status_hud(scene)
	_build_outpost_status_hud(scene)
	_build_center_status_hud(scene)
	_build_backpack_status_hud(scene)
	_build_context_prompt(scene)
	_build_hidden_action_buttons(scene)
	_build_inventory_panels(scene)

func refresh(scene) -> void:
	if scene.run_director.context == null:
		return
	_refresh_stability_hud(scene)
	_refresh_countdown(scene)
	_refresh_extraction_status(scene)
	_refresh_outpost_status_hud(scene)
	_refresh_backpack_status(scene)
	_refresh_prompt(scene)
	_set_items_text(scene.inventory_label, scene.run_director.inventory_component.get_items_snapshot(), "inventory")
	_set_items_text(scene.home_storage_label, scene.get_active_storage_items_snapshot(), scene.get_active_storage_source_id())
	_set_items_text(scene.loot_label, scene.opened_loot, "loot")
	var is_home_safe_zone: bool = scene.is_home_storage_active()
	var is_storage_zone: bool = scene.is_storage_zone_active()
	_set_panel_title(scene.home_storage_panel, scene.get_active_storage_title())
	_sync_storage_ui(scene, is_storage_zone)
	var extraction_ready_at_home: bool = scene.run_director.context.is_extraction_unlocked and is_home_safe_zone
	scene.deposit_button.disabled = not is_storage_zone
	scene.deposit_button.text = "存入前哨" if scene._is_active_outpost_storage() else "存入家中"
	scene.deposit_button.size = Vector2(358, 40) if scene._is_active_outpost_storage() else Vector2(172, 40)
	scene.extract_button.disabled = not extraction_ready_at_home
	scene.extract_button.visible = not scene._is_active_outpost_storage()
	scene.extract_hud_button.disabled = not extraction_ready_at_home
	scene.extract_hud_button.text = "撤离(E)" if extraction_ready_at_home else ("返回家中" if scene.run_director.context.is_extraction_unlocked else "撤离未解锁")

func _build_character_status_hud(scene) -> void:
	scene.character_hud_root = Control.new()
	scene.character_hud_root.name = "CharacterStatusHUD"
	scene.character_hud_root.position = Vector2(18, 14)
	scene.character_hud_root.size = Vector2(560, 132)
	scene.ui_root.add_child(scene.character_hud_root)

	scene.stability_hud_root = Panel.new()
	scene.stability_hud_root.name = "StabilityPanel"
	scene.stability_hud_root.position = Vector2(104, 24)
	scene.stability_hud_root.size = Vector2(438, 82)
	scene.stability_hud_root.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.055, 0.05, 0.88), Color(0.95, 0.46, 0.15, 0.95), 2))
	scene.character_hud_root.add_child(scene.stability_hud_root)

	scene.stability_bar = ProgressBar.new()
	scene.stability_bar.name = "StabilityBar"
	scene.stability_bar.position = Vector2(26, 24)
	scene.stability_bar.size = Vector2(376, 20)
	scene.stability_bar.min_value = 0.0
	scene.stability_bar.max_value = STABILITY_MAX
	scene.stability_bar.value = STABILITY_MAX
	scene.stability_bar.show_percentage = false
	scene.stability_hud_root.add_child(scene.stability_bar)

	scene.stability_value_label = Label.new()
	scene.stability_value_label.name = "StabilityValue"
	scene.stability_value_label.position = Vector2(26, 0)
	scene.stability_value_label.size = Vector2(210, 22)
	scene.stability_value_label.add_theme_font_size_override("font_size", 15)
	scene.stability_value_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.76))
	scene.stability_hud_root.add_child(scene.stability_value_label)

	scene.stability_stage_label = Label.new()
	scene.stability_stage_label.name = "StabilityStage"
	scene.stability_stage_label.position = Vector2(260, 0)
	scene.stability_stage_label.size = Vector2(142, 22)
	scene.stability_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scene.stability_stage_label.add_theme_font_size_override("font_size", 14)
	scene.stability_stage_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	scene.stability_hud_root.add_child(scene.stability_stage_label)

	for tick in STABILITY_TICKS:
		var x := 26.0 + 376.0 * float(tick.ratio)
		var line := ColorRect.new()
		line.name = "Tick_%s" % tick.label
		line.position = Vector2(x - 1.0, 20.0)
		line.size = Vector2(2.0, 30.0)
		line.color = Color(0.9, 0.86, 0.78, 0.72)
		scene.stability_hud_root.add_child(line)

		var label := Label.new()
		label.text = String(tick.label)
		label.position = Vector2(x - 18.0, 48.0)
		label.size = Vector2(36.0, 20.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))
		scene.stability_hud_root.add_child(label)

	scene.portrait_frame = Panel.new()
	scene.portrait_frame.name = "PortraitFrame"
	scene.portrait_frame.position = Vector2(0, 0)
	scene.portrait_frame.size = Vector2(124, 132)
	scene.portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.10, 0.095, 0.09, 0.96), Color(0.72, 0.08, 0.08, 1.0), 2))
	scene.character_hud_root.add_child(scene.portrait_frame)

	var portrait_placeholder := Label.new()
	portrait_placeholder.name = "PortraitPlaceholder"
	portrait_placeholder.text = "头像"
	portrait_placeholder.position = Vector2(14, 14)
	portrait_placeholder.size = Vector2(96, 104)
	portrait_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_placeholder.add_theme_font_size_override("font_size", 18)
	portrait_placeholder.add_theme_color_override("font_color", Color(0.55, 0.54, 0.5))
	scene.portrait_frame.add_child(portrait_placeholder)

func _build_center_status_hud(scene) -> void:
	scene.center_hud_root = Control.new()
	scene.center_hud_root.name = "CenterStatusHUD"
	scene.center_hud_root.anchor_left = 0.5
	scene.center_hud_root.anchor_right = 0.5
	scene.center_hud_root.offset_left = -190.0
	scene.center_hud_root.offset_top = 10.0
	scene.center_hud_root.offset_right = 190.0
	scene.center_hud_root.offset_bottom = 104.0
	scene.ui_root.add_child(scene.center_hud_root)

	scene.countdown_panel = Panel.new()
	scene.countdown_panel.name = "CountdownPanel"
	scene.countdown_panel.position = Vector2(0, 0)
	scene.countdown_panel.size = Vector2(380, 62)
	scene.countdown_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.055, 0.9), Color(0.15, 0.21, 0.72, 0.9), 2))
	scene.center_hud_root.add_child(scene.countdown_panel)

	scene.countdown_label = Label.new()
	scene.countdown_label.name = "CountdownLabel"
	scene.countdown_label.position = Vector2(0, 3)
	scene.countdown_label.size = Vector2(380, 56)
	scene.countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.countdown_label.add_theme_font_size_override("font_size", 38)
	scene.countdown_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76))
	scene.countdown_panel.add_child(scene.countdown_label)

	scene.extraction_status_panel = Panel.new()
	scene.extraction_status_panel.name = "ExtractionStatusPanel"
	scene.extraction_status_panel.position = Vector2(35, 66)
	scene.extraction_status_panel.size = Vector2(310, 34)
	scene.extraction_status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.052, 0.86), Color(0.08, 0.48, 0.20, 0.72), 1))
	scene.center_hud_root.add_child(scene.extraction_status_panel)

	scene.extraction_status_dot = Panel.new()
	scene.extraction_status_dot.name = "ExtractionStatusDot"
	scene.extraction_status_dot.position = Vector2(20, 11)
	scene.extraction_status_dot.size = Vector2(12, 12)
	scene.extraction_status_dot.add_theme_stylebox_override("panel", _dot_style(Color(0.34, 0.34, 0.33, 1.0)))
	scene.extraction_status_panel.add_child(scene.extraction_status_dot)

	scene.extraction_status_label = Label.new()
	scene.extraction_status_label.name = "ExtractionStatusLabel"
	scene.extraction_status_label.position = Vector2(46, 4)
	scene.extraction_status_label.size = Vector2(240, 26)
	scene.extraction_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.extraction_status_label.add_theme_font_size_override("font_size", 17)
	scene.extraction_status_panel.add_child(scene.extraction_status_label)

func _build_outpost_status_hud(scene) -> void:
	scene.outpost_hud_root = Panel.new()
	scene.outpost_hud_root.name = "OutpostRepairHUD"
	scene.outpost_hud_root.position = Vector2(18, 214)
	scene.outpost_hud_root.size = Vector2(166, 184)
	scene.outpost_hud_root.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.052, 0.046, 0.88), Color(0.92, 0.74, 0.18, 0.96), 2))
	scene.ui_root.add_child(scene.outpost_hud_root)

	scene.outpost_count_label = Label.new()
	scene.outpost_count_label.name = "OutpostCount"
	scene.outpost_count_label.position = Vector2(18, 16)
	scene.outpost_count_label.size = Vector2(130, 28)
	scene.outpost_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.outpost_count_label.add_theme_font_size_override("font_size", 20)
	scene.outpost_count_label.add_theme_color_override("font_color", Color(0.84, 0.80, 0.70))
	scene.outpost_hud_root.add_child(scene.outpost_count_label)

	scene.outpost_first_icon = _make_outpost_icon("I")
	scene.outpost_first_icon.position = Vector2(20, 66)
	scene.outpost_hud_root.add_child(scene.outpost_first_icon)

	scene.outpost_first_status_label = _make_outpost_status_label("OutpostOneStatus", Vector2(64, 58))
	scene.outpost_hud_root.add_child(scene.outpost_first_status_label)

	scene.outpost_first_progress_bar = _make_outpost_progress_bar(Vector2(64, 90))
	scene.outpost_hud_root.add_child(scene.outpost_first_progress_bar)

	scene.outpost_second_icon = _make_outpost_icon("II")
	scene.outpost_second_icon.position = Vector2(20, 136)
	scene.outpost_hud_root.add_child(scene.outpost_second_icon)

	scene.outpost_second_status_label = _make_outpost_status_label("OutpostTwoStatus", Vector2(64, 128))
	scene.outpost_hud_root.add_child(scene.outpost_second_status_label)

	scene.outpost_second_progress_bar = _make_outpost_progress_bar(Vector2(64, 160))
	scene.outpost_hud_root.add_child(scene.outpost_second_progress_bar)

func _build_backpack_status_hud(scene) -> void:
	scene.backpack_hud_root = Panel.new()
	scene.backpack_hud_root.name = "BackpackStatusHUD"
	scene.backpack_hud_root.anchor_left = 1.0
	scene.backpack_hud_root.anchor_right = 1.0
	scene.backpack_hud_root.anchor_top = 1.0
	scene.backpack_hud_root.anchor_bottom = 1.0
	scene.backpack_hud_root.offset_left = -362.0
	scene.backpack_hud_root.offset_top = -128.0
	scene.backpack_hud_root.offset_right = -18.0
	scene.backpack_hud_root.offset_bottom = -18.0
	scene.backpack_hud_root.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.055, 0.9), Color(0.07, 0.42, 0.72, 0.92), 2))
	scene.ui_root.add_child(scene.backpack_hud_root)

	scene.backpack_icon_placeholder = Panel.new()
	scene.backpack_icon_placeholder.name = "BackpackIcon"
	scene.backpack_icon_placeholder.position = Vector2(16, 18)
	scene.backpack_icon_placeholder.size = Vector2(70, 70)
	scene.backpack_icon_placeholder.add_theme_stylebox_override("panel", _panel_style(Color(0.10, 0.095, 0.09, 0.94), Color(0.38, 0.38, 0.36, 0.9), 1))
	scene.backpack_hud_root.add_child(scene.backpack_icon_placeholder)

	var icon_label := Label.new()
	icon_label.text = "包"
	icon_label.position = Vector2(0, 0)
	icon_label.size = Vector2(70, 70)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.add_theme_color_override("font_color", Color(0.62, 0.60, 0.56))
	scene.backpack_icon_placeholder.add_child(icon_label)

	scene.backpack_slot_label = Label.new()
	scene.backpack_slot_label.name = "BackpackSlots"
	scene.backpack_slot_label.position = Vector2(106, 16)
	scene.backpack_slot_label.size = Vector2(210, 28)
	scene.backpack_slot_label.add_theme_font_size_override("font_size", 20)
	scene.backpack_slot_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76))
	scene.backpack_hud_root.add_child(scene.backpack_slot_label)

	scene.weight_bar = ProgressBar.new()
	scene.weight_bar.name = "WeightBar"
	scene.weight_bar.position = Vector2(106, 58)
	scene.weight_bar.size = Vector2(210, 20)
	scene.weight_bar.min_value = 0.0
	scene.weight_bar.max_value = 20.0
	scene.weight_bar.value = 0.0
	scene.weight_bar.show_percentage = false
	scene.weight_bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.02, 0.018, 0.92), Color(0.28, 0.28, 0.27), 1))
	scene.weight_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.42, 0.28, 0.72, 0.95), Color(0.42, 0.28, 0.72), 0))
	scene.backpack_hud_root.add_child(scene.weight_bar)

	scene.weight_value_label = Label.new()
	scene.weight_value_label.name = "WeightValue"
	scene.weight_value_label.position = Vector2(106, 78)
	scene.weight_value_label.size = Vector2(210, 22)
	scene.weight_value_label.add_theme_font_size_override("font_size", 15)
	scene.weight_value_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76))
	scene.backpack_hud_root.add_child(scene.weight_value_label)

func _build_context_prompt(scene) -> void:
	scene.hud_label = Label.new()
	scene.hud_label.name = "LegacyHUDLabel"
	scene.hud_label.visible = false
	scene.ui_root.add_child(scene.hud_label)

	scene.prompt_label = Label.new()
	scene.prompt_label.name = "PromptLabel"
	scene.prompt_label.anchor_left = 0.5
	scene.prompt_label.anchor_right = 0.5
	scene.prompt_label.anchor_top = 1.0
	scene.prompt_label.anchor_bottom = 1.0
	scene.prompt_label.offset_left = -330.0
	scene.prompt_label.offset_top = -72.0
	scene.prompt_label.offset_right = 330.0
	scene.prompt_label.offset_bottom = -28.0
	scene.prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.prompt_label.add_theme_font_size_override("font_size", 18)
	scene.prompt_label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.76))
	scene.ui_root.add_child(scene.prompt_label)

func _build_hidden_action_buttons(scene) -> void:
	scene.backpack_button = Button.new()
	scene.backpack_button.name = "BackpackButton"
	scene.backpack_button.text = "背包"
	scene.backpack_button.visible = false
	scene.backpack_button.pressed.connect(scene._toggle_inventory_panel)
	scene.ui_root.add_child(scene.backpack_button)

	scene.extract_hud_button = Button.new()
	scene.extract_hud_button.name = "ExtractHUDButton"
	scene.extract_hud_button.text = "撤离未解锁"
	scene.extract_hud_button.visible = false
	scene.extract_hud_button.button_down.connect(scene._begin_extraction_hold_from_button)
	scene.extract_hud_button.button_up.connect(scene._release_extraction_hold_button)
	scene.ui_root.add_child(scene.extract_hud_button)

func _build_inventory_panels(scene) -> void:
	scene.inventory_panel = _make_panel(Vector2(16, 154), Vector2(390, 360), "背包")
	scene.inventory_label = _make_item_list(Vector2(16, 52), Vector2(358, 288))
	scene.inventory_label.meta_clicked.connect(scene._on_inventory_item_meta_clicked)
	scene.inventory_panel.add_child(scene.inventory_label)
	scene.ui_root.add_child(scene.inventory_panel)
	scene.inventory_panel.visible = false

	scene.home_storage_panel = _make_panel(Vector2(422, 154), Vector2(390, 360), "家中存储")
	scene.home_storage_label = _make_item_list(Vector2(16, 52), Vector2(358, 230))
	scene.home_storage_label.meta_clicked.connect(scene._on_home_storage_item_meta_clicked)
	scene.home_storage_panel.add_child(scene.home_storage_label)
	scene.deposit_button = Button.new()
	scene.deposit_button.text = "存入家中"
	scene.deposit_button.position = Vector2(16, 300)
	scene.deposit_button.size = Vector2(172, 40)
	scene.deposit_button.pressed.connect(scene._deposit_all)
	scene.home_storage_panel.add_child(scene.deposit_button)
	scene.extract_button = Button.new()
	scene.extract_button.text = "撤离"
	scene.extract_button.position = Vector2(202, 300)
	scene.extract_button.size = Vector2(172, 40)
	scene.extract_button.button_down.connect(scene._begin_extraction_hold_from_button)
	scene.extract_button.button_up.connect(scene._release_extraction_hold_button)
	scene.home_storage_panel.add_child(scene.extract_button)
	scene.ui_root.add_child(scene.home_storage_panel)
	scene.home_storage_panel.visible = false

	scene.loot_panel = _make_panel(Vector2(422, 154), Vector2(390, 300), "容器 / 材料")
	scene.loot_label = _make_item_list(Vector2(16, 52), Vector2(358, 170))
	scene.loot_label.meta_clicked.connect(scene._on_loot_item_meta_clicked)
	scene.loot_panel.add_child(scene.loot_label)
	scene.take_all_button = Button.new()
	scene.take_all_button.text = "全部拾取"
	scene.take_all_button.position = Vector2(16, 240)
	scene.take_all_button.size = Vector2(172, 40)
	scene.take_all_button.pressed.connect(scene._take_all_loot)
	scene.loot_panel.add_child(scene.take_all_button)
	scene.ui_root.add_child(scene.loot_panel)
	scene.loot_panel.visible = false

func _refresh_stability_hud(scene) -> void:
	if scene.stability_bar == null:
		return
	var max_value: float = maxf(1.0, float(scene.run_director.config.max_stability))
	var current: float = clampf(float(scene.run_director.context.player_stability), 0.0, max_value)
	var ratio: float = current / max_value
	scene.stability_bar.max_value = max_value
	scene.stability_bar.value = current
	scene.stability_value_label.text = "稳定值  %d/%d" % [int(round(current)), int(round(max_value))]
	scene.stability_stage_label.text = _stability_stage_text(ratio)
	scene.stability_bar.add_theme_stylebox_override("background", _progress_style(Color(0.025, 0.024, 0.022, 0.92), Color(0.42, 0.40, 0.36), 1))
	scene.stability_bar.add_theme_stylebox_override("fill", _progress_style(_stability_fill_color(ratio), _stability_fill_color(ratio), 0))

func _refresh_countdown(scene) -> void:
	if scene.countdown_label == null:
		return
	var remaining: float = maxf(0.0, float(scene.run_director.context.remaining_seconds))
	scene.countdown_label.text = _format_countdown(remaining)
	var text_color := Color(0.82, 0.80, 0.76)
	if remaining <= 30.0:
		text_color = Color(0.72, 0.42, 0.42)
	scene.countdown_label.add_theme_color_override("font_color", text_color)

func _refresh_extraction_status(scene) -> void:
	var can_extract: bool = scene.run_director.context.is_extraction_unlocked
	var active_color := Color(0.05, 0.36, 0.16, 1.0)
	var inactive_color := Color(0.34, 0.34, 0.33, 1.0)
	_set_dot_color(scene.extraction_status_dot, active_color if can_extract else inactive_color)
	scene.extraction_status_label.text = "可返回家中撤离" if can_extract else "不可撤离"
	scene.extraction_status_label.add_theme_color_override("font_color", active_color if can_extract else inactive_color)

func _refresh_outpost_status_hud(scene) -> void:
	if scene.outpost_hud_root == null:
		return
	var context = scene.run_director.context
	var first_id: String = String(context.selected_first_outpost_id)
	var second_id: String = String(context.selected_second_outpost_id)
	var repaired_count: int = int(context.repaired_outpost_count)
	var total_count := 2
	scene.outpost_count_label.text = "前哨  %d/%d" % [repaired_count, total_count]
	_refresh_outpost_row(scene, first_id, scene.outpost_first_status_label, scene.outpost_first_progress_bar)
	_refresh_outpost_row(scene, second_id, scene.outpost_second_status_label, scene.outpost_second_progress_bar)

func _refresh_outpost_row(scene, outpost_id: String, status_label: Label, progress_bar: ProgressBar) -> void:
	var status := _get_outpost_repair_status(scene, outpost_id)
	var state: String = String(status.get("state", "missing"))
	var progress: float = clampf(float(status.get("progress", 0.0)), 0.0, 1.0)
	match state:
		"repaired":
			status_label.text = "修复完成"
			status_label.add_theme_color_override("font_color", Color(0.12, 0.52, 0.22))
			progress_bar.value = 1.0
			progress_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.12, 0.52, 0.22, 0.96), Color(0.12, 0.52, 0.22), 0))
		"repairing":
			status_label.text = "修复中  %d%%" % int(round(progress * 100.0))
			status_label.add_theme_color_override("font_color", Color(0.82, 0.62, 0.32))
			progress_bar.value = progress
			progress_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.82, 0.32, 0.32, 0.96), Color(0.82, 0.32, 0.32), 0))
		"partial", "repairable":
			status_label.text = "材料 %d%%" % int(round(progress * 100.0))
			status_label.add_theme_color_override("font_color", Color(0.82, 0.62, 0.32))
			progress_bar.value = progress
			progress_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.82, 0.62, 0.32, 0.96), Color(0.82, 0.62, 0.32), 0))
		_:
			status_label.text = "未修复"
			status_label.add_theme_color_override("font_color", Color(0.50, 0.49, 0.47))
			progress_bar.value = 0.0
			progress_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.32, 0.31, 0.30, 0.72), Color(0.32, 0.31, 0.30), 0))

func _get_outpost_repair_status(scene, outpost_id: String) -> Dictionary:
	var station = _find_outpost_station(scene, outpost_id)
	if station == null:
		return {"state": "missing", "progress": 0.0}
	var payload: Dictionary = station.get("payload")
	if bool(payload.get("repaired", false)):
		return {"state": "repaired", "progress": 1.0}
	var material_progress := _outpost_material_progress(payload)
	if scene.interaction_progress_controller != null and scene.interaction_progress_controller.is_active():
		if scene.interaction_progress_controller.active_id == "repair_outpost" and scene.interaction_progress_controller.is_target(station):
			return {"state": "repairing", "progress": scene.interaction_progress_controller.get_progress()}
	if String(payload.get("repair_state", "UNREPAIRED")) == "REPAIRING":
		return {"state": "repairing", "progress": material_progress}
	if material_progress > 0.0:
		return {"state": "partial", "progress": material_progress}
	if String(payload.get("repair_state", "UNREPAIRED")) == "REPAIRABLE":
		return {"state": "repairable", "progress": material_progress}
	return {"state": "unrepaired", "progress": 0.0}

func _outpost_material_progress(payload: Dictionary) -> float:
	var requirements: Dictionary = payload.get("requirements", {})
	var delivered: Dictionary = payload.get("delivered_materials", {})
	var total_required := 0
	var total_delivered := 0
	for item_id in requirements.keys():
		var required := int(requirements[item_id].get("amount", 0))
		total_required += required
		total_delivered += mini(int(delivered.get(str(item_id), 0)), required)
	if total_required <= 0:
		return 0.0
	return clampf(float(total_delivered) / float(total_required), 0.0, 1.0)

func _find_outpost_station(scene, outpost_id: String):
	if scene.outpost_root == null:
		return null
	for child in scene.outpost_root.get_children():
		if not is_instance_valid(child):
			continue
		if child.get("interact_type") == "outpost" and String(child.get("interact_id")) == outpost_id:
			return child
	return null

func _refresh_backpack_status(scene) -> void:
	var used_slots := 0
	var max_slots := 0
	if scene.run_director.inventory_component != null:
		used_slots = scene.run_director.inventory_component.items.size()
		max_slots = scene.run_director.inventory_component.max_slots
	else:
		used_slots = scene.run_director.context.player_inventory.size()
		max_slots = scene.run_director.config.inventory_slots
	var current_weight: float = maxf(0.0, float(scene.run_director.context.current_weight))
	var max_weight: float = maxf(1.0, float(scene.run_director.context.weight_limit))
	scene.backpack_slot_label.text = "背包格  %d/%d" % [used_slots, max_slots]
	scene.weight_bar.max_value = max_weight
	scene.weight_bar.value = minf(current_weight, max_weight)
	scene.weight_value_label.text = "负重: %.1f/%.1f" % [current_weight, max_weight]
	var fill_color := Color(0.43, 0.31, 0.72, 0.96)
	if current_weight >= max_weight:
		fill_color = Color(0.62, 0.12, 0.15, 0.96)
	elif current_weight >= max_weight * 0.75:
		fill_color = Color(0.66, 0.48, 0.15, 0.96)
	scene.weight_bar.add_theme_stylebox_override("fill", _progress_style(fill_color, fill_color, 0))

func _refresh_prompt(scene) -> void:
	var is_home_safe_zone: bool = scene.run_director.context.active_safe_zone_id == "home"
	var extraction_ready_at_home: bool = scene.run_director.context.is_extraction_unlocked and is_home_safe_zone
	if scene.interaction_progress_controller != null and scene.interaction_progress_controller.is_active():
		var progress_percent: int = int(round(scene.interaction_progress_controller.get_progress() * 100.0))
		scene.prompt_label.text = "%s中：%s%%" % [
			_interaction_progress_text(scene.interaction_progress_controller.active_id),
			progress_percent,
		]
	elif extraction_ready_at_home:
		scene.prompt_label.text = "撤离已准备：按住 E 撤离"
	elif not scene._status_prompt.is_empty():
		scene.prompt_label.text = scene._status_prompt
	elif scene.nearest_interactable:
		scene.prompt_label.text = "%s  %s" % [
			_interact_prompt_prefix(scene.nearest_interactable.interact_type),
			scene.nearest_interactable.display_name,
		]
	else:
		scene.prompt_label.text = ""

func _format_countdown(seconds: float) -> String:
	var total_seconds: int = int(ceil(maxf(0.0, seconds)))
	var minutes: int = floori(float(total_seconds) / 60.0)
	var secs: int = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]

func toggle_inventory(scene) -> void:
	var is_storage_zone: bool = scene.run_director.context != null and scene.is_storage_zone_active()
	if is_storage_zone:
		if scene.inventory_panel.visible or scene.home_storage_panel.visible:
			scene.home_storage_user_closed = true
			scene.inventory_panel.visible = false
			scene.home_storage_panel.visible = false
		else:
			scene.home_storage_user_closed = false
			scene.inventory_panel.visible = true
			scene.home_storage_panel.visible = true
	else:
		scene.inventory_panel.visible = not scene.inventory_panel.visible
	refresh(scene)

func _make_panel(pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 60
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	var label := Label.new()
	label.name = "TitleLabel"
	label.text = title
	label.position = Vector2(16, 12)
	label.size = Vector2(panel_size.x - 32.0, 28.0)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.76))
	panel.add_child(label)
	return panel

func _make_item_list(pos: Vector2, item_list_size: Vector2) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.position = pos
	label.size = item_list_size
	label.bbcode_enabled = true
	label.fit_content = false
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", 16)
	label.meta_underlined = false
	return label

func _sync_storage_ui(scene, is_storage_zone: bool) -> void:
	if not is_storage_zone:
		scene.home_storage_user_closed = false
		scene.home_storage_panel.visible = false
		if not scene.loot_panel.visible:
			scene.inventory_panel.visible = false
		return
	if scene.home_storage_user_closed:
		scene.home_storage_panel.visible = false
		return
	scene.inventory_panel.visible = true
	scene.home_storage_panel.visible = true

func _set_panel_title(panel: Panel, title: String) -> void:
	if panel == null:
		return
	var label := panel.get_node_or_null("TitleLabel") as Label
	if label != null:
		label.text = title

func _set_items_text(label: RichTextLabel, items: Array, source_id: String = "") -> void:
	label.clear()
	if items.is_empty():
		label.append_text("空")
		return
	var lines: Array[String] = []
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			lines.append(_item_line(item, index, source_id))
	label.append_text("\n".join(lines))

func _item_line(item: Dictionary, index: int = -1, source_id: String = "") -> String:
	var quality := String(item.get("quality", "C"))
	var color := _quality_color_hex(item)
	var name := String(item.get("display_name", item.get("item_id", "")))
	var amount := int(item.get("amount", 0))
	var weight := float(item.get("weight_per_unit", 0.0))
	var text := "[color=#%s][%s] %s[/color]  x%s  单重 %.2f" % [color, quality, name, amount, weight]
	if source_id.is_empty() or index < 0:
		return text
	return "[url=%s:%d]%s[/url]" % [source_id, index, text]

func _quality_color_hex(item: Dictionary) -> String:
	var value = item.get("quality_color", Color.WHITE)
	if value is Color:
		return value.to_html(false)
	return "FFFFFF"

func _interaction_progress_text(interaction_id: String) -> String:
	match interaction_id:
		"open_container":
			return "开箱"
		"repair_outpost":
			return "修复"
		"extract":
			return "撤离"
		_:
			return "交互"

func _interact_prompt_prefix(interact_type: String) -> String:
	match interact_type:
		"container":
			return "按住 F"
		"outpost":
			return "按住 F"
		_:
			return "按 F"

func _make_outpost_icon(text: String) -> Panel:
	var icon := Panel.new()
	icon.size = Vector2(34, 34)
	icon.add_theme_stylebox_override("panel", _panel_style(Color(0.10, 0.095, 0.085, 0.92), Color(0.40, 0.36, 0.28, 0.92), 1))
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, 0)
	label.size = icon.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	icon.add_child(label)
	return icon

func _make_outpost_status_label(node_name: String, pos: Vector2) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.size = Vector2(86, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	return label

func _make_outpost_progress_bar(pos: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(78, 9)
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.02, 0.018, 0.92), Color(0.28, 0.27, 0.25), 1))
	bar.add_theme_stylebox_override("fill", _progress_style(Color(0.32, 0.31, 0.30, 0.72), Color(0.32, 0.31, 0.30), 0))
	return bar

func _set_dot_color(dot: Panel, color: Color) -> void:
	if dot == null:
		return
	dot.add_theme_stylebox_override("panel", _dot_style(color))

func _stability_fill_color(ratio: float) -> Color:
	if ratio <= 0.15:
		return Color(0.48, 0.05, 0.08, 0.96)
	if ratio <= 0.35:
		return Color(0.70, 0.18, 0.22, 0.96)
	if ratio <= 0.60:
		return Color(0.58, 0.27, 0.30, 0.96)
	return Color(0.68, 0.30, 0.30, 0.96)

func _stability_stage_text(ratio: float) -> String:
	if ratio <= 0.15:
		return "CRITICAL"
	if ratio <= 0.35:
		return "DANGER"
	if ratio <= 0.60:
		return "UNSTEADY"
	return "STABLE"

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

func _progress_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	return style

func _dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	return style

class_name RunUiController
extends RefCounted

const CHARACTER_HUD_PORTRAIT_FRAME := preload("res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_frame_empty_ref_01.png")
const CHARACTER_HUD_DEFAULT_PORTRAIT := preload("res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_male_01.png")
const CHARACTER_HUD_STABILITY_FRAME := preload("res://assets/ui/run_character_hud/character_status/components/ui_run_character_stability_bar_frame_empty_ref_01.png")
const CHARACTER_HUD_STABILITY_FILL := preload("res://assets/ui/run_character_hud/character_status/components/ui_run_character_stability_fill_strip_current_ref_01.png")
const RunMinimapScript := preload("res://scripts/run/run_minimap.gd")
const TIMER_COUNTDOWN_FRAME := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_timer_countdown_frame_empty_01.png")
const EXTRACTION_STATUS_FRAME_LEFT := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_extraction_status_frame_left_01.png")
const EXTRACTION_STATUS_FRAME_CENTER := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_extraction_status_frame_center_tile_01.png")
const EXTRACTION_STATUS_FRAME_RIGHT := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_extraction_status_frame_right_01.png")
const EXTRACTION_STATUS_DOT_UNAVAILABLE := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_extraction_status_dot_unavailable_01.png")
const EXTRACTION_STATUS_DOT_AVAILABLE := preload("res://assets/ui/run_timer_extraction_hud/components/ui_run_extraction_status_dot_available_01.png")
const BACKPACK_STATUS_ICON := preload("res://assets/ui/itemicon/backpack_small_reinforced.png")
const STABILITY_FILL_OFFSET := Vector2(22, 19)
const STABILITY_FILL_SIZE := Vector2(361, 35)
const EXTRACTION_STATUS_WIDTH := 298.0
const INVENTORY_GRID_COLUMNS := 5
const INVENTORY_GRID_SLOT_SIZE := 62.0
const INVENTORY_GRID_SLOT_GAP := 10.0
const INVENTORY_BACKPACK_DISPLAY_SLOTS := 30
const MATERIAL_BACKPACK_DISPLAY_SLOTS := 5
const ITEM_GRID_SIGNATURE_META := "item_grid_signature"
const INVENTORY_PANEL_TOP := 128.0
const INVENTORY_PANEL_RIGHT_MARGIN := 20.0
const INVENTORY_PANEL_SIZE := Vector2(460.0, 760.0)
const INVENTORY_SECONDARY_PANEL_RIGHT_MARGIN := 498.0
const INVENTORY_STORAGE_PANEL_SIZE := Vector2(430.0, 360.0)
const INVENTORY_LOOT_PANEL_SIZE := Vector2(430.0, 336.0)
const INVENTORY_LOOT_PANEL_TOP := 252.0
const PORTRAIT_SIZE := Vector2(168.0, 184.0)
const OBJECTIVE_HUD_POSITION := Vector2(2.0, 242.0)
const OBJECTIVE_HUD_SIZE := Vector2(430.0, 170.0)
const OBJECTIVE_HUD_HOME_ALPHA := 1.0
const OBJECTIVE_HUD_FIELD_ALPHA := 0.58
const INVENTORY_PANEL_OPEN_SECONDS := 0.18
const LOW_STABILITY_WARNING_THRESHOLD := 30.0
const LOW_STABILITY_WARNING_MAX_ALPHA := 0.62
const LOW_STABILITY_WARNING_NEAR_EDGE_WIDTH := 0.034
const LOW_STABILITY_WARNING_NEAR_FADE_WIDTH := 0.22
const LOW_STABILITY_WARNING_CRITICAL_EDGE_WIDTH := 0.013
const LOW_STABILITY_WARNING_CRITICAL_FADE_WIDTH := 0.09
const LOW_STABILITY_WARNING_PULSE_SPEED := 3.4
const LOW_STABILITY_WARNING_PULSE_FLOOR := 0.42

func build(scene) -> void:
	_build_character_status_hud(scene)
	_build_outpost_status_hud(scene)
	_build_minimap(scene)
	_build_center_status_hud(scene)
	_build_backpack_status_hud(scene)
	_build_context_prompt(scene)
	_build_hidden_action_buttons(scene)
	_build_inventory_panels(scene)
	_build_low_stability_warning_overlay(scene)

func refresh(scene) -> void:
	if scene.run_director.context == null:
		return
	_refresh_stability_hud(scene)
	_refresh_countdown(scene)
	_refresh_outpost_status_hud(scene)
	_refresh_minimap(scene)
	_refresh_backpack_status(scene)
	_refresh_prompt(scene)
	var story_paused: bool = scene.has_method("is_run_story_paused") and bool(scene.is_run_story_paused())
	var is_home_safe_zone: bool = scene.is_home_storage_active()
	var is_storage_zone: bool = scene.is_storage_zone_active()
	_set_panel_title(scene.home_storage_panel, scene.get_active_storage_title())
	_sync_storage_ui(scene, is_storage_zone)
	var extraction_ready_at_home: bool = scene.run_director.context.is_extraction_unlocked and is_home_safe_zone
	scene.deposit_button.disabled = story_paused or not is_storage_zone
	scene.deposit_button.text = "存入前哨" if scene._is_active_outpost_storage() else "存入家中"
	scene.extract_button.disabled = story_paused or not extraction_ready_at_home
	scene.extract_button.visible = false
	scene.extract_hud_button.disabled = story_paused or not extraction_ready_at_home
	scene.extract_hud_button.text = "撤离(E)" if extraction_ready_at_home else ("返回家中" if scene.run_director.context.is_extraction_unlocked else "撤离未解锁")
	scene.extraction_status_button.disabled = story_paused or not extraction_ready_at_home
	_refresh_extraction_status(scene)
	_layout_inventory_surfaces(scene, is_storage_zone, scene.loot_panel.visible)
	_refresh_inventory_actions(scene)
	if scene.inventory_panel.visible:
		_set_items_grid(scene, scene.inventory_label, scene.run_director.inventory_component.get_items_snapshot(), "inventory", scene.run_director.inventory_component.max_slots)
		_set_items_grid(scene, scene.material_inventory_label, _material_items_snapshot(scene), "inventory_material", _material_capacity(scene))
	if scene.home_storage_panel.visible:
		_set_items_grid(scene, scene.home_storage_label, scene.get_active_storage_items_snapshot(), scene.get_active_storage_source_id(), _active_storage_capacity(scene))
	if scene.loot_panel.visible:
		_set_items_grid(scene, scene.loot_label, scene.opened_loot, "loot", maxi(scene.opened_loot.size(), 8))

func outpost_material_pickup_prompt(scene, outpost_id: String = "") -> String:
	var target_id := outpost_id if not outpost_id.is_empty() else _objective_target_outpost_id(scene)
	var counts := _objective_material_counts(scene, target_id)
	var required := int(counts.get("required", 0))
	if required <= 0:
		return "前哨材料已获得"
	return "前哨材料已获得 %d/%d" % [int(counts.get("covered", 0)), required]

func _build_character_status_hud(scene) -> void:
	scene.character_hud_root = Control.new()
	scene.character_hud_root.name = "CharacterStatusHUD"
	scene.character_hud_root.position = Vector2(18, 14)
	scene.character_hud_root.size = Vector2(590, 200)
	scene.ui_root.add_child(scene.character_hud_root)

	scene.stability_hud_root = Control.new()
	scene.stability_hud_root.name = "StabilityPanel"
	scene.stability_hud_root.position = Vector2(150, 38)
	scene.stability_hud_root.size = Vector2(405, 100)
	scene.character_hud_root.add_child(scene.stability_hud_root)

	scene.stability_bar = Control.new()
	scene.stability_bar.name = "StabilityBar"
	scene.stability_bar.position = Vector2.ZERO
	scene.stability_bar.size = Vector2(405, 100)
	scene.stability_hud_root.add_child(scene.stability_bar)

	scene.stability_frame_texture = TextureRect.new()
	scene.stability_frame_texture.name = "StabilityFrame"
	scene.stability_frame_texture.texture = CHARACTER_HUD_STABILITY_FRAME
	scene.stability_frame_texture.position = Vector2.ZERO
	scene.stability_frame_texture.size = Vector2(405, 100)
	scene.stability_frame_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.stability_frame_texture.stretch_mode = TextureRect.STRETCH_SCALE
	scene.stability_bar.add_child(scene.stability_frame_texture)

	scene.stability_fill_clip = Control.new()
	scene.stability_fill_clip.name = "StabilityFillClip"
	scene.stability_fill_clip.position = STABILITY_FILL_OFFSET
	scene.stability_fill_clip.size = STABILITY_FILL_SIZE
	scene.stability_fill_clip.clip_contents = true
	scene.stability_bar.add_child(scene.stability_fill_clip)

	scene.stability_fill_texture = TextureRect.new()
	scene.stability_fill_texture.name = "StabilityFill"
	scene.stability_fill_texture.texture = CHARACTER_HUD_STABILITY_FILL
	scene.stability_fill_texture.position = Vector2.ZERO
	scene.stability_fill_texture.size = STABILITY_FILL_SIZE
	scene.stability_fill_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.stability_fill_texture.stretch_mode = TextureRect.STRETCH_SCALE
	scene.stability_fill_clip.add_child(scene.stability_fill_texture)

	scene.stability_value_label = Label.new()
	scene.stability_value_label.name = "StabilityValue"
	scene.stability_value_label.position = STABILITY_FILL_OFFSET
	scene.stability_value_label.size = STABILITY_FILL_SIZE
	scene.stability_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.stability_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.stability_value_label.add_theme_font_size_override("font_size", 18)
	scene.stability_value_label.add_theme_color_override("font_color", Color("#F1EBDD"))
	scene.stability_value_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	scene.stability_value_label.add_theme_constant_override("shadow_offset_x", 1)
	scene.stability_value_label.add_theme_constant_override("shadow_offset_y", 1)
	scene.stability_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.stability_value_label.z_index = 6
	scene.stability_bar.add_child(scene.stability_value_label)

	scene.stability_stage_label = Label.new()
	scene.stability_stage_label.name = "StabilityStage"
	scene.stability_stage_label.visible = false
	scene.stability_hud_root.add_child(scene.stability_stage_label)

	var character_assets := _selected_character_hud_assets()
	scene.portrait_image = TextureRect.new()
	scene.portrait_image.name = "PortraitImage"
	scene.portrait_image.position = Vector2.ZERO
	scene.portrait_image.size = PORTRAIT_SIZE
	scene.portrait_image.texture = _load_texture_or_default(String(character_assets.get("portrait_path", "")), CHARACTER_HUD_DEFAULT_PORTRAIT)
	scene.portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.portrait_image.stretch_mode = TextureRect.STRETCH_SCALE
	scene.portrait_image.z_index = 4
	scene.character_hud_root.add_child(scene.portrait_image)

	scene.portrait_frame = TextureRect.new()
	scene.portrait_frame.name = "PortraitFrame"
	scene.portrait_frame.position = Vector2(0, 0)
	scene.portrait_frame.size = PORTRAIT_SIZE
	scene.portrait_frame.texture = _load_texture_or_default(String(character_assets.get("portrait_frame_path", "")), CHARACTER_HUD_PORTRAIT_FRAME)
	scene.portrait_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.portrait_frame.stretch_mode = TextureRect.STRETCH_SCALE
	scene.portrait_frame.z_index = 5
	scene.character_hud_root.add_child(scene.portrait_frame)

func _selected_character_hud_assets() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var game_state := tree.root.get_node_or_null("GameState")
		if game_state != null and game_state.has_method("get_selected_character_hud_assets"):
			return game_state.get_selected_character_hud_assets()
	return {
		"portrait_path": CHARACTER_HUD_DEFAULT_PORTRAIT.resource_path,
		"portrait_frame_path": CHARACTER_HUD_PORTRAIT_FRAME.resource_path,
	}

func _load_texture_or_default(path: String, default_texture: Texture2D) -> Texture2D:
	if path.is_empty():
		return default_texture
	var texture := load(path) as Texture2D
	return texture if texture != null else default_texture

func _build_center_status_hud(scene) -> void:
	scene.center_hud_root = Control.new()
	scene.center_hud_root.name = "CenterStatusHUD"
	scene.center_hud_root.anchor_left = 0.5
	scene.center_hud_root.anchor_right = 0.5
	scene.center_hud_root.offset_left = -190.0
	scene.center_hud_root.offset_top = 10.0
	scene.center_hud_root.offset_right = 190.0
	scene.center_hud_root.offset_bottom = 176.0
	scene.ui_root.add_child(scene.center_hud_root)

	scene.countdown_panel = TextureRect.new()
	scene.countdown_panel.name = "CountdownPanel"
	scene.countdown_panel.texture = TIMER_COUNTDOWN_FRAME
	scene.countdown_panel.position = Vector2(27.5, 0)
	scene.countdown_panel.size = Vector2(325, 87)
	scene.countdown_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.countdown_panel.stretch_mode = TextureRect.STRETCH_SCALE
	scene.center_hud_root.add_child(scene.countdown_panel)

	scene.countdown_label = Label.new()
	scene.countdown_label.name = "CountdownLabel"
	scene.countdown_label.position = Vector2(61, 18)
	scene.countdown_label.size = Vector2(194, 50)
	scene.countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.countdown_label.add_theme_font_size_override("font_size", 42)
	scene.countdown_label.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.countdown_label.add_theme_color_override("font_shadow_color", Color("#1A1714"))
	scene.countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	scene.countdown_label.add_theme_constant_override("shadow_offset_y", 2)
	scene.countdown_panel.add_child(scene.countdown_label)

	scene.extraction_status_panel = Control.new()
	scene.extraction_status_panel.name = "ExtractionStatusPanel"
	scene.extraction_status_panel.position = Vector2(41, 88)
	scene.extraction_status_panel.size = Vector2(EXTRACTION_STATUS_WIDTH, 50)
	scene.center_hud_root.add_child(scene.extraction_status_panel)

	scene.extraction_status_frame_left = TextureRect.new()
	scene.extraction_status_frame_left.name = "ExtractionStatusFrameLeft"
	scene.extraction_status_frame_left.texture = EXTRACTION_STATUS_FRAME_LEFT
	scene.extraction_status_frame_left.position = Vector2.ZERO
	scene.extraction_status_frame_left.size = Vector2(76, 50)
	scene.extraction_status_frame_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.extraction_status_frame_left.stretch_mode = TextureRect.STRETCH_SCALE
	scene.extraction_status_panel.add_child(scene.extraction_status_frame_left)

	scene.extraction_status_frame_center = TextureRect.new()
	scene.extraction_status_frame_center.name = "ExtractionStatusFrameCenter"
	scene.extraction_status_frame_center.texture = EXTRACTION_STATUS_FRAME_CENTER
	scene.extraction_status_frame_center.position = Vector2(76, 0)
	scene.extraction_status_frame_center.size = Vector2(EXTRACTION_STATUS_WIDTH - 100.0, 50)
	scene.extraction_status_frame_center.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.extraction_status_frame_center.stretch_mode = TextureRect.STRETCH_SCALE
	scene.extraction_status_panel.add_child(scene.extraction_status_frame_center)

	scene.extraction_status_frame_right = TextureRect.new()
	scene.extraction_status_frame_right.name = "ExtractionStatusFrameRight"
	scene.extraction_status_frame_right.texture = EXTRACTION_STATUS_FRAME_RIGHT
	scene.extraction_status_frame_right.position = Vector2(EXTRACTION_STATUS_WIDTH - 24.0, 0)
	scene.extraction_status_frame_right.size = Vector2(24, 50)
	scene.extraction_status_frame_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.extraction_status_frame_right.stretch_mode = TextureRect.STRETCH_SCALE
	scene.extraction_status_panel.add_child(scene.extraction_status_frame_right)

	scene.extraction_status_dot = TextureRect.new()
	scene.extraction_status_dot.name = "ExtractionStatusDot"
	scene.extraction_status_dot.texture = EXTRACTION_STATUS_DOT_UNAVAILABLE
	scene.extraction_status_dot.position = Vector2(17, 10)
	scene.extraction_status_dot.size = Vector2(30, 30)
	scene.extraction_status_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.extraction_status_dot.stretch_mode = TextureRect.STRETCH_SCALE
	scene.extraction_status_dot.z_index = 3
	scene.extraction_status_panel.add_child(scene.extraction_status_dot)

	scene.extraction_status_label = Label.new()
	scene.extraction_status_label.name = "ExtractionStatusLabel"
	scene.extraction_status_label.position = Vector2(64, 8)
	scene.extraction_status_label.size = Vector2(EXTRACTION_STATUS_WIDTH - 88.0, 34)
	scene.extraction_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.extraction_status_label.z_index = 3
	scene.extraction_status_label.add_theme_font_size_override("font_size", 18)
	scene.extraction_status_label.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.extraction_status_panel.add_child(scene.extraction_status_label)

	scene.extraction_progress_bar = ProgressBar.new()
	scene.extraction_progress_bar.name = "ExtractionHoldProgress"
	scene.extraction_progress_bar.position = Vector2(64, 17)
	scene.extraction_progress_bar.size = Vector2(EXTRACTION_STATUS_WIDTH - 96.0, 9)
	scene.extraction_progress_bar.min_value = 0.0
	scene.extraction_progress_bar.max_value = 1.0
	scene.extraction_progress_bar.value = 0.0
	scene.extraction_progress_bar.show_percentage = false
	scene.extraction_progress_bar.visible = false
	scene.extraction_progress_bar.z_index = 1
	scene.extraction_progress_bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.02, 0.018, 0.92), Color(0.28, 0.27, 0.24), 1))
	scene.extraction_progress_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.18, 0.66, 0.34, 0.96), Color(0.18, 0.66, 0.34), 0))
	scene.extraction_status_panel.add_child(scene.extraction_progress_bar)

	scene.extraction_status_button = Button.new()
	scene.extraction_status_button.name = "ExtractionStatusButton"
	scene.extraction_status_button.position = Vector2.ZERO
	scene.extraction_status_button.size = scene.extraction_status_panel.size
	scene.extraction_status_button.text = ""
	scene.extraction_status_button.focus_mode = Control.FOCUS_NONE
	scene.extraction_status_button.tooltip_text = "按住撤离"
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		scene.extraction_status_button.add_theme_stylebox_override(style_name, _transparent_button_style())
	scene.extraction_status_button.button_down.connect(scene._begin_extraction_hold_from_button)
	scene.extraction_status_button.button_up.connect(scene._release_extraction_hold_button)
	scene.extraction_status_panel.add_child(scene.extraction_status_button)

	scene.home_backpack_hint_label = Label.new()
	scene.home_backpack_hint_label.name = "HomeBackpackHint"
	scene.home_backpack_hint_label.position = Vector2(41, 140)
	scene.home_backpack_hint_label.size = Vector2(EXTRACTION_STATUS_WIDTH, 24)
	scene.home_backpack_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene.home_backpack_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene.home_backpack_hint_label.text = "按 TAB 打开背包界面"
	scene.home_backpack_hint_label.add_theme_font_size_override("font_size", 16)
	scene.home_backpack_hint_label.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.home_backpack_hint_label.add_theme_color_override("font_shadow_color", Color("#1A1714"))
	scene.home_backpack_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	scene.home_backpack_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	scene.home_backpack_hint_label.visible = false
	scene.center_hud_root.add_child(scene.home_backpack_hint_label)

func _build_outpost_status_hud(scene) -> void:
	scene.outpost_hud_root = Panel.new()
	scene.outpost_hud_root.name = "ObjectiveChainHUD"
	scene.outpost_hud_root.position = OBJECTIVE_HUD_POSITION
	scene.outpost_hud_root.size = OBJECTIVE_HUD_SIZE
	scene.outpost_hud_root.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.052, 0.046, 0.88), Color(0.92, 0.74, 0.18, 0.96), 2))
	scene.ui_root.add_child(scene.outpost_hud_root)

	scene.objective_task_title_label = _make_objective_label("ObjectiveTaskTitle", Vector2(18, 14), Vector2(394, 32), 18, Color(0.98, 0.82, 0.30))
	scene.outpost_hud_root.add_child(scene.objective_task_title_label)

	scene.objective_title_label = _make_objective_label("ObjectiveTitle", Vector2(18, 56), Vector2(394, 30), 16, Color(0.96, 0.86, 0.48))
	scene.outpost_hud_root.add_child(scene.objective_title_label)

	scene.objective_next_step_label = _make_objective_label("ObjectiveNextStep", Vector2(18, 96), Vector2(394, 28), 15, Color(0.84, 0.80, 0.70))
	scene.outpost_hud_root.add_child(scene.objective_next_step_label)

	scene.objective_extraction_label = _make_objective_label("ObjectiveExtraction", Vector2(18, 132), Vector2(394, 24), 15, Color(0.64, 0.62, 0.56))
	scene.outpost_hud_root.add_child(scene.objective_extraction_label)

	scene.outpost_count_label = scene.objective_title_label
	scene.outpost_first_status_label = scene.objective_next_step_label
	scene.outpost_second_status_label = scene.objective_extraction_label

func _build_minimap(scene) -> void:
	scene.minimap = RunMinimapScript.new()
	scene.minimap.name = "RunMinimap"
	scene.minimap.anchor_left = 1.0
	scene.minimap.anchor_right = 1.0
	scene.minimap.offset_left = -214.0
	scene.minimap.offset_top = 18.0
	scene.minimap.offset_right = -26.0
	scene.minimap.offset_bottom = 206.0
	scene.ui_root.add_child(scene.minimap)

func _build_backpack_status_hud(scene) -> void:
	scene.backpack_hud_root = Panel.new()
	scene.backpack_hud_root.name = "BackpackStatusHUD"
	scene.backpack_hud_root.anchor_left = 1.0
	scene.backpack_hud_root.anchor_right = 1.0
	scene.backpack_hud_root.anchor_top = 1.0
	scene.backpack_hud_root.anchor_bottom = 1.0
	scene.backpack_hud_root.offset_left = -362.0
	scene.backpack_hud_root.offset_top = -146.0
	scene.backpack_hud_root.offset_right = -18.0
	scene.backpack_hud_root.offset_bottom = -18.0
	scene.backpack_hud_root.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.055, 0.9), Color(0.07, 0.42, 0.72, 0.92), 2))
	scene.backpack_hud_root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	scene.backpack_hud_root.gui_input.connect(func(event): _on_backpack_status_hud_gui_input(scene, event))
	scene.ui_root.add_child(scene.backpack_hud_root)

	scene.backpack_icon_placeholder = Panel.new()
	scene.backpack_icon_placeholder.name = "BackpackIcon"
	scene.backpack_icon_placeholder.position = Vector2(16, 18)
	scene.backpack_icon_placeholder.size = Vector2(70, 70)
	scene.backpack_icon_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_icon_placeholder.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.04, 0.038, 0.55), Color(0.20, 0.20, 0.18, 0.0), 0))
	scene.backpack_hud_root.add_child(scene.backpack_icon_placeholder)

	var icon_image := TextureRect.new()
	icon_image.name = "BackpackIconImage"
	icon_image.position = Vector2(4, 4)
	icon_image.size = Vector2(62, 62)
	icon_image.texture = BACKPACK_STATUS_ICON
	icon_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_icon_placeholder.add_child(icon_image)

	var supply_panel := Control.new()
	supply_panel.name = "SupplySlotsBox"
	supply_panel.position = Vector2(106, 14)
	supply_panel.size = Vector2(210, 28)
	supply_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_hud_root.add_child(supply_panel)

	scene.backpack_slot_label = Label.new()
	scene.backpack_slot_label.name = "BackpackSlots"
	scene.backpack_slot_label.position = Vector2(8, 1)
	scene.backpack_slot_label.size = Vector2(194, 24)
	scene.backpack_slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_slot_label.add_theme_font_size_override("font_size", 20)
	scene.backpack_slot_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76))
	supply_panel.add_child(scene.backpack_slot_label)

	var material_panel := Control.new()
	material_panel.name = "MaterialSlotsBox"
	material_panel.position = Vector2(106, 46)
	material_panel.size = Vector2(210, 28)
	material_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_hud_root.add_child(material_panel)

	scene.backpack_material_slot_label = Label.new()
	scene.backpack_material_slot_label.name = "MaterialSlots"
	scene.backpack_material_slot_label.position = Vector2(8, 1)
	scene.backpack_material_slot_label.size = Vector2(194, 24)
	scene.backpack_material_slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.backpack_material_slot_label.add_theme_font_size_override("font_size", 20)
	scene.backpack_material_slot_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.78))
	material_panel.add_child(scene.backpack_material_slot_label)

	scene.weight_bar = ProgressBar.new()
	scene.weight_bar.name = "WeightBar"
	scene.weight_bar.position = Vector2(106, 86)
	scene.weight_bar.size = Vector2(210, 20)
	scene.weight_bar.min_value = 0.0
	scene.weight_bar.max_value = 20.0
	scene.weight_bar.value = 0.0
	scene.weight_bar.show_percentage = false
	scene.weight_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.weight_bar.add_theme_stylebox_override("background", _progress_style(Color(0.02, 0.02, 0.018, 0.92), Color(0.28, 0.28, 0.27), 1))
	scene.weight_bar.add_theme_stylebox_override("fill", _progress_style(Color(0.42, 0.28, 0.72, 0.95), Color(0.42, 0.28, 0.72), 0))
	scene.backpack_hud_root.add_child(scene.weight_bar)

	scene.weight_value_label = Label.new()
	scene.weight_value_label.name = "WeightValue"
	scene.weight_value_label.position = Vector2(106, 106)
	scene.weight_value_label.size = Vector2(210, 22)
	scene.weight_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _on_backpack_status_hud_gui_input(scene, event: InputEvent) -> void:
	if scene.has_method("is_run_story_paused") and bool(scene.is_run_story_paused()):
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			scene._toggle_inventory_panel()

func _build_inventory_panels(scene) -> void:
	scene.inventory_panel = _make_panel(Vector2(16, 154), Vector2(390, 360), "背包")
	scene.inventory_label = _make_grid_area(Vector2(16, 86), Vector2(358, 196))
	scene.inventory_panel.add_child(scene.inventory_label)
	scene.material_inventory_label = _make_grid_area(Vector2(16, 524), Vector2(358, 86))
	scene.inventory_panel.add_child(scene.material_inventory_label)
	var supply_title := Label.new()
	supply_title.name = "SupplyBackpackTitle"
	supply_title.text = "物资背包"
	supply_title.position = Vector2(28, 72)
	supply_title.size = Vector2(160, 24)
	supply_title.add_theme_font_size_override("font_size", 15)
	supply_title.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.inventory_panel.add_child(supply_title)
	var material_title := Label.new()
	material_title.name = "MaterialBackpackTitle"
	material_title.text = "材料背包"
	material_title.position = Vector2(28, 504)
	material_title.size = Vector2(160, 24)
	material_title.add_theme_font_size_override("font_size", 15)
	material_title.add_theme_color_override("font_color", Color("#88D8A8"))
	scene.inventory_panel.add_child(material_title)
	scene.inventory_selection_label = Label.new()
	scene.inventory_selection_label.name = "InventorySelectionLabel"
	scene.inventory_selection_label.add_theme_font_size_override("font_size", 15)
	scene.inventory_selection_label.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.inventory_panel.add_child(scene.inventory_selection_label)
	scene.discard_button = Button.new()
	scene.discard_button.name = "DiscardSelectedButton"
	scene.discard_button.text = "丢弃"
	scene.discard_button.disabled = true
	scene.discard_button.pressed.connect(scene._discard_selected_inventory_item)
	scene.inventory_panel.add_child(scene.discard_button)
	scene.ui_root.add_child(scene.inventory_panel)
	scene.inventory_panel.visible = false

	scene.home_storage_panel = _make_panel(Vector2(422, 154), Vector2(390, 360), "家中存储")
	scene.home_storage_label = _make_grid_area(Vector2(16, 52), Vector2(358, 230))
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
	scene.loot_label = _make_grid_area(Vector2(16, 52), Vector2(358, 170))
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
	if scene.stability_fill_clip != null:
		scene.stability_fill_clip.size = Vector2(STABILITY_FILL_SIZE.x * ratio, STABILITY_FILL_SIZE.y)
	if scene.stability_value_label != null:
		scene.stability_value_label.text = "%d/%d" % [int(round(current)), int(round(max_value))]
	if scene.stability_stage_label != null:
		scene.stability_stage_label.text = _stability_stage_text(ratio)
	_refresh_low_stability_warning(scene, current)

func _build_low_stability_warning_overlay(scene) -> void:
	scene.stability_warning_overlay = ColorRect.new()
	scene.stability_warning_overlay.name = "LowStabilityWarningOverlay"
	scene.stability_warning_overlay.anchor_right = 1.0
	scene.stability_warning_overlay.anchor_bottom = 1.0
	scene.stability_warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.stability_warning_overlay.color = Color.WHITE
	scene.stability_warning_overlay.z_index = 170
	scene.stability_warning_overlay.visible = false
	scene.stability_warning_material = _make_low_stability_warning_material()
	scene.stability_warning_overlay.material = scene.stability_warning_material
	scene.ui_root.add_child(scene.stability_warning_overlay)

func _refresh_low_stability_warning(scene, current_stability: float) -> void:
	if scene.stability_warning_overlay == null or scene.stability_warning_material == null:
		return
	var low_ratio := clampf((LOW_STABILITY_WARNING_THRESHOLD - current_stability) / LOW_STABILITY_WARNING_THRESHOLD, 0.0, 1.0)
	var strength := low_ratio * low_ratio * (3.0 - 2.0 * low_ratio)
	scene.stability_warning_overlay.visible = strength > 0.001
	scene.stability_warning_material.set_shader_parameter("warning_strength", strength)

func _make_low_stability_warning_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float warning_strength = 0.0;
uniform vec4 warning_color : source_color = vec4(0.92, 0.04, 0.03, 1.0);
uniform float max_alpha = 0.62;
uniform float near_edge_width = 0.034;
uniform float near_fade_width = 0.22;
uniform float critical_edge_width = 0.013;
uniform float critical_fade_width = 0.09;
uniform float pulse_speed = 3.4;
uniform float pulse_floor = 0.42;

void fragment() {
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float range_shrink = smoothstep(0.05, 0.5, warning_strength);
	float edge_width = mix(near_edge_width, critical_edge_width, range_shrink);
	float fade_width = mix(near_fade_width, critical_fade_width, range_shrink);
	float edge_mask = 1.0 - smoothstep(edge_width, fade_width, edge_distance);
	float pulse = mix(pulse_floor, 1.0, 0.5 + 0.5 * sin(TIME * pulse_speed));
	float alpha = warning_strength * max_alpha * pulse * edge_mask;
	COLOR = vec4(warning_color.rgb, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("warning_strength", 0.0)
	material.set_shader_parameter("max_alpha", LOW_STABILITY_WARNING_MAX_ALPHA)
	material.set_shader_parameter("near_edge_width", LOW_STABILITY_WARNING_NEAR_EDGE_WIDTH)
	material.set_shader_parameter("near_fade_width", LOW_STABILITY_WARNING_NEAR_FADE_WIDTH)
	material.set_shader_parameter("critical_edge_width", LOW_STABILITY_WARNING_CRITICAL_EDGE_WIDTH)
	material.set_shader_parameter("critical_fade_width", LOW_STABILITY_WARNING_CRITICAL_FADE_WIDTH)
	material.set_shader_parameter("pulse_speed", LOW_STABILITY_WARNING_PULSE_SPEED)
	material.set_shader_parameter("pulse_floor", LOW_STABILITY_WARNING_PULSE_FLOOR)
	return material

func _refresh_countdown(scene) -> void:
	if scene.countdown_label == null:
		return
	var remaining: float = maxf(0.0, float(scene.run_director.context.remaining_seconds))
	scene.countdown_label.text = _format_countdown(remaining)
	var text_color := Color("#D7D0C3")
	if remaining <= 30.0:
		text_color = Color("#8F3038")
		scene.countdown_label.add_theme_color_override("font_outline_color", Color("#080304"))
		scene.countdown_label.add_theme_constant_override("outline_size", 2)
	else:
		scene.countdown_label.add_theme_constant_override("outline_size", 0)
	scene.countdown_label.add_theme_color_override("font_color", text_color)

func _refresh_extraction_status(scene) -> void:
	var context = scene.run_director.context
	var can_extract: bool = context.is_extraction_unlocked
	var is_home_safe_zone: bool = context.active_safe_zone_id == "home"
	var is_extracting: bool = (
		scene.interaction_progress_controller != null
		and scene.interaction_progress_controller.is_active()
		and scene.interaction_progress_controller.active_id == "extract"
	)
	var extraction_progress: float = scene.interaction_progress_controller.get_progress() if is_extracting else 0.0
	scene.extraction_status_dot.texture = EXTRACTION_STATUS_DOT_AVAILABLE if can_extract else EXTRACTION_STATUS_DOT_UNAVAILABLE
	if is_extracting:
		scene.extraction_status_label.text = "撤离中 %d%%" % int(round(extraction_progress * 100.0))
	elif can_extract and is_home_safe_zone:
		scene.extraction_status_label.text = "长按 E 键进行撤离"
	elif can_extract:
		scene.extraction_status_label.text = "返回家中可撤离"
	else:
		scene.extraction_status_label.text = "撤离未激活"
	scene.extraction_status_label.add_theme_color_override("font_color", Color("#D7D0C3"))
	scene.extraction_progress_bar.visible = can_extract and (is_home_safe_zone or is_extracting)
	scene.extraction_progress_bar.value = extraction_progress
	scene.home_backpack_hint_label.visible = (
		is_home_safe_zone
		and not scene.inventory_panel.visible
		and not scene.home_storage_panel.visible
	)

func _refresh_outpost_status_hud(scene) -> void:
	if scene.outpost_hud_root == null:
		return
	var view := _objective_chain_view(scene)
	scene.objective_task_title_label.text = String(view.get("task_title", ""))
	scene.objective_title_label.text = String(view.get("title", ""))
	scene.objective_next_step_label.text = String(view.get("next_step", ""))
	scene.objective_extraction_label.text = String(view.get("extraction", ""))
	scene.outpost_hud_root.self_modulate = Color(
		1.0,
		1.0,
		1.0,
		OBJECTIVE_HUD_HOME_ALPHA if String(scene.run_director.context.active_safe_zone_id) == "home" else OBJECTIVE_HUD_FIELD_ALPHA
	)
	match String(view.get("stage", "")):
		"repairable":
			scene.objective_task_title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.30))
			scene.objective_title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
			scene.objective_next_step_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		"repairing":
			scene.objective_task_title_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.30))
			scene.objective_title_label.add_theme_color_override("font_color", Color(0.95, 0.58, 0.34))
			scene.objective_next_step_label.add_theme_color_override("font_color", Color(0.95, 0.74, 0.46))
		"extract_ready":
			scene.objective_task_title_label.add_theme_color_override("font_color", Color(0.70, 1.0, 0.58))
			scene.objective_title_label.add_theme_color_override("font_color", Color(0.56, 0.94, 0.58))
			scene.objective_next_step_label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.76))
		_:
			scene.objective_task_title_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.30))
			scene.objective_title_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.48))
			scene.objective_next_step_label.add_theme_color_override("font_color", Color(0.84, 0.80, 0.70))
	scene.objective_extraction_label.add_theme_color_override(
		"font_color",
		Color(0.56, 0.94, 0.58) if scene.run_director.context.is_extraction_unlocked else Color(0.64, 0.62, 0.56)
	)

func _refresh_minimap(scene) -> void:
	if scene.minimap != null and is_instance_valid(scene.minimap):
		scene.minimap.update_from_scene(scene)

func _objective_chain_view(scene) -> Dictionary:
	var context = scene.run_director.context
	var extraction_text := _objective_extraction_text(scene)
	var task_title := _objective_task_title_text(scene)
	if bool(context.is_extraction_unlocked):
		return {
			"task_title": task_title,
			"title": "当前目标：撤离已解锁",
			"next_step": "下一步：长按 E 撤离" if String(context.active_safe_zone_id) == "home" else "下一步：返回家中撤离",
			"extraction": extraction_text,
			"stage": "extract_ready",
		}
	var repair_progress := _active_outpost_repair_progress(scene)
	if bool(repair_progress.get("active", false)):
		return {
			"task_title": task_title,
			"title": "当前目标：修复前哨站 %d%%" % int(round(float(repair_progress.get("progress", 0.0)) * 100.0)),
			"next_step": "下一步：保持按住直到完成",
			"extraction": extraction_text,
			"stage": "repairing",
		}
	var target_id := _objective_target_outpost_id(scene)
	if target_id.is_empty():
		return {
			"task_title": task_title,
			"title": "当前目标：寻找前哨站",
			"next_step": "下一步：确认前哨位置",
			"extraction": extraction_text,
			"stage": "missing",
		}
	var counts := _objective_material_counts(scene, target_id)
	var covered := int(counts.get("covered", 0))
	var required := int(counts.get("required", 0))
	if required > 0 and covered >= required:
		return {
			"task_title": task_title,
			"title": "当前目标：前往前哨站",
			"next_step": "下一步：长按修复前哨站",
			"extraction": extraction_text,
			"stage": "repairable",
		}
	return {
		"task_title": task_title,
		"title": "当前目标：收集前哨站材料（菱形） %d/%d" % [covered, required],
		"next_step": "下一步：前哨站修复",
		"extraction": extraction_text,
		"stage": "collect_material",
	}

func _objective_extraction_text(scene) -> String:
	var context = scene.run_director.context
	if not bool(context.is_extraction_unlocked):
		return "解锁撤离：未解锁"
	if String(context.active_safe_zone_id) == "home":
		return "解锁撤离：可撤离"
	return "解锁撤离：已解锁"

func _objective_task_title_text(scene) -> String:
	var context = scene.run_director.context
	var repaired_count := _objective_repaired_outpost_count(scene)
	if bool(context.is_extraction_unlocked) or repaired_count >= 2:
		return "任务标题：携带物资返回家中撤离"
	return "任务标题：修复两座前哨站（%d/2）" % repaired_count

func _objective_target_outpost_id(scene) -> String:
	var context = scene.run_director.context
	var first_id := String(context.selected_first_outpost_id)
	var second_id := String(context.selected_second_outpost_id)
	if not _objective_outpost_repaired(scene, first_id):
		return first_id
	if not _objective_outpost_repaired(scene, second_id):
		return second_id
	return ""

func _objective_outpost_repaired(scene, outpost_id: String) -> bool:
	if outpost_id.is_empty():
		return true
	var station = _find_outpost_station(scene, outpost_id)
	if station != null:
		return bool(station.get("payload").get("repaired", false))
	return String(scene.run_director.context.outpost_states.get(outpost_id, "")) == "repaired"

func _objective_repaired_outpost_count(scene) -> int:
	var context = scene.run_director.context
	var repaired_count := 0
	var outpost_ids := [
		String(context.selected_first_outpost_id),
		String(context.selected_second_outpost_id),
	]
	for outpost_id in outpost_ids:
		if not outpost_id.is_empty() and _objective_outpost_repaired(scene, outpost_id):
			repaired_count += 1
	return mini(repaired_count, 2)

func _objective_material_counts(scene, outpost_id: String) -> Dictionary:
	var station = _find_outpost_station(scene, outpost_id)
	if station == null:
		return {"covered": 0, "required": 0}
	var requirements: Dictionary = station.get("payload").get("requirements", {})
	var delivered: Dictionary = station.get("payload").get("delivered_materials", {})
	var required := 0
	var covered := 0
	for item_id in requirements.keys():
		var item_key := str(item_id)
		var need := int(requirements[item_id].get("amount", 0))
		if need <= 0:
			continue
		required += 1
		var submitted := mini(need, int(delivered.get(item_key, 0)))
		var carried := _objective_inventory_count(scene, item_key)
		if submitted + carried >= need:
			covered += 1
	return {"covered": covered, "required": required}

func _objective_inventory_count(scene, item_id: String) -> int:
	if scene.run_director == null or scene.run_director.inventory_component == null:
		return 0
	var count := 0
	for stack in _material_items_snapshot(scene):
		if str(stack.get("item_id", "")) == item_id:
			count += int(stack.get("amount", 1))
	return count

func _active_outpost_repair_progress(scene) -> Dictionary:
	if scene.interaction_progress_controller != null and scene.interaction_progress_controller.is_active():
		if scene.interaction_progress_controller.active_id == "repair_outpost":
			return {"active": true, "progress": scene.interaction_progress_controller.get_progress()}
	return {"active": false, "progress": 0.0}

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
	var material_used_slots := 0
	var material_max_slots := 0
	if scene.run_director.inventory_component != null:
		used_slots = scene.run_director.inventory_component.items.size()
		max_slots = scene.run_director.inventory_component.max_slots
		if scene.run_director.inventory_component.has_method("get_repair_material_items_snapshot"):
			material_used_slots = scene.run_director.inventory_component.get_repair_material_items_snapshot().size()
		else:
			material_used_slots = scene.run_director.inventory_component.repair_material_items.size()
		material_max_slots = scene.run_director.inventory_component.max_repair_material_slots
	else:
		used_slots = scene.run_director.context.player_inventory.size()
		max_slots = scene.run_director.config.inventory_slots
		material_used_slots = scene.run_director.context.material_inventory.size()
		material_max_slots = MATERIAL_BACKPACK_DISPLAY_SLOTS
	var current_weight: float = maxf(0.0, float(scene.run_director.context.current_weight))
	var max_weight: float = maxf(1.0, float(scene.run_director.context.weight_limit))
	scene.backpack_slot_label.text = "背包格  %d/%d" % [used_slots, max_slots]
	scene.backpack_slot_label.text = "物资：%d/%d" % [used_slots, max_slots]
	scene.backpack_material_slot_label.text = "材料：%d/%d" % [material_used_slots, material_max_slots]
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
	var inventory_was_visible: bool = scene.inventory_panel.visible
	var storage_was_visible: bool = scene.home_storage_panel.visible
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
	if scene.inventory_panel.visible and not inventory_was_visible:
		_play_panel_open_from_bottom(scene.inventory_panel, scene)
	if scene.home_storage_panel.visible and not storage_was_visible:
		_play_panel_open_from_bottom(scene.home_storage_panel, scene)

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

func _make_grid_area(pos: Vector2, grid_size: Vector2) -> Control:
	var root := Control.new()
	root.position = pos
	root.size = grid_size
	return root

func _sync_storage_ui(scene, is_storage_zone: bool) -> void:
	if not is_storage_zone:
		var was_storage_panel_visible: bool = scene.home_storage_panel.visible
		scene.home_storage_user_closed = false
		scene.home_storage_panel.visible = false
		if was_storage_panel_visible and not scene.loot_panel.visible:
			scene.inventory_panel.visible = false
		return
	if scene._is_active_outpost_storage():
		if scene.home_storage_user_closed:
			scene.home_storage_panel.visible = false
			return
		scene.inventory_panel.visible = true
		scene.home_storage_panel.visible = true
		return
	if scene.home_storage_user_closed:
		scene.home_storage_panel.visible = false
		return
	scene.home_storage_panel.visible = scene.inventory_panel.visible

func _layout_inventory_surfaces(scene, is_storage_zone: bool, loot_open: bool) -> void:
	_configure_panel_anchor_right(scene.inventory_panel, INVENTORY_PANEL_SIZE, INVENTORY_PANEL_RIGHT_MARGIN, INVENTORY_PANEL_TOP)
	var supply_title := scene.inventory_panel.get_node_or_null("SupplyBackpackTitle") as Label
	if supply_title != null:
		supply_title.position = Vector2(28, 72)
		supply_title.size = Vector2(220, 24)
	var material_title := scene.inventory_panel.get_node_or_null("MaterialBackpackTitle") as Label
	if material_title != null:
		material_title.position = Vector2(28, 566)
		material_title.size = Vector2(220, 24)
	scene.inventory_label.position = Vector2(28, 108)
	scene.inventory_label.size = Vector2(404, 438)
	scene.material_inventory_label.position = Vector2(28, 596)
	scene.material_inventory_label.size = Vector2(404, 88)
	scene.inventory_selection_label.position = Vector2(28, 708)
	scene.inventory_selection_label.size = Vector2(280, 28)
	scene.discard_button.position = Vector2(326, 704)
	scene.discard_button.size = Vector2(106, 36)
	if is_storage_zone:
		_configure_panel_anchor_right(scene.home_storage_panel, INVENTORY_STORAGE_PANEL_SIZE, INVENTORY_SECONDARY_PANEL_RIGHT_MARGIN, INVENTORY_PANEL_TOP)
		scene.home_storage_label.position = Vector2(24, 68)
		scene.home_storage_label.size = Vector2(382, 190)
		scene.deposit_button.position = Vector2(140, 300)
		scene.deposit_button.size = Vector2(140, 36)
		scene.extract_button.position = Vector2(292, 300)
		scene.extract_button.size = Vector2(114, 36)
	if loot_open:
		_configure_panel_anchor_right(scene.loot_panel, INVENTORY_LOOT_PANEL_SIZE, INVENTORY_SECONDARY_PANEL_RIGHT_MARGIN, INVENTORY_LOOT_PANEL_TOP)
		scene.loot_label.position = Vector2(24, 68)
		scene.loot_label.size = Vector2(382, 170)
		scene.take_all_button.position = Vector2(140, 272)
		scene.take_all_button.size = Vector2(140, 36)

func _configure_panel_rect(panel: Panel, pos: Vector2, panel_size: Vector2, anchor_right: bool) -> void:
	if anchor_right:
		_configure_panel_anchor_right(panel, panel_size, 20.0, 72.0)
		return
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.position = pos
	panel.size = panel_size

func _configure_panel_anchor_right(panel: Panel, panel_size: Vector2, right_margin: float, top_margin: float) -> void:
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -right_margin - panel_size.x
	panel.offset_top = top_margin
	panel.offset_right = -right_margin
	panel.offset_bottom = top_margin + panel_size.y

func _play_panel_open_from_bottom(panel: Control, scene) -> void:
	if panel == null:
		return
	panel.pivot_offset = Vector2(panel.size.x * 0.5, panel.size.y)
	panel.scale = Vector2(1.0, 0.08)
	panel.modulate.a = 0.0
	var tween: Tween = scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, INVENTORY_PANEL_OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, INVENTORY_PANEL_OPEN_SECONDS * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_panel_title(panel: Panel, title: String) -> void:
	if panel == null:
		return
	var label := panel.get_node_or_null("TitleLabel") as Label
	if label != null:
		label.text = title

func _set_items_grid(scene, grid_root: Control, items: Array, source_id: String, capacity: int) -> void:
	capacity = maxi(capacity, items.size())
	var signature := _items_grid_signature(scene, grid_root, items, source_id, capacity)
	if grid_root.has_meta(ITEM_GRID_SIGNATURE_META) and String(grid_root.get_meta(ITEM_GRID_SIGNATURE_META)) == signature:
		return
	grid_root.set_meta(ITEM_GRID_SIGNATURE_META, signature)
	for child in grid_root.get_children():
		grid_root.remove_child(child)
		child.queue_free()
	var columns := INVENTORY_GRID_COLUMNS
	var gap := INVENTORY_GRID_SLOT_GAP
	var display_slots := _display_slot_count(source_id, capacity)
	var rows := ceili(float(maxi(display_slots, 1)) / float(columns))
	var slot_size: float = minf(
		INVENTORY_GRID_SLOT_SIZE,
		minf(
			floorf((grid_root.size.x - gap * float(columns - 1)) / float(columns)),
			floorf((grid_root.size.y - 34.0 - gap * float(rows - 1)) / float(rows))
		)
	)
	slot_size = maxf(34.0, slot_size)
	for index in range(display_slots):
		var col := index % columns
		var row := int(index / columns)
		var slot_pos := Vector2(col * (slot_size + gap), row * (slot_size + gap))
		var item: Variant = items[index] if index < items.size() else null
		if item is Dictionary:
			grid_root.add_child(_make_item_slot(scene, slot_pos, Vector2(slot_size, slot_size), item, index, source_id))
		else:
			grid_root.add_child(_make_empty_slot(scene, slot_pos, Vector2(slot_size, slot_size), index >= capacity, source_id, index))
	_add_grid_footer(scene, grid_root, items, capacity, source_id)

func _items_grid_signature(scene, grid_root: Control, items: Array, source_id: String, capacity: int) -> String:
	var parts := PackedStringArray()
	parts.append(source_id)
	parts.append(str(capacity))
	parts.append("%d:%d" % [roundi(grid_root.size.x), roundi(grid_root.size.y)])
	parts.append(str(_display_slot_count(source_id, capacity)))
	if source_id == "inventory":
		parts.append(str(int(scene.selected_inventory_index)))
		parts.append("%.1f:%.1f" % [float(scene.run_director.context.current_weight), float(scene.run_director.context.weight_limit)])
	for item in items:
		if item is Dictionary:
			parts.append(_item_signature(item))
		else:
			parts.append("_")
	return "|".join(parts)

func _item_signature(item: Dictionary) -> String:
	var keys := item.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key in keys:
		parts.append("%s=%s" % [str(key), var_to_str(item[key])])
	return ",".join(parts)

func _display_slot_count(source_id: String, capacity: int) -> int:
	if source_id == "inventory":
		return maxi(INVENTORY_BACKPACK_DISPLAY_SLOTS, capacity)
	if source_id == "inventory_material":
		return maxi(MATERIAL_BACKPACK_DISPLAY_SLOTS, capacity)
	return maxi(capacity, 1)

func _make_item_slot(scene, pos: Vector2, slot_size: Vector2, item: Dictionary, index: int, source_id: String) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = slot_size
	button.text = ""
	button.clip_text = false
	button.set_meta("ui_click_sfx", "ui_item_click")
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", _quality_color(item))
	var selected := source_id == "inventory" and index == int(scene.selected_inventory_index)
	var border_color := Color("#D1B850") if selected else Color("#35C9D7")
	if source_id == "inventory_material" and not selected:
		border_color = Color("#20B86B")
	var border_width := 3 if selected else 2
	button.add_theme_stylebox_override("normal", _slot_style(Color("#071116"), border_color, border_width))
	button.add_theme_stylebox_override("hover", _slot_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _slot_style(Color("#121817"), Color("#D1B850"), 3))
	_add_item_slot_content(button, slot_size, item)
	button.button_up.connect(func(): _dispatch_grid_slot(scene, source_id, index))
	return button

func _refresh_inventory_actions(scene) -> void:
	var has_selection: bool = scene.has_selected_inventory_item()
	var story_paused: bool = scene.has_method("is_run_story_paused") and bool(scene.is_run_story_paused())
	scene.discard_button.disabled = story_paused or not has_selection
	scene.inventory_selection_label.text = scene.selected_inventory_item_summary()

func _make_empty_slot(scene, pos: Vector2, slot_size: Vector2, locked: bool = false, source_id: String = "", index: int = -1) -> Control:
	if not locked and _empty_slot_accepts_click(source_id):
		var button := Button.new()
		button.position = pos
		button.size = slot_size
		button.text = ""
		button.set_meta("ui_click_sfx", "ui_item_click")
		button.add_theme_stylebox_override("normal", _slot_style(Color("#071116"), Color("#35C9D7"), 1))
		button.add_theme_stylebox_override("hover", _slot_style(Color("#0B151A"), Color("#D1B850"), 2))
		button.add_theme_stylebox_override("pressed", _slot_style(Color("#121817"), Color("#D1B850"), 3))
		button.button_up.connect(func(): _dispatch_grid_slot(scene, source_id, index))
		return button
	var panel := Panel.new()
	panel.position = pos
	panel.size = slot_size
	var border := Color("#4D575B") if locked else Color("#35C9D7")
	if source_id == "inventory_material" and not locked:
		border = Color("#20B86B")
	panel.add_theme_stylebox_override("panel", _slot_style(Color("#071116"), border, 1))
	if locked:
		var label := Label.new()
		label.text = "/"
		label.position = Vector2.ZERO
		label.size = slot_size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color("#4D575B"))
		panel.add_child(label)
	return panel

func _add_grid_footer(scene, grid_root: Control, items: Array, capacity: int, source_id: String) -> void:
	var used := _occupied_item_count(items)
	var footer := Label.new()
	footer.position = Vector2(0, grid_root.size.y - 26.0)
	footer.size = Vector2(grid_root.size.x, 24)
	footer.add_theme_font_size_override("font_size", 15)
	footer.add_theme_color_override("font_color", Color("#8DB6B9"))
	if source_id == "inventory":
		var current_weight: float = maxf(0.0, float(scene.run_director.context.current_weight))
		var max_weight: float = maxf(1.0, float(scene.run_director.context.weight_limit))
		footer.text = "容量: %d/%d    负重: %.1f/%.1f" % [used, capacity, current_weight, max_weight]
	else:
		footer.text = "容量: %d/%d" % [used, capacity]
	if source_id == "inventory":
		var current_weight_override: float = maxf(0.0, float(scene.run_director.context.current_weight))
		var max_weight_override: float = maxf(1.0, float(scene.run_director.context.weight_limit))
		footer.text = "物资: %d/%d    负重: %.1f/%.1f" % [used, capacity, current_weight_override, max_weight_override]
	elif source_id == "inventory_material":
		footer.text = "材料: %d/%d" % [used, capacity]
	grid_root.add_child(footer)

func _empty_slot_accepts_click(source_id: String) -> bool:
	return source_id == "storage"

func _occupied_item_count(items: Array) -> int:
	var count := 0
	for item in items:
		if item is Dictionary:
			count += 1
	return count

func _dispatch_grid_slot(scene, source_id: String, index: int) -> void:
	match source_id:
		"inventory":
			scene._on_inventory_item_meta_clicked("inventory:%d" % index)
		"loot":
			scene._on_loot_item_meta_clicked("loot:%d" % index)
		"inventory_material":
			pass
		_:
			scene._on_home_storage_item_meta_clicked("storage:%d" % index)

func _slot_text(item: Dictionary) -> String:
	var name := String(item.get("display_name", item.get("item_id", "")))
	return "%s" % name

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
		fallback.text = "材" if _is_repair_material_item(item) else String(item.get("quality", "C"))
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

func _item_icon_texture(item: Dictionary) -> Texture2D:
	var icon_path := String(item.get("icon", ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	var resource := load(icon_path)
	return resource as Texture2D

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

func _compact_item_name(name: String) -> String:
	if name.length() <= 4:
		return name
	return name.substr(0, 4) + "..."

func _slot_display_name(name: String) -> String:
	if name.length() <= 6:
		return name
	return name.substr(0, 6)

func _material_items_snapshot(scene) -> Array:
	var inventory = scene.run_director.inventory_component
	if inventory != null and inventory.has_method("get_repair_material_items_snapshot"):
		return inventory.get_repair_material_items_snapshot()
	return []

func _material_capacity(scene) -> int:
	var inventory = scene.run_director.inventory_component
	if inventory != null:
		return int(inventory.max_repair_material_slots)
	return MATERIAL_BACKPACK_DISPLAY_SLOTS

func _active_storage_capacity(scene) -> int:
	if scene._is_active_outpost_storage():
		return scene.run_director.get_outpost_storage_capacity(scene.active_outpost_storage_id)
	if scene.run_director.home_storage_component != null:
		return scene.run_director.home_storage_component.max_slots
	return 0

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
	var color := _quality_color_hex(item)
	var name := String(item.get("display_name", item.get("item_id", "")))
	var amount := int(item.get("amount", 0))
	var weight := float(item.get("weight_per_unit", 0.0))
	var text := "[color=#%s]%s[/color]  x%s  单重 %.2f" % [color, name, amount, weight]
	if not _is_repair_material_item(item):
		var quality := String(item.get("quality", "C"))
		text = "[color=#%s][%s] %s[/color]  x%s  单重 %.2f" % [color, quality, name, amount, weight]
	if source_id.is_empty() or index < 0:
		return text
	return "[url=%s:%d]%s[/url]" % [source_id, index, text]

func _quality_color_hex(item: Dictionary) -> String:
	if _is_repair_material_item(item) and not item.has("quality_color"):
		return "20B86B"
	var value = item.get("quality_color", Color.WHITE)
	if value is Color:
		return value.to_html(false)
	return "FFFFFF"

func _quality_color(item: Dictionary) -> Color:
	if _is_repair_material_item(item) and not item.has("quality_color"):
		return Color("#20B86B")
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

func _is_repair_material_item(item: Dictionary) -> bool:
	return not String(item.get("repair_material_id", "")).is_empty()

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

func _make_objective_label(node_name: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

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

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style

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

func _dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	return style

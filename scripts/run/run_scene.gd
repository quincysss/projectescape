extends Node2D

const BasicPlayerScene := preload("res://scenes/entities/player/BasicPlayer.tscn")
const InteractableScript := preload("res://scripts/run/run_interactable.gd")
const VisionCircleScript := preload("res://scripts/vision/vision_debug_circle.gd")
const VisionMaskScript := preload("res://scripts/vision/vision_mask_overlay.gd")
const LootInteractionControllerScript := preload("res://scripts/run/loot_interaction_controller.gd")
const RunEndControllerScript := preload("res://scripts/run/run_end_controller.gd")
const OutpostRepairControllerScript := preload("res://scripts/run/outpost_repair_controller.gd")
const InteractionProgressControllerScript := preload("res://scripts/run/interaction_progress_controller.gd")
const ContainerSpawnControllerScript := preload("res://scripts/run/container_spawn_controller.gd")
const OutpostMaterialSpawnControllerScript := preload("res://scripts/run/outpost_material_spawn_controller.gd")
const InteractableVisualBuilderScript := preload("res://scripts/run/interactable_visual_builder.gd")
const RunUiControllerScript := preload("res://scripts/run/run_ui_controller.gd")
const RunTimerControllerScript := preload("res://scripts/run/run_timer_controller.gd")
const RunMapBuilderScript := preload("res://scripts/map/run_map_builder.gd")
const MonsterSpawnControllerScript := preload("res://scripts/monsters/monster_spawn_controller.gd")
const SettlementResultScreenScript := preload("res://scripts/ui/settlement_result_screen.gd")
const ReturnToBaseLoadingScreenScript := preload("res://scripts/ui/return_to_base_loading_screen.gd")
const DialogueServiceScript := preload("res://scripts/dialogue/dialogue_service.gd")
const DialoguePanelScene := preload("res://scenes/ui/DialoguePanel.tscn")
const UNIT := 64.0
const MAP_UNITS := Vector2(280.0, 220.0)
const MAP_ORIGIN_UNITS := Vector2(-140.0, -110.0)
const HOME_SIZE_UNITS := Vector2(10.0, 8.0)
const HOME_SAFE_SIZE_UNITS := Vector2(12.0, 10.0)
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const MAIN_ROAD_WIDTH_UNITS := 8.0
const SECONDARY_ROAD_WIDTH_UNITS := 6.0
const ALLEY_WIDTH_UNITS := 4.0
const PLAYER_FOLLOW_ZOOM := Vector2(0.28, 0.28)
const HOME_OVERVIEW_MAX_ZOOM := 0.11
const HOME_OVERVIEW_MIN_ZOOM := 0.025
const HOME_OVERVIEW_PADDING_UNITS := Vector2(0.0, 0.0)
const HOME_OVERVIEW_READABLE_UI_SCALE_MULTIPLIER := 1.0
const HOME_OVERVIEW_READABLE_UI_MAX_SCALE := 3.0
const CAMERA_TRANSITION_SECONDS := 0.5
const CONTAINER_OPEN_HOLD_SECONDS := 0.8
const OUTPOST_REPAIR_HOLD_SECONDS := 1.5
const EXTRACTION_HOLD_SECONDS := 3.0
const STATUS_PROMPT_VISIBLE_SECONDS := 3.0
const SHOW_DEBUG_VISION_CIRCLE := false
const PLAYER_ALWAYS_IN_FRONT_BUILDING_Z_INDEX := -1
const SECOND_DAY_BLACK_TIDE_DIALOGUE_PATH := "res://setting/dialogues.tab#second_day_black_tide_reveal_dialogue"
const SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH := "res://assets/cinematics/source/second_day_black_tide_reveal_720p.mp4"
const SECOND_DAY_BLACK_TIDE_CINEMATIC_FALLBACK_PATH := "res://assets/cinematics/second_day_black_tide_reveal_720p.ogv"
const SECOND_DAY_BLACK_TIDE_PLACEHOLDER_SECONDS := 1.2
const WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID := "project-escape-second-day-black-tide-video"

@onready var run_director: RunDirector = $RunDirector
@onready var world_root: Node2D = $WorldRoot
@onready var y_sort_root: Node2D = $WorldRoot/YSortRoot
@onready var map_visual_root: Node2D = $WorldRoot/MapVisual
@onready var road_visual_root: Node2D = $WorldRoot/MapVisual/RoadVisual
@onready var block_visual_root: Node2D = $WorldRoot/MapVisual/BlockVisual
@onready var building_visual_root: Node2D = $WorldRoot/YSortRoot
@onready var prop_visual_root: Node2D = $WorldRoot/MapVisual/PropVisual
@onready var decal_visual_root: Node2D = $WorldRoot/MapVisual/DecalVisual
@onready var player_root: Node2D = $WorldRoot/PlayerRoot
@onready var container_root: Node2D = $WorldRoot/ContainerRoot
@onready var outpost_root: Node2D = $WorldRoot/OutpostRoot
@onready var ui_root: CanvasLayer = $RunUIRoot
@onready var home_safe_zone: HomeSafeZone = $WorldRoot/PlayerRoot/HomeSafeZone

var player
var camera: Camera2D
var vision_circle
var vision_mask
var interactables: Array = []
var nearest_interactable
var opened_container
var opened_loot: Array[Dictionary] = []
var repaired_outposts: Dictionary = {}
var outpost_requirements: Dictionary = {}
var outpost_safe_zones: Dictionary = {}
var outpost_visual_anchors: Dictionary = {}
var _blocked_rects: Array[Rect2] = []
var _walkable_rects: Array[Rect2] = []
var _walkable_polygons: Array[PackedVector2Array] = []
var enterable_exception_rects: Array[Rect2] = []

var hud_label: Label
var character_hud_root: Control
var portrait_image: TextureRect
var portrait_frame: TextureRect
var stability_hud_root: Control
var stability_bar: Control
var stability_fill_clip: Control
var stability_fill_texture: TextureRect
var stability_frame_texture: TextureRect
var stability_value_label: Label
var stability_stage_label: Label
var center_hud_root: Control
var countdown_panel: TextureRect
var countdown_label: Label
var extraction_status_panel: Control
var extraction_status_frame_left: TextureRect
var extraction_status_frame_center: TextureRect
var extraction_status_frame_right: TextureRect
var extraction_status_dot: TextureRect
var extraction_status_label: Label
var extraction_status_button: Button
var extraction_progress_bar: ProgressBar
var home_backpack_hint_label: Label
var outpost_hud_root: Panel
var outpost_count_label: Label
var outpost_first_icon: Panel
var outpost_first_status_label: Label
var outpost_first_progress_bar: ProgressBar
var outpost_second_icon: Panel
var outpost_second_status_label: Label
var outpost_second_progress_bar: ProgressBar
var objective_title_label: Label
var objective_next_step_label: Label
var objective_extraction_label: Label
var backpack_hud_root: Panel
var backpack_icon_placeholder: Panel
var backpack_slot_label: Label
var backpack_material_slot_label: Label
var weight_bar: ProgressBar
var weight_value_label: Label
var prompt_label: Label
var inventory_panel: Panel
var inventory_label: Control
var material_inventory_label: Control
var inventory_selection_label: Label
var loot_panel: Panel
var loot_label: Control
var home_storage_panel: Panel
var home_storage_label: Control
var take_all_button: Button
var discard_button: Button
var deposit_button: Button
var extract_button: Button
var extract_hud_button: Button
var backpack_button: Button
var _game_state: Node
var _camera_tween: Tween
var loot_interaction_controller
var run_end_controller
var outpost_repair_controller
var interaction_progress_controller
var container_spawn_controller
var outpost_material_spawn_controller
var monster_spawn_controller
var interactable_visual_builder
var run_ui_controller
var run_timer_controller
var map_builder
var dialogue_service = DialogueServiceScript.new()
var _timed_status_prompt_text: String = ""
var _status_prompt_clear_time_msec: int = 0
var _status_prompt: String = "":
	set(value):
		_status_prompt = value
		_timed_status_prompt_text = ""
		_status_prompt_clear_time_msec = 0
var settlement_result_screen: SettlementResultScreen
var return_to_base_loading_screen: ReturnToBaseLoadingScreen
var _pending_run_result: Dictionary = {}
var home_storage_user_closed: bool = false
var active_outpost_storage_id: String = ""
var selected_inventory_index: int = -1
var _extract_button_held: bool = false
var _ui_refresh_queued: bool = false
var _story_pause_tokens: Dictionary = {}
var _story_gate_running: bool = false
var _story_video_overlay: Control
var _story_video_player: VideoStreamPlayer
var _story_video_finish_timer: Timer
var _story_video_bgm_paused: bool = false
var _story_web_video_active := false
var _active_story_dialogue_panel: Control

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_camera_for_viewport()
		_refresh_story_video_cover()

func _ready() -> void:
	_ensure_input_actions()
	_game_state = get_node_or_null("/root/GameState")
	_create_runtime_controllers()
	_build_run_world()
	_configure_monster_spawn_controller()
	_build_ui()
	_connect_runtime()
	run_director.start_new_run()
	_spawn_selected_outposts()
	_spawn_initial_containers()
	_spawn_requirement_materials()
	_spawn_monsters_for_run()
	_prepare_initial_story_gate()
	if camera:
		camera.zoom = _home_overview_zoom()
		camera.position = _home_overview_offset()
	_play_run_safe_house_bgm()
	_refresh_ui()
	call_deferred("_maybe_start_run_story_gate")

func _exit_tree() -> void:
	_story_web_video_active = false
	_remove_web_video(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID)
	_set_web_canvas_transparent(false)
	_resume_bgm_after_story_video()
	_audio_manager_call("stop_container_open_loop")
	_audio_manager_call("set_stability_critical_loop_active", [false])

func _create_runtime_controllers() -> void:
	loot_interaction_controller = LootInteractionControllerScript.new()
	run_end_controller = RunEndControllerScript.new()
	run_end_controller.setup(run_director, _game_state)
	outpost_repair_controller = OutpostRepairControllerScript.new()
	outpost_repair_controller.setup(run_director, repaired_outposts)
	interaction_progress_controller = InteractionProgressControllerScript.new()
	interactable_visual_builder = InteractableVisualBuilderScript.new()
	interactable_visual_builder.setup(UNIT)
	run_ui_controller = RunUiControllerScript.new()
	run_timer_controller = RunTimerControllerScript.new()
	run_timer_controller.time_expired.connect(_on_run_time_expired)
	map_builder = RunMapBuilderScript.new()
	map_builder.setup(self, UNIT, MAP_UNITS, MAP_ORIGIN_UNITS, HOME_SAFE_SIZE_UNITS, OUTPOST_SIZE_UNITS)
	container_spawn_controller = ContainerSpawnControllerScript.new()
	container_spawn_controller.setup(
		container_root,
		Callable(self, "_get_container_spawn_points"),
		Callable(self, "_make_interactable"),
		Callable(self, "_item"),
		Callable(self, "_remove_interactable"),
		UNIT
	)
	outpost_material_spawn_controller = OutpostMaterialSpawnControllerScript.new()
	outpost_material_spawn_controller.setup(
		outpost_root,
		Callable(self, "_get_material_spawn_points"),
		Callable(self, "_make_interactable"),
		Callable(self, "_item"),
		Callable(self, "_remove_interactable"),
		UNIT,
		run_director.data_registry
	)
	monster_spawn_controller = MonsterSpawnControllerScript.new()

func _configure_monster_spawn_controller() -> void:
	if monster_spawn_controller == null:
		monster_spawn_controller = MonsterSpawnControllerScript.new()
	monster_spawn_controller.setup(
		y_sort_root,
		Callable(self, "_get_monster_spawn_points"),
		player,
		run_director,
		UNIT
	)

func _refresh_camera_for_viewport() -> void:
	if camera == null or player == null:
		return
	if run_director.context != null and run_director.context.active_safe_zone_id == "home":
		camera.zoom = _home_overview_zoom()
		camera.position = _home_overview_offset()

func _ensure_input_actions() -> void:
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("interact", KEY_F)
	_add_key_action("toggle_inventory", KEY_TAB)
	_add_key_action("extract", KEY_E)

func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var already_bound := false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			already_bound = true
	if already_bound:
		return
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)

func _process(delta: float) -> void:
	_update_status_prompt_timeout()
	_update_story_web_video()
	if _is_settlement_flow_active():
		return
	if _is_story_paused():
		_update_readable_world_ui_scale()
		_refresh_ui()
		return
	_update_run_timer(delta)
	_update_active_interaction(delta)
	if container_spawn_controller != null:
		container_spawn_controller.update(delta, interactables)
	if outpost_material_spawn_controller != null:
		outpost_material_spawn_controller.update_lifetimes(delta, interactables)
	_update_container_lifetime_visuals()
	_update_material_lifetime_visuals()
	_update_outpost_requirement_bubbles()
	_update_readable_world_ui_scale()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("toggle_inventory"):
		_toggle_inventory_panel()
	if Input.is_action_just_pressed("extract"):
		_try_extract()
	_refresh_ui()

func _build_run_world() -> void:
	map_builder.build()
	_setup_outpost_visual_anchors()
	_apply_building_draw_overrides()
	_create_home_visual()
	_create_player()
	_create_camera()
	_create_vision_circle()

func _apply_building_draw_overrides() -> void:
	for child in y_sort_root.get_children():
		if not (child is CanvasItem):
			continue
		if bool(child.get_meta("outpost_uses_normal_ysort", false)):
			child.set_meta("occludes_player", false)
		if bool(child.get_meta("player_always_in_front", false)):
			var canvas_item := child as CanvasItem
			canvas_item.z_index = PLAYER_ALWAYS_IN_FRONT_BUILDING_Z_INDEX
			child.set_meta("occludes_player", false)
		elif bool(child.get_meta("outpost_uses_normal_ysort", false)):
			var ysort_canvas_item := child as CanvasItem
			ysort_canvas_item.z_index = 0

func _setup_outpost_visual_anchors() -> void:
	outpost_visual_anchors.clear()
	for child in y_sort_root.get_children():
		if not (child.has_method("get_candidate_id") and child.has_method("set_repaired")):
			continue
		var candidate_id := String(child.get_candidate_id())
		if candidate_id.is_empty():
			continue
		outpost_visual_anchors[candidate_id] = child
		child.set_meta("player_always_in_front", true)
		child.set_meta("outpost_uses_normal_ysort", true)
		child.set_meta("occludes_player", false)
		if child is CanvasItem:
			(child as CanvasItem).z_index = PLAYER_ALWAYS_IN_FRONT_BUILDING_Z_INDEX
		if child.has_method("set_selected"):
			child.set_selected(false)

func _reset_outpost_visual_anchors() -> void:
	for anchor in outpost_visual_anchors.values():
		if anchor == null or not is_instance_valid(anchor):
			continue
		if anchor.has_method("set_repaired"):
			anchor.set_repaired(false)
		if anchor.has_method("set_selected"):
			anchor.set_selected(false)

func _get_outpost_visual_anchor(outpost_id: String) -> Node2D:
	var anchor = outpost_visual_anchors.get(outpost_id, null)
	if anchor is Node2D and is_instance_valid(anchor):
		return anchor
	return null

func _sync_outpost_visual_anchor(station) -> void:
	if station == null or not is_instance_valid(station):
		return
	var anchor := _get_outpost_visual_anchor(station.interact_id)
	if anchor == null:
		return
	var payload: Dictionary = station.payload
	payload["visual_anchor_path"] = anchor.get_path()
	if anchor.has_method("set_selected"):
		anchor.set_selected(true)
	else:
		anchor.visible = true
	if anchor.has_method("set_repaired"):
		anchor.set_repaired(bool(payload.get("repaired", false)))

func _get_enterable_exception_rects() -> Array[Rect2]:
	return map_builder.get_enterable_exception_rects()

func _get_outpost_candidate_points() -> Array[Node2D]:
	return map_builder.get_outpost_candidate_points()

func _get_layout_rects(section_name: String) -> Array:
	return map_builder.get_layout_rects(section_name)

func _get_layout_points(section_name: String) -> Array:
	return map_builder.get_layout_points(section_name)

func _create_home_visual() -> void:
	var safe_area := ColorRect.new()
	safe_area.name = "HomeSafeZoneVisual"
	safe_area.color = Color(0.0, 0.55, 0.22, 0.22)
	safe_area.size = _u(HOME_SAFE_SIZE_UNITS)
	safe_area.position = -safe_area.size * 0.5
	safe_area.z_index = -20
	player_root.add_child(safe_area)

	var home := ColorRect.new()
	home.name = "HomeGreenBox_10x8"
	home.color = Color(0.08, 0.7, 0.22)
	home.size = _u(HOME_SIZE_UNITS)
	home.position = -home.size * 0.5
	home.z_index = -10
	player_root.add_child(home)

	var label: Label = interactable_visual_builder.make_world_label("HOME 10x8\nSAFE 12x10", _u(Vector2(-5.5, -6.8)), player_root)
	label.modulate = Color(0.8, 1.0, 0.8)
	label.z_index = 20

func _create_player() -> void:
	player = BasicPlayerScene.instantiate()
	player.name = "Player"
	var speed_multiplier := 1.0
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("get_player_move_speed_multiplier"):
		speed_multiplier = maxf(1.0, float(game_state.get_player_move_speed_multiplier()))
	player.base_speed = 12.0 * UNIT * speed_multiplier
	y_sort_root.add_child(player)
	player.global_position = $WorldRoot/PlayerRoot/PlayerSpawn.global_position
	_walkable_rects.append(Rect2(player_root.global_position - _u(HOME_SAFE_SIZE_UNITS) * 0.5, _u(HOME_SAFE_SIZE_UNITS)))
	player.set_blocked_rects(_blocked_rects)
	player.set_walkable_rects(_walkable_rects)
	player.set_walkable_polygons(_walkable_polygons)

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.name = "PlayerCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.zoom = _home_overview_zoom()
	camera.position = _home_overview_offset()
	camera.limit_left = int(MAP_ORIGIN_UNITS.x * UNIT)
	camera.limit_top = int(MAP_ORIGIN_UNITS.y * UNIT)
	camera.limit_right = int((MAP_ORIGIN_UNITS.x + MAP_UNITS.x) * UNIT)
	camera.limit_bottom = int((MAP_ORIGIN_UNITS.y + MAP_UNITS.y) * UNIT)
	var camera_parent: Node = player.get_node_or_null("CameraMount")
	if camera_parent == null:
		camera_parent = player
	camera_parent.add_child(camera)
	camera.call_deferred("make_current")

func _create_vision_circle() -> void:
	vision_circle = VisionCircleScript.new()
	vision_circle.name = "VisionDebugCircle"
	vision_circle.target = player
	vision_circle.visible = SHOW_DEBUG_VISION_CIRCLE
	vision_circle.z_index = 100
	world_root.add_child(vision_circle)

	vision_mask = VisionMaskScript.new()
	vision_mask.name = "VisionMaskOverlay"
	vision_mask.target = player
	ui_root.add_child(vision_mask)

func _build_ui() -> void:
	run_ui_controller.build(self)

func _connect_runtime() -> void:
	run_director.run_initialized.connect(_on_run_initialized)
	run_director.stability_changed.connect(_on_stability_changed)
	run_director.weight_changed.connect(_on_weight_changed)
	run_director.inventory_changed.connect(func(_items): _refresh_ui())
	run_director.home_storage_changed.connect(func(_items): _refresh_ui())
	run_director.outpost_storage_changed.connect(func(_outpost_id, _items): _refresh_ui())
	home_safe_zone.safe_zone_entered.connect(func(_zone_id, _zone_type): _switch_camera_home())
	home_safe_zone.safe_zone_exited.connect(func(_zone_id, _zone_type): _switch_camera_follow())
	if run_director.vision_controller:
		run_director.vision_controller.darkness_changed.connect(vision_mask.set_darkness_enabled)
		if SHOW_DEBUG_VISION_CIRCLE:
			run_director.vision_controller.darkness_changed.connect(vision_circle.set_darkness_enabled)
			run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_circle.set_radius(radius))
		run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_mask.set_radius(radius))

func _on_run_initialized(context) -> void:
	if run_timer_controller == null or run_director == null:
		return
	run_timer_controller.setup(context, run_director.config.run_duration_seconds)
	if container_spawn_controller != null and run_director.has_method("get_ss_loot_director"):
		container_spawn_controller.setup_ss_loot_director(run_director.get_ss_loot_director())

func _prepare_initial_story_gate() -> void:
	if _should_trigger_second_day_black_tide_story():
		_acquire_story_pause("second_day_black_tide_reveal")

func _maybe_start_run_story_gate() -> void:
	if _story_gate_running:
		return
	await get_tree().process_frame
	if not _should_trigger_second_day_black_tide_story():
		_release_story_pause("second_day_black_tide_reveal")
		return
	_story_gate_running = true
	_acquire_story_pause("second_day_black_tide_reveal")
	await _play_second_day_black_tide_story()
	_story_gate_running = false

func _should_trigger_second_day_black_tide_story() -> bool:
	if _game_state == null or run_director == null or run_director.context == null:
		return false
	var run_day_index := int(run_director.context.run_day_index)
	if _game_state.has_method("should_play_second_day_black_tide_reveal"):
		return bool(_game_state.should_play_second_day_black_tide_reveal(run_day_index))
	return run_day_index == 2 and not bool(_game_state.get("second_day_black_tide_reveal_seen"))

func _play_second_day_black_tide_story() -> void:
	_show_second_day_black_tide_cinematic()
	while is_instance_valid(_story_video_overlay):
		await get_tree().process_frame
	await _play_run_story_dialogue(SECOND_DAY_BLACK_TIDE_DIALOGUE_PATH)
	if _game_state != null and _game_state.has_method("mark_second_day_black_tide_reveal_seen"):
		_game_state.mark_second_day_black_tide_reveal_seen()
	_release_story_pause("second_day_black_tide_reveal")
	_refresh_ui()

func _show_second_day_black_tide_cinematic() -> void:
	if is_instance_valid(_story_video_overlay):
		return
	var overlay := Control.new()
	overlay.name = "SecondDayBlackTideCinematicOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	ui_root.add_child(overlay)
	_story_video_overlay = overlay

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
	placeholder_label.text = "暗潮影像同步中"
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
	skip_button.pressed.connect(func(): _finish_second_day_black_tide_cinematic(true))
	overlay.add_child(skip_button)
	if video_loaded and OS.has_feature("web"):
		skip_button.visible = false

	if not video_loaded:
		push_warning("Second day black tide cinematic is missing or unsupported; continuing with placeholder.")
		_story_video_finish_timer = Timer.new()
		_story_video_finish_timer.one_shot = true
		_story_video_finish_timer.wait_time = SECOND_DAY_BLACK_TIDE_PLACEHOLDER_SECONDS
		_story_video_finish_timer.timeout.connect(func(): _finish_second_day_black_tide_cinematic(false))
		overlay.add_child(_story_video_finish_timer)
		_story_video_finish_timer.start()

func _add_second_day_black_tide_video(background: ColorRect, frame: ColorRect, placeholder_label: Label) -> bool:
	if OS.has_feature("web"):
		var web_url := _res_path_to_web_url(SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH)
		if not _play_web_video(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID, web_url, false, false, true):
			return false
		_story_web_video_active = true
		background.visible = false
		frame.visible = false
		placeholder_label.visible = false
		_pause_bgm_for_story_video()
		return true

	var stream := _load_first_story_video_stream([
		SECOND_DAY_BLACK_TIDE_CINEMATIC_PATH,
		SECOND_DAY_BLACK_TIDE_CINEMATIC_FALLBACK_PATH,
	])
	if stream == null:
		return false
	var video_player := VideoStreamPlayer.new()
	video_player.name = "SecondDayBlackTideCinematicVideoPlayer"
	video_player.stream = stream
	video_player.expand = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.finished.connect(func(): _finish_second_day_black_tide_cinematic(false))
	_story_video_overlay.add_child(video_player)
	_story_video_player = video_player
	_fit_control_to_16x9_cover(video_player)
	background.visible = false
	frame.visible = false
	placeholder_label.visible = false
	_pause_bgm_for_story_video()
	video_player.play()
	return true

func _finish_second_day_black_tide_cinematic(_skipped: bool = false) -> void:
	_story_web_video_active = false
	_remove_web_video(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID)
	_set_web_canvas_transparent(false)
	if is_instance_valid(_story_video_finish_timer):
		_story_video_finish_timer.stop()
	if is_instance_valid(_story_video_player):
		_story_video_player.stop()
	if is_instance_valid(_story_video_overlay):
		_story_video_overlay.queue_free()
	_story_video_finish_timer = null
	_story_video_player = null
	_story_video_overlay = null
	_resume_bgm_after_story_video()

func _pause_bgm_for_story_video() -> void:
	if _story_video_bgm_paused:
		return
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("pause_bgm"):
		audio_manager.pause_bgm()
		_story_video_bgm_paused = true

func _resume_bgm_after_story_video() -> void:
	if not _story_video_bgm_paused:
		return
	_story_video_bgm_paused = false
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("resume_bgm"):
		audio_manager.resume_bgm()

func _update_story_web_video() -> void:
	if not _story_web_video_active:
		return
	if _is_web_video_ended(WEB_SECOND_DAY_BLACK_TIDE_VIDEO_ID):
		_finish_second_day_black_tide_cinematic(false)

func _play_web_video(element_id: String, url: String, loop: bool, muted: bool, foreground: bool = false) -> bool:
	if not OS.has_feature("web") or element_id.is_empty() or url.is_empty():
		return false
	_set_web_canvas_transparent(not foreground)
	_ensure_web_video_bridge()
	var script := "window.ProjectEscapeStoryVideo.play(%s, %s, { loop: %s, muted: %s, foreground: %s, skipButton: %s });" % [
		JSON.stringify(element_id),
		JSON.stringify(url),
		_bool_to_js(loop),
		_bool_to_js(muted),
		_bool_to_js(foreground),
		_bool_to_js(foreground),
	]
	var result = JavaScriptBridge.eval(script, true)
	return result == null or bool(result)

func _remove_web_video(element_id: String) -> void:
	if not OS.has_feature("web") or element_id.is_empty():
		return
	_ensure_web_video_bridge()
	JavaScriptBridge.eval("window.ProjectEscapeStoryVideo.remove(%s);" % JSON.stringify(element_id), false)

func _is_web_video_ended(element_id: String) -> bool:
	if not OS.has_feature("web") or element_id.is_empty():
		return false
	_ensure_web_video_bridge()
	return bool(JavaScriptBridge.eval("window.ProjectEscapeStoryVideo.ended(%s);" % JSON.stringify(element_id), true))

func _set_web_canvas_transparent(enabled: bool) -> void:
	if not OS.has_feature("web"):
		return
	get_viewport().transparent_bg = enabled
	RenderingServer.set_default_clear_color(Color(0.0, 0.0, 0.0, 0.0) if enabled else Color.BLACK)
	var alpha := "0" if enabled else "1"
	JavaScriptBridge.eval("""
(function() {
	var canvas = document.getElementById('canvas');
	if (!canvas) {
		return;
	}
	canvas.style.background = 'rgba(0,0,0,%s)';
	canvas.style.position = 'relative';
	canvas.style.zIndex = '1';
	document.body.style.backgroundColor = 'black';
	document.documentElement.style.backgroundColor = 'black';
})();
""" % alpha, false)

func _ensure_web_video_bridge() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
(function() {
	if (window.ProjectEscapeStoryVideo) {
		return;
	}
	window.ProjectEscapeStoryVideo = {
		play: function(id, src, options) {
			options = options || {};
			var canvas = document.getElementById('canvas');
			var rootId = id + '-root';
			var root = document.getElementById(rootId);
			if (!root) {
				root = document.createElement('div');
				root.id = rootId;
				document.body.appendChild(root);
			}
			root.style.position = 'fixed';
			root.style.left = '0';
			root.style.top = '0';
			root.style.width = '100vw';
			root.style.height = '100vh';
			root.style.zIndex = options.foreground ? '2147483646' : '0';
			root.style.pointerEvents = 'none';
			root.style.backgroundColor = options.foreground ? '#050505' : 'transparent';
			root.style.visibility = 'visible';
			root.style.opacity = '1';
			root.style.display = 'block';
			root.style.transform = 'translateZ(0)';

			var video = document.getElementById(id);
			if (!video) {
				video = document.createElement('video');
				video.id = id;
			}
			if (options.foreground) {
				root.appendChild(video);
			} else if (canvas) {
				document.body.insertBefore(video, canvas);
			} else {
				document.body.appendChild(video);
			}
			video.dataset.projectEscapeEnded = 'false';
			video.src = src;
			video.loop = !!options.loop;
			video.muted = !!options.muted;
			video.autoplay = true;
			video.playsInline = true;
			video.preload = 'auto';
			video.controls = false;
			video.style.position = 'fixed';
			video.style.left = '0';
			video.style.top = '0';
			video.style.width = '100vw';
			video.style.height = '100vh';
			video.style.objectFit = 'cover';
			video.style.zIndex = options.foreground ? '0' : '0';
			video.style.pointerEvents = 'none';
			video.style.backgroundColor = '#050505';
			video.style.visibility = 'visible';
			video.style.opacity = '1';
			video.style.display = 'block';
			video.onended = function() {
				video.dataset.projectEscapeEnded = 'true';
			};
			video.onerror = function() {
				video.dataset.projectEscapeEnded = 'true';
				console.warn('ProjectEscape video failed: ' + src);
			};
			var promise = video.play();
			if (promise && promise.catch) {
				promise.catch(function(error) {
					console.warn('ProjectEscape video play rejected: ' + error);
					if (!options.loop) {
						video.dataset.projectEscapeEnded = 'true';
					}
				});
			}
			var skipId = id + '-skip';
			var skipButton = document.getElementById(skipId);
			if (skipButton) {
				skipButton.remove();
			}
			if (options.skipButton) {
				skipButton = document.createElement('button');
				skipButton.id = skipId;
				skipButton.type = 'button';
				skipButton.textContent = '\u8df3\u8fc7\u5f71\u50cf';
				skipButton.style.position = 'fixed';
				skipButton.style.right = '36px';
				skipButton.style.bottom = '34px';
				skipButton.style.zIndex = '2147483647';
				skipButton.style.pointerEvents = 'auto';
				skipButton.style.padding = '9px 18px';
				skipButton.style.border = '1px solid rgba(233, 216, 158, 0.78)';
				skipButton.style.borderRadius = '2px';
				skipButton.style.background = 'rgba(8, 8, 8, 0.72)';
				skipButton.style.color = '#f1e7bd';
				skipButton.style.font = '16px sans-serif';
				skipButton.style.cursor = 'pointer';
				skipButton.onclick = function() {
					video.dataset.projectEscapeEnded = 'true';
					video.pause();
				};
				document.body.appendChild(skipButton);
			}
			return true;
		},
		remove: function(id) {
			var skipButton = document.getElementById(id + '-skip');
			if (skipButton) {
				skipButton.remove();
			}
			var video = document.getElementById(id);
			if (video) {
				video.pause();
				video.removeAttribute('src');
				video.load();
				video.remove();
			}
			var root = document.getElementById(id + '-root');
			if (root) {
				root.remove();
			}
		},
		ended: function(id) {
			var video = document.getElementById(id);
			return !video || video.dataset.projectEscapeEnded === 'true' || video.ended;
		}
	};
})();
""", false)

func _bool_to_js(value: bool) -> String:
	return "true" if value else "false"

func _res_path_to_web_url(path: String) -> String:
	if path.begins_with("res://"):
		return path.trim_prefix("res://")
	return path

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
	var sequence: Dictionary = dialogue_service.load_sequence(path)
	if sequence.is_empty():
		push_warning("Run story dialogue sequence is missing: %s" % path)
		return
	var panel = DialoguePanelScene.instantiate()
	panel.name = "RunStoryDialoguePanel"
	_active_story_dialogue_panel = panel
	ui_root.add_child(panel)
	var dialogue_finished := false
	panel.dialogue_finished.connect(func(_dialogue_id: String, _skipped: bool):
		dialogue_finished = true
	)
	panel.tree_exiting.connect(func():
		if _active_story_dialogue_panel == panel:
			_active_story_dialogue_panel = null
	)
	panel.play_sequence(sequence)
	while not dialogue_finished and is_instance_valid(panel):
		await get_tree().process_frame
	if _active_story_dialogue_panel == panel:
		_active_story_dialogue_panel = null

func _acquire_story_pause(token: String) -> void:
	if token.is_empty():
		return
	var was_paused := _is_story_paused()
	_story_pause_tokens[token] = true
	if not was_paused:
		_apply_story_pause_state(true)

func _release_story_pause(token: String) -> void:
	if token.is_empty():
		return
	_story_pause_tokens.erase(token)
	if _story_pause_tokens.is_empty():
		_apply_story_pause_state(false)

func _apply_story_pause_state(paused: bool) -> void:
	_extract_button_held = false
	if paused:
		if interaction_progress_controller != null and interaction_progress_controller.is_active():
			interaction_progress_controller.cancel()
			_end_player_interact_animation()
		_audio_manager_call("stop_container_open_loop")
	if player != null and is_instance_valid(player):
		player.set_physics_process(not paused)
		if paused:
			if player is CharacterBody2D:
				player.velocity = Vector2.ZERO
			if player.has_method("end_interact_animation"):
				player.end_interact_animation()
	_set_story_simulation_nodes_paused(paused)

func _set_story_simulation_nodes_paused(paused: bool) -> void:
	if run_director != null and run_director.stability_component != null:
		run_director.stability_component.set_process(not paused)
	if monster_spawn_controller != null:
		for monster in monster_spawn_controller.get_active_monsters():
			if monster != null and is_instance_valid(monster):
				monster.set_process(not paused)
		var pending_respawn_timers: Dictionary = monster_spawn_controller.get("_pending_respawn_timers")
		for timer in pending_respawn_timers.values():
			if timer is Timer and is_instance_valid(timer):
				timer.paused = paused

func _is_story_paused() -> bool:
	return not _story_pause_tokens.is_empty()

func is_run_story_paused() -> bool:
	return _is_story_paused()

func _refresh_story_video_cover() -> void:
	if is_instance_valid(_story_video_player):
		_fit_control_to_16x9_cover(_story_video_player)

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

func _update_run_timer(delta: float) -> void:
	if run_timer_controller != null:
		run_timer_controller.update(delta)

func _on_run_time_expired() -> void:
	if _is_settlement_flow_active():
		return
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		interaction_progress_controller.cancel()
		_end_player_interact_animation()
	if run_end_controller != null:
		var result: Dictionary = run_end_controller.handle_timeout(get_tree(), "time_expired")
		if bool(result.get("accepted", false)):
			var run_result: Dictionary = result.get("result", {})
			_show_settlement_result(run_result)
		else:
			_status_prompt = String(result.get("message", ""))
			_refresh_ui()
	else:
		_show_settlement_result({
			"result_type": "TIMEOUT_FAILED",
			"reason": "time_expired",
			"warehouse_items": [],
			"lost_items": [],
			"message": "探索失败：对局时间耗尽。",
		})

func _spawn_initial_containers() -> void:
	if container_spawn_controller == null:
		return
	container_spawn_controller.spawn_initial()

func _spawn_container(pos: Vector2) -> void:
	if container_spawn_controller == null:
		return
	container_spawn_controller.spawn_container(pos)

func _spawn_selected_outposts() -> void:
	var context = run_director.context
	if context == null:
		return
	outpost_requirements.clear()
	outpost_safe_zones.clear()
	if outpost_visual_anchors.is_empty():
		_setup_outpost_visual_anchors()
	_reset_outpost_visual_anchors()
	var first_id: String = context.selected_first_outpost_id
	var second_id: String = context.selected_second_outpost_id
	if outpost_material_spawn_controller:
		outpost_requirements = outpost_material_spawn_controller.build_requirements(first_id, second_id, int(context.seed))
	for outpost_id in [first_id, second_id]:
		var pos: Vector2 = context.selected_outpost_positions.get(outpost_id, Vector2.ZERO)
		var footprint_units := _get_outpost_footprint_units(outpost_id)
		var station = _make_interactable(outpost_id, "outpost", "前哨站 %s" % outpost_id, pos, Color(0.45, 0.24, 0.10), footprint_units)
		station.payload = {
			"repaired": false,
			"repair_state": "UNREPAIRED",
			"requirements": outpost_requirements[outpost_id],
			"delivered_materials": {},
			"footprint_units": footprint_units,
		}
		_sync_outpost_visual_anchor(station)
		interactable_visual_builder.refresh_outpost_requirement_bubbles(station, Callable(self, "_inventory_count"))
		_attach_outpost_safe_zone(station)
		outpost_root.add_child(station)

func _spawn_requirement_materials() -> void:
	if run_director.context == null or outpost_material_spawn_controller == null:
		return
	outpost_material_spawn_controller.spawn_for_outposts(
		outpost_requirements,
		run_director.context.selected_outpost_positions
	)

func _spawn_monsters_for_run() -> void:
	if monster_spawn_controller == null or run_director.context == null:
		return
	monster_spawn_controller.spawn_for_context(run_director.context)

func _get_material_points_for_outpost(base_pos: Vector2, count: int) -> Array:
	var points := _get_material_spawn_points()
	points.sort_custom(func(a, b): return a.global_position.distance_squared_to(base_pos) < b.global_position.distance_squared_to(base_pos))
	return points.slice(0, count)

func _get_container_spawn_points() -> Array:
	return _get_layout_points("ContainerSpawnPoints")

func _get_material_spawn_points() -> Array:
	return _get_layout_points("MaterialSpawnPoints")

func _get_monster_spawn_points() -> Array:
	return _get_layout_points("MonsterSpawnPoints")

func _make_interactable(id: String, type: String, label_text: String, pos: Vector2, color: Color, size_units: Vector2 = Vector2.ZERO, visual_data: Dictionary = {}):
	var area := Area2D.new()
	area.name = id
	area.script = InteractableScript
	area.interact_id = id
	area.interact_type = type
	area.display_name = label_text
	area.position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ((maxf(size_units.x, size_units.y) * 0.6) if (type == "outpost" or type == "container") and size_units != Vector2.ZERO else (6.0 if type == "outpost" else 2.0)) * UNIT
	shape.shape = circle
	area.add_child(shape)
	var visual_size: Vector2 = interactable_visual_builder.add_interactable_visual(area, type, label_text, color, size_units, visual_data)
	if type != "container" and type != "material":
		var label: Label = interactable_visual_builder.make_world_label(label_text, Vector2(-visual_size.x * 0.5, -visual_size.y * 0.5 - 42), area)
		label.z_index = 20
	area.player_entered.connect(_on_interactable_entered)
	area.player_exited.connect(_on_interactable_exited)
	interactables.append(area)
	return area

func _attach_outpost_safe_zone(station) -> void:
	var footprint_units: Vector2 = station.payload.get("footprint_units", OUTPOST_SIZE_UNITS)
	var safe_zone := Area2D.new()
	safe_zone.name = "%s_SafeZoneArea_%sx%s" % [station.interact_id, int(round(footprint_units.x)), int(round(footprint_units.y))]
	safe_zone.set_meta("outpost_id", station.interact_id)
	safe_zone.set_meta("player_inside", false)
	safe_zone.monitoring = true
	safe_zone.monitorable = false
	var collision := CollisionShape2D.new()
	collision.name = "SafeZoneCollision_%sx%s" % [int(round(footprint_units.x)), int(round(footprint_units.y))]
	var rect := RectangleShape2D.new()
	rect.size = _u(footprint_units)
	collision.shape = rect
	safe_zone.add_child(collision)
	safe_zone.body_entered.connect(func(body): _on_outpost_safe_zone_body_entered(station, body))
	safe_zone.body_exited.connect(func(body): _on_outpost_safe_zone_body_exited(station, body))
	station.add_child(safe_zone)
	outpost_safe_zones[station.interact_id] = safe_zone

func _get_outpost_footprint_units(outpost_id: String) -> Vector2:
	if run_director.context != null:
		var context_footprint = run_director.context.selected_outpost_footprints.get(outpost_id, Vector2.ZERO)
		if context_footprint is Vector2 and context_footprint != Vector2.ZERO:
			return context_footprint
	for point in _get_outpost_candidate_points():
		if point.has_method("get_candidate_id") and point.get_candidate_id() == outpost_id:
			if point.has_method("get_footprint_units"):
				return point.get_footprint_units()
	return OUTPOST_SIZE_UNITS

func _on_interactable_entered(node) -> void:
	nearest_interactable = node
	_status_prompt = ""
	_refresh_ui()

func _on_interactable_exited(node) -> void:
	if nearest_interactable == node:
		nearest_interactable = null
	if opened_container == node:
		_close_loot_transfer()
	if interaction_progress_controller != null and interaction_progress_controller.is_target(node):
		var interaction_id: String = interaction_progress_controller.active_id
		interaction_progress_controller.cancel()
		_end_player_interact_animation()
		_status_prompt = _interaction_cancel_message(interaction_id)
	_refresh_ui()

func _on_outpost_safe_zone_body_entered(station, body: Node) -> void:
	if not _is_player_body(body):
		return
	var safe_zone: Area2D = _get_outpost_safe_zone(station)
	if safe_zone:
		safe_zone.set_meta("player_inside", true)
	if _is_repaired_outpost(station):
		_enter_repaired_outpost_safe_zone(station)
	_refresh_ui()

func _on_outpost_safe_zone_body_exited(station, body: Node) -> void:
	if not _is_player_body(body):
		return
	var safe_zone: Area2D = _get_outpost_safe_zone(station)
	if safe_zone:
		safe_zone.set_meta("player_inside", false)
	if _is_repaired_outpost(station):
		_exit_repaired_outpost_safe_zone(station)
		_close_outpost_storage_ui(station.interact_id)
	_refresh_ui()

func _is_player_body(body: Node) -> bool:
	return body != null and (body.is_in_group("player") or body.name == "Player")

func _try_interact() -> void:
	if _is_story_paused():
		return
	if nearest_interactable == null:
		return
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		return
	match nearest_interactable.interact_type:
		"container":
			_begin_container_open(nearest_interactable)
		"material":
			_pick_material(nearest_interactable)
		"outpost":
			_begin_outpost_repair(nearest_interactable)

func _begin_player_interact_animation(_target = null) -> void:
	if player != null and player.has_method("begin_interact_animation"):
		player.begin_interact_animation(true)

func _play_player_interact_once(_target = null) -> void:
	if player != null and player.has_method("play_interact_once"):
		player.play_interact_once()

func _end_player_interact_animation() -> void:
	if player != null and player.has_method("end_interact_animation"):
		player.end_interact_animation()

func _begin_container_open(container) -> void:
	if _is_story_paused():
		return
	if interaction_progress_controller == null:
		_open_container(container)
		return
	if not is_instance_valid(container):
		return
	if container.payload.get("state", "") == "depleted" or (
		bool(container.payload.get("loot_generated", false))
		and container.payload.get("rewards", []).is_empty()
	):
		_status_prompt = "容器已不可开启。"
		_refresh_ui()
		return
	_set_container_lifetime_paused(container, true)
	if interaction_progress_controller.begin(
		"open_container",
		container,
		float(container.payload.get("open_time", CONTAINER_OPEN_HOLD_SECONDS)),
		Callable(self, "_complete_held_container_open"),
		Callable(self, "_cancel_held_container_open")
	):
		_status_prompt = ""
		_begin_player_interact_animation(container)
		_audio_manager_call("start_container_open_loop")
	_refresh_ui()

func _complete_held_container_open(container) -> void:
	_audio_manager_call("stop_container_open_loop")
	_open_container(container)
	_audio_manager_call("play_container_open_complete")
	_status_prompt = "容器已打开。"

func _cancel_held_container_open(container) -> void:
	_audio_manager_call("stop_container_open_loop")
	_set_container_lifetime_paused(container, false)

func _open_container(container) -> void:
	if container_spawn_controller != null:
		container_spawn_controller.ensure_container_rewards(container)
	if not loot_interaction_controller.open_container(container):
		_set_container_lifetime_paused(container, false)
		prompt_label.text = loot_interaction_controller.last_prompt
		return
	_set_container_lifetime_paused(container, true)
	_play_player_interact_once(container)
	_sync_loot_state()
	_open_loot_transfer_panels()
	_refresh_ui()

func _pick_material(pickup) -> void:
	if _is_story_paused():
		return
	var pickup_outpost_id := String(pickup.payload.get("outpost_id", "")) if pickup != null and is_instance_valid(pickup) else ""
	if loot_interaction_controller.pick_material_immediate(
		pickup,
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	):
		_play_player_interact_once(pickup)
		_set_timed_status_prompt(run_ui_controller.outpost_material_pickup_prompt(self, pickup_outpost_id), 1.8)
	else:
		_status_prompt = loot_interaction_controller.last_prompt
	_refresh_ui()

func _take_all_loot() -> void:
	if _is_story_paused():
		return
	var transfer_finished: bool = loot_interaction_controller.take_all_loot(
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	)
	_sync_loot_state()
	if transfer_finished:
		loot_panel.visible = false
		inventory_panel.visible = false
		_set_container_lifetime_paused(opened_container, false)
	_refresh_ui()

func _on_loot_item_meta_clicked(meta: Variant) -> void:
	var index := _item_meta_index(meta, "loot")
	if index >= 0:
		_take_loot_item_at(index)

func _on_inventory_item_meta_clicked(meta: Variant) -> void:
	var index := _item_meta_index(meta, "inventory")
	if index >= 0:
		_select_inventory_item_at(index)

func _on_home_storage_item_meta_clicked(meta: Variant) -> void:
	var index := _item_meta_index(meta, "storage")
	if index < 0:
		index = _item_meta_index(meta, "home")
	if index >= 0:
		if has_selected_inventory_item():
			_deposit_inventory_item_at(index, selected_inventory_index)
		else:
			_withdraw_active_storage_item_at(index)

func _take_loot_item_at(index: int) -> void:
	if _is_story_paused():
		return
	var result: Dictionary = loot_interaction_controller.take_loot_at(
		index,
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	)
	_sync_loot_state()
	if bool(result.get("accepted", false)):
		_status_prompt = "已放入背包：%s" % result.item.get("display_name", result.item.get("item_id", ""))
		if bool(result.get("finished", false)):
			loot_panel.visible = false
			_set_container_lifetime_paused(opened_container, false)
	else:
		_status_prompt = loot_interaction_controller.last_prompt
	_refresh_ui()

func _deposit_inventory_item_at(index: int, inventory_index: int = -1) -> void:
	if _is_story_paused():
		return
	var result: Dictionary
	var storage_name := _active_storage_display_name()
	var source_inventory_index := inventory_index if inventory_index >= 0 else index
	var target_storage_index := index if inventory_index >= 0 else -1
	if _is_active_outpost_storage():
		result = run_director.deposit_inventory_item_to_outpost(active_outpost_storage_id, source_inventory_index, target_storage_index)
	else:
		result = run_director.deposit_inventory_item_to_home_by_selection(source_inventory_index, target_storage_index)
	if bool(result.get("accepted", false)):
		if selected_inventory_index == source_inventory_index:
			selected_inventory_index = -1
		_status_prompt = "已存入%s：%s" % [storage_name, result.item.get("display_name", result.item.get("item_id", ""))]
	else:
		_status_prompt = _selection_transfer_reason_text(str(result.get("reason", "")))
		_sync_inventory_selection_state()
	_refresh_ui()

func _select_inventory_item_at(index: int) -> void:
	if _is_story_paused():
		return
	if run_director == null or run_director.inventory_component == null:
		selected_inventory_index = -1
		_status_prompt = "背包不可用。"
		_refresh_ui()
		return
	if index < 0 or index >= run_director.inventory_component.items.size():
		selected_inventory_index = -1
		_status_prompt = "道具不可用。"
		_refresh_ui()
		return
	selected_inventory_index = index
	var item: Dictionary = run_director.inventory_component.items[index]
	_status_prompt = "已选中：%s" % item.get("display_name", item.get("item_id", ""))
	_refresh_ui()

func _discard_selected_inventory_item() -> void:
	if _is_story_paused():
		return
	if not has_selected_inventory_item():
		_status_prompt = "请先选择背包道具。"
		_refresh_ui()
		return
	var result: Dictionary = run_director.discard_inventory_item_at(selected_inventory_index)
	if bool(result.get("accepted", false)):
		selected_inventory_index = -1
		_status_prompt = "已丢弃：%s" % result.item.get("display_name", result.item.get("item_id", ""))
	else:
		_status_prompt = _inventory_discard_reason_text(str(result.get("reason", "")))
		_sync_inventory_selection_state()
	_refresh_ui()

func has_selected_inventory_item() -> bool:
	return not _selected_inventory_item().is_empty()

func selected_inventory_item_summary() -> String:
	var item := _selected_inventory_item()
	if item.is_empty():
		return ""
	return "已选：%s" % item.get("display_name", item.get("item_id", ""))

func _selected_inventory_item() -> Dictionary:
	if run_director == null or run_director.inventory_component == null:
		return {}
	if selected_inventory_index < 0 or selected_inventory_index >= run_director.inventory_component.items.size():
		return {}
	return run_director.inventory_component.items[selected_inventory_index]

func _sync_inventory_selection_state() -> void:
	if selected_inventory_index < 0:
		return
	if inventory_panel == null or not inventory_panel.visible or _selected_inventory_item().is_empty():
		selected_inventory_index = -1

func _inventory_discard_reason_text(reason: String) -> String:
	match reason:
		"missing_inventory":
			return "背包不可用。"
		"invalid_item":
			return "道具不可用。"
		_:
			return "无法丢弃该道具。"

func _withdraw_active_storage_item_at(index: int) -> void:
	if _is_story_paused():
		return
	var result: Dictionary
	if _is_active_outpost_storage():
		result = run_director.withdraw_outpost_storage_item_to_inventory(active_outpost_storage_id, index)
	else:
		result = run_director.withdraw_home_storage_item_to_inventory(index)
	if bool(result.get("accepted", false)):
		_status_prompt = "已放入背包：%s" % result.item.get("display_name", result.item.get("item_id", ""))
	else:
		_status_prompt = _selection_transfer_reason_text(str(result.get("reason", "")))
	_refresh_ui()

func _item_meta_index(meta: Variant, expected_source: String) -> int:
	var parts := String(meta).split(":")
	if parts.size() != 2 or parts[0] != expected_source:
		return -1
	return int(parts[1])

func _selection_transfer_reason_text(reason: String) -> String:
	match reason:
		"not_home":
			return "请回到家中整理物品。"
		"not_outpost":
			return "请进入已修复前哨站整理物品。"
		"outpost_inactive":
			return "前哨站尚未修复，无法存储。"
		"outpost_storage_locked":
			return "前哨站安全箱尚未研究。"
		"storage_rejected":
			return "%s空间不足。" % _active_storage_display_name()
		"inventory_rejected":
			return "背包空间或负重不足。"
		"invalid_item":
			return "道具不可用。"
		_:
			return "无法移动该道具。"

func _open_loot_transfer_panels() -> void:
	_set_container_lifetime_paused(opened_container, true)
	loot_panel.visible = true
	inventory_panel.visible = true

func _close_loot_transfer() -> void:
	_set_container_lifetime_paused(opened_container, false)
	loot_interaction_controller.close()
	_sync_loot_state()
	loot_panel.visible = false
	inventory_panel.visible = false

func _save_opened_loot_to_source() -> void:
	loot_interaction_controller.save_opened_loot_to_source()
	_sync_loot_state()

func _set_container_lifetime_paused(container, paused: bool) -> void:
	if container == null or not is_instance_valid(container):
		return
	if container.get("interact_type") != "container":
		return
	container.payload["lifetime_paused"] = paused

func _sync_loot_state() -> void:
	if loot_interaction_controller == null:
		opened_container = null
		opened_loot = []
		return
	opened_container = loot_interaction_controller.opened_interactable
	opened_loot = loot_interaction_controller.opened_loot

func _begin_outpost_repair(station) -> void:
	if _is_story_paused():
		return
	if interaction_progress_controller == null or outpost_repair_controller == null:
		_try_repair_outpost(station)
		return
	var validation: Dictionary = outpost_repair_controller.can_repair(station)
	if not validation.accepted:
		_status_prompt = validation.message
		_refresh_ui()
		return
	if interaction_progress_controller.begin(
		"repair_outpost",
		station,
		OUTPOST_REPAIR_HOLD_SECONDS,
		Callable(self, "_complete_held_outpost_repair"),
		Callable(self, "_cancel_held_outpost_repair")
	):
		_status_prompt = ""
		_begin_player_interact_animation(station)
		outpost_repair_controller.mark_repairing(station)
	_refresh_ui()

func _complete_held_outpost_repair(station) -> void:
	_try_repair_outpost(station)

func _cancel_held_outpost_repair(station) -> void:
	if outpost_repair_controller != null:
		outpost_repair_controller.cancel_repairing(station)

func _update_active_interaction(delta: float) -> void:
	if interaction_progress_controller == null or not interaction_progress_controller.is_active():
		return
	var target = interaction_progress_controller.active_target
	var interaction_id: String = interaction_progress_controller.active_id
	var should_continue: bool = _should_continue_active_interaction(interaction_id, target)
	var result: Dictionary = interaction_progress_controller.update(delta, should_continue)
	if bool(result.get("cancelled", false)):
		_end_player_interact_animation()
		_status_prompt = _interaction_cancel_message(interaction_id)
	elif bool(result.get("completed", false)):
		_end_player_interact_animation()
		if _status_prompt.is_empty():
			_status_prompt = _interaction_complete_message(interaction_id)

func _set_timed_status_prompt(text: String, seconds: float) -> void:
	_status_prompt = text
	_timed_status_prompt_text = text
	_status_prompt_clear_time_msec = Time.get_ticks_msec() + int(maxf(0.0, seconds) * 1000.0)

func _update_status_prompt_timeout() -> void:
	if _status_prompt.is_empty():
		_timed_status_prompt_text = ""
		_status_prompt_clear_time_msec = 0
		return
	if _status_prompt_clear_time_msec <= 0 or _status_prompt != _timed_status_prompt_text:
		_timed_status_prompt_text = _status_prompt
		_status_prompt_clear_time_msec = Time.get_ticks_msec() + int(STATUS_PROMPT_VISIBLE_SECONDS * 1000.0)
		return
	if Time.get_ticks_msec() < _status_prompt_clear_time_msec:
		return
	if _status_prompt == _timed_status_prompt_text:
		_status_prompt = ""
	_timed_status_prompt_text = ""
	_status_prompt_clear_time_msec = 0

func _should_continue_active_interaction(interaction_id: String, target) -> bool:
	match interaction_id:
		"open_container", "repair_outpost":
			return (
				Input.is_action_pressed("interact")
				and nearest_interactable == target
				and is_instance_valid(target)
			)
		"extract":
			return _is_extraction_hold_pressed() and _can_continue_extraction_hold()
		_:
			return false

func _is_extraction_hold_pressed() -> bool:
	if _is_story_paused():
		return false
	return Input.is_action_pressed("extract") or _extract_button_held

func _can_continue_extraction_hold() -> bool:
	return (
		not _is_story_paused()
		and run_director != null
		and run_director.context != null
		and run_director.context.is_extraction_unlocked
		and run_director.context.active_safe_zone_id == "home"
	)

func _interaction_cancel_message(interaction_id: String) -> String:
	match interaction_id:
		"open_container":
			return "开箱中断。"
		"repair_outpost":
			return "修复中断。"
		"extract":
			return "撤离中断。"
		_:
			return "交互中断。"

func _interaction_complete_message(interaction_id: String) -> String:
	match interaction_id:
		"open_container":
			return "容器已打开。"
		"repair_outpost":
			return "前哨站修复完成。"
		"extract":
			return "撤离完成。"
		_:
			return "交互完成。"

func _try_repair_outpost(station) -> void:
	var result: Dictionary = outpost_repair_controller.repair(station)
	_status_prompt = result.message
	if bool(result.get("activated", false)):
		_audio_manager_call("play_outpost_repair_complete")
		_activate_outpost_safe_zone(station)
		if run_director.get_outpost_storage_capacity(station.interact_id) > 0:
			run_director.ensure_outpost_storage(station.interact_id)
	if bool(result.get("activated", false)) and _is_player_inside_outpost_safe_zone(station):
		_enter_repaired_outpost_safe_zone(station)
	_update_outpost_requirement_bubbles()
	_refresh_ui()

func _is_repaired_outpost(node) -> bool:
	return (
		node != null
		and is_instance_valid(node)
		and node.interact_type == "outpost"
		and bool(node.payload.get("repaired", false))
	)

func _enter_repaired_outpost_safe_zone(station) -> void:
	if run_director.context == null:
		return
	if run_director.context.active_safe_zone_id == station.interact_id:
		return
	run_director.on_safe_zone_entered(station.interact_id)
	_play_run_safe_house_bgm()
	if run_director.get_outpost_storage_capacity(station.interact_id) > 0:
		run_director.ensure_outpost_storage(station.interact_id)
		active_outpost_storage_id = station.interact_id
		home_storage_user_closed = false
		_status_prompt = "前哨站安全区：稳定值正在恢复，安全箱已开启。"
	else:
		active_outpost_storage_id = ""
		_status_prompt = "前哨站安全区：稳定值正在恢复，安全箱尚未研究。"

func _exit_repaired_outpost_safe_zone(station) -> void:
	if run_director.context == null:
		return
	if run_director.context.active_safe_zone_id != station.interact_id:
		return
	run_director.on_safe_zone_exited(station.interact_id)
	_play_run_exploration_bgm()

func _activate_outpost_safe_zone(station) -> void:
	var safe_zone: Area2D = _get_outpost_safe_zone(station)
	if safe_zone == null:
		return
	safe_zone.set_meta("is_active_after_repair", true)

func _get_outpost_safe_zone(station) -> Area2D:
	if station == null or not is_instance_valid(station):
		return null
	return outpost_safe_zones.get(station.interact_id, null)

func _is_player_inside_outpost_safe_zone(station) -> bool:
	var safe_zone: Area2D = _get_outpost_safe_zone(station)
	if safe_zone and bool(safe_zone.get_meta("player_inside", false)):
		return true
	if player == null or station == null or not is_instance_valid(station):
		return false
	var local_pos: Vector2 = station.to_local(player.global_position)
	var footprint_units: Vector2 = station.payload.get("footprint_units", OUTPOST_SIZE_UNITS)
	var footprint_size: Vector2 = _u(footprint_units)
	return Rect2(footprint_size * -0.5, footprint_size).has_point(local_pos)

func _has_requirements(requirements: Dictionary) -> bool:
	return outpost_repair_controller.has_requirements(requirements)

func _missing_requirements_text(requirements: Dictionary) -> String:
	return outpost_repair_controller.missing_requirements_text(requirements)

func _inventory_count(item_id: String) -> int:
	return outpost_repair_controller.inventory_count(item_id)

func _deposit_all() -> void:
	if _is_story_paused():
		return
	if not is_storage_zone_active():
		prompt_label.text = "请进入家中或已修复前哨站存放物品。"
		return
	if has_selected_inventory_item():
		_deposit_inventory_item_at(selected_inventory_index)
		return
	var index := 0
	while index < run_director.inventory_component.items.size():
		var moved := false
		if _is_active_outpost_storage():
			moved = bool(run_director.deposit_inventory_item_to_outpost(active_outpost_storage_id, index).get("accepted", false))
		else:
			moved = run_director.deposit_inventory_item_to_home(index)
		if not moved:
			index += 1
	_refresh_ui()

func is_storage_zone_active() -> bool:
	return (
		run_director != null
		and run_director.context != null
		and (
			run_director.context.active_safe_zone_id == "home"
			or _is_active_outpost_storage()
		)
	)

func is_home_storage_active() -> bool:
	return run_director != null and run_director.context != null and run_director.context.active_safe_zone_id == "home"

func _is_active_outpost_storage() -> bool:
	return (
		not active_outpost_storage_id.is_empty()
		and run_director != null
		and run_director.context != null
		and run_director.context.active_safe_zone_id == active_outpost_storage_id
		and run_director.context.active_safe_zone_type == "outpost"
	)

func get_active_storage_items_snapshot() -> Array:
	if _is_active_outpost_storage():
		return run_director.get_outpost_storage_slots_snapshot(active_outpost_storage_id)
	if run_director.home_storage_component != null:
		return run_director.home_storage_component.get_slots_snapshot()
	return []

func get_active_storage_source_id() -> String:
	return "storage"

func get_active_storage_title() -> String:
	if _is_active_outpost_storage():
		return "前哨存储"
	return "家中存储"

func _active_storage_display_name() -> String:
	return "前哨" if _is_active_outpost_storage() else "家中"

func _close_outpost_storage_ui(outpost_id: String) -> void:
	if active_outpost_storage_id != outpost_id:
		return
	active_outpost_storage_id = ""
	home_storage_user_closed = false
	home_storage_panel.visible = false
	if not loot_panel.visible:
		inventory_panel.visible = false

func _try_extract() -> void:
	if _is_story_paused():
		return
	_begin_extraction_hold()

func _begin_extraction_hold_from_button() -> void:
	if _is_story_paused():
		return
	_extract_button_held = true
	_begin_extraction_hold()

func _release_extraction_hold_button() -> void:
	_extract_button_held = false

func _begin_extraction_hold() -> void:
	if _is_story_paused():
		_extract_button_held = false
		return
	if run_end_controller == null:
		return
	if _is_run_terminal():
		return
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		return
	var validation: Dictionary = run_end_controller.validate_extraction()
	if not validation.accepted:
		_status_prompt = validation.message
		_refresh_ui()
		return
	if interaction_progress_controller == null:
		_complete_held_extract(run_director)
		return
	if interaction_progress_controller.begin(
		"extract",
		run_director,
		EXTRACTION_HOLD_SECONDS,
		Callable(self, "_complete_held_extract"),
		Callable(self, "_cancel_held_extract")
	):
		_status_prompt = ""
		run_director.on_extraction_started()
		_begin_player_interact_animation()
	_refresh_ui()

func _complete_held_extract(_target) -> void:
	if run_end_controller == null:
		return
	var result: Dictionary = run_end_controller.try_extract(get_tree())
	if bool(result.get("accepted", false)):
		_audio_manager_call("play_extraction_success_cue")
		if run_timer_controller != null:
			run_timer_controller.stop()
		_extract_button_held = false
		var run_result: Dictionary = result.get("result", {})
		_show_settlement_result(run_result)
	if not result.accepted:
		_status_prompt = result.message
		_refresh_ui()

func _cancel_held_extract(_target) -> void:
	_extract_button_held = false
	if run_director != null and _is_current_run_phase("EXTRACT"):
		run_director.on_extraction_interrupted()

func _is_current_run_phase(phase_name: String) -> bool:
	if run_director == null or run_director.state_machine == null:
		return false
	return RunStateMachine.phase_name(run_director.state_machine.current_phase) == phase_name

func _is_run_terminal() -> bool:
	if run_director == null or run_director.state_machine == null:
		return false
	var phase_name: String = RunStateMachine.phase_name(run_director.state_machine.current_phase)
	return phase_name in ["SETTLEMENT", "FAILED"]

func _is_settlement_flow_active() -> bool:
	return (
		(settlement_result_screen != null and is_instance_valid(settlement_result_screen))
		or (return_to_base_loading_screen != null and is_instance_valid(return_to_base_loading_screen))
	)

func _show_settlement_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	if _is_settlement_flow_active():
		return
	_pending_run_result = result.duplicate(true)
	_status_prompt = ""
	_timed_status_prompt_text = ""
	_status_prompt_clear_time_msec = 0
	home_storage_panel.visible = false
	inventory_panel.visible = false
	loot_panel.visible = false
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		interaction_progress_controller.cancel()
		_end_player_interact_animation()
	settlement_result_screen = SettlementResultScreenScript.new()
	ui_root.add_child(settlement_result_screen)
	settlement_result_screen.return_to_base_requested.connect(_begin_return_to_base_loading)
	settlement_result_screen.show_result(_pending_run_result)

func _begin_return_to_base_loading() -> void:
	if _pending_run_result.is_empty():
		return
	if settlement_result_screen != null and is_instance_valid(settlement_result_screen):
		settlement_result_screen.queue_free()
	settlement_result_screen = null
	return_to_base_loading_screen = ReturnToBaseLoadingScreenScript.new()
	ui_root.add_child(return_to_base_loading_screen)
	return_to_base_loading_screen.return_failed.connect(_on_return_to_base_loading_failed)
	return_to_base_loading_screen.begin_return(_pending_run_result, _game_state)

func _on_return_to_base_loading_failed(reason: String) -> void:
	_status_prompt = "返回哨所失败：%s" % reason

func _on_stability_changed(current: float, _max_value: float, _stage: int) -> void:
	_audio_manager_call("set_stability_critical_loop_active", [current > 0.0 and _stage >= 3])
	if current <= 0.0:
		call_deferred("_return_to_base_after_death", "stability_depleted")

func _return_to_base_after_death(reason: String = "stability_depleted") -> void:
	if _is_settlement_flow_active():
		return
	_audio_manager_call("set_stability_critical_loop_active", [false])
	_audio_manager_call("play_player_death_cue")
	if run_timer_controller != null:
		run_timer_controller.stop()
	if run_end_controller:
		var result: Dictionary = run_end_controller.handle_player_death(get_tree(), reason)
		if bool(result.get("accepted", false)):
			var run_result: Dictionary = result.get("result", {})
			_show_settlement_result(run_result)
		else:
			_status_prompt = String(result.get("message", ""))
			_refresh_ui()
	else:
		_show_settlement_result({
			"result_type": "DEAD",
			"reason": reason,
			"warehouse_items": [],
			"lost_items": [],
			"message": "探索失败：稳定值耗尽。",
		})

func _on_weight_changed(_current_weight: float, _max_weight: float, _stage: int) -> void:
	if player and run_director.weight_component:
		player.speed_multiplier = run_director.weight_component.speed_multiplier

func _refresh_ui() -> void:
	if _ui_refresh_queued:
		return
	_ui_refresh_queued = true
	call_deferred("_flush_ui_refresh")

func _flush_ui_refresh() -> void:
	_ui_refresh_queued = false
	if not is_inside_tree():
		return
	_sync_inventory_selection_state()
	run_ui_controller.refresh(self)

func _item(id: String, display_name: String, amount: int, weight: float, _stack_limit: int) -> Dictionary:
	return {
		"item_id": id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
	}

func _random_container_position() -> Vector2:
	if container_spawn_controller == null:
		return _u(Vector2(18.0 + randf() * 98.0, -42.0 + randf() * 84.0))
	return container_spawn_controller.next_spawn_position()

func _toggle_inventory_panel() -> void:
	if _is_story_paused():
		return
	run_ui_controller.toggle_inventory(self)

func _switch_camera_home() -> void:
	_play_run_safe_house_bgm()
	_tween_camera(_home_overview_zoom(), _home_overview_offset())

func _switch_camera_follow() -> void:
	_play_run_exploration_bgm()
	_tween_camera(PLAYER_FOLLOW_ZOOM, Vector2.ZERO)

func _play_run_safe_house_bgm() -> void:
	_audio_manager_call("play_run_safe_house_bgm")

func _play_run_exploration_bgm() -> void:
	_audio_manager_call("play_run_exploration_bgm")

func _audio_manager_call(method_name: String, args: Array = []) -> Variant:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null or not audio_manager.has_method(method_name):
		return null
	return audio_manager.callv(method_name, args)

func _tween_camera(target_zoom: Vector2, target_position: Vector2) -> void:
	if camera == null:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(camera, "zoom", target_zoom, CAMERA_TRANSITION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(camera, "position", target_position, CAMERA_TRANSITION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _home_overview_zoom() -> Vector2:
	var viewport_size := _camera_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2(HOME_OVERVIEW_MAX_ZOOM, HOME_OVERVIEW_MAX_ZOOM)
	var focus_bounds := _home_overview_bounds()
	var zoom_value := minf(viewport_size.x / focus_bounds.size.x, viewport_size.y / focus_bounds.size.y)
	zoom_value = clampf(zoom_value, HOME_OVERVIEW_MIN_ZOOM, HOME_OVERVIEW_MAX_ZOOM)
	return Vector2(zoom_value, zoom_value)

func _home_overview_offset() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return _home_overview_bounds().get_center() - player.global_position

func _home_overview_bounds() -> Rect2:
	var map_bounds := _map_bounds_px()
	var padding: Vector2 = _u(HOME_OVERVIEW_PADDING_UNITS)
	return Rect2(map_bounds.position - padding, map_bounds.size + padding * 2.0)

func _map_bounds_px() -> Rect2:
	return Rect2(_u(MAP_ORIGIN_UNITS), _u(MAP_UNITS))

func _camera_viewport_size() -> Vector2:
	return get_viewport_rect().size

func _home_target_bounds() -> Rect2:
	var points: Array[Vector2] = [player_root.global_position]
	if run_director.context:
		for pos in run_director.context.selected_outpost_positions.values():
			points.append(pos)
	for container in container_root.get_children():
		if container is Node2D:
			points.append(container.global_position)
	for outpost_child in outpost_root.get_children():
		if outpost_child is Node2D and not outpost_child.name == "OutpostCandidates":
			points.append(outpost_child.global_position)
	if points.size() == 1:
		points.append(player_root.global_position + _u(Vector2(105.0, 70.0)))
	var min_pos: Vector2 = points[0]
	var max_pos: Vector2 = points[0]
	for point in points:
		min_pos.x = minf(min_pos.x, point.x)
		min_pos.y = minf(min_pos.y, point.y)
		max_pos.x = maxf(max_pos.x, point.x)
		max_pos.y = maxf(max_pos.y, point.y)
	var padding: Vector2 = _u(Vector2(16.0, 12.0))
	return Rect2(min_pos - padding, (max_pos - min_pos) + padding * 2.0)

func _update_container_lifetimes(delta: float) -> void:
	if container_spawn_controller == null:
		return
	container_spawn_controller.update_lifetimes(delta, interactables)

func _update_container_lifetime_visuals() -> void:
	for container in container_root.get_children():
		if not is_instance_valid(container) or not (container is Node2D):
			continue
		if container.get("interact_type") != "container":
			continue
		_refresh_container_lifetime_visual(container)

func _refresh_container_lifetime_visual(container: Node) -> void:
	interactable_visual_builder.refresh_container_lifetime_visual(container)

func _update_material_lifetime_visuals() -> void:
	for material in outpost_root.get_children():
		if not is_instance_valid(material) or not (material is Node2D):
			continue
		if material.get("interact_type") != "material":
			continue
		_refresh_material_lifetime_visual(material)

func _refresh_material_lifetime_visual(material: Node) -> void:
	interactable_visual_builder.refresh_material_lifetime_visual(material)

func _update_outpost_requirement_bubbles() -> void:
	if interactable_visual_builder == null:
		return
	for outpost in outpost_root.get_children():
		if not is_instance_valid(outpost) or outpost.get("interact_type") != "outpost":
			continue
		_sync_outpost_visual_anchor(outpost)
		interactable_visual_builder.refresh_outpost_requirement_bubbles(outpost, Callable(self, "_inventory_count"))

func _update_readable_world_ui_scale() -> void:
	if camera == null or interactable_visual_builder == null:
		return
	var scale_value := 1.0
	if run_director.context != null and run_director.context.active_safe_zone_id == "home":
		var zoom_value := maxf(0.001, (absf(camera.zoom.x) + absf(camera.zoom.y)) * 0.5)
		scale_value = clampf((1.0 / zoom_value) * HOME_OVERVIEW_READABLE_UI_SCALE_MULTIPLIER, 1.0, HOME_OVERVIEW_READABLE_UI_MAX_SCALE)
	for root in [container_root, outpost_root, player_root]:
		interactable_visual_builder.apply_readable_overlay_scale(root, scale_value)

func _remove_interactable(interactable) -> void:
	if nearest_interactable == interactable:
		nearest_interactable = null
	if opened_container == interactable and loot_interaction_controller != null:
		loot_interaction_controller.close_without_saving()
		_sync_loot_state()
		loot_panel.visible = false
		inventory_panel.visible = false
	if interaction_progress_controller != null and interaction_progress_controller.is_target(interactable):
		interaction_progress_controller.cancel()
		_end_player_interact_animation()
	interactables.erase(interactable)
	if is_instance_valid(interactable):
		interactable.visible = false
		if interactable is Area2D:
			interactable.monitoring = false
			interactable.monitorable = false
		interactable.queue_free()

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * UNIT
	return float(value) * UNIT

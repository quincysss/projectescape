extends Node2D

const BasicPlayerScene := preload("res://scenes/entities/player/BasicPlayer.tscn")
const InteractableScript := preload("res://scripts/run/run_interactable.gd")
const VisionCircleScript := preload("res://scripts/vision/vision_debug_circle.gd")
const ExplorationFogScript := preload("res://scripts/vision/exploration_fog_overlay.gd")
const LootInteractionControllerScript := preload("res://scripts/run/loot_interaction_controller.gd")
const MaterialPickupFlowControllerScript := preload("res://scripts/run/material_pickup_flow_controller.gd")
const RunActiveInteractionControllerScript := preload("res://scripts/run/run_active_interaction_controller.gd")
const RunEndControllerScript := preload("res://scripts/run/run_end_controller.gd")
const ExtractionFlowControllerScript := preload("res://scripts/extraction/extraction_flow_controller.gd")
const OutpostRepairControllerScript := preload("res://scripts/run/outpost_repair_controller.gd")
const OutpostRepairFlowControllerScript := preload("res://scripts/outpost/outpost_repair_flow_controller.gd")
const InteractionProgressControllerScript := preload("res://scripts/run/interaction_progress_controller.gd")
const ContainerInteractionControllerScript := preload("res://scripts/run/container_interaction_controller.gd")
const ContainerSpawnControllerScript := preload("res://scripts/run/container_spawn_controller.gd")
const OutpostMaterialSpawnControllerScript := preload("res://scripts/run/outpost_material_spawn_controller.gd")
const InteractableVisualBuilderScript := preload("res://scripts/run/interactable_visual_builder.gd")
const RunWorldPresentationControllerScript := preload("res://scripts/run/run_world_presentation_controller.gd")
const RunUiControllerScript := preload("res://scripts/run/run_ui_controller.gd")
const RunInventoryPanelControllerScript := preload("res://scripts/inventory/run_inventory_panel_controller.gd")
const RunTimerControllerScript := preload("res://scripts/run/run_timer_controller.gd")
const RunMapBuilderScript := preload("res://scripts/map/run_map_builder.gd")
const MonsterSpawnControllerScript := preload("res://scripts/monsters/monster_spawn_controller.gd")
const SettlementResultScreenScript := preload("res://scripts/ui/settlement_result_screen.gd")
const ReturnToBaseLoadingScreenScript := preload("res://scripts/ui/return_to_base_loading_screen.gd")
const WebVideoBridgeScript := preload("res://scripts/ui/web_video_bridge.gd")
const RunSimulationPauseServiceScript := preload("res://scripts/flow/run_simulation_pause_service.gd")
const RunStoryGateControllerScript := preload("res://scripts/flow/run_story_gate_controller.gd")
const DialogueServiceScript := preload("res://scripts/dialogue/dialogue_service.gd")
const DialoguePanelScene := preload("res://scenes/ui/DialoguePanel.tscn")
const UNIT := 64.0
const MAP_UNITS := Vector2(280.0, 220.0)
const MAP_ORIGIN_UNITS := Vector2(-140.0, -110.0)
const HOME_SIZE_UNITS := Vector2(10.0, 8.0)
const HOME_SAFE_SIZE_UNITS := Vector2(12.0, 10.0)
const HOME_ART_LIGHT_PADDING_UNITS := 0.5
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const MAIN_ROAD_WIDTH_UNITS := 8.0
const SECONDARY_ROAD_WIDTH_UNITS := 6.0
const ALLEY_WIDTH_UNITS := 4.0
const PLAYER_FOLLOW_ZOOM := Vector2(0.28, 0.28)
const CAMERA_TRANSITION_SECONDS := 0.5
const CONTAINER_OPEN_HOLD_SECONDS := 0.8
const OUTPOST_REPAIR_HOLD_SECONDS := 1.5
const EXTRACTION_HOLD_SECONDS := 3.0
const STATUS_PROMPT_VISIBLE_SECONDS := 3.0
const SHOW_DEBUG_VISION_CIRCLE := false
const PLAYER_ALWAYS_IN_FRONT_BUILDING_Z_INDEX := -1
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
var minimap: Control
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
var material_pickup_flow_controller
var active_interaction_controller
var run_end_controller
var extraction_flow_controller
var outpost_repair_controller
var outpost_repair_flow_controller
var interaction_progress_controller
var container_interaction_controller
var container_spawn_controller
var outpost_material_spawn_controller
var monster_spawn_controller
var interactable_visual_builder
var run_world_presentation_controller
var run_ui_controller
var run_inventory_panel_controller
var run_timer_controller
var map_builder
var web_video_bridge = WebVideoBridgeScript.new()
var run_simulation_pause_service = RunSimulationPauseServiceScript.new()
var run_story_gate_controller = RunStoryGateControllerScript.new()
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
var home_storage_user_closed: bool:
	get:
		return bool(run_inventory_panel_controller.home_storage_user_closed) if run_inventory_panel_controller != null else false
	set(value):
		if run_inventory_panel_controller != null:
			run_inventory_panel_controller.home_storage_user_closed = value
var active_outpost_storage_id: String:
	get:
		return String(run_inventory_panel_controller.active_outpost_storage_id) if run_inventory_panel_controller != null else ""
	set(value):
		if run_inventory_panel_controller != null:
			run_inventory_panel_controller.active_outpost_storage_id = value
var selected_inventory_index: int:
	get:
		return int(run_inventory_panel_controller.selected_inventory_index) if run_inventory_panel_controller != null else -1
	set(value):
		if run_inventory_panel_controller != null:
			run_inventory_panel_controller.selected_inventory_index = value
var _extract_button_held: bool = false
var _ui_refresh_queued: bool = false
var _story_video_overlay: Control:
	get:
		return run_story_gate_controller.video_overlay if run_story_gate_controller != null else null
var _story_video_player: VideoStreamPlayer:
	get:
		return run_story_gate_controller.video_player if run_story_gate_controller != null else null
var _active_story_dialogue_panel: Control:
	get:
		return run_story_gate_controller.active_dialogue_panel if run_story_gate_controller != null else null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_camera_for_viewport()
		_refresh_story_video_cover()

func _ready() -> void:
	_ensure_input_actions()
	_game_state = get_node_or_null("/root/GameState")
	web_video_bridge.setup(get_viewport())
	if not run_simulation_pause_service.pause_changed.is_connected(_on_run_simulation_pause_changed):
		run_simulation_pause_service.pause_changed.connect(_on_run_simulation_pause_changed)
	run_story_gate_controller.setup(
		self,
		ui_root,
		_game_state,
		dialogue_service,
		DialoguePanelScene,
		web_video_bridge,
		run_simulation_pause_service,
		Callable(self, "_refresh_ui")
	)
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
		camera.zoom = PLAYER_FOLLOW_ZOOM
		camera.position = Vector2.ZERO
	_play_run_safe_house_bgm()
	_refresh_ui()
	call_deferred("_maybe_start_run_story_gate")

func _exit_tree() -> void:
	run_story_gate_controller.cleanup()
	run_simulation_pause_service.clear()
	_audio_manager_call("stop_container_open_loop")
	_audio_manager_call("set_stability_critical_loop_active", [false])

func _create_runtime_controllers() -> void:
	loot_interaction_controller = LootInteractionControllerScript.new()
	material_pickup_flow_controller = MaterialPickupFlowControllerScript.new()
	material_pickup_flow_controller.setup(loot_interaction_controller, run_director, Callable(self, "_remove_interactable"))
	run_end_controller = RunEndControllerScript.new()
	run_end_controller.setup(run_director, _game_state)
	extraction_flow_controller = ExtractionFlowControllerScript.new()
	extraction_flow_controller.setup(run_director, run_end_controller, EXTRACTION_HOLD_SECONDS)
	outpost_repair_controller = OutpostRepairControllerScript.new()
	outpost_repair_controller.setup(run_director, repaired_outposts)
	outpost_repair_flow_controller = OutpostRepairFlowControllerScript.new()
	outpost_repair_flow_controller.setup(outpost_repair_controller, OUTPOST_REPAIR_HOLD_SECONDS)
	interaction_progress_controller = InteractionProgressControllerScript.new()
	interactable_visual_builder = InteractableVisualBuilderScript.new()
	interactable_visual_builder.setup(UNIT)
	run_world_presentation_controller = RunWorldPresentationControllerScript.new()
	run_world_presentation_controller.setup(UNIT, interactable_visual_builder, Callable(self, "_sync_outpost_visual_anchor"))
	run_ui_controller = RunUiControllerScript.new()
	run_inventory_panel_controller = RunInventoryPanelControllerScript.new()
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
	container_interaction_controller = ContainerInteractionControllerScript.new()
	container_interaction_controller.setup(container_spawn_controller, loot_interaction_controller, CONTAINER_OPEN_HOLD_SECONDS)
	active_interaction_controller = RunActiveInteractionControllerScript.new()
	active_interaction_controller.setup(container_interaction_controller, outpost_repair_flow_controller, extraction_flow_controller)
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
	camera.zoom = PLAYER_FOLLOW_ZOOM
	camera.position = Vector2.ZERO

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
	_update_run_world_presentation()
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
	_create_exploration_fog()

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
	camera.zoom = PLAYER_FOLLOW_ZOOM
	camera.position = Vector2.ZERO
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

func _create_exploration_fog() -> void:
	vision_mask = ExplorationFogScript.new()
	vision_mask.name = "ExplorationFogOverlay"
	world_root.add_child(vision_mask)
	var radius: float = run_director.vision_controller.current_radius if run_director.vision_controller != null else 20.0 * UNIT
	vision_mask.setup(_map_bounds_px(), player, radius)
	vision_mask.reveal_permanent_light_rect(Rect2(player_root.global_position - _u(HOME_SAFE_SIZE_UNITS) * 0.5, _u(HOME_SAFE_SIZE_UNITS)), 0.0)
	var home_art_rect := _home_art_permanent_light_rect()
	if home_art_rect.size.x > 0.0 and home_art_rect.size.y > 0.0:
		vision_mask.reveal_permanent_light_rect(home_art_rect, 0.0)

func _home_art_permanent_light_rect() -> Rect2:
	var home_node := _find_home_art_node()
	if home_node == null:
		return Rect2()
	var home_art_rect := _visual_world_rect_for_node(home_node)
	if home_art_rect.size.x <= 0.0 or home_art_rect.size.y <= 0.0:
		return Rect2()
	return home_art_rect.grow(HOME_ART_LIGHT_PADDING_UNITS * UNIT)

func _find_home_art_node() -> Node:
	if y_sort_root == null:
		return null
	for child in y_sort_root.get_children():
		if not is_instance_valid(child):
			continue
		if String(child.get_meta("building_type", "")) == "home":
			return child
	for child in y_sort_root.get_children():
		if is_instance_valid(child) and String(child.name).contains("Building_Home"):
			return child
	return null

func _visual_world_rect_for_node(root: Node) -> Rect2:
	if root == null or not is_instance_valid(root):
		return Rect2()
	var combined := Rect2()
	var has_rect := false
	if root is Sprite2D:
		combined = _sprite_world_rect(root)
		has_rect = combined.size.x > 0.0 and combined.size.y > 0.0
	for sprite in root.find_children("*", "Sprite2D", true, false):
		var sprite_rect := _sprite_world_rect(sprite)
		if sprite_rect.size.x <= 0.0 or sprite_rect.size.y <= 0.0:
			continue
		combined = combined.merge(sprite_rect) if has_rect else sprite_rect
		has_rect = true
	return combined if has_rect else Rect2()

func _sprite_world_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or not is_instance_valid(sprite) or sprite.texture == null:
		return Rect2()
	var texture_size := sprite.texture.get_size()
	var top_left := (-texture_size * 0.5 if sprite.centered else Vector2.ZERO) + sprite.offset
	return _world_rect_from_local_rect(sprite.global_transform, Rect2(top_left, texture_size))

func _world_rect_from_local_rect(transform: Transform2D, local_rect: Rect2) -> Rect2:
	var points := [
		transform * local_rect.position,
		transform * Vector2(local_rect.end.x, local_rect.position.y),
		transform * local_rect.end,
		transform * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point: Vector2 in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)

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
		if SHOW_DEBUG_VISION_CIRCLE:
			run_director.vision_controller.darkness_changed.connect(vision_circle.set_darkness_enabled)
			run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_circle.set_radius(radius))
		run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_mask.set_radius(radius))
		run_director.vision_controller.vision_radius_target_changed.connect(vision_mask.set_radius)

func _on_run_initialized(context) -> void:
	if run_timer_controller == null or run_director == null:
		return
	run_timer_controller.setup(context, run_director.config.run_duration_seconds)
	if container_spawn_controller != null and run_director.has_method("get_ss_loot_director"):
		container_spawn_controller.setup_ss_loot_director(run_director.get_ss_loot_director())

func _prepare_initial_story_gate() -> void:
	run_story_gate_controller.prepare_initial_gate(run_director.context if run_director != null else null)

func _maybe_start_run_story_gate() -> void:
	await run_story_gate_controller.maybe_start_run_story_gate(run_director.context if run_director != null else null)

func _finish_second_day_black_tide_cinematic(_skipped: bool = false) -> void:
	run_story_gate_controller.finish_second_day_black_tide_cinematic(_skipped)

func _update_story_web_video() -> void:
	run_story_gate_controller.update_web_video()

func _acquire_story_pause(token: String) -> void:
	run_simulation_pause_service.acquire(token)

func _release_story_pause(token: String) -> void:
	run_simulation_pause_service.release(token)

func _on_run_simulation_pause_changed(paused: bool, _reason: String) -> void:
	_apply_story_pause_state(paused)

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
	return run_simulation_pause_service.is_paused()

func is_run_story_paused() -> bool:
	return _is_story_paused()

func _refresh_story_video_cover() -> void:
	run_story_gate_controller.refresh_video_cover()

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
		if run_world_presentation_controller != null:
			run_world_presentation_controller.refresh_outpost_requirement_bubble(station, Callable(self, "_inventory_count"))
		else:
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
		_status_prompt = active_interaction_controller.cancel_message(interaction_id) if active_interaction_controller != null else "交互中断。"
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
	var result: Dictionary = container_interaction_controller.begin_open(
		container,
		interaction_progress_controller,
		Callable(self, "_complete_held_container_open"),
		Callable(self, "_cancel_held_container_open")
	)
	if not bool(result.get("accepted", false)):
		if result.get("reason", "") == ContainerInteractionControllerScript.REASON_DEPLETED:
			_status_prompt = "容器已不可开启。"
		else:
			_status_prompt = String(result.get("message", ""))
		_refresh_ui()
		return
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
	if container_interaction_controller != null:
		container_interaction_controller.cancel_held_open(container)

func _open_container(container) -> void:
	var result: Dictionary = container_interaction_controller.open(container)
	if not bool(result.get("accepted", false)):
		if result.get("reason", "") == ContainerInteractionControllerScript.REASON_DEPLETED:
			prompt_label.text = "容器已不可开启。"
		else:
			prompt_label.text = String(result.get("message", loot_interaction_controller.last_prompt))
		return
	_reveal_interaction_area(container, false)
	_play_player_interact_once(container)
	_sync_loot_state()
	_open_loot_transfer_panels()
	_refresh_ui()

func _pick_material(pickup) -> void:
	if _is_story_paused():
		return
	if material_pickup_flow_controller == null:
		return
	var result: Dictionary = material_pickup_flow_controller.pick_material(pickup)
	if bool(result.get("accepted", false)):
		_mark_catalog_item_collected_from_run(result.get("item", {}), "run_material_pickup")
		_reveal_interaction_area(pickup, false)
		_play_player_interact_once(pickup)
		var pickup_outpost_id := String(result.get("outpost_id", ""))
		_set_timed_status_prompt(run_ui_controller.outpost_material_pickup_prompt(self, pickup_outpost_id), 1.8)
	else:
		_status_prompt = String(result.get("message", ""))
	_refresh_ui()

func _take_all_loot() -> void:
	if _is_story_paused():
		return
	var before_loot: Array = loot_interaction_controller.opened_loot.duplicate(true)
	var transfer_finished: bool = loot_interaction_controller.take_all_loot(
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	)
	_mark_catalog_items_transferred_from_run(before_loot, loot_interaction_controller.opened_loot, "run_loot_take_all")
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
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.on_inventory_item_clicked(meta, run_director))

func _on_home_storage_item_meta_clicked(meta: Variant) -> void:
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.on_storage_item_clicked(meta, run_director, _is_inventory_panel_visible()))

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
		_mark_catalog_item_collected_from_run(Dictionary(result.get("item", {})), "run_loot_pickup")
		_status_prompt = "已放入背包：%s" % result.item.get("display_name", result.item.get("item_id", ""))
		if bool(result.get("finished", false)):
			loot_panel.visible = false
			_set_container_lifetime_paused(opened_container, false)
	else:
		_status_prompt = loot_interaction_controller.last_prompt
	_refresh_ui()

func _mark_catalog_item_collected_from_run(item: Dictionary, source: String) -> void:
	if _game_state == null or not _game_state.has_method("mark_item_collected"):
		return
	var item_id := String(item.get("item_id", "")).strip_edges()
	if item_id.is_empty():
		return
	_game_state.mark_item_collected(item_id, source)

func _mark_catalog_items_transferred_from_run(before_items: Array, remaining_items: Array, source: String) -> void:
	if _game_state == null or not _game_state.has_method("mark_items_collected"):
		return
	var before_counts := _count_items_by_id(before_items)
	var remaining_counts := _count_items_by_id(remaining_items)
	var collected_ids: Array[String] = []
	for item_id in before_counts.keys():
		var transferred_count := int(before_counts.get(item_id, 0)) - int(remaining_counts.get(item_id, 0))
		if transferred_count > 0:
			collected_ids.append(String(item_id))
	if not collected_ids.is_empty():
		_game_state.mark_items_collected(collected_ids, source)

func _count_items_by_id(items: Array) -> Dictionary:
	var counts := {}
	for item in items:
		if not (item is Dictionary):
			continue
		var item_id := String(item.get("item_id", "")).strip_edges()
		if item_id.is_empty():
			continue
		counts[item_id] = int(counts.get(item_id, 0)) + maxi(1, int(item.get("amount", 1)))
	return counts

func _deposit_inventory_item_at(index: int, inventory_index: int = -1) -> void:
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.deposit_inventory_item_at(index, run_director, inventory_index, _is_inventory_panel_visible()))

func _select_inventory_item_at(index: int) -> void:
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.select_inventory_item_at(index, run_director))

func _discard_selected_inventory_item() -> void:
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.discard_selected_inventory_item(run_director, _is_inventory_panel_visible()))

func has_selected_inventory_item() -> bool:
	return run_inventory_panel_controller != null and run_inventory_panel_controller.has_selected_inventory_item(run_director)

func selected_inventory_item_summary() -> String:
	if run_inventory_panel_controller == null:
		return ""
	return run_inventory_panel_controller.selected_inventory_item_summary(run_director)

func _selected_inventory_item() -> Dictionary:
	if run_inventory_panel_controller == null:
		return {}
	return run_inventory_panel_controller.selected_inventory_item(run_director)

func _sync_inventory_selection_state() -> void:
	if run_inventory_panel_controller != null:
		run_inventory_panel_controller.sync_inventory_selection_state(_is_inventory_panel_visible(), run_director)

func _inventory_discard_reason_text(reason: String) -> String:
	if run_inventory_panel_controller == null:
		return "无法丢弃该道具。"
	return run_inventory_panel_controller.inventory_discard_reason_text(reason)

func _withdraw_active_storage_item_at(index: int) -> void:
	if _is_story_paused():
		return
	if run_inventory_panel_controller == null:
		return
	_apply_inventory_panel_result(run_inventory_panel_controller.withdraw_active_storage_item_at(index, run_director))

func _item_meta_index(meta: Variant, expected_source: String) -> int:
	if run_inventory_panel_controller == null:
		return -1
	return run_inventory_panel_controller.item_meta_index(meta, expected_source)

func _selection_transfer_reason_text(reason: String) -> String:
	if run_inventory_panel_controller == null:
		return "无法移动该道具。"
	return run_inventory_panel_controller.selection_transfer_reason_text(reason, run_director)

func _apply_inventory_panel_result(result: Dictionary, direct_prompt: bool = false) -> void:
	var message := String(result.get("message", ""))
	if not message.is_empty():
		if direct_prompt:
			prompt_label.text = message
		else:
			_status_prompt = message
	if bool(result.get("refresh", true)):
		_refresh_ui()

func _is_inventory_panel_visible() -> bool:
	return inventory_panel != null and inventory_panel.visible

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
	if container_interaction_controller == null:
		return
	container_interaction_controller.set_lifetime_paused(container, paused)

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
	if interaction_progress_controller == null or outpost_repair_flow_controller == null:
		_try_repair_outpost(station)
		return
	var result: Dictionary = outpost_repair_flow_controller.begin_repair(
		station,
		interaction_progress_controller,
		Callable(self, "_complete_held_outpost_repair"),
		Callable(self, "_cancel_held_outpost_repair")
	)
	if not bool(result.get("accepted", false)):
		_status_prompt = String(result.get("message", ""))
		_refresh_ui()
		return
	_status_prompt = ""
	_begin_player_interact_animation(station)
	_refresh_ui()

func _complete_held_outpost_repair(station) -> void:
	_try_repair_outpost(station)

func _cancel_held_outpost_repair(station) -> void:
	if outpost_repair_flow_controller != null:
		outpost_repair_flow_controller.cancel_repair(station)

func _update_active_interaction(delta: float) -> void:
	if interaction_progress_controller == null or not interaction_progress_controller.is_active():
		return
	var target = interaction_progress_controller.active_target
	var interaction_id: String = interaction_progress_controller.active_id
	var should_continue := false
	if active_interaction_controller != null:
		should_continue = active_interaction_controller.should_continue(
			interaction_id,
			target,
			{
				"nearest_interactable": nearest_interactable,
				"interact_pressed": Input.is_action_pressed("interact"),
				"extract_pressed": _is_extraction_hold_pressed(),
				"story_paused": _is_story_paused(),
			}
		)
	var result: Dictionary = interaction_progress_controller.update(delta, should_continue)
	if bool(result.get("cancelled", false)):
		_end_player_interact_animation()
		_status_prompt = active_interaction_controller.cancel_message(interaction_id) if active_interaction_controller != null else "交互中断。"
	elif bool(result.get("completed", false)):
		_end_player_interact_animation()
		if _status_prompt.is_empty():
			_status_prompt = active_interaction_controller.complete_message(interaction_id) if active_interaction_controller != null else "交互完成。"

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

func _is_extraction_hold_pressed() -> bool:
	if _is_story_paused():
		return false
	return Input.is_action_pressed("extract") or _extract_button_held

func _can_continue_extraction_hold() -> bool:
	if extraction_flow_controller != null:
		return not _is_story_paused() and extraction_flow_controller.can_continue_hold(true)
	return (
		not _is_story_paused()
		and run_director != null
		and run_director.context != null
		and run_director.context.is_extraction_unlocked
		and run_director.context.active_safe_zone_id == "home"
	)

func _try_repair_outpost(station) -> void:
	var result: Dictionary
	if outpost_repair_flow_controller != null:
		result = outpost_repair_flow_controller.complete_repair(station)
	else:
		result = outpost_repair_controller.repair(station)
	_status_prompt = result.message
	if bool(result.get("activated", false)):
		_audio_manager_call("play_outpost_repair_complete")
		_reveal_interaction_area(station, true)
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
	if run_inventory_panel_controller == null:
		return
	var result: Dictionary = run_inventory_panel_controller.enter_repaired_outpost_safe_zone(station, run_director)
	if not bool(result.get("accepted", false)):
		return
	_play_run_safe_house_bgm()
	_status_prompt = String(result.get("message", ""))

func _exit_repaired_outpost_safe_zone(station) -> void:
	if run_inventory_panel_controller == null:
		return
	var result: Dictionary = run_inventory_panel_controller.exit_repaired_outpost_safe_zone(station, run_director)
	if not bool(result.get("accepted", false)):
		return
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
	if run_inventory_panel_controller == null:
		return
	var result: Dictionary = run_inventory_panel_controller.deposit_all(run_director, _is_inventory_panel_visible())
	_apply_inventory_panel_result(result, String(result.get("reason", "")) == "not_storage_zone")

func is_storage_zone_active() -> bool:
	return run_inventory_panel_controller != null and run_inventory_panel_controller.is_storage_zone_active(run_director)

func is_home_storage_active() -> bool:
	return run_inventory_panel_controller != null and run_inventory_panel_controller.is_home_storage_active(run_director)

func _is_active_outpost_storage() -> bool:
	return run_inventory_panel_controller != null and run_inventory_panel_controller.is_active_outpost_storage(run_director)

func get_active_storage_items_snapshot() -> Array:
	if run_inventory_panel_controller == null:
		return []
	return run_inventory_panel_controller.get_active_storage_items_snapshot(run_director)

func get_active_storage_source_id() -> String:
	if run_inventory_panel_controller == null:
		return "storage"
	return run_inventory_panel_controller.get_active_storage_source_id()

func get_active_storage_title() -> String:
	if run_inventory_panel_controller == null:
		return "家中存储"
	return run_inventory_panel_controller.get_active_storage_title(run_director)

func _active_storage_display_name() -> String:
	if run_inventory_panel_controller == null:
		return "家中"
	return run_inventory_panel_controller.active_storage_display_name(run_director)

func _close_outpost_storage_ui(outpost_id: String) -> void:
	if run_inventory_panel_controller != null:
		run_inventory_panel_controller.close_outpost_storage_ui(outpost_id, home_storage_panel, loot_panel, inventory_panel)

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
	if extraction_flow_controller == null:
		return
	var result: Dictionary = extraction_flow_controller.begin_extraction(
		interaction_progress_controller,
		Callable(self, "_complete_held_extract"),
		Callable(self, "_cancel_held_extract")
	)
	if not bool(result.get("accepted", false)):
		_status_prompt = String(result.get("message", ""))
		_refresh_ui()
		return
	if bool(result.get("complete_immediately", false)):
		_complete_held_extract(run_director)
		return
	if bool(result.get("held", false)):
		_status_prompt = ""
		_begin_player_interact_animation()
	_refresh_ui()

func _complete_held_extract(_target) -> void:
	if extraction_flow_controller == null and run_end_controller == null:
		return
	var result: Dictionary
	if extraction_flow_controller != null:
		result = extraction_flow_controller.complete_extraction(get_tree())
	else:
		result = run_end_controller.try_extract(get_tree())
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
	if extraction_flow_controller != null:
		extraction_flow_controller.cancel_extraction()
	elif run_director != null and _is_current_run_phase("EXTRACT"):
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
	_tween_camera(PLAYER_FOLLOW_ZOOM, Vector2.ZERO)

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

func _map_bounds_px() -> Rect2:
	return Rect2(_u(MAP_ORIGIN_UNITS), _u(MAP_UNITS))

func _update_container_lifetimes(delta: float) -> void:
	if container_spawn_controller == null:
		return
	container_spawn_controller.update_lifetimes(delta, interactables)

func _update_container_lifetime_visuals() -> void:
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_container_lifetime_visuals(container_root)

func _refresh_container_lifetime_visual(container: Node) -> void:
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_container_lifetime_visual(container)
	elif interactable_visual_builder != null:
		interactable_visual_builder.refresh_container_lifetime_visual(container)

func _update_material_lifetime_visuals() -> void:
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_material_lifetime_visuals(outpost_root)

func _refresh_material_lifetime_visual(material: Node) -> void:
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_material_lifetime_visual(material)
	elif interactable_visual_builder != null:
		interactable_visual_builder.refresh_material_lifetime_visual(material)

func _update_outpost_requirement_bubbles() -> void:
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_outpost_requirement_bubbles(outpost_root, Callable(self, "_inventory_count"))
		return
	if interactable_visual_builder == null:
		return
	for outpost in outpost_root.get_children():
		if not is_instance_valid(outpost) or outpost.get("interact_type") != "outpost":
			continue
		_sync_outpost_visual_anchor(outpost)
		interactable_visual_builder.refresh_outpost_requirement_bubbles(outpost, Callable(self, "_inventory_count"))

func _update_run_world_presentation() -> void:
	if run_world_presentation_controller == null:
		_update_container_lifetime_visuals()
		_update_material_lifetime_visuals()
		_update_outpost_requirement_bubbles()
		_update_readable_world_ui_scale()
		return
	run_world_presentation_controller.update(container_root, outpost_root, player_root, Callable(self, "_inventory_count"))

func _update_readable_world_ui_scale() -> void:
	if camera == null:
		return
	if run_world_presentation_controller != null:
		run_world_presentation_controller.refresh_readable_overlay_layout([container_root, outpost_root, player_root])
		return
	if interactable_visual_builder != null:
		var scale_value := 1.0
		for root in [container_root, outpost_root, player_root]:
			interactable_visual_builder.apply_readable_overlay_scale(root, scale_value)

func _reveal_interaction_area(interactable, reveal_host_block: bool) -> void:
	if vision_mask == null or not is_instance_valid(vision_mask) or interactable == null or not is_instance_valid(interactable):
		return
	if reveal_host_block:
		var block_rect := _resolve_host_block_rect(interactable)
		if block_rect.size.x > 0.0 and block_rect.size.y > 0.0:
			vision_mask.reveal_permanent_light_rect(block_rect)
			return
	var radius_from_vision: float = run_director.vision_controller.current_radius * 0.28 if run_director.vision_controller != null else 3.5 * UNIT
	var small_radius := maxf(3.5 * UNIT, radius_from_vision)
	vision_mask.reveal_circle(interactable.global_position, small_radius)

func _resolve_host_block_rect(node) -> Rect2:
	var host_block_id := ""
	if node != null and is_instance_valid(node):
		host_block_id = String(node.get_meta("host_block_id", ""))
		var payload_value = node.get("payload")
		if host_block_id.is_empty() and payload_value is Dictionary:
			host_block_id = String(payload_value.get("host_block_id", ""))
	for block in _get_layout_rects("BlockSolid"):
		if not block.has_method("get_rect_id"):
			continue
		if not host_block_id.is_empty() and block.get_rect_id() == host_block_id:
			return block.get_rect_px(UNIT)
	if node is Node2D:
		var world_pos: Vector2 = node.global_position
		for block in _get_layout_rects("BlockSolid"):
			if block.has_method("get_rect_px"):
				var rect: Rect2 = block.get_rect_px(UNIT)
				if rect.has_point(world_pos):
					return rect
	return Rect2()

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

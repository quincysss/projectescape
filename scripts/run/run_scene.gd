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
const HOME_OVERVIEW_READABLE_UI_MAX_SCALE := 3.0
const CAMERA_TRANSITION_SECONDS := 0.5
const CONTAINER_OPEN_HOLD_SECONDS := 0.8
const OUTPOST_REPAIR_HOLD_SECONDS := 1.5
const EXTRACTION_HOLD_SECONDS := 1.2
const SHOW_DEBUG_VISION_CIRCLE := false

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
var _walkable_rects: Array[Rect2] = []
var _walkable_polygons: Array[PackedVector2Array] = []
var enterable_exception_rects: Array[Rect2] = []

var hud_label: Label
var character_hud_root: Control
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
var outpost_hud_root: Panel
var outpost_count_label: Label
var outpost_first_icon: Panel
var outpost_first_status_label: Label
var outpost_first_progress_bar: ProgressBar
var outpost_second_icon: Panel
var outpost_second_status_label: Label
var outpost_second_progress_bar: ProgressBar
var backpack_hud_root: Panel
var backpack_icon_placeholder: Panel
var backpack_slot_label: Label
var weight_bar: ProgressBar
var weight_value_label: Label
var prompt_label: Label
var inventory_panel: Panel
var inventory_label: Control
var loot_panel: Panel
var loot_label: Control
var home_storage_panel: Panel
var home_storage_label: Control
var take_all_button: Button
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
var interactable_visual_builder
var run_ui_controller
var run_timer_controller
var map_builder
var _status_prompt: String = ""
var home_storage_user_closed: bool = false
var active_outpost_storage_id: String = ""
var _extract_button_held: bool = false
var _ui_refresh_queued: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_camera_for_viewport()

func _ready() -> void:
	_ensure_input_actions()
	_game_state = get_node_or_null("/root/GameState")
	_create_runtime_controllers()
	_build_run_world()
	_build_ui()
	_connect_runtime()
	run_director.start_new_run()
	_spawn_selected_outposts()
	_spawn_initial_containers()
	_spawn_requirement_materials()
	if camera:
		camera.zoom = _home_overview_zoom()
		camera.position = _home_overview_offset()
	_refresh_ui()

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
	_update_run_timer(delta)
	_update_active_interaction(delta)
	if container_spawn_controller != null:
		container_spawn_controller.update(delta, interactables)
	_update_container_lifetime_visuals()
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
	_create_home_visual()
	_create_player()
	_create_camera()
	_create_vision_circle()

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
	player.base_speed = 12.0 * UNIT
	y_sort_root.add_child(player)
	player.global_position = $WorldRoot/PlayerRoot/PlayerSpawn.global_position
	_walkable_rects.append(Rect2(player_root.global_position - _u(HOME_SAFE_SIZE_UNITS) * 0.5, _u(HOME_SAFE_SIZE_UNITS)))
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

func _update_run_timer(delta: float) -> void:
	if run_timer_controller != null:
		run_timer_controller.update(delta)

func _on_run_time_expired() -> void:
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		interaction_progress_controller.cancel()
		_end_player_interact_animation()
	if run_end_controller != null:
		run_end_controller.handle_timeout(get_tree(), "time_expired")
	else:
		get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

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
	var first_id: String = context.selected_first_outpost_id
	var second_id: String = context.selected_second_outpost_id
	if outpost_material_spawn_controller:
		outpost_requirements = outpost_material_spawn_controller.build_requirements(first_id, second_id)
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

func _get_material_points_for_outpost(base_pos: Vector2, count: int) -> Array:
	var points := _get_material_spawn_points()
	points.sort_custom(func(a, b): return a.global_position.distance_squared_to(base_pos) < b.global_position.distance_squared_to(base_pos))
	return points.slice(0, count)

func _get_container_spawn_points() -> Array:
	return _get_layout_points("ContainerSpawnPoints")

func _get_material_spawn_points() -> Array:
	return _get_layout_points("MaterialSpawnPoints")

func _make_interactable(id: String, type: String, label_text: String, pos: Vector2, color: Color, size_units: Vector2 = Vector2.ZERO):
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
	var visual_size: Vector2 = interactable_visual_builder.add_interactable_visual(area, type, label_text, color, size_units)
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
	if interaction_progress_controller == null:
		_open_container(container)
		return
	if not is_instance_valid(container):
		return
	if container.payload.get("state", "") == "depleted" or container.payload.get("rewards", []).is_empty():
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
	_refresh_ui()

func _complete_held_container_open(container) -> void:
	_open_container(container)
	_status_prompt = "容器已打开。"

func _cancel_held_container_open(container) -> void:
	_set_container_lifetime_paused(container, false)

func _open_container(container) -> void:
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
	if loot_interaction_controller.pick_material_immediate(
		pickup,
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	):
		_play_player_interact_once(pickup)
		_status_prompt = "材料已放入背包。"
	else:
		_status_prompt = loot_interaction_controller.last_prompt
	_refresh_ui()

func _take_all_loot() -> void:
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
		_deposit_inventory_item_at(index)

func _on_home_storage_item_meta_clicked(meta: Variant) -> void:
	var index := _item_meta_index(meta, "storage")
	if index < 0:
		index = _item_meta_index(meta, "home")
	if index >= 0:
		_withdraw_active_storage_item_at(index)

func _take_loot_item_at(index: int) -> void:
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

func _deposit_inventory_item_at(index: int) -> void:
	var result: Dictionary
	var storage_name := _active_storage_display_name()
	if _is_active_outpost_storage():
		result = run_director.deposit_inventory_item_to_outpost(active_outpost_storage_id, index)
	else:
		result = run_director.deposit_inventory_item_to_home_by_selection(index)
	if bool(result.get("accepted", false)):
		_status_prompt = "已存入%s：%s" % [storage_name, result.item.get("display_name", result.item.get("item_id", ""))]
	else:
		_status_prompt = _selection_transfer_reason_text(str(result.get("reason", "")))
	_refresh_ui()

func _withdraw_active_storage_item_at(index: int) -> void:
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
	return Input.is_action_pressed("extract") or _extract_button_held

func _can_continue_extraction_hold() -> bool:
	return (
		run_director != null
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
		_activate_outpost_safe_zone(station)
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
	run_director.ensure_outpost_storage(station.interact_id)
	active_outpost_storage_id = station.interact_id
	home_storage_user_closed = false
	_status_prompt = "前哨站安全区：稳定值正在恢复。"

func _exit_repaired_outpost_safe_zone(station) -> void:
	if run_director.context == null:
		return
	if run_director.context.active_safe_zone_id != station.interact_id:
		return
	run_director.on_safe_zone_exited(station.interact_id)

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
	return Rect2(_u(OUTPOST_SIZE_UNITS) * -0.5, _u(OUTPOST_SIZE_UNITS)).has_point(local_pos)

func _has_requirements(requirements: Dictionary) -> bool:
	return outpost_repair_controller.has_requirements(requirements)

func _missing_requirements_text(requirements: Dictionary) -> String:
	return outpost_repair_controller.missing_requirements_text(requirements)

func _inventory_count(item_id: String) -> int:
	return outpost_repair_controller.inventory_count(item_id)

func _deposit_all() -> void:
	if not is_storage_zone_active():
		prompt_label.text = "请进入家中或已修复前哨站存放物品。"
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
		return run_director.get_outpost_storage_items_snapshot(active_outpost_storage_id)
	if run_director.home_storage_component != null:
		return run_director.home_storage_component.get_items_snapshot()
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
	_begin_extraction_hold()

func _begin_extraction_hold_from_button() -> void:
	_extract_button_held = true
	_begin_extraction_hold()

func _release_extraction_hold_button() -> void:
	_extract_button_held = false

func _begin_extraction_hold() -> void:
	if run_end_controller == null:
		return
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		return
	var validation: Dictionary = run_end_controller.validate_extraction()
	if not validation.accepted:
		prompt_label.text = validation.message
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
		_begin_player_interact_animation()
	_refresh_ui()

func _complete_held_extract(_target) -> void:
	if run_end_controller == null:
		return
	var result: Dictionary = run_end_controller.try_extract(get_tree())
	if bool(result.get("accepted", false)) and run_timer_controller != null:
		run_timer_controller.stop()
	if not result.accepted:
		prompt_label.text = result.message

func _cancel_held_extract(_target) -> void:
	pass

func _on_stability_changed(current: float, _max_value: float, _stage: int) -> void:
	if current <= 0.0:
		call_deferred("_return_to_base_after_death", "stability_depleted")

func _return_to_base_after_death(reason: String = "stability_depleted") -> void:
	if run_timer_controller != null:
		run_timer_controller.stop()
	if run_end_controller:
		run_end_controller.handle_player_death(get_tree(), reason)
	else:
		get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

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
	run_ui_controller.toggle_inventory(self)

func _switch_camera_home() -> void:
	_tween_camera(_home_overview_zoom(), _home_overview_offset())

func _switch_camera_follow() -> void:
	_tween_camera(PLAYER_FOLLOW_ZOOM, Vector2.ZERO)

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

func _update_outpost_requirement_bubbles() -> void:
	if interactable_visual_builder == null:
		return
	for outpost in outpost_root.get_children():
		if not is_instance_valid(outpost) or outpost.get("interact_type") != "outpost":
			continue
		interactable_visual_builder.refresh_outpost_requirement_bubbles(outpost, Callable(self, "_inventory_count"))

func _update_readable_world_ui_scale() -> void:
	if camera == null or interactable_visual_builder == null:
		return
	var scale_value := 1.0
	if run_director.context != null and run_director.context.active_safe_zone_id == "home":
		var zoom_value := maxf(0.001, (absf(camera.zoom.x) + absf(camera.zoom.y)) * 0.5)
		scale_value = clampf(1.0 / zoom_value, 1.0, HOME_OVERVIEW_READABLE_UI_MAX_SCALE)
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

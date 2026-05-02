extends Node2D

const PlayerScript := preload("res://scripts/player/whitebox_player.gd")
const InteractableScript := preload("res://scripts/run/whitebox_interactable.gd")
const VisionCircleScript := preload("res://scripts/vision/vision_debug_circle.gd")
const VisionMaskScript := preload("res://scripts/vision/vision_mask_overlay.gd")

const UNIT := 64.0
const MAP_UNITS := Vector2(280.0, 220.0)
const MAP_ORIGIN_UNITS := Vector2(-140.0, -110.0)
const HOME_SIZE_UNITS := Vector2(10.0, 8.0)
const HOME_SAFE_SIZE_UNITS := Vector2(12.0, 10.0)
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const MAIN_ROAD_WIDTH_UNITS := 6.0
const SECONDARY_ROAD_WIDTH_UNITS := 4.0
const ALLEY_WIDTH_UNITS := 2.5
const PLAYER_FOLLOW_ZOOM := Vector2(0.28, 0.28)
const HOME_OVERVIEW_MAX_ZOOM := 0.11
const HOME_OVERVIEW_MIN_ZOOM := 0.025
const CAMERA_TRANSITION_SECONDS := 0.5
const SHOW_DEBUG_VISION_CIRCLE := false

@onready var run_director: RunDirector = $RunDirector
@onready var world_root: Node2D = $WorldRoot
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
var container_index: int = 0
var _container_timer: float = 0.0
var _walkable_rects: Array[Rect2] = []
var _walkable_polygons: Array[PackedVector2Array] = []
var _last_container_spawn_point_index: int = 0

var hud_label: Label
var prompt_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var loot_panel: PanelContainer
var loot_label: Label
var take_all_button: Button
var deposit_button: Button
var extract_button: Button
var backpack_button: Button
var _game_state: Node
var _camera_tween: Tween

func _ready() -> void:
	_ensure_input_actions()
	_game_state = get_node_or_null("/root/GameState")
	_build_whitebox_world()
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
	_update_container_lifetimes(delta)
	_container_timer += delta
	if _container_timer >= 12.0:
		_container_timer = 0.0
		_spawn_container(_random_container_position())
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("toggle_inventory"):
		inventory_panel.visible = not inventory_panel.visible
		_refresh_ui()
	if Input.is_action_just_pressed("extract"):
		_try_extract()
	_refresh_ui()

func _build_whitebox_world() -> void:
	_create_ground()
	_create_home_visual()
	_create_player()
	_create_camera()
	_create_vision_circle()

func _create_ground() -> void:
	_walkable_rects.clear()
	_walkable_polygons.clear()
	var ground := ColorRect.new()
	ground.name = "WhiteboxGround"
	ground.color = Color(0.12, 0.14, 0.12)
	ground.size = _u(MAP_UNITS)
	ground.position = _u(MAP_ORIGIN_UNITS)
	ground.z_index = -100
	world_root.add_child(ground)

	for road in _get_layout_rects("Roads"):
		_add_road_from_layout(road)
	for building in _get_layout_rects("Buildings"):
		_add_building_from_layout(building)

func _add_road_from_layout(layout) -> void:
	var color := Color(0.42, 0.42, 0.42)
	if layout.subtype == "plaza" or layout.rect_kind == "plaza":
		color = Color(0.34, 0.34, 0.32)
	_add_road(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(UNIT), color)
	_walkable_polygons.append(layout.get_world_corners_px(UNIT))
	_walkable_rects.append(layout.get_rect_px(UNIT))

func _add_road(road_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array, color: Color = Color(0.42, 0.42, 0.42)) -> void:
	var road := Polygon2D.new()
	road.name = road_name
	road.color = color
	road.polygon = local_polygon
	road.z_index = -90
	world_root.add_child(road)
	road.global_transform = source_transform

func _add_building_from_layout(layout) -> void:
	_add_building(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(UNIT))

func _add_building(building_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.name = building_name
	body.z_index = -40
	world_root.add_child(body)
	body.global_transform = source_transform
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(0.92, 0.92, 0.9)
	visual.polygon = local_polygon
	body.add_child(visual)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = local_polygon[2] - local_polygon[0]
	shape.shape = rect
	body.add_child(shape)

func _get_layout_rects(section_name: String) -> Array:
	var section := get_node_or_null("WorldRoot/MapLayout/%s" % section_name)
	if section == null:
		return []
	var rects := []
	for child in section.get_children():
		if child.has_method("get_rect_px"):
			rects.append(child)
	return rects

func _get_layout_points(section_name: String) -> Array:
	var section := get_node_or_null("WorldRoot/MapLayout/Points/%s" % section_name)
	if section == null:
		return []
	var points := []
	for child in section.get_children():
		if child is Node2D and child.has_method("get_point_id") and child.enabled:
			points.append(child)
	return points

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

	var label := _make_world_label("HOME 10x8\nSAFE 12x10", _u(Vector2(-5.5, -6.8)), player_root)
	label.modulate = Color(0.8, 1.0, 0.8)
	label.z_index = 20

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.script = PlayerScript
	player.base_speed = 6.0 * UNIT
	player.position = $WorldRoot/PlayerRoot/PlayerSpawn.position
	player_root.add_child(player)
	_walkable_rects.append(Rect2(player_root.global_position - _u(HOME_SAFE_SIZE_UNITS) * 0.5, _u(HOME_SAFE_SIZE_UNITS)))
	player.set_walkable_rects(_walkable_rects)
	player.set_walkable_polygons(_walkable_polygons)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.6 * UNIT
	shape.shape = circle
	player.add_child(shape)
	var body := ColorRect.new()
	body.name = "PlayerBox"
	body.color = Color(0.2, 0.65, 1.0)
	body.size = _u(Vector2(2.0, 4.0))
	body.position = Vector2(-body.size.x * 0.5, -body.size.y * 0.75)
	body.z_index = 30
	player.add_child(body)

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
	player.add_child(camera)
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
	hud_label = Label.new()
	hud_label.name = "HUDLabel"
	hud_label.position = Vector2(16, 12)
	hud_label.size = Vector2(760, 160)
	ui_root.add_child(hud_label)

	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.position = Vector2(16, 170)
	prompt_label.size = Vector2(760, 50)
	ui_root.add_child(prompt_label)

	backpack_button = Button.new()
	backpack_button.name = "BackpackButton"
	backpack_button.text = "Backpack"
	backpack_button.position = Vector2(780, 16)
	backpack_button.size = Vector2(130, 36)
	backpack_button.pressed.connect(_toggle_inventory_panel)
	ui_root.add_child(backpack_button)

	inventory_panel = _make_panel(Vector2(16, 230), Vector2(360, 320), "Inventory")
	inventory_label = Label.new()
	inventory_label.position = Vector2(12, 38)
	inventory_label.size = Vector2(330, 190)
	inventory_panel.add_child(inventory_label)
	deposit_button = Button.new()
	deposit_button.text = "Deposit All At Home"
	deposit_button.position = Vector2(12, 252)
	deposit_button.size = Vector2(180, 36)
	deposit_button.pressed.connect(_deposit_all)
	inventory_panel.add_child(deposit_button)
	extract_button = Button.new()
	extract_button.text = "Extract"
	extract_button.position = Vector2(204, 252)
	extract_button.size = Vector2(120, 36)
	extract_button.pressed.connect(_try_extract)
	inventory_panel.add_child(extract_button)
	ui_root.add_child(inventory_panel)
	inventory_panel.visible = false

	loot_panel = _make_panel(Vector2(400, 230), Vector2(320, 260), "Loot")
	loot_label = Label.new()
	loot_label.position = Vector2(12, 38)
	loot_label.size = Vector2(280, 150)
	loot_panel.add_child(loot_label)
	take_all_button = Button.new()
	take_all_button.text = "Take All"
	take_all_button.position = Vector2(12, 204)
	take_all_button.size = Vector2(120, 36)
	take_all_button.pressed.connect(_take_all_loot)
	loot_panel.add_child(take_all_button)
	ui_root.add_child(loot_panel)
	loot_panel.visible = false

func _make_panel(pos: Vector2, panel_size: Vector2, title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = panel_size
	var label := Label.new()
	label.text = title
	label.position = Vector2(12, 8)
	panel.add_child(label)
	return panel

func _connect_runtime() -> void:
	run_director.stability_changed.connect(_on_stability_changed)
	run_director.weight_changed.connect(_on_weight_changed)
	run_director.inventory_changed.connect(func(_items): _refresh_ui())
	run_director.home_storage_changed.connect(func(_items): _refresh_ui())
	home_safe_zone.safe_zone_entered.connect(func(_zone_id, _zone_type): _switch_camera_home())
	home_safe_zone.safe_zone_exited.connect(func(_zone_id, _zone_type): _switch_camera_follow())
	if run_director.vision_controller:
		run_director.vision_controller.darkness_changed.connect(vision_mask.set_darkness_enabled)
		if SHOW_DEBUG_VISION_CIRCLE:
			run_director.vision_controller.darkness_changed.connect(vision_circle.set_darkness_enabled)
			run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_circle.set_radius(radius))
		run_director.vision_controller.vision_radius_changed.connect(func(radius, _stage): vision_mask.set_radius(radius))

func _spawn_initial_containers() -> void:
	for spawn_point in _get_layout_points("ContainerSpawnPoints").slice(0, 6):
		_spawn_container(spawn_point.global_position)

func _spawn_container(pos: Vector2) -> void:
	container_index += 1
	var rarity := _pick_rarity()
	var container = _make_interactable("container_%s" % container_index, "container", "%s Resource Cache" % rarity, pos, _rarity_color(rarity))
	container.payload = {
		"state": "available",
		"rarity": rarity,
		"lifetime": 45.0,
		"rewards": [_item("scrap_metal", "Scrap Metal", 1 + randi() % 2, 2.0, 5), _item("food_can", "Food Can", 1, 1.0, 3)],
	}
	container_root.add_child(container)

func _spawn_selected_outposts() -> void:
	var context = run_director.context
	if context == null:
		return
	outpost_requirements.clear()
	var first_id: String = context.selected_first_outpost_id
	var second_id: String = context.selected_second_outpost_id
	outpost_requirements[first_id] = {
		"scrap_metal": {"display_name": "Scrap Metal", "amount": 2, "weight": 2.0},
		"old_battery": {"display_name": "Old Battery", "amount": 1, "weight": 4.0},
	}
	outpost_requirements[second_id] = {
		"copper_wire": {"display_name": "Copper Wire", "amount": 2, "weight": 1.5},
		"signal_core": {"display_name": "Signal Core", "amount": 1, "weight": 3.0},
	}
	for outpost_id in [first_id, second_id]:
		var pos: Vector2 = context.selected_outpost_positions.get(outpost_id, Vector2.ZERO)
		var station = _make_interactable(outpost_id, "outpost", "Outpost %s" % outpost_id, pos, Color(0.45, 0.24, 0.10))
		station.payload = {"repaired": false, "requirements": outpost_requirements[outpost_id]}
		outpost_root.add_child(station)

func _spawn_requirement_materials() -> void:
	for outpost_id in outpost_requirements.keys():
		var base_pos: Vector2 = run_director.context.selected_outpost_positions.get(outpost_id, Vector2.ZERO)
		var requirements: Dictionary = outpost_requirements[outpost_id]
		var material_points := _get_material_points_for_outpost(base_pos, requirements.size())
		var offset := 0
		for item_id in requirements.keys():
			var data: Dictionary = requirements[item_id]
			var pos: Vector2 = material_points[offset].global_position if offset < material_points.size() else base_pos + _u(Vector2(-2.5 + offset * 1.3, 3.0 + offset * 0.8))
			var pickup = _make_interactable("pickup_%s" % item_id, "material", data.display_name, pos, Color(0.2, 0.8, 0.35))
			pickup.payload = {"item": _item(item_id, data.display_name, data.amount, data.weight, 5)}
			outpost_root.add_child(pickup)
			offset += 1

func _get_material_points_for_outpost(base_pos: Vector2, count: int) -> Array:
	var points := _get_layout_points("MaterialSpawnPoints")
	points.sort_custom(func(a, b): return a.global_position.distance_squared_to(base_pos) < b.global_position.distance_squared_to(base_pos))
	return points.slice(0, count)

func _make_interactable(id: String, type: String, label_text: String, pos: Vector2, color: Color):
	var area := Area2D.new()
	area.name = id
	area.script = InteractableScript
	area.interact_id = id
	area.interact_type = type
	area.display_name = label_text
	area.position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0 * UNIT
	shape.shape = circle
	area.add_child(shape)
	var box := ColorRect.new()
	box.color = color
	var visual_units := OUTPOST_SIZE_UNITS if type == "outpost" else RESOURCE_SIZE_UNITS
	box.size = _u(visual_units)
	box.position = -box.size * 0.5
	box.z_index = 10
	area.add_child(box)
	var label := _make_world_label(label_text, Vector2(-box.size.x * 0.5, -box.size.y * 0.5 - 34), area)
	label.z_index = 20
	area.player_entered.connect(_on_interactable_entered)
	area.player_exited.connect(_on_interactable_exited)
	interactables.append(area)
	return area

func _make_world_label(text: String, pos: Vector2, parent: Node) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(160, 44)
	parent.add_child(label)
	return label

func _on_interactable_entered(node) -> void:
	nearest_interactable = node
	_refresh_ui()

func _on_interactable_exited(node) -> void:
	if nearest_interactable == node:
		nearest_interactable = null
	_refresh_ui()

func _try_interact() -> void:
	if nearest_interactable == null:
		return
	match nearest_interactable.interact_type:
		"container":
			_open_container(nearest_interactable)
		"material":
			_pick_material(nearest_interactable)
		"outpost":
			_try_repair_outpost(nearest_interactable)

func _open_container(container) -> void:
	if container.payload.get("state", "") != "available":
		prompt_label.text = "Container already opened."
		return
	container.payload.state = "opened"
	opened_container = container
	opened_loot = []
	for item in container.payload.get("rewards", []):
		opened_loot.append(item.duplicate(true))
	loot_panel.visible = true
	container.modulate = Color(0.45, 0.45, 0.45)
	_refresh_ui()

func _take_all_loot() -> void:
	var remaining: Array[Dictionary] = []
	for item in opened_loot:
		if not run_director.inventory_component.add_item(item):
			remaining.append(item)
	opened_loot = remaining
	if opened_loot.is_empty():
		loot_panel.visible = false
		if is_instance_valid(opened_container) and opened_container.interact_type == "container":
			_remove_interactable(opened_container)
		opened_container = null
	_refresh_ui()

func _pick_material(pickup) -> void:
	var item: Dictionary = pickup.payload.get("item", {})
	if run_director.inventory_component.add_item(item):
		interactables.erase(pickup)
		if nearest_interactable == pickup:
			nearest_interactable = null
		pickup.queue_free()
	_refresh_ui()

func _try_repair_outpost(station) -> void:
	if station.payload.get("repaired", false):
		prompt_label.text = "Outpost already repaired."
		return
	var requirements: Dictionary = station.payload.get("requirements", {})
	if not _has_requirements(requirements):
		prompt_label.text = "Missing materials: %s" % _missing_requirements_text(requirements)
		return
	run_director.on_outpost_repair_started(station.interact_id)
	for item_id in requirements.keys():
		run_director.inventory_component.remove_item(StringName(item_id), int(requirements[item_id].amount))
	station.payload.repaired = true
	repaired_outposts[station.interact_id] = true
	station.modulate = Color(0.3, 1.0, 0.5)
	run_director.on_outpost_repaired(station.interact_id)
	_refresh_ui()

func _has_requirements(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if _inventory_count(item_id) < int(requirements[item_id].amount):
			return false
	return true

func _missing_requirements_text(requirements: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in requirements.keys():
		var need := int(requirements[item_id].amount)
		var have := _inventory_count(item_id)
		if have < need:
			parts.append("%s %s/%s" % [requirements[item_id].display_name, have, need])
	return ", ".join(parts)

func _inventory_count(item_id: String) -> int:
	var count := 0
	for stack in run_director.inventory_component.items:
		if str(stack.item_id) == item_id:
			count += int(stack.amount)
	return count

func _deposit_all() -> void:
	if run_director.context == null or run_director.context.active_safe_zone_id != "home":
		prompt_label.text = "Return home to deposit."
		return
	var index := 0
	while index < run_director.inventory_component.items.size():
		if not run_director.deposit_inventory_item_to_home(index):
			index += 1
	_refresh_ui()

func _try_extract() -> void:
	if run_director.context == null:
		return
	if not run_director.context.is_extraction_unlocked:
		prompt_label.text = "Repair both outposts first."
		return
	if run_director.context.active_safe_zone_id != "home":
		prompt_label.text = "Extract from home."
		return
	run_director.on_extraction_started()
	var gained: Array = []
	gained.append_array(run_director.inventory_component.get_items_snapshot())
	gained.append_array(run_director.home_storage_component.get_items_snapshot())
	if _game_state:
		_game_state.add_to_warehouse(gained)
		_game_state.last_run_result = "Extraction success: %s item stacks returned." % gained.size()
	run_director.on_extraction_completed()
	get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

func _on_stability_changed(current: float, _max_value: float, _stage: int) -> void:
	if current <= 0.0:
		if _game_state:
			_game_state.last_run_result = "Run failed: stability depleted. Stored home items kept."
			_game_state.add_to_warehouse(run_director.home_storage_component.get_items_snapshot())
		call_deferred("_return_to_base_after_death")

func _return_to_base_after_death() -> void:
	get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

func _on_weight_changed(_current_weight: float, _max_weight: float, _stage: int) -> void:
	if player and run_director.weight_component:
		player.speed_multiplier = run_director.weight_component.speed_multiplier

func _refresh_ui() -> void:
	if run_director.context == null:
		return
	var phase: String = run_director.state_machine.phase_name(run_director.state_machine.current_phase)
	hud_label.text = "WASD move | F interact | Tab backpack | E extract\nPhase: %s | Stability: %d | Weight: %.1f/%.1f %s | Outposts: %d/2 | Extract: %s" % [
		phase,
		int(run_director.context.player_stability),
		run_director.context.current_weight,
		run_director.context.weight_limit,
		run_director.context.weight_stage,
		run_director.context.repaired_outpost_count,
		str(run_director.context.is_extraction_unlocked),
	]
	if nearest_interactable:
		prompt_label.text = "F: %s (%s)" % [nearest_interactable.display_name, nearest_interactable.interact_type]
	elif run_director.context.active_safe_zone_id == "home":
		prompt_label.text = "Home safe zone: recover, deposit, extract after both outposts."
	else:
		prompt_label.text = ""
	inventory_label.text = _items_text("Backpack", run_director.inventory_component.get_items_snapshot())
	loot_label.text = _items_text("Loot", opened_loot)
	deposit_button.disabled = run_director.context.active_safe_zone_id != "home"
	extract_button.disabled = not run_director.context.is_extraction_unlocked or run_director.context.active_safe_zone_id != "home"

func _items_text(title: String, items: Array) -> String:
	var lines: Array[String] = [title + ":"]
	if items.is_empty():
		lines.append("empty")
	for item in items:
		if item is Dictionary:
			lines.append("- %s x%s (w %.1f)" % [item.get("display_name", item.get("item_id", "")), item.get("amount", 0), float(item.get("weight_per_unit", 0.0))])
	return "\n".join(lines)

func _item(id: String, display_name: String, amount: int, weight: float, stack_limit: int) -> Dictionary:
	return {
		"item_id": id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": stack_limit,
		"item_type": "material",
	}

func _random_container_position() -> Vector2:
	var points := _get_layout_points("ContainerSpawnPoints")
	if points.is_empty():
		return _u(Vector2(18.0 + randf() * 98.0, -42.0 + randf() * 84.0))
	_last_container_spawn_point_index = (_last_container_spawn_point_index + 1) % points.size()
	return points[_last_container_spawn_point_index].global_position

func _toggle_inventory_panel() -> void:
	inventory_panel.visible = not inventory_panel.visible
	_refresh_ui()

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
	var viewport_size := get_viewport_rect().size
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
	for interactable in interactables.duplicate():
		if not is_instance_valid(interactable) or interactable.interact_type != "container":
			continue
		if interactable.payload.get("state", "") != "available":
			continue
		interactable.payload.lifetime = float(interactable.payload.get("lifetime", 0.0)) - delta
		if interactable.payload.lifetime <= 0.0:
			_remove_interactable(interactable)

func _remove_interactable(interactable) -> void:
	if nearest_interactable == interactable:
		nearest_interactable = null
	interactables.erase(interactable)
	if is_instance_valid(interactable):
		interactable.visible = false
		if interactable is Area2D:
			interactable.monitoring = false
			interactable.monitorable = false
		interactable.queue_free()

func _pick_rarity() -> String:
	var roll := randf()
	if roll < 0.6:
		return "C"
	if roll < 0.85:
		return "B"
	if roll < 0.97:
		return "A"
	return "S"

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"C":
			return Color(0.78, 0.78, 0.78)
		"B":
			return Color(0.55, 0.78, 1.0)
		"A":
			return Color(0.78, 0.58, 1.0)
		"S":
			return Color(1.0, 0.84, 0.36)
		_:
			return Color.WHITE

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * UNIT
	return float(value) * UNIT

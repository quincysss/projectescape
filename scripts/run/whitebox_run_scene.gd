extends Node2D

const PlayerScript := preload("res://scripts/player/whitebox_player.gd")
const InteractableScript := preload("res://scripts/run/whitebox_interactable.gd")
const VisionCircleScript := preload("res://scripts/vision/vision_debug_circle.gd")
const VisionMaskScript := preload("res://scripts/vision/vision_mask_overlay.gd")
const LootInteractionControllerScript := preload("res://scripts/run/loot_interaction_controller.gd")
const RunEndControllerScript := preload("res://scripts/run/run_end_controller.gd")
const OutpostRepairControllerScript := preload("res://scripts/run/outpost_repair_controller.gd")
const InteractionProgressControllerScript := preload("res://scripts/run/interaction_progress_controller.gd")
const ContainerSpawnControllerScript := preload("res://scripts/run/container_spawn_controller.gd")
const OutpostMaterialSpawnControllerScript := preload("res://scripts/run/outpost_material_spawn_controller.gd")
const TerrainGroundTextures := [
	preload("res://assets/map/terrain/ground/terrain_ground_base_tile_1024_04.png"),
	preload("res://assets/map/terrain/ground/terrain_ground_base_tile_1024_05.png"),
]
const BlockFillTextures := [
	preload("res://assets/map/blocks/fill/block_fill_dirty_02.png"),
	preload("res://assets/map/blocks/fill/block_fill_cracked_02.png"),
	preload("res://assets/map/blocks/fill/block_fill_clean_02.png"),
]
const BlockEdgeTexture := preload("res://assets/map/blocks/edge/block_edge_straight_long_02.png")
const BlockCornerTexture := preload("res://assets/map/blocks/edge/block_corner_outer_round_01.png")
const BlockEntranceGapTexture := preload("res://assets/map/blocks/cut/block_edge_entrance_gap_01.png")
const BlockRubbleTexture := preload("res://assets/map/blocks/overlay/block_rubble_patch_02.png")
const BLOCK_ART_USE_EXPERIMENTAL_EDGES := false
const BLOCK_ART_USE_CORNER_PIECES := false
const BLOCK_ART_USE_TILED_FILL := false

const UNIT := 64.0
const MAP_UNITS := Vector2(280.0, 220.0)
const MAP_ORIGIN_UNITS := Vector2(-140.0, -110.0)
const HOME_SIZE_UNITS := Vector2(10.0, 8.0)
const HOME_SAFE_SIZE_UNITS := Vector2(12.0, 10.0)
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const CONTAINER_VISUAL_SIZE_UNITS := Vector2(3.4, 3.4)
const MATERIAL_VISUAL_SIZE_UNITS := Vector2(2.0, 2.0)
const MAIN_ROAD_WIDTH_UNITS := 8.0
const SECONDARY_ROAD_WIDTH_UNITS := 6.0
const ALLEY_WIDTH_UNITS := 4.0
const PLAYER_FOLLOW_ZOOM := Vector2(0.28, 0.28)
const HOME_OVERVIEW_MAX_ZOOM := 0.11
const HOME_OVERVIEW_MIN_ZOOM := 0.025
const HOME_OVERVIEW_PADDING_UNITS := Vector2(0.0, 0.0)
const CAMERA_TRANSITION_SECONDS := 0.5
const CONTAINER_OPEN_HOLD_SECONDS := 0.8
const OUTPOST_REPAIR_HOLD_SECONDS := 1.5
const EXTRACTION_HOLD_SECONDS := 1.2
const SHOW_DEBUG_VISION_CIRCLE := false
const TERRAIN_GROUND_TILE_UNITS := Vector2(16.0, 16.0)
const BLOCK_FILL_TILE_UNITS := Vector2(4.0, 4.0)
const BLOCK_EDGE_THICKNESS_UNITS := 1.6
const MAP_BOUNDARY_STRIP_UNITS := 8.0

@onready var run_director: RunDirector = $RunDirector
@onready var world_root: Node2D = $WorldRoot
@onready var map_visual_root: Node2D = $WorldRoot/MapVisual
@onready var road_visual_root: Node2D = $WorldRoot/MapVisual/RoadVisual
@onready var block_visual_root: Node2D = $WorldRoot/MapVisual/BlockVisual
@onready var building_visual_root: Node2D = $WorldRoot/MapVisual/BuildingVisual
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
var _enterable_exception_rects: Array[Rect2] = []

var hud_label: Label
var prompt_label: Label
var inventory_panel: Panel
var inventory_label: Label
var loot_panel: Panel
var loot_label: Label
var home_storage_panel: Panel
var home_storage_label: Label
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
var _status_prompt: String = ""
var _home_storage_user_closed: bool = false
var _extract_button_held: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_camera_for_viewport()

func _ready() -> void:
	_ensure_input_actions()
	_game_state = get_node_or_null("/root/GameState")
	_create_runtime_controllers()
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

func _create_runtime_controllers() -> void:
	loot_interaction_controller = LootInteractionControllerScript.new()
	run_end_controller = RunEndControllerScript.new()
	run_end_controller.setup(run_director, _game_state)
	outpost_repair_controller = OutpostRepairControllerScript.new()
	outpost_repair_controller.setup(run_director, repaired_outposts)
	interaction_progress_controller = InteractionProgressControllerScript.new()
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
	_update_active_interaction(delta)
	if container_spawn_controller != null:
		container_spawn_controller.update(delta, interactables)
	_update_container_lifetime_visuals()
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("toggle_inventory"):
		_toggle_inventory_panel()
	if Input.is_action_just_pressed("extract"):
		_try_extract()
	_refresh_ui()

func _build_whitebox_world() -> void:
	_clear_generated_visual_layers()
	_create_ground()
	_generate_road_visuals()
	_create_home_visual()
	_create_player()
	_create_camera()
	_create_vision_circle()

func _clear_generated_visual_layers() -> void:
	for layer in [block_visual_root, building_visual_root, prop_visual_root, decal_visual_root]:
		for child in layer.get_children():
			layer.remove_child(child)
			child.free()

func _generate_road_visuals() -> void:
	if road_visual_root.has_method("_clear_generated"):
		road_visual_root._clear_generated()

func _create_ground() -> void:
	_walkable_rects.clear()
	_walkable_polygons.clear()
	_enterable_exception_rects = _get_enterable_exception_rects()
	_create_terrain_ground_base()
	var ground := ColorRect.new()
	ground.name = "WhiteboxGround"
	ground.color = Color(0.12, 0.14, 0.12, 0.0)
	ground.size = _u(MAP_UNITS)
	ground.position = _u(MAP_ORIGIN_UNITS)
	ground.z_index = -120
	ground.set_meta("_generated_whitebox_ground", true)
	road_visual_root.add_child(ground)

	for street in _get_layout_rects("StreetWalkable"):
		_add_street_from_layout(street)
	for exception_rect in _enterable_exception_rects:
		_walkable_rects.append(exception_rect)
	for block in _get_layout_rects("BlockSolid"):
		_add_block_from_layout(block)
	for building in _get_layout_rects("Buildings"):
		_add_visual_building_from_layout(building)
	_create_map_boundary_visuals()

func _create_terrain_ground_base() -> void:
	for child in road_visual_root.get_children():
		if child.has_meta("_generated_whitebox_ground") or child.has_meta("_generated_road_art"):
			road_visual_root.remove_child(child)
			child.free()
	var terrain_root := map_visual_root.get_node_or_null("TerrainGroundBase")
	if terrain_root == null:
		terrain_root = Node2D.new()
		terrain_root.name = "TerrainGroundBase"
		map_visual_root.add_child(terrain_root)
		map_visual_root.move_child(terrain_root, 0)
	for child in terrain_root.get_children():
		if child.has_meta("_generated_terrain_ground"):
			terrain_root.remove_child(child)
			child.free()
	var map_rect := Rect2(_u(MAP_ORIGIN_UNITS), _u(MAP_UNITS))
	var tile_size: Vector2 = TerrainGroundTextures[0].get_size()
	var cols: int = int(ceil(map_rect.size.x / tile_size.x))
	var rows: int = int(ceil(map_rect.size.y / tile_size.y))
	for y in range(rows):
		for x in range(cols):
			var texture: Texture2D = TerrainGroundTextures[(x + y) % TerrainGroundTextures.size()]
			var sprite := Sprite2D.new()
			sprite.name = "TerrainGround_%03d_%03d" % [x, y]
			sprite.texture = texture
			sprite.centered = true
			sprite.position = map_rect.position + Vector2((float(x) + 0.5) * tile_size.x, (float(y) + 0.5) * tile_size.y)
			sprite.z_index = -115
			sprite.set_meta("_generated_terrain_ground", true)
			terrain_root.add_child(sprite)

func _add_street_from_layout(layout) -> void:
	var color := Color(0.42, 0.42, 0.42, 0.0)
	if layout.subtype == "plaza" or layout.rect_kind == "plaza":
		color = Color(0.34, 0.34, 0.32, 0.0)
	_add_layout_polygon(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(UNIT), color, -90, road_visual_root)
	_add_road_art_from_layout(layout)
	_walkable_polygons.append(layout.get_world_corners_px(UNIT))
	_walkable_rects.append(layout.get_rect_px(UNIT))

func _add_block_from_layout(layout) -> void:
	_add_solid_layout_rect(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(UNIT), Color(0.86, 0.86, 0.82), -70)
	_add_block_art_from_layout(layout)

func _add_visual_building_from_layout(layout) -> void:
	_add_layout_polygon(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(UNIT), Color(0.92, 0.92, 0.9, 0.0), -40, building_visual_root)

func _add_road_art_from_layout(layout) -> void:
	var road_rect: Rect2 = layout.get_rect_px(UNIT)
	_add_tiled_texture_rect(road_visual_root, "%s_Ground" % layout.get_rect_id(), TerrainGroundTextures, road_rect, -95)

func _create_map_boundary_visuals() -> void:
	var boundary_root := Node2D.new()
	boundary_root.name = "MapBoundaryVisual"
	boundary_root.set_meta("_generated_map_boundary", true)
	building_visual_root.add_child(boundary_root)
	var map_rect := Rect2(_u(MAP_ORIGIN_UNITS), _u(MAP_UNITS))
	var strip: float = MAP_BOUNDARY_STRIP_UNITS * UNIT
	_add_boundary_ground_strip(boundary_root, "BoundaryTop", Rect2(map_rect.position, Vector2(map_rect.size.x, strip)), 0)
	_add_boundary_ground_strip(boundary_root, "BoundaryBottom", Rect2(Vector2(map_rect.position.x, map_rect.end.y - strip), Vector2(map_rect.size.x, strip)), 1)
	_add_boundary_ground_strip(boundary_root, "BoundaryLeft", Rect2(map_rect.position, Vector2(strip, map_rect.size.y)), 2)
	_add_boundary_ground_strip(boundary_root, "BoundaryRight", Rect2(Vector2(map_rect.end.x - strip, map_rect.position.y), Vector2(strip, map_rect.size.y)), 3)

func _add_boundary_ground_strip(parent: Node, sprite_name: String, rect: Rect2, texture_index: int) -> void:
	var texture: Texture2D = TerrainGroundTextures[texture_index % TerrainGroundTextures.size()]
	var sprite := _make_scaled_sprite(sprite_name, texture, rect, -35)
	sprite.modulate = Color(0.35, 0.38, 0.34)
	sprite.set_meta("_generated_map_boundary_piece", true)
	parent.add_child(sprite)

func _add_tiled_texture_rect(parent: Node, prefix: String, textures: Array, rect: Rect2, z: int) -> void:
	var tile_size: Vector2 = textures[0].get_size()
	var cols: int = int(ceil(rect.size.x / tile_size.x))
	var rows: int = int(ceil(rect.size.y / tile_size.y))
	for y in range(rows):
		for x in range(cols):
			var tile_pos := rect.position + Vector2(float(x) * tile_size.x, float(y) * tile_size.y)
			var remaining := rect.end - tile_pos
			var region_size := Vector2(minf(tile_size.x, remaining.x), minf(tile_size.y, remaining.y))
			if region_size.x <= 0.0 or region_size.y <= 0.0:
				continue
			var texture: Texture2D = textures[(x + y) % textures.size()]
			var sprite := Sprite2D.new()
			sprite.name = "%s_%03d_%03d" % [prefix, x, y]
			sprite.texture = texture
			sprite.centered = true
			sprite.region_enabled = true
			sprite.region_rect = Rect2(Vector2.ZERO, region_size)
			sprite.position = tile_pos + region_size * 0.5
			sprite.z_index = z
			sprite.set_meta("_generated_road_art", true)
			parent.add_child(sprite)

func _add_block_art_from_layout(layout) -> void:
	var block_rect: Rect2 = layout.get_rect_px(UNIT)
	var art_root := Node2D.new()
	art_root.name = "%s_Art" % layout.get_rect_id()
	art_root.set_meta("_generated_block_visual", true)
	block_visual_root.add_child(art_root)
	if BLOCK_ART_USE_TILED_FILL:
		_add_block_fill_tiles(art_root, block_rect)
	else:
		_add_block_single_fill(art_root, block_rect, layout.get_rect_id())
	if BLOCK_ART_USE_EXPERIMENTAL_EDGES:
		_add_block_edges(art_root, block_rect)

func _add_block_single_fill(parent: Node, block_rect: Rect2, rect_id: String) -> void:
	var texture_index: int = int(abs(hash(rect_id)) % BlockFillTextures.size())
	parent.add_child(_make_scaled_sprite("SingleFill", BlockFillTextures[texture_index], block_rect, -68))

func _add_block_fill_tiles(parent: Node, block_rect: Rect2) -> void:
	var tile_size := BLOCK_FILL_TILE_UNITS * UNIT
	var cols := int(ceil(block_rect.size.x / tile_size.x))
	var rows := int(ceil(block_rect.size.y / tile_size.y))
	for y in range(rows):
		for x in range(cols):
			var tile_pos := block_rect.position + Vector2(x * tile_size.x, y * tile_size.y)
			var remaining := (block_rect.position + block_rect.size) - tile_pos
			var tile_rect := Rect2(tile_pos, Vector2(minf(tile_size.x, remaining.x), minf(tile_size.y, remaining.y)))
			if tile_rect.size.x <= 0.0 or tile_rect.size.y <= 0.0:
				continue
			var texture: Texture2D = BlockFillTextures[(x + y * 2) % BlockFillTextures.size()]
			parent.add_child(_make_scaled_sprite("Fill_%02d_%02d" % [x, y], texture, tile_rect, -68))

func _add_block_edges(parent: Node, block_rect: Rect2) -> void:
	var edge_size := BlockEdgeTexture.get_size()
	var corner_size := BlockCornerTexture.get_size()
	var inset_x := corner_size.x * 0.45 if BLOCK_ART_USE_CORNER_PIECES else 0.0
	var inset_y := corner_size.y * 0.45 if BLOCK_ART_USE_CORNER_PIECES else 0.0
	_add_edge_run(parent, "EdgeTop", block_rect.position + Vector2(inset_x, edge_size.y * 0.5), Vector2.RIGHT, block_rect.size.x - inset_x * 2.0, 0.0)
	_add_edge_run(parent, "EdgeBottom", Vector2(block_rect.position.x + inset_x, block_rect.position.y + block_rect.size.y - edge_size.y * 0.5), Vector2.RIGHT, block_rect.size.x - inset_x * 2.0, 180.0)
	_add_edge_run(parent, "EdgeLeft", block_rect.position + Vector2(edge_size.y * 0.5, inset_y), Vector2.DOWN, block_rect.size.y - inset_y * 2.0, -90.0)
	_add_edge_run(parent, "EdgeRight", Vector2(block_rect.position.x + block_rect.size.x - edge_size.y * 0.5, block_rect.position.y + inset_y), Vector2.DOWN, block_rect.size.y - inset_y * 2.0, 90.0)
	if not BLOCK_ART_USE_CORNER_PIECES:
		return
	_add_corner_sprite(parent, "CornerTopLeft", block_rect.position + corner_size * 0.5, false, true)
	_add_corner_sprite(parent, "CornerTopRight", Vector2(block_rect.position.x + block_rect.size.x - corner_size.x * 0.5, block_rect.position.y + corner_size.y * 0.5), true, true)
	_add_corner_sprite(parent, "CornerBottomRight", block_rect.position + block_rect.size - corner_size * 0.5, true, false)
	_add_corner_sprite(parent, "CornerBottomLeft", Vector2(block_rect.position.x + corner_size.x * 0.5, block_rect.position.y + block_rect.size.y - corner_size.y * 0.5), false, false)

func _add_edge_run(parent: Node, edge_name: String, start_pos: Vector2, direction: Vector2, run_length: float, edge_rotation_degrees: float) -> void:
	var segment_length: float = BlockEdgeTexture.get_size().x
	var segment_count: int = maxi(1, int(floor(run_length / segment_length)))
	var used_length: float = float(segment_count) * segment_length
	var centered_start: Vector2 = start_pos + direction * ((run_length - used_length) * 0.5 + segment_length * 0.5)
	for index in range(segment_count):
		var sprite := _make_native_sprite("%s_%02d" % [edge_name, index], BlockEdgeTexture, centered_start + direction * segment_length * index, -66)
		sprite.rotation_degrees = edge_rotation_degrees
		parent.add_child(sprite)

func _add_corner_sprite(parent: Node, sprite_name: String, pos: Vector2, flip_h: bool, flip_v: bool) -> void:
	var sprite := _make_native_sprite(sprite_name, BlockCornerTexture, pos, -65)
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	parent.add_child(sprite)

func _add_home_block_entrance(parent: Node, block_rect: Rect2) -> void:
	var entrance_size := Vector2(8.0, 3.0) * UNIT
	var entrance_center := Vector2(player_root.global_position.x, block_rect.position.y + block_rect.size.y - entrance_size.y * 0.35)
	var entrance_rect := Rect2(entrance_center - entrance_size * 0.5, entrance_size)
	parent.add_child(_make_scaled_sprite("HomeEntranceGap", BlockEntranceGapTexture, entrance_rect, -64))

func _add_home_block_decals(parent: Node, block_rect: Rect2) -> void:
	var rubble_size := Vector2(8.0, 3.0) * UNIT
	var rubble_rect := Rect2(block_rect.position + Vector2(block_rect.size.x * 0.08, block_rect.size.y * 0.58), rubble_size)
	parent.add_child(_make_scaled_sprite("RubblePatch", BlockRubbleTexture, rubble_rect, -63))

func _make_scaled_sprite(sprite_name: String, texture: Texture2D, rect: Rect2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = rect.get_center()
	sprite.scale = rect.size / texture.get_size()
	sprite.z_index = z
	return sprite

func _make_native_sprite(sprite_name: String, texture: Texture2D, pos: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = pos
	sprite.z_index = z
	return sprite

func _add_layout_polygon(polygon_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array, color: Color, z: int, parent: Node = null) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = polygon_name
	polygon.color = color
	polygon.polygon = local_polygon
	polygon.z_index = z
	var target_parent := world_root if parent == null else parent
	target_parent.add_child(polygon)
	polygon.global_transform = source_transform
	return polygon

func _add_solid_layout_rect(block_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array, color: Color, z: int) -> void:
	var body := StaticBody2D.new()
	body.name = block_name
	body.z_index = z
	world_root.add_child(body)
	body.global_transform = source_transform
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	visual.polygon = local_polygon
	body.add_child(visual)
	var block_local_rect := Rect2(local_polygon[0], local_polygon[2] - local_polygon[0])
	for collision_rect in _carve_enterable_exceptions(block_local_rect, source_transform):
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = collision_rect.size
		shape.position = collision_rect.position + collision_rect.size * 0.5
		shape.shape = rect
		body.add_child(shape)

func _carve_enterable_exceptions(block_local_rect: Rect2, source_transform: Transform2D) -> Array[Rect2]:
	var collision_rects: Array[Rect2] = [block_local_rect]
	var inverse_transform := source_transform.affine_inverse()
	for exception_rect in _enterable_exception_rects:
		var exception_local_rect := _rect_to_local(exception_rect, inverse_transform)
		var next_rects: Array[Rect2] = []
		for collision_rect in collision_rects:
			next_rects.append_array(_subtract_rect(collision_rect, exception_local_rect))
		collision_rects = next_rects
	return collision_rects

func _rect_to_local(world_rect: Rect2, inverse_transform: Transform2D) -> Rect2:
	var corners := [
		world_rect.position,
		world_rect.position + Vector2(world_rect.size.x, 0.0),
		world_rect.position + world_rect.size,
		world_rect.position + Vector2(0.0, world_rect.size.y),
	]
	var min_pos: Vector2 = inverse_transform * corners[0]
	var max_pos := min_pos
	for corner in corners:
		var local_corner: Vector2 = inverse_transform * corner
		min_pos.x = minf(min_pos.x, local_corner.x)
		min_pos.y = minf(min_pos.y, local_corner.y)
		max_pos.x = maxf(max_pos.x, local_corner.x)
		max_pos.y = maxf(max_pos.y, local_corner.y)
	return Rect2(min_pos, max_pos - min_pos)

func _subtract_rect(source_rect: Rect2, cut_rect: Rect2) -> Array[Rect2]:
	var intersection := source_rect.intersection(cut_rect)
	if intersection.size.x <= 0.0 or intersection.size.y <= 0.0:
		return [source_rect]
	var pieces: Array[Rect2] = []
	var source_end := source_rect.position + source_rect.size
	var cut_end := intersection.position + intersection.size
	if intersection.position.y > source_rect.position.y:
		pieces.append(Rect2(source_rect.position, Vector2(source_rect.size.x, intersection.position.y - source_rect.position.y)))
	if cut_end.y < source_end.y:
		pieces.append(Rect2(Vector2(source_rect.position.x, cut_end.y), Vector2(source_rect.size.x, source_end.y - cut_end.y)))
	if intersection.position.x > source_rect.position.x:
		pieces.append(Rect2(Vector2(source_rect.position.x, intersection.position.y), Vector2(intersection.position.x - source_rect.position.x, intersection.size.y)))
	if cut_end.x < source_end.x:
		pieces.append(Rect2(Vector2(cut_end.x, intersection.position.y), Vector2(source_end.x - cut_end.x, intersection.size.y)))
	return pieces.filter(func(rect): return rect.size.x > 0.0 and rect.size.y > 0.0)

func _get_enterable_exception_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	rects.append(Rect2(player_root.global_position - _u(HOME_SAFE_SIZE_UNITS) * 0.5, _u(HOME_SAFE_SIZE_UNITS)))
	for point in _get_outpost_candidate_points():
		rects.append(Rect2(point.global_position - _u(OUTPOST_SIZE_UNITS) * 0.5, _u(OUTPOST_SIZE_UNITS)))
	for layout in _get_layout_rects("Buildings"):
		if layout.rect_kind == "home" or layout.rect_kind == "outpost" or layout.walkable:
			rects.append(layout.get_rect_px(UNIT))
	return rects

func _get_outpost_candidate_points() -> Array[Node2D]:
	var root := get_node_or_null("WorldRoot/OutpostRoot/OutpostCandidates")
	if root == null:
		return []
	var points: Array[Node2D] = []
	for child in root.find_children("*", "Node2D", true, false):
		if child.has_method("get_candidate_id"):
			points.append(child)
	return points

func _get_layout_rects(section_name: String) -> Array:
	var section := get_node_or_null("WorldRoot/MapLayout/%s" % section_name)
	if section == null:
		return []
	var rects := []
	for child in section.find_children("*", "", true, false):
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
	player.base_speed = 12.0 * UNIT
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
	hud_label.size = Vector2(760, 78)
	hud_label.add_theme_font_size_override("font_size", 18)
	ui_root.add_child(hud_label)

	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.position = Vector2(16, 96)
	prompt_label.size = Vector2(900, 44)
	prompt_label.add_theme_font_size_override("font_size", 18)
	ui_root.add_child(prompt_label)

	backpack_button = Button.new()
	backpack_button.name = "BackpackButton"
	backpack_button.text = "背包"
	backpack_button.position = Vector2(820, 16)
	backpack_button.size = Vector2(96, 38)
	backpack_button.pressed.connect(_toggle_inventory_panel)
	ui_root.add_child(backpack_button)

	extract_hud_button = Button.new()
	extract_hud_button.name = "ExtractHUDButton"
	extract_hud_button.text = "撤离未解锁"
	extract_hud_button.position = Vector2(928, 16)
	extract_hud_button.size = Vector2(140, 38)
	extract_hud_button.button_down.connect(_begin_extraction_hold_from_button)
	extract_hud_button.button_up.connect(_release_extraction_hold_button)
	ui_root.add_child(extract_hud_button)

	inventory_panel = _make_panel(Vector2(16, 154), Vector2(390, 360), "背包")
	inventory_label = Label.new()
	inventory_label.position = Vector2(16, 52)
	inventory_label.size = Vector2(358, 288)
	inventory_label.clip_text = true
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_panel.add_child(inventory_label)

	ui_root.add_child(inventory_panel)
	inventory_panel.visible = false

	home_storage_panel = _make_panel(Vector2(422, 154), Vector2(390, 360), "家中储存")
	home_storage_label = Label.new()
	home_storage_label.position = Vector2(16, 52)
	home_storage_label.size = Vector2(358, 230)
	home_storage_label.clip_text = true
	home_storage_label.add_theme_font_size_override("font_size", 16)
	home_storage_panel.add_child(home_storage_label)
	deposit_button = Button.new()
	deposit_button.text = "存入家中"
	deposit_button.position = Vector2(16, 300)
	deposit_button.size = Vector2(172, 40)
	deposit_button.pressed.connect(_deposit_all)
	home_storage_panel.add_child(deposit_button)
	extract_button = Button.new()
	extract_button.text = "撤离"
	extract_button.position = Vector2(202, 300)
	extract_button.size = Vector2(172, 40)
	extract_button.button_down.connect(_begin_extraction_hold_from_button)
	extract_button.button_up.connect(_release_extraction_hold_button)
	home_storage_panel.add_child(extract_button)
	ui_root.add_child(home_storage_panel)
	home_storage_panel.visible = false

	loot_panel = _make_panel(Vector2(422, 154), Vector2(390, 300), "容器 / 材料")
	loot_label = Label.new()
	loot_label.position = Vector2(16, 52)
	loot_label.size = Vector2(358, 170)
	loot_label.clip_text = true
	loot_label.add_theme_font_size_override("font_size", 16)
	loot_panel.add_child(loot_label)
	take_all_button = Button.new()
	take_all_button.text = "全部拾取"
	take_all_button.position = Vector2(16, 240)
	take_all_button.size = Vector2(172, 40)
	take_all_button.pressed.connect(_take_all_loot)
	loot_panel.add_child(take_all_button)
	ui_root.add_child(loot_panel)
	loot_panel.visible = false

func _make_panel(pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 60
	var label := Label.new()
	label.text = title
	label.position = Vector2(16, 12)
	label.size = Vector2(panel_size.x - 32.0, 28.0)
	label.add_theme_font_size_override("font_size", 20)
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
		var station = _make_interactable(outpost_id, "outpost", "前哨站 %s" % outpost_id, pos, Color(0.45, 0.24, 0.10))
		station.payload = {"repaired": false, "repair_state": "UNREPAIRED", "requirements": outpost_requirements[outpost_id]}
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
	circle.radius = (6.0 if type == "outpost" else 2.0) * UNIT
	shape.shape = circle
	area.add_child(shape)
	var visual_size: Vector2 = _add_interactable_whitebox_visual(area, type, label_text, color)
	var label := _make_world_label(label_text, Vector2(-visual_size.x * 0.5, -visual_size.y * 0.5 - 42), area)
	label.z_index = 20
	area.player_entered.connect(_on_interactable_entered)
	area.player_exited.connect(_on_interactable_exited)
	interactables.append(area)
	return area

func _add_interactable_whitebox_visual(area: Node, type: String, label_text: String, color: Color) -> Vector2:
	match type:
		"outpost":
			var size: Vector2 = _u(OUTPOST_SIZE_UNITS)
			_add_rect_visual(area, "OutpostWhiteboxVisual", size, color, 10)
			return size
		"container":
			var size: Vector2 = _u(CONTAINER_VISUAL_SIZE_UNITS)
			_add_rect_visual(area, "ContainerWhiteboxVisual", size, Color(0.08, 0.08, 0.08, 0.92), 12)
			_add_rect_visual(area, "ContainerLifetimeFill", size, color, 14)
			_add_rect_outline(area, "ContainerWhiteboxOutline", size, Color(0.02, 0.02, 0.02), 10.0, 25)
			_add_center_marker_label(area, _container_marker_text(label_text), size, Color(0.0, 0.0, 0.0), 52)
			_add_container_lifetime_label(area, size)
			return size
		"material":
			var size: Vector2 = _u(MATERIAL_VISUAL_SIZE_UNITS)
			_add_diamond_visual(area, "BuildMaterialWhiteboxVisual", size, color, 12)
			_add_diamond_outline(area, "BuildMaterialWhiteboxOutline", size, Color(0.02, 0.09, 0.04), 8.0, 13)
			_add_center_marker_label(area, "建材", size, Color(0.0, 0.0, 0.0), 22)
			return size
		_:
			var size: Vector2 = _u(RESOURCE_SIZE_UNITS)
			_add_rect_visual(area, "InteractableWhiteboxVisual", size, color, 10)
			return size

func _add_rect_visual(parent: Node, node_name: String, size: Vector2, color: Color, z: int) -> ColorRect:
	var box := ColorRect.new()
	box.name = node_name
	box.color = color
	box.size = size
	box.position = -size * 0.5
	box.z_index = z
	parent.add_child(box)
	return box

func _add_rect_outline(parent: Node, node_name: String, size: Vector2, color: Color, width: float, z: int) -> Line2D:
	var half := size * 0.5
	var outline := Line2D.new()
	outline.name = node_name
	outline.default_color = color
	outline.width = width
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	outline.z_index = z
	parent.add_child(outline)
	return outline

func _add_diamond_visual(parent: Node, node_name: String, size: Vector2, color: Color, z: int) -> Polygon2D:
	var half := size * 0.5
	var diamond := Polygon2D.new()
	diamond.name = node_name
	diamond.color = color
	diamond.polygon = PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	])
	diamond.z_index = z
	parent.add_child(diamond)
	return diamond

func _add_diamond_outline(parent: Node, node_name: String, size: Vector2, color: Color, width: float, z: int) -> Line2D:
	var half := size * 0.5
	var outline := Line2D.new()
	outline.name = node_name
	outline.default_color = color
	outline.width = width
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	])
	outline.z_index = z
	parent.add_child(outline)
	return outline

func _add_center_marker_label(parent: Node, text: String, size: Vector2, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.name = "WhiteboxMarkerLabel"
	label.text = text
	label.position = -size * 0.5
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 30
	parent.add_child(label)
	return label

func _add_container_lifetime_label(parent: Node, size: Vector2) -> Label:
	var label := Label.new()
	label.name = "ContainerLifetimeLabel"
	label.text = "45s"
	label.position = Vector2(-size.x * 0.5, size.y * 0.5 + 6.0)
	label.size = Vector2(size.x, 34.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 31
	parent.add_child(label)
	return label

func _container_marker_text(label_text: String) -> String:
	var grade := label_text.substr(0, 1)
	if ["C", "B", "A", "S"].has(grade):
		return "%s级" % grade
	return "箱"

func _make_world_label(text: String, pos: Vector2, parent: Node) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(160, 44)
	parent.add_child(label)
	return label

func _attach_outpost_safe_zone(station) -> void:
	var safe_zone := Area2D.new()
	safe_zone.name = "%s_SafeZoneArea_10x8" % station.interact_id
	safe_zone.set_meta("outpost_id", station.interact_id)
	safe_zone.set_meta("player_inside", false)
	safe_zone.monitoring = true
	safe_zone.monitorable = false
	var collision := CollisionShape2D.new()
	collision.name = "SafeZoneCollision_10x8"
	var rect := RectangleShape2D.new()
	rect.size = _u(OUTPOST_SIZE_UNITS)
	collision.shape = rect
	safe_zone.add_child(collision)
	safe_zone.body_entered.connect(func(body): _on_outpost_safe_zone_body_entered(station, body))
	safe_zone.body_exited.connect(func(body): _on_outpost_safe_zone_body_exited(station, body))
	station.add_child(safe_zone)
	outpost_safe_zones[station.interact_id] = safe_zone

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
			_open_material(nearest_interactable)
		"outpost":
			_begin_outpost_repair(nearest_interactable)

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
	if interaction_progress_controller.begin(
		"open_container",
		container,
		CONTAINER_OPEN_HOLD_SECONDS,
		Callable(self, "_complete_held_container_open"),
		Callable(self, "_cancel_held_container_open")
	):
		_status_prompt = ""
	_refresh_ui()

func _complete_held_container_open(container) -> void:
	_open_container(container)
	_status_prompt = "容器已打开。"

func _cancel_held_container_open(_container) -> void:
	pass

func _open_container(container) -> void:
	if not loot_interaction_controller.open_container(container):
		prompt_label.text = loot_interaction_controller.last_prompt
		return
	_sync_loot_state()
	_open_loot_transfer_panels()
	_refresh_ui()

func _open_material(pickup) -> void:
	if not loot_interaction_controller.open_material(pickup):
		prompt_label.text = loot_interaction_controller.last_prompt
		return
	_sync_loot_state()
	_open_loot_transfer_panels()
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
	_refresh_ui()

func _open_loot_transfer_panels() -> void:
	loot_panel.visible = true
	inventory_panel.visible = true

func _close_loot_transfer() -> void:
	loot_interaction_controller.close()
	_sync_loot_state()
	loot_panel.visible = false
	inventory_panel.visible = false

func _save_opened_loot_to_source() -> void:
	loot_interaction_controller.save_opened_loot_to_source()
	_sync_loot_state()

func _pick_material(pickup) -> void:
	loot_interaction_controller.pick_material_immediate(
		pickup,
		run_director.inventory_component,
		Callable(self, "_remove_interactable")
	)
	_sync_loot_state()
	_refresh_ui()

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
		_status_prompt = _interaction_cancel_message(interaction_id)
	elif bool(result.get("completed", false)):
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
	if result.accepted:
		_activate_outpost_safe_zone(station)
	if result.accepted and _is_player_inside_outpost_safe_zone(station):
		_enter_repaired_outpost_safe_zone(station)
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
	if run_director.context == null or run_director.context.active_safe_zone_id != "home":
		prompt_label.text = "请回到家中存放物品。"
		return
	var index := 0
	while index < run_director.inventory_component.items.size():
		if not run_director.deposit_inventory_item_to_home(index):
			index += 1
	_refresh_ui()

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
	_refresh_ui()

func _complete_held_extract(_target) -> void:
	if run_end_controller == null:
		return
	var result: Dictionary = run_end_controller.try_extract(get_tree())
	if not result.accepted:
		prompt_label.text = result.message

func _cancel_held_extract(_target) -> void:
	pass

func _on_stability_changed(current: float, _max_value: float, _stage: int) -> void:
	if current <= 0.0:
		call_deferred("_return_to_base_after_death", "stability_depleted")

func _return_to_base_after_death(reason: String = "stability_depleted") -> void:
	if run_end_controller:
		run_end_controller.handle_player_death(get_tree(), reason)
	else:
		get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")

func _on_weight_changed(_current_weight: float, _max_weight: float, _stage: int) -> void:
	if player and run_director.weight_component:
		player.speed_multiplier = run_director.weight_component.speed_multiplier

func _refresh_ui() -> void:
	if run_director.context == null:
		return
	var phase: String = run_director.state_machine.phase_name(run_director.state_machine.current_phase)
	hud_label.text = "WASD移动  F交互  Tab背包  E撤离\n阶段：%s    稳定值：%d    负重：%.1f/%.1f（%s）    前哨：%d/2    撤离：%s" % [
		_phase_name_cn(phase),
		int(run_director.context.player_stability),
		run_director.context.current_weight,
		run_director.context.weight_limit,
		_weight_stage_cn(run_director.context.weight_stage),
		run_director.context.repaired_outpost_count,
		"已解锁" if run_director.context.is_extraction_unlocked else "未解锁",
	]
	var extraction_ready_at_home: bool = run_director.context.is_extraction_unlocked and run_director.context.active_safe_zone_id == "home"
	var extraction_unlocked: bool = run_director.context.is_extraction_unlocked
	var is_home_safe_zone: bool = run_director.context.active_safe_zone_id == "home"
	if interaction_progress_controller != null and interaction_progress_controller.is_active():
		var progress_percent: int = int(round(interaction_progress_controller.get_progress() * 100.0))
		prompt_label.text = "%s中：%s%%" % [
			_interaction_progress_text(interaction_progress_controller.active_id),
			progress_percent,
		]
	elif extraction_ready_at_home:
		prompt_label.text = "撤离已准备：按住 E 或按住“撤离”返回基地。"
	elif not _status_prompt.is_empty():
		prompt_label.text = _status_prompt
	elif nearest_interactable:
		prompt_label.text = "%s：%s（%s）" % [_interact_prompt_prefix(nearest_interactable.interact_type), nearest_interactable.display_name, _interactable_type_name(nearest_interactable.interact_type)]
	elif is_home_safe_zone:
		prompt_label.text = "家中安全区：恢复稳定值，可存放物品。修复两座前哨站后可撤离。"
	elif extraction_unlocked:
		prompt_label.text = "撤离已解锁。请返回家中撤离。"
	else:
		prompt_label.text = ""
	inventory_label.text = _items_text("背包", run_director.inventory_component.get_items_snapshot())
	home_storage_label.text = _items_text("家中储存", run_director.home_storage_component.get_items_snapshot() if run_director.home_storage_component != null else [])
	loot_label.text = _items_text("容器 / 材料", opened_loot)
	_sync_home_storage_ui(is_home_safe_zone)
	deposit_button.disabled = not is_home_safe_zone
	extract_button.disabled = not extraction_ready_at_home
	extract_hud_button.disabled = not extraction_ready_at_home
	extract_hud_button.text = "撤离(E)" if extraction_ready_at_home else ("返回家中" if extraction_unlocked else "撤离未解锁")

func _sync_home_storage_ui(is_home_safe_zone: bool) -> void:
	if not is_home_safe_zone:
		_home_storage_user_closed = false
		home_storage_panel.visible = false
		if not loot_panel.visible:
			inventory_panel.visible = false
		return
	if _home_storage_user_closed:
		home_storage_panel.visible = false
		return
	inventory_panel.visible = true
	home_storage_panel.visible = true

func _items_text(_title: String, items: Array) -> String:
	var lines: Array[String] = []
	if items.is_empty():
		lines.append("空")
	for item in items:
		if item is Dictionary:
			lines.append("%s  x%s  单重 %.1f" % [
				item.get("display_name", item.get("item_id", "")),
				item.get("amount", 0),
				float(item.get("weight_per_unit", 0.0)),
			])
	return "\n".join(lines)

func _phase_name_cn(phase: String) -> String:
	match phase:
		"SPAWN":
			return "出生"
		"OBSERVE":
			return "家中观察"
		"LEAVE_HOME":
			return "离家"
		"SCAVENGE":
			return "探索"
		"RECOVER":
			return "恢复"
		"OUTPOST_PUSH":
			return "修复前哨"
		"GREED_DECISION":
			return "撤离抉择"
		"EXTRACT":
			return "撤离"
		"SETTLEMENT":
			return "结算"
		"FAILED":
			return "失败"
		_:
			return phase

func _weight_stage_cn(stage: String) -> String:
	match stage:
		"LIGHT":
			return "轻装"
		"HEAVY":
			return "重载"
		"OVERLOADED":
			return "超重"
		_:
			return stage

func _interactable_type_name(interact_type: String) -> String:
	match interact_type:
		"container":
			return "容器"
		"material":
			return "前哨材料"
		"outpost":
			return "前哨站"
		_:
			return interact_type

func _interact_prompt_prefix(interact_type: String) -> String:
	match interact_type:
		"container":
			return "按住 F"
		"outpost":
			return "按住 F"
		_:
			return "按 F"

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
	if container_spawn_controller == null:
		return _u(Vector2(18.0 + randf() * 98.0, -42.0 + randf() * 84.0))
	return container_spawn_controller.next_spawn_position()

func _toggle_inventory_panel() -> void:
	var is_home_safe_zone: bool = run_director.context != null and run_director.context.active_safe_zone_id == "home"
	if is_home_safe_zone:
		if inventory_panel.visible or home_storage_panel.visible:
			_home_storage_user_closed = true
			inventory_panel.visible = false
			home_storage_panel.visible = false
		else:
			_home_storage_user_closed = false
			inventory_panel.visible = true
			home_storage_panel.visible = true
	else:
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
	var payload: Dictionary = container.get("payload")
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 45.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var visual := container.get_node_or_null("ContainerWhiteboxVisual") as ColorRect
	var fill := container.get_node_or_null("ContainerLifetimeFill") as ColorRect
	if visual != null and fill != null:
		fill.color = _rarity_color(String(payload.get("rarity", "C")))
		fill.position = visual.position
		fill.size = Vector2(visual.size.x * ratio, visual.size.y)
	var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
	if lifetime_label != null:
		lifetime_label.text = "%ds" % int(ceil(lifetime))

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
	if container_spawn_controller == null:
		return "C"
	return container_spawn_controller.pick_rarity()

func _rarity_color(rarity: String) -> Color:
	if container_spawn_controller == null:
		return Color.WHITE
	return container_spawn_controller.rarity_color(rarity)

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * UNIT
	return float(value) * UNIT

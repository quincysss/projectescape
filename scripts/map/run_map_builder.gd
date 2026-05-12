class_name RunMapBuilder
extends RefCounted

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
const BLOCK_ART_USE_EXPERIMENTAL_EDGES := false
const BLOCK_ART_USE_CORNER_PIECES := false
const BLOCK_ART_USE_TILED_FILL := false
const BLOCK_FILL_TILE_UNITS := Vector2(4.0, 4.0)
const OUTPOST_ENTRY_CLEARANCE_UNITS := Vector2(1.5, 1.5)

var scene: Node
var unit: float
var map_units: Vector2
var map_origin_units: Vector2
var home_safe_size_units: Vector2
var outpost_size_units: Vector2


func setup(
	p_scene: Node,
	p_unit: float,
	p_map_units: Vector2,
	p_map_origin_units: Vector2,
	p_home_safe_size_units: Vector2,
	p_outpost_size_units: Vector2
) -> void:
	scene = p_scene
	unit = p_unit
	map_units = p_map_units
	map_origin_units = p_map_origin_units
	home_safe_size_units = p_home_safe_size_units
	outpost_size_units = p_outpost_size_units


func build() -> void:
	clear_generated_visual_layers()
	generate_road_visuals()
	create_ground()


func clear_generated_visual_layers() -> void:
	for layer in [scene.block_visual_root, scene.building_visual_root, scene.prop_visual_root, scene.decal_visual_root]:
		for child in layer.get_children():
			if _is_generated_visual_layer_child(child):
				layer.remove_child(child)
				child.free()


func generate_road_visuals() -> void:
	if scene.road_visual_root.has_method("_clear_generated"):
		scene.road_visual_root._clear_generated()


func create_ground() -> void:
	scene._blocked_rects.clear()
	scene._walkable_rects.clear()
	scene._walkable_polygons.clear()
	scene.enterable_exception_rects = get_enterable_exception_rects()
	_create_terrain_ground_base()

	var ground := ColorRect.new()
	ground.name = "RunGround"
	ground.color = Color(0.12, 0.14, 0.12, 0.0)
	ground.size = _u(map_units)
	ground.position = _u(map_origin_units)
	ground.z_index = -120
	ground.set_meta("_generated_run_ground", true)
	scene.road_visual_root.add_child(ground)

	for street in get_layout_rects("StreetWalkable"):
		_add_street_from_layout(street)
	for exception_rect in scene.enterable_exception_rects:
		scene._walkable_rects.append(exception_rect)
	for block in get_layout_rects("BlockSolid"):
		_add_block_from_layout(block)
	for building in get_layout_rects("Buildings"):
		_add_visual_building_from_layout(building)


func get_enterable_exception_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	rects.append(Rect2(scene.player_root.global_position - _u(home_safe_size_units) * 0.5, _u(home_safe_size_units)))
	for point in get_outpost_candidate_points():
		var footprint_units: Vector2 = point.get_footprint_units() if point.has_method("get_footprint_units") else outpost_size_units
		var footprint_rect := Rect2(point.global_position - _u(footprint_units) * 0.5, _u(footprint_units))
		rects.append(footprint_rect)
		rects.append(footprint_rect.grow_individual(
			OUTPOST_ENTRY_CLEARANCE_UNITS.x * unit,
			OUTPOST_ENTRY_CLEARANCE_UNITS.y * unit,
			OUTPOST_ENTRY_CLEARANCE_UNITS.x * unit,
			OUTPOST_ENTRY_CLEARANCE_UNITS.y * unit
		))
	for layout in get_layout_rects("Buildings"):
		if layout.rect_kind == "home" or layout.rect_kind == "outpost" or layout.walkable:
			rects.append(layout.get_rect_px(unit))
	return rects


func get_outpost_candidate_points() -> Array[Node2D]:
	var root := scene.get_node_or_null("WorldRoot/OutpostRoot/OutpostCandidates")
	if root == null:
		return []
	var points: Array[Node2D] = []
	for child in root.find_children("*", "Node2D", true, false):
		if child.has_method("get_candidate_id"):
			points.append(child)
	return points


func get_layout_rects(section_name: String) -> Array:
	var section := scene.get_node_or_null("WorldRoot/MapLayout/%s" % section_name)
	if section == null:
		return []
	var rects := []
	for child in section.find_children("*", "", true, false):
		if child.has_method("get_rect_px"):
			rects.append(child)
	return rects


func get_layout_points(section_name: String) -> Array:
	var section := scene.get_node_or_null("WorldRoot/MapLayout/Points/%s" % section_name)
	if section == null:
		return []
	var points := []
	for child in section.get_children():
		if child is Node2D and child.has_method("get_point_id") and child.enabled:
			points.append(child)
	return points


func _create_terrain_ground_base() -> void:
	for child in scene.road_visual_root.get_children():
		if child.has_meta("_generated_run_ground") or child.has_meta("_generated_road_art"):
			scene.road_visual_root.remove_child(child)
			child.free()
	var terrain_root: Node = scene.map_visual_root.get_node_or_null("TerrainGroundBase")
	if terrain_root == null:
		terrain_root = Node2D.new()
		terrain_root.name = "TerrainGroundBase"
		scene.map_visual_root.add_child(terrain_root)
		scene.map_visual_root.move_child(terrain_root, 0)
	for child in terrain_root.get_children():
		if child.has_meta("_generated_terrain_ground"):
			terrain_root.remove_child(child)
			child.free()
	var map_rect := Rect2(_u(map_origin_units), _u(map_units))
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
	_add_layout_polygon(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(unit), color, -90, scene.road_visual_root)
	_add_road_art_from_layout(layout)
	scene._walkable_polygons.append(layout.get_world_corners_px(unit))
	scene._walkable_rects.append(layout.get_rect_px(unit))


func _add_block_from_layout(layout) -> void:
	_add_solid_layout_rect(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(unit), Color(0.86, 0.86, 0.82), -70)
	_add_block_art_from_layout(layout)


func _add_visual_building_from_layout(layout) -> void:
	var polygon := _add_layout_polygon(layout.get_rect_id(), layout.global_transform, layout.get_local_corners_px(unit), Color(0.92, 0.92, 0.9, 0.0), -40, scene.building_visual_root)
	polygon.set_meta("_generated_building_visual", true)


func _add_road_art_from_layout(layout) -> void:
	var road_rect: Rect2 = layout.get_rect_px(unit)
	_add_layout_art(scene.road_visual_root, "%s_Ground" % layout.get_rect_id(), layout, TerrainGroundTextures, road_rect, -95, true)


func _add_layout_art(parent: Node, prefix: String, layout, default_textures: Array, rect: Rect2, default_z: int, default_tiled: bool) -> void:
	if _layout_uses_child_art(layout):
		return
	var mode := _layout_art_mode(layout)
	if mode == "hidden":
		return
	var texture := null if mode == "auto" else _layout_art_texture(layout)
	var z := _layout_art_z(layout, default_z)
	if texture != null:
		if mode == "tile":
			_add_tiled_texture_rect(parent, prefix, [texture], rect, z, _layout_art_tile_size(layout), _layout_art_tint(layout))
		else:
			parent.add_child(_make_scaled_sprite("CustomFill", texture, rect, z, _layout_art_tint(layout)))
		return
	if default_tiled:
		_add_tiled_texture_rect(parent, prefix, default_textures, rect, default_z)
	else:
		parent.add_child(_make_scaled_sprite("SingleFill", _default_texture_for_layout(default_textures, layout), rect, default_z))


func _add_tiled_texture_rect(parent: Node, prefix: String, textures: Array, rect: Rect2, z: int, tile_size_override: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> void:
	var texture_size: Vector2 = textures[0].get_size()
	var tile_size: Vector2 = tile_size_override if tile_size_override != Vector2.ZERO else texture_size
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
			sprite.region_enabled = tile_size_override == Vector2.ZERO
			if sprite.region_enabled:
				sprite.region_rect = Rect2(Vector2.ZERO, region_size)
			sprite.position = tile_pos + region_size * 0.5
			if tile_size_override != Vector2.ZERO:
				sprite.scale = region_size / texture_size
			sprite.modulate = tint
			sprite.z_index = z
			sprite.set_meta("_generated_road_art", true)
			parent.add_child(sprite)


func _add_block_art_from_layout(layout) -> void:
	if _layout_uses_child_art(layout):
		return
	var block_rect: Rect2 = layout.get_rect_px(unit)
	var art_root := Node2D.new()
	art_root.name = "%s_Art" % layout.get_rect_id()
	art_root.set_meta("_generated_block_visual", true)
	scene.block_visual_root.add_child(art_root)
	var mode := _layout_art_mode(layout)
	if mode == "hidden":
		return
	var texture := null if mode == "auto" else _layout_art_texture(layout)
	if texture != null:
		if mode == "tile":
			_add_tiled_texture_rect(art_root, "CustomTile", [texture], block_rect, _layout_art_z(layout, -68), _layout_art_tile_size(layout), _layout_art_tint(layout))
		else:
			art_root.add_child(_make_scaled_sprite("CustomFill", texture, block_rect, _layout_art_z(layout, -68), _layout_art_tint(layout)))
	elif BLOCK_ART_USE_TILED_FILL:
		_add_block_fill_tiles(art_root, block_rect)
	else:
		_add_block_single_fill(art_root, block_rect, layout.get_rect_id())
	if BLOCK_ART_USE_EXPERIMENTAL_EDGES:
		_add_block_edges(art_root, block_rect)


func _add_block_single_fill(parent: Node, block_rect: Rect2, rect_id: String) -> void:
	var texture_index: int = int(abs(hash(rect_id)) % BlockFillTextures.size())
	parent.add_child(_make_scaled_sprite("SingleFill", BlockFillTextures[texture_index], block_rect, -68))


func _add_block_fill_tiles(parent: Node, block_rect: Rect2) -> void:
	var tile_size := BLOCK_FILL_TILE_UNITS * unit
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


func _make_scaled_sprite(sprite_name: String, texture: Texture2D, rect: Rect2, z: int, tint: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = rect.get_center()
	sprite.scale = rect.size / texture.get_size()
	sprite.modulate = tint
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


func _layout_art_mode(layout) -> String:
	var mode = layout.get("art_mode")
	if mode == null or String(mode).is_empty():
		return "auto"
	return String(mode)


func _layout_uses_child_art(layout) -> bool:
	var prefer_child_art = layout.get("prefer_child_art")
	if prefer_child_art is bool and not prefer_child_art:
		return false
	if layout.has_method("has_child_art"):
		return layout.has_child_art()
	var art_root: Node = null
	if layout is Node:
		art_root = layout.get_node_or_null("ArtRoot")
	if art_root == null:
		return false
	for child in art_root.get_children():
		if child is CanvasItem and child.visible:
			return true
	return false


func _layout_art_texture(layout) -> Texture2D:
	var texture = layout.get("art_texture")
	return texture if texture is Texture2D else null


func _layout_art_tint(layout) -> Color:
	var tint = layout.get("art_tint")
	return tint if tint is Color else Color.WHITE


func _layout_art_tile_size(layout) -> Vector2:
	var tile_size_units = layout.get("art_tile_size_units")
	var tile_size: Vector2 = tile_size_units if tile_size_units is Vector2 else Vector2(4.0, 4.0)
	tile_size = Vector2(maxf(tile_size.x, 0.25), maxf(tile_size.y, 0.25))
	return tile_size * unit


func _layout_art_z(layout, default_z: int) -> int:
	var custom_z = layout.get("art_z_index")
	if custom_z == null or int(custom_z) == 0:
		return default_z
	return int(custom_z)


func _default_texture_for_layout(textures: Array, layout) -> Texture2D:
	var texture_index: int = int(abs(hash(layout.get_rect_id())) % textures.size())
	return textures[texture_index]


func _is_generated_visual_layer_child(child: Node) -> bool:
	if child.has_meta("_generated_block_visual"):
		return true
	if child.has_meta("_generated_building_visual"):
		return true
	if child.has_meta("_generated_prop_visual"):
		return true
	if child.has_meta("_generated_decal_visual"):
		return true
	return false


func _add_layout_polygon(polygon_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array, color: Color, z: int, parent: Node = null) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = polygon_name
	polygon.color = color
	polygon.polygon = local_polygon
	polygon.z_index = z
	var target_parent: Node = scene.world_root if parent == null else parent
	target_parent.add_child(polygon)
	polygon.global_transform = source_transform
	return polygon


func _add_solid_layout_rect(block_name: String, source_transform: Transform2D, local_polygon: PackedVector2Array, color: Color, z: int) -> void:
	var body := StaticBody2D.new()
	body.name = block_name
	body.z_index = z
	scene.world_root.add_child(body)
	body.global_transform = source_transform
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	visual.polygon = local_polygon
	body.add_child(visual)
	var block_local_rect := Rect2(local_polygon[0], local_polygon[2] - local_polygon[0])
	for collision_rect in _carve_enterable_exceptions(block_local_rect, source_transform):
		scene._blocked_rects.append(_rect_to_world(collision_rect, source_transform))
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = collision_rect.size
		shape.position = collision_rect.position + collision_rect.size * 0.5
		shape.shape = rect
		body.add_child(shape)


func _carve_enterable_exceptions(block_local_rect: Rect2, source_transform: Transform2D) -> Array[Rect2]:
	var collision_rects: Array[Rect2] = [block_local_rect]
	var inverse_transform := source_transform.affine_inverse()
	for exception_rect in scene.enterable_exception_rects:
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

func _rect_to_world(local_rect: Rect2, source_transform: Transform2D) -> Rect2:
	var corners := [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0.0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0.0, local_rect.size.y),
	]
	var min_pos: Vector2 = source_transform * corners[0]
	var max_pos := min_pos
	for corner in corners:
		var world_corner: Vector2 = source_transform * corner
		min_pos.x = minf(min_pos.x, world_corner.x)
		min_pos.y = minf(min_pos.y, world_corner.y)
		max_pos.x = maxf(max_pos.x, world_corner.x)
		max_pos.y = maxf(max_pos.y, world_corner.y)
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


func _u(value: Variant) -> Variant:
	return value * unit

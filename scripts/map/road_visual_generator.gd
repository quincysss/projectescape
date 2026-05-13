@tool
class_name RoadVisualGenerator
extends Node2D

const UNIT := 64.0

const CrosswalkTexture := preload("res://assets/map/roads/overlays/road_overlay_crosswalk_remnant_01.png")
const ManholeTexture := preload("res://assets/map/roads/overlays/road_overlay_manhole_01.png")
const SidewalkTexture := preload("res://assets/map/roads/overlays/road_overlay_curb_chip_strip_01.png")

const GroundTileTextures := [
	preload("res://assets/map/roads/ground/road_ground_base_tile_1024_01.png"),
	preload("res://assets/map/roads/ground/road_ground_base_tile_1024_02.png"),
	preload("res://assets/map/roads/ground/road_ground_base_tile_1024_03.png"),
]
const StreetOverlayTextures := [
	preload("res://assets/map/roads/overlays/road_overlay_lane_marking_strip_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_broken_lane_short_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_long_crack_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_branching_crack_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_manhole_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_oil_stain_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_dust_stain_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_tire_skid_marks_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_storm_drain_01.png"),
	preload("res://assets/map/roads/overlays/road_overlay_rubble_scatter_01.png"),
]

@export var enabled := true:
	set(value):
		enabled = value
		_queue_editor_refresh()
@export_enum("street_decor", "ground_field", "cell_tiles") var visual_mode := "street_decor":
	set(value):
		visual_mode = value
		_queue_editor_refresh()
@export var preview_in_editor := true:
	set(value):
		preview_in_editor = value
		_queue_editor_refresh()
@export var layout_root_path: NodePath = NodePath("../../MapLayout")
@export var trial_min_units := Vector2(-140.0, -4.0):
	set(value):
		trial_min_units = value
		_queue_editor_refresh()
@export var trial_size_units := Vector2(108.0, 114.0):
	set(value):
		trial_size_units = value
		_queue_editor_refresh()
@export var grid_origin_units := Vector2(-140.0, -110.0):
	set(value):
		grid_origin_units = value
		_queue_editor_refresh()
@export var road_cell_units := Vector2(8.0, 8.0):
	set(value):
		road_cell_units = value
		_queue_editor_refresh()
@export var ground_tile_units := Vector2(16.0, 16.0):
	set(value):
		ground_tile_units = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_queue_editor_refresh()
@export var show_decals := false:
	set(value):
		show_decals = value
		_queue_editor_refresh()

var _refresh_queued := false

func _ready() -> void:
	if Engine.is_editor_hint():
		_queue_editor_refresh()

func generate_from_layout() -> void:
	_clear_generated()
	if not enabled:
		return
	var layout_root := get_node_or_null(layout_root_path)
	if layout_root == null:
		return
	var street_rects := _collect_rects(layout_root, "StreetWalkable")
	if visual_mode == "street_decor":
		_add_street_decorations(street_rects)
		return
	if visual_mode == "ground_field":
		_add_ground_field(street_rects)
		return
	var block_rects := _collect_rects(layout_root, "BlockSolid")
	var cells := _build_road_cells(street_rects, block_rects)
	_add_road_visuals(cells)
	if show_decals:
		_add_road_decals(cells)

func _queue_editor_refresh() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_editor_preview")

func _refresh_editor_preview() -> void:
	_refresh_queued = false
	if preview_in_editor:
		generate_from_layout()
	else:
		_clear_generated()

func _collect_rects(layout_root: Node, section_name: String) -> Array[Rect2]:
	var section := layout_root.get_node_or_null(section_name)
	if section == null:
		return []
	var rects: Array[Rect2] = []
	for child in section.find_children("*", "", true, false):
		if child.has_method("get_rect_px"):
			rects.append(child.get_rect_px(UNIT))
	return rects

func _build_road_cells(street_rects: Array[Rect2], block_rects: Array[Rect2]) -> Dictionary:
	var cells := {}
	var trial_rect := _trial_rect_px()
	var cell_size := road_cell_units * UNIT
	var grid_origin := grid_origin_units * UNIT
	var start_col := int(floor((trial_rect.position.x - grid_origin.x) / cell_size.x))
	var start_row := int(floor((trial_rect.position.y - grid_origin.y) / cell_size.y))
	var end_col := int(ceil((trial_rect.position.x + trial_rect.size.x - grid_origin.x) / cell_size.x))
	var end_row := int(ceil((trial_rect.position.y + trial_rect.size.y - grid_origin.y) / cell_size.y))
	for y in range(start_row, end_row):
		for x in range(start_col, end_col):
			var cell_rect := Rect2(grid_origin + Vector2(x * cell_size.x, y * cell_size.y), cell_size)
			if not cell_rect.intersects(trial_rect):
				continue
			var center := cell_rect.get_center()
			if not _point_in_any_rect(center, street_rects):
				continue
			if _point_in_any_rect(center, block_rects):
				continue
			cells[Vector2i(x, y)] = {
				"rect": cell_rect,
				"grid": Vector2i(x, y),
			}
	return cells

func _add_road_visuals(cells: Dictionary) -> void:
	var consumed := {}
	_add_straight_segments(cells, consumed, true)
	_add_straight_segments(cells, consumed, false)
	for key in cells.keys():
		if consumed.has(key):
			continue
		var cell = cells[key]
		var mask := _neighbor_mask(cells, key)
		var tile_kind := _tile_kind_for_mask(mask, key)
		var texture := _texture_for_kind(tile_kind)
		var sprite := _make_tile_sprite("Road%s_%03d_%03d" % [tile_kind, key.x, key.y], texture, cell.rect, -88)
		sprite.rotation_degrees = _rotation_for_mask(mask)
		add_child(sprite)

func _add_straight_segments(cells: Dictionary, consumed: Dictionary, horizontal: bool) -> void:
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if horizontal:
			return a.y < b.y if a.y != b.y else a.x < b.x
		return a.x < b.x if a.x != b.x else a.y < b.y
	)
	for start_key in keys:
		if consumed.has(start_key) or not _is_straight_cell(cells, start_key, horizontal):
			continue
		var segment_keys: Array[Vector2i] = []
		var current_key: Vector2i = start_key
		while cells.has(current_key) and not consumed.has(current_key) and _is_straight_cell(cells, current_key, horizontal):
			segment_keys.append(current_key)
			current_key += Vector2i(1, 0) if horizontal else Vector2i(0, 1)
		if segment_keys.size() < 2:
			continue
		var segment_rect := _rect_for_keys(cells, segment_keys)
		var sprite_name := "RoadStraight%s_%03d_%03d_%02d" % ["H" if horizontal else "V", start_key.x, start_key.y, segment_keys.size()]
		var sprite := _make_tile_sprite(sprite_name, _texture_for_kind("StraightDetail"), segment_rect, -88)
		sprite.rotation_degrees = 90.0 if horizontal else 0.0
		add_child(sprite)
		for key in segment_keys:
			consumed[key] = true

func _add_ground_field(street_rects: Array[Rect2]) -> void:
	var tile_size := ground_tile_units * UNIT
	for street_index in range(street_rects.size()):
		var street_rect := street_rects[street_index]
		var cols := int(ceil(street_rect.size.x / tile_size.x))
		var rows := int(ceil(street_rect.size.y / tile_size.y))
		for y in range(rows):
			for x in range(cols):
				var tile_pos := street_rect.position + Vector2(x * tile_size.x, y * tile_size.y)
				var remaining := (street_rect.position + street_rect.size) - tile_pos
				var tile_rect := Rect2(tile_pos, Vector2(minf(tile_size.x, remaining.x), minf(tile_size.y, remaining.y)))
				if tile_rect.size.x <= 0.0 or tile_rect.size.y <= 0.0:
					continue
				var texture: Texture2D = GroundTileTextures[(x + y * 3 + street_index) % GroundTileTextures.size()]
				var sprite := _make_tile_sprite("RoadGround_%02d_%03d_%03d" % [street_index, x, y], texture, tile_rect, -89)
				add_child(sprite)

func _add_street_decorations(street_rects: Array[Rect2]) -> void:
	for street_index in range(street_rects.size()):
		var street_rect := street_rects[street_index]
		var area_units := (street_rect.size.x / UNIT) * (street_rect.size.y / UNIT)
		var decal_count := clampi(int(area_units / 80.0), 1, 18)
		for index in range(decal_count):
			var texture: Texture2D = StreetOverlayTextures[(street_index * 5 + index * 3) % StreetOverlayTextures.size()]
			var t := float(index + 1) / float(decal_count + 1)
			var lane_offset := 0.34 + 0.32 * float((street_index + index) % 3) / 2.0
			var pos := Vector2(
				street_rect.position.x + street_rect.size.x * t,
				street_rect.position.y + street_rect.size.y * lane_offset
			)
			if street_rect.size.y > street_rect.size.x:
				pos = Vector2(
					street_rect.position.x + street_rect.size.x * lane_offset,
					street_rect.position.y + street_rect.size.y * t
				)
			var sprite := Sprite2D.new()
			sprite.name = "StreetDecor_%02d_%02d" % [street_index, index]
			sprite.texture = texture
			sprite.centered = true
			sprite.position = pos
			var target_units := Vector2(2.0, 1.0)
			if texture.get_size().y > texture.get_size().x:
				target_units = Vector2(1.2, 2.4)
			elif texture.get_size().x > texture.get_size().y * 2.0:
				target_units = Vector2(4.0, 0.8)
			sprite.scale = (target_units * UNIT) / texture.get_size()
			sprite.rotation_degrees = 90.0 if street_rect.size.y > street_rect.size.x else 0.0
			if (street_index + index) % 4 == 0:
				sprite.rotation_degrees += 180.0
			sprite.z_index = -86
			sprite.set_meta("_generated_road_visual", true)
			add_child(sprite)

func _is_straight_cell(cells: Dictionary, key: Vector2i, horizontal: bool) -> bool:
	var mask := _neighbor_mask(cells, key)
	if horizontal:
		return mask == 10
	return mask == 5

func _rect_for_keys(cells: Dictionary, keys: Array[Vector2i]) -> Rect2:
	var rect: Rect2 = cells[keys[0]].rect
	for index in range(1, keys.size()):
		rect = rect.merge(cells[keys[index]].rect)
	return rect

func _add_road_decals(cells: Dictionary) -> void:
	for key in cells.keys():
		var cell = cells[key]
		var mask := _neighbor_mask(cells, key)
		var neighbor_count := _neighbor_count(mask)
		if neighbor_count >= 3 and (key.x + key.y) % 6 == 0:
			var crosswalk := _make_decal_sprite("Crosswalk_%03d_%03d" % [key.x, key.y], CrosswalkTexture, cell.rect, Vector2(3.5, 2.5) * UNIT, -86)
			crosswalk.rotation_degrees = 90.0 if key.x % 2 == 0 else 0.0
			add_child(crosswalk)
		elif neighbor_count == 2 and (key.x * 3 + key.y) % 13 == 0:
			add_child(_make_decal_sprite("Manhole_%03d_%03d" % [key.x, key.y], ManholeTexture, cell.rect, Vector2(1.4, 1.4) * UNIT, -86))
		elif neighbor_count == 1 and (key.x + key.y * 2) % 9 == 0:
			var sidewalk := _make_decal_sprite("Sidewalk_%03d_%03d" % [key.x, key.y], SidewalkTexture, cell.rect, Vector2(3.5, 2.0) * UNIT, -86)
			sidewalk.rotation_degrees = _rotation_for_mask(mask)
			add_child(sidewalk)

func _make_tile_sprite(sprite_name: String, texture: Texture2D, rect: Rect2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = rect.get_center()
	sprite.scale = rect.size / texture.get_size()
	sprite.z_index = z
	sprite.set_meta("_generated_road_visual", true)
	return sprite

func _make_decal_sprite(sprite_name: String, texture: Texture2D, rect: Rect2, size: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = rect.get_center()
	sprite.scale = size / texture.get_size()
	sprite.z_index = z
	sprite.set_meta("_generated_road_visual", true)
	return sprite

func _tile_kind_for_mask(mask: int, key: Vector2i) -> String:
	var count := _neighbor_count(mask)
	if count >= 4:
		return "Cross"
	if count == 3:
		return "T"
	if count == 2:
		if _is_opposite(mask):
			return "Alley" if (key.x + key.y) % 2 == 0 else "StraightDetail"
		return "Corner"
	if count == 1:
		return "Alley"
	return "Plaza"

func _texture_for_kind(tile_kind: String) -> Texture2D:
	match tile_kind:
		"Cross":
			return GroundTileTextures[0]
		"T":
			return GroundTileTextures[1]
		"Corner":
			return GroundTileTextures[2]
		"StraightDetail":
			return GroundTileTextures[0]
		"Plaza":
			return GroundTileTextures[1]
		_:
			return GroundTileTextures[2]

func _rotation_for_mask(mask: int) -> float:
	if mask == 3 or mask == 7:
		return 90.0
	if mask == 6 or mask == 14:
		return 180.0
	if mask == 12 or mask == 13:
		return 270.0
	if mask == 1 or mask == 5 or mask == 11:
		return 0.0
	if mask == 4:
		return 90.0
	if mask == 10:
		return 90.0
	return 0.0

func _neighbor_mask(cells: Dictionary, key: Vector2i) -> int:
	var mask := 0
	if cells.has(key + Vector2i(0, -1)):
		mask |= 1
	if cells.has(key + Vector2i(1, 0)):
		mask |= 2
	if cells.has(key + Vector2i(0, 1)):
		mask |= 4
	if cells.has(key + Vector2i(-1, 0)):
		mask |= 8
	return mask

func _neighbor_count(mask: int) -> int:
	var count := 0
	for bit in [1, 2, 4, 8]:
		if mask & bit:
			count += 1
	return count

func _is_opposite(mask: int) -> bool:
	return mask == 5 or mask == 10

func _point_in_any_rect(point: Vector2, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _trial_rect_px() -> Rect2:
	return Rect2(trial_min_units * UNIT, trial_size_units * UNIT)

func _clear_generated() -> void:
	for child in get_children():
		if child.has_meta("_generated_road_visual"):
			remove_child(child)
			child.free()

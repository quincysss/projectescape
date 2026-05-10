@tool
class_name MapLayoutRect
extends Node2D

@export_enum("street", "plaza", "block", "building", "home", "outpost") var rect_kind: String = "street"
@export var rect_id: String = ""
@export var size_units: Vector2 = Vector2(6.0, 6.0):
	set(value):
		size_units = Vector2(maxf(value.x, 0.25), maxf(value.y, 0.25))
		queue_redraw()
@export_enum("main", "secondary", "alley", "plaza", "transition", "small_block", "standard_block", "long_block", "large_block", "special_block", "house", "shop", "apartment", "warehouse", "factory", "home", "outpost") var subtype: String = "main"
@export_enum("inner", "middle", "outer", "far_outer") var ring: String = "inner"
@export var walkable: bool = false
@export var has_collision: bool = false
@export_group("Art Override")
@export_enum("auto", "stretch", "tile", "hidden") var art_mode: String = "auto"
@export var art_texture: Texture2D
@export var art_tint: Color = Color.WHITE
@export var art_tile_size_units: Vector2 = Vector2(4.0, 4.0)
@export var art_z_index: int = 0
@export var prefer_child_art: bool = true
@export_group("Editor Box")
@export var editor_unit_px: float = 64.0:
	set(value):
		editor_unit_px = maxf(value, 1.0)
		queue_redraw()
@export var show_editor_box: bool = true:
	set(value):
		show_editor_box = value
		queue_redraw()
@export var editor_fill_alpha: float = 0.72:
	set(value):
		editor_fill_alpha = clampf(value, 0.0, 1.0)
		queue_redraw()
@export var editor_outline_width: float = 5.0:
	set(value):
		editor_outline_width = maxf(value, 1.0)
		queue_redraw()
@export var show_editor_label: bool = true:
	set(value):
		show_editor_label = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_box:
		return
	var size_px := size_units * editor_unit_px
	var rect := Rect2(-size_px * 0.5, size_px)
	var fill := _editor_color()
	fill.a = editor_fill_alpha
	draw_rect(rect, fill, true)
	draw_rect(rect, _editor_outline_color(), false, editor_outline_width)
	_draw_corner_handles(rect)
	_draw_center_cross()
	if show_editor_label:
		_draw_editor_label(rect)

func _draw_corner_handles(rect: Rect2) -> void:
	var handle_size := 10.0
	for corner in [rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y)]:
		draw_rect(Rect2(corner - Vector2.ONE * handle_size * 0.5, Vector2.ONE * handle_size), Color(1.0, 1.0, 1.0, 0.9), true)

func _draw_center_cross() -> void:
	var cross := 8.0
	draw_line(Vector2(-cross, 0.0), Vector2(cross, 0.0), Color(0.0, 0.0, 0.0, 0.85), 2.0)
	draw_line(Vector2(0.0, -cross), Vector2(0.0, cross), Color(0.0, 0.0, 0.0, 0.85), 2.0)

func _draw_editor_label(rect: Rect2) -> void:
	var text := "%s  %.1fx%.1f" % [get_rect_id(), size_units.x, size_units.y]
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, -8.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, _editor_outline_color())

func _editor_color() -> Color:
	match rect_kind:
		"building":
			return Color(1.0, 1.0, 1.0)
		"block":
			return Color(0.86, 0.86, 0.82)
		"home":
			return Color(0.0, 0.95, 0.28)
		"outpost":
			return Color(0.6, 0.32, 0.12)
		"plaza":
			return Color(0.62, 0.62, 0.58)
		_:
			return Color(0.68, 0.68, 0.68)

func _editor_outline_color() -> Color:
	if has_collision or rect_kind == "building" or rect_kind == "block":
		return Color(1.0, 0.45, 0.1)
	if walkable or rect_kind == "street" or rect_kind == "plaza":
		return Color(0.15, 0.9, 1.0)
	if rect_kind == "home":
		return Color(0.0, 1.0, 0.35)
	if rect_kind == "outpost":
		return Color(0.95, 0.55, 0.22)
	return Color(1.0, 1.0, 1.0)

func get_rect_id() -> String:
	if rect_id.is_empty():
		return name
	return rect_id

func get_local_corners_px(unit_size: float) -> PackedVector2Array:
	var size_px := size_units * unit_size
	var half := size_px * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])

func get_world_corners_px(unit_size: float) -> PackedVector2Array:
	var world_corners := PackedVector2Array()
	for point in get_local_corners_px(unit_size):
		world_corners.append(global_transform * point)
	return world_corners

func get_rect_px(unit_size: float) -> Rect2:
	var corners := get_world_corners_px(unit_size)
	if corners.is_empty():
		return Rect2(global_position, Vector2.ZERO)
	var min_pos := corners[0]
	var max_pos := corners[0]
	for corner in corners:
		min_pos.x = minf(min_pos.x, corner.x)
		min_pos.y = minf(min_pos.y, corner.y)
		max_pos.x = maxf(max_pos.x, corner.x)
		max_pos.y = maxf(max_pos.y, corner.y)
	return Rect2(min_pos, max_pos - min_pos)

func has_child_art() -> bool:
	var art_root := get_node_or_null("ArtRoot")
	if art_root == null:
		return false
	for child in art_root.get_children():
		if child is CanvasItem and child.visible:
			return true
	return false

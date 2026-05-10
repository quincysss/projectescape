@tool
class_name MapLayoutPoint
extends Marker2D

@export_enum("container", "material", "anomaly", "spawn", "extract") var point_type: String = "container"
@export var point_id: String = "":
	set(value):
		point_id = value
		queue_redraw()
@export_enum("inner", "middle", "outer", "far_outer") var ring: String = "inner":
	set(value):
		ring = value
		queue_redraw()
@export_enum("left", "center", "right") var map_side: String = "center":
	set(value):
		map_side = value
		queue_redraw()
@export var tags: Array[StringName] = []
@export var enabled: bool = true
@export var validation_note: String = ""
@export_group("Editor Preview")
@export var editor_unit_px: float = 64.0:
	set(value):
		editor_unit_px = maxf(value, 1.0)
		queue_redraw()
@export var show_editor_preview: bool = true:
	set(value):
		show_editor_preview = value
		queue_redraw()
@export var preview_size_units: Vector2 = Vector2.ZERO:
	set(value):
		preview_size_units = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		queue_redraw()
@export var show_editor_label: bool = true:
	set(value):
		show_editor_label = value
		queue_redraw()
@export var editor_label_offset_px: Vector2 = Vector2(18.0, -18.0):
	set(value):
		editor_label_offset_px = value
		queue_redraw()

func _ready() -> void:
	if not enabled:
		return
	add_to_group("map_points")
	add_to_group("%s_spawn_points" % point_type)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return
	var color := _editor_color()
	var outline := Color(0.02, 0.02, 0.02, 0.92)
	var size_px := _preview_size_px()
	match point_type:
		"material":
			_draw_diamond(size_px, color, outline)
		"spawn":
			_draw_triangle(size_px, color, outline)
		"extract":
			_draw_cross(size_px, color, outline)
		_:
			var rect := Rect2(-size_px * 0.5, size_px)
			draw_rect(rect, color, true)
			draw_rect(rect, outline, false, 4.0)
	_draw_center_dot()
	if show_editor_label:
		draw_string(ThemeDB.fallback_font, editor_label_offset_px, _editor_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, outline)

func get_point_id() -> String:
	if point_id.is_empty():
		return name
	return point_id

func get_preview_size_units() -> Vector2:
	if preview_size_units != Vector2.ZERO:
		return preview_size_units
	match point_type:
		"container":
			return Vector2(2.2, 1.6)
		"material":
			return Vector2(1.5, 1.5)
		"spawn", "extract":
			return Vector2(1.4, 1.4)
		_:
			return Vector2(1.2, 1.2)

func _preview_size_px() -> Vector2:
	return get_preview_size_units() * editor_unit_px

func _editor_label() -> String:
	var disabled_suffix := " DISABLED" if not enabled else ""
	return "%s | %s | %s%s" % [get_point_id(), point_type, ring, disabled_suffix]

func _editor_color() -> Color:
	var alpha := 0.88 if enabled else 0.28
	match point_type:
		"container":
			match ring:
				"inner":
					return Color(0.78, 0.78, 0.78, alpha)
				"middle":
					return Color(0.55, 0.78, 1.0, alpha)
				"outer":
					return Color(0.78, 0.58, 1.0, alpha)
				"far_outer":
					return Color(1.0, 0.82, 0.35, alpha)
				_:
					return Color(0.8, 0.8, 0.8, alpha)
		"material":
			return Color(0.25, 0.95, 0.45, alpha)
		"anomaly":
			return Color(1.0, 0.25, 0.25, alpha)
		"spawn":
			return Color(0.2, 1.0, 0.9, alpha)
		"extract":
			return Color(1.0, 0.9, 0.25, alpha)
		_:
			return Color(1.0, 1.0, 1.0, alpha)

func _draw_diamond(size_px: Vector2, fill: Color, outline: Color) -> void:
	var half := size_px * 0.5
	var points := PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, 4.0)

func _draw_triangle(size_px: Vector2, fill: Color, outline: Color) -> void:
	var half := size_px * 0.5
	var points := PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), outline, 4.0)

func _draw_cross(size_px: Vector2, fill: Color, outline: Color) -> void:
	var half := size_px * 0.5
	draw_circle(Vector2.ZERO, maxf(half.x, half.y), fill)
	draw_arc(Vector2.ZERO, maxf(half.x, half.y), 0.0, TAU, 32, outline, 4.0)
	draw_line(Vector2(-half.x, 0.0), Vector2(half.x, 0.0), outline, 4.0)
	draw_line(Vector2(0.0, -half.y), Vector2(0.0, half.y), outline, 4.0)

func _draw_center_dot() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(0.0, 0.0, 0.0, 0.9))

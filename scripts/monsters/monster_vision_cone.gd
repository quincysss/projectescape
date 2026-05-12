class_name MonsterVisionCone
extends Node2D

@export var radius: float = 360.0:
	set(value):
		radius = maxf(1.0, value)
		queue_redraw()
@export var angle_degrees: float = 70.0:
	set(value):
		angle_degrees = clampf(value, 1.0, 180.0)
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var warning_progress: float = 0.0:
	set(value):
		warning_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
@export var alert: bool = false:
	set(value):
		alert = value
		queue_redraw()

var _segments: int = 28

func set_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	rotation = direction.angle()

func set_state(progress: float, is_alert: bool) -> void:
	warning_progress = progress
	alert = is_alert
	queue_redraw()

func _draw() -> void:
	var half_angle := deg_to_rad(angle_degrees) * 0.5
	if alert:
		_draw_sector(-half_angle, half_angle, Color(1.0, 0.1, 0.05, 0.36), Color(1.0, 0.18, 0.08, 0.78))
		return
	_draw_sector(-half_angle, half_angle, Color(0.35, 1.0, 0.55, 0.22), Color(0.55, 1.0, 0.65, 0.52))
	if warning_progress <= 0.0:
		return
	var filled_angle := lerpf(-half_angle, half_angle, warning_progress)
	_draw_sector(-half_angle, filled_angle, Color(1.0, 0.82, 0.18, 0.32), Color(1.0, 0.9, 0.22, 0.72))

func _draw_sector(start_angle: float, end_angle: float, fill: Color, outline: Color) -> void:
	if end_angle <= start_angle:
		return
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var span := end_angle - start_angle
	var steps: int = maxi(2, int(ceil(float(_segments) * span / deg_to_rad(angle_degrees))))
	for index in range(steps + 1):
		var t := float(index) / float(steps)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill)
	var outline_points := points.duplicate()
	outline_points.append(Vector2.ZERO)
	draw_polyline(outline_points, outline, 2.0)

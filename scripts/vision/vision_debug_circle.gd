class_name VisionDebugCircle
extends Node2D

var target: Node2D
var radius: float = 220.0
var enabled: bool = false

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position
	queue_redraw()

func set_radius(value: float) -> void:
	radius = value
	queue_redraw()

func set_darkness_enabled(value: bool) -> void:
	enabled = value
	visible = value
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.45, 0.95, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.2, 0.7, 1.0, 0.9), 3.0)

@tool
class_name OutpostCandidatePoint
extends Marker2D

@export_enum("first", "second") var outpost_tier: String = "first"
@export var candidate_id: String = "":
	set(value):
		candidate_id = value
		queue_redraw()
@export var footprint_units: Vector2 = Vector2(10.0, 8.0):
	set(value):
		footprint_units = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		queue_redraw()
@export var enabled: bool = true:
	set(value):
		enabled = value
		queue_redraw()
@export_group("Editor Preview")
@export var editor_unit_px: float = 64.0:
	set(value):
		editor_unit_px = maxf(value, 1.0)
		queue_redraw()
@export var show_editor_preview: bool = true:
	set(value):
		show_editor_preview = value
		queue_redraw()
@export var show_editor_label: bool = true:
	set(value):
		show_editor_label = value
		queue_redraw()

func _ready() -> void:
	if not enabled:
		return
	add_to_group("outpost_candidate_points")
	if outpost_tier == "first":
		add_to_group("first_outpost_candidates")
	else:
		add_to_group("second_outpost_candidates")
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return
	var size_px := footprint_units * editor_unit_px
	var rect := Rect2(-size_px * 0.5, size_px)
	var fill := Color(0.48, 0.25, 0.10, 0.62 if enabled else 0.22)
	var outline := Color(1.0, 0.62, 0.22, 0.95 if enabled else 0.4)
	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 5.0)
	draw_line(Vector2(-12.0, 0.0), Vector2(12.0, 0.0), Color(0.0, 0.0, 0.0, 0.85), 3.0)
	draw_line(Vector2(0.0, -12.0), Vector2(0.0, 12.0), Color(0.0, 0.0, 0.0, 0.85), 3.0)
	if show_editor_label:
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(8.0, -10.0),
			"%s | %s | %.1fx%.1f" % [get_candidate_id(), outpost_tier, footprint_units.x, footprint_units.y],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			outline
		)

func get_candidate_id() -> String:
	if not candidate_id.is_empty():
		return candidate_id
	return name

func get_footprint_units() -> Vector2:
	return footprint_units

class_name WhiteboxMapRect
extends Node2D

@export_enum("road", "plaza", "building", "home", "outpost") var rect_kind: String = "road"
@export var rect_id: String = ""
@export var size_units: Vector2 = Vector2(6.0, 6.0)
@export_enum("main", "secondary", "alley", "plaza", "transition", "house", "shop", "apartment", "warehouse", "factory", "home", "outpost") var subtype: String = "main"
@export_enum("inner", "middle", "outer", "far_outer") var ring: String = "inner"
@export var walkable: bool = false
@export var has_collision: bool = false

func get_rect_id() -> String:
	if rect_id.is_empty():
		return name
	return rect_id

func get_rect_px(unit_size: float) -> Rect2:
	var size_px := size_units * unit_size
	return Rect2(global_position - size_px * 0.5, size_px)

class_name WhiteboxPlayer
extends CharacterBody2D

@export var base_speed: float = 180.0
var speed_multiplier: float = 1.0
var walkable_rects: Array[Rect2] = []
var walkable_polygons: Array[PackedVector2Array] = []

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * base_speed * speed_multiplier
	var previous_position := global_position
	move_and_slide()
	if not _is_position_walkable(global_position):
		global_position = previous_position
		velocity = Vector2.ZERO

func set_walkable_rects(rects: Array[Rect2]) -> void:
	walkable_rects = rects

func set_walkable_polygons(polygons: Array[PackedVector2Array]) -> void:
	walkable_polygons = polygons

func _is_position_walkable(world_position: Vector2) -> bool:
	if walkable_rects.is_empty() and walkable_polygons.is_empty():
		return true
	for polygon in walkable_polygons:
		if Geometry2D.is_point_in_polygon(world_position, polygon):
			return true
	for rect in walkable_rects:
		if rect.has_point(world_position):
			return true
	return false

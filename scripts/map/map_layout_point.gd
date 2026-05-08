class_name MapLayoutPoint
extends Marker2D

@export_enum("container", "material", "anomaly", "spawn", "extract") var point_type: String = "container"
@export var point_id: String = ""
@export_enum("inner", "middle", "outer", "far_outer") var ring: String = "inner"
@export_enum("left", "center", "right") var map_side: String = "center"
@export var tags: Array[StringName] = []
@export var enabled: bool = true

func _ready() -> void:
	if not enabled:
		return
	add_to_group("map_points")
	add_to_group("%s_spawn_points" % point_type)

func get_point_id() -> String:
	if point_id.is_empty():
		return name
	return point_id

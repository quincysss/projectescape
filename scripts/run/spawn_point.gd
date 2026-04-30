class_name SpawnPoint
extends Marker2D

@export var spawn_id: String = "PlayerSpawn"

func _ready() -> void:
	add_to_group("player_spawn_points")

class_name RunInteractable
extends Area2D

signal player_entered(node)
signal player_exited(node)

@export var interact_id: String = ""
@export var interact_type: String = ""
@export var display_name: String = ""

var payload: Dictionary = {}
var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_entered.emit(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_exited.emit(self)

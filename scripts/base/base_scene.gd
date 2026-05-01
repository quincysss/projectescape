extends Control

@onready var start_button: Button = %StartRunButton
@onready var warehouse_label: Label = %WarehouseLabel
@onready var result_label: Label = %ResultLabel

var _game_state: Node

func _ready() -> void:
	_game_state = get_node_or_null("/root/GameState")
	start_button.pressed.connect(_on_start_pressed)
	_refresh()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/run/RunScene.tscn")

func _refresh() -> void:
	if _game_state == null:
		result_label.text = "Project Escape - Whitebox V0.1"
		warehouse_label.text = "Warehouse: unavailable"
		return
	result_label.text = _game_state.last_run_result if not _game_state.last_run_result.is_empty() else "Project Escape - Whitebox V0.1"
	warehouse_label.text = _game_state.get_warehouse_text()

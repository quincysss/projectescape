extends Node

const WarehouseManagerScript := preload("res://scripts/game/warehouse_manager.gd")

var warehouse_items: Array[Dictionary] = []
var last_run_result: String = ""
var warehouse_manager = WarehouseManagerScript.new()

func _ready() -> void:
	_bind_warehouse_manager()

func add_to_warehouse(items: Array) -> void:
	_bind_warehouse_manager()
	warehouse_manager.add_items(items)

func apply_run_result(result: Dictionary) -> void:
	_bind_warehouse_manager()
	last_run_result = str(result.get("message", ""))
	warehouse_manager.add_items(result.get("warehouse_items", []))

func clear_warehouse() -> void:
	_bind_warehouse_manager()
	warehouse_manager.clear()
	last_run_result = ""

func get_warehouse_text() -> String:
	_bind_warehouse_manager()
	return warehouse_manager.get_warehouse_text()

func _bind_warehouse_manager() -> void:
	if warehouse_manager == null:
		warehouse_manager = WarehouseManagerScript.new()
	warehouse_manager.bind_items(warehouse_items)

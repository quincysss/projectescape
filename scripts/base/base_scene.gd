extends Control

@onready var start_button: Button = %StartRunButton
@onready var warehouse_label: RichTextLabel = %WarehouseLabel
@onready var result_label: Label = %ResultLabel

var _game_state: Node

func _ready() -> void:
	_game_state = get_node_or_null("/root/GameState")
	start_button.pressed.connect(_on_start_pressed)
	warehouse_label.meta_clicked.connect(_on_warehouse_item_meta_clicked)
	_refresh()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/run/RunScene.tscn")

func _refresh() -> void:
	if _game_state == null:
		result_label.text = "Project Escape - 白盒 V0.1"
		warehouse_label.text = "局外仓库：不可用"
		return
	result_label.text = _game_state.last_run_result if not _game_state.last_run_result.is_empty() else "Project Escape - 白盒 V0.1"
	_set_warehouse_items_text(_game_state.get_warehouse_items_snapshot())

func _set_warehouse_items_text(items: Array) -> void:
	warehouse_label.clear()
	if items.is_empty():
		warehouse_label.append_text("局外仓库：空")
		return
	var lines: Array[String] = ["局外仓库："]
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			var name := String(item.get("display_name", item.get("item_id", "")))
			var amount := int(item.get("amount", 1))
			var weight := float(item.get("weight_per_unit", 0.0))
			lines.append("[url=warehouse:%d]- %s x%s  单重 %.2f[/url]" % [index, name, amount, weight])
	warehouse_label.append_text("\n".join(lines))

func _on_warehouse_item_meta_clicked(meta: Variant) -> void:
	if _game_state == null:
		return
	var parts := String(meta).split(":")
	if parts.size() != 2 or parts[0] != "warehouse":
		return
	var item: Dictionary = _game_state.select_warehouse_item(int(parts[1]))
	if item.is_empty():
		return
	result_label.text = "已选择：%s" % item.get("display_name", item.get("item_id", ""))

extends SceneTree

const RunUiControllerScript := preload("res://scripts/run/run_ui_controller.gd")

func _initialize() -> void:
	var ok := _verify_item_quality_text()
	print("Item quality UI text verified." if ok else "Item quality UI text failed.")
	quit(0 if ok else 1)

func _verify_item_quality_text() -> bool:
	var controller = RunUiControllerScript.new()
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	controller._set_items_text(label, [
		{
			"display_name": "金色数据芯片",
			"amount": 1,
			"weight_per_unit": 0.03,
			"quality": "S",
			"quality_color": Color("#E8B84A"),
		},
		{
			"display_name": "旧线圈",
			"amount": 1,
			"weight_per_unit": 0.12,
			"quality": "B",
			"quality_color": Color("#4BA3FF"),
		},
	])
	var text := label.get_parsed_text()
	if not text.contains("金色数据芯片") or not text.contains("旧线圈"):
		printerr("Expected item names in rich text.")
		label.free()
		return false
	label.free()
	return true

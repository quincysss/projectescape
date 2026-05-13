extends SceneTree

const BaseSceneScript := preload("res://scripts/base/base_scene.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const RunUiControllerScript := preload("res://scripts/run/run_ui_controller.gd")


func _initialize() -> void:
	var registry = GameDataRegistryScript.new()
	var ok: bool = registry.load_all()
	if not ok:
		printerr("Data registry load errors: %s" % str(registry.load_errors))
	else:
		ok = _verify_icon_paths(registry) and _verify_slot_layouts(registry)
	print("Item icon slot UI verified." if ok else "Item icon slot UI failed.")
	quit(0 if ok else 1)


func _verify_icon_paths(registry) -> bool:
	var ok := true
	for item_id in registry.items_by_id.keys():
		var item: Dictionary = registry.get_item(item_id)
		var icon_path := String(item.get("icon", ""))
		if not icon_path.begins_with("res://assets/ui/itemicon/"):
			printerr("Item %s should use itemicon path, got %s." % [item_id, icon_path])
			ok = false
			continue
		if not ResourceLoader.exists(icon_path):
			printerr("Item %s icon resource is missing: %s." % [item_id, icon_path])
			ok = false
			continue
		if not (load(icon_path) is Texture2D):
			printerr("Item %s icon must load as Texture2D: %s." % [item_id, icon_path])
			ok = false
	return ok


func _verify_slot_layouts(registry) -> bool:
	var item: Dictionary = registry.get_item("gold_data_chip").duplicate(true)
	item["display_name"] = String(item.get("name", item.get("id", "")))
	item["amount"] = 3
	item["quality_color"] = Color("#35C9D7")
	var expected_name := String(item.get("display_name", ""))

	var run_ui = RunUiControllerScript.new()
	var run_button := Button.new()
	run_ui._add_item_slot_content(run_button, Vector2(62.0, 62.0), item)
	if not _slot_has_expected_content(run_button, expected_name):
		printerr("Run item slot should render icon and centered name only.")
		run_button.free()
		return false
	run_button.free()

	var base_scene = BaseSceneScript.new()
	var base_button := Button.new()
	base_scene._add_base_item_slot_content(base_button, Vector2(62.0, 62.0), item, "warehouse")
	if not _slot_has_expected_content(base_button, expected_name):
		printerr("Base item slot should render icon and centered name only.")
		base_button.free()
		base_scene.free()
		return false
	base_button.free()
	base_scene.free()
	return true


func _slot_has_expected_content(button: Button, name_text: String) -> bool:
	var has_icon := false
	var label_count := 0
	var has_name := false
	var has_amount := false
	var icon_center_x := -1.0
	var name_center_x := -1.0
	for child in button.get_children():
		if child is TextureRect:
			has_icon = true
			icon_center_x = child.position.x + child.size.x * 0.5
		if child is Control and not (child is TextureRect):
			if child.position.x < 0.0 or child.position.y < 0.0:
				return false
			if child.position.x + child.size.x > 62.0 or child.position.y + child.size.y > 62.0:
				return false
		var labels := _find_labels(child)
		for label in labels:
			label_count += 1
			if String(label.text) == name_text:
				has_name = true
				name_center_x = _local_center_x(label)
			if String(label.text).begins_with("x"):
				has_amount = true
	var centered := absf(icon_center_x - name_center_x) <= 1.0
	if not (has_icon and label_count == 1 and has_name and not has_amount and centered):
		printerr("Slot content mismatch: icon=%s labels=%d name=%s amount=%s icon_center=%.2f name_center=%.2f expected='%s'" % [
			str(has_icon),
			label_count,
			str(has_name),
			str(has_amount),
			icon_center_x,
			name_center_x,
			name_text,
		])
	return has_icon and label_count == 1 and has_name and not has_amount and centered


func _local_center_x(control: Control) -> float:
	var center := control.position.x + control.size.x * 0.5
	var parent := control.get_parent()
	if parent is Control:
		center += (parent as Control).position.x
	return center


func _find_labels(root: Node) -> Array[Label]:
	var labels: Array[Label] = []
	if root is Label:
		labels.append(root)
	for child in root.get_children():
		labels.append_array(_find_labels(child))
	return labels

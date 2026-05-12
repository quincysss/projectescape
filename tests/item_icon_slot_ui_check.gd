extends SceneTree

const BaseSceneScript := preload("res://scripts/base/base_scene.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const RunUiControllerScript := preload("res://scripts/run/run_ui_controller.gd")

const EXPECTED_ICON_IDS := [
	"scrap_metal",
	"cloth_dirty",
	"wire_coil",
	"battery_old",
	"medicine_powder",
	"tool_parts",
	"outpost_fuse",
	"outpost_filter",
	"stability_candy",
	"field_bandage",
	"signal_injector",
	"backpack_small_reinforced",
	"scanner_broken",
	"bp_backpack_small",
	"keepsake_photo",
	"gold_data_chip",
	"ration_bar",
	"cracked_lens",
	"duct_tape_roll",
]

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
	for item_id in EXPECTED_ICON_IDS:
		var item: Dictionary = registry.get_item(item_id)
		var icon_path := String(item.get("icon", ""))
		if not icon_path.begins_with("res://assets/ui/itemicon/"):
			printerr("Item %s should use generated icon path, got %s." % [item_id, icon_path])
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
	item["display_name"] = String(item.get("name", "金色数据芯片"))
	item["amount"] = 3
	item["quality_color"] = Color("#35C9D7")

	var run_ui = RunUiControllerScript.new()
	var run_button := Button.new()
	run_ui._add_item_slot_content(run_button, Vector2(62.0, 62.0), item)
	if not _slot_has_expected_content(run_button, "金色数据芯片", "x3"):
		printerr("Run item slot should render icon, name label, and amount label.")
		return false

	var base_scene = BaseSceneScript.new()
	var base_button := Button.new()
	base_scene._add_base_item_slot_content(base_button, Vector2(62.0, 62.0), item, "warehouse")
	if not _slot_has_expected_content(base_button, "金色数据芯片", "x3"):
		printerr("Base item slot should render icon, name label, and amount label.")
		return false
	return true

func _slot_has_expected_content(button: Button, name_text: String, amount_text: String) -> bool:
	var has_icon := false
	var label_count := 0
	var has_name := false
	var has_amount := false
	for child in button.get_children():
		if child is TextureRect:
			has_icon = true
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
			if String(label.text) == amount_text:
				has_amount = true
	return has_icon and label_count >= 2 and has_name and has_amount

func _find_labels(root: Node) -> Array[Label]:
	var labels: Array[Label] = []
	if root is Label:
		labels.append(root)
	for child in root.get_children():
		labels.append_array(_find_labels(child))
	return labels

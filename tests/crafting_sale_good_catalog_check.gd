extends SceneTree

const DailyDemandServiceScript := preload("res://scripts/game/daily_demand_service.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const EXPECTED_GOODS := [
	"sale_good_scrap_bundle",
	"sale_good_cloth_wrap",
	"sale_good_wire_spool",
	"sale_good_battery_clip",
	"sale_good_medicine_sachet",
	"sale_good_tool_bit_box",
	"sale_good_lens_tag",
	"sale_good_tape_strip",
	"sale_good_bolt_cup",
	"sale_good_strap_bundle",
	"sale_good_charge_cell",
	"sale_good_signal_tag",
	"sale_good_gear_bundle",
	"sale_good_patch_roll",
	"sale_good_tie_hook_set",
	"sale_good_lens_filter",
	"sale_good_cookware_fix",
	"sale_good_wire_hook",
	"sale_good_medical_fix_roll",
	"sale_good_work_lamp",
	"sale_good_signal_marker",
	"sale_good_power_adapter",
]

const DIRECT_BASIC_GOODS := [
	"sale_good_scrap_bundle",
	"sale_good_cloth_wrap",
	"sale_good_wire_spool",
	"sale_good_battery_clip",
	"sale_good_medicine_sachet",
	"sale_good_tool_bit_box",
	"sale_good_lens_tag",
	"sale_good_tape_strip",
	"sale_good_bolt_cup",
	"sale_good_strap_bundle",
	"sale_good_charge_cell",
	"sale_good_signal_tag",
]


func _initialize() -> void:
	var ok := _verify_catalog_and_orders()
	print("Crafting sale good catalog verified." if ok else "Crafting sale good catalog failed.")
	quit(0 if ok else 1)


func _verify_catalog_and_orders() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load: %s" % registry.load_errors)
		return false

	var ok := true
	var recipe_outputs := _recipe_outputs(registry.get_crafting_recipe_rows())
	for item_id in EXPECTED_GOODS:
		var item := registry.get_item(item_id)
		if item.is_empty():
			printerr("Expected crafted sale_good item: %s" % item_id)
			ok = false
			continue
		if not _is_sale_good(item):
			printerr("Expected item to be sale_good: %s" % item_id)
			ok = false
		if int(item.get("sell_value", 0)) <= 0:
			printerr("Expected sale_good to have positive sell value: %s" % item_id)
			ok = false
		if int(item.get("base_sale_value", 0)) != int(item.get("sell_value", 0)):
			printerr("Expected sale_good base_sale_value to mirror the current sell_value baseline: %s" % item_id)
			ok = false
		if not recipe_outputs.has(item_id):
			printerr("Expected crafting recipe output for sale_good: %s" % item_id)
			ok = false
		if not ResourceLoader.exists(String(item.get("icon", ""))):
			printerr("Expected icon resource to exist for sale_good: %s" % item_id)
			ok = false
	ok = _verify_direct_and_combo_recipes(registry) and ok

	var demand_service = DailyDemandServiceScript.new()
	var demand_entries: Array[Dictionary] = demand_service.generate_for_day(2)
	var demand_ids := {}
	for entry in demand_entries:
		demand_ids[String(entry.get("item_id", ""))] = true
	for item_id in EXPECTED_GOODS:
		if not demand_ids.has(item_id):
			printerr("Expected sale_good to enter daily demand orders: %s" % item_id)
			ok = false
	return ok


func _verify_direct_and_combo_recipes(registry) -> bool:
	var ok := true
	var recipes_by_output := _recipes_by_output(registry.get_crafting_recipe_rows())
	for item_id in DIRECT_BASIC_GOODS:
		var recipe: Dictionary = recipes_by_output.get(item_id, {})
		if recipe.is_empty():
			printerr("Expected direct basic recipe for: %s" % item_id)
			ok = false
			continue
		var requirements := _parse_requirements(String(recipe.get("required_items", "")))
		if requirements.size() != 1:
			printerr("Direct basic recipe must consume exactly one item type: %s" % recipe)
			ok = false
			continue
		for required_item_id in requirements.keys():
			if int(requirements[required_item_id]) != 1:
				printerr("Direct basic recipe must consume one carried-out item: %s" % recipe)
				ok = false
	var high_value_recipe: Dictionary = recipes_by_output.get("sale_good_work_lamp", {})
	var high_value_item: Dictionary = registry.get_item("sale_good_work_lamp")
	if _parse_requirements(String(high_value_recipe.get("required_items", ""))).size() < 3:
		printerr("Expected work lamp to be a multi-material higher-value recipe.")
		ok = false
	if int(high_value_item.get("sell_value", 0)) <= int(registry.get_item("sale_good_wire_spool").get("sell_value", 0)):
		printerr("Expected multi-material work lamp to have higher sell value than direct goods.")
		ok = false
	if int(high_value_item.get("base_sale_value", 0)) <= int(registry.get_item("sale_good_wire_spool").get("base_sale_value", 0)):
		printerr("Expected multi-material work lamp to have higher base sale value than direct goods.")
		ok = false
	return ok


func _recipe_outputs(rows: Array[Dictionary]) -> Dictionary:
	var result := {}
	for row in rows:
		result[String(row.get("output_item_id", ""))] = true
	return result


func _recipes_by_output(rows: Array[Dictionary]) -> Dictionary:
	var result := {}
	for row in rows:
		result[String(row.get("output_item_id", ""))] = row
	return result


func _parse_requirements(value: String) -> Dictionary:
	var result := {}
	for part in TabDataLoaderScript.split_list(value):
		var cells := part.split(":", false, 1)
		if cells.size() != 2:
			continue
		result[String(cells[0])] = int(cells[1])
	return result


func _is_sale_good(item: Dictionary) -> bool:
	if String(item.get("item_type", "")) == "sale_good":
		return true
	return TabDataLoaderScript.split_list(String(item.get("tags", ""))).has("sale_good")

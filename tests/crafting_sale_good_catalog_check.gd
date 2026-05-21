extends SceneTree

const DailyDemandServiceScript := preload("res://scripts/game/daily_demand_service.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const EXPECTED_GOODS := [
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
		if not recipe_outputs.has(item_id):
			printerr("Expected crafting recipe output for sale_good: %s" % item_id)
			ok = false
		if not ResourceLoader.exists(String(item.get("icon", ""))):
			printerr("Expected icon resource to exist for sale_good: %s" % item_id)
			ok = false

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


func _recipe_outputs(rows: Array[Dictionary]) -> Dictionary:
	var result := {}
	for row in rows:
		result[String(row.get("output_item_id", ""))] = true
	return result


func _is_sale_good(item: Dictionary) -> bool:
	if String(item.get("item_type", "")) == "sale_good":
		return true
	return TabDataLoaderScript.split_list(String(item.get("tags", ""))).has("sale_good")

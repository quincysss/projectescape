extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

func _initialize() -> void:
	var ok := _verify_item_sell_values()
	print("Item sell value table verified." if ok else "Item sell value table failed.")
	quit(0 if ok else 1)

func _verify_item_sell_values() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false
	var ok := true
	for item_id in registry.items_by_id.keys():
		var item: Dictionary = registry.get_item(String(item_id))
		var sellable := TabDataLoader.parse_bool(String(item.get("sellable", "")), false)
		var sell_value := int(item.get("sell_value", 0))
		var sell_currency_id := String(item.get("sell_currency_id", ""))
		if not sellable:
			printerr("Expected items.tab item %s to be sellable." % item_id)
			ok = false
		if sell_currency_id != "mine_coin":
			printerr("Expected sellable item %s to sell for mine_coin." % item_id)
			ok = false
		if sell_value <= 0:
			printerr("Expected sellable item %s to have a positive sell value." % item_id)
			ok = false
		if registry.repair_materials_by_id.has(String(item_id)):
			printerr("Repair material must not also live in items.tab: %s" % item_id)
			ok = false
	var material_stack: Dictionary = registry.make_item_stack("scrap_metal")
	if not bool(material_stack.get("sellable", false)) or int(material_stack.get("sell_value", 0)) <= 0:
		printerr("Expected generated material stack to carry merchant value.")
		ok = false
	var rare_stack: Dictionary = registry.make_item_stack("gold_data_chip")
	if not bool(rare_stack.get("sellable", false)) or int(rare_stack.get("sell_value", 0)) <= 0:
		printerr("Expected generated rare stack to carry merchant value.")
		ok = false
	if not _verify_legacy_data_items_table():
		ok = false
	return ok

func _verify_legacy_data_items_table() -> bool:
	var loader = TabDataLoaderScript.new()
	var rows: Array[Dictionary] = loader.load_tab("res://data/items.tab")
	if not loader.last_error.is_empty():
		printerr("Expected legacy data/items.tab to load: %s" % loader.last_error)
		return false
	var ok := true
	for item in rows:
		var item_type := String(item.get("item_type", ""))
		if item_type != "material":
			continue
		var sellable := TabDataLoader.parse_bool(String(item.get("sellable", "")), false)
		var sell_value := int(item.get("sell_value", 0))
		if sellable or sell_value != 0:
			printerr("Expected legacy material item %s to have no merchant value." % item.get("id", ""))
			ok = false
	return ok

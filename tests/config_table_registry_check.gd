extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoader := preload("res://scripts/data/tab_data_loader.gd")
const VALID_ITEM_QUALITIES := ["C", "B", "A", "S"]

func _initialize() -> void:
	var ok := _verify_registry()
	print("Config table registry verified." if ok else "Config table registry failed.")
	quit(0 if ok else 1)

func _verify_registry() -> bool:
	var registry = GameDataRegistryScript.new()
	var ok: bool = registry.load_all()
	if not ok:
		printerr("Data registry load errors: %s" % str(registry.load_errors))
		return false
	if registry.items_by_id.size() < 10:
		printerr("Expected item table content.")
		ok = false
	if registry.repair_materials_by_id.size() != 6:
		printerr("Expected exactly six repair material rows.")
		ok = false
	for item in registry.items_by_id.values():
		var item_id := String(item.get("id", ""))
		var item_type := String(item.get("item_type", ""))
		var quality := String(item.get("quality", ""))
		if not VALID_ITEM_QUALITIES.has(quality):
			printerr("Item %s uses invalid quality: %s" % [item_id, quality])
			ok = false
		if item_type == "material":
			if String(item.get("material_category", "")).is_empty():
				printerr("Material item must declare material_category: %s" % item_id)
				ok = false
			if String(item.get("stackable", "")) != "true" or int(item.get("stack_limit", 0)) <= 1:
				printerr("Material item must be stackable for resource-loop carryout: %s" % item_id)
				ok = false
		if item_type == "sale_good":
			if String(item.get("stackable", "")) != "true" or int(item.get("stack_limit", 0)) <= 1:
				printerr("Sale good must be stackable for shop stocking: %s" % item_id)
				ok = false
			if int(item.get("base_sale_value", 0)) <= 0:
				printerr("Sale good must declare positive base_sale_value: %s" % item_id)
				ok = false
		if item_type == "outpost_material":
			printerr("Outpost repair materials must not live in items.tab: %s" % item_id)
			ok = false
	for material in registry.repair_materials_by_id.values():
		var material_id := String(material.get("id", ""))
		if material_id.is_empty() or not registry.get_item(material_id).is_empty():
			printerr("Repair material id must be unique from items.tab: %s" % material_id)
			ok = false
		if material.has("quality") or material.has("first_outpost_amount") or material.has("second_outpost_amount"):
			printerr("Repair material table must not carry quality or fixed outpost amount fields: %s" % material_id)
			ok = false
		if float(material.get("weight", -1.0)) < 0.0:
			printerr("Repair material must declare non-negative weight: %s" % material_id)
			ok = false
		var stack: Dictionary = registry.make_repair_material_stack(material_id)
		if stack.has("quality") or stack.has("quality_color") or stack.has("item_type"):
			printerr("Repair material stack must stay quality-free and item-table-free: %s" % material_id)
			ok = false
	if registry.containers_by_id.size() < 7:
		printerr("Expected seven configured container types.")
		ok = false
	if registry.shop_stock_rows.size() < 8:
		printerr("Expected configured merchant shop stock rows.")
		ok = false
	if registry.research_rows.size() < 3:
		printerr("Expected configured research rows.")
		ok = false
	for row in registry.get_research_rows():
		var requirements := String(row.get("required_items", ""))
		if not requirements.is_empty():
			printerr("Research row must not consume warehouse items: %s" % row.get("research_id", ""))
			ok = false
		if String(row.get("required_currency_id", "")) != "mine_coin" or int(row.get("required_currency_amount", 0)) <= 0:
			printerr("Research row must require a positive mine_coin cost: %s" % row.get("research_id", ""))
			ok = false
		if String(row.get("effect_type", "")) == "player_move_speed_multiplier" and float(row.get("effect_value", 0.0)) <= 1.0:
			printerr("Move speed research must increase speed multiplier.")
			ok = false
	for row in registry.shop_stock_rows:
		var item := registry.get_item(String(row.get("item_id", "")))
		if item.is_empty():
			printerr("Shop stock row references missing item: %s" % row.get("item_id", ""))
			ok = false
			continue
		if not TabDataLoader.parse_bool(String(item.get("sellable", "false")), false):
			printerr("Shop stock row must reference a sellable item: %s" % row.get("item_id", ""))
			ok = false
		if int(row.get("buy_price", 0)) <= 0:
			printerr("Shop stock row must have positive buy_price: %s" % row.get("item_id", ""))
			ok = false
		if int(row.get("buy_price", 0)) != int(item.get("sell_value", 0)):
			printerr("Shop stock buy_price must match item sell_value: %s" % row.get("item_id", ""))
			ok = false
		if String(row.get("buy_currency_id", "")) != String(item.get("sell_currency_id", "")):
			printerr("Shop stock buy_currency_id must match item sell_currency_id: %s" % row.get("item_id", ""))
			ok = false
	for container in registry.containers_by_id.values():
		if container.has("quality") or container.has("grade") or container.has("rarity"):
			printerr("Container config must not expose S/A/B/C grade fields.")
			ok = false
		if String(container.get("visual_color_hex", "")) != "#3A8DFF":
			printerr("Container %s does not use unified blue." % container.get("type_id", ""))
			ok = false
		if String(container.get("quality_label_enabled", "")) != "false":
			printerr("Container %s should hide quality labels." % container.get("type_id", ""))
			ok = false
	for context in registry.drop_rows_by_context.keys():
		for row in registry.drop_rows_by_context[context]:
			var item: Dictionary = registry.get_item(String(row.get("item_id", "")))
			if item.is_empty():
				printerr("Drop row references missing item: %s" % row.get("item_id", ""))
				ok = false
				continue
			if registry.repair_materials_by_id.has(String(row.get("item_id", ""))):
				printerr("Container drop rows must not include run-only repair materials: %s" % row.get("item_id", ""))
				ok = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var wooden := registry.get_container_type("wooden_crate")
	var loot: Array[Dictionary] = registry.generate_container_loot(wooden, "middle", rng)
	if loot.is_empty():
		printerr("Expected generated loot for wooden_crate.")
		ok = false
	for item in loot:
		if not item.has("quality") or not item.has("quality_color"):
			printerr("Generated item lacks quality display fields.")
			ok = false
		if not VALID_ITEM_QUALITIES.has(String(item.get("quality", ""))):
			printerr("Generated loot uses invalid quality: %s" % item)
			ok = false
	return ok

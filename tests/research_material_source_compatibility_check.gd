extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := _verify_research_material_sources()
	print("Research material source compatibility verified." if ok else "Research material source compatibility failed.")
	quit(0 if ok else 1)

func _verify_research_material_sources() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load data tables: %s" % registry.load_errors)
		return false

	if not _verify_research_requirements_are_empty(registry):
		return false
	if not _verify_outpost_materials_are_run_only(registry):
		return false
	if not _verify_shop_stock_level_pools(registry):
		return false
	if not _verify_actual_shop_buy_marks_source(game_state):
		return false
	if not _verify_research_ignores_warehouse_source(game_state, registry, "run_loot"):
		return false
	if not _verify_research_ignores_warehouse_source(game_state, registry, "merchant_shop"):
		return false
	return true

func _verify_research_requirements_are_empty(registry) -> bool:
	for row in registry.get_research_rows():
		if not String(row.get("required_items", "")).strip_edges().is_empty():
			printerr("Research required_items must be empty or ignored: %s" % row)
			return false
	return true

func _verify_shop_stock_level_pools(registry) -> bool:
	var level_one_ids := _shop_item_id_set(registry.get_shop_stock_rows_for_level(1))
	var level_two_ids := _shop_item_id_set(registry.get_shop_stock_rows_for_level(2))
	var level_three_ids := _shop_item_id_set(registry.get_shop_stock_rows_for_level(3))
	for item_id in ["scrap_metal", "cloth_dirty", "rusted_bolts", "duct_tape_roll", "cracked_lens", "wire_coil"]:
		if not level_one_ids.has(item_id):
			printerr("Merchant level 1 stock pool is missing expected basic resource: %s" % item_id)
			return false
	for item_id in ["battery_old", "medicine_powder", "tool_parts", "reinforced_strap", "pulse_battery", "signal_resonator_coil"]:
		if not level_two_ids.has(item_id):
			printerr("Merchant level 2 stock pool is missing expected resource: %s" % item_id)
			return false
	var level_one_qualities := _shop_quality_set(registry.get_shop_stock_rows_for_level(1), registry)
	var level_two_qualities := _shop_quality_set(registry.get_shop_stock_rows_for_level(2), registry)
	var level_three_qualities := _shop_quality_set(registry.get_shop_stock_rows_for_level(3), registry)
	if level_one_qualities.has("A") or level_one_qualities.has("S"):
		printerr("Merchant level 1 must not include A/S stock rows.")
		return false
	if not level_two_qualities.has("A") or level_two_qualities.has("S"):
		printerr("Merchant level 2 must include A stock rows and exclude S stock rows.")
		return false
	if not level_three_qualities.has("S"):
		printerr("Merchant level 3 must include S stock rows.")
		return false
	for row in registry.shop_stock_rows:
		var item_id := String(row.get("item_id", ""))
		var item: Dictionary = registry.get_item(item_id)
		if not _is_sellable_shop_item(item):
			printerr("Merchant shop must only sell sellable warehouse items: %s" % item_id)
			return false
	return true

func _verify_outpost_materials_are_run_only(registry) -> bool:
	var ok := true
	for material_id in registry.repair_materials_by_id.keys():
		if not registry.get_item(String(material_id)).is_empty():
			printerr("Repair material must not be defined in items.tab: %s" % material_id)
			ok = false
	for row in registry.shop_stock_rows:
		var item_id := String(row.get("item_id", ""))
		if registry.repair_materials_by_id.has(item_id):
			printerr("Merchant shop must not sell run-only repair material: %s" % item_id)
			ok = false
	for context in registry.drop_rows_by_context.keys():
		for row in registry.drop_rows_by_context[context]:
			var item_id := String(row.get("item_id", ""))
			if registry.repair_materials_by_id.has(item_id):
				printerr("Container drops must not include run-only repair material: %s" % item_id)
				ok = false
	return ok

func _verify_actual_shop_buy_marks_source(game_state: Node) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	game_state.set_merchant_shop_level(1)
	game_state.add_currency("mine_coin", 100, "test_merchant_source")
	var offers: Array = game_state.refresh_shop_stock(13579)
	if offers.is_empty():
		printerr("Expected merchant stock offers.")
		return false
	var offer: Dictionary = offers[0]
	var result: Dictionary = game_state.buy_shop_item(String(offer.get("shop_offer_id", "")), 1)
	if not bool(result.get("ok", false)):
		printerr("Expected merchant buy to succeed: %s" % result)
		return false
	var warehouse_items: Array = game_state.get_warehouse_items_snapshot()
	if warehouse_items.size() != 1:
		printerr("Expected one bought item in warehouse.")
		return false
	var bought_item: Dictionary = warehouse_items[0]
	if String(bought_item.get("source", "")) != "merchant_shop":
		printerr("Expected merchant-bought item to keep merchant_shop source: %s" % bought_item)
		return false
	return true

func _verify_research_ignores_warehouse_source(game_state: Node, registry, source: String) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	_add_items_with_source(registry, game_state, "scrap_metal", 3, source)
	_add_items_with_source(registry, game_state, "cloth_dirty", 2, source)
	var before_count: int = game_state.get_warehouse_items_snapshot().size()
	game_state.add_currency("mine_coin", 20, "test_research_source_%s" % source)
	var quote: Dictionary = game_state.get_research_quote("move_speed")
	if not bool(quote.get("ok", false)):
		printerr("Expected research quote to ignore %s source items and use mine_coin only: %s" % [source, quote])
		return false
	if not Array(quote.get("requirement_details", [])).is_empty() or not Dictionary(quote.get("required_items", {})).is_empty():
		printerr("Expected research quote to expose no item requirements: %s" % quote)
		return false
	var result: Dictionary = game_state.complete_research("move_speed")
	if not bool(result.get("ok", false)) or game_state.get_research_level("move_speed") != 1:
		printerr("Expected research to complete with mine_coin only for %s source setup: %s" % [source, result])
		return false
	if game_state.get_warehouse_items_snapshot().size() != before_count:
		printerr("Expected research not to consume %s source items." % source)
		return false
	return true

func _shop_item_id_set(rows: Array) -> Dictionary:
	var result := {}
	for row in rows:
		result[String(row.get("item_id", ""))] = true
	return result

func _shop_quality_set(rows: Array, registry) -> Dictionary:
	var result := {}
	for row in rows:
		var item: Dictionary = registry.get_item(String(row.get("item_id", "")))
		result[String(item.get("quality", ""))] = true
	return result

func _is_sellable_shop_item(item: Dictionary) -> bool:
	return not item.is_empty() and String(item.get("item_type", "")).length() > 0 and String(item.get("sellable", "")) == "true" and int(item.get("sell_value", 0)) > 0

func _add_items_with_source(registry, game_state: Node, item_id: String, count: int, source: String) -> void:
	var items: Array[Dictionary] = []
	for _index in range(count):
		var stack: Dictionary = registry.make_item_stack(item_id)
		stack["source"] = source
		items.append(stack)
	game_state.add_to_warehouse(items)

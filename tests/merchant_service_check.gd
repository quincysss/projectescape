extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_merchant_service_and_base_entry()
	print("Merchant service compatibility and new base entry verified." if ok else "Merchant service compatibility and new base entry failed.")
	quit(0 if ok else 1)


func _verify_merchant_service_and_base_entry() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.add_to_warehouse([
		registry.make_item_stack("gold_data_chip"),
		registry.make_item_stack("ss_old_world_gold_bar"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("scrap_metal"),
	])

	var sellable_items: Array = game_state.query_sellable_items()
	var chip_group := _find_group_by_item_id(sellable_items, "gold_data_chip")
	var ss_group := _find_group_by_item_id(sellable_items, "ss_old_world_gold_bar")
	var bandage_group := _find_group_by_item_id(sellable_items, "field_bandage")
	var material_group := _find_group_by_item_id(sellable_items, "scrap_metal")
	if chip_group.is_empty() or ss_group.is_empty() or bandage_group.is_empty():
		printerr("Expected legacy merchant service to remain compatible with sellable inventory.")
		return false
	if not material_group.is_empty():
		printerr("Expected raw materials to be excluded from direct sale.")
		return false
	if int(bandage_group.get("count", 0)) != 2:
		printerr("Expected merchant service to group two warehouse bandages.")
		return false

	var quote: Dictionary = game_state.get_sell_quote(String(chip_group.get("warehouse_item_id", "")), 1)
	if not bool(quote.get("ok", false)) or int(quote.get("total_value", 0)) != 120:
		printerr("Expected gold_data_chip quote to pay 120 mine_coin.")
		return false
	var ss_quote: Dictionary = game_state.get_sell_quote(String(ss_group.get("warehouse_item_id", "")), 1)
	if not bool(ss_quote.get("ok", false)) or int(ss_quote.get("total_value", 0)) <= 0:
		printerr("Expected SS item quote to pay mine_coin.")
		return false
	var before_currency: int = game_state.get_currency_amount("mine_coin")
	var before_warehouse_count: int = game_state.get_warehouse_items_snapshot().size()
	var failed_sale: Dictionary = game_state.sell_warehouse_item(String(bandage_group.get("warehouse_item_id", "")), 3)
	if bool(failed_sale.get("ok", false)):
		printerr("Expected oversell to fail.")
		return false
	if game_state.get_currency_amount("mine_coin") != before_currency or game_state.get_warehouse_items_snapshot().size() != before_warehouse_count:
		printerr("Expected failed sale to leave warehouse and currency unchanged.")
		return false

	var chip_sale: Dictionary = game_state.sell_warehouse_item(String(chip_group.get("warehouse_item_id", "")), 1)
	if not bool(chip_sale.get("ok", false)):
		printerr("Expected chip sale to succeed: %s" % chip_sale)
		return false
	if game_state.get_currency_amount("mine_coin") != 120:
		printerr("Expected successful sale to add mine_coin.")
		return false
	if not _find_group_by_item_id(game_state.query_sellable_items(), "gold_data_chip").is_empty():
		printerr("Expected sold chip to be removed from merchant sell list.")
		return false

	if not await _verify_base_uses_new_shop_entry(game_state, registry):
		return false
	return true


func _verify_base_uses_new_shop_entry(game_state: Node, registry) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	if game_state.has_method("reset_story_flags"):
		game_state.reset_story_flags()
	if game_state.has_method("mark_intro_cinematic_seen"):
		game_state.mark_intro_cinematic_seen()
	if game_state.has_method("mark_world_intro_dialogue_seen"):
		game_state.mark_world_intro_dialogue_seen()
	if game_state.has_method("mark_first_departure_outpost_dialogue_seen"):
		game_state.mark_first_departure_outpost_dialogue_seen()
	if game_state.has_method("mark_first_return_dialogue_seen_and_activate_chapter"):
		game_state.pending_first_return_dialogue = true
		var return_result: Dictionary = game_state.mark_first_return_dialogue_seen_and_activate_chapter()
		if not bool(return_result.get("ok", false)):
			printerr("Expected first return setup to unlock shop entry: %s" % return_result)
			return false
	game_state.add_to_warehouse([registry.make_item_stack("sale_good_repaired_filter")])

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	get_root().add_child(base_root)
	await process_frame

	var merchant_tab := base_root.get_node_or_null("BaseUIRoot/MerchantTabButton") as Button
	var warehouse_tab := base_root.get_node_or_null("BaseUIRoot/WarehouseTabButton") as Button
	var research_tab := base_root.get_node_or_null("BaseUIRoot/ResearchTabButton") as Button
	var crafting_tab := base_root.get_node_or_null("BaseUIRoot/CraftingTabButton") as Button
	var catalog_tab := base_root.get_node_or_null("BaseUIRoot/CatalogTabButton") as Button
	var start_button := base_root.get_node_or_null("BaseUIRoot/StartRunButton") as Button
	var merchant_panel := base_root.get_node_or_null("BaseUIRoot/MerchantPanel") as Panel
	var shop_day_panel := base_root.get_node_or_null("BaseUIRoot/ShopDayPrepPanel") as Panel
	if merchant_tab == null or warehouse_tab == null or research_tab == null or crafting_tab == null or catalog_tab == null or start_button == null or merchant_panel == null or shop_day_panel == null:
		printerr("Expected legacy merchant nodes and new shop day panel in BaseScene.")
		base_root.queue_free()
		return false
	if merchant_tab.visible or merchant_panel.visible:
		printerr("Expected old merchant tab/panel to stay hidden from the main outgame flow.")
		base_root.queue_free()
		return false
	if not shop_day_panel.visible:
		printerr("Expected day prep shop panel to be the main business entry.")
		base_root.queue_free()
		return false
	if not _verify_compact_top_navigation(warehouse_tab, research_tab, crafting_tab, catalog_tab, start_button):
		base_root.queue_free()
		return false

	base_root._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		printerr("Expected BaseScene start entry to open the day shop, not direct run loading.")
		base_root.queue_free()
		return false
	if merchant_panel.visible:
		printerr("Expected old merchant panel to remain hidden after opening shop.")
		base_root.queue_free()
		return false

	base_root.queue_free()
	await process_frame
	return true


func _find_group_by_item_id(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			return item
	return {}


func _verify_compact_top_navigation(
	warehouse_tab: Button,
	research_tab: Button,
	crafting_tab: Button,
	catalog_tab: Button,
	start_button: Button
) -> bool:
	var expected_x := 24.0
	for button in [warehouse_tab, research_tab, crafting_tab, catalog_tab]:
		if not button.visible:
			printerr("Expected visible base tab in compact navigation.")
			return false
		if not is_equal_approx(button.position.x, expected_x):
			printerr("Expected compact tab x %.1f, got %.1f." % [expected_x, button.position.x])
			return false
		expected_x += 120.0
	var expected_start_x := expected_x + 24.0
	if not is_equal_approx(start_button.position.x, expected_start_x):
		printerr("Expected start button x %.1f after compact tabs, got %.1f." % [expected_start_x, start_button.position.x])
		return false
	return true

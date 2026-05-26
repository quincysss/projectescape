extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

class FailingCurrencyWallet:
	extends CurrencyWallet

	func add_currency(currency_id: String, amount: int, reason: String = "") -> Dictionary:
		return {"ok": false, "reason": "forced_failure", "message": "forced failure"}

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
		registry.make_item_stack("blackbox_memory_core"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("scrap_metal"),
	])

	var sellable_items: Array = game_state.query_sellable_items()
	var chip_group := _find_group_by_item_id(sellable_items, "gold_data_chip")
	var high_value_group := _find_group_by_item_id(sellable_items, "blackbox_memory_core")
	var bandage_group := _find_group_by_item_id(sellable_items, "field_bandage")
	var material_group := _find_group_by_item_id(sellable_items, "scrap_metal")
	if chip_group.is_empty() or high_value_group.is_empty() or bandage_group.is_empty():
		printerr("Expected legacy merchant service to remain compatible with sellable inventory.")
		return false
	if not material_group.is_empty():
		printerr("Expected raw materials to be excluded from direct sale.")
		return false
	if int(bandage_group.get("count", 0)) != 2:
		printerr("Expected merchant service to group two warehouse bandages.")
		return false
	if not _verify_merchant_stack_quantity_sales(registry):
		return false
	if not _verify_merchant_group_dimensions():
		return false
	if not _verify_merchant_buy_stacks_in_warehouse():
		return false

	var quote: Dictionary = game_state.get_sell_quote(String(chip_group.get("warehouse_item_id", "")), 1)
	if not bool(quote.get("ok", false)) or int(quote.get("total_value", 0)) != 120:
		printerr("Expected gold_data_chip quote to pay 120 mine_coin.")
		return false
	var high_value_quote: Dictionary = game_state.get_sell_quote(String(high_value_group.get("warehouse_item_id", "")), 1)
	if not bool(high_value_quote.get("ok", false)) or int(high_value_quote.get("total_value", 0)) <= 0:
		printerr("Expected S item quote to pay mine_coin.")
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


func _verify_merchant_stack_quantity_sales(registry) -> bool:
	var warehouse_items: Array[Dictionary] = []
	var warehouse := WarehouseManager.new()
	warehouse.bind_items(warehouse_items)
	var currencies := {}
	var wallet := CurrencyWallet.new()
	wallet.bind_currencies(currencies)
	var service := MerchantService.new()
	service.bind_dependencies(warehouse, wallet)

	warehouse.add_items([registry.make_item_stack("field_bandage", 5)])
	var single_stack_group := _find_group_by_item_id(service.query_sellable_items(), "field_bandage")
	var single_stack_sale: Dictionary = service.sell_warehouse_item(String(single_stack_group.get("warehouse_item_id", "")), 3)
	if not bool(single_stack_sale.get("ok", false)):
		printerr("Expected partial single-stack sale to succeed: %s" % single_stack_sale)
		return false
	if warehouse.get_item_count("field_bandage") != 2:
		printerr("Expected selling 3 from amount=5 stack to leave 2, got %d." % warehouse.get_item_count("field_bandage"))
		return false
	if wallet.get_currency_amount("mine_coin") != 42:
		printerr("Expected partial single-stack sale to pay 42 mine_coin.")
		return false

	warehouse.clear()
	wallet.clear()
	warehouse.add_items([registry.make_item_stack("field_bandage", 7)])
	var multi_stack_group := _find_group_by_item_id(service.query_sellable_items(), "field_bandage")
	var multi_stack_sale: Dictionary = service.sell_warehouse_item(String(multi_stack_group.get("warehouse_item_id", "")), 6)
	if not bool(multi_stack_sale.get("ok", false)):
		printerr("Expected multi-stack sale to succeed: %s" % multi_stack_sale)
		return false
	if warehouse.get_item_count("field_bandage") != 1:
		printerr("Expected selling 6 across amount=5+2 stacks to leave 1, got %d." % warehouse.get_item_count("field_bandage"))
		return false
	if wallet.get_currency_amount("mine_coin") != 84:
		printerr("Expected multi-stack sale to pay 84 mine_coin.")
		return false

	var rollback_items: Array[Dictionary] = []
	var rollback_warehouse := WarehouseManager.new()
	rollback_warehouse.bind_items(rollback_items)
	rollback_warehouse.add_items([registry.make_item_stack("field_bandage", 5)])
	var failing_wallet := FailingCurrencyWallet.new()
	failing_wallet.bind_currencies({})
	var failing_service := MerchantService.new()
	failing_service.bind_dependencies(rollback_warehouse, failing_wallet)
	var rollback_group := _find_group_by_item_id(failing_service.query_sellable_items(), "field_bandage")
	var failed_sale: Dictionary = failing_service.sell_warehouse_item(String(rollback_group.get("warehouse_item_id", "")), 3)
	if bool(failed_sale.get("ok", false)):
		printerr("Expected forced currency failure to fail sale.")
		return false
	if rollback_warehouse.get_item_count("field_bandage") != 5:
		printerr("Expected currency failure rollback to restore exactly 5 bandages, got %d." % rollback_warehouse.get_item_count("field_bandage"))
		return false
	return true


func _verify_merchant_group_dimensions() -> bool:
	var warehouse_items: Array[Dictionary] = [
		_make_manual_sellable("field_bandage", "consumable", "C", 14),
		_make_manual_sellable("field_bandage", "consumable", "B", 14),
		_make_manual_sellable("field_bandage", "consumable", "C", 20),
	]
	var warehouse := WarehouseManager.new()
	warehouse.bind_items(warehouse_items)
	var wallet := CurrencyWallet.new()
	wallet.bind_currencies({})
	var service := MerchantService.new()
	service.bind_dependencies(warehouse, wallet)
	var groups := service.query_sellable_items()
	if groups.size() != 3:
		printerr("Expected item_id/item_type/quality/currency/sell_value grouping to keep 3 distinct groups: %s" % groups)
		return false
	for group in groups:
		if int(group.get("count", 0)) != 1:
			printerr("Expected distinct sellable dimensions to avoid accidental count merging: %s" % group)
			return false
	return true


func _verify_merchant_buy_stacks_in_warehouse() -> bool:
	var warehouse_items: Array[Dictionary] = []
	var warehouse := WarehouseManager.new()
	warehouse.bind_items(warehouse_items)
	var currencies := {"mine_coin": 1000}
	var wallet := CurrencyWallet.new()
	wallet.bind_currencies(currencies)
	var service := MerchantService.new()
	service.bind_dependencies(warehouse, wallet, [{
		"shop_offer_id": "test:field_bandage",
		"item_id": "field_bandage",
		"display_name": "field_bandage",
		"count": 4,
		"buy_currency_id": "mine_coin",
		"buy_price": 14,
	}])
	var buy_result: Dictionary = service.buy_shop_item("test:field_bandage", 3)
	if not bool(buy_result.get("ok", false)):
		printerr("Expected merchant buy count > 1 to succeed: %s" % buy_result)
		return false
	if warehouse.get_item_count("field_bandage") != 3:
		printerr("Expected merchant buy to add 3 bandages, got %d." % warehouse.get_item_count("field_bandage"))
		return false
	if warehouse.get_items_snapshot().size() != 1:
		printerr("Expected merchant buy count > 1 to use one warehouse stack, got %d slots." % warehouse.get_items_snapshot().size())
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


func _make_manual_sellable(item_id: String, item_type: String, quality: String, sell_value: int) -> Dictionary:
	return {
		"item_id": StringName(item_id),
		"display_name": item_id,
		"amount": 1,
		"weight_per_unit": 0.0,
		"stackable": false,
		"stack_limit": 1,
		"item_type": StringName(item_type),
		"quality": StringName(quality),
		"tags": [],
		"sellable": true,
		"sell_currency_id": "mine_coin",
		"sell_value": sell_value,
	}


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

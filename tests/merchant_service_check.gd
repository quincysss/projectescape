extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_merchant_service_and_base_tabs()
	print("Merchant service and base tabs verified." if ok else "Merchant service and base tabs failed.")
	quit(0 if ok else 1)

func _verify_merchant_service_and_base_tabs() -> bool:
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
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("scrap_metal"),
	])

	var sellable_items: Array = game_state.query_sellable_items()
	var chip_group := _find_group_by_item_id(sellable_items, "gold_data_chip")
	var bandage_group := _find_group_by_item_id(sellable_items, "field_bandage")
	var material_group := _find_group_by_item_id(sellable_items, "scrap_metal")
	if chip_group.is_empty() or bandage_group.is_empty():
		printerr("Expected rare item and medical consumable to be sellable.")
		return false
	if not material_group.is_empty():
		printerr("Expected material to be hidden from merchant sell list.")
		return false
	if int(bandage_group.get("count", 0)) != 2:
		printerr("Expected merchant to group two warehouse bandages.")
		return false

	var quote: Dictionary = game_state.get_sell_quote(String(chip_group.get("warehouse_item_id", "")), 1)
	if not bool(quote.get("ok", false)) or int(quote.get("total_value", 0)) != 120:
		printerr("Expected gold_data_chip quote to pay 120 mine_coin.")
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

	if not await _verify_base_merchant_tab(game_state, registry):
		return false
	return true

func _verify_base_merchant_tab(game_state: Node, registry) -> bool:
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
	game_state.add_to_warehouse([registry.make_item_stack("field_bandage")])
	var bandage_group := _find_group_by_item_id(game_state.query_sellable_items(), "field_bandage")
	if bandage_group.is_empty():
		printerr("Expected bandage group before opening merchant tab.")
		return false

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	get_root().add_child(base_root)
	await process_frame

	var warehouse_tab := base_root.get_node_or_null("BaseUIRoot/WarehouseTabButton") as Button
	var merchant_tab := base_root.get_node_or_null("BaseUIRoot/MerchantTabButton") as Button
	var research_tab := base_root.get_node_or_null("BaseUIRoot/ResearchTabButton") as Button
	var crafting_tab := base_root.get_node_or_null("BaseUIRoot/CraftingTabButton") as Button
	var merchant_panel := base_root.get_node_or_null("BaseUIRoot/MerchantPanel") as Panel
	var warehouse_label := base_root.get_node_or_null("BaseUIRoot/WarehouseLabel") as RichTextLabel
	if warehouse_tab == null or merchant_tab == null or research_tab == null or crafting_tab == null or merchant_panel == null or warehouse_label == null:
		printerr("Expected all out-of-run tabs and panels in BaseScene.")
		base_root.queue_free()
		return false
	if warehouse_tab.text != "仓库" or merchant_tab.text != "商人" or research_tab.text != "研究所" or crafting_tab.text != "制造所":
		printerr("Expected top tab order: 仓库, 商人, 研究所, 制造所.")
		base_root.queue_free()
		return false
	if research_tab.disabled or not crafting_tab.disabled:
		printerr("Expected research to be clickable and manufacturing to stay locked before chapter 1 objective.")
		base_root.queue_free()
		return false
	game_state.activate_chapter_1_goal_debug()
	base_root._refresh()
	await process_frame
	if crafting_tab.disabled:
		printerr("Expected manufacturing tab to unlock after chapter 1 objective is active.")
		base_root.queue_free()
		return false

	merchant_tab.emit_signal("pressed")
	await process_frame
	if not merchant_panel.visible or warehouse_label.visible:
		printerr("Expected merchant tab to hide warehouse view and show merchant panel.")
		base_root.queue_free()
		return false
	var merchant_list := base_root.get_node_or_null("BaseUIRoot/MerchantPanel/MerchantList") as RichTextLabel
	if merchant_list == null or not merchant_list.get_parsed_text().contains("临时绷带"):
		printerr("Expected merchant tab to list sellable warehouse items.")
		base_root.queue_free()
		return false

	base_root._on_merchant_item_meta_clicked("sell:%s" % String(bandage_group.get("warehouse_item_id", "")))
	base_root._on_sell_pressed()
	await process_frame
	if game_state.get_currency_amount("mine_coin") != 14:
		printerr("Expected merchant UI sell action to grant mine_coin through GameState.")
		base_root.queue_free()
		return false
	var result_label := base_root.get_node_or_null("BaseUIRoot/MerchantPanel/MerchantResultLabel") as Label
	if result_label == null or not result_label.text.contains("已出售"):
		printerr("Expected merchant UI to show sale result prompt.")
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

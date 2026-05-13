extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_merchant_shop_stock()
	print("Merchant shop stock verified." if ok else "Merchant shop stock failed.")
	quit(0 if ok else 1)

func _verify_merchant_shop_stock() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load shop stock: %s" % registry.load_errors)
		return false
	if registry.get_shop_stock_rows_for_level(1).is_empty() or registry.get_shop_stock_rows_for_level(3).size() <= registry.get_shop_stock_rows_for_level(1).size():
		printerr("Expected higher merchant levels to expose a wider shop stock pool.")
		return false

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.set_merchant_shop_level(1)
	game_state.add_currency("mine_coin", 100, "test_shop_buy")
	var level_one_offers: Array = game_state.refresh_shop_stock(12345)
	if level_one_offers.size() != 3:
		printerr("Expected level 1 merchant to generate 3 offers, got %d." % level_one_offers.size())
		return false
	for offer in level_one_offers:
		if not _is_resource_offer(offer):
			printerr("Expected shop offers to be material resources only: %s" % offer)
			return false
		if int(offer.get("min_shop_level", 1)) > 1:
			printerr("Expected level 1 stock to exclude higher-level rows.")
			return false

	var first_offer: Dictionary = level_one_offers[0]
	var quote: Dictionary = game_state.get_buy_quote(String(first_offer.get("shop_offer_id", "")), 1)
	if not bool(quote.get("ok", false)):
		printerr("Expected buy quote to succeed: %s" % quote)
		return false
	var before_currency: int = game_state.get_currency_amount("mine_coin")
	var before_warehouse_count: int = game_state.get_warehouse_items_snapshot().size()
	var buy_result: Dictionary = game_state.buy_shop_item(String(first_offer.get("shop_offer_id", "")), 1)
	if not bool(buy_result.get("ok", false)):
		printerr("Expected buy to succeed: %s" % buy_result)
		return false
	if game_state.get_currency_amount("mine_coin") != before_currency - int(quote.get("total_price", 0)):
		printerr("Expected buy to spend mine_coin.")
		return false
	if game_state.get_warehouse_items_snapshot().size() != before_warehouse_count + 1:
		printerr("Expected bought resource to enter warehouse.")
		return false

	game_state.clear_currencies()
	var warehouse_after_success: int = game_state.get_warehouse_items_snapshot().size()
	var failed_buy: Dictionary = game_state.buy_shop_item(String(first_offer.get("shop_offer_id", "")), 1)
	if bool(failed_buy.get("ok", false)):
		printerr("Expected buy without currency to fail.")
		return false
	if game_state.get_warehouse_items_snapshot().size() != warehouse_after_success:
		printerr("Expected failed buy to leave warehouse unchanged.")
		return false

	game_state.set_merchant_shop_level(3)
	var level_three_offers: Array = game_state.refresh_shop_stock(12345)
	if level_three_offers.size() != 5:
		printerr("Expected level 3 merchant to generate 5 offers, got %d." % level_three_offers.size())
		return false
	if not await _verify_base_shop_buy(game_state):
		return false
	return true

func _verify_base_shop_buy(game_state: Node) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.set_merchant_shop_level(1)
	game_state.add_currency("mine_coin", 100, "test_base_shop_ui")
	var offers: Array = game_state.refresh_shop_stock(2468)
	if offers.is_empty():
		printerr("Expected shop offers before opening BaseScene.")
		return false
	var first_offer: Dictionary = offers[0]

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	get_root().add_child(base_root)
	await process_frame

	var merchant_tab := base_root.get_node_or_null("BaseUIRoot/MerchantTabButton") as Button
	var shop_stock_list := base_root.get_node_or_null("BaseUIRoot/MerchantPanel/ShopStockList") as RichTextLabel
	var buy_button := base_root.get_node_or_null("BaseUIRoot/MerchantPanel/BuyButton") as Button
	if merchant_tab == null or shop_stock_list == null or buy_button == null:
		printerr("Expected merchant shop UI controls in BaseScene.")
		base_root.queue_free()
		return false

	merchant_tab.emit_signal("pressed")
	await process_frame
	if not shop_stock_list.get_parsed_text().contains(String(first_offer.get("display_name", ""))):
		printerr("Expected BaseScene merchant tab to list shop stock.")
		base_root.queue_free()
		return false

	var before_currency: int = game_state.get_currency_amount("mine_coin")
	var before_count: int = game_state.get_warehouse_items_snapshot().size()
	base_root._on_shop_stock_meta_clicked("buy:%s" % String(first_offer.get("shop_offer_id", "")))
	if buy_button.disabled:
		printerr("Expected buy button to enable after selecting affordable stock.")
		base_root.queue_free()
		return false
	base_root._on_buy_pressed()
	await process_frame
	if game_state.get_warehouse_items_snapshot().size() != before_count + 1:
		printerr("Expected BaseScene buy action to add resource to warehouse.")
		base_root.queue_free()
		return false
	if game_state.get_currency_amount("mine_coin") >= before_currency:
		printerr("Expected BaseScene buy action to spend mine_coin.")
		base_root.queue_free()
		return false
	base_root.queue_free()
	await process_frame
	return true

func _is_resource_offer(offer: Variant) -> bool:
	if not (offer is Dictionary):
		return false
	var item_type := String(offer.get("item_type", ""))
	return item_type == "material"

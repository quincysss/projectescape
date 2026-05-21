extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_item_catalog_collection()
	print("Item catalog collection verified." if ok else "Item catalog collection failed.")
	quit(0 if ok else 1)

func _verify_item_catalog_collection() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load items: %s" % registry.load_errors)
		return false
	if game_state.has_method("create_profile"):
		game_state.create_profile("Catalog01")
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.clear_collected_items_debug_only()

	var catalog_items: Array = game_state.query_catalog_items()
	if catalog_items.size() != registry.items_by_id.size():
		printerr("Expected catalog to list every items.tab item.")
		return false
	if _catalog_item_collected(catalog_items, "gold_data_chip"):
		printerr("Expected gold_data_chip to start uncollected.")
		return false

	game_state.add_to_warehouse([registry.make_item_stack("gold_data_chip")])
	if not game_state.is_item_collected("gold_data_chip"):
		printerr("Expected adding an item to warehouse to light catalog.")
		return false
	var duplicate_mark: Dictionary = game_state.mark_item_collected("gold_data_chip", "test_duplicate")
	if bool(duplicate_mark.get("changed", true)):
		printerr("Expected duplicate catalog mark to be idempotent.")
		return false

	var group := _find_sell_group_by_item_id(game_state.query_sellable_items(), "gold_data_chip")
	if group.is_empty():
		printerr("Expected gold_data_chip to be sellable for persistence check.")
		return false
	var sell_result: Dictionary = game_state.sell_warehouse_item(String(group.get("warehouse_item_id", "")), 1)
	if not bool(sell_result.get("ok", false)):
		printerr("Expected selling collected item to succeed: %s" % sell_result)
		return false
	if not game_state.is_item_collected("gold_data_chip"):
		printerr("Expected selling item to keep catalog lit.")
		return false

	game_state.add_to_warehouse([registry.make_item_stack("scrap_metal")])
	game_state.clear_warehouse()
	if not game_state.is_item_collected("scrap_metal"):
		printerr("Expected clearing warehouse to keep catalog lit.")
		return false

	var preview_items: Array = game_state.query_catalog_items()
	if _catalog_item_collected(preview_items, "blackbox_memory_core"):
		printerr("Expected catalog preview itself not to light unseen items.")
		return false

	if not await _verify_base_catalog_ui(registry, game_state):
		return false
	return true

func _verify_base_catalog_ui(registry, game_state: Node) -> bool:
	if game_state.has_method("mark_first_return_dialogue_seen_and_activate_chapter"):
		var unlock_result: Dictionary = game_state.mark_first_return_dialogue_seen_and_activate_chapter()
		if not bool(unlock_result.get("ok", false)):
			printerr("Expected first return chapter activation to unlock catalog UI: %s" % unlock_result)
			return false
	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	var catalog_tab := base_root.get("catalog_tab_button") as Button
	var catalog_panel := base_root.get("catalog_panel") as Panel
	var catalog_scroll := base_root.get_node_or_null("BaseUIRoot/CatalogPanel/CatalogScroll") as ScrollContainer
	var catalog_grid := base_root.get_node_or_null("BaseUIRoot/CatalogPanel/CatalogScroll/CatalogGrid") as Control
	var shop_day_panel := base_root.get_node_or_null("BaseUIRoot/ShopDayPrepPanel") as Panel
	if catalog_tab == null or catalog_panel == null or catalog_scroll == null or catalog_grid == null or shop_day_panel == null:
		printerr("Expected catalog tab, panel, and grid nodes.")
		base_root.queue_free()
		return false
	if catalog_tab.disabled:
		printerr("Expected catalog tab to be available by default.")
		base_root.queue_free()
		return false
	catalog_tab.emit_signal("pressed")
	await process_frame
	if not catalog_panel.visible:
		printerr("Expected catalog panel to show after pressing catalog tab.")
		base_root.queue_free()
		return false
	if catalog_panel.get_rect().intersects(shop_day_panel.get_rect()):
		printerr("Expected day demand panel to stay outside the catalog content area.")
		base_root.queue_free()
		return false
	var cards := catalog_grid.get_children()
	if cards.size() != registry.items_by_id.size():
		printerr("Expected one catalog card per items.tab item.")
		base_root.queue_free()
		return false
	if cards.size() >= 5:
		var first := cards[0] as Control
		var fourth := cards[3] as Control
		var fifth := cards[4] as Control
		if absf(first.position.y - fourth.position.y) > 0.01 or fifth.position.y <= first.position.y:
			printerr("Expected catalog layout to keep four cards per row.")
			base_root.queue_free()
			return false
	if catalog_grid.custom_minimum_size.x > catalog_scroll.size.x - 24.0:
		printerr("Expected catalog grid to reserve room for the vertical scrollbar.")
		base_root.queue_free()
		return false
	var gold_card := catalog_grid.get_node_or_null("CatalogCard_gold_data_chip") as Panel
	if gold_card == null or not bool(gold_card.get_meta("catalog_collected", false)):
		printerr("Expected collected catalog card to be marked as lit.")
		base_root.queue_free()
		return false
	var description_label := gold_card.get_node_or_null("Description") as Label
	if description_label == null or not description_label.text.contains("\n"):
		printerr("Expected catalog description to be pre-wrapped into centered lines.")
		base_root.queue_free()
		return false
	base_root.queue_free()
	await process_frame
	return true

func _catalog_item_collected(items: Array, item_id: String) -> bool:
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			return bool(item.get("collected", false))
	return false

func _find_sell_group_by_item_id(groups: Array, item_id: String) -> Dictionary:
	for group in groups:
		if group is Dictionary and String(group.get("item_id", "")) == item_id:
			return group
	return {}

extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_research_manager_and_base_ui()
	print("Research manager and base UI verified." if ok else "Research manager and base UI failed.")
	quit(0 if ok else 1)

func _verify_research_manager_and_base_ui() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load research rows: %s" % registry.load_errors)
		return false
	if registry.get_research_rows().size() < 21:
		printerr("Expected configured research rows for meta progression.")
		return false

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	if game_state.get_research_level("move_speed") != 0:
		printerr("Expected move_speed research to start at level 0.")
		return false
	if absf(game_state.get_player_move_speed_multiplier() - 1.0) > 0.001:
		printerr("Expected no speed multiplier before research.")
		return false
	if game_state.get_inventory_slot_count() != 8 or game_state.get_home_storage_slot_count() != 1 or game_state.get_outpost_storage_slot_count() != 0:
		printerr("Expected default researched storage capacities to match base rules.")
		return false
	if absf(game_state.get_player_max_stability() - 100.0) > 0.001 or game_state.get_warehouse_capacity() != 80:
		printerr("Expected default stability and warehouse capacity before research.")
		return false

	var locked_quote: Dictionary = game_state.get_research_quote("move_speed")
	if bool(locked_quote.get("ok", false)):
		printerr("Expected research to fail without materials and currency.")
		return false
	var before_count: int = game_state.get_warehouse_items_snapshot().size()
	var failed_result: Dictionary = game_state.complete_research("move_speed")
	if bool(failed_result.get("ok", false)):
		printerr("Expected complete_research to fail without costs.")
		return false
	if game_state.get_warehouse_items_snapshot().size() != before_count or game_state.get_currency_amount("mine_coin") != 0:
		printerr("Expected failed research to leave resources unchanged.")
		return false

	_add_items(registry, game_state, "scrap_metal", 3)
	_add_items(registry, game_state, "cloth_dirty", 2)
	game_state.add_currency("mine_coin", 20, "test_research")
	var level_one: Dictionary = game_state.complete_research("move_speed")
	if not bool(level_one.get("ok", false)):
		printerr("Expected move_speed level 1 research to complete: %s" % level_one)
		return false
	if game_state.get_research_level("move_speed") != 1:
		printerr("Expected move_speed level 1.")
		return false
	if game_state.get_currency_amount("mine_coin") != 0 or game_state.get_warehouse_items_snapshot().size() != 0:
		printerr("Expected level 1 research to consume all provided costs.")
		return false
	if absf(game_state.get_player_move_speed_multiplier() - 1.05) > 0.001:
		printerr("Expected level 1 speed multiplier to be 1.05.")
		return false

	_add_items(registry, game_state, "wire_coil", 2)
	_add_items(registry, game_state, "tool_parts", 2)
	_add_items(registry, game_state, "cloth_dirty", 3)
	game_state.add_currency("mine_coin", 45, "test_research")
	var level_two: Dictionary = game_state.complete_research("move_speed")
	if not bool(level_two.get("ok", false)) or game_state.get_research_level("move_speed") != 2:
		printerr("Expected move_speed level 2 research to complete.")
		return false

	if not await _verify_base_research_tab(registry, game_state):
		return false

	if game_state.get_research_level("move_speed") != 3:
		printerr("Expected BaseScene research flow to complete move_speed level 3.")
		return false
	if absf(game_state.get_player_move_speed_multiplier() - 1.16) > 0.001:
		printerr("Expected level 3 speed multiplier to be 1.16.")
		return false
	var max_quote: Dictionary = game_state.get_research_quote("move_speed")
	if bool(max_quote.get("ok", false)) or String(max_quote.get("error", "")) != "max_level":
		printerr("Expected max-level research quote to stop further upgrades.")
		return false

	return true

func _verify_base_research_tab(registry, game_state: Node) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	_add_items(registry, game_state, "battery_old", 2)
	_add_items(registry, game_state, "tool_parts", 4)
	_add_items(registry, game_state, "wire_coil", 3)
	game_state.add_currency("mine_coin", 80, "test_base_research")

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	var research_tab := base_root.get_node_or_null("BaseUIRoot/ResearchTabButton") as Button
	var research_panel := base_root.get_node_or_null("BaseUIRoot/ResearchPanel") as Panel
	var research_list := base_root.get_node_or_null("BaseUIRoot/ResearchPanel/ResearchList") as RichTextLabel
	var research_button := base_root.get_node_or_null("BaseUIRoot/ResearchPanel/ResearchButton") as Button
	if research_tab == null or research_panel == null or research_list == null or research_button == null:
		printerr("Expected research tab controls in BaseScene.")
		base_root.queue_free()
		return false
	if research_tab.disabled:
		printerr("Expected research tab to be enabled.")
		base_root.queue_free()
		return false

	research_tab.emit_signal("pressed")
	await process_frame
	if not research_panel.visible or not research_list.get_parsed_text().contains("行动训练"):
		printerr("Expected research panel to list move speed research.")
		base_root.queue_free()
		return false
	base_root._on_research_meta_clicked("research:move_speed")
	if research_button.disabled:
		printerr("Expected research button to enable for affordable level 3.")
		base_root.queue_free()
		return false
	base_root._on_research_pressed()
	var confirm_dialog := base_root.get_node_or_null("BaseUIRoot/ResearchConfirmDialog") as ConfirmationDialog
	if confirm_dialog == null or not confirm_dialog.visible:
		printerr("Expected research button to open confirmation dialog.")
		base_root.queue_free()
		return false
	base_root._on_research_confirmed()
	await process_frame
	if game_state.get_research_level("move_speed") != 3:
		printerr("Expected confirmed BaseScene research to complete level 3.")
		base_root.queue_free()
		return false
	base_root.queue_free()
	await process_frame
	return true

func _add_items(registry, game_state: Node, item_id: String, count: int) -> void:
	var items: Array[Dictionary] = []
	for _index in range(count):
		items.append(registry.make_item_stack(item_id))
	game_state.add_to_warehouse(items)

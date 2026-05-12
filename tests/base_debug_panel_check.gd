extends SceneTree

func _initialize() -> void:
	var ok := await _verify_base_debug_panel()
	print("Base debug panel verified." if ok else "Base debug panel failed.")
	quit(0 if ok else 1)

func _verify_base_debug_panel() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	game_state.set_merchant_shop_level(1)

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	var debug_panel := base_root.get_node_or_null("BaseUIRoot/DebugPanel") as Panel
	var add_currency_button := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugAddCurrencyButton") as Button
	var add_sell_items_button := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugAddSellItemsButton") as Button
	var refresh_shop_button := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugRefreshShopButton") as Button
	var complete_research_button := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugCompleteResearchButton") as Button
	var force_monster_button := _find_button_by_text(debug_panel, "本日必出怪物")
	var debug_result_label := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugResultLabel") as Label
	if debug_panel == null or add_currency_button == null or add_sell_items_button == null or refresh_shop_button == null or complete_research_button == null or force_monster_button == null or debug_result_label == null:
		return _fail_with_restore("Expected debug panel controls in BaseScene.", game_state, original_profile, base_root)

	add_currency_button.emit_signal("pressed")
	await process_frame
	if game_state.get_currency_amount("mine_coin") != 500:
		return _fail_with_restore("Expected debug currency button to add mine_coin.", game_state, original_profile, base_root)

	add_sell_items_button.emit_signal("pressed")
	await process_frame
	if game_state.query_sellable_items().is_empty():
		return _fail_with_restore("Expected debug sell item button to add sellable items.", game_state, original_profile, base_root)

	refresh_shop_button.emit_signal("pressed")
	await process_frame
	if game_state.query_shop_offers().is_empty():
		return _fail_with_restore("Expected debug refresh shop button to create shop offers.", game_state, original_profile, base_root)

	complete_research_button.emit_signal("pressed")
	await process_frame
	if game_state.get_research_level("move_speed") != 1:
		return _fail_with_restore("Expected debug complete research button to finish next move_speed level.", game_state, original_profile, base_root)
	if not debug_result_label.text.contains("已完成研究"):
		return _fail_with_restore("Expected debug result label to show research completion.", game_state, original_profile, base_root)

	force_monster_button.emit_signal("pressed")
	await process_frame
	if not game_state.get_forced_scene_events_next_run().has("monster_presence"):
		return _fail_with_restore("Expected debug force monster button to set next-run monster event.", game_state, original_profile, base_root)

	base_root.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true

func _find_button_by_text(root_node: Node, text: String) -> Button:
	if root_node == null:
		return null
	for child in root_node.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button.text == text:
			return button
	return null

func _fail_with_restore(message: String, game_state: Node, original_profile: Dictionary, base_root = null) -> bool:
	printerr(message)
	if base_root != null:
		base_root.queue_free()
	_restore_profile(game_state, original_profile)
	return false

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

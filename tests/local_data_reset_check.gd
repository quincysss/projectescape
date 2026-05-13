extends SceneTree

const BaseScene := preload("res://scenes/base/BaseScene.tscn")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify()
	print("Local data reset verified." if ok else "Local data reset failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	var ok := true
	ok = _verify_game_state_reset(game_state) and ok
	ok = await _verify_debug_button_reset(game_state) and ok
	ok = await _verify_esc_settings_reset(game_state) and ok
	ok = await _verify_chapter_complete_reset(game_state) and ok
	_restore_profile(game_state, original_profile)
	return ok

func _verify_game_state_reset(game_state: Node) -> bool:
	if not _make_dirty_local_data(game_state):
		return false
	var result: Dictionary = game_state.reset_local_data_debug_only()
	if not bool(result.get("ok", false)):
		printerr("Expected reset_local_data_debug_only to pass: %s" % result)
		return false
	return _expect_clean_runtime(game_state, true)

func _verify_debug_button_reset(game_state: Node) -> bool:
	if not _make_dirty_local_data(game_state):
		return false
	var base_root = BaseScene.instantiate()
	root.add_child(base_root)
	await process_frame
	var reset_button := _find_button_by_text(base_root, "重置本地数据")
	if reset_button == null:
		printerr("Expected GM panel to include a local data reset button.")
		base_root.queue_free()
		await process_frame
		return false
	reset_button.emit_signal("pressed")
	await process_frame
	var result_label := base_root.get_node_or_null("BaseUIRoot/DebugPanel/DebugResultLabel") as Label
	var ok := _expect_clean_runtime(game_state, false)
	if result_label == null or not result_label.text.contains("重置本地数据"):
		printerr("Expected GM reset button to report local data reset.")
		ok = false
	base_root.queue_free()
	await process_frame
	return ok

func _verify_esc_settings_reset(game_state: Node) -> bool:
	if not _make_dirty_local_data(game_state):
		return false
	var base_root = BaseScene.instantiate()
	root.add_child(base_root)
	await process_frame
	var settings_button := base_root.get_node_or_null("BaseUIRoot/EscSettingsButton") as Button
	if settings_button == null:
		printerr("Expected base surface to include a bottom-right ESC settings button.")
		base_root.queue_free()
		await process_frame
		return false
	settings_button.emit_signal("pressed")
	await process_frame
	var popup := base_root.get_node_or_null("EscSettingsPopupOverlay") as Control
	var reset_button := _find_button_by_text(base_root, "重置进度")
	if popup == null or reset_button == null:
		printerr("Expected ESC settings popup to include reset progress.")
		base_root.queue_free()
		await process_frame
		return false
	reset_button.emit_signal("pressed")
	await process_frame
	var ok := _expect_clean_runtime(game_state, false)
	var notice := _find_label_containing(base_root, "重新登陆或刷新界面")
	if notice == null:
		printerr("Expected reset progress notice to tell the player to relogin or refresh.")
		ok = false
	base_root.queue_free()
	await process_frame
	return ok

func _verify_chapter_complete_reset(game_state: Node) -> bool:
	if not _make_dirty_local_data(game_state):
		return false
	var base_root = BaseScene.instantiate()
	root.add_child(base_root)
	await process_frame
	base_root._show_chapter_complete_popup(3)
	await process_frame
	var continue_button := _find_button_by_text(base_root, "继续游戏")
	var reset_button := _find_button_by_text(base_root, "重新开始")
	if continue_button == null or reset_button == null:
		printerr("Expected chapter complete popup to offer continue game and restart.")
		base_root.queue_free()
		await process_frame
		return false
	reset_button.emit_signal("pressed")
	await process_frame
	var ok := _expect_clean_runtime(game_state, false)
	var notice := _find_label_containing(base_root, "重新登陆或刷新界面")
	if notice == null:
		printerr("Expected chapter reset notice to tell the player to relogin or refresh.")
		ok = false
	base_root.queue_free()
	await process_frame
	return ok

func _make_dirty_local_data(game_state: Node) -> bool:
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("ResetTester")
	if not bool(create_result.get("ok", false)):
		printerr("Expected temporary profile creation to pass: %s" % create_result)
		return false
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load for reset test: %s" % registry.load_errors)
		return false
	game_state.add_currency("mine_coin", 1234, "local_data_reset_test")
	game_state.add_to_warehouse([
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("gold_data_chip"),
	])
	game_state.reset_day(5)
	game_state.intro_cinematic_seen = true
	game_state.world_intro_dialogue_seen = true
	game_state.first_departure_outpost_dialogue_seen = true
	game_state.first_intro_dialogue_seen = true
	game_state.first_return_dialogue_seen = true
	game_state.chapter_1_goal_active = true
	game_state.manufacturing_station_unlocked = true
	game_state.chapter_1_completed = true
	game_state.pending_first_return_dialogue = true
	game_state.research_levels["move_speed"] = 2
	game_state.set_merchant_shop_level(3)
	game_state.refresh_shop_stock(42)
	game_state.debug_set_ss_roll_state(3, 2, 5)
	game_state.last_run_result = "dirty"
	game_state.save_profile()
	return true

func _expect_clean_runtime(game_state: Node, require_merchant_empty: bool) -> bool:
	var ok := true
	if game_state.has_profile():
		printerr("Expected reset to delete the local profile file.")
		ok = false
	if not game_state.profile.is_empty():
		printerr("Expected runtime profile dictionary to be empty.")
		ok = false
	if game_state.username != "":
		printerr("Expected username to be empty after reset.")
		ok = false
	if int(game_state.get_current_day()) != 0:
		printerr("Expected surface_day to reset to 0.")
		ok = false
	if game_state.get_currency_amount("mine_coin") != 0:
		printerr("Expected mine_coin to reset to 0.")
		ok = false
	if not game_state.get_warehouse_items_snapshot().is_empty():
		printerr("Expected warehouse to be empty after reset.")
		ok = false
	if game_state.get_research_level("move_speed") != 0:
		printerr("Expected research levels to reset.")
		ok = false
	if absf(game_state.get_player_move_speed_multiplier() - 1.0) > 0.001:
		printerr("Expected researched move speed bonus to reset.")
		ok = false
	if game_state.get_merchant_shop_level() != 1:
		printerr("Expected merchant shop level to reset to 1.")
		ok = false
	if require_merchant_empty and not game_state.merchant_shop_offers.is_empty():
		printerr("Expected merchant shop offers to reset.")
		ok = false
	if (
		game_state.current_chapter != 1
		or game_state.intro_cinematic_seen
		or game_state.world_intro_dialogue_seen
		or game_state.first_departure_outpost_dialogue_seen
		or game_state.first_intro_dialogue_seen
		or game_state.first_return_dialogue_seen
	):
		printerr("Expected story flags to reset.")
		ok = false
	if game_state.chapter_1_goal_active or game_state.manufacturing_station_unlocked or game_state.chapter_1_completed:
		printerr("Expected chapter and manufacturing state to reset.")
		ok = false
	if game_state.pending_first_return_dialogue:
		printerr("Expected pending return dialogue to reset.")
		ok = false
	var ss_state: Dictionary = game_state.get_ss_roll_state()
	if int(ss_state.get("chance_tier", -1)) != 0 or int(ss_state.get("miss_count", -1)) != 0 or int(ss_state.get("last_roll_day", -1)) != 0:
		printerr("Expected SS roll state to reset.")
		ok = false
	if game_state.last_run_result != "":
		printerr("Expected last run result to reset.")
		ok = false
	if game_state.get_selected_character_id() != "male_01":
		printerr("Expected selected character to reset to default.")
		ok = false
	return ok

func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and String(node.text) == text:
		return node
	for child in node.get_children():
		var found := _find_button_by_text(child, text)
		if found != null:
			return found
	return null

func _find_label_containing(node: Node, text: String) -> Label:
	if node is Label and String(node.text).contains(text):
		return node
	for child in node.get_children():
		var found := _find_label_containing(child, text)
		if found != null:
			return found
	return null

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

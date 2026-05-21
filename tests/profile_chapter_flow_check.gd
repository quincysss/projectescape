extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/ui/MainMenuScene.tscn")
const LOADING_SCENE := preload("res://scenes/ui/RunLoadingScreen.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Profile, dialogue, loading, and chapter flow verified." if ok else "Profile chapter flow failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()

	var create_result: Dictionary = game_state.create_profile("Tester01")
	if not bool(create_result.get("ok", false)):
		return await _fail_with_restore("Expected profile creation to pass: %s" % create_result, game_state, original_profile)
	if not game_state.has_profile() or game_state.username != "Tester01":
		return await _fail_with_restore("Expected created profile to be loaded into GameState.", game_state, original_profile)
	if not bool(game_state.manufacturing_station_unlocked):
		return await _fail_with_restore("Expected manufacturing facility to exist by default.", game_state, original_profile)
	if bool(game_state.is_shop_loop_unlocked()) or bool(game_state.is_research_station_unlocked()):
		return await _fail_with_restore("Expected new profile to keep formal shop loop and research locked.", game_state, original_profile)
	if game_state.get_outgame_phase() != "NIGHT":
		return await _fail_with_restore("Expected new profile to start at prologue night departure gate.", game_state, original_profile)

	var reloaded_profile: Dictionary = game_state.load_profile()
	if String(reloaded_profile.get("username", "")) != "Tester01":
		return await _fail_with_restore("Expected saved profile to reload username.", game_state, original_profile)
	var legacy_failed_return_profile := reloaded_profile.duplicate(true)
	legacy_failed_return_profile["surface_day"] = 1
	legacy_failed_return_profile["first_departure_outpost_dialogue_seen"] = true
	legacy_failed_return_profile["first_return_dialogue_seen"] = false
	legacy_failed_return_profile["pending_first_return_dialogue"] = false
	legacy_failed_return_profile["run_start_pending_result"] = false
	game_state._apply_profile_to_runtime(legacy_failed_return_profile)
	if game_state.get_current_day() != 2 or not game_state.should_play_first_return_dialogue():
		return await _fail_with_restore("Expected legacy first-failure return saves to repair to day 2 and queue first return dialogue.", game_state, original_profile)
	game_state._apply_profile_to_runtime(reloaded_profile)

	if not game_state.should_play_intro_cinematic() or not game_state.should_play_world_intro_dialogue():
		return await _fail_with_restore("Expected new profile to require opening cinematic and world intro dialogue.", game_state, original_profile)
	if not game_state.should_play_first_departure_outpost_dialogue():
		return await _fail_with_restore("Expected new profile to require first departure outpost dialogue.", game_state, original_profile)
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	if game_state.get_current_day() != 1 or game_state.get_outgame_phase() != "NIGHT":
		return await _fail_with_restore("Expected world intro completion to enter day 1 prologue night.", game_state, original_profile)

	if not await _verify_main_menu_profile_ui(game_state, original_profile):
		return false
	if not await _verify_loading_waits_for_input(game_state, original_profile):
		return false

	var day_before: int = int(game_state.get_current_day())
	var commit_result: Dictionary = game_state.commit_run_start(false)
	if not bool(commit_result.get("ok", false)) or game_state.get_current_day() != day_before:
		return await _fail_with_restore("Expected run start commit to keep the active prologue surface day.", game_state, original_profile)
	game_state.apply_run_result({
		"result_type": "DEAD",
		"message": "探索失败",
		"warehouse_items": [],
	})
	if game_state.get_current_day() != day_before + 1:
		return await _fail_with_restore("Expected first run result, even failure, to advance the base display to day 2.", game_state, original_profile)
	if not game_state.should_play_first_return_dialogue():
		return await _fail_with_restore("Expected first completed run, even failure, to queue return dialogue.", game_state, original_profile)
	if String(game_state.get_first_return_dialogue_id()) != "first_return_failed_dialogue":
		return await _fail_with_restore("Expected failed prologue return to use the failed dialogue branch.", game_state, original_profile)
	game_state.last_run_result_type = "EXTRACTED"
	if String(game_state.get_first_return_dialogue_id()) != "first_return_success_dialogue":
		return await _fail_with_restore("Expected extracted prologue return to use the success dialogue branch.", game_state, original_profile)
	game_state.last_run_result_type = "DEAD"
	if bool(game_state.starter_shop_supply_granted) or bool(game_state.is_shop_loop_unlocked()):
		return await _fail_with_restore("Expected starter supply and shop loop to wait for return dialogue completion.", game_state, original_profile)

	var return_result: Dictionary = game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	if not bool(return_result.get("ok", false)):
		return await _fail_with_restore("Expected first return dialogue completion to grant starter supply: %s" % return_result, game_state, original_profile)
	if not bool(game_state.starter_shop_supply_granted) or not bool(game_state.is_shop_loop_unlocked()) or not bool(game_state.is_research_station_unlocked()):
		return await _fail_with_restore("Expected first return to unlock shop loop, research, and starter supply.", game_state, original_profile)
	if game_state.get_outgame_phase() != "DAY_PREP":
		return await _fail_with_restore("Expected first return to open formal day prep.", game_state, original_profile)
	var snapshot: Dictionary = game_state.get_chapter_goal_snapshot()
	if not bool(snapshot.get("active", false)) or String(snapshot.get("title", "")) != "第一章：重启杂货店":
		return await _fail_with_restore("Expected chapter 1 goal to be the first shop tutorial.", game_state, original_profile)
	if game_state.can_unlock_manufacturing_station():
		return await _fail_with_restore("Expected manufacturing currency unlock to be deprecated.", game_state, original_profile)
	if _count_items(game_state, "sale_good_repaired_filter") + _count_items(game_state, "sale_good_emergency_wrap") + _count_items(game_state, "sale_good_signal_lamp") != 0:
		return await _fail_with_restore("Expected starter supply to grant materials, not sale_good items.", game_state, original_profile)

	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	current_scene = base
	await process_frame
	var crafting_tab := base.get_node_or_null("BaseUIRoot/CraftingTabButton") as Button
	if crafting_tab == null or crafting_tab.disabled or not crafting_tab.visible:
		return await _fail_with_restore("Expected manufacturing tab to be visible after first return.", game_state, original_profile)
	crafting_tab.emit_signal("pressed")
	await process_frame
	var crafting_panel := base.get_node_or_null("BaseUIRoot/CraftingPanel") as Panel
	var crafting_unlock := base.get_node_or_null("BaseUIRoot/CraftingPanel/CraftingUnlockButton") as Button
	var chapter_label := base.get_node_or_null("BaseUIRoot/ChapterGoalLabel") as Label
	if crafting_panel == null or not crafting_panel.visible or crafting_unlock == null or crafting_unlock.visible:
		return await _fail_with_restore("Expected manufacturing panel without old unlock button.", game_state, original_profile)
	if chapter_label == null or not chapter_label.text.contains("重启杂货店") or chapter_label.text.contains("100") or chapter_label.text.contains("解锁制造所"):
		return await _fail_with_restore("Expected chapter HUD to show first-shop goals without old fixed currency objective.", game_state, original_profile)
	base.queue_free()
	current_scene = null
	await process_frame

	var craft_result: Dictionary = game_state.craft_recipe("recipe_repaired_filter")
	if not bool(craft_result.get("ok", false)) or not bool(game_state.first_sale_good_crafted):
		return await _fail_with_restore("Expected starter materials to craft first sale_good: %s" % craft_result, game_state, original_profile)
	var open_result: Dictionary = game_state.start_shop_open()
	if not bool(open_result.get("ok", false)) or game_state.get_outgame_phase() != "SHOP_OPEN":
		return await _fail_with_restore("Expected formal day prep to open shop.", game_state, original_profile)
	var sale_group := _find_group(game_state.query_shelfable_sale_goods(), "sale_good_repaired_filter")
	if sale_group.is_empty():
		return await _fail_with_restore("Expected crafted sale_good to be shelfable.", game_state, original_profile)
	var shelf_result: Dictionary = game_state.move_sale_good_to_shelf(String(sale_group.get("shelf_group_id", "")), 0)
	if not bool(shelf_result.get("ok", false)) or not bool(game_state.first_sale_good_shelved):
		return await _fail_with_restore("Expected shelving sale_good to advance chapter step 2: %s" % shelf_result, game_state, original_profile)
	game_state.finish_shop_open("manual")
	var close_result: Dictionary = game_state.close_shop_settlement_to_night()
	if not bool(close_result.get("ok", false)):
		return await _fail_with_restore("Expected first shop settlement to close: %s" % close_result, game_state, original_profile)
	if not bool(game_state.first_shop_settlement_completed) or not bool(game_state.first_shop_tutorial_completed) or not bool(game_state.chapter_1_completed):
		return await _fail_with_restore("Expected first shop settlement to complete chapter 1 tutorial.", game_state, original_profile)

	_restore_profile(game_state, original_profile)
	return true

func _verify_main_menu_profile_ui(game_state: Node, original_profile: Dictionary) -> bool:
	var menu = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	var username_overlay := menu.get_node_or_null("UsernameOverlay") as Control
	var username_panel := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel") as Panel
	var username_edit := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameEdit") as LineEdit
	var username_confirm_button := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameConfirmButton") as Panel
	if username_overlay == null or username_panel == null or username_edit == null or username_confirm_button == null:
		menu.queue_free()
		return await _fail_with_restore("Expected MainMenuScene to instantiate with username whitebox profile UI.", game_state, original_profile)
	if username_edit.size != Vector2(252, 36):
		menu.queue_free()
		return await _fail_with_restore("Expected username input to use the narrowed whitebox size.", game_state, original_profile)
	menu.queue_free()
	await process_frame
	return true

func _verify_loading_waits_for_input(game_state: Node, original_profile: Dictionary) -> bool:
	var loading = LOADING_SCENE.instantiate()
	root.add_child(loading)
	var loading_state := {"done": false, "failed": ""}
	loading.loading_completed.connect(func(_run_scene): loading_state["done"] = true)
	loading.loading_failed.connect(func(reason): loading_state["failed"] = String(reason))
	loading.begin_loading()
	for _index in range(160):
		if loading.is_ready_to_continue():
			break
		await process_frame
		await physics_frame
	if bool(loading_state.get("done", false)):
		if is_instance_valid(loading):
			loading.queue_free()
		return await _fail_with_restore("Expected run loading to wait for player input at 100%.", game_state, original_profile)
	if not loading.is_ready_to_continue():
		if is_instance_valid(loading):
			loading.queue_free()
		return await _fail_with_restore("Expected run loading screen to reach ready-to-continue state. Failure: %s" % String(loading_state.get("failed", "")), game_state, original_profile)
	if not loading.continue_label.visible or loading.continue_label.text != "按下任意按钮继续":
		if is_instance_valid(loading):
			loading.queue_free()
		return await _fail_with_restore("Expected loading continue prompt to appear once below the progress bar.", game_state, original_profile)
	loading._input(_key(KEY_SPACE))
	await process_frame
	if not bool(loading_state.get("done", false)):
		if is_instance_valid(loading):
			loading.queue_free()
		return await _fail_with_restore("Expected run loading screen to complete after continue input. Failure: %s" % String(loading_state.get("failed", "")), game_state, original_profile)
	if is_instance_valid(loading):
		loading.queue_free()
	return true

func _find_group(groups: Array, item_id: String) -> Dictionary:
	for group in groups:
		if group is Dictionary and String(group.get("item_id", "")) == item_id:
			return group
	return {}

func _count_items(game_state: Node, item_id: String) -> int:
	var count := 0
	for item in game_state.get_warehouse_items_snapshot():
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			count += int(item.get("amount", 1))
	return count

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _fail_with_restore(message: String, game_state: Node, original_profile: Dictionary) -> bool:
	printerr(message)
	_restore_profile(game_state, original_profile)
	await process_frame
	return false

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

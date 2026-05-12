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
	game_state.delete_profile_debug_only()
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_day(0)
	game_state.reset_story_flags()

	var create_result: Dictionary = game_state.create_profile("测试员_01")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false
	if not game_state.has_profile() or game_state.username != "测试员_01":
		printerr("Expected created profile to be loaded into GameState.")
		_restore_profile(game_state, original_profile)
		return false
	var reloaded_profile: Dictionary = game_state.load_profile()
	if String(reloaded_profile.get("username", "")) != "测试员_01":
		printerr("Expected saved profile to reload username.")
		_restore_profile(game_state, original_profile)
		return false
	if not game_state.should_play_intro_cinematic() or not game_state.should_play_world_intro_dialogue():
		printerr("Expected new profile to require opening cinematic and world intro dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	if not game_state.should_play_first_departure_outpost_dialogue():
		printerr("Expected new profile to require first departure outpost dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	if game_state.should_play_intro_cinematic() or game_state.should_play_world_intro_dialogue():
		printerr("Expected opening cinematic and world intro flags to persist in runtime.")
		_restore_profile(game_state, original_profile)
		return false

	var menu = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	var username_overlay := menu.get_node_or_null("UsernameOverlay") as Control
	var username_panel := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel") as Panel
	var username_edit := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameEdit") as LineEdit
	var username_confirm_button := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameConfirmButton") as Panel
	if username_overlay == null or username_panel == null or username_edit == null or username_confirm_button == null:
		printerr("Expected MainMenuScene to instantiate with username whitebox profile UI.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if username_edit.size != Vector2(252, 36):
		printerr("Expected username input to use the narrowed whitebox size.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	menu.queue_free()
	await process_frame

	var day_before: int = int(game_state.get_current_day())
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
		printerr("Expected run loading to wait for player input at 100%.")
		if is_instance_valid(loading):
			loading.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if not loading.is_ready_to_continue():
		printerr("Expected run loading screen to reach ready-to-continue state. Failure: %s" % String(loading_state.get("failed", "")))
		if is_instance_valid(loading):
			loading.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if loading.stage_label.text != "地面部署完成":
		printerr("Expected loading stage label to show deployment completion, got '%s'." % loading.stage_label.text)
		if is_instance_valid(loading):
			loading.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if not loading.continue_label.visible or loading.continue_label.text != "按下任意按钮继续":
		printerr("Expected loading continue prompt to appear once below the progress bar.")
		if is_instance_valid(loading):
			loading.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	loading._input(_key(KEY_SPACE))
	await process_frame
	if not bool(loading_state.get("done", false)):
		printerr("Expected run loading screen to complete after continue input. Failure: %s" % String(loading_state.get("failed", "")))
		if is_instance_valid(loading):
			loading.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var commit_result: Dictionary = game_state.commit_run_start(false)
	if not bool(commit_result.get("ok", false)) or game_state.get_current_day() != day_before + 1:
		printerr("Expected successful loading commit to advance surface_day once.")
		_restore_profile(game_state, original_profile)
		return false

	game_state.apply_run_result({
		"result_type": "EXTRACTED",
		"message": "撤离成功",
		"warehouse_items": [],
	})
	if not game_state.should_play_first_return_dialogue():
		printerr("Expected first extracted run to queue return dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	var snapshot: Dictionary = game_state.get_chapter_goal_snapshot()
	if not bool(snapshot.get("active", false)):
		printerr("Expected first return dialogue to activate chapter 1 goal.")
		_restore_profile(game_state, original_profile)
		return false

	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	await process_frame
	var crafting_tab := base.get_node_or_null("BaseUIRoot/CraftingTabButton") as Button
	if crafting_tab == null or crafting_tab.disabled or crafting_tab.text != "制造所":
		printerr("Expected manufacturing tab to be visible and clickable.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	crafting_tab.emit_signal("pressed")
	await process_frame
	var crafting_panel := base.get_node_or_null("BaseUIRoot/CraftingPanel") as Panel
	var crafting_status := base.get_node_or_null("BaseUIRoot/CraftingPanel/CraftingStatusLabel") as Label
	var crafting_unlock := base.get_node_or_null("BaseUIRoot/CraftingPanel/CraftingUnlockButton") as Button
	if crafting_panel == null or not crafting_panel.visible or crafting_status == null or crafting_unlock == null:
		printerr("Expected active chapter 1 to open manufacturing objective panel.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if crafting_unlock.text != "购买制造机" or not crafting_status.text.contains("攒够 5000 矿币") or not crafting_status.text.contains("妹妹还有救"):
		printerr("Expected manufacturing objective copy to explain the old machine, 5000 mine_coin, and sister stakes.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if game_state.can_unlock_manufacturing_station():
		printerr("Expected manufacturing unlock to require 5000 mine_coin.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	game_state.add_currency("mine_coin", 4999, "test")
	if game_state.can_unlock_manufacturing_station():
		printerr("Expected 4999 mine_coin to be insufficient.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	game_state.add_currency("mine_coin", 1, "test")
	var unlock_result: Dictionary = game_state.unlock_manufacturing_station()
	if not bool(unlock_result.get("ok", false)):
		printerr("Expected 5000 mine_coin to unlock manufacturing: %s" % unlock_result)
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if game_state.get_currency_amount("mine_coin") != 0 or not game_state.manufacturing_station_unlocked or not game_state.chapter_1_completed:
		printerr("Expected unlock to spend currency and complete chapter 1.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	base.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true

func _has_child_of_type(node: Node, type_name: String) -> bool:
	for child in node.get_children():
		if child.get_class() == type_name or child.is_class(type_name):
			return true
	return false

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.delete_profile_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

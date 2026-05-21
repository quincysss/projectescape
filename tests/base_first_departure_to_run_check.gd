extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify_prologue_departure_dialogue_then_loading()
	ok = await _verify_early_finish_settlement_then_departure_loading() and ok
	ok = await _verify_timer_finish_settlement_then_departure_loading() and ok
	ok = await _verify_reopen_from_departure_middle_state_restores_ui() and ok
	await _shutdown_audio()
	print("Base first departure and shop settlement departure flow verified." if ok else "Base first departure flow failed.")
	quit(0 if ok else 1)

func _verify_prologue_departure_dialogue_then_loading() -> bool:
	var setup := await _prepare_base("FlowPrologue", false)
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")

	base._request_start_run()
	await process_frame
	var dialogue := _first_dialogue_panel(base)
	if dialogue == null:
		return await _fail_with_restore("Expected first prologue departure click to open mission dialogue.", game_state, original_profile)
	if bool(game_state.first_departure_outpost_dialogue_seen):
		return await _fail_with_restore("Expected first departure flag to wait for dialogue completion.", game_state, original_profile)
	dialogue.emit_signal("dialogue_finished", "first_departure_outpost_dialogue", false)
	await process_frame
	if not bool(game_state.first_departure_outpost_dialogue_seen):
		return await _fail_with_restore("Expected dialogue completion to mark first departure as seen.", game_state, original_profile)
	return await _verify_loading_started_and_enter_run(base, game_state, original_profile)

func _verify_early_finish_settlement_then_departure_loading() -> bool:
	var setup := await _prepare_base("FlowEarly", true)
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")

	base._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		return await _fail_with_restore("Expected day-prep start button to open shop.", game_state, original_profile)
	var finish_button := _find_button_by_text(base, "提前结束营业")
	if finish_button == null:
		return await _fail_with_restore("Expected early-finish shop button.", game_state, original_profile)
	finish_button.emit_signal("pressed")
	await process_frame
	if _first_loading_screen(base) != null:
		return await _fail_with_restore("Expected early-finish shop button to wait on settlement before loading.", game_state, original_profile)
	if game_state.get_outgame_phase() != "SHOP_SETTLEMENT":
		return await _fail_with_restore("Expected early-finish shop button to show settlement.", game_state, original_profile)
	if _find_label_containing(base, "总收入") == null:
		return await _fail_with_restore("Expected early-finish settlement to show total income summary.", game_state, original_profile)
	var depart_button := _find_button_by_text(base, "出发")
	if depart_button == null:
		return await _fail_with_restore("Expected settlement panel to provide departure button.", game_state, original_profile)
	depart_button.emit_signal("pressed")
	await process_frame
	if _first_loading_screen(base) == null:
		return await _fail_with_restore("Expected settlement departure button to load the next run.", game_state, original_profile)
	return await _verify_loading_started_and_enter_run(base, game_state, original_profile)

func _verify_timer_finish_settlement_then_departure_loading() -> bool:
	var setup := await _prepare_base("FlowTimer", true)
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")

	base._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		return await _fail_with_restore("Expected day-prep start button to open shop.", game_state, original_profile)
	game_state.advance_shop_open(999.0)
	base._refresh()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_SETTLEMENT":
		return await _fail_with_restore("Expected timer finish to show settlement panel.", game_state, original_profile)
	if _first_loading_screen(base) != null:
		return await _fail_with_restore("Expected timer finish to wait on settlement before loading.", game_state, original_profile)
	if _find_label_containing(base, "总收入") == null:
		return await _fail_with_restore("Expected timer-finish settlement to show total income summary.", game_state, original_profile)
	var settle_button := _find_button_by_text(base, "出发")
	if settle_button == null:
		return await _fail_with_restore("Expected timer-finish settlement departure button.", game_state, original_profile)
	settle_button.emit_signal("pressed")
	await process_frame
	if _first_loading_screen(base) == null:
		return await _fail_with_restore("Expected timer-finish settlement departure button to load the next run.", game_state, original_profile)
	return await _verify_loading_started_and_enter_run(base, game_state, original_profile)

func _verify_reopen_from_departure_middle_state_restores_ui() -> bool:
	var setup := await _prepare_base("FlowResume", true)
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")
	base.queue_free()
	current_scene = null
	await process_frame

	game_state.set_outgame_phase("LOADOUT")
	game_state.load_profile()
	if game_state.get_outgame_phase() != "NIGHT":
		return await _fail_with_restore("Expected reopened loadout saves to return to the night departure gate.", game_state, original_profile)

	var commit_result: Dictionary = game_state.commit_run_start(false)
	if not bool(commit_result.get("ok", false)) or game_state.get_outgame_phase() != "LOADING_TO_RUN":
		return await _fail_with_restore("Expected run start to save the loading phase before simulating reopen.", game_state, original_profile)
	game_state.load_profile()
	if game_state.get_outgame_phase() != "NIGHT":
		return await _fail_with_restore("Expected reopened loading saves to return to the night departure gate.", game_state, original_profile)

	var reopened_base = BASE_SCENE.instantiate()
	root.add_child(reopened_base)
	current_scene = reopened_base
	await process_frame
	var start_button := reopened_base.get_node_or_null("BaseUIRoot/StartRunButton") as Button
	if start_button == null or not start_button.visible or start_button.disabled or start_button.text != "出击":
		return await _fail_with_restore("Expected reopened base to show the departure button after recovering loading state.", game_state, original_profile)
	_restore_profile(game_state, original_profile)
	return true

func _prepare_base(profile_name: String, unlock_shop_loop: bool) -> Dictionary:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return {"ok": false}
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile(profile_name)
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return {"ok": false}
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	if unlock_shop_loop:
		game_state.mark_first_departure_outpost_dialogue_seen()
		game_state.pending_first_return_dialogue = true
		var return_result: Dictionary = game_state.mark_first_return_dialogue_seen_and_activate_chapter()
		if not bool(return_result.get("ok", false)):
			printerr("Expected first return setup to unlock shop loop: %s" % return_result)
			_restore_profile(game_state, original_profile)
			return {"ok": false}

	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	current_scene = base
	await process_frame
	return {
		"ok": true,
		"game_state": game_state,
		"original_profile": original_profile,
		"base": base,
	}

func _verify_loading_started_and_enter_run(base: Node, game_state: Node, original_profile: Dictionary) -> bool:
	var loading := _first_loading_screen(base)
	if loading == null:
		return await _fail_with_restore("Expected loading screen after first departure dialogue.", game_state, original_profile)
	for _index in range(220):
		if loading.is_ready_to_continue():
			break
		await process_frame
		await physics_frame
	if not is_instance_valid(loading) or not loading.is_ready_to_continue():
		return await _fail_with_restore("Expected loading to wait for continue input.", game_state, original_profile)

	loading._input(_key(KEY_SPACE))
	for _index in range(6):
		await process_frame
	if current_scene == null or current_scene.name != "RunScene":
		return await _fail_with_restore("Expected continue input to enter RunScene, got '%s'." % (current_scene.name if current_scene != null else "null"), game_state, original_profile)

	_restore_profile(game_state, original_profile)
	return true

func _find_button_by_text(node: Node, text: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button.text == text:
			return button
	return null

func _find_label_containing(node: Node, text: String) -> Label:
	for child in node.find_children("*", "Label", true, false):
		var label := child as Label
		if label != null and label.text.contains(text):
			return label
	return null

func _first_dialogue_panel(node: Node) -> DialoguePanel:
	for child in node.get_children():
		if child is DialoguePanel:
			return child
	return null

func _first_loading_screen(node: Node) -> RunLoadingScreen:
	for child in node.get_children():
		if child is RunLoadingScreen:
			return child
	return null

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

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

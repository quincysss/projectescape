extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify_early_finish_direct_departure()
	ok = await _verify_settlement_direct_departure() and ok
	await _shutdown_audio()
	print("Base direct shop departure verified." if ok else "Base direct shop departure failed.")
	quit(0 if ok else 1)

func _verify_early_finish_direct_departure() -> bool:
	var setup := await _prepare_base("FlowFast")
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")

	base._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		return await _fail_with_restore("Expected day-prep start button to open shop.", game_state, original_profile)
	var finish_button := _find_button_by_text(base, "提前结束并出击")
	if finish_button == null:
		return await _fail_with_restore("Expected early-finish direct departure button.", game_state, original_profile)
	finish_button.emit_signal("pressed")
	await process_frame
	return await _verify_loading_started_and_enter_run(base, game_state, original_profile)

func _verify_settlement_direct_departure() -> bool:
	var setup := await _prepare_base("FlowSettle")
	if not bool(setup.get("ok", false)):
		return false
	var game_state: Node = setup.get("game_state")
	var original_profile: Dictionary = setup.get("original_profile", {})
	var base: Node = setup.get("base")

	base._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		return await _fail_with_restore("Expected shop to open before settlement setup.", game_state, original_profile)
	game_state.finish_shop_open("manual")
	base._refresh()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_SETTLEMENT":
		return await _fail_with_restore("Expected manual finish to show settlement panel.", game_state, original_profile)
	var settle_button := _find_button_by_text(base, "收款并出击")
	if settle_button == null:
		return await _fail_with_restore("Expected settlement direct departure button.", game_state, original_profile)
	settle_button.emit_signal("pressed")
	await process_frame
	return await _verify_loading_started_and_enter_run(base, game_state, original_profile)

func _prepare_base(profile_name: String) -> Dictionary:
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
	if game_state.get_outgame_phase() != "NIGHT":
		return await _fail_with_restore("Expected direct departure to settle shop and leave phase at NIGHT until loading commits.", game_state, original_profile)
	if not bool(game_state.first_departure_outpost_dialogue_seen):
		return await _fail_with_restore("Expected direct departure to skip and mark first departure story as seen.", game_state, original_profile)
	if _first_dialogue_panel(base) != null:
		return await _fail_with_restore("Expected direct departure to skip first departure dialogue.", game_state, original_profile)
	var loading := _first_loading_screen(base)
	if loading == null:
		return await _fail_with_restore("Expected loading screen after direct shop departure.", game_state, original_profile)
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

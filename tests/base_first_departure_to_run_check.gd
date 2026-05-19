extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	await _shutdown_audio()
	print("Base first departure to run verified." if ok else "Base first departure to run failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("FlowTester")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()

	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	current_scene = base
	await process_frame

	base._request_start_run()
	await process_frame
	var panel := _first_dialogue_panel(base)
	if panel == null or panel.dialogue_id != "first_departure_outpost_dialogue":
		printerr("Expected first departure dialogue before loading.")
		_restore_profile(game_state, original_profile)
		return false
	panel._finish(false)
	await process_frame
	if not bool(game_state.first_departure_outpost_dialogue_seen):
		printerr("Expected first departure dialogue to be marked seen.")
		_restore_profile(game_state, original_profile)
		return false

	var loading := _first_loading_screen(base)
	if loading == null:
		printerr("Expected loading screen after first departure dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	for _index in range(220):
		if loading.is_ready_to_continue():
			break
		await process_frame
		await physics_frame
	if not is_instance_valid(loading) or not loading.is_ready_to_continue():
		printerr("Expected loading to wait for continue input.")
		_restore_profile(game_state, original_profile)
		return false

	loading._input(_key(KEY_SPACE))
	for _index in range(6):
		await process_frame
	if current_scene == null or current_scene.name != "RunScene":
		printerr("Expected continue input to enter RunScene, got '%s'." % (current_scene.name if current_scene != null else "null"))
		_restore_profile(game_state, original_profile)
		return false

	_restore_profile(game_state, original_profile)
	return true

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

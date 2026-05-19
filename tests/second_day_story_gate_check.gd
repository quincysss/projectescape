extends SceneTree

const RUN_SCENE := preload("res://scenes/run/RunScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	await _shutdown_audio()
	print("Second day story gate verified." if ok else "Second day story gate failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("Day2Tester")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false
	game_state.reset_day(2)
	game_state.second_day_black_tide_reveal_seen = false
	game_state.save_profile()

	var run_scene = RUN_SCENE.instantiate()
	root.add_child(run_scene)
	current_scene = run_scene
	await process_frame
	if not run_scene.is_run_story_paused():
		printerr("Expected second day run to acquire story pause immediately.")
		_restore_profile(game_state, original_profile)
		return false
	if run_scene.run_director.context == null or int(run_scene.run_director.context.run_day_index) != 2:
		printerr("Expected run context day index to be 2.")
		_restore_profile(game_state, original_profile)
		return false
	var remaining_before := float(run_scene.run_director.context.remaining_seconds)
	for _index in range(5):
		await process_frame
		await physics_frame
	if absf(float(run_scene.run_director.context.remaining_seconds) - remaining_before) > 0.001:
		printerr("Expected run countdown to stay frozen during the second day cinematic gate.")
		_restore_profile(game_state, original_profile)
		return false

	for _index in range(20):
		if is_instance_valid(run_scene._story_video_overlay):
			break
		await process_frame
	if not is_instance_valid(run_scene._story_video_overlay):
		printerr("Expected second day cinematic overlay to appear before dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	var audio_manager := root.get_node_or_null("AudioManager")
	var video_loaded := is_instance_valid(run_scene._story_video_player)
	if video_loaded and not _is_bgm_paused(audio_manager):
		printerr("Expected run BGM to pause while the second day cinematic video is playing.")
		_restore_profile(game_state, original_profile)
		return false
	run_scene._finish_second_day_black_tide_cinematic(true)
	await process_frame
	if video_loaded and _is_bgm_paused(audio_manager):
		printerr("Expected run BGM to resume after the second day cinematic video finishes.")
		_restore_profile(game_state, original_profile)
		return false

	for _index in range(20):
		if is_instance_valid(run_scene._active_story_dialogue_panel):
			break
		await process_frame
	var panel = run_scene._active_story_dialogue_panel
	if not is_instance_valid(panel) or panel.dialogue_id != "second_day_black_tide_reveal_dialogue":
		printerr("Expected second day reveal dialogue after skipping cinematic.")
		_restore_profile(game_state, original_profile)
		return false
	for _index in range(12):
		if not is_instance_valid(panel):
			break
		panel._input(_key(KEY_SPACE))
		await process_frame
	for _index in range(20):
		if not run_scene.is_run_story_paused():
			break
		await process_frame
	if run_scene.is_run_story_paused():
		printerr("Expected second day story pause to release after dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	if not bool(game_state.second_day_black_tide_reveal_seen):
		printerr("Expected second day reveal flag to be saved after dialogue.")
		_restore_profile(game_state, original_profile)
		return false
	_restore_profile(game_state, original_profile)
	return true

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _is_bgm_paused(audio_manager: Node) -> bool:
	if audio_manager == null:
		return false
	var player = audio_manager.get("bgm_player")
	if player == null or not is_instance_valid(player):
		return false
	return bool(player.stream_paused)

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

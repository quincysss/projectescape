extends SceneTree

const MainMenuScene := preload("res://scenes/ui/MainMenuScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Main menu opening flow verified." if ok else "Main menu opening flow failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()

	var menu = MainMenuScene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame

	menu._on_start_pressed()
	await process_frame
	var username_edit := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameEdit") as LineEdit
	if username_edit == null:
		printerr("Expected username input to exist.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	username_edit.text = "FlowTester"
	menu._on_username_confirmed()
	await process_frame

	var opening := menu.get_node_or_null("OpeningCinematicOverlay") as Control
	if opening == null or not bool(game_state.should_play_world_intro_dialogue()):
		printerr("Expected new profile to show skippable opening cinematic before world intro.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var menu_content := menu.get_node_or_null("MainMenuContent") as Control
	var menu_dim := menu.get_node_or_null("MainMenuBackgroundDim") as ColorRect
	var version_label := menu.get_node_or_null("VersionLabel") as Label
	var background_video := menu.get_node_or_null("MainMenuBackgroundVideo") as VideoStreamPlayer
	if (
		menu_content == null
		or menu_content.visible
		or menu_dim == null
		or menu_dim.visible
		or version_label == null
		or version_label.visible
		or background_video == null
		or background_video.visible
	):
		printerr("Expected main menu UI and background loop to be hidden while the opening cinematic is playing.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var video_player := opening.get_node_or_null("OpeningCinematicVideoPlayer") as VideoStreamPlayer
	if video_player == null or video_player.stream == null:
		printerr("Expected opening cinematic video player to load the configured video stream.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager == null or audio_manager.bgm_player == null or not audio_manager.bgm_player.stream_paused:
		printerr("Expected BGM to pause while the opening cinematic is playing.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var cinematic_frame := opening.get_node_or_null("OpeningCinematicPlaceholder16x9") as ColorRect
	if cinematic_frame == null or cinematic_frame.anchor_right != 1.0 or cinematic_frame.anchor_bottom != 1.0:
		printerr("Expected opening cinematic placeholder to fill the full screen.")
		menu.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	menu._finish_intro_cinematic(true)
	await _wait_process_frames(4)
	if not bool(game_state.intro_cinematic_seen):
		printerr("Expected skipping opening cinematic to mark intro_cinematic_seen.")
		_restore_profile(game_state, original_profile)
		return false
	if bool(game_state.world_intro_dialogue_seen):
		printerr("Expected world intro dialogue to remain pending until BaseScene plays it.")
		_restore_profile(game_state, original_profile)
		return false
	if audio_manager.bgm_player != null and audio_manager.bgm_player.stream_paused:
		printerr("Expected BGM to resume after the opening cinematic ends or is skipped.")
		_restore_profile(game_state, original_profile)
		return false

	var base_scene := current_scene
	if base_scene == null or base_scene.name != "BaseScene":
		printerr("Expected opening cinematic to enter BaseScene before world intro dialogue.")
		_restore_profile(game_state, original_profile)
		return false

	var panel := _first_dialogue_panel(base_scene)
	if panel == null or panel.dialogue_id != "world_intro_dialogue":
		printerr("Expected BaseScene to play world_intro_dialogue over the warehouse UI.")
		_restore_profile(game_state, original_profile)
		return false
	panel._finish(false)
	await _wait_process_frames(2)
	if not bool(game_state.world_intro_dialogue_seen):
		printerr("Expected finishing world intro dialogue to mark world_intro_dialogue_seen.")
		_restore_profile(game_state, original_profile)
		return false

	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame
	_restore_profile(game_state, original_profile)
	return true

func _first_dialogue_panel(node: Node) -> DialoguePanel:
	for child in node.get_children():
		if child is DialoguePanel:
			return child
	return null

func _wait_process_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

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

extends SceneTree

const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")

func _initialize() -> void:
	var manager = root.get_node_or_null("AudioManager")
	var created_manager := false
	if manager == null:
		manager = AudioManagerScript.new()
		root.add_child(manager)
		created_manager = true
	await process_frame

	var ok := _verify_autoload_path()
	if ok:
		ok = _verify_manifest_paths(manager)
	if ok:
		ok = _verify_bgm_loop_contract(manager)
	if ok:
		ok = _verify_bgm_assets_play(manager)
	if ok:
		ok = _verify_sfx_assets_play(manager)

	await manager.shutdown_and_flush()
	if created_manager:
		manager.queue_free()
		await process_frame
	print("Audio framework verified." if ok else "Audio framework failed.")
	quit(0 if ok else 1)

func _verify_autoload_path() -> bool:
	var autoload_path := String(ProjectSettings.get_setting("autoload/AudioManager", ""))
	if autoload_path != "*res://scripts/audio/audio_manager.gd":
		printerr("Expected AudioManager autoload, got '%s'." % autoload_path)
		return false
	return true

func _verify_manifest_paths(manager) -> bool:
	if not manager.reload_manifest():
		printerr("Expected audio manifest to load.")
		return false
	var expected := [
		"res://assets/audio/bgm/base_safe_house_bgm.wav",
		"res://assets/audio/bgm/run_safe_house_bgm.wav",
		"res://assets/audio/bgm/run_exploration_bgm.wav",
		"res://assets/audio/sfx/stability_critical_loop.wav",
		"res://assets/audio/sfx/container_open_loop.wav",
		"res://assets/audio/sfx/container_open_complete.wav",
		"res://assets/audio/sfx/outpost_repair_complete.wav",
		"res://assets/audio/sfx/cue_extraction_success.wav",
		"res://assets/audio/sfx/cue_player_death.wav",
		"res://assets/audio/sfx/ui_button_click.wav",
		"res://assets/audio/sfx/ui_item_click.wav",
	]
	var actual: PackedStringArray = manager.get_expected_audio_paths()
	for path in expected:
		if not actual.has(path):
			printerr("Expected manifest path '%s'." % path)
			return false
	return true

func _verify_bgm_loop_contract(manager) -> bool:
	if manager.bgm_player == null:
		printerr("Expected BGM player to exist.")
		return false
	if manager.bgm_player.bus != "Master":
		printerr("Expected BGM to route to Master bus, got '%s'." % manager.bgm_player.bus)
		return false
	if not manager.bgm_player.finished.is_connected(manager._on_bgm_finished):
		printerr("Expected BGM finished signal to be connected for looping.")
		return false
	manager._current_bgm_id = manager.BGM_BASE_SAFE_HOUSE
	if not manager._should_loop_current_bgm():
		printerr("Expected base safe house BGM to be loop-enabled by manifest.")
		return false
	manager._current_bgm_id = manager.BGM_RUN_SAFE_HOUSE
	if not manager._should_loop_current_bgm():
		printerr("Expected run safe house BGM to be loop-enabled by manifest.")
		return false
	manager._current_bgm_id = manager.BGM_RUN_EXPLORATION
	if not manager._should_loop_current_bgm():
		printerr("Expected run exploration BGM to be loop-enabled by manifest.")
		return false
	manager._current_bgm_id = ""
	return true

func _verify_bgm_assets_play(manager) -> bool:
	if not manager.play_base_safe_house_bgm():
		printerr("Expected base safe house BGM to load and play.")
		return false
	if manager.bgm_player.stream == null:
		printerr("Expected base safe house BGM stream.")
		return false
	if manager.bgm_player.stream.get_length() <= 0.0:
		printerr("Expected base safe house BGM stream to have length.")
		return false
	if not manager.play_run_safe_house_bgm():
		printerr("Expected run safe house BGM to load and play.")
		return false
	if manager.bgm_player.stream == null:
		printerr("Expected run safe house BGM stream.")
		return false
	if manager.bgm_player.stream.get_length() <= 0.0:
		printerr("Expected run safe house BGM stream to have length.")
		return false
	if not manager.play_run_exploration_bgm():
		printerr("Expected run exploration BGM to load and play.")
		return false
	if manager.bgm_player.stream == null:
		printerr("Expected run exploration BGM stream.")
		return false
	if manager.bgm_player.stream.get_length() <= 0.0:
		printerr("Expected run exploration BGM stream to have length.")
		return false
	return true

func _verify_sfx_assets_play(manager) -> bool:
	manager.start_container_open_loop()
	manager.stop_container_open_loop()
	manager.play_container_open_complete()
	manager.play_outpost_repair_complete()
	manager.set_stability_critical_loop_active(true)
	manager.set_stability_critical_loop_active(false)
	manager.play_extraction_success_cue()
	manager.play_player_death_cue()
	manager.play_ui_button_click()
	manager.play_ui_item_click()
	manager.stop_all_loops()
	return true

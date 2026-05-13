extends SceneTree

const RUN_SCENE := preload("res://scenes/run/RunScene.tscn")


func _initialize() -> void:
	var ok := await _verify_stability_depletion_opens_settlement()
	print("Stability depletion settlement verified." if ok else "Stability depletion settlement failed.")
	quit(0 if ok else 1)


func _verify_stability_depletion_opens_settlement() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_day(1)

	var run_root = RUN_SCENE.instantiate()
	root.add_child(run_root)
	await process_frame
	await process_frame

	if run_root.run_director == null or run_root.run_director.stability_component == null:
		return await _fail_with_restore("Run stability component missing.", game_state, original_profile, run_root)

	run_root.run_director.on_safe_zone_exited("home")
	run_root.run_director.on_camera_transition_finished()
	run_root.run_director.stability_component.set_stability(0.0)
	await process_frame
	await process_frame

	var state: Dictionary = run_root.run_director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "FAILED" or state.get("run_result") != "DEAD":
		return await _fail_with_restore("Expected DEAD failed state after stability depletion.", game_state, original_profile, run_root)
	if run_root.settlement_result_screen == null or not is_instance_valid(run_root.settlement_result_screen):
		return await _fail_with_restore("Expected stability depletion to open settlement screen.", game_state, original_profile, run_root)
	if run_root.settlement_result_screen.title_label.text != "你已被黑潮吞噬，将在404重塑躯体。":
		return await _fail_with_restore("Expected failure settlement title after stability depletion.", game_state, original_profile, run_root)

	run_root.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true


func _fail_with_restore(message: String, game_state: Node, original_profile: Dictionary, run_root = null) -> bool:
	printerr(message)
	if run_root != null and is_instance_valid(run_root):
		run_root.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return false


func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

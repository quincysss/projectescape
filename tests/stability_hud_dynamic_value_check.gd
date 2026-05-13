extends SceneTree

const RUN_SCENE := preload("res://scenes/run/RunScene.tscn")


func _initialize() -> void:
	var ok := await _verify_stability_hud_dynamic_value()
	print("Stability HUD dynamic value verified." if ok else "Stability HUD dynamic value failed.")
	quit(0 if ok else 1)


func _verify_stability_hud_dynamic_value() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_research()
	game_state.research_levels["max_stability"] = 1

	var run_root = RUN_SCENE.instantiate()
	root.add_child(run_root)
	await process_frame
	await process_frame

	var stability_bar := run_root.get_node_or_null("RunUIRoot/CharacterStatusHUD/StabilityPanel/StabilityBar") as Control
	if stability_bar == null:
		return await _fail_with_restore("Expected StabilityBar.", game_state, original_profile, run_root)
	if stability_bar.find_child("StabilityLabelMask", true, false) != null:
		return await _fail_with_restore("Expected stability tick label mask to be removed.", game_state, original_profile, run_root)
	if stability_bar.find_child("CorrectedTick_0", true, false) != null:
		return await _fail_with_restore("Expected fixed stability tick labels to be removed.", game_state, original_profile, run_root)

	var value_label := stability_bar.get_node_or_null("StabilityValue") as Label
	if value_label == null:
		return await _fail_with_restore("Expected StabilityValue label on stability bar.", game_state, original_profile, run_root)
	if not value_label.visible:
		return await _fail_with_restore("Expected StabilityValue label to be visible.", game_state, original_profile, run_root)
	if value_label.text != "120/120":
		return await _fail_with_restore("Expected researched stability HUD value 120/120, got %s." % value_label.text, game_state, original_profile, run_root)

	run_root.run_director.stability_component.set_stability(73.0)
	run_root._refresh_ui()
	await process_frame
	if value_label.text != "73/120":
		return await _fail_with_restore("Expected current stability HUD value 73/120, got %s." % value_label.text, game_state, original_profile, run_root)

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

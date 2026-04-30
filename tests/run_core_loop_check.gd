extends SceneTree

func _initialize() -> void:
	if not _verify_scene_loads():
		quit(1)
		return

	var scene := load("res://scenes/debug/DebugCoreLoop.tscn")
	if scene == null:
		printerr("Failed to load DebugCoreLoop.tscn")
		quit(1)
		return

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var director = root.get_node("RunDirector")
	var ok: bool = await _verify_run_scene_points()
	if ok:
		ok = _verify_invalid_extraction_guard(director)
	if ok:
		ok = _verify_success_path(director)
	if ok:
		ok = _verify_death_path(director)

	root.queue_free()
	await process_frame
	quit(0 if ok else 1)

func _verify_scene_loads() -> bool:
	var scene_paths := [
		"res://scenes/boot/BootScene.tscn",
		"res://scenes/base/BaseScene.tscn",
		"res://scenes/run/RunScene.tscn",
		"res://scenes/debug/DebugCoreLoop.tscn",
	]
	for scene_path in scene_paths:
		var scene = load(scene_path)
		if scene == null:
			printerr("Failed to load %s" % scene_path)
			return false
	print("Scene load check verified.")
	return true

func _verify_run_scene_points() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var director = root.get_node("RunDirector")
	if not director.start_new_run():
		printerr("RunScene start_new_run failed")
		root.queue_free()
		return false

	var context = director.context
	var first_candidates = get_nodes_in_group("first_outpost_candidates")
	var second_candidates = get_nodes_in_group("second_outpost_candidates")
	if first_candidates.size() < 3:
		printerr("Expected at least 3 first outpost candidates, got %s" % first_candidates.size())
		root.queue_free()
		return false
	if second_candidates.size() < 4:
		printerr("Expected at least 4 second outpost candidates, got %s" % second_candidates.size())
		root.queue_free()
		return false
	if context.player_stability != 100.0:
		printerr("Expected stability 100, got %s" % context.player_stability)
		root.queue_free()
		return false
	if context.home_storage.size() != 4:
		printerr("Expected 4 home storage slots, got %s" % context.home_storage.size())
		root.queue_free()
		return false
	if context.selected_outpost_positions.size() != 2:
		printerr("Expected selected outpost positions for 2 outposts.")
		root.queue_free()
		return false

	root.queue_free()
	await process_frame
	print("RunScene point-based initialization verified.")
	return true

func _verify_invalid_extraction_guard(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run for invalid extraction guard failed")
		return false
	director.on_extraction_started()
	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "OBSERVE":
		printerr("Expected invalid extraction to remain OBSERVE, got %s" % state.get("current_phase"))
		return false
	print("Invalid extraction guard verified.")
	return true

func _verify_success_path(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run failed")
		return false
	director.on_home_exited()
	director.on_camera_transition_finished()
	director.on_safe_zone_entered("outpost_debug_a")
	director.on_outpost_repair_started("debug_outpost_a")
	director.on_outpost_repaired("debug_outpost_a")
	director.on_safe_zone_exited("outpost_debug_a")
	director.on_camera_transition_finished()
	director.on_outpost_repair_started("debug_outpost_b")
	director.on_outpost_repaired("debug_outpost_b")
	director.on_safe_zone_entered("home")
	director.on_extraction_started()
	director.on_extraction_completed()

	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "SETTLEMENT":
		printerr("Expected SETTLEMENT, got %s" % state.get("current_phase"))
		return false
	if state.get("run_result") != "EXTRACTED":
		printerr("Expected EXTRACTED, got %s" % state.get("run_result"))
		return false
	print("Success path verified.")
	return true

func _verify_death_path(director) -> bool:
	if not director.start_new_run():
		printerr("second start_new_run failed")
		return false
	director.on_home_exited()
	director.on_camera_transition_finished()
	director.on_player_dead("test_stability_depleted")

	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "FAILED":
		printerr("Expected FAILED, got %s" % state.get("current_phase"))
		return false
	if state.get("run_result") != "DEAD":
		printerr("Expected DEAD, got %s" % state.get("run_result"))
		return false
	print("Death path verified.")
	return true

extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_scene_uses_research_speed()
	print("Research speed application verified." if ok else "Research speed application failed.")
	quit(0 if ok else 1)

func _verify_run_scene_uses_research_speed() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	if game_state.profile.is_empty():
		game_state.profile = {"username": "测试员"}
	game_state.reset_research()
	game_state.clear_currencies()
	game_state.add_currency("mine_coin", 145, "test_speed_research")
	for _index in range(3):
		var research_result: Dictionary = game_state.complete_research("move_speed")
		if not bool(research_result.get("ok", false)):
			printerr("Expected move_speed research to complete before run scene: %s" % research_result)
			return false

	var run_scene: Node = load("res://scenes/run/RunScene.tscn").instantiate()
	root.add_child(run_scene)
	await process_frame
	await process_frame
	var player = run_scene.get_node_or_null("WorldRoot/YSortRoot/Player")
	if player == null:
		printerr("Expected RunScene to create player.")
		run_scene.queue_free()
		return false
	var expected_speed := 12.0 * 64.0 * 1.16
	if absf(float(player.base_speed) - expected_speed) > 0.01:
		printerr("Expected researched player base speed %.2f, got %.2f." % [expected_speed, float(player.base_speed)])
		run_scene.queue_free()
		return false
	run_scene.queue_free()
	await process_frame
	return true

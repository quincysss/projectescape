extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_countdown()
	quit(0 if ok else 1)

func _verify_run_countdown() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var context = root.run_director.context
	if context == null:
		printerr("Expected run context.")
		return false
	if not is_equal_approx(context.run_duration_seconds, 180.0):
		printerr("Expected run duration 180, got %s." % context.run_duration_seconds)
		return false
	if context.remaining_seconds > 180.0 or context.remaining_seconds < 179.0:
		printerr("Expected initial remaining seconds to stay near 180, got %s." % context.remaining_seconds)
		return false

	var countdown := root.get_node_or_null("RunUIRoot/CenterStatusHUD/CountdownPanel/CountdownLabel") as Label
	if countdown == null:
		printerr("Expected CountdownLabel under center status HUD.")
		return false
	var center_hud := root.get_node_or_null("RunUIRoot/CenterStatusHUD") as Control
	if center_hud == null or center_hud.anchor_left != 0.5 or center_hud.anchor_right != 0.5:
		printerr("Expected center status HUD to be anchored at top center.")
		return false
	if countdown.text != "03:00":
		printerr("Expected initial countdown 03:00, got %s." % countdown.text)
		return false

	root._update_run_timer(61.0)
	root._refresh_ui()
	await process_frame
	if countdown.text != "01:59":
		printerr("Expected countdown 01:59 after 61 seconds, got %s." % countdown.text)
		return false

	root.run_end_controller.base_scene_path = ""
	root._update_run_timer(119.0)
	var state: Dictionary = root.run_director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "FAILED":
		printerr("Expected timeout to enter FAILED, got %s." % state.get("current_phase"))
		return false
	if state.get("run_result") != "TIMEOUT_FAILED":
		printerr("Expected TIMEOUT_FAILED, got %s." % state.get("run_result"))
		return false
	if not context.is_time_expired or context.remaining_seconds != 0.0:
		printerr("Expected context timeout flags to be set.")
		return false

	root.queue_free()
	await process_frame
	print("Run countdown verified.")
	return true

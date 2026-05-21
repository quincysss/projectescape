extends SceneTree

func _initialize() -> void:
	var ok := await _verify_low_stability_warning_overlay()
	print("Low stability warning overlay verified." if ok else "Low stability warning overlay failed.")
	quit(0 if ok else 1)

func _verify_low_stability_warning_overlay() -> bool:
	var game_state = get_root().get_node("GameState")
	await process_frame
	game_state.reset_day(1)
	game_state.mark_second_day_black_tide_reveal_seen()

	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var overlay = root.get_node_or_null("RunUIRoot/LowStabilityWarningOverlay") as ColorRect
	if overlay == null:
		printerr("Expected low stability warning overlay under RunUIRoot.")
		return false
	if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		printerr("Expected low stability warning overlay to ignore mouse input.")
		return false
	var material := overlay.material as ShaderMaterial
	if material == null:
		printerr("Expected low stability warning overlay to use a ShaderMaterial.")
		return false
	if float(material.get_shader_parameter("near_edge_width")) < 0.03:
		printerr("Expected low stability warning edge band near 30 stability to be slightly widened.")
		return false
	if float(material.get_shader_parameter("near_fade_width")) < 0.20:
		printerr("Expected low stability warning fade range near 30 stability to be slightly widened.")
		return false
	if float(material.get_shader_parameter("critical_edge_width")) > 0.014:
		printerr("Expected low stability warning critical edge band to be halved.")
		return false
	if float(material.get_shader_parameter("critical_fade_width")) > 0.09:
		printerr("Expected low stability warning critical fade range to be halved.")
		return false

	root.run_director.context.player_stability = 30.0
	root.run_ui_controller.refresh(root)
	if overlay.visible:
		printerr("Expected low stability warning to stay hidden at 30 stability.")
		return false
	if float(material.get_shader_parameter("warning_strength")) > 0.001:
		printerr("Expected warning strength to be zero at 30 stability.")
		return false

	root.run_director.context.player_stability = 15.0
	root.run_ui_controller.refresh(root)
	if not overlay.visible:
		printerr("Expected low stability warning to show below 30 stability.")
		return false
	var mid_strength := float(material.get_shader_parameter("warning_strength"))
	if mid_strength <= 0.45 or mid_strength >= 0.55:
		printerr("Expected smooth warning strength around half at 15 stability, got %s." % mid_strength)
		return false

	root.run_director.context.player_stability = 0.0
	root.run_ui_controller.refresh(root)
	if float(material.get_shader_parameter("warning_strength")) < 0.99:
		printerr("Expected warning strength to max out near zero stability.")
		return false

	root.queue_free()
	await process_frame
	return true

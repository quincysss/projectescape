extends SceneTree

const LoadingScene := preload("res://scenes/ui/RunLoadingScreen.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Run loading continue gate verified." if ok else "Run loading continue gate failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var loading = LoadingScene.instantiate()
	root.add_child(loading)
	var state := {"completed": false, "failed": ""}
	loading.loading_completed.connect(func(_run_scene): state["completed"] = true)
	loading.loading_failed.connect(func(reason): state["failed"] = String(reason))
	loading.begin_loading()

	for _index in range(180):
		if loading.is_ready_to_continue() or not String(state.get("failed", "")).is_empty():
			break
		await process_frame
		await physics_frame

	if not String(state.get("failed", "")).is_empty():
		printerr("Expected loading to succeed, failed: %s" % String(state.get("failed", "")))
		loading.queue_free()
		return false
	if bool(state.get("completed", false)):
		printerr("Expected loading to wait at 100% before emitting completion.")
		loading.queue_free()
		return false
	if not loading.is_ready_to_continue():
		printerr("Expected loading to reach ready-to-continue state.")
		loading.queue_free()
		return false
	if loading.stage_label.text != "地面部署完成" or loading.percent_label.text != "100%":
		printerr("Expected ready state copy and percent to be visible.")
		loading.queue_free()
		return false
	if not loading.continue_label.visible or loading.continue_label.text != "按下任意按钮继续":
		printerr("Expected a single ready-to-continue prompt below the progress bar.")
		loading.queue_free()
		return false
	if not loading.controls_label.text.contains("WASD") or not loading.controls_label.text.contains("Tab") or not loading.controls_label.text.contains("F") or not loading.controls_label.text.contains("E"):
		printerr("Expected loading controls hint to include WASD, Tab, F, and E.")
		loading.queue_free()
		return false
	if not loading.mechanics_label.text.contains("视野") or not loading.mechanics_label.text.contains("稳定值") or not loading.mechanics_label.text.contains("基地"):
		printerr("Expected loading mechanics hint to mention vision, stability, and base recovery.")
		loading.queue_free()
		return false

	loading._input(_key(KEY_ENTER))
	await process_frame
	if not bool(state.get("completed", false)):
		printerr("Expected any key to continue into the run.")
		if is_instance_valid(loading):
			loading.queue_free()
		return false
	return true

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

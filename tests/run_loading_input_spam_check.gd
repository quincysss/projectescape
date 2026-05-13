extends SceneTree

const BaseScene := preload("res://scenes/base/BaseScene.tscn")
const LoadingScene := preload("res://scenes/ui/RunLoadingScreen.tscn")


func _initialize() -> void:
	var ok := await _verify_loading_input_spam_is_safe()
	ok = await _verify_base_rejects_duplicate_loading() and ok
	print("Run loading input spam verified." if ok else "Run loading input spam failed.")
	quit(0 if ok else 1)


func _verify_loading_input_spam_is_safe() -> bool:
	var loading = LoadingScene.instantiate()
	root.add_child(loading)
	var state := {"completed": false, "failed": ""}
	loading.loading_completed.connect(func(_run_scene): state["completed"] = true)
	loading.loading_failed.connect(func(reason): state["failed"] = String(reason))
	loading.begin_loading({"slow_mode": true})

	for _index in range(8):
		loading._input(_key(KEY_SPACE))
		await process_frame
		await physics_frame

	if bool(state.get("completed", false)):
		printerr("Loading should ignore continue input before the ready state.")
		loading.queue_free()
		return false
	if not String(state.get("failed", "")).is_empty():
		printerr("Loading failed while spamming input: %s" % String(state.get("failed", "")))
		loading.queue_free()
		return false

	loading.queue_free()
	for _index in range(12):
		await process_frame
		await physics_frame
	return true


func _verify_base_rejects_duplicate_loading() -> bool:
	var base = BaseScene.instantiate()
	root.add_child(base)
	await process_frame

	base._begin_run_loading()
	base._begin_run_loading()
	await process_frame

	var loading_count := 0
	for child in base.get_children():
		if child is RunLoadingScreen:
			loading_count += 1
	if loading_count != 1:
		printerr("Expected duplicate loading requests to keep one loading screen, got %d." % loading_count)
		base.queue_free()
		return false

	base.queue_free()
	for _index in range(4):
		await process_frame
	return true


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

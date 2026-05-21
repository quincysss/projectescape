extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Dialogue reentry guard verified." if ok else "Dialogue reentry guard failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("DialogueTest")
	if not bool(create_result.get("ok", false)):
		printerr("Expected temporary profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false

	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	await process_frame
	game_state.set_outgame_phase("LOADOUT")
	base._refresh()
	await process_frame

	base._request_start_run()
	await process_frame
	var panel := _first_dialogue_panel(base)
	if panel == null:
		printerr("Expected intro dialogue panel after starting run.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if _dialogue_panel_count(base) != 1:
		printerr("Expected exactly one dialogue panel after first start.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	panel._input(_key(KEY_SPACE))
	panel._input(_key(KEY_SPACE))
	await process_frame
	if int(panel.entry_index) != 1:
		printerr("Expected Space to advance to the second dialogue entry, got index %d." % int(panel.entry_index))
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	base._request_start_run()
	await process_frame
	if _dialogue_panel_count(base) != 1:
		printerr("Expected start-run reentry to not create another dialogue panel.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if panel != _first_dialogue_panel(base) or int(panel.entry_index) != 1:
		printerr("Expected existing dialogue panel to keep its current entry after reentry attempt.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	base.start_button.grab_focus()
	Input.parse_input_event(_key(KEY_SPACE))
	await process_frame
	if _dialogue_panel_count(base) != 1:
		printerr("Expected focused Start button Space input to not create another dialogue panel.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if panel != _first_dialogue_panel(base):
		printerr("Expected focused Start button Space input to keep the same dialogue panel.")
		base.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	base.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true

func _dialogue_panel_count(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is DialoguePanel:
			count += 1
	return count

func _first_dialogue_panel(node: Node) -> DialoguePanel:
	for child in node.get_children():
		if child is DialoguePanel:
			return child
	return null

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

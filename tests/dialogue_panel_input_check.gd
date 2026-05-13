extends SceneTree

const DIALOGUE_PANEL := preload("res://scenes/ui/DialoguePanel.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Dialogue panel input verified." if ok else "Dialogue panel input failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	var original_username := ""
	if game_state != null:
		original_username = String(game_state.username)
	var panel = DIALOGUE_PANEL.instantiate()
	root.add_child(panel)
	await process_frame
	if game_state != null:
		game_state.username = "昵称测试"
	panel.play_sequence({
		"dialogue_id": "test_dialogue",
		"entries": [
			{"speaker_id": "player", "speaker_name": "主角", "text": "第一句测试文本。"},
			{"speaker_id": "player", "speaker_name": "主角", "text": "第二句测试文本。"},
		],
	})
	await process_frame
	var hint := panel.get_node_or_null("DialogueBox/HintLabel") as Label
	if hint == null or hint.text != "SPACE 继续":
		printerr("Expected dialogue hint to only mention Space.")
		_restore_username(game_state, original_username)
		return false
	var dim := panel.get_node_or_null("DimLayer") as ColorRect
	if dim == null or dim.color.a > 0.8:
		printerr("Expected dialogue to dim the full screen without an opaque stage backdrop.")
		_restore_username(game_state, original_username)
		return false
	if panel.get_node_or_null("VideoPlaceholder16x9") != null:
		printerr("Expected dialogue panel to not include the cinematic placeholder backdrop.")
		_restore_username(game_state, original_username)
		return false
	var dialogue_box := panel.get_node_or_null("DialogueBox") as Panel
	var gradient_bg := panel.get_node_or_null("DialogueBox/DialogueGradientBackground") as TextureRect
	var dialogue_style := dialogue_box.get_theme_stylebox("panel") as StyleBoxFlat if dialogue_box != null else null
	if dialogue_box == null or gradient_bg == null or dialogue_style == null:
		printerr("Expected dialogue box to use a separate transparent gradient background.")
		_restore_username(game_state, original_username)
		return false
	if dialogue_box.size.x < 650.0 or dialogue_box.size.y < 250.0:
		printerr("Expected enlarged dialogue box, got %s." % str(dialogue_box.size))
		_restore_username(game_state, original_username)
		return false
	if dialogue_style.border_color != Color("#7F6A34") or dialogue_style.get_border_width(SIDE_TOP) != 2:
		printerr("Expected dialogue border to match the loading screen gold frame.")
		_restore_username(game_state, original_username)
		return false
	if panel.get_node_or_null("SkipButton") != null:
		printerr("Expected whole-sequence skip button to be removed.")
		_restore_username(game_state, original_username)
		return false
	if int(panel.speaker_label.get_theme_font_size("font_size")) != 22:
		printerr("Expected dialogue speaker name font size to be 22.")
		_restore_username(game_state, original_username)
		return false
	if panel.speaker_label.text != "昵称测试：":
		printerr("Expected player speaker name to use profile username, got '%s'." % panel.speaker_label.text)
		_restore_username(game_state, original_username)
		return false

	var state := {"finished": false, "skipped": true}
	panel.dialogue_finished.connect(func(_dialogue_id, skipped):
		state["finished"] = true
		state["skipped"] = bool(skipped)
	)

	panel._input(_key(KEY_ESCAPE))
	await process_frame
	if bool(state.get("finished", false)):
		printerr("Expected Escape to do nothing in dialogue.")
		_restore_username(game_state, original_username)
		return false

	panel._input(_key(KEY_SPACE))
	await process_frame
	if panel.body_label.text != "第一句测试文本。":
		printerr("Expected first Space to reveal current line.")
		_restore_username(game_state, original_username)
		return false
	panel._input(_key(KEY_SPACE))
	await process_frame
	if panel.body_label.text != "":
		printerr("Expected second Space to advance to the next line typing state.")
		_restore_username(game_state, original_username)
		return false
	if panel.speaker_label.text != "昵称测试：":
		printerr("Expected second player line to keep using profile username.")
		_restore_username(game_state, original_username)
		return false
	panel._input(_key(KEY_SPACE))
	panel._input(_key(KEY_SPACE))
	await process_frame
	if not bool(state.get("finished", false)) or bool(state.get("skipped", true)):
		printerr("Expected Space progression to finish without skipped=true.")
		_restore_username(game_state, original_username)
		return false
	_restore_username(game_state, original_username)
	return true

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _restore_username(game_state: Node, original_username: String) -> void:
	if game_state != null:
		game_state.username = original_username

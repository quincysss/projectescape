extends SceneTree

const DIALOGUE_PANEL := preload("res://scenes/ui/DialoguePanel.tscn")
const PLAYER_PORTRAIT := "res://assets/characters/dialogue/player/player_dialogue_bust_01.png"
const OPERATOR_PORTRAIT := "res://assets/characters/dialogue/operator_404/operator_404_dialogue_bust_01.png"

func _initialize() -> void:
	var ok := await _verify()
	print("Dialogue portrait display verified." if ok else "Dialogue portrait display failed.")
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
		game_state.username = "PortraitUser"

	panel.play_sequence({
		"dialogue_id": "portrait_test",
		"entries": [
			{"speaker_id": "operator_404", "speaker_name": "operator_404", "text": "operator line"},
			{"speaker_id": "player", "speaker_name": "player", "text": "player line"},
		],
	})
	await process_frame

	var left := panel.get_node_or_null("PortraitLayer/LeftPortrait") as TextureRect
	var right := panel.get_node_or_null("PortraitLayer/RightPortrait") as TextureRect
	if left == null or right == null:
		printerr("Expected dialogue portrait views.")
		_restore_username(game_state, original_username)
		return false
	if left.visible or not _has_texture(right, OPERATOR_PORTRAIT):
		printerr("Expected only the active operator portrait in the dialogue portrait slot.")
		_restore_username(game_state, original_username)
		return false
	if not right.visible or not is_equal_approx(right.modulate.a, 1.0):
		printerr("Expected active portrait to be fully visible.")
		_restore_username(game_state, original_username)
		return false
	var viewport_size := root.get_viewport().get_visible_rect().size
	var portrait_center_x := right.position.x + right.size.x * 0.5
	if portrait_center_x < viewport_size.x * 0.58 or portrait_center_x > viewport_size.x * 0.62:
		printerr("Expected dialogue portrait slot above the center dialogue area, got x %.1f." % portrait_center_x)
		_restore_username(game_state, original_username)
		return false
	var dialogue_box := panel.get_node_or_null("DialogueBox") as Panel
	var portrait_layer := panel.get_node_or_null("PortraitLayer") as Control
	var portrait_fade := panel.get_node_or_null("PortraitLayer/PortraitBottomFade") as TextureRect
	if dialogue_box == null or dialogue_box.size.x < 1000.0:
		printerr("Expected wider dialogue box.")
		_restore_username(game_state, original_username)
		return false
	var overlap := right.position.y + right.size.y - dialogue_box.position.y
	if overlap < 60.0 or overlap > 90.0:
		printerr("Expected dialogue portrait to overlap behind the dialogue box, got %.1f." % overlap)
		_restore_username(game_state, original_username)
		return false
	if portrait_layer == null or dialogue_box.z_index <= portrait_layer.z_index:
		printerr("Expected dialogue box to draw above the portrait layer.")
		_restore_username(game_state, original_username)
		return false
	if portrait_fade == null or not portrait_fade.visible:
		printerr("Expected portrait bottom fade overlay.")
		_restore_username(game_state, original_username)
		return false
	if not panel.speaker_label.text.contains("404"):
		printerr("Expected operator display name from dialogue_speakers.tab.")
		_restore_username(game_state, original_username)
		return false

	panel._input(_key(KEY_SPACE))
	panel._input(_key(KEY_SPACE))
	await process_frame
	if left.visible or not _has_texture(right, PLAYER_PORTRAIT):
		printerr("Expected only the active player portrait after advancing.")
		_restore_username(game_state, original_username)
		return false
	if panel.speaker_label.text != "PortraitUser：":
		printerr("Expected player speaker name to use profile username, got '%s'." % panel.speaker_label.text)
		_restore_username(game_state, original_username)
		return false

	panel.play_sequence({
		"dialogue_id": "player_monologue_test",
		"entries": [
			{"speaker_id": "player", "speaker_name": "player", "text": "alone"},
		],
	})
	await process_frame
	if left.visible or not _has_texture(right, PLAYER_PORTRAIT):
		printerr("Expected player monologue to only show the player portrait.")
		_restore_username(game_state, original_username)
		return false

	panel.queue_free()
	await process_frame
	_restore_username(game_state, original_username)
	return true

func _has_texture(view: TextureRect, expected_path: String) -> bool:
	return view.texture != null and view.texture.resource_path == expected_path

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _restore_username(game_state: Node, original_username: String) -> void:
	if game_state != null:
		game_state.username = original_username

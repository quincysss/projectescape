extends SceneTree

func _initialize() -> void:
	var ok := await _verify()
	print("UI click audio router verified." if ok else "UI click audio router failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var router = root.get_node_or_null("UIAudioRouter")
	var audio_manager = root.get_node_or_null("AudioManager")
	if router == null:
		printerr("Expected UIAudioRouter autoload.")
		return false
	if audio_manager == null:
		printerr("Expected AudioManager autoload.")
		return false

	var received: Array[String] = []
	var callback := func(sfx_id: String, _path: String, _played: bool) -> void:
		received.append(sfx_id)
	audio_manager.sfx_requested.connect(callback)

	var normal_button := Button.new()
	root.add_child(normal_button)
	await process_frame
	normal_button.pressed.emit()
	await process_frame
	if not received.has("ui_button_click"):
		printerr("Expected normal button click to request ui_button_click.")
		return false

	var item_button := Button.new()
	item_button.set_meta("ui_click_sfx", "ui_item_click")
	root.add_child(item_button)
	await process_frame
	item_button.pressed.emit()
	await process_frame
	if not received.has("ui_item_click"):
		printerr("Expected item button click to request ui_item_click.")
		return false

	normal_button.queue_free()
	item_button.queue_free()
	await process_frame
	return true

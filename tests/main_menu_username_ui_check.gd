extends SceneTree

const MainMenuScene := preload("res://scenes/ui/MainMenuScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Main menu username UI verified." if ok else "Main menu username UI failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()

	var menu = MainMenuScene.instantiate()
	root.add_child(menu)
	await process_frame

	var overlay := menu.get_node_or_null("UsernameOverlay") as Control
	var background := menu.get_node_or_null("UsernameOverlay/UsernameBackgroundPlaceholder") as ColorRect
	var panel := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel") as Panel
	var edit := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameEdit") as LineEdit
	var confirm := menu.get_node_or_null("UsernameOverlay/UsernameProfilePanel/UsernameConfirmButton") as Panel
	var ok := true
	if overlay == null or background == null or panel == null or edit == null or confirm == null:
		printerr("Expected custom username whitebox controls.")
		ok = false
	elif overlay.visible:
		printerr("Expected username overlay to stay hidden before Start is pressed.")
		ok = false
	else:
		menu._on_start_pressed()
		await process_frame
		if not overlay.visible:
			printerr("Expected username overlay to show when no profile exists.")
			ok = false
		if background.color != Color("#171211") or background.anchor_right != 1.0 or background.anchor_bottom != 1.0:
			printerr("Expected username background placeholder to be full-screen black.")
			ok = false
		if panel.size != Vector2(736, 386):
			printerr("Expected username panel to match the whitebox mockup size.")
			ok = false
		if edit.position != Vector2(242, 176) or edit.size != Vector2(252, 36):
			printerr("Expected username input to use the narrowed whitebox rect.")
			ok = false
		if confirm.position != Vector2(320, 272) or confirm.size != Vector2(96, 26):
			printerr("Expected confirm button to use the whitebox rect, got position=%s size=%s." % [confirm.position, confirm.size])
			ok = false

	menu.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return ok

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

extends SceneTree

const PORTRAIT_PATH := "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_male_01.png"
const FRAME_PATH := "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_frame_empty_ref_01.png"

func _initialize() -> void:
	var ok := await _verify_character_portrait_hud()
	print("Character portrait HUD verified." if ok else "Character portrait HUD failed.")
	quit(0 if ok else 1)

func _verify_character_portrait_hud() -> bool:
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null and game_state.has_method("set_selected_character"):
		game_state.set_selected_character("male_01")
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var hud := root.get_node_or_null("RunUIRoot/CharacterStatusHUD") as Control
	var portrait := hud.get_node_or_null("PortraitImage") as TextureRect if hud != null else null
	var frame := hud.get_node_or_null("PortraitFrame") as TextureRect if hud != null else null
	var placeholder := hud.get_node_or_null("PortraitFrame/PortraitPlaceholder") if hud != null else null
	var ok := true
	if hud == null or portrait == null or frame == null:
		printerr("Expected character HUD portrait image and frame.")
		ok = false
	if portrait != null:
		if portrait.texture == null or portrait.texture.resource_path != PORTRAIT_PATH:
			printerr("Expected selected male portrait texture.")
			ok = false
		if portrait.size != Vector2(168, 184):
			printerr("Expected portrait to match frame size.")
			ok = false
	if frame != null:
		if frame.texture == null or frame.texture.resource_path != FRAME_PATH:
			printerr("Expected portrait frame texture.")
			ok = false
		if portrait != null and frame.z_index <= portrait.z_index:
			printerr("Expected portrait frame to draw above portrait image.")
			ok = false
	if placeholder != null:
		printerr("Expected portrait placeholder text to be removed.")
		ok = false

	root.queue_free()
	await process_frame
	return ok

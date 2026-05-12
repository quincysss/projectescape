extends SceneTree

const MainMenuScene := preload("res://scenes/ui/MainMenuScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Main menu layout verified." if ok else "Main menu layout failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var menu = MainMenuScene.instantiate()
	root.add_child(menu)
	await process_frame

	var background := menu.get_node_or_null("MainMenuBackgroundFallback") as ColorRect
	var dim := menu.get_node_or_null("MainMenuBackgroundDim") as ColorRect
	var left_shade := menu.get_node_or_null("MainMenuLeftShade") as ColorRect
	var background_video := menu.get_node_or_null("MainMenuBackgroundVideo") as VideoStreamPlayer
	var content := menu.get_node_or_null("MainMenuContent") as Control
	var start_button := menu.get_node_or_null("MainMenuContent/StartGameButton") as Button
	var settings_button := menu.get_node_or_null("MainMenuContent/SettingsButton") as Button
	var logo_box := menu.get_node_or_null("MainMenuContent/MainMenuLogoBox") as Control
	var logo_fallback := menu.get_node_or_null("MainMenuContent/MainMenuLogoBox/MainMenuLogoFallbackLabel") as Label
	var logo_image := menu.get_node_or_null("MainMenuContent/MainMenuLogoBox/MainMenuLogoImage") as TextureRect
	var ok := true

	if background == null or background.anchor_right != 1.0 or background.anchor_bottom != 1.0:
		printerr("Expected full-screen main menu background fallback.")
		ok = false
	if dim == null:
		printerr("Expected main menu readability dim overlay.")
		ok = false
	if left_shade != null:
		printerr("Expected main menu left black shade to be removed.")
		ok = false
	if background_video == null or background_video.stream == null:
		printerr("Expected main menu MP4 background video to load as a VideoStream.")
		ok = false
	if content == null or content.position != Vector2(34.0, 128.0) or content.size != Vector2(780.0, 742.0):
		printerr("Expected left-side main menu content to match the reference frame.")
		ok = false
	if logo_box == null or logo_box.position != Vector2(0.0, 0.0) or logo_box.size != Vector2(780.0, 270.0):
		printerr("Expected logo to be enlarged to the red reference frame.")
		ok = false
	if start_button == null or start_button.position != Vector2(172.0, 486.0) or start_button.size != Vector2(360.0, 72.0):
		printerr("Expected start button to match the green reference frame.")
		ok = false
	if settings_button == null or settings_button.position != Vector2(172.0, 676.0) or settings_button.size != Vector2(360.0, 72.0):
		printerr("Expected settings button to match the green reference frame.")
		ok = false
	if logo_image == null:
		printerr("Expected main menu to use the processed Black Tide Project logo image.")
		ok = false
	elif logo_image.texture == null or logo_image.texture.resource_path != "res://assets/ui/logos/black_tide_project/processed/black_tide_project_logo_handpainted_alpha_bgfit_01.png":
		printerr("Expected main menu logo to use the processed logo resource.")
		ok = false
	elif logo_image.size.x > 780.0 or logo_image.size.y > 270.0 or logo_image.stretch_mode != TextureRect.STRETCH_SCALE:
		printerr("Expected main menu logo image to be scaled inside the enlarged box.")
		ok = false
	if logo_fallback != null:
		printerr("Expected processed logo image instead of fallback logo text.")
		ok = false

	menu.queue_free()
	await process_frame
	return ok

extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")
const RUN_LOADING_SCENE := preload("res://scenes/ui/RunLoadingScreen.tscn")
const ReturnToBaseLoadingScreenScript := preload("res://scripts/ui/return_to_base_loading_screen.gd")


func _initialize() -> void:
	var ok := await _verify()
	print("UI background photos verified." if ok else "UI background photos failed.")
	quit(0 if ok else 1)


func _verify() -> bool:
	var ok := true
	ok = await _verify_base_background() and ok
	ok = await _verify_run_loading_background() and ok
	ok = await _verify_return_loading_background() and ok
	return ok


func _verify_base_background() -> bool:
	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	await process_frame
	var image := base.get_node_or_null("BaseBackground/BaseBackgroundImage") as TextureRect
	var ok := _verify_cover_image(image, "res://assets/originalphoto/basementphoto.png", "base background")
	_stop_bgm()
	base.queue_free()
	await process_frame
	return ok


func _verify_run_loading_background() -> bool:
	var loading = RUN_LOADING_SCENE.instantiate()
	root.add_child(loading)
	await process_frame
	var image := loading.get_node_or_null("RunLoadingBackground/RunLoadingBackgroundImage") as TextureRect
	var ok := _verify_cover_image(image, "res://assets/originalphoto/loadingphoto.png", "run loading background")
	loading.queue_free()
	await process_frame
	return ok


func _verify_return_loading_background() -> bool:
	var loading: ReturnToBaseLoadingScreen = ReturnToBaseLoadingScreenScript.new()
	root.add_child(loading)
	await process_frame
	var image := loading.get_node_or_null("ReturnLoadingBackground/ReturnLoadingBackgroundImage") as TextureRect
	var ok := _verify_cover_image(image, "res://assets/originalphoto/backloadingphoto.png", "return loading background")
	loading.queue_free()
	await process_frame
	return ok


func _verify_cover_image(image: TextureRect, expected_path: String, label: String) -> bool:
	if image == null:
		printerr("Expected %s image node." % label)
		return false
	if image.texture == null or String(image.get_meta("source_texture_path", "")) != expected_path:
		printerr("Expected %s to use %s." % [label, expected_path])
		return false
	if image.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		printerr("Expected %s to ignore source size for screen fitting." % label)
		return false
	if image.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		printerr("Expected %s to use aspect-covered screen fitting." % label)
		return false
	return true


func _stop_bgm() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_bgm"):
		audio_manager.stop_bgm()

extends SceneTree

const VisionMaskScript := preload("res://scripts/vision/vision_mask_overlay.gd")

func _initialize() -> void:
	var ok := await _verify_mask_center_tracks_target_after_resize()
	print("Vision mask resize alignment verified." if ok else "Vision mask resize alignment failed.")
	quit(0 if ok else 1)

func _verify_mask_center_tracks_target_after_resize() -> bool:
	root.size = Vector2i(1280, 720)
	var world := Node2D.new()
	get_root().add_child(world)
	var player := Node2D.new()
	player.position = Vector2(360.0, 220.0)
	world.add_child(player)

	var ui := CanvasLayer.new()
	get_root().add_child(ui)
	var mask = VisionMaskScript.new()
	mask.target = player
	ui.add_child(mask)
	await process_frame
	mask.set_darkness_enabled(true)
	mask.set_radius(640.0)
	await process_frame

	var first_center: Vector2 = mask._get_mask_center()
	var first_expected: Vector2 = mask.get_global_transform_with_canvas().affine_inverse() * player.get_global_transform_with_canvas().origin
	if first_center.distance_to(first_expected) > 0.1:
		printerr("Expected mask center to match target before resize. center=%s expected=%s" % [first_center, first_expected])
		return false

	root.size = Vector2i(1024, 768)
	await process_frame
	await process_frame
	mask._update_shader()
	var resized_center: Vector2 = mask._get_mask_center()
	var resized_expected: Vector2 = mask.get_global_transform_with_canvas().affine_inverse() * player.get_global_transform_with_canvas().origin
	if resized_center.distance_to(resized_expected) > 0.1:
		printerr("Expected mask center to match target after resize. center=%s expected=%s" % [resized_center, resized_expected])
		return false
	var expected_size := mask.get_viewport_rect().size
	if mask.size != expected_size:
		printerr("Expected mask size to match resized viewport rect. mask=%s viewport=%s" % [mask.size, expected_size])
		return false

	ui.queue_free()
	world.queue_free()
	await process_frame
	return true

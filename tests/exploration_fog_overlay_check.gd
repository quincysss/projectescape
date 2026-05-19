extends SceneTree

const ExplorationFogScript := preload("res://scripts/vision/exploration_fog_overlay.gd")

func _initialize() -> void:
	var ok := await _verify_exploration_fog_reveals_current_and_persistent_areas()
	print("Exploration fog overlay verified." if ok else "Exploration fog overlay failed.")
	quit(0 if ok else 1)

func _verify_exploration_fog_reveals_current_and_persistent_areas() -> bool:
	var world := Node2D.new()
	get_root().add_child(world)
	var player := Node2D.new()
	player.position = Vector2.ZERO
	world.add_child(player)

	var fog = ExplorationFogScript.new()
	world.add_child(fog)
	fog.mask_pixel_world_size = 64.0
	fog.persistent_edge_softness_px = 0.0
	fog.setup(Rect2(Vector2(-512.0, -512.0), Vector2(1024.0, 1024.0)), player, 128.0)
	await process_frame

	if _explored_value(fog, Vector2.ZERO) < 0.95:
		printerr("Expected initial current area to be explored.")
		return false
	if _explored_value(fog, Vector2(448.0, 448.0)) > 0.05:
		printerr("Expected distant area to remain unexplored.")
		return false

	player.global_position = Vector2(256.0, 0.0)
	fog._process(0.0)
	if _explored_value(fog, Vector2(256.0, 0.0)) < 0.95:
		printerr("Expected moved-to area to be explored.")
		return false
	if _explored_value(fog, Vector2.ZERO) < 0.95:
		printerr("Expected walked area to stay persistently explored.")
		return false

	fog.reveal_rect(Rect2(Vector2(-384.0, 192.0), Vector2(128.0, 128.0)), 0.0)
	if _explored_value(fog, Vector2(-320.0, 256.0)) < 0.95:
		printerr("Expected explicit host block reveal to mark its rect explored.")
		return false

	fog.reveal_permanent_light_rect(Rect2(Vector2(192.0, 192.0), Vector2(128.0, 128.0)), 0.0)
	if fog.get_permanent_light_value(Vector2(256.0, 256.0)) < 0.95:
		printerr("Expected permanent light rect to keep its block bright.")
		return false
	if _explored_value(fog, Vector2(256.0, 256.0)) < 0.95:
		printerr("Expected permanent light rect to also count as explored.")
		return false

	world.queue_free()
	await process_frame
	return true

func _explored_value(fog, world_pos: Vector2) -> float:
	var pixel: Vector2i = fog._world_to_pixel(world_pos)
	return fog._image.get_pixel(pixel.x, pixel.y).r

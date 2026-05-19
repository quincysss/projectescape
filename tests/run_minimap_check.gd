extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_minimap_tracks_fog_and_strategic_markers()
	print("Run minimap verified." if ok else "Run minimap failed.")
	quit(0 if ok else 1)

func _verify_run_minimap_tracks_fog_and_strategic_markers() -> bool:
	var game_state = get_root().get_node("GameState")
	await process_frame
	game_state.reset_day(1)
	game_state.mark_second_day_black_tide_reveal_seen()

	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var minimap = root.get_node_or_null("RunUIRoot/RunMinimap")
	if minimap == null:
		printerr("Expected RunMinimap under RunUIRoot.")
		return false
	if minimap != root.minimap:
		printerr("Expected RunScene.minimap to reference the HUD minimap.")
		return false
	if minimap.anchor_left != 1.0 or minimap.anchor_right != 1.0:
		printerr("Expected minimap anchored to the right side.")
		return false
	if minimap.offset_right > -20.0 or minimap.offset_top < 10.0:
		printerr("Expected minimap in the upper-right HUD area.")
		return false
	if minimap.fog_overlay != root.vision_mask:
		printerr("Expected minimap to read from the exploration fog overlay.")
		return false
	if minimap.get_marker_count("outpost") < 2:
		printerr("Expected minimap to always include outpost markers.")
		return false
	if minimap.get_marker_count("material") < 4:
		printerr("Expected minimap to always include repair material markers.")
		return false
	if root.vision_mask.get_permanent_light_value(root.player_root.global_position) < 0.95:
		printerr("Expected home block to stay permanently bright.")
		return false
	var home_art_rect: Rect2 = root._home_art_permanent_light_rect()
	if home_art_rect.size.x <= 0.0 or home_art_rect.size.y <= 0.0:
		printerr("Expected the real home art resource to resolve a permanent-light rect.")
		return false
	if root.vision_mask.get_permanent_light_value(home_art_rect.get_center()) < 0.95:
		printerr("Expected the real home art resource to stay permanently bright.")
		return false

	var hidden_material = _first_marker_position(minimap, "material")
	if hidden_material == Vector2.INF:
		printerr("Expected a material marker position.")
		return false
	if root.vision_mask.get_explored_value(hidden_material) > 0.05:
		printerr("Expected at least one minimap material marker to be allowed before local fog reveal.")
		return false

	var outpost = _first_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected an outpost interactable.")
		return false
	root._reveal_interaction_area(outpost, true)
	if root.vision_mask.get_permanent_light_value(outpost.global_position) < 0.95:
		printerr("Expected repaired outpost block to stay permanently bright.")
		return false

	root.queue_free()
	await process_frame
	return true

func _first_marker_position(minimap, marker_type: String) -> Vector2:
	for marker in minimap.markers:
		if String(marker.get("type", "")) == marker_type:
			return marker.get("position", Vector2.INF)
	return Vector2.INF

func _first_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and String(interactable.interact_type) == interact_type:
			return interactable
	return null

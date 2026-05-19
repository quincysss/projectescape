extends SceneTree

func _initialize() -> void:
	var ok := await _verify_material_spawn_points()
	await _shutdown_audio()
	print("Material spawn point uniqueness verified." if ok else "Material spawn point uniqueness failed.")
	quit(0 if ok else 1)

func _verify_material_spawn_points() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := _check_no_duplicate_material_positions(root)
	ok = _check_material_lifetime_fill_visual(root) and ok
	root._spawn_requirement_materials()
	ok = _check_no_duplicate_material_positions(root) and ok
	ok = await _check_material_lifetime_respawn(root) and ok

	root.queue_free()
	await process_frame
	return ok

func _check_no_duplicate_material_positions(root: Node) -> bool:
	var seen := {}
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		var key := "%d,%d" % [int(round(interactable.global_position.x)), int(round(interactable.global_position.y))]
		if seen.has(key):
			printerr("Duplicate material spawn position: %s" % key)
			return false
		seen[key] = true
	return true

func _check_material_lifetime_respawn(root: Node) -> bool:
	var material = _first_material(root)
	if material == null:
		printerr("Expected at least one outpost material.")
		return false
	var old_pos: Vector2 = material.global_position
	var item_id := String(material.payload.get("item_id", ""))
	var positions_before := _material_position_keys(root)
	material.payload.lifetime = 0.01
	root.outpost_material_spawn_controller.update_lifetimes(1.0, root.interactables)
	await root.get_tree().process_frame
	if is_instance_valid(material):
		printerr("Expected expired outpost material to be removed.")
		return false
	var replacement = _new_material_for_item(root, item_id, positions_before)
	if replacement == null:
		printerr("Expected expired outpost material to respawn immediately.")
		return false
	if replacement.global_position.distance_squared_to(old_pos) <= 1.0:
		printerr("Expected expired outpost material to move to another spawn point.")
		return false
	var replacement_lifetime := float(replacement.payload.get("lifetime", 0.0))
	if replacement_lifetime <= 119.0 or replacement_lifetime > 120.0:
		printerr("Expected replacement material lifetime to reset to 120 seconds.")
		return false
	return _check_no_duplicate_material_positions(root)

func _check_material_lifetime_fill_visual(root: Node) -> bool:
	var material = _first_material(root)
	if material == null:
		printerr("Expected at least one outpost material.")
		return false
	var visual := material.get_node_or_null("BuildMaterialVisual") as Polygon2D
	var fill := material.get_node_or_null("BuildMaterialLifetimeFill") as Polygon2D
	if visual == null or fill == null:
		printerr("Expected material visual and lifetime fill nodes.")
		return false
	material.payload.lifetime = float(material.payload.get("lifetime_max", 120.0)) * 0.5
	root._refresh_material_lifetime_visual(material)
	if fill.polygon.size() < 3:
		printerr("Expected half-lifetime material fill polygon.")
		return false
	var visual_height := _polygon_height(visual.polygon)
	var fill_height := _polygon_height(fill.polygon)
	if fill_height >= visual_height - 0.5:
		printerr("Expected material lifetime fill height to shrink with remaining lifetime.")
		return false
	return true

func _first_material(root: Node):
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		return interactable
	return null

func _new_material_for_item(root: Node, item_id: String, positions_before: Dictionary):
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		if String(interactable.payload.get("item_id", "")) != item_id:
			continue
		if positions_before.has(_position_key(interactable.global_position)):
			continue
		return interactable
	return null

func _material_position_keys(root: Node) -> Dictionary:
	var keys := {}
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		keys[_position_key(interactable.global_position)] = true
	return keys

func _position_key(position: Vector2) -> String:
	return "%d,%d" % [int(round(position.x)), int(round(position.y))]

func _polygon_height(polygon: PackedVector2Array) -> float:
	if polygon.is_empty():
		return 0.0
	var min_y := polygon[0].y
	var max_y := polygon[0].y
	for point in polygon:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return max_y - min_y

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

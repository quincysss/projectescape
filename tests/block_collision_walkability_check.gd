extends SceneTree

const UNIT := 64.0
const PLAYER_RADIUS_UNITS := 0.6

func _initialize() -> void:
	var ok := await _verify_block_collision_walkability()
	print("Block collision walkability verified." if ok else "Block collision walkability failed.")
	quit(0 if ok else 1)

func _verify_block_collision_walkability() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	var blocks := _layout_rects(root, "BlockSolid")
	var exception_rects: Array[Rect2] = root._get_enterable_exception_rects()
	if blocks.is_empty():
		printerr("Expected BlockSolid layout rects.")
		ok = false

	for block in blocks:
		var rect: Rect2 = block.rect
		var samples := _block_samples(rect)
		var blocked_samples := 0
		for sample in samples:
			if _point_in_plain_rects(sample, exception_rects):
				continue
			var player_allows: bool = root.player._is_position_walkable(sample)
			var collision_blocks := _circle_hits_generated_collision(root, sample, PLAYER_RADIUS_UNITS * UNIT)
			if player_allows:
				printerr("Block %s sample is in player walkable whitelist: %s" % [block.id, _fmt_units(sample)])
				ok = false
			if not collision_blocks:
				printerr("Block %s sample is missing generated collision: %s" % [block.id, _fmt_units(sample)])
				ok = false
			else:
				blocked_samples += 1
		if blocked_samples <= 0:
			printerr("Block %s has no non-exception collision sample." % block.id)
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _layout_rects(root: Node, section_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var section := root.get_node_or_null("WorldRoot/MapLayout/%s" % section_name)
	if section == null:
		return result
	for child in section.find_children("*", "", true, false):
		if child.has_method("get_rect_px"):
			result.append({
				"id": child.get_rect_id(),
				"rect": child.get_rect_px(UNIT),
			})
	return result

func _block_samples(rect: Rect2) -> Array[Vector2]:
	var inset := minf(rect.size.x, rect.size.y) * 0.2
	return [
		rect.get_center(),
		rect.position + Vector2(inset, inset),
		rect.position + Vector2(rect.size.x - inset, inset),
		rect.position + Vector2(inset, rect.size.y - inset),
		rect.position + rect.size - Vector2(inset, inset),
	]

func _point_in_plain_rects(point: Vector2, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _circle_hits_generated_collision(root: Node, point: Vector2, radius: float) -> bool:
	var world_root := root.get_node("WorldRoot")
	for child in world_root.get_children():
		if not (child is StaticBody2D):
			continue
		for shape_node in child.get_children():
			if not (shape_node is CollisionShape2D) or shape_node.shape == null:
				continue
			if not (shape_node.shape is RectangleShape2D):
				continue
			var local_point: Vector2 = shape_node.global_transform.affine_inverse() * point
			var half_size: Vector2 = shape_node.shape.size * 0.5
			if absf(local_point.x) <= half_size.x + radius and absf(local_point.y) <= half_size.y + radius:
				return true
	return false

func _fmt_units(pos: Vector2) -> String:
	return "(%.1f, %.1f)u" % [pos.x / UNIT, pos.y / UNIT]

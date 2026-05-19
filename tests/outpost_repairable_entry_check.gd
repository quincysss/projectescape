extends SceneTree

const UNIT := 64.0
const PLAYER_RADIUS_UNITS := 0.6
const SEARCH_STEP := 32.0

func _initialize() -> void:
	var ok := await _verify_repairable_outposts_are_reachable()
	await _shutdown_audio()
	print("Repairable outpost entry verified." if ok else "Repairable outpost entry failed.")
	quit(0 if ok else 1)

func _verify_repairable_outposts_are_reachable() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	var start: Vector2 = root.player.global_position
	var reachable := _collect_reachable_points(root, start)
	for candidate in root._get_outpost_candidate_points():
		if not _candidate_area_reachable(candidate, reachable):
			printerr("Outpost candidate cannot be entered from player spawn: %s at %s" % [
				candidate.get_candidate_id(),
				_fmt_units(candidate.global_position),
			])
			ok = false
	for outpost in _selected_outposts(root):
		_fill_outpost_requirements(root, outpost)
		var validation: Dictionary = root.outpost_repair_controller.can_repair(outpost)
		if not bool(validation.get("accepted", false)):
			printerr("Expected selected outpost to become repairable: %s" % outpost.interact_id)
			ok = false
			continue
		if not _outpost_area_reachable(outpost, reachable):
			printerr("Repairable outpost cannot be entered from player spawn: %s at %s" % [
				outpost.interact_id,
				_fmt_units(outpost.global_position),
			])
			ok = false
		if _circle_hits_generated_collision(root, outpost.global_position, PLAYER_RADIUS_UNITS * UNIT):
			printerr("Repairable outpost center is still covered by generated collision: %s" % outpost.interact_id)
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _selected_outposts(root: Node) -> Array:
	var result := []
	for child in root.outpost_root.get_children():
		if is_instance_valid(child) and child.get("interact_type") == "outpost":
			result.append(child)
	return result

func _fill_outpost_requirements(root: Node, outpost) -> void:
	var requirements: Dictionary = outpost.payload.get("requirements", {})
	for item_id in requirements.keys():
		var amount := int(requirements[item_id].get("amount", 0))
		for _i in range(amount):
			root.run_director.inventory_component.add_item({
				"item_id": StringName(str(item_id)),
				"amount": 1,
				"repair_material_id": StringName(str(item_id)),
			})

func _collect_reachable_points(root: Node, start: Vector2) -> Dictionary:
	var bounds := Rect2(root.MAP_ORIGIN_UNITS * UNIT, root.MAP_UNITS * UNIT)
	var start_key := _grid_key(start)
	var frontier := [start_key]
	var visited := {start_key: true}
	var points := {start_key: _grid_pos(start_key)}
	while not frontier.is_empty():
		var key: Vector2i = frontier.pop_front()
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_key: Vector2i = key + dir
			if visited.has(next_key):
				continue
			var next_pos := _grid_pos(next_key)
			if not bounds.has_point(next_pos):
				continue
			if not _can_player_stand_at(root, next_pos):
				continue
			visited[next_key] = true
			points[next_key] = next_pos
			frontier.append(next_key)
	return points

func _outpost_area_reachable(outpost, reachable: Dictionary) -> bool:
	var footprint_units: Vector2 = outpost.payload.get("footprint_units", Vector2(10.0, 8.0))
	var rect := Rect2(outpost.global_position - footprint_units * UNIT * 0.5, footprint_units * UNIT)
	for point in reachable.values():
		if rect.has_point(point):
			return true
	return false

func _candidate_area_reachable(candidate: Node2D, reachable: Dictionary) -> bool:
	var footprint_units: Vector2 = candidate.get_footprint_units() if candidate.has_method("get_footprint_units") else Vector2(10.0, 8.0)
	var rect := Rect2(candidate.global_position - footprint_units * UNIT * 0.5, footprint_units * UNIT)
	for point in reachable.values():
		if rect.has_point(point):
			return true
	return false

func _can_player_stand_at(root: Node, point: Vector2) -> bool:
	if not root.player._is_position_walkable(point):
		return false
	return not _circle_hits_generated_collision(root, point, PLAYER_RADIUS_UNITS * UNIT)

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

func _grid_key(pos: Vector2) -> Vector2i:
	return Vector2i(int(round(pos.x / SEARCH_STEP)), int(round(pos.y / SEARCH_STEP)))

func _grid_pos(key: Vector2i) -> Vector2:
	return Vector2(float(key.x) * SEARCH_STEP, float(key.y) * SEARCH_STEP)

func _fmt_units(pos: Vector2) -> String:
	return "(%.1f, %.1f)u" % [pos.x / UNIT, pos.y / UNIT]

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

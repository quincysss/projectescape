extends SceneTree

const UNIT := 64.0
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const PLAYER_RADIUS_UNITS := 0.6

func _initialize() -> void:
	var ok := await _verify_map_spawn_points()
	quit(0 if ok else 1)

func _verify_map_spawn_points() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	var block_rects := _layout_rects(root, "BlockSolid")
	var street_rects := _layout_rects(root, "StreetWalkable")
	var exception_rects: Array[Rect2] = root._get_enterable_exception_rects()

	ok = _check_point_pool(root, "ContainerSpawnPoints", block_rects, street_rects, exception_rects, false) and ok
	ok = _check_point_pool(root, "MaterialSpawnPoints", block_rects, street_rects, exception_rects, false) and ok
	ok = _check_point_pool(root, "MonsterSpawnPoints", block_rects, street_rects, exception_rects, false) and ok
	ok = _check_monster_point_count(root) and ok
	ok = _check_monster_patrol_paths(root, block_rects, street_rects) and ok
	ok = _check_outpost_candidates(root, block_rects, street_rects, exception_rects) and ok

	root.queue_free()
	await process_frame
	if ok:
		print("Map spawn point sanity verified.")
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
				"node": child,
			})
	return result

func _check_point_pool(root: Node, section_name: String, block_rects: Array[Dictionary], street_rects: Array[Dictionary], exception_rects: Array[Rect2], allow_block_exception: bool) -> bool:
	var section := root.get_node_or_null("WorldRoot/MapLayout/Points/%s" % section_name)
	if section == null:
		printerr("Missing point section: %s" % section_name)
		return false
	var ok := true
	for point in section.get_children():
		if not (point is Node2D) or not point.has_method("get_point_id") or not point.enabled:
			continue
		var pos: Vector2 = point.global_position
		var id := String(point.get_point_id())
		var inside_street := _point_in_rects(pos, street_rects)
		var block := _first_containing_rect(pos, block_rects)
		var inside_exception := _point_in_plain_rects(pos, exception_rects)
		if not inside_street:
			printerr("%s %s is outside StreetWalkable: %s" % [section_name, id, _fmt_units(pos)])
			ok = false
		if not block.is_empty() and not (allow_block_exception and inside_exception):
			printerr("%s %s is inside block %s at %s" % [section_name, id, block.id, _fmt_units(pos)])
			ok = false
	return ok

func _check_monster_point_count(root: Node) -> bool:
	var section := root.get_node_or_null("WorldRoot/MapLayout/Points/MonsterSpawnPoints")
	if section == null:
		printerr("Missing point section: MonsterSpawnPoints")
		return false
	var enabled_count := 0
	for point in section.get_children():
		if point is Node2D and point.has_method("get_point_id") and point.enabled:
			enabled_count += 1
	if enabled_count != 10:
		printerr("Expected 10 enabled monster street points, got %s." % enabled_count)
		return false
	return true

func _check_monster_patrol_paths(root: Node, block_rects: Array[Dictionary], street_rects: Array[Dictionary]) -> bool:
	var section := root.get_node_or_null("WorldRoot/MapLayout/Points/MonsterSpawnPoints")
	if section == null:
		printerr("Missing point section: MonsterSpawnPoints")
		return false
	var ok := true
	for point in section.get_children():
		if not (point is Node2D) or not point.has_method("get_point_id") or not point.enabled:
			continue
		var path_count := 0
		for child in point.find_children("*", "Node2D", true, false):
			if not _is_patrol_path_marker(child):
				continue
			path_count += 1
			var pos: Vector2 = child.global_position
			var inside_street := _point_in_rects(pos, street_rects)
			var block := _first_containing_rect(pos, block_rects)
			if not inside_street:
				printerr("Monster patrol point %s/%s is outside StreetWalkable: %s" % [point.get_point_id(), child.name, _fmt_units(pos)])
				ok = false
			if not block.is_empty():
				printerr("Monster patrol point %s/%s is inside block %s at %s" % [point.get_point_id(), child.name, block.id, _fmt_units(pos)])
				ok = false
		if path_count < 2:
			printerr("Monster point %s should expose at least 2 patrol child points." % point.get_point_id())
			ok = false
	return ok

func _is_patrol_path_marker(node: Node) -> bool:
	if not (node is Node2D):
		return false
	var normalized_name := String(node.name).to_snake_case().to_lower()
	if normalized_name.begins_with("patrol_path"):
		return false
	return normalized_name.begins_with("patrol") or normalized_name.contains("_patrol_")

func _check_outpost_candidates(root: Node, block_rects: Array[Dictionary], street_rects: Array[Dictionary], exception_rects: Array[Rect2]) -> bool:
	var candidates_root := root.get_node_or_null("WorldRoot/OutpostRoot/OutpostCandidates")
	if candidates_root == null:
		printerr("Missing outpost candidates root")
		return false
	var ok := true
	var candidates := candidates_root.find_children("*", "Node2D", true, false)
	var first_count := 0
	var second_count := 0
	for point in candidates:
		if not point.has_method("get_candidate_id"):
			continue
		var id := String(point.get_candidate_id())
		var pos: Vector2 = point.global_position
		var rect := Rect2(pos - OUTPOST_SIZE_UNITS * UNIT * 0.5, OUTPOST_SIZE_UNITS * UNIT)
		var has_exception := _rect_has_matching_exception(rect, exception_rects)
		var center_walkable: bool = root.player._is_position_walkable(pos)
		var center_blocked := _point_hits_generated_collision(root, pos)
		var touches_street := _rect_intersects_rects(rect, street_rects)
		var touches_block := _rect_intersects_rects(rect, block_rects)
		var has_entry_clearance := _outpost_has_player_clearance(root, rect)
		if point.outpost_tier == "first":
			first_count += 1
		else:
			second_count += 1
		if not has_exception:
			printerr("Outpost %s is not registered as an enterable exception: %s" % [id, _fmt_units(pos)])
			ok = false
		if not center_walkable:
			printerr("Outpost %s center is not in player walkable whitelist: %s" % [id, _fmt_units(pos)])
			ok = false
		if center_blocked:
			printerr("Outpost %s center remains inside generated block collision: %s" % [id, _fmt_units(pos)])
			ok = false
		if not touches_street:
			printerr("Outpost %s 10x8 area does not touch StreetWalkable: %s" % [id, _fmt_units(pos)])
			ok = false
		if not touches_block:
			push_warning("Outpost %s is not on a block; this is allowed but no longer tests the block exception rule." % id)
		if not has_entry_clearance:
			printerr("Outpost %s does not have enough player-radius clearance around the footprint." % id)
			ok = false
	if first_count < 3:
		printerr("Expected at least 3 first outpost candidates, got %s" % first_count)
		ok = false
	if second_count < 4:
		printerr("Expected at least 4 second outpost candidates, got %s" % second_count)
		ok = false
	return ok

func _point_in_rects(point: Vector2, rects: Array[Dictionary]) -> bool:
	return not _first_containing_rect(point, rects).is_empty()

func _first_containing_rect(point: Vector2, rects: Array[Dictionary]) -> Dictionary:
	for item in rects:
		var rect: Rect2 = item.rect
		if rect.has_point(point):
			return item
	return {}

func _point_in_plain_rects(point: Vector2, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _rect_has_matching_exception(rect: Rect2, exception_rects: Array[Rect2]) -> bool:
	for exception in exception_rects:
		if exception.position.distance_to(rect.position) < 0.1 and exception.size.distance_to(rect.size) < 0.1:
			return true
	return false

func _rect_intersects_rects(rect: Rect2, rects: Array[Dictionary]) -> bool:
	for item in rects:
		var other: Rect2 = item.rect
		if rect.intersects(other):
			return true
	return false

func _point_hits_generated_collision(root: Node, point: Vector2) -> bool:
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
			if absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y:
				return true
	return false

func _outpost_has_player_clearance(root: Node, rect: Rect2) -> bool:
	var radius := PLAYER_RADIUS_UNITS * UNIT
	var samples := [
		Vector2(rect.get_center().x, rect.position.y - radius),
		Vector2(rect.get_center().x, rect.position.y + rect.size.y + radius),
		Vector2(rect.position.x - radius, rect.get_center().y),
		Vector2(rect.position.x + rect.size.x + radius, rect.get_center().y),
		Vector2(rect.get_center().x, rect.position.y + radius),
		Vector2(rect.get_center().x, rect.position.y + rect.size.y - radius),
		Vector2(rect.position.x + radius, rect.get_center().y),
		Vector2(rect.position.x + rect.size.x - radius, rect.get_center().y),
	]
	for sample in samples:
		if not root.player._is_position_walkable(sample):
			return false
		if _circle_hits_generated_collision(root, sample, radius):
			return false
	return true

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

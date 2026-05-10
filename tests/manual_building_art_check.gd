extends SceneTree

const UNIT := 64.0
const YSORT_ITEM_Z_INDEX := 0

func _initialize() -> void:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		quit(1)
		return

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	var y_sort_root: Node = root.get_node_or_null("WorldRoot/YSortRoot")
	var player_root: Node = root.get_node_or_null("WorldRoot/PlayerRoot")
	var block_root: Node = root.get_node_or_null("WorldRoot/MapLayout/BlockSolid")

	if y_sort_root == null:
		printerr("Missing WorldRoot/YSortRoot.")
		ok = false
	elif not bool(y_sort_root.get("y_sort_enabled")):
		printerr("YSortRoot must have y_sort_enabled enabled.")
		ok = false
	if player_root == null:
		printerr("Missing PlayerRoot spawn/safe-zone anchor.")
		ok = false
	if block_root == null:
		printerr("Missing BlockSolid layout root.")
		ok = false

	var checked_blocks := 0
	var checked_buildings := 0
	if y_sort_root != null and block_root != null:
		for block in block_root.get_children():
			if not block.has_method("get_rect_id") or not block.has_method("get_rect_px"):
				continue
			var block_id := String(block.get_rect_id())
			var group_id := "%s_Buildings" % block_id
			var anchor := y_sort_root.get_node_or_null(group_id)
			if anchor == null:
				printerr("Missing building anchor for %s." % block_id)
				ok = false
				continue
			if String(anchor.get_meta("host_block_id", "")) != block_id:
				printerr("%s anchor must declare host_block_id." % group_id)
				ok = false
			var block_rect: Rect2 = block.get_rect_px(UNIT)
			var group_count := 0
			for child in y_sort_root.get_children():
				if String(child.get_meta("placement_group", "")) != group_id:
					continue
				group_count += 1
				checked_buildings += 1
				ok = _check_building_node(child, y_sort_root, block_id, group_id, block_rect) and ok
			if group_count <= 0:
				printerr("Expected at least one building on %s." % block_id)
				ok = false
			checked_blocks += 1

	root.queue_free()
	await process_frame

	if ok:
		print("Manual building art placement verified: %d blocks, %d buildings." % [checked_blocks, checked_buildings])
	quit(0 if ok else 1)


func _check_building_node(building: Node, y_sort_root: Node, block_id: String, group_id: String, block_rect: Rect2) -> bool:
	var ok := true
	if not (building is Node2D):
		printerr("%s must be a Node2D building root." % building.name)
		return false
	var building_2d := building as Node2D
	if building_2d.get_parent() != y_sort_root:
		printerr("%s must be a direct YSortRoot child for per-building depth sorting." % building.name)
		ok = false
	if building_2d.z_index != YSORT_ITEM_Z_INDEX:
		printerr("%s must keep z_index %d so YSort controls depth." % [building.name, YSORT_ITEM_Z_INDEX])
		ok = false
	if String(building.get_meta("host_block_id", "")) != block_id:
		printerr("%s must declare host_block_id %s." % [building.name, block_id])
		ok = false
	if String(building.get_meta("placement_group", "")) != group_id:
		printerr("%s must declare placement_group %s." % [building.name, group_id])
		ok = false
	if bool(building.get_meta("has_collision", true)):
		printerr("%s should be pure art in this sample." % building.name)
		ok = false
	if not block_rect.has_point(building_2d.global_position):
		printerr("%s footline sort point should stay inside host block: %s" % [building.name, building_2d.global_position])
		ok = false
	var sprite := building.get_node_or_null("ArtSprite") as Sprite2D
	if sprite == null:
		printerr("%s must contain an ArtSprite child." % building.name)
		ok = false
	else:
		if sprite.texture == null:
			printerr("%s has no building texture." % sprite.name)
			ok = false
		if sprite.z_index != YSORT_ITEM_Z_INDEX:
			printerr("%s must keep z_index %d so YSort controls depth." % [sprite.name, YSORT_ITEM_Z_INDEX])
			ok = false
		if _has_collision_child(sprite):
			printerr("%s should not contain collision nodes." % sprite.name)
			ok = false
	return ok


func _has_collision_child(node: Node) -> bool:
	if node is StaticBody2D or node is Area2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true
	for child in node.get_children():
		if _has_collision_child(child):
			return true
	return false

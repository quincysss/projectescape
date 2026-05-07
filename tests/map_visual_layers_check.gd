extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		quit(1)
		return

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var ok := true
	ok = _require_node(root, "WorldRoot/MapVisual/RoadVisual") and ok
	ok = _require_node(root, "WorldRoot/MapVisual/BlockVisual") and ok
	ok = _require_node(root, "WorldRoot/MapVisual/BuildingVisual") and ok
	ok = _require_node(root, "WorldRoot/MapVisual/PropVisual") and ok
	ok = _require_node(root, "WorldRoot/MapVisual/DecalVisual") and ok
	ok = _require_node(root, "WorldRoot/MapVisual/RoadVisual/ManualRoadPieces") and ok
	ok = _require_node(root, "WorldRoot/MapLights/StreetLights") and ok
	ok = _require_node(root, "WorldRoot/MapLights/BuildingLights") and ok
	ok = _require_node(root, "WorldRoot/MapLights/AmbientLights") and ok

	var road_visual: Node = root.get_node_or_null("WorldRoot/MapVisual/RoadVisual")
	var block_visual: Node = root.get_node_or_null("WorldRoot/MapVisual/BlockVisual")
	if road_visual == null:
		printerr("Expected MapVisual/RoadVisual node.")
		ok = false
	else:
		var generated_road_visual_count := 0
		for child in road_visual.get_children():
			if child.name.begins_with("RoadGround_") or child.name.begins_with("StreetDecor_"):
				generated_road_visual_count += 1
		if generated_road_visual_count <= 0:
			printerr("Expected generated road sprites under MapVisual/RoadVisual.")
			ok = false
	if block_visual == null:
		printerr("Expected MapVisual/BlockVisual node.")
		ok = false
	else:
		var expected_block_visual_count := _count_layout_rects(root, "WorldRoot/MapLayout/BlockSolid")
		var generated_block_visual_count := 0
		for child in block_visual.get_children():
			if child.name.ends_with("_Art") and child.get_node_or_null("SingleFill") != null:
				generated_block_visual_count += 1
		if generated_block_visual_count != expected_block_visual_count:
			printerr("Expected %d block art roots under MapVisual/BlockVisual, found %d." % [expected_block_visual_count, generated_block_visual_count])
			ok = false

	root.queue_free()
	await process_frame

	if ok:
		print("Map visual layers verified.")
	quit(0 if ok else 1)

func _require_node(root: Node, node_path: NodePath) -> bool:
	if root.get_node_or_null(node_path) != null:
		return true
	printerr("Missing node: %s" % node_path)
	return false

func _count_layout_rects(root: Node, node_path: NodePath) -> int:
	var layout_root := root.get_node_or_null(node_path)
	if layout_root == null:
		return 0
	var count := 0
	for child in layout_root.get_children():
		if child.has_method("get_rect_id"):
			count += 1
	return count

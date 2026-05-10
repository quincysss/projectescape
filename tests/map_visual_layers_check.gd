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
	ok = _require_interactable_visual(root, "container", "ContainerVisual") and ok
	ok = _require_interactable_visual(root, "material", "BuildMaterialVisual") and ok
	ok = _require_outpost_requirement_bubbles(root) and ok

	var road_visual: Node = root.get_node_or_null("WorldRoot/MapVisual/RoadVisual")
	var block_visual: Node = root.get_node_or_null("WorldRoot/MapVisual/BlockVisual")
	if road_visual == null:
		printerr("Expected MapVisual/RoadVisual node.")
		ok = false
	else:
		var generated_road_visual_count := 0
		for child in road_visual.get_children():
			if child.name.begins_with("RoadGround_") or child.name.begins_with("StreetDecor_") or child.has_meta("_generated_road_art"):
				generated_road_visual_count += 1
		if generated_road_visual_count <= 0:
			printerr("Expected generated road sprites under MapVisual/RoadVisual.")
			ok = false
	if block_visual == null:
		printerr("Expected MapVisual/BlockVisual node.")
		ok = false
	else:
		var expected_block_visual_count := _count_auto_layout_rects(root, "WorldRoot/MapLayout/BlockSolid")
		var generated_block_visual_count := 0
		for child in block_visual.get_children():
			if child.name.ends_with("_Art") and (
				child.get_node_or_null("SingleFill") != null
				or child.get_node_or_null("CustomFill") != null
				or _has_custom_tile(child)
			):
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

func _require_interactable_visual(root: Node, interact_type: String, visual_name: String) -> bool:
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.interact_type != interact_type:
			continue
		if interactable.get_node_or_null(visual_name) == null:
			printerr("Missing %s visual on %s." % [visual_name, interactable.name])
			return false
		if interactable.get_node_or_null("MarkerLabel") == null:
			printerr("Missing marker label on %s." % interactable.name)
			return false
		if interact_type == "material":
			var material_label := interactable.get_node_or_null("MarkerLabel") as Label
			var material_visual := interactable.get_node_or_null(visual_name) as Polygon2D
			if interactable.get_node_or_null("WorldLabel") != null:
				printerr("Expected material to omit the extra world label on %s." % interactable.name)
				return false
			if material_label == null or not String(interactable.display_name).begins_with(material_label.text):
				printerr("Expected material marker to show the material display name on %s." % interactable.name)
				return false
			if material_label.get_theme_font_size("font_size") < 38:
				printerr("Expected material marker font to be readable on %s." % interactable.name)
				return false
			if material_visual == null or material_visual.polygon.size() < 4:
				printerr("Expected material visual polygon on %s." % interactable.name)
				return false
			if material_visual != null and absf(material_visual.polygon[1].x - material_visual.polygon[3].x) < 250.0:
				printerr("Expected larger material visual on %s." % interactable.name)
				return false
		return true
	printerr("Missing interactable type for visual check: %s" % interact_type)
	return false

func _require_outpost_requirement_bubbles(root: Node) -> bool:
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.interact_type != "outpost":
			continue
		var bubbles: Node = interactable.get_node_or_null("OutpostRequirementBubbles")
		if bubbles == null:
			printerr("Missing outpost requirement bubbles on %s." % interactable.name)
			return false
		var labels: int = 0
		for child in bubbles.get_children():
			if child is Label:
				labels += 1
				var label := child as Label
				if label == null or not label.text.contains("/"):
					printerr("Expected requirement bubble label to show have/need on %s." % interactable.name)
					return false
				if label.get_theme_font_size("font_size") < 44:
					printerr("Expected larger requirement bubble font on %s." % interactable.name)
					return false
		if labels < 2:
			printerr("Expected at least two requirement bubbles on %s." % interactable.name)
			return false
		return true
	printerr("Missing outpost for requirement bubble check.")
	return false

func _count_auto_layout_rects(root: Node, node_path: NodePath) -> int:
	var layout_root := root.get_node_or_null(node_path)
	if layout_root == null:
		return 0
	var count := 0
	for child in layout_root.get_children():
		if child.has_method("get_rect_id") and child.get_node_or_null("ArtRoot/FoundationSprite") == null:
			count += 1
	return count

func _has_custom_tile(node: Node) -> bool:
	for child in node.get_children():
		if child.name.begins_with("CustomTile_"):
			return true
	return false

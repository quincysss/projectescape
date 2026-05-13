extends SceneTree

func _initialize() -> void:
	var ok := await _verify_overview_readable_overlay_scale()
	print("World readable overlay scale verified." if ok else "World readable overlay scale failed.")
	quit(0 if ok else 1)

func _verify_overview_readable_overlay_scale() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	root.camera.zoom = Vector2(0.10, 0.10)
	if root.run_director.context != null:
		root.run_director.context.active_safe_zone_id = "home"
	await process_frame
	root._update_readable_world_ui_scale()

	var container: Node = _first_interactable(root.container_root, "container")
	if container == null:
		printerr("Expected a spawned container.")
		ok = false
	else:
		var readable_root := container.get_node_or_null("ContainerReadableRoot") as Node2D
		var visual := container.get_node_or_null("ContainerReadableRoot/ContainerVisual") as Sprite2D
		var lifetime_label := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeLabel") as Label
		var lifetime_background := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeBarBackground") as ColorRect
		var name_label := container.get_node_or_null("ContainerReadableRoot/ContainerNameLabel") as Label
		var marker_label := container.get_node_or_null("MarkerLabel") as Label
		if readable_root == null or absf(readable_root.scale.x - 3.0) > 0.01:
			printerr("Expected overview formal container root to cap at 3.0x scale.")
			ok = false
		if visual == null or visual.texture == null:
			printerr("Expected overview container formal icon.")
			ok = false
		if lifetime_label == null or lifetime_background == null:
			printerr("Expected overview container lifetime bar and label.")
			ok = false
		if name_label == null:
			printerr("Expected overview container name label.")
			ok = false
		if marker_label != null:
			printerr("Expected formal container to omit the old marker label.")
			ok = false

	var material: Node = _first_interactable(root.outpost_root, "material")
	if material == null:
		printerr("Expected a spawned material.")
		ok = false
	else:
		var material_visual := material.get_node_or_null("BuildMaterialVisual") as Polygon2D
		var material_label := material.get_node_or_null("MarkerLabel") as Label
		if material_visual == null or absf(material_visual.scale.x - 3.0) > 0.01:
			printerr("Expected overview material visual to cap at 3.0x scale.")
			ok = false
		if material_label == null or absf(material_label.scale.x - 3.0) > 0.01:
			printerr("Expected overview material marker label to cap at 3.0x scale.")
			ok = false

	var outpost: Node = _first_interactable(root.outpost_root, "outpost")
	if outpost == null:
		printerr("Expected a spawned outpost.")
		ok = false
	else:
		var outpost_label := outpost.get_node_or_null("WorldLabel") as Label
		if outpost_label == null or absf(outpost_label.scale.x - 3.0) > 0.01:
			printerr("Expected overview outpost label to cap at 3.0x scale.")
			ok = false
		ok = _check_outpost_requirement_bubble_spacing(outpost) and ok

	if root.run_director.context != null:
		root.run_director.context.active_safe_zone_id = ""
	await process_frame
	root._update_readable_world_ui_scale()
	if container != null:
		var follow_root := container.get_node_or_null("ContainerReadableRoot") as Node2D
		if follow_root != null and absf(follow_root.scale.x - 1.0) > 0.01:
			printerr("Expected follow mode formal container root to return to normal scale.")
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _first_interactable(parent: Node, interact_type: String):
	for child in parent.get_children():
		if is_instance_valid(child) and child.get("interact_type") == interact_type:
			return child
	return null

func _check_outpost_requirement_bubble_spacing(outpost: Node) -> bool:
	var bubbles := outpost.get_node_or_null("OutpostRequirementBubbles")
	if bubbles == null:
		printerr("Expected outpost requirement bubbles.")
		return false
	if absf(bubbles.scale.x - 3.0) > 0.01 or absf(bubbles.scale.y - 3.0) > 0.01:
		printerr("Expected outpost requirement bubbles to scale as one centered panel.")
		return false
	var background := bubbles.get_node_or_null("RequirementBubbleBackground") as ColorRect
	if background == null:
		printerr("Expected outpost requirement panel background.")
		return false
	if background.color.a < 0.5 or background.color.a > 0.8:
		printerr("Expected outpost requirement panel background to use a compact translucent black fill.")
		return false
	var border := bubbles.get_node_or_null("RequirementBubbleBorder") as Line2D
	if border == null or border.default_color != Color("#D1B850"):
		printerr("Expected outpost requirement panel to use the project gold border.")
		return false
	var panel_center := background.position + background.size * 0.5
	if panel_center.length() > 0.01:
		printerr("Expected outpost requirement panel center to match outpost center. center=%s" % panel_center)
		return false
	var labels: Array[Label] = []
	var title: Label = null
	for child in bubbles.get_children():
		if child is Label:
			var label := child as Label
			if label.name == "RequirementBubbleTitle":
				title = label
			elif label.name.begins_with("RequirementBubbleMaterial"):
				labels.append(label)
	if title == null:
		printerr("Expected outpost requirement panel title.")
		return false
	if title.get_theme_font_size("font_size") < 52:
		printerr("Expected larger outpost requirement title font.")
		return false
	if labels.size() < 2:
		printerr("Expected at least two material requirement labels.")
		return false
	labels.sort_custom(func(a, b): return a.position.y < b.position.y)
	for label in labels:
		if not label.text.contains("/"):
			printerr("Expected material requirement label format.")
			return false
		if label.get_theme_font_size("font_size") < 36:
			printerr("Expected readable requirement material font.")
			return false
	for index in range(labels.size() - 1):
		var current := labels[index]
		var next := labels[index + 1]
		var current_height := current.size.y * current.scale.y
		var gap := next.position.y - current.position.y - current_height
		if gap < 12.0:
			printerr("Expected vertical requirement rows not to overlap.")
			return false
	var title_bottom := title.position.y + title.size.y * title.scale.y
	var first_material_top := labels[0].position.y
	if first_material_top <= title_bottom:
		printerr("Expected requirement title and material row to stay on separate lines. title_y=%s title_h=%s title_scale=%s material_y=%s material_h=%s material_scale=%s" % [title.position.y, title.size.y, title.scale.y, labels[0].position.y, labels[0].size.y, labels[0].scale.y])
		return false
	return true

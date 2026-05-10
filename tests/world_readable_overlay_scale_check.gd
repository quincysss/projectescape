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
		var visual := container.get_node_or_null("ContainerVisual") as ColorRect
		var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
		var lifetime_background := container.get_node_or_null("ContainerLifetimeLabelBackground") as ColorRect
		var marker_label := container.get_node_or_null("MarkerLabel") as Label
		if lifetime_label == null or absf(lifetime_label.scale.x - 3.0) > 0.01:
			printerr("Expected overview container lifetime label to cap at 3x scale.")
			ok = false
		if visual != null and lifetime_label != null and absf(lifetime_label.position.y - (visual.size.y * 0.5 + 8.0)) > 0.01:
			printerr("Expected scaled lifetime label to keep normal offset from container.")
			ok = false
		if lifetime_background != null and lifetime_label != null and lifetime_background.position != lifetime_label.position:
			printerr("Expected lifetime label and background to stay grouped.")
			ok = false
		if marker_label == null or absf(marker_label.scale.x - 3.0) > 0.01:
			printerr("Expected overview container marker label to cap at 3x scale.")
			ok = false

	var outpost: Node = _first_interactable(root.outpost_root, "outpost")
	if outpost == null:
		printerr("Expected a spawned outpost.")
		ok = false
	else:
		var outpost_label := outpost.get_node_or_null("WorldLabel") as Label
		if outpost_label == null or absf(outpost_label.scale.x - 3.0) > 0.01:
			printerr("Expected overview outpost label to cap at 3x scale.")
			ok = false
		ok = _check_outpost_requirement_bubble_spacing(outpost) and ok

	if root.run_director.context != null:
		root.run_director.context.active_safe_zone_id = ""
	await process_frame
	root._update_readable_world_ui_scale()
	if container != null:
		var follow_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
		if follow_label != null and absf(follow_label.scale.x - 1.0) > 0.01:
			printerr("Expected follow mode container label to return to normal scale.")
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
	var labels: Array[Label] = []
	for child in bubbles.get_children():
		if child is Label:
			labels.append(child)
	if labels.size() < 2:
		printerr("Expected at least two requirement bubble labels.")
		return false
	labels.sort_custom(func(a, b): return a.position.x < b.position.x)
	for label in labels:
		if label.get_theme_font_size("font_size") < 44:
			printerr("Expected larger requirement bubble font.")
			return false
	for index in range(labels.size() - 1):
		var current := labels[index]
		var next := labels[index + 1]
		var current_width := current.size.x * current.scale.x
		var gap := next.position.x - current.position.x - current_width
		if gap < 20.0:
			printerr("Expected scaled requirement bubbles not to overlap.")
			return false
	return true

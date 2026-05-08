extends SceneTree

func _initialize() -> void:
	var ok := await _verify_container_spawn_and_visuals()
	print("Container spawn and visual lifetime verified." if ok else "Container spawn and visual lifetime failed.")
	quit(0 if ok else 1)

func _verify_container_spawn_and_visuals() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	ok = _check_no_duplicate_container_positions(root) and ok
	var first_container = _first_container(root)
	if first_container == null:
		printerr("Expected at least one spawned container.")
		ok = false
	else:
		ok = _check_container_visual(root, first_container) and ok

	var point_count: int = root._get_container_spawn_points().size()
	for index in range(point_count + 3):
		root.container_spawn_controller.spawn_next_container()
	ok = _check_no_duplicate_container_positions(root) and ok

	var before_count := _container_count(root)
	if first_container != null:
		var duplicate = root.container_spawn_controller.spawn_container(first_container.global_position)
		if duplicate != null:
			printerr("Expected direct spawn on an occupied point to be rejected.")
			ok = false
		if _container_count(root) != before_count:
			printerr("Expected occupied-point spawn rejection to keep container count unchanged.")
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _check_container_visual(root: Node, container: Node) -> bool:
	var visual := container.get_node_or_null("ContainerWhiteboxVisual") as ColorRect
	var fill := container.get_node_or_null("ContainerLifetimeFill") as ColorRect
	var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
	var marker_label := container.get_node_or_null("WhiteboxMarkerLabel") as Label
	var ok := true
	if visual == null or fill == null:
		printerr("Expected container visual and lifetime fill nodes.")
		ok = false
	if lifetime_label == null:
		printerr("Expected container lifetime seconds label.")
		ok = false
	if marker_label == null or marker_label.get_theme_font_size("font_size") < 48:
		printerr("Expected larger container grade marker label.")
		ok = false
	if visual != null and visual.size.x < 200.0:
		printerr("Expected larger container visual size.")
		ok = false
	if visual != null and fill != null:
		container.payload.lifetime = float(container.payload.lifetime_max) * 0.5
		root._refresh_container_lifetime_visual(container)
		if absf(fill.size.x - visual.size.x * 0.5) > 0.5:
			printerr("Expected lifetime fill width to track remaining lifetime.")
			ok = false
		if lifetime_label != null and not lifetime_label.text.ends_with("s"):
			printerr("Expected lifetime label to show seconds.")
			ok = false
	return ok

func _check_no_duplicate_container_positions(root: Node) -> bool:
	var seen := {}
	for container in root.container_root.get_children():
		if not is_instance_valid(container) or container.get("interact_type") != "container":
			continue
		var key := "%d,%d" % [int(round(container.global_position.x)), int(round(container.global_position.y))]
		if seen.has(key):
			printerr("Duplicate container spawn position: %s" % key)
			return false
		seen[key] = true
	return true

func _first_container(root: Node):
	for container in root.container_root.get_children():
		if is_instance_valid(container) and container.get("interact_type") == "container":
			return container
	return null

func _container_count(root: Node) -> int:
	var count := 0
	for container in root.container_root.get_children():
		if is_instance_valid(container) and container.get("interact_type") == "container":
			count += 1
	return count

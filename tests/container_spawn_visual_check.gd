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
		root._open_container(first_container)
		first_container.payload.lifetime = 0.01
		root._update_container_lifetimes(1.0)
		if root.interactables.has(first_container) or (is_instance_valid(first_container) and first_container.visible):
			printerr("Expected opened container to keep counting down and expire.")
			ok = false
		if root.loot_panel.visible:
			printerr("Expected expired opened container to close loot panel.")
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _check_container_visual(root: Node, container: Node) -> bool:
	var visual := container.get_node_or_null("ContainerVisual") as ColorRect
	var fill := container.get_node_or_null("ContainerLifetimeFill") as ColorRect
	var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
	var lifetime_background := container.get_node_or_null("ContainerLifetimeLabelBackground") as ColorRect
	var nameplate_label := container.get_node_or_null("ContainerNameplateLabel") as Label
	var nameplate_background := container.get_node_or_null("ContainerNameplateBackground") as ColorRect
	var marker_label := container.get_node_or_null("MarkerLabel") as Label
	var ok := true
	if visual == null or fill == null:
		printerr("Expected container visual and lifetime fill nodes.")
		ok = false
	if lifetime_label == null:
		printerr("Expected container lifetime seconds label.")
		ok = false
	if lifetime_background == null:
		printerr("Expected readable lifetime label background.")
		ok = false
	if nameplate_label != null or nameplate_background != null:
		printerr("Expected container to omit the extra nameplate.")
		ok = false
	if marker_label == null or ["S", "A", "B", "C"].has(marker_label.text):
		printerr("Expected container type marker instead of S/A/B/C grade marker.")
		ok = false
	elif marker_label.get_theme_font_size("font_size") < 40:
		printerr("Expected container marker font to stay readable in home overview.")
		ok = false
	if visual != null and visual.size.x < 120.0:
		printerr("Expected configured container visual size.")
		ok = false
	if not container.payload.has("type_id") or not container.payload.has("open_time"):
		printerr("Expected container payload to include configured type_id and open_time.")
		ok = false
	if not container.payload.has("container_color") or container.payload.container_color != Color("#3A8DFF"):
		printerr("Expected configured unified blue container color.")
		ok = false
	if visual != null and fill != null:
		container.payload.lifetime = float(container.payload.lifetime_max) * 0.5
		root._refresh_container_lifetime_visual(container)
		if absf(fill.size.x - visual.size.x * 0.5) > 0.5:
			printerr("Expected lifetime fill width to track remaining lifetime.")
			ok = false
		if lifetime_label != null and (not lifetime_label.text.begins_with("剩 ") or not lifetime_label.text.ends_with("s")):
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

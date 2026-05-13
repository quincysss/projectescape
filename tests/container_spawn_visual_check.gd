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
		if not root.interactables.has(first_container) or not (is_instance_valid(first_container) and first_container.visible):
			printerr("Expected opened container lifetime to pause while transfer UI is open.")
			ok = false
		if not root.loot_panel.visible:
			printerr("Expected paused opened container to keep loot panel open.")
			ok = false
		root._close_loot_transfer()
		root._update_container_lifetimes(1.0)
		if root.interactables.has(first_container) or (is_instance_valid(first_container) and first_container.visible):
			printerr("Expected container lifetime to resume and expire after transfer UI closes.")
			ok = false

	root.queue_free()
	await process_frame
	return ok

func _check_container_visual(root: Node, container: Node) -> bool:
	var readable_root := container.get_node_or_null("ContainerReadableRoot") as Node2D
	var visual := container.get_node_or_null("ContainerReadableRoot/ContainerVisual") as Sprite2D
	var fill := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeFill") as ColorRect
	var lifetime_label := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeLabel") as Label
	var lifetime_bar := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeBarBackground") as ColorRect
	var name_label := container.get_node_or_null("ContainerReadableRoot/ContainerNameLabel") as Label
	var marker_label := container.get_node_or_null("MarkerLabel") as Label
	var ok := true
	if readable_root == null:
		printerr("Expected formal readable container root.")
		ok = false
	if visual == null or visual.texture == null or fill == null:
		printerr("Expected formal container icon and lifetime fill nodes.")
		ok = false
	if lifetime_label == null:
		printerr("Expected container lifetime seconds label.")
		ok = false
	if lifetime_bar == null:
		printerr("Expected readable lifetime progress bar background.")
		ok = false
	if name_label == null:
		printerr("Expected formal container name label.")
		ok = false
	if container.get_node_or_null("ContainerReadableRoot/ContainerNameUnderline") != null:
		printerr("Expected formal container name underline to be removed.")
		ok = false
	if marker_label != null:
		printerr("Expected formal container visual to omit the old center marker label.")
		ok = false
	if visual != null and visual.texture != null and visual.scale.x * visual.texture.get_width() < 120.0:
		printerr("Expected configured container visual size.")
		ok = false
	if not container.payload.has("type_id") or not container.payload.has("open_time"):
		printerr("Expected container payload to include configured type_id and open_time.")
		ok = false
	if not container.payload.has("container_color") or container.payload.container_color != Color("#3A8DFF"):
		printerr("Expected configured unified blue container color.")
		ok = false
	if lifetime_bar != null and fill != null:
		container.payload.lifetime = float(container.payload.lifetime_max) * 0.5
		root._refresh_container_lifetime_visual(container)
		if absf(fill.size.x - lifetime_bar.size.x * 0.5) > 0.5:
			printerr("Expected lifetime fill width to track remaining lifetime.")
			ok = false
	if lifetime_label != null and not lifetime_label.text.ends_with("s"):
		printerr("Expected lifetime label to show seconds.")
		ok = false
	if name_label != null and name_label.get_theme_color("font_color") != Color("#FFC547"):
		printerr("Expected container name label color #FFC547.")
		ok = false
	if lifetime_label != null and lifetime_label.get_theme_color("font_color") != Color("#FEDC54"):
		printerr("Expected container lifetime label color #FEDC54.")
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

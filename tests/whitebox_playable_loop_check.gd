extends SceneTree

func _initialize() -> void:
	var ok := await _verify_whitebox_loop()
	quit(0 if ok else 1)

func _verify_whitebox_loop() -> bool:
	var game_state = get_root().get_node("GameState")
	game_state.clear_warehouse()
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	if root.player == null:
		printerr("Whitebox player missing")
		return false
	if root.run_director.context == null:
		printerr("Run context missing")
		return false
	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	await process_frame
	if not root.vision_mask.visible:
		printerr("Expected vision mask visible after leaving home")
		return false
	root.run_director.on_safe_zone_entered("home")
	await process_frame
	if root.vision_mask.visible:
		printerr("Expected vision mask hidden inside home")
		return false
	if root.interactables.is_empty():
		printerr("Expected interactables")
		return false

	var container = _find_interactable(root, "container")
	if container == null:
		printerr("Expected a loot container")
		return false
	root._open_container(container)
	root._take_all_loot()
	if root.run_director.inventory_component.items.is_empty():
		printerr("Expected loot to enter backpack")
		return false
	if root.interactables.has(container) or (is_instance_valid(container) and container.visible):
		printerr("Expected looted container to disappear")
		return false

	var expiring_container = _find_interactable(root, "container")
	if expiring_container == null:
		printerr("Expected another container for lifetime check")
		return false
	expiring_container.payload.lifetime = 0.01
	root._update_container_lifetimes(1.0)
	if root.interactables.has(expiring_container) or (is_instance_valid(expiring_container) and expiring_container.visible):
		printerr("Expected expired container to disappear")
		return false

	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()

	for interactable in root.interactables.duplicate():
		if is_instance_valid(interactable) and interactable.interact_type == "material":
			root._pick_material(interactable)

	var repaired := 0
	for interactable in root.interactables.duplicate():
		if is_instance_valid(interactable) and interactable.interact_type == "outpost":
			root._try_repair_outpost(interactable)
			if interactable.payload.get("repaired", false):
				repaired += 1

	if repaired != 2:
		printerr("Expected 2 repaired outposts, got %s" % repaired)
		return false
	if not root.run_director.context.is_extraction_unlocked:
		printerr("Expected extraction unlocked")
		return false

	root.run_director.on_safe_zone_entered("home")
	root._deposit_all()
	root._try_extract()
	await process_frame
	if game_state.warehouse_items.is_empty():
		printerr("Expected warehouse items after extraction")
		return false
	print("Whitebox playable loop verified.")
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

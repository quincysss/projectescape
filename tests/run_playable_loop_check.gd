extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_loop()
	quit(0 if ok else 1)

func _verify_run_loop() -> bool:
	var game_state = get_root().get_node("GameState")
	await process_frame
	game_state.reset_day(1)
	game_state.mark_second_day_black_tide_reveal_seen()
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
		printerr("Run player missing")
		return false
	if root.run_director.context == null:
		printerr("Run context missing")
		return false
	root.run_director.inventory_component.setup(64, 100.0)
	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	await process_frame
	if not root.vision_mask.visible:
		printerr("Expected exploration fog visible after leaving home")
		return false
	root.run_director.on_safe_zone_entered("home")
	await process_frame
	if not root.vision_mask.visible:
		printerr("Expected exploration fog visible inside home")
		return false
	if root.interactables.is_empty():
		printerr("Expected interactables")
		return false

	var container = _find_interactable(root, "container")
	if container == null:
		printerr("Expected a loot container")
		return false
	root._on_interactable_entered(container)
	Input.action_press("interact")
	root._try_interact()
	Input.action_release("interact")
	root._update_active_interaction(0.2)
	if root.interaction_progress_controller.is_active() or root.loot_panel.visible:
		printerr("Expected releasing interact to cancel held container open")
		return false
	root._on_interactable_entered(container)
	Input.action_press("interact")
	root._try_interact()
	root._on_interactable_exited(container)
	Input.action_release("interact")
	if root.interaction_progress_controller.is_active() or root.loot_panel.visible:
		printerr("Expected leaving range to cancel held container open")
		return false
	root._on_interactable_entered(container)
	Input.action_press("interact")
	root._try_interact()
	root._update_active_interaction(float(container.payload.get("open_time", root.CONTAINER_OPEN_HOLD_SECONDS)) + 0.1)
	Input.action_release("interact")
	if not root.loot_panel.visible or not root.inventory_panel.visible:
		printerr("Expected held container interaction to open loot and backpack panels")
		return false
	root._on_interactable_exited(container)
	if root.loot_panel.visible or root.inventory_panel.visible:
		printerr("Expected leaving container range to close loot and backpack panels")
		return false
	root._on_interactable_entered(container)
	Input.action_press("interact")
	root._try_interact()
	root._update_active_interaction(float(container.payload.get("open_time", root.CONTAINER_OPEN_HOLD_SECONDS)) + 0.1)
	Input.action_release("interact")
	root._take_all_loot()
	if root.loot_panel.visible or root.inventory_panel.visible:
		printerr("Expected empty container to close loot and backpack panels")
		return false
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
			var before_count: int = root.run_director.inventory_component.repair_material_items.size()
			root._pick_material(interactable)
			if root.loot_panel.visible:
				printerr("Expected material pickup to avoid the loot panel")
				return false
			if root.run_director.inventory_component.repair_material_items.size() <= before_count:
				printerr("Expected material pickup to enter material backpack immediately")
				return false

	var repaired := 0
	for interactable in root.interactables.duplicate():
		if is_instance_valid(interactable) and interactable.interact_type == "outpost":
			root._on_interactable_entered(interactable)
			Input.action_press("interact")
			root._try_interact()
			root._update_active_interaction(root.OUTPOST_REPAIR_HOLD_SECONDS + 0.1)
			Input.action_release("interact")
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
	var warehouse_count_before_return: int = game_state.get_warehouse_items_snapshot().size()
	Input.action_press("extract")
	root._try_extract()
	root._update_active_interaction(root.EXTRACTION_HOLD_SECONDS + 0.1)
	Input.action_release("extract")
	await process_frame
	if game_state.get_warehouse_items_snapshot().size() != warehouse_count_before_return:
		printerr("Expected extraction to wait for settlement return loading before writing warehouse")
		return false
	if root.settlement_result_screen == null or not is_instance_valid(root.settlement_result_screen):
		printerr("Expected settlement result screen after extraction")
		return false
	if root.settlement_result_screen.title_label.text != "成功返回404哨所":
		printerr("Expected success settlement title before return loading")
		return false
	root.settlement_result_screen.return_button.emit_signal("pressed")
	await process_frame
	if root.return_to_base_loading_screen == null or not is_instance_valid(root.return_to_base_loading_screen):
		printerr("Expected return-to-base loading screen after settlement button")
		return false
	for _index in range(160):
		if root.return_to_base_loading_screen.is_ready_to_continue():
			break
		await process_frame
		await physics_frame
	if not root.return_to_base_loading_screen.is_ready_to_continue():
		printerr("Expected return-to-base loading to reach ready state")
		return false
	if game_state.get_warehouse_items_snapshot().size() <= warehouse_count_before_return:
		printerr("Expected warehouse items after return loading commits settlement")
		return false
	root.return_to_base_loading_screen._input(_key(KEY_ENTER))
	await process_frame
	print("Run playable loop verified.")
	return true

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

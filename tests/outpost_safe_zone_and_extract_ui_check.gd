extends SceneTree

func _initialize() -> void:
	var ok := await _verify_outpost_safe_zone_and_extract_ui()
	print("Outpost safe zone and extract UI verified." if ok else "Outpost safe zone and extract UI failed.")
	quit(0 if ok else 1)

func _verify_outpost_safe_zone_and_extract_ui() -> bool:
	var game_state = get_root().get_node("GameState")
	await process_frame
	game_state.reset_day(1)
	game_state.mark_second_day_black_tide_reveal_seen()
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	if root.deposit_button.get_parent() == root.inventory_panel or root.extract_button.get_parent() == root.inventory_panel:
		printerr("Expected home action buttons outside backpack panel.")
		return false
	if root.deposit_button.get_parent() != root.home_storage_panel or root.extract_button.get_parent() != root.home_storage_panel:
		printerr("Expected home action buttons under home storage panel.")
		return false
	if root.inventory_panel.visible or root.home_storage_panel.visible:
		printerr("Expected backpack and home storage to stay closed when entering home.")
		return false
	if not root.home_backpack_hint_label.visible or not root.home_backpack_hint_label.text.contains("TAB"):
		printerr("Expected home backpack hint below extraction signal.")
		return false
	if root.extract_button.visible:
		printerr("Expected storage-side extract button to stay hidden.")
		return false
	root._toggle_inventory_panel()
	await process_frame
	if not root.inventory_panel.visible or not root.home_storage_panel.visible:
		printerr("Expected TAB to open backpack and home storage at home.")
		return false
	if root.home_backpack_hint_label.visible:
		printerr("Expected home backpack hint hidden while backpack is open.")
		return false
	root._toggle_inventory_panel()
	await process_frame
	if root.inventory_panel.visible or root.home_storage_panel.visible:
		printerr("Expected manual backpack close to also close home storage.")
		return false
	root._toggle_inventory_panel()
	await process_frame
	if not root.inventory_panel.visible or not root.home_storage_panel.visible:
		printerr("Expected TAB to reopen backpack and home storage before leaving home.")
		return false

	var outpost = _find_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected an outpost interactable.")
		return false

	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	await process_frame
	if root.inventory_panel.visible or root.home_storage_panel.visible:
		printerr("Expected backpack and home storage to auto-close after leaving home.")
		return false
	root.run_director.stability_component.set_stability(50.0)
	outpost.payload.repaired = true
	outpost.payload.repair_state = "ACTIVE"
	root._on_interactable_entered(outpost)
	await process_frame

	if root.run_director.context.active_safe_zone_id == outpost.interact_id:
		printerr("Expected outpost interact radius to stay separate from safe zone.")
		return false

	root.player.global_position = outpost.global_position
	root._on_outpost_safe_zone_body_entered(outpost, root.player)
	await process_frame

	if root.run_director.context.active_safe_zone_id != outpost.interact_id:
		printerr("Expected repaired outpost to become active safe zone.")
		return false
	if not root.run_director.stability_component.is_recovering:
		printerr("Expected stability recovery inside repaired outpost.")
		return false
	if not root.vision_mask.visible:
		printerr("Expected exploration fog visible inside repaired outpost.")
		return false

	root._on_outpost_safe_zone_body_exited(outpost, root.player)
	await process_frame
	if root.run_director.context.active_safe_zone_id != "":
		printerr("Expected outpost safe zone to clear after exit.")
		return false
	if not root.run_director.stability_component.is_decaying:
		printerr("Expected stability decay after leaving repaired outpost.")
		return false

	root.run_director.context.is_extraction_unlocked = true
	root.run_director.state_machine.is_extraction_unlocked = true
	root.player.global_position = root.player_root.global_position
	root.run_director.on_safe_zone_entered("home")
	root._refresh_ui()
	await process_frame
	if root.extraction_status_button.disabled:
		printerr("Expected extraction signal button enabled at home after unlock.")
		return false
	if not root.extraction_status_label.text.contains("长按 E"):
		printerr("Expected extraction signal to explain held E extraction.")
		return false
	if not root.extraction_progress_bar.visible or root.extraction_progress_bar.value != 0.0:
		printerr("Expected extraction progress bar ready at zero.")
		return false
	var progress_rect := Rect2(root.extraction_progress_bar.position, root.extraction_progress_bar.size)
	var status_rect := Rect2(Vector2.ZERO, root.extraction_status_panel.size)
	if not status_rect.encloses(progress_rect) or progress_rect.end.y > 46.0:
		printerr("Expected extraction progress bar inside the signal frame, got %s in %s." % [progress_rect, status_rect])
		return false
	Input.action_press("extract")
	root._try_extract()
	root._update_active_interaction(root.EXTRACTION_HOLD_SECONDS * 0.5)
	root._refresh_ui()
	await process_frame
	if root.extraction_progress_bar.value <= 0.0 or not root.extraction_status_label.text.contains("撤离中"):
		printerr("Expected extraction signal progress while holding E.")
		return false
	Input.action_release("extract")
	root._update_active_interaction(0.1)
	await process_frame
	if root.interaction_progress_controller.is_active():
		printerr("Expected extraction hold to cancel when E is released.")
		return false

	root.queue_free()
	await process_frame
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

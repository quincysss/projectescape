extends SceneTree

func _initialize() -> void:
	var ok := await _verify_locked_outpost_storage()
	if ok:
		ok = await _verify_outpost_storage()
	await _shutdown_audio()
	await process_frame
	print("Outpost storage verified." if ok else "Outpost storage failed.")
	quit(0 if ok else 1)

func _verify_locked_outpost_storage() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	_prepare_profile(game_state, "OutpostStorageLocked")
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var outpost = _find_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected an outpost interactable.")
		return false

	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	outpost.payload.repaired = true
	outpost.payload.repair_state = "ACTIVE"
	root.run_director.context.outpost_states[outpost.interact_id] = "repaired"
	root._activate_outpost_safe_zone(outpost)
	root.player.global_position = outpost.global_position
	root._on_outpost_safe_zone_body_entered(outpost, root.player)
	await process_frame

	if root.active_outpost_storage_id != "":
		printerr("Expected outpost storage to stay inactive without research.")
		return false
	if root.run_director.outpost_storage_controller.has_storage(outpost.interact_id):
		printerr("Expected no outpost storage instance without research.")
		return false
	if root.inventory_panel.visible or root.home_storage_panel.visible:
		printerr("Expected backpack and storage panels to stay closed without outpost storage research.")
		return false

	root.queue_free()
	await process_frame
	await process_frame
	return true

func _verify_outpost_storage() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	_prepare_profile(game_state, "OutpostStorageUnlocked")
	if game_state != null:
		game_state.research_levels["outpost_storage_slots"] = 2
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.setup(64, 100.0)
	var outpost = _find_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected an outpost interactable.")
		return false

	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	outpost.payload.repaired = true
	outpost.payload.repair_state = "ACTIVE"
	root.run_director.context.outpost_states[outpost.interact_id] = "repaired"
	root._activate_outpost_safe_zone(outpost)
	root.player.global_position = outpost.global_position
	root._on_outpost_safe_zone_body_entered(outpost, root.player)
	await process_frame

	if root.active_outpost_storage_id != outpost.interact_id:
		printerr("Expected active outpost storage id.")
		return false
	var storage = root.run_director.outpost_storage_controller.get_storage(outpost.interact_id)
	if storage == null or storage.max_slots != 2:
		printerr("Expected researched outpost storage capacity to be 2 slots.")
		return false
	if not root.inventory_panel.visible or not root.home_storage_panel.visible:
		printerr("Expected backpack and outpost storage to auto-open.")
		return false
	if root.extract_button.visible:
		printerr("Expected extract button hidden in outpost storage UI.")
		return false

	if not root.run_director.debug_add_item(_item("scrap_metal", "废金属")):
		printerr("Expected debug item add.")
		return false
	root._on_inventory_item_meta_clicked("inventory:0")
	if root.selected_inventory_index != 0 or root.run_director.inventory_component.items.size() != 1:
		printerr("Expected inventory item to become selected before outpost storage transfer.")
		return false
	root.deposit_button.pressed.emit()
	if root.run_director.inventory_component.items.size() != 0:
		printerr("Expected inventory item to move into outpost storage.")
		return false
	if root.run_director.get_outpost_storage_items_snapshot(outpost.interact_id).size() != 1:
		printerr("Expected one item in outpost storage.")
		return false

	var extraction_result: Dictionary = root.run_end_controller.result_builder.build_extraction_result(root.run_director)
	if not _has_item(extraction_result.get("warehouse_items", []), "scrap_metal"):
		printerr("Expected extraction result to include outpost storage item.")
		return false
	var death_result: Dictionary = root.run_end_controller.result_builder.build_death_result(root.run_director, "test")
	if not _has_item(death_result.get("warehouse_items", []), "scrap_metal"):
		printerr("Expected death result to retain outpost storage item.")
		return false
	if game_state != null:
		game_state.clear_warehouse()
		game_state.apply_run_result(death_result)
		if not _has_item(game_state.get_warehouse_items_snapshot(), "scrap_metal"):
			printerr("Expected failed extraction/death to bring outpost storage into meta warehouse.")
			return false

	root._on_home_storage_item_meta_clicked("storage:0")
	if root.run_director.inventory_component.items.size() != 1:
		printerr("Expected outpost storage item to move back into inventory.")
		return false
	if root.run_director.get_outpost_storage_items_snapshot(outpost.interact_id).size() != 0:
		printerr("Expected outpost storage to be empty after withdraw.")
		return false

	root._on_outpost_safe_zone_body_exited(outpost, root.player)
	await process_frame
	if root.inventory_panel.visible or root.home_storage_panel.visible:
		printerr("Expected backpack and outpost storage to close after leaving outpost.")
		return false

	root.queue_free()
	await process_frame
	await process_frame
	return true

func _item(item_id: String, display_name: String) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": 1.0,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
	}

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

func _has_item(items: Array, item_id: String) -> bool:
	for item in items:
		if item is Dictionary and str(item.get("item_id", "")) == item_id:
			return true
	return false

func _prepare_profile(game_state, profile_name: String) -> void:
	if game_state == null:
		return
	if game_state.has_method("reset_local_data_debug_only"):
		game_state.reset_local_data_debug_only()
	if game_state.has_method("create_profile"):
		game_state.create_profile(profile_name)
	if game_state.has_method("reset_research"):
		game_state.reset_research()

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

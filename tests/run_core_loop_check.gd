extends SceneTree

func _initialize() -> void:
	if not _verify_scene_loads():
		quit(1)
		return

	var scene := load("res://scenes/debug/DebugCoreLoop.tscn")
	if scene == null:
		printerr("Failed to load DebugCoreLoop.tscn")
		quit(1)
		return

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var director = root.get_node("RunDirector")
	var ok: bool = await _verify_run_scene_points()
	if ok:
		ok = _verify_invalid_extraction_guard(director)
	if ok:
		ok = _verify_inventory_weight_storage(director)
	if ok:
		ok = await _verify_safe_zone_and_stability(director)
	if ok:
		ok = _verify_success_path(director)
	if ok:
		ok = _verify_death_path(director)

	root.queue_free()
	await process_frame
	quit(0 if ok else 1)

func _verify_scene_loads() -> bool:
	var scene_paths := [
		"res://scenes/boot/BootScene.tscn",
		"res://scenes/base/BaseScene.tscn",
		"res://scenes/run/RunScene.tscn",
		"res://scenes/debug/DebugCoreLoop.tscn",
	]
	for scene_path in scene_paths:
		var scene = load(scene_path)
		if scene == null:
			printerr("Failed to load %s" % scene_path)
			return false
	print("Scene load check verified.")
	return true

func _verify_run_scene_points() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var director = root.get_node("RunDirector")
	if not director.start_new_run():
		printerr("RunScene start_new_run failed")
		root.queue_free()
		return false

	var context = director.context
	var first_candidates = get_nodes_in_group("first_outpost_candidates")
	var second_candidates = get_nodes_in_group("second_outpost_candidates")
	if first_candidates.size() < 3:
		printerr("Expected at least 3 first outpost candidates, got %s" % first_candidates.size())
		root.queue_free()
		return false
	if second_candidates.size() < 4:
		printerr("Expected at least 4 second outpost candidates, got %s" % second_candidates.size())
		root.queue_free()
		return false
	if context.player_stability != 100.0:
		printerr("Expected stability 100, got %s" % context.player_stability)
		root.queue_free()
		return false
	if context.home_storage.size() != 4:
		printerr("Expected 4 home storage slots, got %s" % context.home_storage.size())
		root.queue_free()
		return false
	if context.selected_outpost_positions.size() != 2:
		printerr("Expected selected outpost positions for 2 outposts.")
		root.queue_free()
		return false

	root.queue_free()
	await process_frame
	print("RunScene point-based initialization verified.")
	return true

func _verify_invalid_extraction_guard(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run for invalid extraction guard failed")
		return false
	director.on_extraction_started()
	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "OBSERVE":
		printerr("Expected invalid extraction to remain OBSERVE, got %s" % state.get("current_phase"))
		return false
	print("Invalid extraction guard verified.")
	return true

func _verify_inventory_weight_storage(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run for inventory check failed")
		return false

	var inventory = director.inventory_component
	var weight = director.weight_component
	var storage = director.home_storage_component
	if inventory == null:
		printerr("Expected InventoryComponent to be wired.")
		return false
	if weight == null:
		printerr("Expected WeightComponent to be wired.")
		return false
	if storage == null:
		printerr("Expected HomeStorageComponent to be wired.")
		return false

	if not director.debug_add_item(_item("scrap_metal", 3, 2.0, 5)):
		printerr("Expected scrap stack add to pass.")
		return false
	if inventory.items.size() != 1 or int(inventory.items[0].amount) != 3:
		printerr("Expected one stacked scrap slot.")
		return false
	if not is_equal_approx(weight.current_weight, 6.0):
		printerr("Expected weight 6, got %s" % weight.current_weight)
		return false

	if not director.debug_add_item(_item("heavy_battery", 1, 12.0, 1)):
		printerr("Expected heavy battery add to pass.")
		return false
	if weight.current_stage != weight.WeightStage.HEAVY:
		printerr("Expected HEAVY stage, got %s" % weight.current_stage)
		return false
	if director.debug_add_item(_item("heavy_battery", 1, 12.0, 1)):
		printerr("Expected over-weight item add to fail.")
		return false
	if not is_equal_approx(weight.current_weight, 18.0):
		printerr("Expected failed add to preserve weight 18, got %s" % weight.current_weight)
		return false

	if not director.deposit_inventory_item_to_home(0):
		printerr("Expected deposit first item to pass.")
		return false
	if inventory.items.size() != 1:
		printerr("Expected inventory item removed after deposit.")
		return false
	if storage.items.size() != 1:
		printerr("Expected one home storage item.")
		return false
	if not is_equal_approx(weight.current_weight, 12.0):
		printerr("Expected weight 12 after deposit, got %s" % weight.current_weight)
		return false

	inventory.setup(1, 100.0)
	if not inventory.add_item(_item("slot_a", 1, 1.0, 1)):
		printerr("Expected first single-slot add to pass.")
		return false
	if inventory.add_item(_item("slot_b", 1, 1.0, 1)):
		printerr("Expected no-slot add to fail.")
		return false

	director.start_new_run()
	for i in range(4):
		if not director.debug_add_item(_item("stored_%s" % i, 1, 1.0, 1)):
			printerr("Expected storage fill source item %s to add." % i)
			return false
		if not director.deposit_inventory_item_to_home(0):
			printerr("Expected storage slot %s to fill." % i)
			return false
	if not director.debug_add_item(_item("overflow_source", 1, 1.0, 1)):
		printerr("Expected overflow source add to pass.")
		return false
	if director.deposit_inventory_item_to_home(0):
		printerr("Expected full home storage deposit to fail.")
		return false
	if director.inventory_component.items.size() != 1:
		printerr("Expected failed full-storage deposit to keep source item.")
		return false

	print("Inventory, weight, and home storage verified.")
	return true

func _item(item_id: String, amount: int, weight_per_unit: float, stack_limit: int) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": item_id,
		"amount": amount,
		"weight_per_unit": weight_per_unit,
		"stack_limit": stack_limit,
		"item_type": "material",
	}

func _verify_safe_zone_and_stability(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run for safe zone and stability failed")
		return false

	var stability = director.stability_component
	var vision = director.vision_controller
	var camera = director.camera_controller
	if stability == null:
		printerr("Expected StabilityComponent to be wired.")
		return false
	if vision == null:
		printerr("Expected VisionController to be wired.")
		return false
	if camera == null:
		printerr("Expected RunCameraController to be wired.")
		return false

	director.on_home_exited()
	await process_frame
	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "SCAVENGE":
		printerr("Expected auto camera transition into SCAVENGE, got %s" % state.get("current_phase"))
		return false
	if not stability.is_decaying:
		printerr("Expected stability decay after leaving home.")
		return false
	if not vision.darkness_enabled:
		printerr("Expected darkness enabled after leaving home.")
		return false
	if camera.get_mode_name() != "PLAYER_FOLLOW":
		printerr("Expected camera follow after leaving home, got %s" % camera.get_mode_name())
		return false

	stability.set_stability(74.0)
	if stability.current_stage != stability.StabilityStage.TENSE:
		printerr("Expected TENSE stage below 75.")
		return false
	if vision.current_radius >= vision.safe_radius:
		printerr("Expected reduced vision radius for TENSE stage.")
		return false

	director.on_safe_zone_entered("home")
	if not stability.is_recovering:
		printerr("Expected stability recovery inside home.")
		return false
	if vision.darkness_enabled:
		printerr("Expected darkness disabled inside home.")
		return false
	if camera.get_mode_name() != "OVERVIEW":
		printerr("Expected overview camera inside home, got %s" % camera.get_mode_name())
		return false

	director.on_safe_zone_exited("home")
	await process_frame
	stability.set_stability(0.0)
	state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "FAILED":
		printerr("Expected stability depletion to enter FAILED, got %s" % state.get("current_phase"))
		return false
	print("Safe zone and stability loop verified.")
	return true

func _verify_success_path(director) -> bool:
	if not director.start_new_run():
		printerr("start_new_run failed")
		return false
	director.on_home_exited()
	director.on_camera_transition_finished()
	director.on_safe_zone_entered("outpost_debug_a")
	director.on_outpost_repair_started("debug_outpost_a")
	director.on_outpost_repaired("debug_outpost_a")
	director.on_safe_zone_exited("outpost_debug_a")
	director.on_camera_transition_finished()
	director.on_outpost_repair_started("debug_outpost_b")
	director.on_outpost_repaired("debug_outpost_b")
	director.on_safe_zone_entered("home")
	director.on_extraction_started()
	director.on_extraction_completed()

	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "SETTLEMENT":
		printerr("Expected SETTLEMENT, got %s" % state.get("current_phase"))
		return false
	if state.get("run_result") != "EXTRACTED":
		printerr("Expected EXTRACTED, got %s" % state.get("run_result"))
		return false
	print("Success path verified.")
	return true

func _verify_death_path(director) -> bool:
	if not director.start_new_run():
		printerr("second start_new_run failed")
		return false
	director.on_home_exited()
	director.on_camera_transition_finished()
	director.on_player_dead("test_stability_depleted")

	var state = director.state_machine.get_state_snapshot()
	if state.get("current_phase") != "FAILED":
		printerr("Expected FAILED, got %s" % state.get("current_phase"))
		return false
	if state.get("run_result") != "DEAD":
		printerr("Expected DEAD, got %s" % state.get("run_result"))
		return false
	print("Death path verified.")
	return true

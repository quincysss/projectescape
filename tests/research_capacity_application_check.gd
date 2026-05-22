extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_research_capacity_application()
	print("Research capacity application verified." if ok else "Research capacity application failed.")
	quit(0 if ok else 1)

func _verify_research_capacity_application() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	if game_state.get_inventory_slot_count() != 8:
		printerr("Expected base inventory capacity to be 8.")
		return false
	if game_state.get_home_storage_slot_count() != 1:
		printerr("Expected base home storage capacity to be 1.")
		return false
	if game_state.get_outpost_storage_slot_count() != 0:
		printerr("Expected base outpost storage capacity to be 0.")
		return false
	if game_state.get_warehouse_capacity() != 80:
		printerr("Expected base warehouse capacity to be 80.")
		return false
	if game_state.get_warehouse_max_capacity() != 120:
		printerr("Expected warehouse UI max capacity to be 120.")
		return false

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load: %s" % registry.load_errors)
		return false
	var accepted: Array = game_state.add_to_warehouse(_make_items(registry, 80))
	if accepted.size() != 80:
		printerr("Expected base warehouse to accept 80 items.")
		return false
	if game_state.add_to_warehouse(_make_items(registry, 1)).size() != 0:
		printerr("Expected base warehouse to reject items beyond capacity.")
		return false

	game_state.research_levels["inventory_slots"] = 3
	game_state.research_levels["home_storage_slots"] = 3
	game_state.research_levels["outpost_storage_slots"] = 2
	game_state.research_levels["max_stability"] = 5
	game_state.research_levels["warehouse_capacity"] = 5
	if game_state.get_inventory_slot_count() != 20:
		printerr("Expected researched inventory capacity to be 20.")
		return false
	if game_state.get_home_storage_slot_count() != 4:
		printerr("Expected researched home storage capacity to be 4.")
		return false
	if game_state.get_outpost_storage_slot_count() != 2:
		printerr("Expected researched outpost storage capacity to be 2.")
		return false
	if absf(game_state.get_player_max_stability() - 200.0) > 0.001:
		printerr("Expected researched stability max to be 200.")
		return false
	if game_state.get_warehouse_capacity() != 120:
		printerr("Expected researched warehouse capacity to be 120.")
		return false

	var extra: Array = game_state.add_to_warehouse(_make_items(registry, 40))
	if extra.size() != 40:
		printerr("Expected researched warehouse capacity to accept 40 more items.")
		return false

	game_state.clear_warehouse()
	if game_state.get_inventory_slot_count() != 20:
		printerr("Expected researched inventory capacity to survive warehouse clear.")
		return false
	var run_scene: Node = load("res://scenes/run/RunScene.tscn").instantiate()
	root.add_child(run_scene)
	await process_frame
	await process_frame
	if run_scene.run_director.inventory_component.max_slots != 20:
		printerr("Expected RunScene inventory to use researched capacity. got=%d game_state=%d config=%d" % [
			run_scene.run_director.inventory_component.max_slots,
			game_state.get_inventory_slot_count(),
			run_scene.run_director.config.inventory_slots,
		])
		run_scene.queue_free()
		return false
	if run_scene.run_director.home_storage_component.max_slots != 4:
		printerr("Expected RunScene home storage to use researched capacity.")
		run_scene.queue_free()
		return false
	if absf(float(run_scene.run_director.stability_component.max_stability) - 200.0) > 0.001:
		printerr("Expected RunScene stability max to use researched value.")
		run_scene.queue_free()
		return false
	var outpost_id := String(run_scene.run_director.context.selected_first_outpost_id)
	if run_scene.run_director.get_outpost_storage_capacity(outpost_id) != 2:
		printerr("Expected RunScene outpost storage capacity to use researched value.")
		run_scene.queue_free()
		return false

	run_scene.queue_free()
	await process_frame
	game_state.reset_research()
	game_state.clear_warehouse()
	if not await _verify_locked_warehouse_slots():
		return false
	return true

func _verify_locked_warehouse_slots() -> bool:
	var base_root = load("res://scenes/base/BaseScene.tscn").instantiate()
	root.add_child(base_root)
	await process_frame
	await process_frame
	var grid_root: Control = base_root.warehouse_grid_root
	if grid_root == null:
		printerr("Expected warehouse grid root.")
		base_root.queue_free()
		return false
	var unlocked_slots := 0
	var locked_slots := 0
	for child in grid_root.get_children():
		if child is Label:
			continue
		if bool(child.get_meta("warehouse_slot_locked", false)):
			locked_slots += 1
		else:
			unlocked_slots += 1
	base_root.queue_free()
	await process_frame
	if unlocked_slots != 80 or locked_slots != 40:
		printerr("Expected warehouse grid to keep 120 slots with 40 grey locked slots, got unlocked=%d locked=%d." % [unlocked_slots, locked_slots])
		return false
	return true

func _make_items(registry, count: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for _index in range(count):
		items.append(registry.make_item_stack("keepsake_photo"))
	return items

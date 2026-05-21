extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify_shop_shelf_buttons()
	print("Shop shelf button flow verified." if ok else "Shop shelf button flow failed.")
	quit(0 if ok else 1)


func _verify_shop_shelf_buttons() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("ShopGrid")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	game_state.mark_first_departure_outpost_dialogue_seen()
	game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load.")
		_restore_profile(game_state, original_profile)
		return false

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.set_outgame_phase("DAY_PREP")
	game_state.add_to_warehouse([
		registry.make_item_stack("sale_good_repaired_filter"),
		registry.make_item_stack("sale_good_emergency_wrap"),
		registry.make_item_stack("scrap_metal"),
	])

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		_restore_profile(game_state, original_profile)
		return false
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	base_root._request_start_run()
	await process_frame
	if game_state.get_outgame_phase() != "SHOP_OPEN":
		printerr("Expected opening entry to enter SHOP_OPEN.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var shelf_buttons := _find_buttons_by_text(base_root, "上架")
	if shelf_buttons.size() < 2:
		printerr("Expected shelf buttons for two sale_goods.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	shelf_buttons[0].emit_signal("pressed")
	await process_frame
	var shelf_items: Array = game_state.get_shelf_items()
	if _filled_shelf_count(shelf_items) != 1:
		printerr("Expected one shelf slot to be filled after shelf button press.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	if not _find_group_by_item_id(game_state.query_shelfable_sale_goods(), "scrap_metal").is_empty():
		printerr("Expected raw materials to stay excluded from shelfable goods.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	var return_buttons := _find_buttons_by_text(base_root, "下架")
	if return_buttons.is_empty():
		printerr("Expected return button on filled shelf slot.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false
	return_buttons[0].emit_signal("pressed")
	await process_frame
	if _filled_shelf_count(game_state.get_shelf_items()) != 0:
		printerr("Expected shelf slot to be empty after return button press.")
		base_root.queue_free()
		_restore_profile(game_state, original_profile)
		return false

	base_root.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true


func _find_buttons_by_text(root_node: Node, text: String) -> Array[Button]:
	var result: Array[Button] = []
	for child in root_node.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button.text == text:
			result.append(button)
	return result


func _filled_shelf_count(shelf_items: Array) -> int:
	var count := 0
	for item in shelf_items:
		if item is Dictionary and not Dictionary(item).is_empty():
			count += 1
	return count


func _find_group_by_item_id(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			return item
	return {}


func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := await _verify()
	print("Outgame shop flow verified." if ok else "Outgame shop flow failed.")
	quit(0 if ok else 1)


func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()
	var create_result: Dictionary = game_state.create_profile("ShopFlow")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		_restore_profile(game_state, original_profile)
		return false
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	game_state.mark_first_departure_outpost_dialogue_seen()
	game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	game_state.manufacturing_station_unlocked = true
	game_state.chapter_1_completed = true
	game_state.chapter_1_goal_active = false

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load: %s" % registry.load_errors)
		_restore_profile(game_state, original_profile)
		return false
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.add_to_warehouse([
		registry.make_item_stack("scrap_metal"),
		registry.make_item_stack("cloth_dirty"),
		registry.make_item_stack("scrap_metal"),
	])

	var recipes: Array = game_state.query_crafting_recipes()
	if recipes.is_empty():
		printerr("Expected crafting recipes.")
		_restore_profile(game_state, original_profile)
		return false
	var craft_result: Dictionary = game_state.craft_recipe("recipe_repaired_filter")
	if not bool(craft_result.get("ok", false)):
		printerr("Expected crafting sale_good to succeed: %s" % craft_result)
		_restore_profile(game_state, original_profile)
		return false

	var shelfable: Array = game_state.query_shelfable_sale_goods()
	var sale_group := _find_group(shelfable, "sale_good_repaired_filter")
	var material_group := _find_group(shelfable, "scrap_metal")
	if sale_group.is_empty() or not material_group.is_empty():
		printerr("Expected only sale_good items to be shelfable: %s" % shelfable)
		_restore_profile(game_state, original_profile)
		return false

	var start_result: Dictionary = game_state.start_shop_open()
	if not bool(start_result.get("ok", false)) or game_state.get_outgame_phase() != "SHOP_OPEN":
		printerr("Expected shop to enter SHOP_OPEN: %s" % start_result)
		_restore_profile(game_state, original_profile)
		return false
	sale_group = _find_group(game_state.query_shelfable_sale_goods(), "sale_good_repaired_filter")
	var shelf_result: Dictionary = game_state.move_sale_good_to_shelf(String(sale_group.get("shelf_group_id", "")), 0)
	if not bool(shelf_result.get("ok", false)):
		printerr("Expected sale_good to move to shelf: %s" % shelf_result)
		_restore_profile(game_state, original_profile)
		return false
	var advance_result: Dictionary = game_state.advance_shop_open(5.1)
	if not bool(advance_result.get("ok", false)) or game_state.get_shop_sales_records().size() != 1:
		printerr("Expected automatic shop sale after countdown tick: %s" % advance_result)
		_restore_profile(game_state, original_profile)
		return false
	game_state.finish_shop_open("manual")
	if game_state.get_outgame_phase() != "SHOP_SETTLEMENT":
		printerr("Expected shop settlement phase.")
		_restore_profile(game_state, original_profile)
		return false
	var settlement: Dictionary = game_state.get_shop_settlement_snapshot()
	if int(settlement.get("total_earned", 0)) <= 0:
		printerr("Expected positive settlement total: %s" % settlement)
		_restore_profile(game_state, original_profile)
		return false
	var total := int(settlement.get("total_earned", 0))
	var close_result: Dictionary = game_state.close_shop_settlement_to_night()
	if not bool(close_result.get("ok", false)) or game_state.get_outgame_phase() != "NIGHT":
		printerr("Expected settlement close to enter NIGHT: %s" % close_result)
		_restore_profile(game_state, original_profile)
		return false
	if game_state.get_currency_amount("mine_coin") != total:
		printerr("Expected settlement to apply currency exactly once.")
		_restore_profile(game_state, original_profile)
		return false

	game_state.go_to_night_plan()
	var plan: Dictionary = game_state.get_night_plan_snapshot()
	if Array(plan.get("characters", [])).size() != 1 or Array(plan.get("locations", [])).size() != 1:
		printerr("Expected one character and one location in night plan.")
		_restore_profile(game_state, original_profile)
		return false
	game_state.go_to_loadout()
	var loadout: Dictionary = game_state.get_loadout_snapshot()
	if int(loadout.get("consumable_slot_count", 0)) != 4 or int(loadout.get("unlocked_consumable_slots", 0)) != 1:
		printerr("Expected 4 consumable slots with only the first unlocked: %s" % loadout)
		_restore_profile(game_state, original_profile)
		return false

	_restore_profile(game_state, original_profile)
	return true


func _find_group(groups: Array, item_id: String) -> Dictionary:
	for group in groups:
		if group is Dictionary and String(group.get("item_id", "")) == item_id:
			return group
	return {}


func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

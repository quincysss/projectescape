extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

const DIRECT_RECIPES := {
	"scrap_metal": "recipe_scrap_bundle",
	"cloth_dirty": "recipe_cloth_wrap",
	"wire_coil": "recipe_wire_spool",
	"battery_old": "recipe_battery_clip",
	"medicine_powder": "recipe_medicine_sachet",
	"tool_parts": "recipe_tool_bit_box",
	"cracked_lens": "recipe_lens_tag",
	"duct_tape_roll": "recipe_tape_strip",
	"rusted_bolts": "recipe_bolt_cup",
	"reinforced_strap": "recipe_strap_bundle",
	"pulse_battery": "recipe_charge_cell",
	"signal_resonator_coil": "recipe_signal_tag",
}


func _initialize() -> void:
	var ok := await _verify()
	print("Resource shop loop minimum verified." if ok else "Resource shop loop minimum failed.")
	quit(0 if ok else 1)


func _verify() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_local_data_debug_only()

	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load: %s" % str(registry.load_errors))
		_restore_profile(game_state, original_profile)
		return false

	var ok := _prepare_unlocked_profile(game_state)
	if not ok:
		_restore_profile(game_state, original_profile)
		return false

	for material_id in DIRECT_RECIPES.keys():
		if not _can_direct_craft_from_single_material(game_state, registry, String(material_id), String(DIRECT_RECIPES[material_id])):
			_restore_profile(game_state, original_profile)
			return false

	if not _can_craft_higher_value_combo(game_state, registry):
		_restore_profile(game_state, original_profile)
		return false

	if not _crafting_consumes_partial_stack_amount(game_state, registry):
		_restore_profile(game_state, original_profile)
		return false

	if not _can_shelf_sell_and_earn_coin(game_state, registry):
		_restore_profile(game_state, original_profile)
		return false

	_restore_profile(game_state, original_profile)
	return true


func _prepare_unlocked_profile(game_state: Node) -> bool:
	var create_result: Dictionary = game_state.create_profile("ResourceLoop")
	if not bool(create_result.get("ok", false)):
		printerr("Expected profile creation to pass: %s" % create_result)
		return false
	game_state.mark_intro_cinematic_seen()
	game_state.mark_world_intro_dialogue_seen()
	game_state.mark_first_departure_outpost_dialogue_seen()
	game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	game_state.manufacturing_station_unlocked = true
	game_state.shop_loop_unlocked = true
	game_state.chapter_1_completed = true
	game_state.chapter_1_goal_active = false
	game_state.clear_warehouse()
	game_state.clear_currencies()
	return true


func _can_direct_craft_from_single_material(game_state: Node, registry, material_id: String, recipe_id: String) -> bool:
	game_state.clear_warehouse()
	game_state.add_to_warehouse([registry.make_item_stack(material_id)])
	var quote: Dictionary = game_state.get_craft_quote(recipe_id)
	if not bool(quote.get("ok", false)):
		printerr("Expected direct recipe %s to be craftable from %s: %s" % [recipe_id, material_id, quote])
		return false
	if Dictionary(quote.get("required_items", {})).size() != 1:
		printerr("Expected direct recipe %s to require one material only: %s" % [recipe_id, quote])
		return false
	var craft_result: Dictionary = game_state.craft_recipe(recipe_id)
	if not bool(craft_result.get("ok", false)):
		printerr("Expected direct recipe %s to craft: %s" % [recipe_id, craft_result])
		return false
	var crafted_items: Array = Array(craft_result.get("crafted_items", []))
	if crafted_items.size() != 1:
		printerr("Expected direct recipe %s to output one sale_good: %s" % [recipe_id, craft_result])
		return false
	var crafted_item: Dictionary = crafted_items[0]
	if String(crafted_item.get("item_type", "")) != "sale_good":
		printerr("Expected direct recipe %s output to be sale_good: %s" % [recipe_id, crafted_item])
		return false
	if game_state.get_currency_amount("mine_coin") != 0:
		printerr("Expected sale-good crafting to avoid mine_coin cost.")
		return false
	return true


func _can_craft_higher_value_combo(game_state: Node, registry) -> bool:
	game_state.clear_warehouse()
	game_state.add_to_warehouse([
		registry.make_item_stack("scrap_metal"),
		registry.make_item_stack("rusted_bolts"),
	])
	var craft_result: Dictionary = game_state.craft_recipe("recipe_gear_bundle")
	if not bool(craft_result.get("ok", false)):
		printerr("Expected combo recipe to craft: %s" % craft_result)
		return false
	var combo_item_id := String(craft_result.get("output_item_id", ""))
	var combo_item: Dictionary = registry.get_item(combo_item_id)
	var scrap_value := int(registry.get_item("sale_good_scrap_bundle").get("sell_value", 0))
	var bolt_value := int(registry.get_item("sale_good_bolt_cup").get("sell_value", 0))
	if int(combo_item.get("sell_value", 0)) <= scrap_value + bolt_value:
		printerr("Expected combo good to exceed direct-craft value: %s" % combo_item)
		return false
	if _count_warehouse_item(game_state, "scrap_metal") != 0 or _count_warehouse_item(game_state, "rusted_bolts") != 0:
		printerr("Expected combo crafting to consume warehouse materials.")
		return false
	return true


func _crafting_consumes_partial_stack_amount(game_state: Node, registry) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.add_to_warehouse([registry.make_item_stack("scrap_metal", 2)])
	if _count_warehouse_item(game_state, "scrap_metal") != 2:
		printerr("Expected stacked scrap_metal amount to enter warehouse as quantity 2.")
		return false
	var craft_result: Dictionary = game_state.craft_recipe("recipe_scrap_bundle")
	if not bool(craft_result.get("ok", false)):
		printerr("Expected direct recipe to consume one unit from a stacked material entry: %s" % craft_result)
		return false
	if _count_warehouse_item(game_state, "scrap_metal") != 1:
		printerr("Expected crafting to consume only one unit from the material stack, not the whole slot.")
		return false
	if _count_warehouse_item(game_state, "sale_good_scrap_bundle") != 1:
		printerr("Expected partial-stack craft to add one sale_good output.")
		return false
	return true


func _can_shelf_sell_and_earn_coin(game_state: Node, registry) -> bool:
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.reset_research()
	game_state.add_to_warehouse([
		registry.make_item_stack("scrap_metal"),
		registry.make_item_stack("scrap_metal"),
	])
	for _index in range(2):
		var craft_result: Dictionary = game_state.craft_recipe("recipe_scrap_bundle")
		if not bool(craft_result.get("ok", false)):
			printerr("Expected direct sale_good craft before shop loop: %s" % craft_result)
			return false

	var start_result: Dictionary = game_state.start_shop_open()
	if not bool(start_result.get("ok", false)):
		printerr("Expected shop open to start: %s" % start_result)
		return false
	var sale_group := _find_group(game_state.query_shelfable_sale_goods(), "sale_good_scrap_bundle")
	if sale_group.is_empty():
		printerr("Expected crafted sale_good to be shelfable: %s" % game_state.query_shelfable_sale_goods())
		return false
	var shelf_result: Dictionary = game_state.move_sale_good_to_shelf(String(sale_group.get("shelf_group_id", "")), 0)
	if not bool(shelf_result.get("ok", false)):
		printerr("Expected sale_good to move to shelf: %s" % shelf_result)
		return false
	if _count_warehouse_item(game_state, "sale_good_scrap_bundle") != 1:
		printerr("Expected one shelf slot to remove exactly one item from a stacked sale_good.")
		return false
	sale_group = _find_group(game_state.query_shelfable_sale_goods(), "sale_good_scrap_bundle")
	shelf_result = game_state.move_sale_good_to_shelf(String(sale_group.get("shelf_group_id", "")), 1)
	if not bool(shelf_result.get("ok", false)):
		printerr("Expected second sale_good to move to shelf: %s" % shelf_result)
		return false
	var demand_by_item := _demand_by_item_id(game_state.get_daily_demand_entries())
	var expected_unit_price := _expected_shop_unit_price(registry, demand_by_item, "sale_good_scrap_bundle")
	var advance_result: Dictionary = game_state.advance_shop_open(5.1)
	if not bool(advance_result.get("ok", false)):
		printerr("Expected shop to sell first shelved sale_good: %s" % advance_result)
		return false
	advance_result = game_state.advance_shop_open(5.1)
	if not bool(advance_result.get("ok", false)) or game_state.get_shop_sales_records().size() != 2:
		printerr("Expected shop to sell both shelved sale_goods: %s" % advance_result)
		return false
	for record in game_state.get_shop_sales_records():
		if int(record.get("unit_price", 0)) != expected_unit_price:
			printerr("Expected shop sale unit_price to be based on sell_value and demand multiplier: %s" % record)
			return false
	game_state.finish_shop_open("manual")
	var settlement: Dictionary = game_state.get_shop_settlement_snapshot()
	var total := int(settlement.get("total_earned", 0))
	if total < 20:
		printerr("Expected positive shop settlement: %s" % settlement)
		return false
	var close_result: Dictionary = game_state.close_shop_settlement_to_night()
	if not bool(close_result.get("ok", false)):
		printerr("Expected settlement close to succeed: %s" % close_result)
		return false
	if game_state.get_currency_amount("mine_coin") != total:
		printerr("Expected shop settlement to grant mine_coin.")
		return false
	var quote: Dictionary = game_state.get_research_quote("move_speed")
	if not bool(quote.get("ok", false)) or not Dictionary(quote.get("required_items", {})).is_empty():
		printerr("Expected sold mine_coin to unlock currency-only research: %s" % quote)
		return false
	var research_result: Dictionary = game_state.complete_research("move_speed")
	if not bool(research_result.get("ok", false)) or game_state.get_research_level("move_speed") != 1:
		printerr("Expected mine_coin research unlock after shop settlement: %s" % research_result)
		return false
	if game_state.get_currency_amount("mine_coin") != total - 20:
		printerr("Expected research to spend only move_speed mine_coin cost.")
		return false
	return true


func _demand_by_item_id(entries: Array) -> Dictionary:
	var result := {}
	for entry in entries:
		if entry is Dictionary:
			result[String(entry.get("item_id", ""))] = entry
	return result


func _expected_shop_unit_price(registry, demand_by_item: Dictionary, item_id: String) -> int:
	var item: Dictionary = registry.get_item(item_id)
	var demand: Dictionary = demand_by_item.get(item_id, {})
	var sell_value := int(item.get("sell_value", 1))
	var multiplier := float(demand.get("sell_multiplier", 1.0))
	return maxi(1, int(round(float(sell_value) * multiplier)))


func _count_warehouse_item(game_state: Node, item_id: String) -> int:
	var total := 0
	for item in game_state.get_warehouse_items_snapshot():
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			total += maxi(1, int(item.get("amount", 1)))
	return total


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

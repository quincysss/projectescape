extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const SSRunChanceDirectorScript := preload("res://scripts/run/ss_run_chance_director.gd")
const SSLootDirectorScript := preload("res://scripts/run/ss_loot_director.gd")
const GameStateScript := preload("res://scripts/game/game_state.gd")
const InventoryComponentScript := preload("res://scripts/inventory/inventory_component.gd")
const StorageContainerScript := preload("res://scripts/inventory/storage_container.gd")

const SS_ITEM_IDS := [
	"ss_silverwing_engine_core",
	"ss_pink_star",
	"ss_wanming_pocket_watch",
	"ss_old_world_gold_bar",
	"ss_zero_master_control_board",
]

func _initialize() -> void:
	var ok := _verify_ss_loot_rules()
	print("SS loot rules verified." if ok else "SS loot rules failed.")
	quit(0 if ok else 1)

func _verify_ss_loot_rules() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false
	var ok := true
	ok = _verify_ss_tables(registry) and ok
	ok = _verify_run_chance_state(registry) and ok
	ok = _verify_ss_loot_director(registry) and ok
	ok = _verify_sell_fields_survive_inventory_and_storage(registry) and ok
	return ok

func _verify_ss_tables(registry) -> bool:
	var ok := true
	if registry.get_item_quality_color("SS") != Color("#FF4A4A"):
		printerr("Expected SS quality to use red display color.")
		ok = false
	var pool_ids: Array[String] = registry.get_ss_loot_pool_item_ids()
	var normal_drop_ids: Dictionary = _collect_normal_drop_ids(registry)
	for item_id in SS_ITEM_IDS:
		var item: Dictionary = registry.get_item(String(item_id))
		if item.is_empty():
			printerr("Missing SS item: %s" % item_id)
			ok = false
			continue
		if String(item.get("quality", "")) != "SS":
			printerr("Expected %s quality SS." % item_id)
			ok = false
		if String(item.get("item_type", "")) != "rare":
			printerr("Expected %s to use rare item_type." % item_id)
			ok = false
		if String(item.get("sell_currency_id", "")) != "mine_coin" or int(item.get("sell_value", 0)) <= 0:
			printerr("Expected %s to sell for mine_coin with positive value." % item_id)
			ok = false
		if not _tags_include(item, ["ss_rare", "showcase", "sellable"]):
			printerr("Expected %s to include ss_rare/showcase/sellable tags." % item_id)
			ok = false
		if not pool_ids.has(String(item_id)):
			printerr("Expected %s in SS loot pool." % item_id)
			ok = false
		if normal_drop_ids.has(String(item_id)):
			printerr("SS item %s must not be in normal drop_tables.tab." % item_id)
			ok = false
	for case_data in [
		{"type_id": "cardboard_box", "chance": 0.001, "pity": false},
		{"type_id": "wooden_crate", "chance": 0.01, "pity": false},
		{"type_id": "small_safe", "chance": 0.05, "pity": true},
		{"type_id": "large_safe", "chance": 0.10, "pity": true},
		{"type_id": "anomaly_case", "chance": 0.10, "pity": true},
	]:
		if not is_equal_approx(registry.get_ss_container_chance(case_data.type_id), float(case_data.chance)):
			printerr("Unexpected SS container chance for %s." % case_data.type_id)
			ok = false
		if registry.is_ss_pity_container(case_data.type_id) != bool(case_data.pity):
			printerr("Unexpected SS pity flag for %s." % case_data.type_id)
			ok = false
	for tier_case in [
		{"tier": 0, "chance": 0.20},
		{"tier": 1, "chance": 0.10},
		{"tier": 2, "chance": 0.05},
		{"tier": 3, "chance": 0.025},
		{"tier": 4, "chance": 0.01},
		{"tier": 99, "chance": 0.01},
	]:
		if not is_equal_approx(registry.get_ss_chance_for_tier(int(tier_case.tier)), float(tier_case.chance)):
			printerr("Unexpected SS chance tier %s." % tier_case.tier)
			ok = false
	return ok

func _verify_run_chance_state(registry) -> bool:
	var game_state = GameStateScript.new()
	var director = SSRunChanceDirectorScript.new()
	director.setup(registry)
	game_state.reset_ss_roll_state()
	game_state.reset_day(1)
	var hit: Dictionary = director.debug_roll_for_run_with_value(game_state, 0.05, 2)
	if not bool(hit.get("active", false)) or int(hit.get("budget_total", 0)) != 2:
		printerr("Expected first SS run roll to hit and allocate budget.")
		return false
	var state: Dictionary = game_state.get_ss_roll_state()
	if int(state.get("chance_tier", 0)) != 1 or int(state.get("miss_count", -1)) != 0:
		printerr("Expected SS hit to decay next chance tier.")
		return false
	game_state.reset_day(2)
	var miss_one: Dictionary = director.debug_roll_for_run_with_value(game_state, 0.95)
	game_state.reset_day(3)
	var miss_two: Dictionary = director.debug_roll_for_run_with_value(game_state, 0.95)
	game_state.reset_day(4)
	var miss_three: Dictionary = director.debug_roll_for_run_with_value(game_state, 0.95)
	if bool(miss_one.get("active", true)) or bool(miss_two.get("active", true)) or bool(miss_three.get("active", true)):
		printerr("Expected forced high rolls to miss.")
		return false
	if not is_equal_approx(float(miss_three.get("chance", 0.0)), 0.20) or not bool(miss_three.get("recovered_before_roll", false)):
		printerr("Expected third consecutive SS miss judgment to roll at recovered 20%% chance.")
		return false
	state = game_state.get_ss_roll_state()
	if int(state.get("chance_tier", -1)) != 0 or int(state.get("miss_count", -1)) != 1:
		printerr("Expected missed recovered SS roll to keep tier 0 with one miss recorded.")
		game_state.free()
		return false
	game_state.free()
	return true

func _verify_ss_loot_director(registry) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88001
	var large_safe: Dictionary = registry.get_container_type("large_safe")
	var inactive = SSLootDirectorScript.new()
	inactive.setup(registry)
	inactive.begin_run({"active": false, "budget_total": 2})
	inactive.debug_force_next_ss_drop()
	if not inactive.try_generate_ss(large_safe, "far_outer", rng).is_empty():
		printerr("Expected inactive run to never generate SS loot.")
		return false

	var pity = SSLootDirectorScript.new()
	pity.setup(registry)
	pity.begin_run({"active": true, "budget_total": 1})
	pity.debug_set_opened_effective_container_count(8)
	var pity_stack: Dictionary = pity.try_generate_ss(large_safe, "far_outer", rng)
	if String(pity_stack.get("quality", "")) != "SS" or int(pity.get_debug_snapshot().get("ss_budget_used", 0)) != 1:
		printerr("Expected pity eligible safe to generate one SS item.")
		return false

	var capped = SSLootDirectorScript.new()
	capped.setup(registry)
	capped.begin_run({"active": true, "budget_total": 2})
	capped.debug_force_next_ss_drop()
	var first: Dictionary = capped.try_generate_ss(large_safe, "far_outer", rng)
	capped.debug_force_next_ss_drop()
	var second: Dictionary = capped.try_generate_ss(large_safe, "far_outer", rng)
	capped.debug_force_next_ss_drop()
	var third: Dictionary = capped.try_generate_ss(large_safe, "far_outer", rng)
	if String(first.get("quality", "")) != "SS" or String(second.get("quality", "")) != "SS" or not third.is_empty():
		printerr("Expected SS loot budget to cap at two generated items.")
		return false
	return true

func _verify_sell_fields_survive_inventory_and_storage(registry) -> bool:
	var stack: Dictionary = registry.make_item_stack("ss_old_world_gold_bar", 1)
	var inventory = InventoryComponentScript.new()
	inventory.setup(2, 20.0)
	if not inventory.add_item(stack):
		printerr("Expected inventory to accept SS item.")
		return false
	var inventory_item: Dictionary = inventory.get_items_snapshot()[0]
	if not bool(inventory_item.get("sellable", false)) or int(inventory_item.get("sell_value", 0)) <= 0:
		printerr("Expected inventory normalization to preserve SS sell fields.")
		return false
	var storage = StorageContainerScript.new()
	storage.setup("test_storage", "test", 2)
	if not storage.store_from_inventory(inventory, 0, 1):
		printerr("Expected storage to accept SS item.")
		return false
	var stored_item: Dictionary = storage.get_items_snapshot()[0]
	if not bool(stored_item.get("sellable", false)) or String(stored_item.get("sell_currency_id", "")) != "mine_coin":
		printerr("Expected storage normalization to preserve SS sell fields.")
		inventory.free()
		return false
	inventory.free()
	return true

func _collect_normal_drop_ids(registry) -> Dictionary:
	var result := {}
	for context in registry.drop_rows_by_context.keys():
		for row in registry.drop_rows_by_context[context]:
			result[String(row.get("item_id", ""))] = true
	return result

func _tags_include(item: Dictionary, required_tags: Array) -> bool:
	var tags := String(item.get("tags", "")).split(";", false)
	for required in required_tags:
		if not tags.has(String(required)):
			return false
	return true

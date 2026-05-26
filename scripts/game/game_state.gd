extends Node

const WarehouseManagerScript := preload("res://scripts/game/warehouse_manager.gd")
const CurrencyWalletScript := preload("res://scripts/game/currency_wallet.gd")
const MerchantServiceScript := preload("res://scripts/game/merchant_service.gd")
const ResearchManagerScript := preload("res://scripts/game/research_manager.gd")
const ItemCatalogServiceScript := preload("res://scripts/game/item_catalog_service.gd")
const DailyDemandServiceScript := preload("res://scripts/game/daily_demand_service.gd")
const ShelfInventoryServiceScript := preload("res://scripts/game/shelf_inventory_service.gd")
const ShopSalesServiceScript := preload("res://scripts/game/shop_sales_service.gd")
const CraftingManagerScript := preload("res://scripts/game/crafting_manager.gd")
const StarterSupplyServiceScript := preload("res://scripts/game/starter_supply_service.gd")
const ChapterProgressServiceScript := preload("res://scripts/game/chapter_progress_service.gd")
const ProfileServiceScript := preload("res://scripts/profile/profile_service.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

const BASE_INVENTORY_SLOTS := 8
const BASE_HOME_STORAGE_SLOTS := 1
const BASE_OUTPOST_STORAGE_SLOTS := 0
const BASE_MAX_STABILITY := 100.0
const BASE_WAREHOUSE_CAPACITY := 80
const MANUFACTURING_UNLOCK_COST := 100
const OUTGAME_PHASE_DAY_PREP := "DAY_PREP"
const OUTGAME_PHASE_SHOP_OPEN := "SHOP_OPEN"
const OUTGAME_PHASE_SHOP_SETTLEMENT := "SHOP_SETTLEMENT"
const OUTGAME_PHASE_NIGHT := "NIGHT"
const OUTGAME_PHASE_NIGHT_PLAN := "NIGHT_PLAN"
const OUTGAME_PHASE_LOADOUT := "LOADOUT"
const OUTGAME_PHASE_LOADING_TO_RUN := "LOADING_TO_RUN"
const SHOP_DURATION_SECONDS := 60.0
const SHOP_SHELF_SLOT_COUNT := 3
const LOADOUT_CONSUMABLE_SLOT_COUNT := 4
const LOADOUT_UNLOCKED_CONSUMABLE_SLOTS := 1
const DEFAULT_CHARACTER_ID := "male_01"
const DEFAULT_CHARACTER_HUD_ASSETS := {
	"portrait_path": "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_male_01.png",
	"portrait_frame_path": "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_frame_empty_ref_01.png",
}
const NIGHT_LOCATIONS := {
	"abandoned_house": {
		"display_name": "废弃民居",
		"description": "住宅区资源，偏食物、布料和生活用品。",
	},
	"clinic_small": {
		"display_name": "街角诊所",
		"description": "医疗地点，偏药品、绷带和稳定补给。",
	},
	"industrial_yard": {
		"display_name": "旧工业区",
		"description": "工业地点，偏五金、工具和电子组件。",
	},
}

var warehouse_items: Array[Dictionary] = []
var currencies: Dictionary = {}
var current_day: int = 0
var profile: Dictionary = {}
var username: String = ""
var current_chapter: int = 1
var intro_cinematic_seen: bool = false
var world_intro_dialogue_seen: bool = false
var first_departure_outpost_dialogue_seen: bool = false
var first_intro_dialogue_seen: bool = false
var first_return_dialogue_seen: bool = false
var second_day_black_tide_reveal_seen: bool = false
var merchant_unlocked: bool = false
var research_station_unlocked: bool = false
var shop_loop_unlocked: bool = false
var starter_shop_supply_granted: bool = false
var first_sale_good_crafted: bool = false
var first_sale_good_shelved: bool = false
var first_shop_settlement_completed: bool = false
var first_shop_tutorial_completed: bool = false
var chapter_1_goal_active: bool = false
var manufacturing_station_unlocked: bool = true
var chapter_1_completed: bool = false
var pending_first_return_dialogue: bool = false
var _run_start_pending_result: bool = false
var selected_character_id: String = DEFAULT_CHARACTER_ID
var character_hud_assets_by_id: Dictionary = {
	DEFAULT_CHARACTER_ID: DEFAULT_CHARACTER_HUD_ASSETS,
}
var merchant_shop_level: int = 1
var merchant_shop_offers: Array[Dictionary] = []
var research_levels: Dictionary = {}
var collected_item_ids: Dictionary = {}
var legacy_high_tier_chance_tier: int = 0
var legacy_high_tier_miss_count: int = 0
var legacy_high_tier_last_roll_day: int = 0
var legacy_high_tier_last_roll_result: Dictionary = {}
var forced_scene_events_next_run: Dictionary = {}
var last_run_result: String = ""
var last_run_result_type: String = ""
var outgame_phase: String = OUTGAME_PHASE_DAY_PREP
var daily_demand_day: int = 0
var daily_demand_entries: Array[Dictionary] = []
var shop_shelf_items: Array[Dictionary] = []
var shop_sales_records: Array[Dictionary] = []
var shop_elapsed_seconds: float = 0.0
var shop_next_sale_second: float = 5.0
var shop_duration_seconds: float = SHOP_DURATION_SECONDS
var shop_settlement_applied: bool = false
var shop_ended_by: String = ""
var selected_night_location_id: String = "abandoned_house"
var location_resource_states: Dictionary = {}
var loadout_equipment_slots: Dictionary = {
	"HEAD": "",
	"BODY": "",
	"HAND": "",
	"FOOT": "",
}
var loadout_consumable_slots: Array = ["", "", "", ""]
var warehouse_manager = WarehouseManagerScript.new()
var currency_wallet = CurrencyWalletScript.new()
var merchant_service = MerchantServiceScript.new()
var research_manager = ResearchManagerScript.new()
var item_catalog_service = ItemCatalogServiceScript.new()
var daily_demand_service = DailyDemandServiceScript.new()
var shelf_inventory_service = ShelfInventoryServiceScript.new()
var shop_sales_service = ShopSalesServiceScript.new()
var crafting_manager = CraftingManagerScript.new()
var starter_supply_service = StarterSupplyServiceScript.new()
var chapter_progress_service = ChapterProgressServiceScript.new()
var profile_service = ProfileServiceScript.new()
var location_briefing_data_registry = GameDataRegistryScript.new()
var location_briefing_data_loaded := false

func _ready() -> void:
	load_profile()
	_bind_warehouse_manager()
	_bind_currency_wallet()
	_bind_merchant_service()
	_bind_research_manager()
	_bind_item_catalog_service()
	_bind_crafting_manager()
	_bind_shop_services()

func add_to_warehouse(items: Array) -> Array[Dictionary]:
	_bind_warehouse_manager()
	var accepted: Array[Dictionary] = warehouse_manager.add_items(items)
	if not accepted.is_empty():
		_mark_items_collected(accepted, "warehouse_add")
		save_profile()
	return accepted

func apply_run_result(result: Dictionary) -> void:
	_bind_warehouse_manager()
	last_run_result = str(result.get("message", ""))
	last_run_result_type = String(result.get("result_type", ""))
	var accepted: Array[Dictionary] = warehouse_manager.add_items(result.get("warehouse_items", []))
	_mark_items_collected(accepted, "run_result")
	advance_day_after_run(result)
	if _should_queue_first_return_dialogue(result):
		pending_first_return_dialogue = true
	save_profile()

func get_current_day() -> int:
	current_day = maxi(0, current_day)
	return current_day

func get_day_display_text() -> String:
	return "第 %d 天" % maxi(1, get_current_day())

func advance_day_after_run(_result: Dictionary = {}) -> int:
	if _run_start_pending_result:
		_run_start_pending_result = false
	current_day = maxi(1, get_current_day()) + 1
	merchant_shop_offers.clear()
	_reset_shop_day_state(OUTGAME_PHASE_DAY_PREP)
	_bind_merchant_service()
	_bind_shop_services()
	save_profile()
	return current_day

func reset_day(day: int = 1) -> void:
	current_day = maxi(0, day)
	_run_start_pending_result = false
	merchant_shop_offers.clear()
	_reset_shop_day_state(OUTGAME_PHASE_DAY_PREP)
	_bind_merchant_service()
	_bind_shop_services()
	save_profile()

func commit_run_start(debug_run: bool = false) -> Dictionary:
	if debug_run:
		return {"ok": true, "surface_day": get_current_day(), "debug": true}
	current_day = maxi(1, get_current_day())
	_run_start_pending_result = true
	merchant_shop_offers.clear()
	outgame_phase = OUTGAME_PHASE_LOADING_TO_RUN
	_bind_merchant_service()
	var save_result := save_profile()
	if not bool(save_result.get("ok", true)):
		return save_result
	return {"ok": true, "surface_day": current_day}

func recover_interrupted_departure_to_night() -> Dictionary:
	if not _recover_departure_phase_to_night():
		return {"ok": true, "changed": false, "phase": get_outgame_phase()}
	var save_result := save_profile()
	save_result["changed"] = true
	save_result["phase"] = outgame_phase
	return save_result

func get_outgame_phase() -> String:
	_normalize_outgame_phase()
	return outgame_phase

func set_outgame_phase(phase: String) -> Dictionary:
	if not _is_valid_outgame_phase(phase):
		return {"ok": false, "reason": "invalid_phase", "phase": phase}
	outgame_phase = phase
	save_profile()
	return {"ok": true, "phase": outgame_phase}

func ensure_daily_demand() -> Array[Dictionary]:
	var day := maxi(1, get_current_day())
	if daily_demand_day != day or daily_demand_entries.is_empty():
		_bind_shop_services()
		daily_demand_day = day
		daily_demand_entries = daily_demand_service.generate_for_day(day)
		save_profile()
	return get_daily_demand_entries()

func get_daily_demand_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in daily_demand_entries:
		if entry is Dictionary:
			result.append(entry.duplicate(true))
	return result

func start_shop_open() -> Dictionary:
	if not is_shop_loop_unlocked():
		return {"ok": false, "reason": "shop_loop_locked", "message": "Shop loop is not unlocked yet."}
	_bind_shop_services()
	_return_all_shelf_items_without_save()
	ensure_daily_demand()
	outgame_phase = OUTGAME_PHASE_SHOP_OPEN
	shop_elapsed_seconds = 0.0
	shop_next_sale_second = 5.0
	shop_duration_seconds = SHOP_DURATION_SECONDS
	shop_settlement_applied = false
	shop_ended_by = ""
	shop_sales_records.clear()
	_bind_shop_services()
	save_profile()
	return {"ok": true, "phase": outgame_phase}

func advance_shop_open(delta_seconds: float) -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_SHOP_OPEN:
		return {"ok": false, "reason": "shop_not_open"}
	_bind_shop_services()
	var result: Dictionary = shop_sales_service.advance(delta_seconds, shop_elapsed_seconds, shop_duration_seconds, shop_next_sale_second)
	if bool(result.get("ok", false)):
		shop_elapsed_seconds = float(result.get("elapsed_seconds", shop_elapsed_seconds))
		shop_next_sale_second = float(result.get("next_sale_second", shop_next_sale_second))
		if bool(result.get("ended", false)):
			finish_shop_open("timer")
		elif not Array(result.get("sold_records", [])).is_empty():
			save_profile()
	return result

func finish_shop_open(ended_by: String = "manual") -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_SHOP_OPEN:
		return {"ok": false, "reason": "shop_not_open"}
	outgame_phase = OUTGAME_PHASE_SHOP_SETTLEMENT
	shop_ended_by = ended_by
	shop_elapsed_seconds = clampf(shop_elapsed_seconds, 0.0, shop_duration_seconds)
	save_profile()
	return {"ok": true, "phase": outgame_phase, "ended_by": shop_ended_by}

func close_shop_settlement_to_night() -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_SHOP_SETTLEMENT:
		return {"ok": false, "reason": "not_in_settlement"}
	_bind_shop_services()
	_bind_currency_wallet()
	var return_result := shelf_inventory_service.return_all_to_warehouse()
	if not bool(return_result.get("ok", false)):
		return return_result
	var settlement_result: Dictionary = shop_sales_service.apply_settlement(currency_wallet, shop_settlement_applied)
	if not bool(settlement_result.get("ok", false)):
		return settlement_result
	shop_settlement_applied = true
	first_shop_settlement_completed = true
	_update_first_shop_tutorial_completion()
	outgame_phase = OUTGAME_PHASE_NIGHT
	save_profile()
	return {"ok": true, "phase": outgame_phase, "settlement": settlement_result}

func get_shop_time_remaining() -> float:
	return maxf(0.0, shop_duration_seconds - shop_elapsed_seconds)

func get_shop_settlement_snapshot() -> Dictionary:
	_bind_shop_services()
	return shop_sales_service.build_settlement_snapshot(shop_elapsed_seconds, shop_duration_seconds, shop_settlement_applied)

func get_shop_sales_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in shop_sales_records:
		if record is Dictionary:
			result.append(record.duplicate(true))
	return result

func get_shelf_items() -> Array[Dictionary]:
	_bind_shop_services()
	return shelf_inventory_service.get_shelf_items()

func query_shelfable_sale_goods() -> Array[Dictionary]:
	_bind_shop_services()
	return shelf_inventory_service.query_shelfable_sale_goods()

func move_sale_good_to_shelf(shelf_group_id: String, slot_index: int) -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_SHOP_OPEN:
		return {"ok": false, "reason": "shop_not_open", "message": "只有开店营业时可以上架商品。"}
	_bind_shop_services()
	var result: Dictionary = shelf_inventory_service.move_group_to_shelf(shelf_group_id, slot_index)
	if bool(result.get("ok", false)):
		var shelved_item: Dictionary = result.get("item", {})
		if chapter_progress_service.is_sale_good_item(shelved_item):
			first_sale_good_shelved = true
			_update_first_shop_tutorial_completion()
		save_profile()
	return result

func return_shelf_item_to_warehouse(slot_index: int) -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_SHOP_OPEN:
		return {"ok": false, "reason": "shop_not_open", "message": "只有开店营业时可以调整货台。"}
	_bind_shop_services()
	var result: Dictionary = shelf_inventory_service.return_slot_to_warehouse(slot_index)
	if bool(result.get("ok", false)):
		save_profile()
	return result

func should_highlight_early_close() -> bool:
	_bind_shop_services()
	return not shelf_inventory_service.has_shelf_goods() and not shelf_inventory_service.has_warehouse_sale_goods()

func go_to_night_plan() -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_NIGHT:
		return {"ok": false, "reason": "not_night"}
	outgame_phase = OUTGAME_PHASE_NIGHT_PLAN
	save_profile()
	return {"ok": true, "phase": outgame_phase}

func go_to_loadout() -> Dictionary:
	if get_outgame_phase() != OUTGAME_PHASE_NIGHT_PLAN:
		return {"ok": false, "reason": "not_night_plan"}
	outgame_phase = OUTGAME_PHASE_LOADOUT
	save_profile()
	return {"ok": true, "phase": outgame_phase}

func get_night_plan_snapshot() -> Dictionary:
	return {
		"selected_character_id": get_selected_character_id(),
		"selected_location_id": selected_night_location_id,
		"characters": [
			{
				"character_id": DEFAULT_CHARACTER_ID,
				"display_name": "店主",
				"description": "当前唯一可出发角色。",
				"selected": get_selected_character_id() == DEFAULT_CHARACTER_ID,
			},
		],
		"locations": _night_locations_snapshot(),
	}

func set_night_plan_selection(character_id: String, location_id: String) -> Dictionary:
	if not character_id.is_empty():
		set_selected_character(character_id)
	if not location_id.is_empty():
		selected_night_location_id = _normalize_location_id(location_id)
	save_profile()
	return {"ok": true, "snapshot": get_night_plan_snapshot()}

func begin_location_run(location_id: String = "") -> Dictionary:
	var normalized_id := _normalize_location_id(location_id if not location_id.is_empty() else selected_night_location_id)
	var record := _location_resource_record(normalized_id)
	var visit_count_before := maxi(0, int(record.get("visit_count", 0)))
	var state := _state_for_visit_count(visit_count_before)
	if not String(record.get("forced_state", "")).is_empty():
		state = String(record.get("forced_state", state))
	record["visit_count"] = visit_count_before + 1
	record["state"] = _state_for_visit_count(visit_count_before + 1)
	record["last_visit_day"] = get_current_day()
	location_resource_states[normalized_id] = record
	save_profile()
	return {
		"map_id": normalized_id,
		"state": state,
		"visit_count_before": visit_count_before,
		"visit_count_after": int(record.get("visit_count", visit_count_before + 1)),
	}

func get_location_resource_state(location_id: String = "") -> Dictionary:
	var normalized_id := _normalize_location_id(location_id if not location_id.is_empty() else selected_night_location_id)
	var record := _location_resource_record(normalized_id)
	var visit_count := maxi(0, int(record.get("visit_count", 0)))
	var state := String(record.get("forced_state", ""))
	if state.is_empty():
		state = _state_for_visit_count(visit_count)
	return {
		"map_id": normalized_id,
		"state": state,
		"visit_count": visit_count,
		"last_visit_day": int(record.get("last_visit_day", 0)),
	}

func get_location_resource_snapshot() -> Dictionary:
	var snapshot := {}
	for location_id in NIGHT_LOCATIONS.keys():
		snapshot[location_id] = get_location_resource_state(location_id)
	return snapshot

func get_location_resource_briefing(location_id: String = "") -> Dictionary:
	var normalized_id := _normalize_location_id(location_id if not location_id.is_empty() else selected_night_location_id)
	var location: Dictionary = NIGHT_LOCATIONS.get(normalized_id, {})
	var resource_state := get_location_resource_state(normalized_id)
	var state_id := String(resource_state.get("state", "rich"))
	var briefing := {}
	if _ensure_location_briefing_data_loaded():
		briefing = location_briefing_data_registry.get_location_resource_briefing(normalized_id, state_id)
	if briefing.is_empty():
		briefing = _fallback_location_resource_briefing(normalized_id, state_id)
	briefing["location_id"] = normalized_id
	briefing["description"] = String(location.get("description", ""))
	briefing["resource_state"] = state_id
	briefing["visit_count"] = int(resource_state.get("visit_count", 0))
	briefing["last_visit_day"] = int(resource_state.get("last_visit_day", 0))
	briefing["selected"] = selected_night_location_id == normalized_id
	return briefing

func debug_set_location_resource_state(location_id: String, state: String, visit_count: int = 0) -> void:
	var normalized_id := _normalize_location_id(location_id)
	var normalized_state := state if ["rich", "normal", "poor", "recovering"].has(state) else _state_for_visit_count(visit_count)
	location_resource_states[normalized_id] = {
		"visit_count": maxi(0, visit_count),
		"state": normalized_state,
		"forced_state": normalized_state,
		"last_visit_day": get_current_day(),
	}
	save_profile()

func get_loadout_snapshot() -> Dictionary:
	_normalize_loadout_slots()
	return {
		"equipment_slots": loadout_equipment_slots.duplicate(true),
		"consumable_slots": loadout_consumable_slots.duplicate(true),
		"unlocked_consumable_slots": LOADOUT_UNLOCKED_CONSUMABLE_SLOTS,
		"consumable_slot_count": LOADOUT_CONSUMABLE_SLOT_COUNT,
	}

func query_crafting_recipes(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_crafting_manager()
	return crafting_manager.query_recipes(filters)

func get_craft_quote(recipe_id: String) -> Dictionary:
	_bind_crafting_manager()
	return crafting_manager.get_craft_quote(recipe_id)

func craft_recipe(recipe_id: String) -> Dictionary:
	_bind_crafting_manager()
	var result: Dictionary = crafting_manager.craft_recipe(recipe_id)
	if bool(result.get("ok", false)):
		var crafted_items := Array(result.get("crafted_items", []))
		if chapter_progress_service.contains_sale_good(crafted_items):
			first_sale_good_crafted = true
			_update_first_shop_tutorial_completion()
		_mark_items_collected(crafted_items, "crafting")
		save_profile()
	return result

func _should_queue_first_return_dialogue(result: Dictionary) -> bool:
	if first_return_dialogue_seen:
		return false
	var result_type := String(result.get("result_type", ""))
	return _is_first_return_success_result(result_type) or _is_first_return_failure_result(result_type)

func _grant_starter_shop_supply_if_needed() -> Dictionary:
	if starter_shop_supply_granted:
		return {"ok": true, "skipped": true, "reason": "already_granted", "granted_items": []}
	if starter_supply_service == null:
		starter_supply_service = StarterSupplyServiceScript.new()
	_bind_warehouse_manager()
	var result: Dictionary = starter_supply_service.grant_prologue_shop_starter_pack(warehouse_manager)
	if not bool(result.get("ok", false)):
		return result
	starter_shop_supply_granted = true
	for item in Array(result.get("granted_items", [])):
		if item is Dictionary:
			var item_id := String(item.get("item_id", ""))
			if not item_id.is_empty():
				collected_item_ids[item_id] = true
	return result

func _update_first_shop_tutorial_completion() -> void:
	if chapter_progress_service == null:
		chapter_progress_service = ChapterProgressServiceScript.new()
	if first_shop_tutorial_completed:
		return
	if not chapter_1_goal_active or chapter_1_completed:
		return
	if not chapter_progress_service.is_first_shop_tutorial_complete(_chapter_progress_flags()):
		return
	first_shop_tutorial_completed = true
	chapter_1_completed = true
	chapter_1_goal_active = false

func has_profile() -> bool:
	return profile_service != null and profile_service.has_profile()

func load_profile() -> Dictionary:
	if profile_service == null:
		profile_service = ProfileServiceScript.new()
	if not profile_service.has_profile():
		profile = {}
		return {}
	profile = profile_service.load_profile()
	_apply_profile_to_runtime(profile)
	return profile.duplicate(true)

func create_profile(profile_username: String) -> Dictionary:
	if profile_service == null:
		profile_service = ProfileServiceScript.new()
	var result: Dictionary = profile_service.create_profile(profile_username)
	if bool(result.get("ok", false)):
		var created_profile: Dictionary = result.get("profile", {})
		profile = created_profile
		_apply_profile_to_runtime(profile)
	return result

func save_profile() -> Dictionary:
	if profile_service == null:
		profile_service = ProfileServiceScript.new()
	if profile.is_empty():
		return {"ok": true, "skipped": true}
	_sync_runtime_to_profile()
	return profile_service.save_profile(profile)

func delete_profile_debug_only() -> Dictionary:
	return reset_local_data_debug_only()

func reset_local_data_debug_only() -> Dictionary:
	if profile_service == null:
		profile_service = ProfileServiceScript.new()
	var result: Dictionary = profile_service.delete_profile_debug_only()
	if bool(result.get("ok", false)):
		_reset_runtime_to_empty_profile_state()
		result["message"] = "已重置本地数据：玩家档案、仓库、货币、研究、剧情、商店与稀有掉落状态已清空。"
	return result

func _reset_runtime_to_empty_profile_state() -> void:
	profile = {}
	username = ""
	current_day = 0
	current_chapter = 1
	intro_cinematic_seen = false
	world_intro_dialogue_seen = false
	first_departure_outpost_dialogue_seen = false
	first_intro_dialogue_seen = false
	first_return_dialogue_seen = false
	second_day_black_tide_reveal_seen = false
	merchant_unlocked = false
	research_station_unlocked = false
	shop_loop_unlocked = false
	starter_shop_supply_granted = false
	first_sale_good_crafted = false
	first_sale_good_shelved = false
	first_shop_settlement_completed = false
	first_shop_tutorial_completed = false
	chapter_1_goal_active = false
	manufacturing_station_unlocked = false
	chapter_1_completed = false
	pending_first_return_dialogue = false
	_run_start_pending_result = false
	selected_character_id = DEFAULT_CHARACTER_ID
	warehouse_items.clear()
	currencies.clear()
	merchant_shop_level = 1
	merchant_shop_offers.clear()
	research_levels.clear()
	collected_item_ids.clear()
	legacy_high_tier_chance_tier = 0
	legacy_high_tier_miss_count = 0
	legacy_high_tier_last_roll_day = 0
	legacy_high_tier_last_roll_result = {}
	forced_scene_events_next_run.clear()
	last_run_result = ""
	last_run_result_type = ""
	location_resource_states.clear()
	_reset_shop_day_state(OUTGAME_PHASE_DAY_PREP)
	selected_night_location_id = "abandoned_house"
	loadout_equipment_slots = {"HEAD": "", "BODY": "", "HAND": "", "FOOT": ""}
	loadout_consumable_slots = ["", "", "", ""]
	_bind_warehouse_manager()
	_bind_currency_wallet()
	_bind_merchant_service()
	_bind_research_manager()
	_bind_item_catalog_service()
	_bind_crafting_manager()
	_bind_shop_services()

func should_play_intro_cinematic() -> bool:
	return not intro_cinematic_seen

func mark_intro_cinematic_seen() -> Dictionary:
	intro_cinematic_seen = true
	return save_profile()

func should_play_world_intro_dialogue() -> bool:
	return not world_intro_dialogue_seen and not first_intro_dialogue_seen

func mark_world_intro_dialogue_seen() -> Dictionary:
	world_intro_dialogue_seen = true
	first_intro_dialogue_seen = true
	if not is_shop_loop_unlocked():
		current_day = maxi(1, get_current_day())
		_reset_shop_day_state(OUTGAME_PHASE_NIGHT)
	return save_profile()

func should_play_intro_dialogue() -> bool:
	return should_play_world_intro_dialogue()

func mark_intro_dialogue_seen() -> Dictionary:
	return mark_world_intro_dialogue_seen()

func should_play_first_departure_outpost_dialogue() -> bool:
	return not first_departure_outpost_dialogue_seen

func mark_first_departure_outpost_dialogue_seen() -> Dictionary:
	first_departure_outpost_dialogue_seen = true
	return save_profile()

func should_play_first_return_dialogue() -> bool:
	return pending_first_return_dialogue and not first_return_dialogue_seen

func get_first_return_dialogue_id() -> String:
	return "first_return_success_dialogue" if _is_first_return_success_result(last_run_result_type) else "first_return_failed_dialogue"

func mark_first_return_dialogue_seen_and_activate_chapter() -> Dictionary:
	var supply_result := _grant_starter_shop_supply_if_needed()
	if not bool(supply_result.get("ok", false)):
		return supply_result
	first_return_dialogue_seen = true
	pending_first_return_dialogue = false
	merchant_unlocked = true
	research_station_unlocked = true
	shop_loop_unlocked = true
	manufacturing_station_unlocked = true
	chapter_1_goal_active = true
	current_chapter = 1
	_reset_shop_day_state(OUTGAME_PHASE_DAY_PREP)
	var save_result := save_profile()
	save_result["starter_supply"] = supply_result
	return save_result

func is_merchant_unlocked() -> bool:
	return merchant_unlocked

func is_research_station_unlocked() -> bool:
	return research_station_unlocked or shop_loop_unlocked

func is_shop_loop_unlocked() -> bool:
	return shop_loop_unlocked

func _chapter_progress_flags() -> Dictionary:
	return {
		"chapter_1_goal_active": chapter_1_goal_active,
		"chapter_1_completed": chapter_1_completed,
		"first_sale_good_crafted": first_sale_good_crafted,
		"first_sale_good_shelved": first_sale_good_shelved,
		"first_shop_settlement_completed": first_shop_settlement_completed,
	}

func should_play_second_day_black_tide_reveal(run_day_index: int = -1) -> bool:
	var resolved_day := run_day_index
	if resolved_day <= 0:
		resolved_day = get_current_day()
	return resolved_day == 2 and not second_day_black_tide_reveal_seen

func mark_second_day_black_tide_reveal_seen() -> Dictionary:
	second_day_black_tide_reveal_seen = true
	return save_profile()

func reset_story_flags() -> void:
	intro_cinematic_seen = false
	world_intro_dialogue_seen = false
	first_departure_outpost_dialogue_seen = false
	first_intro_dialogue_seen = false
	first_return_dialogue_seen = false
	second_day_black_tide_reveal_seen = false
	merchant_unlocked = false
	research_station_unlocked = false
	pending_first_return_dialogue = false
	shop_loop_unlocked = false
	starter_shop_supply_granted = false
	first_sale_good_crafted = false
	first_sale_good_shelved = false
	first_shop_settlement_completed = false
	first_shop_tutorial_completed = false
	chapter_1_goal_active = false
	chapter_1_completed = false
	manufacturing_station_unlocked = true
	_reset_shop_day_state(OUTGAME_PHASE_NIGHT if world_intro_dialogue_seen else OUTGAME_PHASE_DAY_PREP)
	save_profile()

func _is_first_return_success_result(result_type: String) -> bool:
	return ["EXTRACTED", "EXTRACTION_SUCCESS"].has(result_type)

func _is_first_return_failure_result(result_type: String) -> bool:
	return ["DEAD", "TIMEOUT_FAILED", "RUN_FAILED"].has(result_type)

func activate_chapter_1_goal_debug() -> void:
	current_chapter = 1
	merchant_unlocked = true
	research_station_unlocked = true
	shop_loop_unlocked = true
	manufacturing_station_unlocked = true
	chapter_1_goal_active = true
	chapter_1_completed = false
	first_shop_tutorial_completed = false
	save_profile()

func force_complete_first_shop_tutorial_debug() -> Dictionary:
	current_chapter = 1
	shop_loop_unlocked = true
	research_station_unlocked = true
	manufacturing_station_unlocked = true
	chapter_1_goal_active = false
	chapter_1_completed = true
	first_sale_good_crafted = true
	first_sale_good_shelved = true
	first_shop_settlement_completed = true
	first_shop_tutorial_completed = true
	return save_profile()

func get_chapter_goal_snapshot() -> Dictionary:
	return chapter_progress_service.build_chapter_1_snapshot({
		"chapter_1_goal_active": chapter_1_goal_active,
		"chapter_1_completed": chapter_1_completed,
		"first_sale_good_crafted": first_sale_good_crafted,
		"first_sale_good_shelved": first_sale_good_shelved,
		"first_shop_settlement_completed": first_shop_settlement_completed,
	})

func can_unlock_manufacturing_station() -> bool:
	return false

func unlock_manufacturing_station() -> Dictionary:
	manufacturing_station_unlocked = true
	var default_save_result := save_profile()
	return {
		"ok": true,
		"deprecated": true,
		"message": "Manufacturing is available by default; no currency unlock is required.",
		"surface_day": get_current_day(),
		"save": default_save_result,
	}

func get_legacy_high_tier_roll_state() -> Dictionary:
	return {
		"current_day": get_current_day(),
		"chance_tier": maxi(0, legacy_high_tier_chance_tier),
		"miss_count": maxi(0, legacy_high_tier_miss_count),
		"last_roll_day": maxi(0, legacy_high_tier_last_roll_day),
		"last_roll_result": legacy_high_tier_last_roll_result.duplicate(true),
	}

func apply_legacy_high_tier_roll_result(result: Dictionary) -> void:
	legacy_high_tier_chance_tier = 0
	legacy_high_tier_miss_count = 0
	legacy_high_tier_last_roll_day = maxi(0, int(result.get("day", get_current_day())))
	legacy_high_tier_last_roll_result = {"legacy_disabled": true}
	save_profile()

func reset_legacy_high_tier_roll_state() -> void:
	legacy_high_tier_chance_tier = 0
	legacy_high_tier_miss_count = 0
	legacy_high_tier_last_roll_day = 0
	legacy_high_tier_last_roll_result = {}
	save_profile()

func debug_set_legacy_high_tier_roll_state(chance_tier: int, miss_count: int = 0, last_roll_day: int = 0) -> void:
	legacy_high_tier_chance_tier = maxi(0, chance_tier)
	legacy_high_tier_miss_count = maxi(0, miss_count)
	legacy_high_tier_last_roll_day = maxi(0, last_roll_day)
	legacy_high_tier_last_roll_result = {"legacy_disabled": true}

func debug_force_scene_event_next_run(event_id: String, active: bool = true) -> void:
	if event_id.is_empty():
		return
	forced_scene_events_next_run[event_id] = active

func debug_force_monster_presence_next_run() -> void:
	debug_force_scene_event_next_run("monster_presence", true)

func get_forced_scene_events_next_run() -> Dictionary:
	return forced_scene_events_next_run.duplicate(true)

func consume_forced_scene_events_for_next_run() -> Dictionary:
	var result := forced_scene_events_next_run.duplicate(true)
	forced_scene_events_next_run.clear()
	return result

func set_selected_character(character_id: String) -> void:
	selected_character_id = character_id if character_hud_assets_by_id.has(character_id) else DEFAULT_CHARACTER_ID

func get_selected_character_id() -> String:
	if not character_hud_assets_by_id.has(selected_character_id):
		selected_character_id = DEFAULT_CHARACTER_ID
	return selected_character_id

func _night_locations_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for location_id in NIGHT_LOCATIONS.keys():
		result.append(get_location_resource_briefing(location_id))
	return result

func _normalize_location_id(location_id: String) -> String:
	if NIGHT_LOCATIONS.has(location_id):
		return location_id
	return "abandoned_house"

func _location_resource_record(location_id: String) -> Dictionary:
	var normalized_id := _normalize_location_id(location_id)
	var record: Dictionary = location_resource_states.get(normalized_id, {})
	if record.is_empty():
		return {
			"visit_count": 0,
			"state": "rich",
			"forced_state": "",
			"last_visit_day": 0,
		}
	return record.duplicate(true)

func _state_for_visit_count(visit_count: int) -> String:
	if visit_count <= 0:
		return "rich"
	if visit_count == 1:
		return "normal"
	return "poor"

func _ensure_location_briefing_data_loaded() -> bool:
	if location_briefing_data_loaded:
		return true
	if location_briefing_data_registry == null:
		location_briefing_data_registry = GameDataRegistryScript.new()
	location_briefing_data_loaded = location_briefing_data_registry.load_all()
	return location_briefing_data_loaded

func _fallback_location_resource_briefing(location_id: String, state_id: String) -> Dictionary:
	var location: Dictionary = NIGHT_LOCATIONS.get(location_id, {})
	return {
		"map_id": location_id,
		"display_name": String(location.get("display_name", location_id)),
		"map_type": "",
		"state_id": state_id,
		"state_display_name": _fallback_location_state_display_name(state_id),
		"state_hint": "仅显示资源类别和容器倾向，不显示精确掉落清单。",
		"primary_categories": [],
		"secondary_categories": [],
		"primary_category_names": [],
		"secondary_category_names": [],
		"estimated_container_count_min": 0,
		"estimated_container_count_max": 0,
		"estimated_container_count_text": "?",
		"typical_container_types": [],
		"typical_container_type_names": [],
		"randomness_note": "仅显示资源类别和容器倾向，不显示精确掉落清单。",
	}

func _fallback_location_state_display_name(state_id: String) -> String:
	match state_id:
		"rich":
			return "富集"
		"normal":
			return "普通"
		"poor":
			return "贫瘠"
		"recovering":
			return "恢复中"
		_:
			return state_id

func register_character_hud_assets(character_id: String, assets: Dictionary) -> void:
	if character_id.is_empty():
		return
	var normalized := DEFAULT_CHARACTER_HUD_ASSETS.duplicate()
	for key in assets.keys():
		normalized[key] = assets[key]
	character_hud_assets_by_id[character_id] = normalized

func get_selected_character_hud_assets() -> Dictionary:
	return character_hud_assets_by_id.get(get_selected_character_id(), DEFAULT_CHARACTER_HUD_ASSETS).duplicate()

func clear_warehouse() -> void:
	_bind_warehouse_manager()
	warehouse_manager.clear()
	last_run_result = ""
	last_run_result_type = ""
	save_profile()

func get_warehouse_text() -> String:
	_bind_warehouse_manager()
	return warehouse_manager.get_warehouse_text()

func get_warehouse_items_snapshot() -> Array[Dictionary]:
	_bind_warehouse_manager()
	return warehouse_manager.get_items_snapshot()

func query_warehouse_items(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_warehouse_manager()
	return warehouse_manager.query_items(filters)

func get_warehouse_item_count(item_id: String) -> int:
	_bind_warehouse_manager()
	return warehouse_manager.get_item_count(item_id)

func has_warehouse_materials(requirements: Dictionary) -> bool:
	_bind_warehouse_manager()
	return warehouse_manager.has_materials(requirements)

func consume_warehouse_materials(requirements: Dictionary) -> Dictionary:
	_bind_warehouse_manager()
	var result: Dictionary = warehouse_manager.consume_materials(requirements)
	if bool(result.get("ok", false)):
		save_profile()
	return result

func select_warehouse_item(index: int) -> Dictionary:
	_bind_warehouse_manager()
	return warehouse_manager.select_item_at(index)

func remove_warehouse_item(index: int) -> Dictionary:
	_bind_warehouse_manager()
	return warehouse_manager.remove_item_at(index)

func query_sellable_items(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_merchant_service()
	return merchant_service.query_sellable_items(filters)

func get_sell_quote(warehouse_item_id: String, count: int) -> Dictionary:
	_bind_merchant_service()
	return merchant_service.get_sell_quote(warehouse_item_id, count)

func sell_warehouse_item(warehouse_item_id: String, count: int) -> Dictionary:
	_bind_merchant_service()
	var result: Dictionary = merchant_service.sell_warehouse_item(warehouse_item_id, count)
	if bool(result.get("ok", false)):
		save_profile()
	return result

func get_merchant_shop_level() -> int:
	var researched_level := int(round(_get_research_effect_value("merchant_shop_level", 1.0)))
	return clampi(maxi(merchant_shop_level, researched_level), 1, 3)

func set_merchant_shop_level(level: int) -> void:
	var normalized := clampi(level, 1, 3)
	if merchant_shop_level == normalized:
		return
	merchant_shop_level = normalized
	merchant_shop_offers.clear()
	_bind_merchant_service()
	save_profile()

func refresh_shop_stock(seed: int = -1) -> Array[Dictionary]:
	_bind_merchant_service()
	var offers: Array[Dictionary] = merchant_service.refresh_shop_stock(seed)
	save_profile()
	return offers

func query_shop_offers(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_merchant_service()
	return merchant_service.query_shop_offers(filters)

func get_buy_quote(shop_offer_id: String, count: int) -> Dictionary:
	_bind_merchant_service()
	return merchant_service.get_buy_quote(shop_offer_id, count)

func buy_shop_item(shop_offer_id: String, count: int) -> Dictionary:
	_bind_merchant_service()
	var result: Dictionary = merchant_service.buy_shop_item(shop_offer_id, count)
	if bool(result.get("ok", false)):
		_bind_item_catalog_service()
		item_catalog_service.mark_collected(String(result.get("item_id", "")), "merchant_buy")
		save_profile()
	return result

func mark_item_collected(item_id: String, source: String = "") -> Dictionary:
	_bind_item_catalog_service()
	var result: Dictionary = item_catalog_service.mark_collected(item_id, source)
	if bool(result.get("changed", false)):
		save_profile()
	return result

func mark_items_collected(item_ids: Array, source: String = "") -> Dictionary:
	_bind_item_catalog_service()
	var result: Dictionary = item_catalog_service.mark_many_collected(item_ids, source)
	if bool(result.get("changed", false)):
		save_profile()
	return result

func is_item_collected(item_id: String) -> bool:
	_bind_item_catalog_service()
	return item_catalog_service.is_collected(item_id)

func get_collected_item_ids() -> Dictionary:
	_bind_item_catalog_service()
	return item_catalog_service.get_collected_item_ids()

func query_catalog_items(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_item_catalog_service()
	return item_catalog_service.query_catalog_items(filters)

func clear_collected_items_debug_only() -> void:
	_bind_item_catalog_service()
	item_catalog_service.clear_collected_debug_only()
	save_profile()

func mark_all_catalog_items_collected_debug_only() -> Dictionary:
	_bind_item_catalog_service()
	var result: Dictionary = item_catalog_service.mark_all_collected_debug_only()
	if bool(result.get("changed", false)):
		save_profile()
	return result

func query_research_items(filters: Dictionary = {}) -> Array[Dictionary]:
	_bind_research_manager()
	return research_manager.query_research_items(filters)

func get_research_quote(research_id: String) -> Dictionary:
	_bind_research_manager()
	return research_manager.get_research_quote(research_id)

func complete_research(research_id: String) -> Dictionary:
	_bind_research_manager()
	var result: Dictionary = research_manager.complete_research(research_id)
	if bool(result.get("ok", false)):
		_apply_warehouse_capacity()
		if String(result.get("effect_type", "")) == "merchant_shop_level":
			_apply_merchant_shop_level_from_research()
		save_profile()
	return result

func get_research_level(research_id: String) -> int:
	_bind_research_manager()
	return research_manager.get_research_level(research_id)

func get_player_move_speed_multiplier() -> float:
	_bind_research_manager()
	return research_manager.get_effect_value("player_move_speed_multiplier", 1.0)

func get_inventory_slot_count(default_slots: int = BASE_INVENTORY_SLOTS) -> int:
	return maxi(default_slots, int(round(_get_research_effect_value("inventory_slots", float(default_slots)))))

func get_home_storage_slot_count(default_slots: int = BASE_HOME_STORAGE_SLOTS) -> int:
	return maxi(default_slots, int(round(_get_research_effect_value("home_storage_slots", float(default_slots)))))

func get_outpost_storage_slot_count(default_slots: int = BASE_OUTPOST_STORAGE_SLOTS) -> int:
	return maxi(default_slots, int(round(_get_research_effect_value("outpost_storage_slots", float(default_slots)))))

func get_player_max_stability(default_value: float = BASE_MAX_STABILITY) -> float:
	return maxf(default_value, _get_research_effect_value("max_stability", default_value))

func get_warehouse_capacity(default_capacity: int = BASE_WAREHOUSE_CAPACITY) -> int:
	return maxi(default_capacity, int(round(_get_research_effect_value("warehouse_capacity", float(default_capacity)))))

func get_warehouse_max_capacity(default_capacity: int = BASE_WAREHOUSE_CAPACITY) -> int:
	if research_manager == null:
		research_manager = ResearchManagerScript.new()
	research_manager.research_levels = research_levels
	return maxi(default_capacity, int(round(research_manager.get_max_effect_value("warehouse_capacity", float(default_capacity)))))

func reset_research() -> void:
	_bind_research_manager()
	research_manager.reset_research()
	_apply_warehouse_capacity()
	merchant_shop_level = 1
	merchant_shop_offers.clear()
	_bind_merchant_service()
	save_profile()

func get_currency_amount(currency_id: String = "mine_coin") -> int:
	_bind_currency_wallet()
	return currency_wallet.get_currency_amount(currency_id)

func add_currency(currency_id: String, amount: int, reason: String = "") -> Dictionary:
	_bind_currency_wallet()
	var result: Dictionary = currency_wallet.add_currency(currency_id, amount, reason)
	if bool(result.get("ok", false)):
		save_profile()
	return result

func spend_currency(currency_id: String, amount: int, reason: String = "") -> Dictionary:
	_bind_currency_wallet()
	var result: Dictionary = currency_wallet.spend_currency(currency_id, amount, reason)
	if bool(result.get("ok", false)):
		save_profile()
	return result

func clear_currencies() -> void:
	_bind_currency_wallet()
	currency_wallet.clear()
	save_profile()

func get_currencies_snapshot() -> Dictionary:
	_bind_currency_wallet()
	return currency_wallet.get_currencies_snapshot()

func get_currency_display_text(currency_id: String = "mine_coin") -> String:
	_bind_currency_wallet()
	return currency_wallet.get_currency_display_text(currency_id)

func _bind_warehouse_manager() -> void:
	if warehouse_manager == null:
		warehouse_manager = WarehouseManagerScript.new()
	warehouse_manager.bind_items(warehouse_items)
	_apply_warehouse_capacity()

func _apply_profile_to_runtime(loaded_profile: Dictionary) -> void:
	if loaded_profile.is_empty():
		return
	var should_save_repaired_profile := false
	username = String(loaded_profile.get("username", ""))
	current_chapter = maxi(1, int(loaded_profile.get("current_chapter", 1)))
	current_day = maxi(0, int(loaded_profile.get("surface_day", 0)))
	var legacy_intro_seen := bool(loaded_profile.get("first_intro_dialogue_seen", false))
	intro_cinematic_seen = bool(loaded_profile.get("intro_cinematic_seen", legacy_intro_seen))
	world_intro_dialogue_seen = bool(loaded_profile.get("world_intro_dialogue_seen", legacy_intro_seen))
	first_departure_outpost_dialogue_seen = bool(loaded_profile.get("first_departure_outpost_dialogue_seen", false))
	first_intro_dialogue_seen = world_intro_dialogue_seen
	first_return_dialogue_seen = bool(loaded_profile.get("first_return_dialogue_seen", false))
	second_day_black_tide_reveal_seen = bool(loaded_profile.get("second_day_black_tide_reveal_seen", false))
	merchant_unlocked = bool(loaded_profile.get("merchant_unlocked", first_return_dialogue_seen))
	research_station_unlocked = bool(loaded_profile.get("research_station_unlocked", first_return_dialogue_seen))
	shop_loop_unlocked = bool(loaded_profile.get("shop_loop_unlocked", first_return_dialogue_seen))
	starter_shop_supply_granted = bool(loaded_profile.get("starter_shop_supply_granted", false))
	first_sale_good_crafted = bool(loaded_profile.get("first_sale_good_crafted", false))
	first_sale_good_shelved = bool(loaded_profile.get("first_sale_good_shelved", false))
	first_shop_settlement_completed = bool(loaded_profile.get("first_shop_settlement_completed", false))
	first_shop_tutorial_completed = bool(loaded_profile.get("first_shop_tutorial_completed", false))
	chapter_1_goal_active = bool(loaded_profile.get("chapter_1_goal_active", false))
	manufacturing_station_unlocked = bool(loaded_profile.get("manufacturing_station_unlocked", true)) or shop_loop_unlocked
	chapter_1_completed = bool(loaded_profile.get("chapter_1_completed", false))
	if first_shop_tutorial_completed:
		chapter_1_completed = true
		chapter_1_goal_active = false
	pending_first_return_dialogue = bool(loaded_profile.get("pending_first_return_dialogue", false))
	_run_start_pending_result = bool(loaded_profile.get("run_start_pending_result", false))
	selected_character_id = String(loaded_profile.get("selected_character_id", DEFAULT_CHARACTER_ID))
	selected_night_location_id = _normalize_location_id(String(loaded_profile.get("selected_night_location_id", "abandoned_house")))
	location_resource_states.clear()
	var loaded_location_resource_states: Dictionary = loaded_profile.get("location_resource_states", {})
	for key in loaded_location_resource_states.keys():
		var normalized_key := _normalize_location_id(String(key))
		var value = loaded_location_resource_states.get(key, {})
		if value is Dictionary:
			location_resource_states[normalized_key] = Dictionary(value).duplicate(true)
	outgame_phase = String(loaded_profile.get("outgame_phase", OUTGAME_PHASE_DAY_PREP))
	if _recover_departure_phase_to_night():
		should_save_repaired_profile = true
	_repair_legacy_first_run_return_state()

	warehouse_items.clear()
	for item in Array(loaded_profile.get("warehouse_items", [])):
		if item is Dictionary:
			var item_dict: Dictionary = item
			warehouse_items.append(item_dict.duplicate(true))

	currencies.clear()
	var loaded_currencies: Dictionary = loaded_profile.get("currencies", {})
	for key in loaded_currencies.keys():
		currencies[String(key)] = int(loaded_currencies.get(key, 0))

	research_levels.clear()
	var loaded_research_levels: Dictionary = loaded_profile.get("research_levels", {})
	for key in loaded_research_levels.keys():
		research_levels[String(key)] = int(loaded_research_levels.get(key, 0))

	collected_item_ids.clear()
	var loaded_collected_item_ids: Dictionary = loaded_profile.get("collected_item_ids", {})
	for key in loaded_collected_item_ids.keys():
		if bool(loaded_collected_item_ids.get(key, false)):
			collected_item_ids[String(key)] = true

	merchant_shop_level = clampi(int(loaded_profile.get("merchant_shop_level", 1)), 1, 3)
	merchant_shop_offers.clear()
	for offer in Array(loaded_profile.get("merchant_shop_offers", [])):
		if offer is Dictionary:
			var offer_dict: Dictionary = offer
			merchant_shop_offers.append(offer_dict.duplicate(true))

	var legacy_high_tier_state: Dictionary = loaded_profile.get("legacy_high_tier_roll_state", loaded_profile.get("ss_roll_state", {}))
	legacy_high_tier_chance_tier = maxi(0, int(legacy_high_tier_state.get("chance_tier", loaded_profile.get("ss_chance_tier", 0))))
	legacy_high_tier_miss_count = maxi(0, int(legacy_high_tier_state.get("miss_count", loaded_profile.get("ss_miss_count", 0))))
	legacy_high_tier_last_roll_day = maxi(0, int(legacy_high_tier_state.get("last_roll_day", loaded_profile.get("ss_last_roll_day", 0))))
	var loaded_legacy_high_tier_result: Dictionary = legacy_high_tier_state.get("last_roll_result", loaded_profile.get("ss_last_roll_result", {}))
	legacy_high_tier_last_roll_result = loaded_legacy_high_tier_result.duplicate(true)
	last_run_result = String(loaded_profile.get("last_run_result", ""))
	last_run_result_type = String(loaded_profile.get("last_run_result_type", ""))

	daily_demand_day = maxi(0, int(loaded_profile.get("daily_demand_day", 0)))
	daily_demand_entries.clear()
	for entry in Array(loaded_profile.get("daily_demand_entries", [])):
		if entry is Dictionary:
			var entry_dict: Dictionary = entry
			daily_demand_entries.append(entry_dict.duplicate(true))
	shop_shelf_items.clear()
	for item in Array(loaded_profile.get("shop_shelf_items", [])):
		if item is Dictionary:
			var shelf_item: Dictionary = item
			shop_shelf_items.append(shelf_item.duplicate(true))
	shop_sales_records.clear()
	for record in Array(loaded_profile.get("shop_sales_records", [])):
		if record is Dictionary:
			var record_dict: Dictionary = record
			shop_sales_records.append(record_dict.duplicate(true))
	shop_elapsed_seconds = maxf(0.0, float(loaded_profile.get("shop_elapsed_seconds", 0.0)))
	shop_next_sale_second = maxf(0.0, float(loaded_profile.get("shop_next_sale_second", 5.0)))
	shop_duration_seconds = maxf(1.0, float(loaded_profile.get("shop_duration_seconds", SHOP_DURATION_SECONDS)))
	shop_settlement_applied = bool(loaded_profile.get("shop_settlement_applied", false))
	shop_ended_by = String(loaded_profile.get("shop_ended_by", ""))
	loadout_equipment_slots = Dictionary(loaded_profile.get("loadout_equipment_slots", {"HEAD": "", "BODY": "", "HAND": "", "FOOT": ""})).duplicate(true)
	loadout_consumable_slots = Array(loaded_profile.get("loadout_consumable_slots", ["", "", "", ""])).duplicate(true)
	_normalize_outgame_phase()
	_normalize_loadout_slots()
	_bind_shop_services()
	if first_return_dialogue_seen and not starter_shop_supply_granted:
		var grant_result := _grant_starter_shop_supply_if_needed()
		if bool(grant_result.get("ok", false)):
			should_save_repaired_profile = true
	if should_save_repaired_profile:
		save_profile()

func _repair_legacy_first_run_return_state() -> void:
	if first_return_dialogue_seen or pending_first_return_dialogue or _run_start_pending_result:
		return
	if not first_departure_outpost_dialogue_seen:
		return
	if current_day != 1:
		return
	current_day = 2
	pending_first_return_dialogue = true

func _sync_runtime_to_profile() -> void:
	if profile.is_empty():
		return
	profile["username"] = username
	profile["last_played_at_unix"] = Time.get_unix_time_from_system()
	profile["current_chapter"] = current_chapter
	profile["surface_day"] = get_current_day()
	if first_intro_dialogue_seen:
		world_intro_dialogue_seen = true
	profile["intro_cinematic_seen"] = intro_cinematic_seen
	profile["world_intro_dialogue_seen"] = world_intro_dialogue_seen
	profile["first_departure_outpost_dialogue_seen"] = first_departure_outpost_dialogue_seen
	profile["first_intro_dialogue_seen"] = world_intro_dialogue_seen
	profile["first_return_dialogue_seen"] = first_return_dialogue_seen
	profile["second_day_black_tide_reveal_seen"] = second_day_black_tide_reveal_seen
	profile["merchant_unlocked"] = merchant_unlocked
	profile["research_station_unlocked"] = research_station_unlocked
	profile["shop_loop_unlocked"] = shop_loop_unlocked
	profile["starter_shop_supply_granted"] = starter_shop_supply_granted
	profile["first_sale_good_crafted"] = first_sale_good_crafted
	profile["first_sale_good_shelved"] = first_sale_good_shelved
	profile["first_shop_settlement_completed"] = first_shop_settlement_completed
	profile["first_shop_tutorial_completed"] = first_shop_tutorial_completed
	profile["chapter_1_goal_active"] = chapter_1_goal_active
	profile["manufacturing_station_unlocked"] = manufacturing_station_unlocked
	profile["chapter_1_completed"] = chapter_1_completed
	profile["pending_first_return_dialogue"] = pending_first_return_dialogue
	profile["run_start_pending_result"] = _run_start_pending_result
	profile["selected_character_id"] = get_selected_character_id()
	profile["selected_night_location_id"] = selected_night_location_id
	profile["location_resource_states"] = location_resource_states.duplicate(true)
	profile["outgame_phase"] = get_outgame_phase()
	profile["currencies"] = currencies.duplicate(true)
	profile["warehouse_items"] = warehouse_items.duplicate(true)
	profile["research_levels"] = research_levels.duplicate(true)
	profile["collected_item_ids"] = collected_item_ids.duplicate(true)
	profile["merchant_shop_level"] = merchant_shop_level
	profile["merchant_shop_offers"] = merchant_shop_offers.duplicate(true)
	profile.erase("ss_roll_state")
	profile.erase("ss_chance_tier")
	profile.erase("ss_miss_count")
	profile.erase("ss_last_roll_day")
	profile.erase("ss_last_roll_result")
	profile["last_run_result"] = last_run_result
	profile["last_run_result_type"] = last_run_result_type
	profile["daily_demand_day"] = daily_demand_day
	profile["daily_demand_entries"] = daily_demand_entries.duplicate(true)
	profile["shop_shelf_items"] = shop_shelf_items.duplicate(true)
	profile["shop_sales_records"] = shop_sales_records.duplicate(true)
	profile["shop_elapsed_seconds"] = shop_elapsed_seconds
	profile["shop_next_sale_second"] = shop_next_sale_second
	profile["shop_duration_seconds"] = shop_duration_seconds
	profile["shop_settlement_applied"] = shop_settlement_applied
	profile["shop_ended_by"] = shop_ended_by
	profile["loadout_equipment_slots"] = loadout_equipment_slots.duplicate(true)
	profile["loadout_consumable_slots"] = loadout_consumable_slots.duplicate(true)

func _bind_currency_wallet() -> void:
	if currency_wallet == null:
		currency_wallet = CurrencyWalletScript.new()
	currency_wallet.bind_currencies(currencies)

func _bind_merchant_service() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if merchant_service == null:
		merchant_service = MerchantServiceScript.new()
	merchant_service.bind_dependencies(warehouse_manager, currency_wallet, merchant_shop_offers, get_merchant_shop_level())

func _bind_research_manager() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if research_manager == null:
		research_manager = ResearchManagerScript.new()
	research_manager.bind_dependencies(warehouse_manager, currency_wallet, research_levels, _get_research_condition_state())

func _bind_item_catalog_service() -> void:
	if item_catalog_service == null:
		item_catalog_service = ItemCatalogServiceScript.new()
	item_catalog_service.bind_collected_items(collected_item_ids)

func _bind_crafting_manager() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if crafting_manager == null:
		crafting_manager = CraftingManagerScript.new()
	crafting_manager.bind_dependencies(warehouse_manager, currency_wallet)

func _bind_shop_services() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if daily_demand_service == null:
		daily_demand_service = DailyDemandServiceScript.new()
	if shelf_inventory_service == null:
		shelf_inventory_service = ShelfInventoryServiceScript.new()
	if shop_sales_service == null:
		shop_sales_service = ShopSalesServiceScript.new()
	shelf_inventory_service.bind_dependencies(warehouse_manager, shop_shelf_items, SHOP_SHELF_SLOT_COUNT)
	shop_sales_service.bind_dependencies(shelf_inventory_service, daily_demand_entries, shop_sales_records)

func _reset_shop_day_state(next_phase: String) -> void:
	outgame_phase = next_phase if _is_valid_outgame_phase(next_phase) else OUTGAME_PHASE_DAY_PREP
	daily_demand_day = 0
	daily_demand_entries.clear()
	shop_shelf_items.clear()
	for _index in range(SHOP_SHELF_SLOT_COUNT):
		shop_shelf_items.append({})
	shop_sales_records.clear()
	shop_elapsed_seconds = 0.0
	shop_next_sale_second = 5.0
	shop_duration_seconds = SHOP_DURATION_SECONDS
	shop_settlement_applied = false
	shop_ended_by = ""

func _return_all_shelf_items_without_save() -> void:
	_bind_shop_services()
	if shelf_inventory_service != null:
		shelf_inventory_service.return_all_to_warehouse()

func _normalize_outgame_phase() -> void:
	if not _is_valid_outgame_phase(outgame_phase):
		outgame_phase = OUTGAME_PHASE_DAY_PREP
	if (
		not shop_loop_unlocked
		and world_intro_dialogue_seen
		and not pending_first_return_dialogue
		and outgame_phase == OUTGAME_PHASE_DAY_PREP
	):
		outgame_phase = OUTGAME_PHASE_NIGHT
	if outgame_phase == OUTGAME_PHASE_LOADING_TO_RUN and not _run_start_pending_result:
		outgame_phase = OUTGAME_PHASE_NIGHT

func _recover_departure_phase_to_night() -> bool:
	if not [
		OUTGAME_PHASE_LOADING_TO_RUN,
		OUTGAME_PHASE_NIGHT_PLAN,
		OUTGAME_PHASE_LOADOUT,
	].has(outgame_phase):
		return false
	_run_start_pending_result = false
	outgame_phase = OUTGAME_PHASE_NIGHT
	return true

func _is_valid_outgame_phase(phase: String) -> bool:
	return [
		OUTGAME_PHASE_DAY_PREP,
		OUTGAME_PHASE_SHOP_OPEN,
		OUTGAME_PHASE_SHOP_SETTLEMENT,
		OUTGAME_PHASE_NIGHT,
		OUTGAME_PHASE_NIGHT_PLAN,
		OUTGAME_PHASE_LOADOUT,
		OUTGAME_PHASE_LOADING_TO_RUN,
	].has(phase)

func _normalize_loadout_slots() -> void:
	for key in ["HEAD", "BODY", "HAND", "FOOT"]:
		if not loadout_equipment_slots.has(key):
			loadout_equipment_slots[key] = ""
	while loadout_consumable_slots.size() < LOADOUT_CONSUMABLE_SLOT_COUNT:
		loadout_consumable_slots.append("")
	while loadout_consumable_slots.size() > LOADOUT_CONSUMABLE_SLOT_COUNT:
		loadout_consumable_slots.pop_back()

func _mark_items_collected(items: Array, source: String) -> Dictionary:
	var item_ids: Array[String] = []
	for item in items:
		if item is Dictionary:
			var item_id := String(item.get("item_id", ""))
			if not item_id.is_empty():
				item_ids.append(item_id)
	return mark_items_collected(item_ids, source)

func _get_research_effect_value(effect_type: String, default_value: float) -> float:
	if research_manager == null:
		research_manager = ResearchManagerScript.new()
	research_manager.research_levels = research_levels
	return research_manager.get_effect_value(effect_type, default_value)

func _get_research_condition_state() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"shop_level": clampi(merchant_shop_level, 1, 3),
		"completed_tasks": {
			"first_shop_tutorial": first_shop_tutorial_completed,
			"chapter_1": chapter_1_completed,
		},
		"installed_fixtures": {},
		"conditions": {
			"chapter_1_goal_active": chapter_1_goal_active,
			"chapter_1_completed": chapter_1_completed,
			"first_sale_good_crafted": first_sale_good_crafted,
			"first_sale_good_shelved": first_sale_good_shelved,
			"first_shop_settlement_completed": first_shop_settlement_completed,
			"first_shop_tutorial_completed": first_shop_tutorial_completed,
			"research_station_unlocked": is_research_station_unlocked(),
			"shop_loop_unlocked": shop_loop_unlocked,
			"manufacturing_station_unlocked": manufacturing_station_unlocked,
		},
	}

func _apply_warehouse_capacity() -> void:
	if warehouse_manager == null:
		return
	warehouse_manager.set_capacity(get_warehouse_capacity(BASE_WAREHOUSE_CAPACITY))

func _apply_merchant_shop_level_from_research() -> void:
	var researched_level := int(round(_get_research_effect_value("merchant_shop_level", 1.0)))
	var normalized := clampi(maxi(merchant_shop_level, researched_level), 1, 3)
	if merchant_shop_level != normalized:
		merchant_shop_level = normalized
		merchant_shop_offers.clear()
	_bind_merchant_service()

extends Node

const WarehouseManagerScript := preload("res://scripts/game/warehouse_manager.gd")
const CurrencyWalletScript := preload("res://scripts/game/currency_wallet.gd")
const MerchantServiceScript := preload("res://scripts/game/merchant_service.gd")
const ResearchManagerScript := preload("res://scripts/game/research_manager.gd")
const ProfileServiceScript := preload("res://scripts/profile/profile_service.gd")

const BASE_INVENTORY_SLOTS := 8
const BASE_HOME_STORAGE_SLOTS := 1
const BASE_OUTPOST_STORAGE_SLOTS := 0
const BASE_MAX_STABILITY := 100.0
const BASE_WAREHOUSE_CAPACITY := 80
const MANUFACTURING_UNLOCK_COST := 5000
const DEFAULT_CHARACTER_ID := "male_01"
const DEFAULT_CHARACTER_HUD_ASSETS := {
	"portrait_path": "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_male_01.png",
	"portrait_frame_path": "res://assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_frame_empty_ref_01.png",
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
var chapter_1_goal_active: bool = false
var manufacturing_station_unlocked: bool = false
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
var ss_chance_tier: int = 0
var ss_miss_count: int = 0
var ss_last_roll_day: int = 0
var ss_last_roll_result: Dictionary = {}
var forced_scene_events_next_run: Dictionary = {}
var last_run_result: String = ""
var warehouse_manager = WarehouseManagerScript.new()
var currency_wallet = CurrencyWalletScript.new()
var merchant_service = MerchantServiceScript.new()
var research_manager = ResearchManagerScript.new()
var profile_service = ProfileServiceScript.new()

func _ready() -> void:
	load_profile()
	_bind_warehouse_manager()
	_bind_currency_wallet()
	_bind_merchant_service()
	_bind_research_manager()

func add_to_warehouse(items: Array) -> Array[Dictionary]:
	_bind_warehouse_manager()
	var accepted: Array[Dictionary] = warehouse_manager.add_items(items)
	if not accepted.is_empty():
		save_profile()
	return accepted

func apply_run_result(result: Dictionary) -> void:
	_bind_warehouse_manager()
	last_run_result = str(result.get("message", ""))
	warehouse_manager.add_items(result.get("warehouse_items", []))
	advance_day_after_run(result)
	if String(result.get("result_type", "")) == "EXTRACTED" and not first_return_dialogue_seen:
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
		merchant_shop_offers.clear()
		_bind_merchant_service()
		save_profile()
		return current_day
	current_day = get_current_day() + 1
	merchant_shop_offers.clear()
	_bind_merchant_service()
	save_profile()
	return current_day

func reset_day(day: int = 1) -> void:
	current_day = maxi(0, day)
	_run_start_pending_result = false
	merchant_shop_offers.clear()
	_bind_merchant_service()
	save_profile()

func commit_run_start(debug_run: bool = false) -> Dictionary:
	if debug_run:
		return {"ok": true, "surface_day": get_current_day(), "debug": true}
	current_day = get_current_day() + 1
	_run_start_pending_result = true
	merchant_shop_offers.clear()
	_bind_merchant_service()
	var save_result := save_profile()
	if not bool(save_result.get("ok", true)):
		return save_result
	return {"ok": true, "surface_day": current_day}

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
	ss_chance_tier = 0
	ss_miss_count = 0
	ss_last_roll_day = 0
	ss_last_roll_result = {}
	forced_scene_events_next_run.clear()
	last_run_result = ""
	_bind_warehouse_manager()
	_bind_currency_wallet()
	_bind_merchant_service()
	_bind_research_manager()

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

func mark_first_return_dialogue_seen_and_activate_chapter() -> Dictionary:
	first_return_dialogue_seen = true
	pending_first_return_dialogue = false
	chapter_1_goal_active = true
	current_chapter = 1
	return save_profile()

func reset_story_flags() -> void:
	intro_cinematic_seen = false
	world_intro_dialogue_seen = false
	first_departure_outpost_dialogue_seen = false
	first_intro_dialogue_seen = false
	first_return_dialogue_seen = false
	pending_first_return_dialogue = false
	chapter_1_goal_active = false
	chapter_1_completed = false
	manufacturing_station_unlocked = false
	save_profile()

func activate_chapter_1_goal_debug() -> void:
	current_chapter = 1
	chapter_1_goal_active = true
	chapter_1_completed = false
	manufacturing_station_unlocked = false
	save_profile()

func get_chapter_goal_snapshot() -> Dictionary:
	return {
		"chapter_id": "chapter_1",
		"title": "第一章：解锁制造所",
		"active": chapter_1_goal_active and not chapter_1_completed,
		"completed": chapter_1_completed,
		"feature_id": "manufacturing_station",
		"currency_id": "mine_coin",
		"current_currency": get_currency_amount("mine_coin"),
		"required_currency": MANUFACTURING_UNLOCK_COST,
		"manufacturing_station_unlocked": manufacturing_station_unlocked,
		"surface_day": get_current_day(),
	}

func can_unlock_manufacturing_station() -> bool:
	return (
		current_chapter == 1
		and chapter_1_goal_active
		and not manufacturing_station_unlocked
		and get_currency_amount("mine_coin") >= MANUFACTURING_UNLOCK_COST
	)

func unlock_manufacturing_station() -> Dictionary:
	if manufacturing_station_unlocked:
		return {"ok": false, "reason": "already_unlocked", "message": "制造所已经解锁。"}
	if not chapter_1_goal_active:
		return {"ok": false, "reason": "goal_inactive", "message": "第一章目标尚未激活。"}
	if get_currency_amount("mine_coin") < MANUFACTURING_UNLOCK_COST:
		return {"ok": false, "reason": "not_enough_currency", "message": "矿币不足，无法解锁制造所。"}
	_bind_currency_wallet()
	var spend_result: Dictionary = currency_wallet.spend_currency("mine_coin", MANUFACTURING_UNLOCK_COST, "manufacturing_unlock")
	if not bool(spend_result.get("ok", false)):
		return {"ok": false, "reason": spend_result.get("reason", "currency_failed"), "message": "矿币扣除失败。"}
	manufacturing_station_unlocked = true
	chapter_1_completed = true
	chapter_1_goal_active = false
	var save_result := save_profile()
	if not bool(save_result.get("ok", true)):
		currency_wallet.add_currency("mine_coin", MANUFACTURING_UNLOCK_COST, "manufacturing_unlock_rollback")
		manufacturing_station_unlocked = false
		chapter_1_completed = false
		chapter_1_goal_active = true
		return {"ok": false, "reason": "save_failed", "message": "保存失败，制造所未解锁。"}
	return {
		"ok": true,
		"message": "制造所已解锁。",
		"surface_day": get_current_day(),
		"currency_spent": MANUFACTURING_UNLOCK_COST,
	}

func get_ss_roll_state() -> Dictionary:
	return {
		"current_day": get_current_day(),
		"chance_tier": maxi(0, ss_chance_tier),
		"miss_count": maxi(0, ss_miss_count),
		"last_roll_day": maxi(0, ss_last_roll_day),
		"last_roll_result": ss_last_roll_result.duplicate(true),
	}

func apply_ss_roll_result(result: Dictionary) -> void:
	ss_chance_tier = maxi(0, int(result.get("next_chance_tier", ss_chance_tier)))
	ss_miss_count = maxi(0, int(result.get("next_miss_count", ss_miss_count)))
	ss_last_roll_day = maxi(0, int(result.get("day", get_current_day())))
	ss_last_roll_result = result.duplicate(true)
	save_profile()

func reset_ss_roll_state() -> void:
	ss_chance_tier = 0
	ss_miss_count = 0
	ss_last_roll_day = 0
	ss_last_roll_result = {}
	save_profile()

func debug_set_ss_roll_state(chance_tier: int, miss_count: int = 0, last_roll_day: int = 0) -> void:
	ss_chance_tier = maxi(0, chance_tier)
	ss_miss_count = maxi(0, miss_count)
	ss_last_roll_day = maxi(0, last_roll_day)
	ss_last_roll_result = {}

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
	save_profile()

func get_warehouse_text() -> String:
	_bind_warehouse_manager()
	return warehouse_manager.get_warehouse_text()

func get_warehouse_items_snapshot() -> Array[Dictionary]:
	_bind_warehouse_manager()
	return warehouse_manager.get_items_snapshot()

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
	return merchant_shop_level

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
	username = String(loaded_profile.get("username", ""))
	current_chapter = maxi(1, int(loaded_profile.get("current_chapter", 1)))
	current_day = maxi(0, int(loaded_profile.get("surface_day", 0)))
	var legacy_intro_seen := bool(loaded_profile.get("first_intro_dialogue_seen", false))
	intro_cinematic_seen = bool(loaded_profile.get("intro_cinematic_seen", legacy_intro_seen))
	world_intro_dialogue_seen = bool(loaded_profile.get("world_intro_dialogue_seen", legacy_intro_seen))
	first_departure_outpost_dialogue_seen = bool(loaded_profile.get("first_departure_outpost_dialogue_seen", false))
	first_intro_dialogue_seen = world_intro_dialogue_seen
	first_return_dialogue_seen = bool(loaded_profile.get("first_return_dialogue_seen", false))
	chapter_1_goal_active = bool(loaded_profile.get("chapter_1_goal_active", false))
	manufacturing_station_unlocked = bool(loaded_profile.get("manufacturing_station_unlocked", false))
	chapter_1_completed = bool(loaded_profile.get("chapter_1_completed", false))
	pending_first_return_dialogue = bool(loaded_profile.get("pending_first_return_dialogue", false))
	_run_start_pending_result = bool(loaded_profile.get("run_start_pending_result", false))

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

	merchant_shop_level = clampi(int(loaded_profile.get("merchant_shop_level", 1)), 1, 3)
	merchant_shop_offers.clear()
	for offer in Array(loaded_profile.get("merchant_shop_offers", [])):
		if offer is Dictionary:
			var offer_dict: Dictionary = offer
			merchant_shop_offers.append(offer_dict.duplicate(true))

	var ss_state: Dictionary = loaded_profile.get("ss_roll_state", {})
	ss_chance_tier = maxi(0, int(ss_state.get("chance_tier", loaded_profile.get("ss_chance_tier", 0))))
	ss_miss_count = maxi(0, int(ss_state.get("miss_count", loaded_profile.get("ss_miss_count", 0))))
	ss_last_roll_day = maxi(0, int(ss_state.get("last_roll_day", loaded_profile.get("ss_last_roll_day", 0))))
	var loaded_ss_result: Dictionary = ss_state.get("last_roll_result", loaded_profile.get("ss_last_roll_result", {}))
	ss_last_roll_result = loaded_ss_result.duplicate(true)

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
	profile["chapter_1_goal_active"] = chapter_1_goal_active
	profile["manufacturing_station_unlocked"] = manufacturing_station_unlocked
	profile["chapter_1_completed"] = chapter_1_completed
	profile["pending_first_return_dialogue"] = pending_first_return_dialogue
	profile["run_start_pending_result"] = _run_start_pending_result
	profile["currencies"] = currencies.duplicate(true)
	profile["warehouse_items"] = warehouse_items.duplicate(true)
	profile["research_levels"] = research_levels.duplicate(true)
	profile["merchant_shop_level"] = merchant_shop_level
	profile["merchant_shop_offers"] = merchant_shop_offers.duplicate(true)
	profile["ss_roll_state"] = {
		"chance_tier": ss_chance_tier,
		"miss_count": ss_miss_count,
		"last_roll_day": ss_last_roll_day,
		"last_roll_result": ss_last_roll_result.duplicate(true),
	}

func _bind_currency_wallet() -> void:
	if currency_wallet == null:
		currency_wallet = CurrencyWalletScript.new()
	currency_wallet.bind_currencies(currencies)

func _bind_merchant_service() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if merchant_service == null:
		merchant_service = MerchantServiceScript.new()
	merchant_service.bind_dependencies(warehouse_manager, currency_wallet, merchant_shop_offers, merchant_shop_level)

func _bind_research_manager() -> void:
	_bind_warehouse_manager()
	_bind_currency_wallet()
	if research_manager == null:
		research_manager = ResearchManagerScript.new()
	research_manager.bind_dependencies(warehouse_manager, currency_wallet, research_levels)

func _get_research_effect_value(effect_type: String, default_value: float) -> float:
	if research_manager == null:
		research_manager = ResearchManagerScript.new()
	research_manager.research_levels = research_levels
	return research_manager.get_effect_value(effect_type, default_value)

func _apply_warehouse_capacity() -> void:
	if warehouse_manager == null:
		return
	warehouse_manager.set_capacity(get_warehouse_capacity(BASE_WAREHOUSE_CAPACITY))

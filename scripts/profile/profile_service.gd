class_name ProfileService
extends RefCounted

const FileSaveStorageAdapterScript := preload("res://scripts/profile/file_save_storage_adapter.gd")

const PROFILE_ID := "local_profile_001"
const DEFAULT_CURRENCY_ID := "mine_coin"

var storage

func _init(adapter = null) -> void:
	if adapter != null:
		storage = adapter
	else:
		storage = FileSaveStorageAdapterScript.new()

func has_profile() -> bool:
	return storage != null and storage.has_profile()

func load_profile() -> Dictionary:
	if storage == null:
		return {}
	return _with_defaults(storage.load_profile())

func save_profile(profile: Dictionary) -> Dictionary:
	if storage == null:
		return {"ok": false, "reason": "missing_storage"}
	return storage.save_profile(_with_defaults(profile))

func create_profile(username: String) -> Dictionary:
	var normalized := username.strip_edges()
	var validation := validate_username(normalized)
	if not bool(validation.get("ok", false)):
		return validation
	var profile := default_profile(normalized)
	var save_result := save_profile(profile)
	if not bool(save_result.get("ok", false)):
		return save_result
	save_result["profile"] = profile
	return save_result

func validate_username(username: String) -> Dictionary:
	var normalized := username.strip_edges()
	var length := normalized.length()
	if length < 2 or length > 12:
		return {"ok": false, "reason": "invalid_username", "message": "请输入 2-12 个字符的用户名"}
	var regex := RegEx.new()
	regex.compile("^[\\p{Han}A-Za-z0-9_]+$")
	if regex.search(normalized) == null:
		return {"ok": false, "reason": "invalid_username", "message": "请输入 2-12 个字符的用户名"}
	return {"ok": true, "username": normalized}

func delete_profile_debug_only() -> Dictionary:
	if storage == null:
		return {"ok": false, "reason": "missing_storage"}
	return storage.delete_profile_debug_only()

func default_profile(username: String) -> Dictionary:
	var now := Time.get_unix_time_from_system()
	return {
		"profile_id": PROFILE_ID,
		"username": username,
		"created_at_unix": now,
		"last_played_at_unix": now,
		"current_chapter": 1,
		"surface_day": 0,
		"intro_cinematic_seen": false,
		"world_intro_dialogue_seen": false,
		"first_departure_outpost_dialogue_seen": false,
		"first_intro_dialogue_seen": false,
		"first_return_dialogue_seen": false,
		"second_day_black_tide_reveal_seen": false,
		"merchant_unlocked": false,
		"research_station_unlocked": false,
		"shop_loop_unlocked": false,
		"starter_shop_supply_granted": false,
		"first_sale_good_crafted": false,
		"first_sale_good_shelved": false,
		"first_shop_settlement_completed": false,
		"first_shop_tutorial_completed": false,
		"chapter_1_goal_active": false,
		"manufacturing_station_unlocked": true,
		"chapter_1_completed": false,
		"currencies": {DEFAULT_CURRENCY_ID: 0},
		"warehouse_items": [],
		"research_levels": {},
		"collected_item_ids": {},
		"merchant_shop_level": 1,
		"merchant_shop_offers": [],
		"ss_roll_state": {},
		"selected_character_id": "male_01",
		"selected_night_location_id": "abandoned_house",
		"last_run_result_type": "",
		"outgame_phase": "NIGHT",
		"daily_demand_day": 0,
		"daily_demand_entries": [],
		"shop_shelf_items": [],
		"shop_sales_records": [],
		"shop_elapsed_seconds": 0.0,
		"shop_next_sale_second": 5.0,
		"shop_duration_seconds": 60.0,
		"shop_settlement_applied": false,
		"shop_ended_by": "",
		"loadout_equipment_slots": {"HEAD": "", "BODY": "", "HAND": "", "FOOT": ""},
		"loadout_consumable_slots": ["", "", "", ""],
	}

func _with_defaults(profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return {}
	var had_intro_cinematic := profile.has("intro_cinematic_seen")
	var had_world_intro := profile.has("world_intro_dialogue_seen")
	var had_first_departure := profile.has("first_departure_outpost_dialogue_seen")
	var had_merchant_unlocked := profile.has("merchant_unlocked")
	var had_research_station_unlocked := profile.has("research_station_unlocked")
	var had_shop_loop_unlocked := profile.has("shop_loop_unlocked")
	var had_manufacturing_station_unlocked := profile.has("manufacturing_station_unlocked")
	var merged := default_profile(String(profile.get("username", "玩家")))
	for key in profile.keys():
		merged[key] = profile[key]
	if not had_intro_cinematic:
		merged["intro_cinematic_seen"] = bool(merged.get("first_intro_dialogue_seen", false))
	if not had_world_intro:
		merged["world_intro_dialogue_seen"] = bool(merged.get("first_intro_dialogue_seen", false))
	if not had_first_departure:
		merged["first_departure_outpost_dialogue_seen"] = false
	if not had_merchant_unlocked:
		merged["merchant_unlocked"] = bool(merged.get("first_return_dialogue_seen", false))
	if not had_research_station_unlocked:
		merged["research_station_unlocked"] = bool(merged.get("first_return_dialogue_seen", false))
	if not had_shop_loop_unlocked:
		merged["shop_loop_unlocked"] = bool(merged.get("first_return_dialogue_seen", false))
	if not had_manufacturing_station_unlocked or bool(merged.get("shop_loop_unlocked", false)):
		merged["manufacturing_station_unlocked"] = true
	merged["starter_shop_supply_granted"] = bool(merged.get("starter_shop_supply_granted", false))
	merged["first_sale_good_crafted"] = bool(merged.get("first_sale_good_crafted", false))
	merged["first_sale_good_shelved"] = bool(merged.get("first_sale_good_shelved", false))
	merged["first_shop_settlement_completed"] = bool(merged.get("first_shop_settlement_completed", false))
	merged["first_shop_tutorial_completed"] = bool(merged.get("first_shop_tutorial_completed", false))
	merged["currencies"] = Dictionary(merged.get("currencies", {}))
	if not merged["currencies"].has(DEFAULT_CURRENCY_ID):
		merged["currencies"][DEFAULT_CURRENCY_ID] = 0
	merged["warehouse_items"] = Array(merged.get("warehouse_items", []))
	merged["research_levels"] = Dictionary(merged.get("research_levels", {}))
	merged["collected_item_ids"] = Dictionary(merged.get("collected_item_ids", {}))
	merged["merchant_shop_offers"] = Array(merged.get("merchant_shop_offers", []))
	merged["daily_demand_entries"] = Array(merged.get("daily_demand_entries", []))
	merged["shop_shelf_items"] = Array(merged.get("shop_shelf_items", []))
	merged["shop_sales_records"] = Array(merged.get("shop_sales_records", []))
	merged["loadout_equipment_slots"] = Dictionary(merged.get("loadout_equipment_slots", {"HEAD": "", "BODY": "", "HAND": "", "FOOT": ""}))
	merged["loadout_consumable_slots"] = Array(merged.get("loadout_consumable_slots", ["", "", "", ""]))
	merged["surface_day"] = maxi(0, int(merged.get("surface_day", 0)))
	merged["current_chapter"] = maxi(1, int(merged.get("current_chapter", 1)))
	merged["last_played_at_unix"] = Time.get_unix_time_from_system()
	return merged

class_name SceneRandomEventDirector
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")
const RunEventContextScript := preload("res://scripts/events/run_event_context.gd")

const EVENTS_PATH := "res://setting/scene_random_events.tab"
const MONSTER_EVENT_ID := "monster_presence"

var load_errors: Array[String] = []
var event_rows_by_id: Dictionary = {}

func load_config() -> bool:
	load_errors.clear()
	event_rows_by_id.clear()
	var loader = TabDataLoaderScript.new()
	var rows: Array[Dictionary] = loader.load_tab(EVENTS_PATH)
	if not loader.last_error.is_empty():
		load_errors.append(loader.last_error)
	for row in rows:
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		var event_id := String(row.get("event_id", ""))
		if event_id.is_empty():
			continue
		event_rows_by_id[event_id] = row
	return load_errors.is_empty()

func resolve_for_run(game_state: Node, base_duration_seconds: float, seed: int, forced_events: Dictionary = {}) -> RunEventContext:
	if event_rows_by_id.is_empty():
		load_config()
	var context = RunEventContextScript.new()
	context.run_day_index = _resolve_run_day(game_state)
	context.base_run_duration_seconds = base_duration_seconds
	context.run_duration_seconds = base_duration_seconds

	var monster_row: Dictionary = _event_row(MONSTER_EVENT_ID)
	if not monster_row.is_empty():
		_resolve_monster_event(context, monster_row, seed, forced_events)
	return context

func _resolve_monster_event(context: RunEventContext, row: Dictionary, seed: int, forced_events: Dictionary) -> void:
	var event_id := String(row.get("event_id", MONSTER_EVENT_ID))
	var slot := String(row.get("slot", "threat"))
	var min_day := maxi(1, int(row.get("min_day", 3)))
	var guaranteed_day := maxi(min_day, int(row.get("guaranteed_day", min_day)))
	var daily_chance := clampf(float(row.get("daily_chance", 0.5)), 0.0, 1.0)
	var payload := _parse_payload(String(row.get("payload", "")))

	if bool(forced_events.get(event_id, false)):
		context.activate_monster_event(event_id, slot, "gm_forced", payload)
		return
	if context.run_day_index < min_day:
		return
	if context.run_day_index == guaranteed_day:
		context.activate_monster_event(event_id, slot, "guaranteed_day_%d" % guaranteed_day, payload)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, int(abs(seed)) + context.run_day_index * 92821 + 17041)
	var roll := rng.randf()
	if roll <= daily_chance:
		context.activate_monster_event(event_id, slot, "daily_roll_%.3f_lte_%.3f" % [roll, daily_chance], payload)

func _event_row(event_id: String) -> Dictionary:
	if event_rows_by_id.has(event_id):
		return event_rows_by_id[event_id]
	if event_id == MONSTER_EVENT_ID:
		return {
			"event_id": MONSTER_EVENT_ID,
			"slot": "threat",
			"min_day": "2",
			"guaranteed_day": "2",
			"daily_chance": "0.8",
			"payload": "monster_count=4;spawn_group=MonsterSpawnPoints;monster_type=black_tide_boundary_essence",
			"enabled": "true",
		}
	return {}

func _resolve_run_day(game_state: Node) -> int:
	if game_state != null and game_state.has_method("get_current_day"):
		return maxi(1, int(game_state.get_current_day()))
	return 1

func _parse_payload(value: String) -> Dictionary:
	var payload: Dictionary = {}
	for part in value.split(";", false):
		var trimmed := String(part).strip_edges()
		if trimmed.is_empty():
			continue
		var cells := trimmed.split("=", false, 1)
		if cells.size() != 2:
			continue
		payload[String(cells[0]).strip_edges()] = _parse_payload_value(String(cells[1]).strip_edges())
	return payload

func _parse_payload_value(value: String) -> Variant:
	if value.is_valid_int():
		return int(value)
	if value.is_valid_float():
		return float(value)
	var lower := value.to_lower()
	if lower == "true":
		return true
	if lower == "false":
		return false
	return value

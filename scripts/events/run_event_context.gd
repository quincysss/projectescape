class_name RunEventContext
extends RefCounted

var run_day_index: int = 1
var base_run_duration_seconds: float = 300.0
var run_duration_seconds: float = 300.0
var scene_events: Array[Dictionary] = []
var active_time_event_id: String = ""
var monster_event_active: bool = false
var monster_type_id: String = "black_tide_boundary_essence"
var monster_spawn_count: int = 4
var monster_spawn_group: String = "MonsterSpawnPoints"
var monster_spawn_point_ids: Array[String] = []
var active_monster_ids: Array[String] = []
var trigger_reasons: Array[String] = []

func add_event(event_id: String, slot: String, reason: String, payload: Dictionary = {}) -> void:
	if event_id.is_empty():
		return
	scene_events.append({
		"event_id": event_id,
		"slot": slot,
		"reason": reason,
		"payload": payload.duplicate(true),
	})
	if not reason.is_empty():
		trigger_reasons.append("%s:%s" % [event_id, reason])

func activate_monster_event(event_id: String, slot: String, reason: String, payload: Dictionary = {}) -> void:
	monster_event_active = true
	monster_spawn_count = maxi(1, int(payload.get("monster_count", monster_spawn_count)))
	monster_spawn_group = String(payload.get("spawn_group", monster_spawn_group))
	monster_type_id = String(payload.get("monster_type", monster_type_id))
	add_event(event_id, slot, reason, payload)

func to_dictionary() -> Dictionary:
	return {
		"run_day_index": run_day_index,
		"base_run_duration_seconds": base_run_duration_seconds,
		"run_duration_seconds": run_duration_seconds,
		"scene_events": scene_events.duplicate(true),
		"active_time_event_id": active_time_event_id,
		"monster_event_active": monster_event_active,
		"monster_type_id": monster_type_id,
		"monster_spawn_count": monster_spawn_count,
		"monster_spawn_group": monster_spawn_group,
		"monster_spawn_point_ids": monster_spawn_point_ids.duplicate(),
		"active_monster_ids": active_monster_ids.duplicate(),
		"trigger_reasons": trigger_reasons.duplicate(),
	}

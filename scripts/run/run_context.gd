class_name RunContext
extends RefCounted

var run_id: String = ""
var seed: int = 0
var elapsed_seconds: float = 0.0
var run_duration_seconds: float = 300.0
var remaining_seconds: float = 300.0
var is_time_expired: bool = false

var player_spawn_position: Vector2 = Vector2.ZERO
var player_stability: float = 100.0
var player_inventory: Array = []
var material_inventory: Array = []
var current_weight: float = 0.0
var weight_limit: float = 20.0
var weight_stage: String = "LIGHT"
var weight_speed_multiplier: float = 1.0
var home_storage: Array = []
var outpost_storage: Dictionary = {}

var selected_first_outpost_id: String = ""
var selected_second_outpost_id: String = ""
var selected_outposts: Array = []
var selected_outpost_positions: Dictionary = {}
var selected_outpost_footprints: Dictionary = {}
var outpost_states: Dictionary = {}
var repaired_outpost_count: int = 0

var is_extraction_unlocked: bool = false
var camera_mode: String = "follow"
var darkness_enabled: bool = true
var active_safe_zone_id: String = "home"
var active_safe_zone_type: String = "home"
var stability_stage: String = "SAFE"
var vision_radius: float = 0.0
var ss_roll_day: int = 0
var ss_roll_chance_tier: int = 0
var ss_roll_chance: float = 0.0
var ss_roll_value: float = 0.0
var ss_run_active: bool = false
var ss_budget_total: int = 0
var ss_budget_used: int = 0
var ss_opened_container_count: int = 0
var ss_miss_count_before: int = 0
var ss_next_chance_tier: int = 0
var ss_next_miss_count: int = 0
var ss_debug_events: Array = []
var run_day_index: int = 1
var map_id: String = "abandoned_house"
var location_state: String = "rich"
var location_visit_count_before: int = 0
var location_visit_count_after: int = 1
var container_target_count: int = 0
var scene_events: Array[Dictionary] = []
var active_time_event_id: String = ""
var monster_event_active: bool = false
var monster_type_id: String = "black_tide_boundary_essence"
var monster_spawn_count: int = 4
var monster_spawn_group: String = "MonsterSpawnPoints"
var monster_spawn_point_ids: Array[String] = []
var active_monster_ids: Array[String] = []
var monster_hit_count: int = 0
var event_trigger_reasons: Array[String] = []

var owner_id: String = "local_player"
var player_id: String = "local_player"
var team_id: String = "solo"

func to_debug_dictionary() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed,
		"elapsed_seconds": elapsed_seconds,
		"run_duration_seconds": run_duration_seconds,
		"remaining_seconds": remaining_seconds,
		"is_time_expired": is_time_expired,
		"player_spawn_position": player_spawn_position,
		"player_stability": player_stability,
		"inventory_slots_used": player_inventory.size(),
		"material_slots_used": material_inventory.size(),
		"current_weight": current_weight,
		"weight_limit": weight_limit,
		"weight_stage": weight_stage,
		"weight_speed_multiplier": weight_speed_multiplier,
		"home_storage_slots": home_storage.size(),
		"home_storage": home_storage,
		"outpost_storage": outpost_storage,
		"selected_outposts": selected_outposts,
		"selected_outpost_positions": selected_outpost_positions,
		"selected_outpost_footprints": selected_outpost_footprints,
		"outpost_states": outpost_states,
		"repaired_outpost_count": repaired_outpost_count,
		"is_extraction_unlocked": is_extraction_unlocked,
		"camera_mode": camera_mode,
		"darkness_enabled": darkness_enabled,
		"active_safe_zone_id": active_safe_zone_id,
		"active_safe_zone_type": active_safe_zone_type,
		"stability_stage": stability_stage,
		"vision_radius": vision_radius,
		"ss": {
			"roll_day": ss_roll_day,
			"chance_tier": ss_roll_chance_tier,
			"chance": ss_roll_chance,
			"roll_value": ss_roll_value,
			"run_active": ss_run_active,
			"budget_total": ss_budget_total,
			"budget_used": ss_budget_used,
			"opened_container_count": ss_opened_container_count,
			"miss_count_before": ss_miss_count_before,
			"next_chance_tier": ss_next_chance_tier,
			"next_miss_count": ss_next_miss_count,
			"debug_events": ss_debug_events,
		},
		"scene_events": {
			"run_day_index": run_day_index,
			"map_id": map_id,
			"location_state": location_state,
			"location_visit_count_before": location_visit_count_before,
			"location_visit_count_after": location_visit_count_after,
			"container_target_count": container_target_count,
			"events": scene_events,
			"active_time_event_id": active_time_event_id,
			"monster_event_active": monster_event_active,
			"monster_type_id": monster_type_id,
			"monster_spawn_count": monster_spawn_count,
			"monster_spawn_group": monster_spawn_group,
			"monster_spawn_point_ids": monster_spawn_point_ids,
			"active_monster_ids": active_monster_ids,
			"monster_hit_count": monster_hit_count,
			"trigger_reasons": event_trigger_reasons,
		},
		"owner_id": owner_id,
		"player_id": player_id,
		"team_id": team_id,
	}

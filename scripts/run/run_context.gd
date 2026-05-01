class_name RunContext
extends RefCounted

var run_id: String = ""
var seed: int = 0
var elapsed_seconds: float = 0.0

var player_spawn_position: Vector2 = Vector2.ZERO
var player_stability: float = 100.0
var player_inventory: Array = []
var current_weight: float = 0.0
var weight_limit: float = 20.0
var weight_stage: String = "LIGHT"
var weight_speed_multiplier: float = 1.0
var home_storage: Array = []

var selected_first_outpost_id: String = ""
var selected_second_outpost_id: String = ""
var selected_outposts: Array = []
var selected_outpost_positions: Dictionary = {}
var outpost_states: Dictionary = {}
var repaired_outpost_count: int = 0

var is_extraction_unlocked: bool = false
var camera_mode: String = "observe"
var darkness_enabled: bool = false
var active_safe_zone_id: String = "home"
var active_safe_zone_type: String = "home"
var stability_stage: String = "SAFE"
var vision_radius: float = 0.0

var owner_id: String = "local_player"
var player_id: String = "local_player"
var team_id: String = "solo"

func to_debug_dictionary() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed,
		"elapsed_seconds": elapsed_seconds,
		"player_spawn_position": player_spawn_position,
		"player_stability": player_stability,
		"inventory_slots_used": player_inventory.size(),
		"current_weight": current_weight,
		"weight_limit": weight_limit,
		"weight_stage": weight_stage,
		"weight_speed_multiplier": weight_speed_multiplier,
		"home_storage_slots": home_storage.size(),
		"home_storage": home_storage,
		"selected_outposts": selected_outposts,
		"selected_outpost_positions": selected_outpost_positions,
		"outpost_states": outpost_states,
		"repaired_outpost_count": repaired_outpost_count,
		"is_extraction_unlocked": is_extraction_unlocked,
		"camera_mode": camera_mode,
		"darkness_enabled": darkness_enabled,
		"active_safe_zone_id": active_safe_zone_id,
		"active_safe_zone_type": active_safe_zone_type,
		"stability_stage": stability_stage,
		"vision_radius": vision_radius,
		"owner_id": owner_id,
		"player_id": player_id,
		"team_id": team_id,
	}

class_name RunConfig
extends Resource

@export var max_stability: float = 100.0
@export var stability_decay_per_second: float = 1.0
@export var stability_recover_per_second: float = 10.0
@export var base_weight_limit: float = 20.0
@export var inventory_slots: int = 8
@export var home_storage_slots: int = 4
@export var first_outpost_candidate_count: int = 3
@export var second_outpost_candidate_count: int = 4
@export var container_refresh_interval: float = 30.0
@export var use_random_seed: bool = true
@export var fixed_run_seed: int = 1001

func get_seed() -> int:
	if use_random_seed:
		return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_msec()
	return fixed_run_seed

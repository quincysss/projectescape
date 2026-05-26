class_name RunConfig
extends Resource

@export var max_stability: float = 100.0
@export var stability_decay_per_second: float = 1.5
@export var stability_recover_per_second: float = 10.0
@export var base_weight_limit: float = 20.0
@export var inventory_slots: int = 8
@export var home_storage_slots: int = 1
@export var first_outpost_storage_slots: int = 0
@export var second_outpost_storage_slots: int = 0
@export var run_duration_seconds: float = 300.0
@export var first_outpost_candidate_count: int = 3
@export var second_outpost_candidate_count: int = 4
@export var use_random_seed: bool = true
@export var fixed_run_seed: int = 1001

func get_seed() -> int:
	if use_random_seed:
		return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_msec()
	return fixed_run_seed

class_name MonsterSpawnController
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")
const MonsterBasicScene := preload("res://scenes/entities/monsters/MonsterBasic.tscn")

const MONSTER_DEFS_PATH := "res://setting/monster_defs.tab"
const DEFAULT_MONSTER_ID := "black_tide_boundary_essence"
const MONSTER_HIT_RESPAWN_DELAY_SECONDS := 30.0

var monster_parent: Node2D
var point_provider: Callable
var player: Node2D
var run_director: Node
var unit: float = 64.0
var active_monsters: Array[Node] = []
var load_errors: Array[String] = []
var monster_defs_by_id: Dictionary = {}
var respawn_delay_seconds: float = MONSTER_HIT_RESPAWN_DELAY_SECONDS

var _active_definition: Dictionary = {}
var _respawn_index: int = 0
var _pending_respawn_timers: Dictionary = {}

func setup(
	p_monster_parent: Node2D,
	p_point_provider: Callable,
	p_player: Node2D,
	p_run_director: Node,
	p_unit: float
) -> void:
	monster_parent = p_monster_parent
	point_provider = p_point_provider
	player = p_player
	run_director = p_run_director
	unit = p_unit
	_load_monster_defs()

func spawn_for_context(context) -> Array[Node]:
	clear_all()
	if context == null or not bool(context.get("monster_event_active")):
		return []
	var points := _get_point_pool()
	if points.is_empty():
		push_warning("Monster event active but MonsterSpawnPoints is empty.")
		return []
	var spawn_count := mini(points.size(), maxi(0, int(context.get("monster_spawn_count"))))
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, int(abs(context.seed)) + int(context.run_day_index) * 77377 + 421)
	points = _shuffled_points(points, rng)
	var monster_type_id := String(context.get("monster_type_id"))
	var definition := _monster_definition(monster_type_id)
	_active_definition = definition
	_respawn_index = 0
	context.monster_spawn_point_ids.clear()
	context.active_monster_ids.clear()
	for index in range(spawn_count):
		var point: Node2D = points[index]
		var spawned = _spawn_one(point, index, definition)
		if spawned == null:
			continue
		active_monsters.append(spawned)
		context.monster_spawn_point_ids.append(_point_id(point))
		context.active_monster_ids.append(String(spawned.get("monster_id")))
	return get_active_monsters()

func clear_all() -> void:
	_clear_pending_respawns()
	for monster in active_monsters:
		if monster != null and is_instance_valid(monster):
			monster.queue_free()
	active_monsters.clear()

func get_active_monsters() -> Array[Node]:
	var result: Array[Node] = []
	for monster in active_monsters:
		if monster != null and is_instance_valid(monster):
			result.append(monster)
	active_monsters = result
	return result

func active_count() -> int:
	return get_active_monsters().size()

func debug_spawn(count: int = 4) -> Array[Node]:
	var context := {
		"monster_event_active": true,
		"monster_spawn_count": count,
		"monster_type_id": DEFAULT_MONSTER_ID,
		"seed": Time.get_ticks_msec(),
		"run_day_index": 3,
		"monster_spawn_point_ids": [],
		"active_monster_ids": [],
	}
	return spawn_for_context(context)

func _spawn_one(point: Node2D, index: int, definition: Dictionary, id_suffix: String = ""):
	if monster_parent == null or not is_instance_valid(monster_parent):
		return null
	var monster = MonsterBasicScene.instantiate()
	if monster == null:
		return null
	var point_id := _point_id(point)
	var id := "Monster_%s_%02d%s" % [point_id, index + 1, id_suffix]
	monster.name = id
	var data := {
		"monster_id": id,
		"spawn_point_id": point_id,
		"spawn_position": point.global_position,
		"patrol_radius": float(definition.get("patrol_radius_px", 520.0)),
		"patrol_speed": float(definition.get("patrol_speed_px", 168.0)),
		"charge_speed": float(definition.get("charge_speed_px", 1680.0)),
		"vision_radius": float(definition.get("vision_radius_px", 920.0)),
		"vision_angle_degrees": float(definition.get("vision_angle_degrees", 100.0)),
		"warning_seconds": float(definition.get("warning_seconds", 1.0)),
		"stability_damage": float(definition.get("stability_damage", 20.0)),
		"hit_radius": float(definition.get("hit_radius_px", 128.0)),
		"patrol_target_reach_distance": float(definition.get("patrol_target_reach_distance_px", 40.0)),
		"patrol_points": _patrol_points_for_spawn(point),
	}
	monster_parent.add_child(monster)
	monster.setup(data, player, run_director)
	if monster.has_signal("monster_removed"):
		monster.monster_removed.connect(_on_monster_removed)
	return monster

func _on_monster_removed(monster_id: String, spawn_point_id: String, removal_reason: String) -> void:
	if run_director != null and run_director.context != null:
		run_director.context.active_monster_ids.erase(monster_id)
	get_active_monsters()
	if removal_reason == "hit_player":
		_schedule_hit_respawn(spawn_point_id)

func _schedule_hit_respawn(spawn_point_id: String) -> void:
	if spawn_point_id.is_empty():
		return
	if _pending_respawn_timers.has(spawn_point_id):
		return
	if monster_parent == null or not is_instance_valid(monster_parent):
		return
	var timer := Timer.new()
	timer.name = "MonsterRespawnTimer_%s" % spawn_point_id
	timer.one_shot = true
	timer.wait_time = maxf(0.01, respawn_delay_seconds)
	_pending_respawn_timers[spawn_point_id] = timer
	monster_parent.add_child(timer)
	timer.timeout.connect(_on_respawn_timer_timeout.bind(spawn_point_id, timer))
	timer.start()

func _on_respawn_timer_timeout(spawn_point_id: String, timer: Timer) -> void:
	if _pending_respawn_timers.get(spawn_point_id) == timer:
		_pending_respawn_timers.erase(spawn_point_id)
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	if monster_parent == null or not is_instance_valid(monster_parent):
		return
	var point := _find_point_by_id(spawn_point_id)
	if point == null:
		return
	var definition := _active_definition if not _active_definition.is_empty() else _monster_definition(DEFAULT_MONSTER_ID)
	_respawn_index += 1
	var spawned = _spawn_one(point, _respawn_index, definition, "_respawn")
	if spawned == null:
		return
	active_monsters.append(spawned)
	if run_director != null and run_director.context != null:
		run_director.context.active_monster_ids.append(String(spawned.get("monster_id")))

func _clear_pending_respawns() -> void:
	for timer in _pending_respawn_timers.values():
		if timer != null and is_instance_valid(timer):
			timer.queue_free()
	_pending_respawn_timers.clear()

func _find_point_by_id(spawn_point_id: String) -> Node2D:
	for point in _get_point_pool():
		if _point_id(point) == spawn_point_id:
			return point
	return null

func _get_point_pool() -> Array:
	if not point_provider.is_valid():
		return []
	var points: Array = point_provider.call()
	var result: Array = []
	for point in points:
		if point is Node2D:
			result.append(point)
	return result

func _patrol_points_for_spawn(point: Node2D) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for child in point.find_children("*", "Node2D", true, false):
		if _is_patrol_marker(child):
			result.append(child.global_position)
	return result

func _is_patrol_marker(node: Node) -> bool:
	if not (node is Node2D):
		return false
	var normalized_name := String(node.name).to_snake_case().to_lower()
	if normalized_name.begins_with("patrol_path"):
		return false
	return normalized_name.begins_with("patrol") or normalized_name.contains("_patrol_")

func _shuffled_points(points: Array, rng: RandomNumberGenerator) -> Array:
	var result := points.duplicate()
	for index in range(result.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp = result[index]
		result[index] = result[swap_index]
		result[swap_index] = temp
	return result

func _point_id(point: Node) -> String:
	if point != null and point.has_method("get_point_id"):
		return String(point.get_point_id())
	return point.name if point != null else ""

func _load_monster_defs() -> bool:
	load_errors.clear()
	monster_defs_by_id.clear()
	var loader = TabDataLoaderScript.new()
	var rows: Array[Dictionary] = loader.load_tab(MONSTER_DEFS_PATH)
	if not loader.last_error.is_empty():
		load_errors.append(loader.last_error)
	for row in rows:
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		var monster_id := String(row.get("monster_id", ""))
		if monster_id.is_empty():
			continue
		monster_defs_by_id[monster_id] = row
	return load_errors.is_empty()

func _monster_definition(monster_id: String) -> Dictionary:
	if monster_defs_by_id.is_empty():
		_load_monster_defs()
	var normalized_id := monster_id if not monster_id.is_empty() else DEFAULT_MONSTER_ID
	if monster_defs_by_id.has(normalized_id):
		return monster_defs_by_id[normalized_id]
	return {
		"monster_id": DEFAULT_MONSTER_ID,
		"patrol_radius_px": "520",
		"patrol_speed_px": "168",
		"charge_speed_px": "1680",
		"vision_radius_px": "920",
		"vision_angle_degrees": "100",
		"warning_seconds": "1",
		"stability_damage": "20",
		"hit_radius_px": "128",
		"patrol_target_reach_distance_px": "40",
	}

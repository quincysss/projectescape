class_name MonsterBasic
extends Node2D

signal monster_removed(monster_id: String)

enum State {
	PATROL,
	WARNING,
	CHARGE,
	REMOVED,
}

@export var monster_id: String = ""
@export var spawn_point_id: String = ""
@export var patrol_radius: float = 220.0
@export var patrol_speed: float = 84.0
@export var charge_speed: float = 840.0
@export var vision_radius: float = 720.0
@export var vision_angle_degrees: float = 100.0
@export var warning_seconds: float = 5.0
@export var stability_damage: float = 20.0
@export var hit_radius: float = 128.0
@export var patrol_target_reach_distance: float = 40.0

@onready var vision_cone: MonsterVisionCone = $VisionCone
@onready var visual_root: Node2D = $Visual

var player: Node2D
var run_director: Node
var spawn_position: Vector2 = Vector2.ZERO
var state: int = State.PATROL
var face_direction: Vector2 = Vector2.RIGHT
var warning_time: float = 0.0

var _rng := RandomNumberGenerator.new()
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_points: Array[Vector2] = []
var _patrol_point_index: int = 0
var _patrol_point_direction: int = 1
var _hit_applied := false

func _ready() -> void:
	add_to_group("run_monsters")
	add_to_group("monster_presence")
	if spawn_position == Vector2.ZERO:
		spawn_position = global_position
	_pick_patrol_target()
	_refresh_vision_cone()

func setup(data: Dictionary, player_node: Node2D, director_node: Node) -> void:
	monster_id = String(data.get("monster_id", monster_id))
	spawn_point_id = String(data.get("spawn_point_id", spawn_point_id))
	spawn_position = data.get("spawn_position", global_position)
	patrol_radius = float(data.get("patrol_radius", patrol_radius))
	patrol_speed = float(data.get("patrol_speed", patrol_speed))
	charge_speed = float(data.get("charge_speed", charge_speed))
	vision_radius = float(data.get("vision_radius", vision_radius))
	vision_angle_degrees = float(data.get("vision_angle_degrees", vision_angle_degrees))
	warning_seconds = float(data.get("warning_seconds", warning_seconds))
	stability_damage = float(data.get("stability_damage", stability_damage))
	hit_radius = float(data.get("hit_radius", hit_radius))
	patrol_target_reach_distance = float(data.get("patrol_target_reach_distance", patrol_target_reach_distance))
	_patrol_points = _normalize_patrol_points(data.get("patrol_points", []))
	player = player_node
	run_director = director_node
	global_position = spawn_position
	_rng.seed = maxi(1, int(abs(hash("%s:%s" % [monster_id, spawn_point_id]))))
	_pick_patrol_target()
	_refresh_vision_cone()

func _process(delta: float) -> void:
	update_monster(delta)

func update_monster(delta: float) -> void:
	if state == State.REMOVED or delta <= 0.0:
		return
	match state:
		State.PATROL:
			_update_patrol(delta)
		State.WARNING:
			_update_warning(delta)
		State.CHARGE:
			_update_charge(delta)
	_refresh_vision_cone()

func debug_force_hit_player() -> void:
	_apply_hit_and_remove()

func debug_force_warning(seconds: float) -> void:
	state = State.WARNING
	warning_time = maxf(0.0, seconds)
	_refresh_vision_cone()

func get_patrol_point_count() -> int:
	return _patrol_points.size()

func get_vision_origin_global() -> Vector2:
	return _vision_origin_global()

func _update_patrol(delta: float) -> void:
	_move_toward_patrol_target(delta)
	if _player_in_patrol_cone():
		state = State.WARNING
		warning_time = 0.0
		_face_player()

func _update_warning(delta: float) -> void:
	_face_player()
	_move_toward_patrol_target(delta, false)
	_face_player()
	if not _player_in_vision_cone():
		state = State.PATROL
		warning_time = 0.0
		return
	warning_time += delta
	if warning_time >= warning_seconds:
		state = State.CHARGE

func _update_charge(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		state = State.PATROL
		warning_time = 0.0
		return
	_face_player()
	var distance := global_position.distance_to(player.global_position)
	if distance <= hit_radius:
		_apply_hit_and_remove()
		return
	var step := charge_speed * delta
	global_position = global_position.move_toward(player.global_position, step)
	if global_position.distance_to(player.global_position) <= hit_radius:
		_apply_hit_and_remove()

func _move_toward_patrol_target(delta: float, update_face_direction: bool = true) -> void:
	if global_position.distance_to(_patrol_target) <= patrol_target_reach_distance:
		_pick_patrol_target()
	if not _is_walkable_position(global_position):
		_patrol_target = spawn_position
	var direction := _patrol_target - global_position
	if update_face_direction and direction.length_squared() > 0.001:
		face_direction = direction.normalized()
	var next_position := global_position.move_toward(_patrol_target, patrol_speed * delta)
	if _is_walkable_position(next_position):
		global_position = next_position
	else:
		_pick_patrol_target()

func _pick_patrol_target() -> void:
	if not _patrol_points.is_empty():
		_pick_next_path_target()
		return
	for _attempt in range(12):
		var angle := _rng.randf_range(0.0, TAU)
		var distance := _rng.randf_range(patrol_radius * 0.35, patrol_radius)
		var candidate := spawn_position + Vector2(cos(angle), sin(angle)) * distance
		if _is_walkable_position(candidate):
			_patrol_target = candidate
			return
	_patrol_target = spawn_position

func _pick_next_path_target() -> void:
	for _attempt in range(maxi(1, _patrol_points.size())):
		_patrol_point_index = clampi(_patrol_point_index, 0, _patrol_points.size() - 1)
		var candidate := _patrol_points[_patrol_point_index]
		_advance_patrol_path_cursor()
		if _is_walkable_position(candidate):
			_patrol_target = candidate
			return
	_patrol_target = spawn_position

func _advance_patrol_path_cursor() -> void:
	if _patrol_points.size() <= 1:
		_patrol_point_index = 0
		return
	_patrol_point_index += _patrol_point_direction
	if _patrol_point_index >= _patrol_points.size():
		_patrol_point_index = _patrol_points.size() - 2
		_patrol_point_direction = -1
	elif _patrol_point_index < 0:
		_patrol_point_index = 1
		_patrol_point_direction = 1

func _normalize_patrol_points(value) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if value is Array:
		for item in value:
			if item is Vector2:
				result.append(item)
	return result

func _is_walkable_position(world_position: Vector2) -> bool:
	if player == null or not is_instance_valid(player) or not player.has_method("_is_position_walkable"):
		return true
	return bool(player.call("_is_position_walkable", world_position))

func _player_in_patrol_cone() -> bool:
	return _player_in_vision_cone()

func _player_in_vision_cone() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var to_player := player.global_position - _vision_origin_global()
	var distance := to_player.length()
	if distance <= 0.001 or distance > vision_radius:
		return false
	var angle := absf(face_direction.angle_to(to_player.normalized()))
	return angle <= deg_to_rad(vision_angle_degrees) * 0.5

func _face_player() -> void:
	if player == null or not is_instance_valid(player):
		return
	var direction := player.global_position - _vision_origin_global()
	if direction.length_squared() > 0.001:
		face_direction = direction.normalized()

func _refresh_vision_cone() -> void:
	if vision_cone == null:
		return
	if visual_root != null and visual_root.has_method("set_facing_direction"):
		visual_root.call("set_facing_direction", face_direction)
	vision_cone.global_position = _vision_origin_global()
	vision_cone.radius = vision_radius
	vision_cone.angle_degrees = vision_angle_degrees
	vision_cone.set_direction(face_direction)
	var progress := clampf(warning_time / maxf(0.001, warning_seconds), 0.0, 1.0)
	vision_cone.set_state(progress, state == State.CHARGE)

func _vision_origin_global() -> Vector2:
	if visual_root == null or not is_instance_valid(visual_root):
		return global_position
	var eye_focus := visual_root.get_node_or_null("EyeFocus") as Node2D
	if eye_focus == null:
		return global_position
	return eye_focus.global_position

func _apply_hit_and_remove() -> void:
	if _hit_applied:
		return
	_hit_applied = true
	state = State.REMOVED
	if run_director != null and run_director.has_method("apply_monster_stability_damage"):
		run_director.apply_monster_stability_damage(stability_damage, monster_id)
	monster_removed.emit(monster_id)
	queue_free()

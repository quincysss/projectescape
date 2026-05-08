class_name ContainerSpawnController
extends RefCounted

const INITIAL_SPAWN_COUNT := 6
const RESPAWN_INTERVAL_SECONDS := 12.0
const CONTAINER_LIFETIME_SECONDS := 45.0

var container_root: Node
var get_spawn_points: Callable
var make_interactable: Callable
var make_item: Callable
var remove_interactable: Callable
var unit: float = 64.0

var container_index: int = 0
var respawn_timer: float = 0.0
var last_spawn_point_index: int = 0

func setup(
	p_container_root: Node,
	p_get_spawn_points: Callable,
	p_make_interactable: Callable,
	p_make_item: Callable,
	p_remove_interactable: Callable,
	p_unit: float
) -> void:
	container_root = p_container_root
	get_spawn_points = p_get_spawn_points
	make_interactable = p_make_interactable
	make_item = p_make_item
	remove_interactable = p_remove_interactable
	unit = p_unit

func spawn_initial() -> void:
	var points: Array = _spawn_points()
	var spawned_count := 0
	for spawn_point in points:
		if not (spawn_point is Node2D):
			continue
		if _is_position_occupied(spawn_point.global_position):
			continue
		if spawn_container(spawn_point.global_position) != null:
			spawned_count += 1
		if spawned_count >= INITIAL_SPAWN_COUNT:
			return

func update(delta: float, interactables: Array) -> void:
	update_lifetimes(delta, interactables)
	respawn_timer += delta
	if respawn_timer < RESPAWN_INTERVAL_SECONDS:
		return
	respawn_timer = 0.0
	spawn_next_container()

func update_lifetimes(delta: float, interactables: Array) -> void:
	for interactable in interactables.duplicate():
		if not is_instance_valid(interactable) or interactable.interact_type != "container":
			continue
		if interactable.payload.get("state", "") != "available":
			continue
		interactable.payload.lifetime = float(interactable.payload.get("lifetime", 0.0)) - delta
		if interactable.payload.lifetime <= 0.0:
			remove_interactable.call(interactable)

func spawn_container(pos: Vector2):
	if _is_position_occupied(pos):
		return null
	container_index += 1
	var rarity := pick_rarity()
	var container = make_interactable.call(
		"container_%s" % container_index,
		"container",
		"%s级资源箱" % rarity,
		pos,
		rarity_color(rarity)
	)
	container.payload = {
		"state": "available",
		"rarity": rarity,
		"lifetime": CONTAINER_LIFETIME_SECONDS,
		"lifetime_max": CONTAINER_LIFETIME_SECONDS,
		"rewards": [
			make_item.call("scrap_metal", "废金属", 1 + randi() % 2, 2.0, 5),
			make_item.call("food_can", "罐头食品", 1, 1.0, 3),
		],
	}
	container_root.add_child(container)
	return container

func spawn_next_container():
	var spawn_point: Node2D = next_spawn_point()
	if spawn_point == null:
		return null
	return spawn_container(spawn_point.global_position)

func next_spawn_point() -> Node2D:
	var points: Array = _spawn_points()
	if points.is_empty():
		return null
	for offset in range(points.size()):
		var index := (last_spawn_point_index + 1 + offset) % points.size()
		var candidate = points[index]
		if not (candidate is Node2D):
			continue
		var spawn_point: Node2D = candidate
		if _is_position_occupied(spawn_point.global_position):
			continue
		last_spawn_point_index = index
		return spawn_point
	return null

func next_spawn_position() -> Vector2:
	var points: Array = _spawn_points()
	if points.is_empty():
		return Vector2(18.0 + randf() * 98.0, -42.0 + randf() * 84.0) * unit
	var spawn_point: Node2D = next_spawn_point()
	if spawn_point == null:
		var fallback_point = points[last_spawn_point_index % points.size()]
		return fallback_point.global_position if fallback_point is Node2D else Vector2.ZERO
	return spawn_point.global_position

func pick_rarity() -> String:
	var roll := randf()
	if roll < 0.6:
		return "C"
	if roll < 0.85:
		return "B"
	if roll < 0.97:
		return "A"
	return "S"

func rarity_color(rarity: String) -> Color:
	match rarity:
		"C":
			return Color(0.78, 0.78, 0.78)
		"B":
			return Color(0.55, 0.78, 1.0)
		"A":
			return Color(0.78, 0.58, 1.0)
		"S":
			return Color(1.0, 0.84, 0.36)
		_:
			return Color.WHITE

func _spawn_points() -> Array:
	if not get_spawn_points.is_valid():
		return []
	return get_spawn_points.call()

func _is_position_occupied(pos: Vector2) -> bool:
	if container_root == null:
		return false
	for child in container_root.get_children():
		if not is_instance_valid(child) or not (child is Node2D):
			continue
		if child.get("interact_type") != "container":
			continue
		var payload = child.get("payload")
		if not (payload is Dictionary):
			continue
		if payload.get("state", "") != "available":
			continue
		if child.global_position.distance_squared_to(pos) <= 1.0:
			return true
	return false

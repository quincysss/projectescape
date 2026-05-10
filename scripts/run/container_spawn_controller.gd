class_name ContainerSpawnController
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

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
var data_registry
var rng := RandomNumberGenerator.new()

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
	rng.randomize()
	data_registry = GameDataRegistryScript.new()
	data_registry.load_all()

func spawn_initial() -> void:
	var points: Array = _spawn_points()
	var spawned_count := 0
	for spawn_point in points:
		if not (spawn_point is Node2D):
			continue
		if _is_position_occupied(spawn_point.global_position):
			continue
		if spawn_container_for_point(spawn_point) != null:
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
		if not _should_count_down(interactable.payload):
			continue
		interactable.payload.lifetime = float(interactable.payload.get("lifetime", 0.0)) - delta
		if interactable.payload.lifetime <= 0.0:
			remove_interactable.call(interactable)

func spawn_container(pos: Vector2, container_type_id: String = "", ring: String = "inner"):
	if _is_position_occupied(pos):
		return null
	container_index += 1
	var container_def := _container_definition(container_type_id, ring)
	var type_id := String(container_def.get("type_id", "cardboard_box"))
	var display_name := String(container_def.get("display_name", "容器"))
	var lifetime := float(container_def.get("lifetime_seconds", CONTAINER_LIFETIME_SECONDS))
	var visual_color := _container_color(container_def)
	var visual_size_units := _container_visual_size_units(container_def)
	var open_time := rng.randf_range(
		float(container_def.get("open_time_min", 0.8)),
		float(container_def.get("open_time_max", 1.6))
	)
	var rewards := _generate_rewards(container_def, ring)
	var container = make_interactable.call(
		"container_%s" % container_index,
		"container",
		display_name,
		pos,
		visual_color,
		visual_size_units
	)
	container.payload = {
		"state": "available",
		"type_id": type_id,
		"container_def": container_def.duplicate(true),
		"container_color": visual_color,
		"ring": ring,
		"lifetime": lifetime,
		"lifetime_max": lifetime,
		"open_time": open_time,
		"rewards": rewards,
	}
	container_root.add_child(container)
	return container

func spawn_container_for_point(spawn_point: Node2D):
	if spawn_point == null:
		return null
	var ring := _ring_for_spawn_point(spawn_point)
	return spawn_container(spawn_point.global_position, "", ring)

func spawn_next_container():
	var spawn_point: Node2D = next_spawn_point()
	if spawn_point == null:
		return null
	return spawn_container_for_point(spawn_point)

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

func item_quality_color(quality: String) -> Color:
	if data_registry != null:
		return data_registry.get_item_quality_color(quality)
	return rarity_color(quality)

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
		if String(payload.get("state", "")) == "depleted":
			continue
		if child.global_position.distance_squared_to(pos) <= 1.0:
			return true
	return false

func _should_count_down(payload: Dictionary) -> bool:
	var state := String(payload.get("state", ""))
	return state == "available" or state == "opened"

func _container_definition(container_type_id: String, ring: String) -> Dictionary:
	if data_registry == null:
		return {}
	if not container_type_id.is_empty():
		var explicit_def: Dictionary = data_registry.get_container_type(container_type_id)
		if not explicit_def.is_empty():
			return explicit_def
	return data_registry.pick_container_type_for_ring(ring, rng)

func _generate_rewards(container_def: Dictionary, ring: String) -> Array[Dictionary]:
	if data_registry != null and not container_def.is_empty():
		var generated: Array[Dictionary] = data_registry.generate_container_loot(container_def, ring, rng)
		if not generated.is_empty():
			return generated
	return [
		make_item.call("scrap_metal", "废金属", 1 + rng.randi_range(0, 1), 0.1, 99),
	]

func _container_color(container_def: Dictionary) -> Color:
	var color_text := String(container_def.get("visual_color_hex", "#3A8DFF"))
	if color_text.is_empty():
		return Color(0.23, 0.55, 1.0)
	return Color(color_text)

func _container_visual_size_units(container_def: Dictionary) -> Vector2:
	var asset_max_px := float(container_def.get("asset_max_px", 256.0))
	var size_units: float = clampf(asset_max_px / maxf(1.0, unit), 2.0, 8.0)
	match String(container_def.get("size_class", "")):
		"small":
			return Vector2(size_units, size_units * 0.78)
		"medium":
			return Vector2(size_units, size_units * 0.86)
		_:
			return Vector2(size_units, size_units)

func _ring_for_spawn_point(spawn_point: Node) -> String:
	if spawn_point == null:
		return "inner"
	var value = spawn_point.get("ring")
	if value == null:
		return "inner"
	return String(value)

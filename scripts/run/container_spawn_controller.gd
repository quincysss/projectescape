class_name ContainerSpawnController
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

const INITIAL_SPAWN_COUNT := 6

var container_root: Node
var get_spawn_points: Callable
var make_interactable: Callable
var make_item: Callable
var remove_interactable: Callable
var unit: float = 64.0

var container_index: int = 0
var last_spawn_point_index: int = 0
var data_registry
var rng := RandomNumberGenerator.new()
var map_id: String = "abandoned_house"
var location_state: String = "rich"
var visit_count_before: int = 0
var map_profile: Dictionary = {}
var location_state_rule: Dictionary = {}
var target_container_count: int = INITIAL_SPAWN_COUNT
var run_seed: int = 0

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
	_refresh_resource_profile()

func setup_legacy_high_tier_director(_director) -> void:
	pass

func configure_location(p_map_id: String, p_location_state: String, p_visit_count_before: int, p_run_seed: int) -> void:
	map_id = p_map_id if not p_map_id.is_empty() else "abandoned_house"
	location_state = p_location_state if not p_location_state.is_empty() else "normal"
	visit_count_before = maxi(0, p_visit_count_before)
	run_seed = p_run_seed
	if run_seed != 0:
		rng.seed = run_seed
	_refresh_resource_profile()

func spawn_initial() -> void:
	clear_instance_containers()
	target_container_count = _target_container_count_for_current_location()
	for _index in range(target_container_count):
		if spawn_next_container() != null:
			continue
		else:
			return

func update(delta: float, interactables: Array) -> void:
	pass

func update_lifetimes(delta: float, interactables: Array) -> void:
	pass

func clear_instance_containers() -> void:
	if container_root == null:
		return
	for child in container_root.get_children().duplicate():
		if not is_instance_valid(child) or child.get("interact_type") != "container":
			continue
		if remove_interactable.is_valid():
			remove_interactable.call(child)
		if is_instance_valid(child) and child.get_parent() != null:
			child.get_parent().remove_child(child)
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			child.free()

func spawn_container(pos: Vector2, container_type_id: String = "", ring: String = "inner", spawn_point_id: String = ""):
	if _is_position_occupied(pos):
		return null
	container_index += 1
	var container_def := _container_definition(container_type_id, ring)
	var type_id := String(container_def.get("type_id", "cardboard_box"))
	var display_name := String(container_def.get("display_name", "容器"))
	var visual_color := _container_color(container_def)
	var visual_size_units := _container_visual_size_units(container_def)
	var open_time := rng.randf_range(
		float(container_def.get("open_time_min", 0.8)),
		float(container_def.get("open_time_max", 1.6))
	)
	var loot_seed := rng.randi()
	var container = make_interactable.call(
		"container_%s" % container_index,
		"container",
		display_name,
		pos,
		visual_color,
		visual_size_units,
		container_def
	)
	container.payload = {
		"state": "available",
		"type_id": type_id,
		"container_def": container_def.duplicate(true),
		"container_color": visual_color,
		"ring": ring,
		"map_id": map_id,
		"location_state": location_state,
		"spawn_point_id": spawn_point_id,
		"loot_seed": loot_seed,
		"loot_generated": false,
		"open_time": open_time,
		"rewards": [],
		"has_been_opened": false,
		"owner_player_id": "local_player",
		"opened_by_player_id": "",
		"locked_by_player_id": "",
	}
	container_root.add_child(container)
	return container

func spawn_container_for_point(spawn_point: Node2D):
	if spawn_point == null:
		return null
	var ring := _ring_for_spawn_point(spawn_point)
	return spawn_container(spawn_point.global_position, "", ring, _spawn_point_id(spawn_point))

func spawn_next_container():
	var spawn_point: Node2D = next_spawn_point()
	if spawn_point == null:
		return null
	return spawn_container_for_point(spawn_point)

func spawn_refresh_round() -> Array:
	return []

func ensure_container_rewards(container) -> Array[Dictionary]:
	if not is_instance_valid(container):
		return []
	var payload = container.get("payload")
	if not (payload is Dictionary):
		return []
	if bool(payload.get("loot_generated", false)):
		return payload.get("rewards", [])
	var reward_rng := RandomNumberGenerator.new()
	reward_rng.seed = int(payload.get("loot_seed", rng.randi()))
	var container_def: Dictionary = payload.get("container_def", {})
	var ring := String(payload.get("ring", "inner"))
	var rewards := _generate_rewards(container_def, ring, reward_rng)
	payload.rewards = rewards
	payload.loot_generated = true
	return rewards

func next_spawn_point() -> Node2D:
	var points: Array = _spawn_points()
	if points.is_empty():
		return null
	var available_indices: Array[int] = []
	for index in range(points.size()):
		var candidate = points[index]
		if not (candidate is Node2D):
			continue
		var spawn_point: Node2D = candidate
		if _is_position_occupied(spawn_point.global_position):
			continue
		available_indices.append(index)
	if available_indices.is_empty():
		return null
	var selected_index: int = available_indices[rng.randi_range(0, available_indices.size() - 1)]
	last_spawn_point_index = selected_index
	var selected_point: Node2D = points[selected_index]
	return selected_point

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
		if not is_instance_valid(child) or child.is_queued_for_deletion() or not (child is Node2D):
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

func _container_definition(container_type_id: String, ring: String) -> Dictionary:
	if data_registry == null:
		return {}
	if not container_type_id.is_empty():
		var explicit_def: Dictionary = data_registry.get_container_type(container_type_id)
		if not explicit_def.is_empty():
			return explicit_def
	if data_registry.has_method("pick_container_type_for_profile"):
		return data_registry.pick_container_type_for_profile(ring, map_profile, rng)
	return data_registry.pick_container_type_for_ring(ring, rng)

func _generate_rewards(container_def: Dictionary, ring: String, reward_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	if data_registry != null and not container_def.is_empty():
		var generated: Array[Dictionary] = data_registry.generate_container_loot(container_def, ring, reward_rng, _generation_context())
		if not generated.is_empty():
			rewards.append_array(generated)
	if not rewards.is_empty():
		return rewards
	return [
		make_item.call("scrap_metal", "废金属", 1 + reward_rng.randi_range(0, 1), 0.1, 99),
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

func _spawn_point_id(spawn_point: Node) -> String:
	if spawn_point == null:
		return ""
	if spawn_point.has_method("get_point_id"):
		return String(spawn_point.get_point_id())
	return String(spawn_point.name)

func _refresh_resource_profile() -> void:
	if data_registry == null:
		map_profile = {}
		location_state_rule = {}
		return
	map_profile = data_registry.get_map_resource_profile(map_id)
	location_state_rule = data_registry.get_location_state_rule(location_state)

func _target_container_count_for_current_location() -> int:
	var min_count := int(map_profile.get("container_count_min", INITIAL_SPAWN_COUNT))
	var max_count := int(map_profile.get("container_count_max", min_count))
	max_count = maxi(min_count, max_count)
	var base_count := rng.randi_range(min_count, max_count)
	var multiplier := maxf(0.10, float(location_state_rule.get("quantity_multiplier", 1.0)))
	return maxi(1, int(round(float(base_count) * multiplier)))

func _generation_context() -> Dictionary:
	return {
		"map_id": map_id,
		"location_state": location_state,
		"map_profile": map_profile,
		"location_state_rule": location_state_rule,
	}

func get_debug_snapshot() -> Dictionary:
	return {
		"map_id": map_id,
		"location_state": location_state,
		"visit_count_before": visit_count_before,
		"target_container_count": target_container_count,
		"active_container_count": _active_container_count(),
		"map_profile": map_profile.duplicate(true),
		"location_state_rule": location_state_rule.duplicate(true),
	}

func _active_container_count() -> int:
	var count := 0
	if container_root == null:
		return count
	for child in container_root.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion() and child.get("interact_type") == "container":
			count += 1
	return count

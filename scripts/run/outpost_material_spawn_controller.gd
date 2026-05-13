class_name OutpostMaterialSpawnController
extends RefCounted

const MATERIAL_LIFETIME_SECONDS := 120.0
const REQUIREMENTS_PER_OUTPOST := 2
const REQUIREMENT_AMOUNT := 1

var outpost_root: Node
var get_spawn_points: Callable
var make_interactable: Callable
var make_item: Callable
var remove_interactable: Callable
var data_registry
var unit: float = 64.0

func setup(
	p_outpost_root: Node,
	p_get_spawn_points: Callable,
	p_make_interactable: Callable,
	p_make_item: Callable,
	p_remove_interactable: Callable,
	p_unit: float,
	p_data_registry = null
) -> void:
	outpost_root = p_outpost_root
	get_spawn_points = p_get_spawn_points
	make_interactable = p_make_interactable
	make_item = p_make_item
	remove_interactable = p_remove_interactable
	unit = p_unit
	data_registry = p_data_registry

func build_requirements(first_outpost_id: String, second_outpost_id: String, seed: int = 0) -> Dictionary:
	var requirements := {}
	var rng := RandomNumberGenerator.new()
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = _requirements_seed(seed, first_outpost_id, second_outpost_id)
	var rows := _repair_material_rows()
	requirements[first_outpost_id] = _random_requirements(rows, rng)
	requirements[second_outpost_id] = _random_requirements(rows, rng)
	return requirements

func spawn_for_outposts(requirements_by_outpost: Dictionary, outpost_positions: Dictionary) -> Array:
	var spawned: Array = []
	var used_positions: Array[Vector2] = _existing_material_positions()
	for outpost_id in requirements_by_outpost.keys():
		var base_pos: Vector2 = outpost_positions.get(outpost_id, Vector2.ZERO)
		var requirements: Dictionary = requirements_by_outpost[outpost_id]
		var offset := 0
		for item_id in requirements.keys():
			var data: Dictionary = requirements[item_id]
			var pos: Vector2 = _next_material_position(base_pos, used_positions, offset)
			var pickup = make_interactable.call(
				"pickup_%s_%s" % [outpost_id, item_id],
				"material",
				data.display_name,
				pos,
				material_color(String(item_id))
			)
			pickup.payload = {
				"item": _make_repair_material_item(String(item_id), data, String(outpost_id)),
				"outpost_id": outpost_id,
				"item_id": String(item_id),
				"lifetime": MATERIAL_LIFETIME_SECONDS,
				"lifetime_max": MATERIAL_LIFETIME_SECONDS,
			}
			outpost_root.add_child(pickup)
			spawned.append(pickup)
			used_positions.append(pos)
			offset += 1
	return spawned

func update_lifetimes(delta: float, interactables: Array) -> void:
	for interactable in interactables.duplicate():
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		var payload: Dictionary = interactable.get("payload")
		if not payload.has("lifetime"):
			continue
		payload["lifetime"] = float(payload.get("lifetime", 0.0)) - maxf(0.0, delta)
		if float(payload.get("lifetime", 0.0)) > 0.0:
			continue
		var outpost_id := String(payload.get("outpost_id", ""))
		var item_id := String(payload.get("item_id", payload.get("item", {}).get("item_id", "")))
		var item: Dictionary = payload.get("item", {})
		var old_pos: Vector2 = interactable.global_position if interactable is Node2D else Vector2.INF
		if remove_interactable.is_valid():
			remove_interactable.call(interactable)
		_respawn_material(outpost_id, item_id, item, old_pos)

func _respawn_material(outpost_id: String, item_id: String, item: Dictionary, old_pos: Vector2):
	if item_id.is_empty() or item.is_empty():
		return null
	var base_pos := _base_position_for_outpost(outpost_id, old_pos)
	var used_positions: Array[Vector2] = _existing_material_positions()
	if old_pos != Vector2.INF:
		used_positions.append(old_pos)
	var pos := _next_material_position(base_pos, used_positions, 0)
	var display_name := String(item.get("display_name", item_id))
	var pickup = make_interactable.call(
		"pickup_%s_%s" % [outpost_id, item_id],
		"material",
		display_name,
		pos,
		material_color(item_id)
	)
	pickup.payload = {
		"item": _normalize_repair_material_item(item, outpost_id),
		"outpost_id": outpost_id,
		"item_id": item_id,
		"lifetime": MATERIAL_LIFETIME_SECONDS,
		"lifetime_max": MATERIAL_LIFETIME_SECONDS,
	}
	if outpost_root != null:
		outpost_root.add_child(pickup)
	return pickup

func _base_position_for_outpost(outpost_id: String, fallback_pos: Vector2) -> Vector2:
	if outpost_root == null:
		return fallback_pos if fallback_pos != Vector2.INF else Vector2.ZERO
	for child in outpost_root.get_children():
		if not is_instance_valid(child) or not (child is Node2D):
			continue
		if child.get("interact_type") != "outpost":
			continue
		if String(child.get("interact_id")) == outpost_id:
			return child.global_position
	return fallback_pos if fallback_pos != Vector2.INF else Vector2.ZERO

func _next_material_position(base_pos: Vector2, used_positions: Array[Vector2], fallback_offset: int) -> Vector2:
	var material_points: Array = _material_points_for_outpost(base_pos)
	for point in material_points:
		if not (point is Node2D):
			continue
		var pos: Vector2 = point.global_position
		if _is_position_used(pos, used_positions):
			continue
		return pos
	return _fallback_material_position(base_pos, used_positions, fallback_offset)

func _material_points_for_outpost(base_pos: Vector2) -> Array:
	var points: Array = []
	if get_spawn_points.is_valid():
		points = get_spawn_points.call()
	points.sort_custom(func(a, b): return a.global_position.distance_squared_to(base_pos) < b.global_position.distance_squared_to(base_pos))
	return points

func _fallback_material_position(base_pos: Vector2, used_positions: Array[Vector2], fallback_offset: int) -> Vector2:
	var offset := fallback_offset
	while offset < fallback_offset + 64:
		var pos := base_pos + Vector2(-2.5 + offset * 1.3, 3.0 + offset * 0.8) * unit
		if not _is_position_used(pos, used_positions):
			return pos
		offset += 1
	return base_pos + Vector2(5.0, 5.0) * unit

func _existing_material_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	if outpost_root == null:
		return result
	for child in outpost_root.get_children():
		if not is_instance_valid(child) or not (child is Node2D):
			continue
		if child.get("interact_type") != "material":
			continue
		result.append(child.global_position)
	return result

func _is_position_used(pos: Vector2, used_positions: Array[Vector2]) -> bool:
	for used_pos in used_positions:
		if used_pos.distance_squared_to(pos) <= 1.0:
			return true
	return false

func material_color(item_id: String) -> Color:
	var material := _repair_material_row(item_id)
	var color_text := String(material.get("color_hex", ""))
	if not color_text.is_empty():
		return Color(color_text)
	return Color(0.30, 0.85, 0.38)

func _make_repair_material_item(item_id: String, data: Dictionary, outpost_id: String) -> Dictionary:
	var item: Dictionary = {}
	if data_registry != null and data_registry.has_method("make_repair_material_stack"):
		item = data_registry.make_repair_material_stack(item_id, int(data.get("amount", 1)), outpost_id)
	if item.is_empty():
		item = make_item.call(item_id, data.display_name, data.amount, data.weight, 1)
	return _normalize_repair_material_item(item, outpost_id)

func _normalize_repair_material_item(item: Dictionary, outpost_id: String) -> Dictionary:
	var normalized := item.duplicate(true)
	var material_id := String(normalized.get("repair_material_id", normalized.get("item_id", "")))
	normalized["repair_material_id"] = StringName(material_id)
	normalized["item_id"] = StringName(material_id)
	normalized["source"] = "repair_material_spawn"
	normalized["outpost_id"] = outpost_id
	normalized.erase("item_type")
	normalized.erase("tags")
	normalized.erase("quality")
	normalized.erase("quality_color")
	normalized.erase("sellable")
	normalized.erase("sell_currency_id")
	normalized.erase("sell_value")
	return normalized

func _random_requirements(rows: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var result := {}
	var candidates: Array[Dictionary] = []
	for row in rows:
		candidates.append(row)
	var pick_count: int = mini(REQUIREMENTS_PER_OUTPOST, candidates.size())
	for _index in range(pick_count):
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var row: Dictionary = candidates[candidate_index]
		candidates.remove_at(candidate_index)
		var material_id := String(row.get("id", ""))
		if material_id.is_empty():
			continue
		result[material_id] = {
			"display_name": String(row.get("display_name", material_id)),
			"amount": REQUIREMENT_AMOUNT,
			"weight": float(row.get("weight", 0.0)),
		}
	return result

func _requirements_seed(seed: int, first_outpost_id: String, second_outpost_id: String) -> int:
	var text := "%s|%s|%s|repair_materials" % [seed, first_outpost_id, second_outpost_id]
	var hashed := int(text.hash())
	if hashed < 0:
		hashed = -hashed
	return maxi(1, hashed)

func _repair_material_rows() -> Array[Dictionary]:
	if data_registry != null and data_registry.has_method("get_repair_material_rows"):
		var rows: Array[Dictionary] = data_registry.get_repair_material_rows()
		if rows.is_empty() and data_registry.has_method("load_all"):
			data_registry.load_all()
			rows = data_registry.get_repair_material_rows()
		return rows
	return []

func _repair_material_row(item_id: String) -> Dictionary:
	if data_registry != null and data_registry.has_method("get_repair_material"):
		var row: Dictionary = data_registry.get_repair_material(item_id)
		if row.is_empty() and data_registry.has_method("load_all"):
			data_registry.load_all()
			row = data_registry.get_repair_material(item_id)
		return row
	return {}

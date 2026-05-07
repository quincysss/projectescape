class_name OutpostMaterialSpawnController
extends RefCounted

var outpost_root: Node
var get_spawn_points: Callable
var make_interactable: Callable
var make_item: Callable
var unit: float = 64.0

func setup(
	p_outpost_root: Node,
	p_get_spawn_points: Callable,
	p_make_interactable: Callable,
	p_make_item: Callable,
	p_unit: float
) -> void:
	outpost_root = p_outpost_root
	get_spawn_points = p_get_spawn_points
	make_interactable = p_make_interactable
	make_item = p_make_item
	unit = p_unit

func build_requirements(first_outpost_id: String, second_outpost_id: String) -> Dictionary:
	return {
		first_outpost_id: {
			"scrap_metal": {"display_name": "废金属", "amount": 2, "weight": 2.0},
			"old_battery": {"display_name": "旧电池", "amount": 1, "weight": 4.0},
		},
		second_outpost_id: {
			"copper_wire": {"display_name": "铜线", "amount": 2, "weight": 1.5},
			"signal_core": {"display_name": "信号核心", "amount": 1, "weight": 3.0},
		},
	}

func spawn_for_outposts(requirements_by_outpost: Dictionary, outpost_positions: Dictionary) -> Array:
	var spawned: Array = []
	for outpost_id in requirements_by_outpost.keys():
		var base_pos: Vector2 = outpost_positions.get(outpost_id, Vector2.ZERO)
		var requirements: Dictionary = requirements_by_outpost[outpost_id]
		var material_points := _material_points_for_outpost(base_pos, requirements.size())
		var offset := 0
		for item_id in requirements.keys():
			var data: Dictionary = requirements[item_id]
			var pos: Vector2 = (
				material_points[offset].global_position
				if offset < material_points.size()
				else base_pos + Vector2(-2.5 + offset * 1.3, 3.0 + offset * 0.8) * unit
			)
			var pickup = make_interactable.call(
				"pickup_%s" % item_id,
				"material",
				data.display_name,
				pos,
				material_color(String(item_id))
			)
			pickup.payload = {
				"item": make_item.call(item_id, data.display_name, data.amount, data.weight, 5)
			}
			outpost_root.add_child(pickup)
			spawned.append(pickup)
			offset += 1
	return spawned

func _material_points_for_outpost(base_pos: Vector2, count: int) -> Array:
	var points: Array = []
	if get_spawn_points.is_valid():
		points = get_spawn_points.call()
	points.sort_custom(func(a, b): return a.global_position.distance_squared_to(base_pos) < b.global_position.distance_squared_to(base_pos))
	return points.slice(0, count)

func material_color(item_id: String) -> Color:
	match item_id:
		"scrap_metal":
			return Color(0.72, 0.72, 0.68)
		"old_battery":
			return Color(0.95, 0.34, 0.30)
		"copper_wire":
			return Color(0.95, 0.55, 0.22)
		"signal_core":
			return Color(0.30, 0.95, 0.92)
		_:
			return Color(0.30, 0.85, 0.38)

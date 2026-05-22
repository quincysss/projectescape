extends SceneTree

const ContainerSpawnControllerScript := preload("res://scripts/run/container_spawn_controller.gd")
const InteractableScript := preload("res://scripts/run/run_interactable.gd")
const MapLayoutPointScript := preload("res://scripts/map/map_layout_point.gd")

var container_root: Node2D
var interactables: Array = []
var spawn_points: Array = []

func _initialize() -> void:
	var ok := await _verify_map_resource_ecology()
	print("Map resource ecology containers verified." if ok else "Map resource ecology containers failed.")
	quit(0 if ok else 1)

func _verify_map_resource_ecology() -> bool:
	container_root = Node2D.new()
	get_root().add_child(container_root)
	_make_spawn_points(24)
	var controller = ContainerSpawnControllerScript.new()
	controller.setup(
		container_root,
		Callable(self, "_spawn_points"),
		Callable(self, "_make_interactable"),
		Callable(self, "_make_item"),
		Callable(self, "_remove_interactable"),
		64.0
	)
	var ok := true

	controller.configure_location("clinic_small", "rich", 0, 4201)
	controller.spawn_initial()
	var rich_count := _container_count()
	var rich_snapshot: Dictionary = controller.get_debug_snapshot()
	if rich_count <= 0 or rich_count != int(rich_snapshot.get("active_container_count", -1)):
		printerr("Expected rich clinic to spawn tracked instance containers.")
		ok = false
	if rich_snapshot.get("map_id", "") != "clinic_small" or rich_snapshot.get("location_state", "") != "rich":
		printerr("Expected spawn snapshot to include clinic/rich context.")
		ok = false

	controller.update_lifetimes(999.0, interactables)
	if _container_count() != rich_count:
		printerr("Expected ordinary containers not to expire over time.")
		ok = false

	controller.configure_location("clinic_small", "poor", 2, 4201)
	controller.spawn_initial()
	var poor_count := _container_count()
	if poor_count >= rich_count:
		printerr("Expected poor location container count to be lower than rich count; rich=%s poor=%s." % [rich_count, poor_count])
		ok = false

	controller.clear_instance_containers()
	if _container_count() != 0 or not interactables.is_empty():
		printerr("Expected leaving map instance to clear residual containers.")
		ok = false

	ok = _verify_map_container_bias(controller) and ok
	ok = _verify_state_loot_decline(controller) and ok

	_clear_spawn_points()
	container_root.queue_free()
	await process_frame
	return ok

func _verify_map_container_bias(controller) -> bool:
	controller.configure_location("clinic_small", "rich", 0, 9101)
	var clinic_medical := 0
	for _index in range(80):
		var def: Dictionary = controller._container_definition("", "middle")
		if String(def.get("type_id", "")) == "medical_cabinet":
			clinic_medical += 1

	controller.configure_location("industrial_yard", "rich", 0, 9101)
	var industrial_tooling := 0
	for _index in range(80):
		var def: Dictionary = controller._container_definition("", "middle")
		var type_id := String(def.get("type_id", ""))
		if type_id == "tool_cabinet" or type_id == "wooden_crate":
			industrial_tooling += 1

	if clinic_medical < 30:
		printerr("Expected clinic profile to heavily prefer medical cabinets, got %s/80." % clinic_medical)
		return false
	if industrial_tooling < 45:
		printerr("Expected industrial profile to prefer tooling containers, got %s/80." % industrial_tooling)
		return false
	return true

func _verify_state_loot_decline(controller) -> bool:
	controller.configure_location("industrial_yard", "rich", 0, 3301)
	var rich_container = controller.spawn_container(Vector2(10000, 0), "large_safe", "outer", "rich_probe")
	var rich_rewards: Array = controller.ensure_container_rewards(rich_container)
	controller.clear_instance_containers()

	controller.configure_location("industrial_yard", "poor", 2, 3301)
	var poor_container = controller.spawn_container(Vector2(11000, 0), "large_safe", "outer", "poor_probe")
	var poor_rewards: Array = controller.ensure_container_rewards(poor_container)
	controller.clear_instance_containers()

	if poor_rewards.size() >= rich_rewards.size():
		printerr("Expected poor location loot count to be lower; rich=%s poor=%s." % [rich_rewards.size(), poor_rewards.size()])
		return false
	return true

func _make_spawn_points(count: int) -> void:
	_clear_spawn_points()
	spawn_points.clear()
	var rings := ["inner", "middle", "outer", "far_outer"]
	for index in range(count):
		var point = MapLayoutPointScript.new()
		point.name = "TestContainerPoint_%02d" % index
		point.point_id = "test_container_point_%02d" % index
		point.ring = rings[index % rings.size()]
		point.position = Vector2(index * 96.0, 0.0)
		spawn_points.append(point)

func _clear_spawn_points() -> void:
	for point in spawn_points:
		if is_instance_valid(point):
			point.free()
	spawn_points.clear()

func _spawn_points() -> Array:
	return spawn_points

func _make_interactable(id: String, type: String, label_text: String, pos: Vector2, color: Color, size_units: Vector2 = Vector2.ZERO, container_def: Dictionary = {}):
	var area := Area2D.new()
	area.name = id
	area.script = InteractableScript
	area.interact_id = id
	area.interact_type = type
	area.display_name = label_text
	area.position = pos
	interactables.append(area)
	return area

func _make_item(id: String, display_name: String, amount: int, weight: float, stack_limit: int) -> Dictionary:
	return {
		"item_id": id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": stack_limit,
		"item_type": "material",
	}

func _remove_interactable(interactable) -> void:
	interactables.erase(interactable)
	if is_instance_valid(interactable):
		interactable.queue_free()

func _container_count() -> int:
	var count := 0
	for child in container_root.get_children():
		if is_instance_valid(child) and child.get("interact_type") == "container":
			count += 1
	return count

extends SceneTree

const ContainerSpawnControllerScript := preload("res://scripts/run/container_spawn_controller.gd")
const InteractableVisualBuilderScript := preload("res://scripts/run/interactable_visual_builder.gd")
const InteractableScript := preload("res://scripts/run/run_interactable.gd")

var container_root: Node2D
var visual_builder
var interactables: Array = []

func _initialize() -> void:
	var ok := await _verify_config_driven_container_spawn()
	print("Config-driven container spawn verified." if ok else "Config-driven container spawn failed.")
	quit(0 if ok else 1)

func _verify_config_driven_container_spawn() -> bool:
	container_root = Node2D.new()
	get_root().add_child(container_root)
	visual_builder = InteractableVisualBuilderScript.new()
	visual_builder.setup(64.0)
	var controller = ContainerSpawnControllerScript.new()
	controller.setup(
		container_root,
		Callable(self, "_spawn_points"),
		Callable(self, "_make_interactable"),
		Callable(self, "_make_item"),
		Callable(self, "_remove_interactable"),
		64.0
	)
	var container = controller.spawn_container(Vector2.ZERO, "large_safe", "far_outer")
	await process_frame
	var ok := true
	if container == null:
		printerr("Expected large_safe container to spawn.")
		return false
	if container.display_name != "大保险柜":
		printerr("Expected configured container display name, got %s." % container.display_name)
		ok = false
	if container.payload.get("type_id", "") != "large_safe":
		printerr("Expected configured type_id.")
		ok = false
	if container.payload.get("container_color", Color.WHITE) != Color("#3A8DFF"):
		printerr("Expected unified blue container color.")
		ok = false
	if float(container.payload.get("open_time", 0.0)) < 3.6:
		printerr("Expected large_safe open time from table.")
		ok = false
	if bool(container.payload.get("loot_generated", true)):
		printerr("Expected configured container loot to wait until opening.")
		ok = false
	var rewards: Array = controller.ensure_container_rewards(container)
	if rewards.size() < 2:
		printerr("Expected large_safe loot to generate single-item rewards, got %s." % rewards.size())
		ok = false
	for item in rewards:
		if not item.has("quality") or not item.has("quality_color"):
			printerr("Expected generated loot to include item quality display data.")
			ok = false
		if int(item.get("amount", 0)) != 1 or int(item.get("stack_limit", 0)) != 1:
			printerr("Expected generated loot to be single and non-stackable.")
			ok = false
	var visual := container.get_node_or_null("ContainerReadableRoot/ContainerVisual") as Sprite2D
	if visual == null or visual.texture == null or visual.scale.x <= 0.0:
		printerr("Expected configured container sprite visual.")
		ok = false
	container_root.queue_free()
	await process_frame
	return ok

func _spawn_points() -> Array:
	return []

func _make_interactable(id: String, type: String, label_text: String, pos: Vector2, color: Color, size_units: Vector2 = Vector2.ZERO, container_def: Dictionary = {}):
	var area := Area2D.new()
	area.name = id
	area.script = InteractableScript
	area.interact_id = id
	area.interact_type = type
	area.display_name = label_text
	area.position = pos
	var visual_size: Vector2 = visual_builder.add_interactable_visual(area, type, label_text, color, size_units, container_def)
	var label: Label = visual_builder.make_world_label(label_text, Vector2(-visual_size.x * 0.5, -visual_size.y * 0.5 - 42.0), area)
	label.z_index = 20
	interactables.append(area)
	return area

func _make_item(id: String, display_name: String, amount: int, weight: float, stack_limit: int) -> Dictionary:
	return {
		"item_id": id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
	}

func _remove_interactable(interactable) -> void:
	interactables.erase(interactable)
	if is_instance_valid(interactable):
		interactable.queue_free()

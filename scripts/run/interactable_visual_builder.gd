class_name InteractableVisualBuilder
extends RefCounted

const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const CONTAINER_VISUAL_SIZE_UNITS := Vector2(3.4, 3.4)
const MATERIAL_VISUAL_SIZE_UNITS := Vector2(2.0, 2.0)

var unit: float = 64.0

func setup(p_unit: float) -> void:
	unit = p_unit

func add_interactable_visual(area: Node, interact_type: String, label_text: String, color: Color) -> Vector2:
	match interact_type:
		"outpost":
			var outpost_size: Vector2 = _u(OUTPOST_SIZE_UNITS)
			_add_rect_visual(area, "OutpostVisual", outpost_size, color, 10)
			return outpost_size
		"container":
			var container_size: Vector2 = _u(CONTAINER_VISUAL_SIZE_UNITS)
			_add_rect_visual(area, "ContainerVisual", container_size, Color(0.08, 0.08, 0.08, 0.92), 12)
			_add_rect_visual(area, "ContainerLifetimeFill", container_size, color, 14)
			_add_rect_outline(area, "ContainerOutline", container_size, Color(0.02, 0.02, 0.02), 10.0, 25)
			_add_center_marker_label(area, _container_marker_text(label_text), container_size, Color(0.0, 0.0, 0.0), 52)
			_add_container_lifetime_label(area, container_size)
			return container_size
		"material":
			var material_size: Vector2 = _u(MATERIAL_VISUAL_SIZE_UNITS)
			_add_diamond_visual(area, "BuildMaterialVisual", material_size, color, 12)
			_add_diamond_outline(area, "BuildMaterialOutline", material_size, Color(0.02, 0.09, 0.04), 8.0, 13)
			_add_center_marker_label(area, "建材", material_size, Color(0.0, 0.0, 0.0), 22)
			return material_size
		_:
			var default_size: Vector2 = _u(RESOURCE_SIZE_UNITS)
			_add_rect_visual(area, "InteractableVisual", default_size, color, 10)
			return default_size

func make_world_label(text: String, pos: Vector2, parent: Node) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(160, 44)
	parent.add_child(label)
	return label

func refresh_container_lifetime_visual(container: Node) -> void:
	var payload: Dictionary = container.get("payload")
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 45.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var visual := container.get_node_or_null("ContainerVisual") as ColorRect
	var fill := container.get_node_or_null("ContainerLifetimeFill") as ColorRect
	if visual != null and fill != null:
		fill.color = rarity_color(String(payload.get("rarity", "C")))
		fill.position = visual.position
		fill.size = Vector2(visual.size.x * ratio, visual.size.y)
	var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
	if lifetime_label != null:
		lifetime_label.text = "%ds" % int(ceil(lifetime))

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

func _add_rect_visual(parent: Node, node_name: String, size: Vector2, color: Color, z: int) -> ColorRect:
	var box := ColorRect.new()
	box.name = node_name
	box.color = color
	box.size = size
	box.position = -size * 0.5
	box.z_index = z
	parent.add_child(box)
	return box

func _add_rect_outline(parent: Node, node_name: String, size: Vector2, color: Color, width: float, z: int) -> Line2D:
	var half := size * 0.5
	var outline := Line2D.new()
	outline.name = node_name
	outline.default_color = color
	outline.width = width
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	outline.z_index = z
	parent.add_child(outline)
	return outline

func _add_diamond_visual(parent: Node, node_name: String, size: Vector2, color: Color, z: int) -> Polygon2D:
	var half := size * 0.5
	var diamond := Polygon2D.new()
	diamond.name = node_name
	diamond.color = color
	diamond.polygon = PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	])
	diamond.z_index = z
	parent.add_child(diamond)
	return diamond

func _add_diamond_outline(parent: Node, node_name: String, size: Vector2, color: Color, width: float, z: int) -> Line2D:
	var half := size * 0.5
	var outline := Line2D.new()
	outline.name = node_name
	outline.default_color = color
	outline.width = width
	outline.closed = true
	outline.points = PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, 0.0),
		Vector2(0.0, half.y),
		Vector2(-half.x, 0.0),
	])
	outline.z_index = z
	parent.add_child(outline)
	return outline

func _add_center_marker_label(parent: Node, text: String, size: Vector2, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.name = "MarkerLabel"
	label.text = text
	label.position = -size * 0.5
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 30
	parent.add_child(label)
	return label

func _add_container_lifetime_label(parent: Node, size: Vector2) -> Label:
	var label := Label.new()
	label.name = "ContainerLifetimeLabel"
	label.text = "45s"
	label.position = Vector2(-size.x * 0.5, size.y * 0.5 + 6.0)
	label.size = Vector2(size.x, 34.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 31
	parent.add_child(label)
	return label

func _container_marker_text(label_text: String) -> String:
	var grade := label_text.substr(0, 1)
	if ["C", "B", "A", "S"].has(grade):
		return "%s级" % grade
	return "箱"

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * unit
	return float(value) * unit

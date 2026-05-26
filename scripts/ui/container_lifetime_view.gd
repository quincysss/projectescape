class_name ContainerLifetimeView
extends RefCounted

const MATERIAL_VISUAL_SIZE_UNITS := Vector2(4.0, 4.0)

var unit: float = 64.0

func setup(p_unit: float) -> void:
	unit = p_unit

func refresh_container(container: Node) -> void:
	if container == null or not is_instance_valid(container):
		return
	var payload: Dictionary = container.get("payload")
	if not payload.has("lifetime") and not payload.has("lifetime_max"):
		return
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 45.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var bar_background := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeBarBackground") as ColorRect
	var fill := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeFill") as ColorRect
	if bar_background != null and fill != null:
		fill.color = payload.get("container_color", Color(0.23, 0.55, 1.0))
		fill.position = bar_background.position
		fill.size = Vector2(bar_background.size.x * ratio, bar_background.size.y)
	var lifetime_label := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeLabel") as Label
	if lifetime_label != null:
		lifetime_label.text = "%ds" % int(ceil(lifetime))

func refresh_material(material: Node) -> void:
	if material == null or not is_instance_valid(material):
		return
	var payload: Dictionary = material.get("payload")
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 120.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var visual := material.get_node_or_null("BuildMaterialVisual") as Polygon2D
	var fill := material.get_node_or_null("BuildMaterialLifetimeFill") as Polygon2D
	if visual == null or fill == null:
		return
	fill.polygon = _diamond_fill_polygon(_diamond_size_from_polygon(visual.polygon), ratio)

func _diamond_fill_polygon(size: Vector2, ratio: float) -> PackedVector2Array:
	ratio = clampf(ratio, 0.0, 1.0)
	if ratio <= 0.0:
		return PackedVector2Array()
	var half := size * 0.5
	if ratio >= 1.0:
		return PackedVector2Array([
			Vector2(0.0, -half.y),
			Vector2(half.x, 0.0),
			Vector2(0.0, half.y),
			Vector2(-half.x, 0.0),
		])
	var cut_y := half.y - size.y * ratio
	var cut_half_width := half.x * (1.0 - absf(cut_y) / half.y)
	if cut_y <= 0.0:
		return PackedVector2Array([
			Vector2(-cut_half_width, cut_y),
			Vector2(cut_half_width, cut_y),
			Vector2(half.x, 0.0),
			Vector2(0.0, half.y),
			Vector2(-half.x, 0.0),
		])
	return PackedVector2Array([
		Vector2(-cut_half_width, cut_y),
		Vector2(cut_half_width, cut_y),
		Vector2(0.0, half.y),
	])

func _diamond_size_from_polygon(polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return _u(MATERIAL_VISUAL_SIZE_UNITS)
	var min_pos := polygon[0]
	var max_pos := polygon[0]
	for point in polygon:
		min_pos.x = minf(min_pos.x, point.x)
		min_pos.y = minf(min_pos.y, point.y)
		max_pos.x = maxf(max_pos.x, point.x)
		max_pos.y = maxf(max_pos.y, point.y)
	return max_pos - min_pos

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * unit
	return float(value) * unit

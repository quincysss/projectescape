class_name InteractableVisualBuilder
extends RefCounted

const ContainerLifetimeViewScript := preload("res://scripts/ui/container_lifetime_view.gd")
const OutpostRequirementBubbleViewScript := preload("res://scripts/ui/outpost_requirement_bubble_view.gd")
const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const CONTAINER_VISUAL_SIZE_UNITS := Vector2(3.4, 3.4)
const MATERIAL_VISUAL_SIZE_UNITS := Vector2(4.0, 4.0)
const CONTAINER_NAME_FONT_SIZE := 72
const CONTAINER_NAME_COLOR := Color("#FFC547")
const READABLE_OVERLAY_META := "_readable_world_overlay"
const READABLE_BASE_POSITION_META := "_readable_world_overlay_base_position"
const READABLE_BASE_SCALE_META := "_readable_world_overlay_base_scale"
const READABLE_POSITION_SCALES_META := "_readable_world_overlay_position_scales"

var unit: float = 64.0
var container_lifetime_view = ContainerLifetimeViewScript.new()
var outpost_requirement_bubble_view = OutpostRequirementBubbleViewScript.new()

func setup(p_unit: float) -> void:
	unit = p_unit
	container_lifetime_view.setup(p_unit)

func add_interactable_visual(area: Node, interact_type: String, label_text: String, color: Color, size_units: Vector2 = Vector2.ZERO, visual_data: Dictionary = {}) -> Vector2:
	match interact_type:
		"outpost":
			var outpost_size: Vector2 = _u(size_units if size_units != Vector2.ZERO else OUTPOST_SIZE_UNITS)
			return outpost_size
		"container":
			var container_size: Vector2 = _u(size_units if size_units != Vector2.ZERO else CONTAINER_VISUAL_SIZE_UNITS)
			_add_container_formal_visual(area, label_text, container_size, color, visual_data)
			return container_size
		"material":
			var material_size: Vector2 = _u(MATERIAL_VISUAL_SIZE_UNITS)
			_mark_readable_overlay(_add_diamond_visual(area, "BuildMaterialVisual", material_size, Color(0.03, 0.07, 0.04, 0.92), 12))
			_mark_readable_overlay(_add_diamond_visual(area, "BuildMaterialLifetimeFill", material_size, color, 13))
			_mark_readable_overlay(_add_diamond_outline(area, "BuildMaterialOutline", material_size, Color(0.02, 0.09, 0.04), 12.0, 14))
			_add_material_marker_label(area, _material_marker_text(label_text), material_size)
			return material_size
		_:
			var default_size: Vector2 = _u(RESOURCE_SIZE_UNITS)
			_add_rect_visual(area, "InteractableVisual", default_size, color, 10)
			return default_size

func make_world_label(text: String, pos: Vector2, parent: Node) -> Label:
	var label := Label.new()
	label.name = "WorldLabel"
	label.text = text
	label.position = pos
	label.size = Vector2(160, 44)
	parent.add_child(label)
	_mark_readable_overlay(label)
	return label

func apply_readable_overlay_scale(parent: Node, scale_value: float) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		if child.name == "OutpostRequirementBubbles" and child is Node2D:
			_apply_requirement_bubble_scale(child, scale_value)
			continue
		if child.has_meta(READABLE_OVERLAY_META):
			_apply_readable_node_scale(child, scale_value)
		apply_readable_overlay_scale(child, scale_value)

func refresh_outpost_requirement_bubbles(outpost: Node, get_inventory_count: Callable) -> void:
	outpost_requirement_bubble_view.refresh(outpost, get_inventory_count)

func refresh_container_lifetime_visual(container: Node) -> void:
	container_lifetime_view.refresh_container(container)

func refresh_material_lifetime_visual(material: Node) -> void:
	container_lifetime_view.refresh_material(material)

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

func _add_container_formal_visual(parent: Node, label_text: String, size: Vector2, color: Color, visual_data: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "ContainerReadableRoot"
	root.z_index = 12
	parent.add_child(root)
	_mark_readable_overlay(root)

	var icon_size := _container_icon_display_size(size, visual_data)
	var panel_width := clampf(icon_size.x * 1.55, 280.0, 500.0)
	var name_size := Vector2(panel_width, 92.0)
	var icon_half_y := icon_size.y * 0.5
	var name_y := -icon_half_y - 112.0

	var name_label := Label.new()
	name_label.name = "ContainerNameLabel"
	name_label.text = label_text
	name_label.position = Vector2(-name_size.x * 0.5, name_y)
	name_label.size = name_size
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", CONTAINER_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", CONTAINER_NAME_COLOR)
	_apply_text_shadow(name_label, 3)
	name_label.z_index = 34
	root.add_child(name_label)

	var icon := Sprite2D.new()
	icon.name = "ContainerVisual"
	icon.texture = _container_icon_texture(visual_data)
	icon.centered = true
	if icon.texture != null:
		var texture_size := icon.texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			var icon_scale := minf(icon_size.x / texture_size.x, icon_size.y / texture_size.y)
			icon.scale = Vector2(icon_scale, icon_scale)
	icon.z_index = 30
	root.add_child(icon)

func _container_icon_display_size(size: Vector2, visual_data: Dictionary = {}) -> Vector2:
	var extent := maxf(size.x, size.y)
	return Vector2(extent, extent) * _container_icon_display_scale(visual_data)

func _container_icon_display_scale(visual_data: Dictionary) -> float:
	var type_id := String(visual_data.get("type_id", ""))
	match type_id:
		"large_safe", "small_safe", "anomaly_case":
			return 0.48
		_:
			return 0.66

func _container_icon_texture(visual_data: Dictionary) -> Texture2D:
	var icon_path := String(visual_data.get("icon_path", ""))
	if icon_path.is_empty():
		var type_id := String(visual_data.get("type_id", ""))
		if not type_id.is_empty():
			icon_path = "res://assets/ui/containericon/%s.png" % type_id
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D

func _apply_text_shadow(label: Label, offset: int) -> void:
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", offset)
	label.add_theme_constant_override("shadow_offset_y", offset)

func _add_material_marker_label(parent: Node, text: String, size: Vector2) -> Label:
	var label_size := Vector2(maxf(size.x * 1.65, 420.0), 98.0)
	var background := ColorRect.new()
	background.name = "MarkerLabelBackground"
	background.color = Color(0.0, 0.0, 0.0, 0.78)
	background.position = -label_size * 0.5
	background.size = label_size
	background.z_index = 29
	parent.add_child(background)
	_mark_readable_overlay(background)

	var label := Label.new()
	label.name = "MarkerLabel"
	label.text = text
	label.position = background.position
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_apply_text_shadow(label, 1)
	label.z_index = 30
	parent.add_child(label)
	_mark_readable_overlay(label)
	return label

func _mark_readable_overlay(node: Node, position_scales: bool = false) -> void:
	node.set_meta(READABLE_OVERLAY_META, true)
	node.set_meta(READABLE_BASE_POSITION_META, node.get("position"))
	node.set_meta(READABLE_BASE_SCALE_META, node.get("scale"))
	node.set_meta(READABLE_POSITION_SCALES_META, position_scales)
	if node is Control:
		node.pivot_offset = node.size * 0.5

func _apply_readable_node_scale(node: Node, scale_value: float) -> void:
	var base_scale: Vector2 = node.get_meta(READABLE_BASE_SCALE_META, node.get("scale"))
	node.set("scale", base_scale * scale_value)
	if bool(node.get_meta(READABLE_POSITION_SCALES_META, false)):
		var base_position: Vector2 = node.get_meta(READABLE_BASE_POSITION_META, node.get("position"))
		node.set("position", base_position * scale_value)

func _apply_requirement_bubble_scale(root: Node2D, scale_value: float) -> void:
	var base_scale: Vector2 = root.get_meta(READABLE_BASE_SCALE_META, root.scale)
	root.scale = base_scale * scale_value

func _material_marker_text(label_text: String) -> String:
	if label_text.length() <= 4:
		return label_text
	return label_text.substr(0, 4)

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * unit
	return float(value) * unit

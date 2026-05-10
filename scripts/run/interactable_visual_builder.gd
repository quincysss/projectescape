class_name InteractableVisualBuilder
extends RefCounted

const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const CONTAINER_VISUAL_SIZE_UNITS := Vector2(3.4, 3.4)
const MATERIAL_VISUAL_SIZE_UNITS := Vector2(4.0, 4.0)
const OUTPOST_REQUIREMENT_BUBBLE_SIZE := Vector2(240.0, 60.0)
const OUTPOST_REQUIREMENT_BUBBLE_GAP := 40.0
const READABLE_OVERLAY_META := "_readable_world_overlay"
const READABLE_BASE_POSITION_META := "_readable_world_overlay_base_position"
const READABLE_BASE_SCALE_META := "_readable_world_overlay_base_scale"
const REQUIREMENT_BUBBLE_SIGNATURE_META := "_requirement_bubble_signature"

var unit: float = 64.0

func setup(p_unit: float) -> void:
	unit = p_unit

func add_interactable_visual(area: Node, interact_type: String, label_text: String, color: Color, size_units: Vector2 = Vector2.ZERO) -> Vector2:
	match interact_type:
		"outpost":
			var outpost_size: Vector2 = _u(size_units if size_units != Vector2.ZERO else OUTPOST_SIZE_UNITS)
			_add_rect_visual(area, "OutpostVisual", outpost_size, color, 10)
			return outpost_size
		"container":
			var container_size: Vector2 = _u(size_units if size_units != Vector2.ZERO else CONTAINER_VISUAL_SIZE_UNITS)
			_add_rect_visual(area, "ContainerVisual", container_size, Color(0.08, 0.08, 0.08, 0.92), 12)
			_add_rect_visual(area, "ContainerLifetimeFill", container_size, color, 14)
			_add_rect_outline(area, "ContainerOutline", container_size, Color(0.02, 0.02, 0.02), 10.0, 25)
			_add_center_marker_label(area, _container_marker_text(label_text), container_size, Color(1.0, 1.0, 1.0), 42)
			_add_container_lifetime_label(area, container_size)
			return container_size
		"material":
			var material_size: Vector2 = _u(MATERIAL_VISUAL_SIZE_UNITS)
			_add_diamond_visual(area, "BuildMaterialVisual", material_size, color, 12)
			_add_diamond_outline(area, "BuildMaterialOutline", material_size, Color(0.02, 0.09, 0.04), 12.0, 13)
			_add_center_marker_label(area, _material_marker_text(label_text), material_size, Color(1.0, 1.0, 1.0), 38)
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
			_apply_requirement_bubble_spacing(child, scale_value)
		if child.has_meta(READABLE_OVERLAY_META):
			_apply_readable_node_scale(child, scale_value)
		apply_readable_overlay_scale(child, scale_value)

func refresh_outpost_requirement_bubbles(outpost: Node, get_inventory_count: Callable) -> void:
	if outpost == null or not is_instance_valid(outpost):
		return
	var bubble_root := outpost.get_node_or_null("OutpostRequirementBubbles") as Node2D
	var requirements: Dictionary = outpost.get("payload").get("requirements", {})
	if bubble_root == null:
		bubble_root = Node2D.new()
		bubble_root.name = "OutpostRequirementBubbles"
		bubble_root.z_index = 40
		outpost.add_child(bubble_root)
	if bool(outpost.get("payload").get("repaired", false)) or requirements.is_empty():
		bubble_root.visible = false
		return
	bubble_root.visible = true
	var delivered: Dictionary = outpost.get("payload").get("delivered_materials", {})
	_rebuild_requirement_bubbles(bubble_root, requirements, delivered, get_inventory_count)

func refresh_container_lifetime_visual(container: Node) -> void:
	var payload: Dictionary = container.get("payload")
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 45.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var visual := container.get_node_or_null("ContainerVisual") as ColorRect
	var fill := container.get_node_or_null("ContainerLifetimeFill") as ColorRect
	if visual != null and fill != null:
		fill.color = payload.get("container_color", Color(0.23, 0.55, 1.0))
		fill.position = visual.position
		fill.size = Vector2(visual.size.x * ratio, visual.size.y)
	var lifetime_label := container.get_node_or_null("ContainerLifetimeLabel") as Label
	if lifetime_label != null:
		lifetime_label.text = "剩 %ds" % int(ceil(lifetime))

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
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.z_index = 30
	parent.add_child(label)
	_mark_readable_overlay(label)
	return label

func _add_container_lifetime_label(parent: Node, size: Vector2) -> Label:
	var badge_size := Vector2(maxf(size.x * 0.72, 132.0), 42.0)
	var badge := ColorRect.new()
	badge.name = "ContainerLifetimeLabelBackground"
	badge.color = Color(0.0, 0.0, 0.0, 0.82)
	badge.position = Vector2(-badge_size.x * 0.5, size.y * 0.5 + 8.0)
	badge.size = badge_size
	badge.z_index = 31
	parent.add_child(badge)
	_mark_readable_overlay(badge)

	var label := Label.new()
	label.name = "ContainerLifetimeLabel"
	label.text = "剩 45s"
	label.position = badge.position
	label.size = badge_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 32
	parent.add_child(label)
	_mark_readable_overlay(label)
	return label

func _mark_readable_overlay(node: Node) -> void:
	node.set_meta(READABLE_OVERLAY_META, true)
	node.set_meta(READABLE_BASE_POSITION_META, node.get("position"))
	node.set_meta(READABLE_BASE_SCALE_META, node.get("scale"))
	if node is Control:
		node.pivot_offset = node.size * 0.5

func _apply_readable_node_scale(node: Node, scale_value: float) -> void:
	var base_scale: Vector2 = node.get_meta(READABLE_BASE_SCALE_META, node.get("scale"))
	node.set("scale", base_scale * scale_value)

func _rebuild_requirement_bubbles(root: Node2D, requirements: Dictionary, delivered: Dictionary, get_inventory_count: Callable) -> void:
	var entries: Array[Dictionary] = []
	var signature_parts: Array[String] = []
	var keys := requirements.keys()
	keys.sort()
	for key in keys:
		var item_id := String(key)
		var data: Dictionary = requirements[item_id]
		var need := int(data.get("amount", 0))
		var submitted := int(delivered.get(item_id, 0))
		var carried := int(get_inventory_count.call(item_id)) if get_inventory_count.is_valid() else 0
		var text := "%s %d/%d  包:%d" % [String(data.get("display_name", item_id)), submitted, need, carried]
		entries.append({"item_id": item_id, "text": text, "ready": submitted >= need, "can_submit": carried > 0})
		signature_parts.append("%s:%s:%s:%s" % [item_id, submitted, carried, need])
	var signature := "|".join(signature_parts)
	if String(root.get_meta(REQUIREMENT_BUBBLE_SIGNATURE_META, "")) == signature:
		return
	root.set_meta(REQUIREMENT_BUBBLE_SIGNATURE_META, signature)
	for child in root.get_children():
		child.free()
	var count: int = entries.size()
	var gap: float = OUTPOST_REQUIREMENT_BUBBLE_GAP
	var total_width: float = count * OUTPOST_REQUIREMENT_BUBBLE_SIZE.x + max(0, count - 1) * gap
	for index in range(count):
		var bubble_pos: Vector2 = Vector2(-total_width * 0.5 + index * (OUTPOST_REQUIREMENT_BUBBLE_SIZE.x + gap), -OUTPOST_SIZE_UNITS.y * unit * 0.5 - 78.0)
		_add_requirement_bubble(root, String(entries[index].text), bubble_pos, bool(entries[index].ready), bool(entries[index].can_submit))

func _add_requirement_bubble(parent: Node, text: String, pos: Vector2, is_ready: bool, can_submit: bool) -> void:
	var background := ColorRect.new()
	background.name = "RequirementBubbleBackground"
	background.position = pos
	background.size = OUTPOST_REQUIREMENT_BUBBLE_SIZE
	background.color = Color(0.02, 0.20, 0.10, 0.88) if is_ready else (Color(0.26, 0.18, 0.04, 0.90) if can_submit else Color(0.02, 0.025, 0.03, 0.88))
	background.z_index = 41
	parent.add_child(background)
	_mark_readable_overlay(background)

	var label := Label.new()
	label.name = "RequirementBubbleLabel"
	label.text = text
	label.position = pos
	label.size = OUTPOST_REQUIREMENT_BUBBLE_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.72) if is_ready else (Color(1.0, 0.86, 0.42) if can_submit else Color(1.0, 1.0, 1.0)))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 42
	parent.add_child(label)
	_mark_readable_overlay(label)

func _apply_requirement_bubble_spacing(root: Node2D, scale_value: float) -> void:
	for child in root.get_children():
		if not child.has_meta(READABLE_BASE_POSITION_META):
			continue
		var base_position: Vector2 = child.get_meta(READABLE_BASE_POSITION_META, child.get("position"))
		child.set("position", Vector2(base_position.x * scale_value, base_position.y))

func _container_marker_text(label_text: String) -> String:
	if label_text.length() <= 2:
		return label_text
	return label_text.substr(0, 2)

func _material_marker_text(label_text: String) -> String:
	if label_text.length() <= 4:
		return label_text
	return label_text.substr(0, 4)

func _u(value: Variant) -> Variant:
	if value is Vector2:
		return value * unit
	return float(value) * unit

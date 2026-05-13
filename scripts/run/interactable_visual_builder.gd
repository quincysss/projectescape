class_name InteractableVisualBuilder
extends RefCounted

const OUTPOST_SIZE_UNITS := Vector2(10.0, 8.0)
const RESOURCE_SIZE_UNITS := Vector2(1.0, 1.0)
const CONTAINER_VISUAL_SIZE_UNITS := Vector2(3.4, 3.4)
const MATERIAL_VISUAL_SIZE_UNITS := Vector2(4.0, 4.0)
const CONTAINER_NAME_FONT_SIZE := 72
const CONTAINER_TIME_FONT_SIZE := 54
const CONTAINER_NAME_COLOR := Color("#FFC547")
const CONTAINER_TIME_COLOR := Color("#FEDC54")
const CONTAINER_BAR_BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.92)
const OUTPOST_REQUIREMENT_BORDER_COLOR := Color("#D1B850")
const OUTPOST_REQUIREMENT_PANEL_SIZE := Vector2(560.0, 300.0)
const OUTPOST_REQUIREMENT_TITLE_SIZE := Vector2(560.0, 64.0)
const OUTPOST_REQUIREMENT_TITLE_FONT_SIZE := 58
const OUTPOST_REQUIREMENT_ROW_TOP := 112.0
const OUTPOST_REQUIREMENT_ROW_HEIGHT := 62.0
const OUTPOST_REQUIREMENT_ITEM_GAP := 18.0
const OUTPOST_REQUIREMENT_ITEM_FONT_SIZE := 44
const OUTPOST_REQUIREMENT_ROW_BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.72)
const READABLE_OVERLAY_META := "_readable_world_overlay"
const READABLE_BASE_POSITION_META := "_readable_world_overlay_base_position"
const READABLE_BASE_SCALE_META := "_readable_world_overlay_base_scale"
const READABLE_POSITION_SCALES_META := "_readable_world_overlay_position_scales"
const REQUIREMENT_BUBBLE_SIGNATURE_META := "_requirement_bubble_signature"

var unit: float = 64.0

func setup(p_unit: float) -> void:
	unit = p_unit

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
	if outpost == null or not is_instance_valid(outpost):
		return
	var bubble_root := outpost.get_node_or_null("OutpostRequirementBubbles") as Node2D
	var requirements: Dictionary = outpost.get("payload").get("requirements", {})
	if bubble_root == null:
		bubble_root = Node2D.new()
		bubble_root.name = "OutpostRequirementBubbles"
		bubble_root.z_index = 40
		outpost.add_child(bubble_root)
		_mark_readable_overlay(bubble_root)
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
	var bar_background := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeBarBackground") as ColorRect
	var fill := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeFill") as ColorRect
	if bar_background != null and fill != null:
		fill.color = payload.get("container_color", Color(0.23, 0.55, 1.0))
		fill.position = bar_background.position
		fill.size = Vector2(bar_background.size.x * ratio, bar_background.size.y)
	var lifetime_label := container.get_node_or_null("ContainerReadableRoot/ContainerLifetimeLabel") as Label
	if lifetime_label != null:
		lifetime_label.text = "%ds" % int(ceil(lifetime))

func refresh_material_lifetime_visual(material: Node) -> void:
	var payload: Dictionary = material.get("payload")
	var lifetime_max: float = maxf(0.01, float(payload.get("lifetime_max", 120.0)))
	var lifetime: float = clampf(float(payload.get("lifetime", lifetime_max)), 0.0, lifetime_max)
	var ratio: float = lifetime / lifetime_max
	var visual := material.get_node_or_null("BuildMaterialVisual") as Polygon2D
	var fill := material.get_node_or_null("BuildMaterialLifetimeFill") as Polygon2D
	if visual == null or fill == null:
		return
	fill.polygon = _diamond_fill_polygon(_diamond_size_from_polygon(visual.polygon), ratio)

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
	var bar_size := Vector2(panel_width, 44.0)
	var icon_half_y := icon_size.y * 0.5
	var name_y := -icon_half_y - 158.0
	var bar_y := -icon_half_y - 66.0

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

	var bar_background := ColorRect.new()
	bar_background.name = "ContainerLifetimeBarBackground"
	bar_background.color = CONTAINER_BAR_BACKGROUND_COLOR
	bar_background.position = Vector2(-bar_size.x * 0.5, bar_y)
	bar_background.size = bar_size
	bar_background.z_index = 31
	root.add_child(bar_background)

	var fill := ColorRect.new()
	fill.name = "ContainerLifetimeFill"
	fill.color = color
	fill.position = bar_background.position
	fill.size = bar_size
	fill.z_index = 32
	root.add_child(fill)

	var time_label := Label.new()
	time_label.name = "ContainerLifetimeLabel"
	time_label.text = "0s"
	time_label.position = bar_background.position
	time_label.size = bar_size
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", CONTAINER_TIME_FONT_SIZE)
	time_label.add_theme_color_override("font_color", CONTAINER_TIME_COLOR)
	_apply_text_shadow(time_label, 2)
	time_label.z_index = 35
	root.add_child(time_label)

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
			return 0.62

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
	_apply_text_shadow(label, 2)
	label.z_index = 30
	parent.add_child(label)
	_mark_readable_overlay(label)
	return label

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

func _rebuild_requirement_bubbles(root: Node2D, requirements: Dictionary, delivered: Dictionary, get_inventory_count: Callable) -> void:
	var entries: Array[Dictionary] = []
	var signature_parts: Array[String] = []
	var keys := requirements.keys()
	keys.sort()
	var all_ready := true
	var any_can_submit := false
	for key in keys:
		var item_id := String(key)
		var data: Dictionary = requirements[item_id]
		var need := int(data.get("amount", 0))
		var submitted := int(delivered.get(item_id, 0))
		var carried := int(get_inventory_count.call(item_id)) if get_inventory_count.is_valid() else 0
		var covered := mini(need, submitted + carried)
		var text := "%s %d/%d" % [String(data.get("display_name", item_id)), covered, need]
		entries.append({"item_id": item_id, "text": text, "ready": covered >= need, "can_submit": carried > 0})
		all_ready = all_ready and covered >= need
		any_can_submit = any_can_submit or carried > 0
		signature_parts.append("%s:%s:%s:%s:%s" % [item_id, submitted, carried, covered, need])
	var signature := "|".join(signature_parts)
	if String(root.get_meta(REQUIREMENT_BUBBLE_SIGNATURE_META, "")) == signature:
		return
	root.set_meta(REQUIREMENT_BUBBLE_SIGNATURE_META, signature)
	for child in root.get_children():
		child.free()
	var count: int = entries.size()
	var panel_pos: Vector2 = -OUTPOST_REQUIREMENT_PANEL_SIZE * 0.5
	_add_requirement_panel_background(root, panel_pos, all_ready, any_can_submit)
	_add_requirement_panel_border(root, panel_pos)
	_add_requirement_title(root, panel_pos)
	for index in range(count):
		var item_pos := panel_pos + Vector2(0.0, OUTPOST_REQUIREMENT_ROW_TOP + index * (OUTPOST_REQUIREMENT_ROW_HEIGHT + OUTPOST_REQUIREMENT_ITEM_GAP))
		_add_requirement_material_label(root, String(entries[index].item_id), String(entries[index].text), item_pos, Vector2(OUTPOST_REQUIREMENT_PANEL_SIZE.x, OUTPOST_REQUIREMENT_ROW_HEIGHT), bool(entries[index].ready), bool(entries[index].can_submit))

func _add_requirement_panel_background(parent: Node, pos: Vector2, is_ready: bool, can_submit: bool) -> void:
	var background := ColorRect.new()
	background.name = "RequirementBubbleBackground"
	background.position = pos
	background.size = OUTPOST_REQUIREMENT_PANEL_SIZE
	background.color = Color(0.0, 0.0, 0.0, 0.66)
	background.z_index = 41
	parent.add_child(background)
	_mark_readable_overlay(background)

func _add_requirement_panel_border(parent: Node, pos: Vector2) -> void:
	var border := Line2D.new()
	border.name = "RequirementBubbleBorder"
	border.default_color = OUTPOST_REQUIREMENT_BORDER_COLOR
	border.width = 5.0
	border.closed = true
	border.points = PackedVector2Array([
		pos,
		pos + Vector2(OUTPOST_REQUIREMENT_PANEL_SIZE.x, 0.0),
		pos + OUTPOST_REQUIREMENT_PANEL_SIZE,
		pos + Vector2(0.0, OUTPOST_REQUIREMENT_PANEL_SIZE.y),
	])
	border.z_index = 41
	parent.add_child(border)
	_mark_readable_overlay(border)

func _add_requirement_title(parent: Node, panel_pos: Vector2) -> void:
	_add_requirement_text_backing(parent, "RequirementBubbleTitleBackground", panel_pos, OUTPOST_REQUIREMENT_TITLE_SIZE)
	var label := Label.new()
	label.name = "RequirementBubbleTitle"
	label.text = "前哨站"
	label.position = panel_pos
	label.size = OUTPOST_REQUIREMENT_TITLE_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", OUTPOST_REQUIREMENT_TITLE_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	_apply_text_shadow(label, 2)
	label.z_index = 42
	parent.add_child(label)
	_mark_readable_overlay(label)

func _add_requirement_material_label(parent: Node, item_id: String, text: String, pos: Vector2, size: Vector2, is_ready: bool, can_submit: bool) -> void:
	_add_requirement_text_backing(parent, "RequirementBubbleMaterialBackground_%s" % item_id, pos, size)
	var label := Label.new()
	label.name = "RequirementBubbleMaterial_%s" % item_id
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", OUTPOST_REQUIREMENT_ITEM_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.72) if is_ready else (Color(1.0, 0.86, 0.42) if can_submit else Color(1.0, 1.0, 1.0)))
	_apply_text_shadow(label, 2)
	label.z_index = 42
	parent.add_child(label)
	_mark_readable_overlay(label)

func _add_requirement_text_backing(parent: Node, node_name: String, pos: Vector2, size: Vector2) -> void:
	var backing := ColorRect.new()
	backing.name = node_name
	backing.position = pos + Vector2(18.0, 4.0)
	backing.size = size - Vector2(36.0, 8.0)
	backing.color = OUTPOST_REQUIREMENT_ROW_BACKGROUND_COLOR
	backing.z_index = 41
	parent.add_child(backing)
	_mark_readable_overlay(backing)

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

class_name OutpostRequirementBubbleView
extends RefCounted

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

func refresh(outpost: Node, get_inventory_count: Callable) -> void:
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

func _apply_text_shadow(label: Label, offset: int) -> void:
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", offset)
	label.add_theme_constant_override("shadow_offset_y", offset)

func _mark_readable_overlay(node: Node, position_scales: bool = false) -> void:
	node.set_meta(READABLE_OVERLAY_META, true)
	node.set_meta(READABLE_BASE_POSITION_META, node.get("position"))
	node.set_meta(READABLE_BASE_SCALE_META, node.get("scale"))
	node.set_meta(READABLE_POSITION_SCALES_META, position_scales)
	if node is Control:
		node.pivot_offset = node.size * 0.5

extends SceneTree

const BROKEN_PATH := "res://assets/map/outposts/outpost_broken_01.png"
const REPAIRED_PATH := "res://assets/map/outposts/outpost_repaired_01.png"
const PLAYER_ALWAYS_IN_FRONT_Z_INDEX := -1

func _initialize() -> void:
	var ok := await _verify_outpost_visual_resources()
	print("Outpost visual resources verified." if ok else "Outpost visual resources failed.")
	quit(0 if ok else 1)

func _verify_outpost_visual_resources() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn.")
		return false

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var player := root.get_node_or_null("WorldRoot/YSortRoot/Player") as CanvasItem
	var outposts: Array[Node] = []
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == "outpost":
			outposts.append(interactable)
	if outposts.size() != 2:
		printerr("Expected two selected outpost interactables, got %s." % outposts.size())
		root.queue_free()
		await process_frame
		return false

	var candidate_ids := _candidate_ids(root)
	for candidate_id in candidate_ids:
		var candidate_anchor := _find_anchor(candidate_id)
		if candidate_anchor == null:
			printerr("Missing always-on outpost visual anchor for candidate %s." % candidate_id)
			root.queue_free()
			await process_frame
			return false
		if candidate_anchor.get_parent() != root.get_node_or_null("WorldRoot/YSortRoot"):
			printerr("Outpost visual anchor %s must be a direct YSortRoot child." % candidate_anchor.name)
			root.queue_free()
			await process_frame
			return false
		if not candidate_anchor.visible:
			printerr("Outpost visual anchor %s should stay visible even when not selected." % candidate_anchor.name)
			root.queue_free()
			await process_frame
			return false
		if not bool(candidate_anchor.get_meta("outpost_uses_normal_ysort", false)):
			printerr("Outpost visual anchor %s must opt into normal YSort." % candidate_anchor.name)
			root.queue_free()
			await process_frame
			return false
		if candidate_anchor is CanvasItem and (candidate_anchor as CanvasItem).z_index != PLAYER_ALWAYS_IN_FRONT_Z_INDEX:
			printerr("Outpost visual anchor %s must keep z_index %d so the player draws in front like the home building." % [candidate_anchor.name, PLAYER_ALWAYS_IN_FRONT_Z_INDEX])
			root.queue_free()
			await process_frame
			return false
		var candidate_sprite := candidate_anchor.get_node_or_null("ArtSprite") as Sprite2D
		if candidate_sprite == null or _texture_path(candidate_sprite) != BROKEN_PATH:
			printerr("Candidate %s should render the broken outpost texture by default." % candidate_id)
			root.queue_free()
			await process_frame
			return false

	for outpost in outposts:
		if outpost.get_node_or_null("OutpostVisual") != null:
			printerr("Outpost logic node %s should not own the art sprite." % outpost.name)
			root.queue_free()
			await process_frame
			return false
		var anchor := _find_anchor(outpost.interact_id)
		if anchor == null:
			printerr("Missing YSort outpost visual anchor for %s." % outpost.name)
			root.queue_free()
			await process_frame
			return false
		if anchor.get_parent() != root.get_node_or_null("WorldRoot/YSortRoot"):
			printerr("Outpost visual anchor %s must be a direct YSortRoot child." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if not bool(anchor.get_meta("player_always_in_front", false)):
			printerr("Outpost visual anchor %s must keep player_always_in_front." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if bool(anchor.get_meta("occludes_player", true)):
			printerr("Outpost visual anchor %s must not occlude player." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if anchor is CanvasItem and player != null and (anchor as CanvasItem).z_index >= player.z_index:
			printerr("Outpost visual anchor %s must draw below the player z-index." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if not anchor.visible:
			printerr("Selected outpost visual anchor %s should be visible." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if String(outpost.payload.get("visual_anchor_path", NodePath(""))) != String(anchor.get_path()):
			printerr("Outpost %s should store its visual anchor path." % outpost.name)
			root.queue_free()
			await process_frame
			return false
		var sprite := anchor.get_node_or_null("ArtSprite") as Sprite2D
		if sprite == null:
			printerr("Missing ArtSprite on %s." % anchor.name)
			root.queue_free()
			await process_frame
			return false
		if _texture_path(sprite) != BROKEN_PATH:
			printerr("Expected broken outpost texture on %s, got %s." % [anchor.name, _texture_path(sprite)])
			root.queue_free()
			await process_frame
			return false
		if sprite.scale.x <= 0.0 or sprite.scale.y <= 0.0:
			printerr("Expected positive outpost art scale on %s." % anchor.name)
			root.queue_free()
			await process_frame
			return false

	var target := outposts[0]
	var target_anchor := _find_anchor(target.interact_id)
	var target_sprite := target_anchor.get_node_or_null("ArtSprite") as Sprite2D
	var scale_before_repair := target_sprite.scale
	target.payload.repaired = true
	target.payload.repair_state = "ACTIVE"
	root._update_outpost_requirement_bubbles()
	await process_frame

	var repaired_sprite := target_anchor.get_node_or_null("ArtSprite") as Sprite2D
	if repaired_sprite == null or _texture_path(repaired_sprite) != REPAIRED_PATH:
		printerr("Expected repaired outpost texture on %s, got %s." % [target.name, _texture_path(repaired_sprite)])
		root.queue_free()
		await process_frame
		return false
	if repaired_sprite.scale != scale_before_repair:
		printerr("Repaired outpost visual should keep the broken art scale.")
		root.queue_free()
		await process_frame
		return false

	root.queue_free()
	await process_frame
	return true

func _find_anchor(candidate_id: String) -> Node:
	for node in get_nodes_in_group("outpost_visual_anchors"):
		if node.has_method("get_candidate_id") and String(node.get_candidate_id()) == candidate_id:
			return node
	return null

func _candidate_ids(root: Node) -> Array[String]:
	var ids: Array[String] = []
	var candidates_root := root.get_node_or_null("WorldRoot/OutpostRoot/OutpostCandidates")
	if candidates_root == null:
		return ids
	for child in candidates_root.find_children("*", "Marker2D", true, false):
		if child.has_method("get_candidate_id"):
			ids.append(String(child.get_candidate_id()))
	return ids

func _texture_path(sprite: Sprite2D) -> String:
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path

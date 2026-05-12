extends SceneTree

const BROKEN_PATH := "res://assets/map/outposts/outpost_broken_01.png"
const REPAIRED_PATH := "res://assets/map/outposts/outpost_repaired_01.png"

func _initialize() -> void:
	var ok := await _verify_partial_outpost_repair()
	print("Outpost partial repair verified." if ok else "Outpost partial repair failed.")
	quit(0 if ok else 1)

func _verify_partial_outpost_repair() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_research()
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.setup(64, 100.0)
	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	var outpost = _find_selected_first_outpost(root)
	if outpost == null:
		printerr("Expected first outpost interactable.")
		return false

	if not root.run_director.debug_add_item(_item("scrap_metal", "废金属", 1, 2.0)):
		printerr("Expected first partial material to enter backpack.")
		return false
	root._try_repair_outpost(outpost)
	await process_frame

	if bool(outpost.payload.get("repaired", false)):
		printerr("Expected outpost to stay inactive after partial material submission.")
		return false
	if String(outpost.payload.get("repair_state", "")) != "PARTIAL_DELIVERED":
		printerr("Expected PARTIAL_DELIVERED state after partial material submission.")
		return false
	var delivered: Dictionary = outpost.payload.get("delivered_materials", {})
	if int(delivered.get("scrap_metal", 0)) != 1:
		printerr("Expected one scrap_metal to be delivered.")
		return false
	var progress: float = root.outpost_repair_controller.repair_progress(outpost)
	if progress <= 0.0 or progress >= 1.0:
		printerr("Expected partial repair progress, got %s." % progress)
		return false
	if root.run_director.outpost_storage_controller.has_storage(outpost.interact_id):
		printerr("Expected partial outpost to not create storage.")
		return false
	if _outpost_visual_texture_path(root, outpost) != BROKEN_PATH:
		printerr("Expected partial outpost to keep broken visual, got %s." % _outpost_visual_texture_path(root, outpost))
		return false

	if not root.run_director.debug_add_item(_item("scrap_metal", "废金属", 1, 2.0)):
		printerr("Expected second scrap_metal to enter backpack.")
		return false
	if not root.run_director.debug_add_item(_item("old_battery", "旧电池", 1, 4.0)):
		printerr("Expected old_battery to enter backpack.")
		return false
	root._try_repair_outpost(outpost)
	await process_frame

	if not bool(outpost.payload.get("repaired", false)):
		printerr("Expected outpost to activate after cumulative requirements are met.")
		return false
	if root.run_director.context.outpost_states.get(outpost.interact_id, "") != "repaired":
		printerr("Expected run context to record repaired outpost.")
		return false
	if root.run_director.ensure_outpost_storage(outpost.interact_id) != null:
		printerr("Expected repaired outpost storage to stay locked without outpost storage research.")
		return false
	if root.run_director.get_outpost_storage_capacity(outpost.interact_id) != 0:
		printerr("Expected unresearched outpost storage capacity to be 0.")
		return false
	if _outpost_visual_texture_path(root, outpost) != REPAIRED_PATH:
		printerr("Expected repaired outpost visual, got %s." % _outpost_visual_texture_path(root, outpost))
		return false

	root.queue_free()
	await process_frame
	return true

func _find_selected_first_outpost(root):
	var outpost_id: String = root.run_director.context.selected_first_outpost_id
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == "outpost" and interactable.interact_id == outpost_id:
			return interactable
	return null

func _outpost_visual_texture_path(root: Node, outpost: Node) -> String:
	var anchor := _find_anchor(outpost.interact_id)
	if anchor == null:
		return ""
	if anchor.get_parent() != root.get_node_or_null("WorldRoot/YSortRoot"):
		return ""
	var sprite := anchor.get_node_or_null("ArtSprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return ""
	return sprite.texture.resource_path

func _find_anchor(candidate_id: String) -> Node:
	for node in get_nodes_in_group("outpost_visual_anchors"):
		if node.has_method("get_candidate_id") and String(node.get_candidate_id()) == candidate_id:
			return node
	return null

func _item(item_id: String, display_name: String, amount: int, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
	}

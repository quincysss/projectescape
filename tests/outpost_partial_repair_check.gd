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
	if not _verify_random_requirements(root):
		return false

	if not root.run_director.debug_add_item(_normal_material("scrap_metal", "废金属", 1, 0.1)):
		printerr("Expected container material to enter backpack.")
		return false
	root._try_repair_outpost(outpost)
	await process_frame
	if String(outpost.payload.get("repair_state", "")) != "UNREPAIRED":
		printerr("Expected normal container material to be ignored by outpost repair.")
		return false
	var delivered_before: Dictionary = outpost.payload.get("delivered_materials", {})
	var delivered_total := 0
	for value in delivered_before.values():
		delivered_total += int(value)
	if delivered_total != 0:
		printerr("Expected no delivered materials after submitting ordinary scrap.")
		return false

	var requirements: Dictionary = outpost.payload.get("requirements", {})
	var first_item_id := String(requirements.keys()[0])
	var first_data: Dictionary = requirements[first_item_id]
	if not root.run_director.debug_add_item(_outpost_material(first_item_id, first_data, 1)):
		printerr("Expected first partial outpost material to enter backpack.")
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
	if int(delivered.get(first_item_id, 0)) != 1:
		printerr("Expected one %s to be delivered." % first_item_id)
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

	_fill_remaining_requirements(root, requirements, delivered)
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

func _verify_random_requirements(root) -> bool:
	var ok := true
	var checked_outposts := 0
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.interact_type != "outpost":
			continue
		checked_outposts += 1
		var requirements: Dictionary = interactable.payload.get("requirements", {})
		if requirements.size() != 2:
			printerr("Expected outpost %s to require exactly two repair materials, got %s." % [interactable.interact_id, requirements.size()])
			ok = false
		for item_id in requirements.keys():
			var material_id := String(item_id)
			var data: Dictionary = requirements[item_id]
			if not root.run_director.data_registry.repair_materials_by_id.has(material_id):
				printerr("Expected %s to be selected from repairmaterial.tab." % material_id)
				ok = false
			if int(data.get("amount", 0)) != 1:
				printerr("Expected %s requirement amount to be 1." % material_id)
				ok = false
			if data.has("quality"):
				printerr("Repair requirement data must not include quality: %s" % material_id)
				ok = false
	if checked_outposts != 2:
		printerr("Expected two selected outposts, got %s." % checked_outposts)
		ok = false
	return ok

func _fill_remaining_requirements(root, requirements: Dictionary, delivered: Dictionary) -> void:
	for item_id in requirements.keys():
		var data: Dictionary = requirements[item_id]
		var need := int(data.get("amount", 0)) - int(delivered.get(String(item_id), 0))
		for _index in range(maxi(0, need)):
			root.run_director.debug_add_item(_outpost_material(String(item_id), data, 1))

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

func _normal_material(item_id: String, display_name: String, amount: int, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
		"source_container_type": "container_cardboard",
	}

func _outpost_material(item_id: String, data: Dictionary, amount: int) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": String(data.get("display_name", item_id)),
		"amount": amount,
		"weight_per_unit": float(data.get("weight", 0.1)),
		"stack_limit": 1,
		"repair_material_id": item_id,
		"source": "repair_material_spawn",
	}

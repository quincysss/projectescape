extends SceneTree

func _initialize() -> void:
	var ok := await _verify_outpost_requirement_bubble_uses_carried_materials()
	print("Outpost requirement bubble progress verified." if ok else "Outpost requirement bubble progress failed.")
	quit(0 if ok else 1)

func _verify_outpost_requirement_bubble_uses_carried_materials() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var outpost = _find_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected a spawned outpost.")
		return false
	var requirements: Dictionary = outpost.payload.get("requirements", {})
	if requirements.is_empty():
		printerr("Expected outpost requirements.")
		return false
	var item_id := String(requirements.keys()[0])
	var data: Dictionary = requirements[item_id]
	var need := int(data.get("amount", 1))
	for _i in range(need):
		root.run_director.debug_add_item({
			"item_id": item_id,
			"display_name": String(data.get("display_name", item_id)),
			"amount": 1,
			"weight_per_unit": float(data.get("weight", 1.0)),
			"stack_limit": 99,
			"item_type": "outpost_material",
			"quality": "C",
		})
	root._update_outpost_requirement_bubbles()
	await process_frame

	var label := _find_requirement_label(outpost, item_id)
	if label == null:
		printerr("Expected requirement label for %s." % item_id)
		return false
	if not label.text.contains("%d/%d" % [need, need]):
		printerr("Expected carried material to update bubble progress to %d/%d, got: %s" % [need, need, label.text])
		return false

	root.queue_free()
	await process_frame
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

func _find_requirement_label(outpost, item_id: String) -> Label:
	var bubbles: Node = outpost.get_node_or_null("OutpostRequirementBubbles")
	if bubbles == null:
		return null
	for child in bubbles.get_children():
		if child is Label and String(child.name) == "RequirementBubbleMaterial_%s" % item_id:
			return child
	return null

extends SceneTree

func _initialize() -> void:
	var ok := await _verify_material_spawn_points()
	print("Material spawn point uniqueness verified." if ok else "Material spawn point uniqueness failed.")
	quit(0 if ok else 1)

func _verify_material_spawn_points() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := _check_no_duplicate_material_positions(root)
	root._spawn_requirement_materials()
	ok = _check_no_duplicate_material_positions(root) and ok

	root.queue_free()
	await process_frame
	return ok

func _check_no_duplicate_material_positions(root: Node) -> bool:
	var seen := {}
	for interactable in root.interactables:
		if not is_instance_valid(interactable) or interactable.get("interact_type") != "material":
			continue
		var key := "%d,%d" % [int(round(interactable.global_position.x)), int(round(interactable.global_position.y))]
		if seen.has(key):
			printerr("Duplicate material spawn position: %s" % key)
			return false
		seen[key] = true
	return true

extends SceneTree

func _initialize() -> void:
	var ok := await _verify_editor_layout_exposure()
	quit(0 if ok else 1)

func _verify_editor_layout_exposure() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame

	var ok := true
	ok = _check_map_points(root, "ContainerSpawnPoints") and ok
	ok = _check_map_points(root, "MaterialSpawnPoints") and ok
	ok = _check_map_points(root, "MonsterSpawnPoints") and ok
	ok = _check_outpost_candidates(root) and ok

	root.queue_free()
	await process_frame
	if ok:
		print("Editor layout exposure verified.")
	return ok

func _check_map_points(root: Node, section_name: String) -> bool:
	var section := root.get_node_or_null("WorldRoot/MapLayout/Points/%s" % section_name)
	if section == null:
		printerr("Missing point section: %s" % section_name)
		return false
	var ok := true
	for point in section.get_children():
		if not point.has_method("get_point_id"):
			continue
		if not point.has_method("get_preview_size_units"):
			printerr("%s is missing editor preview size interface." % point.name)
			ok = false
			continue
		var preview_size: Vector2 = point.get_preview_size_units()
		if preview_size.x <= 0.0 or preview_size.y <= 0.0:
			printerr("%s has invalid editor preview size: %s" % [point.name, preview_size])
			ok = false
	return ok

func _check_outpost_candidates(root: Node) -> bool:
	var section := root.get_node_or_null("WorldRoot/OutpostRoot/OutpostCandidates")
	if section == null:
		printerr("Missing outpost candidates root.")
		return false
	var ok := true
	for point in section.find_children("*", "Node2D", true, false):
		if not point.has_method("get_candidate_id"):
			continue
		if not point.has_method("get_footprint_units"):
			printerr("%s is missing editable footprint interface." % point.name)
			ok = false
			continue
		var footprint: Vector2 = point.get_footprint_units()
		if footprint.x <= 0.0 or footprint.y <= 0.0:
			printerr("%s has invalid footprint: %s" % [point.name, footprint])
			ok = false
	return ok

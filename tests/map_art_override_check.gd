extends SceneTree

func _initialize() -> void:
	var ok := await _verify_map_art_override()
	quit(0 if ok else 1)

func _verify_map_art_override() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		return false
	var root: Node = scene.instantiate()
	var scene_defaults_ok := _check_scene_art_defaults(root)
	var block: Node = root.get_node_or_null("WorldRoot/MapLayout/BlockSolid/Block_Ref_01_14x44")
	if block == null:
		printerr("Missing editable block layout node.")
		root.free()
		return false
	var texture: Texture2D = load("res://assets/map/blocks/fill/block_fill_clean_02.png")
	block.prefer_child_art = false
	block.art_mode = "stretch"
	block.art_texture = texture
	block.art_tint = Color(0.8, 0.9, 1.0, 1.0)

	get_root().add_child(root)
	await process_frame
	await process_frame

	var art_root: Node = root.get_node_or_null("WorldRoot/MapVisual/BlockVisual/Block_Ref_01_14x44_Art")
	var ok := scene_defaults_ok
	if art_root == null:
		printerr("Missing generated art root for edited block.")
		ok = false
	elif art_root.get_node_or_null("CustomFill") == null:
		printerr("Block art override did not create CustomFill.")
		ok = false

	root.queue_free()
	await process_frame
	if ok:
		print("Map art override verified.")
	return ok

func _check_scene_art_defaults(root: Node) -> bool:
	var ok := true
	var street_root: Node = root.get_node_or_null("WorldRoot/MapLayout/StreetWalkable")
	if street_root == null:
		printerr("Missing StreetWalkable root.")
		return false
	for street in street_root.get_children():
		if not street.has_method("get_rect_id"):
			continue
		if street.art_mode == "auto" or street.art_texture == null:
			printerr("Street %s should expose art_mode and art_texture in the scene." % street.name)
			ok = false
	var block_root: Node = root.get_node_or_null("WorldRoot/MapLayout/BlockSolid")
	if block_root == null:
		printerr("Missing BlockSolid root.")
		return false
	for block in block_root.get_children():
		if not block.has_method("get_rect_id"):
			continue
		if block.art_mode != "auto":
			printerr("Block %s should use auto art mode by default." % block.name)
			ok = false
		if block.get_node_or_null("ArtRoot/FoundationSprite") == null:
			printerr("Block %s should expose editable child art at ArtRoot/FoundationSprite." % block.name)
			ok = false
	return ok

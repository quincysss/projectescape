extends SceneTree

const HOME_NODE_PATH := "WorldRoot/YSortRoot/Block_Ref_07_25x34_Building_Home"
const PLAYER_NODE_PATH := "WorldRoot/YSortRoot/Player"
const HOME_TEXTURE_PATH := "res://assets/map/safe/safe_house_active_01.png"

func _initialize() -> void:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.tscn")
		quit(1)
		return

	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var ok := true
	var home := root.get_node_or_null(HOME_NODE_PATH) as Node2D
	var player := root.get_node_or_null(PLAYER_NODE_PATH) as Node2D
	if home == null:
		printerr("Missing configured home building node.")
		ok = false
	if player == null:
		printerr("Missing player node under YSortRoot.")
		ok = false

	if home != null:
		if String(home.get_meta("building_id", "")) != "safe_house_active_01":
			printerr("Home building must identify safe_house_active_01.")
			ok = false
		if String(home.get_meta("building_type", "")) != "home":
			printerr("Home building must use building_type home.")
			ok = false
		if not bool(home.get_meta("player_always_in_front", false)):
			printerr("Home building must enable player_always_in_front.")
			ok = false
		if bool(home.get_meta("occludes_player", true)):
			printerr("Home building must not occlude the player.")
			ok = false
		if player != null and home.z_index >= player.z_index:
			printerr("Home building must draw below the player z-index.")
			ok = false

		var sprite := home.get_node_or_null("ArtSprite") as Sprite2D
		if sprite == null:
			printerr("Home building must contain ArtSprite.")
			ok = false
		elif sprite.texture == null or sprite.texture.resource_path != HOME_TEXTURE_PATH:
			printerr("Home building ArtSprite must use %s." % HOME_TEXTURE_PATH)
			ok = false

	root.queue_free()
	await process_frame

	if ok:
		print("Home building player layering verified.")
	quit(0 if ok else 1)

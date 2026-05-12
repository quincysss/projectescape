extends SceneTree

const SCENE_PATH := "res://scenes/entities/monsters/BlackTideBoundaryEssence.tscn"
const FRAME_PATH_PATTERN := "res://assets/sprites/monsters/black_tide_boundary_essence/idle/frames/black_tide_boundary_essence_idle_8f_01_frame_%02d.png"

func _initialize() -> void:
	var ok := await _verify_black_tide_boundary_essence_asset()
	print("Black tide boundary essence asset verified." if ok else "Black tide boundary essence asset failed.")
	quit(0 if ok else 1)

func _verify_black_tide_boundary_essence_asset() -> bool:
	for index in range(1, 9):
		var texture := load(FRAME_PATH_PATTERN % index)
		if not (texture is Texture2D):
			printerr("Missing black tide boundary essence frame: %s" % (FRAME_PATH_PATTERN % index))
			return false

	var packed_scene := load(SCENE_PATH)
	if packed_scene == null:
		printerr("Failed to load %s." % SCENE_PATH)
		return false
	var monster = packed_scene.instantiate()
	get_root().add_child(monster)
	await process_frame
	await process_frame

	var ok := true
	if not (monster is CharacterBody2D):
		printerr("Expected BlackTideBoundaryEssence root to be CharacterBody2D.")
		ok = false
	if not monster.is_in_group("monster_visual_assets"):
		printerr("Expected BlackTideBoundaryEssence to join monster_visual_assets group.")
		ok = false
	var body_sprite := monster.get_node_or_null("BodySprite") as AnimatedSprite2D
	if body_sprite == null:
		printerr("Expected BodySprite node.")
		ok = false
	elif body_sprite.sprite_frames == null or not body_sprite.sprite_frames.has_animation("idle"):
		printerr("Expected BodySprite idle animation.")
		ok = false
	elif body_sprite.sprite_frames.get_frame_count("idle") != 8:
		printerr("Expected 8 idle frames.")
		ok = false
	if monster.get_node_or_null("EyeFocus") == null:
		printerr("Expected EyeFocus marker.")
		ok = false
	if monster.get_node_or_null("CollisionShape2D") == null:
		printerr("Expected placeholder collision shape.")
		ok = false

	monster.queue_free()
	await process_frame
	return ok

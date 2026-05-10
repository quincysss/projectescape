extends SceneTree

func _initialize() -> void:
	var ok := await _verify_basic_player_scene()
	quit(0 if ok else 1)

func _verify_basic_player_scene() -> bool:
	var scene := load("res://scenes/entities/player/BasicPlayer.tscn")
	if scene == null:
		printerr("Failed to load BasicPlayer.tscn")
		return false
	var player = scene.instantiate()
	get_root().add_child(player)
	await process_frame

	var ok := true
	if not (player is CharacterBody2D):
		printerr("Expected BasicPlayer root to be CharacterBody2D.")
		ok = false
	if not player.is_in_group("player"):
		printerr("Expected BasicPlayer to join player group.")
		ok = false
	if player.get_node_or_null("CollisionShape2D") == null:
		printerr("Expected BasicPlayer body collision shape.")
		ok = false
	var body_sprite := player.get_node_or_null("BodySprite") as AnimatedSprite2D
	if body_sprite == null:
		printerr("Expected BasicPlayer BodySprite.")
		ok = false
	elif body_sprite.sprite_frames == null or not body_sprite.sprite_frames.has_animation("idle_down"):
		printerr("Expected BodySprite to be initialized by PlayerController.")
		ok = false
	for node_path in [
		"CameraMount",
		"InteractionAnchor",
		"CombatRoot",
		"CombatRoot/CarrySocket",
		"CombatRoot/AttackPivot",
		"CombatRoot/AttackPivot/WeaponSprite",
		"CombatRoot/AttackPivot/SlashVFX",
		"CombatRoot/AttackPivot/AttackHitbox",
		"AnimationPlayer",
		"CombatController",
	]:
		if player.get_node_or_null(node_path) == null:
			printerr("Expected BasicPlayer node: %s" % node_path)
			ok = false
	var attack_hitbox := player.get_node_or_null("CombatRoot/AttackPivot/AttackHitbox") as Area2D
	if attack_hitbox != null and attack_hitbox.monitoring:
		printerr("Expected AttackHitbox to start inactive.")
		ok = false
	var attack_shape := player.get_node_or_null("CombatRoot/AttackPivot/AttackHitbox/CollisionShape2D") as CollisionShape2D
	if attack_shape != null and not attack_shape.disabled:
		printerr("Expected AttackHitbox shape to start disabled.")
		ok = false

	player.queue_free()
	await process_frame
	if ok:
		print("BasicPlayer scene structure verified.")
	return ok

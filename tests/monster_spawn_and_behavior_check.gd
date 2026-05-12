extends SceneTree

const RUN_SCENE := preload("res://scenes/run/RunScene.tscn")

func _initialize() -> void:
	var ok := await _verify_monster_spawn_and_behavior()
	print("Monster spawn and behavior verified." if ok else "Monster spawn and behavior failed.")
	quit(0 if ok else 1)

func _verify_monster_spawn_and_behavior() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	var original_profile: Dictionary = game_state.load_profile() if game_state.has_profile() else {}
	game_state.reset_day(3)

	var run_root = RUN_SCENE.instantiate()
	root.add_child(run_root)
	await process_frame
	await process_frame

	if run_root.run_director.context == null:
		return _fail_with_restore("Run context missing.", game_state, original_profile, run_root)
	if not run_root.run_director.context.monster_event_active:
		return _fail_with_restore("Day 3 run should activate monster event.", game_state, original_profile, run_root)
	if run_root.monster_spawn_controller == null:
		return _fail_with_restore("MonsterSpawnController missing.", game_state, original_profile, run_root)
	if run_root.monster_spawn_controller.active_count() != 4:
		return _fail_with_restore("Expected 4 active monsters, got %s." % run_root.monster_spawn_controller.active_count(), game_state, original_profile, run_root)
	if run_root.run_director.context.monster_spawn_point_ids.size() != 4:
		return _fail_with_restore("Expected 4 context monster spawn point ids.", game_state, original_profile, run_root)

	var monsters := get_nodes_in_group("run_monsters")
	if monsters.size() != 4:
		return _fail_with_restore("Expected 4 run_monsters group members, got %s." % monsters.size(), game_state, original_profile, run_root)
	for monster in monsters:
		if monster.get_parent() != run_root.y_sort_root:
			return _fail_with_restore("Monster should be placed directly under YSortRoot.", game_state, original_profile, run_root)
		if monster.vision_cone == null:
			return _fail_with_restore("Monster missing vision cone.", game_state, original_profile, run_root)
		if monster.has_method("get_patrol_point_count") and monster.get_patrol_point_count() <= 0:
			return _fail_with_restore("Monster should receive editable patrol path points.", game_state, original_profile, run_root)
		if monster.has_method("get_vision_origin_global") and monster.vision_cone.global_position.distance_to(monster.get_vision_origin_global()) > 0.5:
			return _fail_with_restore("Monster vision cone should be anchored at EyeFocus.", game_state, original_profile, run_root)
		if not _verify_monster_visual_flip_stability(monster):
			return _fail_with_restore("Monster visual facing should not flip the Visual root or desync EyeFocus.", game_state, original_profile, run_root)

	var first_monster = monsters[0]
	run_root.run_director.stability_component.stop()
	var stability_before := float(run_root.run_director.stability_component.current_stability)
	first_monster.debug_force_hit_player()
	await process_frame
	var stability_after := float(run_root.run_director.stability_component.current_stability)
	if not is_equal_approx(stability_after, stability_before - 20.0):
		return _fail_with_restore("Monster hit should reduce stability by 20, got %.1f -> %.1f." % [stability_before, stability_after], game_state, original_profile, run_root)
	if run_root.run_director.context.monster_hit_count != 1:
		return _fail_with_restore("Expected monster_hit_count to be 1.", game_state, original_profile, run_root)

	run_root.queue_free()
	await process_frame
	_restore_profile(game_state, original_profile)
	return true

func _fail_with_restore(message: String, game_state: Node, original_profile: Dictionary, run_root = null) -> bool:
	printerr(message)
	if run_root != null and is_instance_valid(run_root):
		run_root.queue_free()
	_restore_profile(game_state, original_profile)
	return false

func _restore_profile(game_state: Node, original_profile: Dictionary) -> void:
	game_state.reset_local_data_debug_only()
	if original_profile.is_empty():
		return
	game_state.profile = original_profile.duplicate(true)
	game_state._apply_profile_to_runtime(game_state.profile)
	game_state.save_profile()

func _verify_monster_visual_flip_stability(monster: Node) -> bool:
	var visual := monster.get_node_or_null("Visual") as Node2D
	if visual == null:
		printerr("Monster missing Visual node.")
		return false
	var sprite := visual.get_node_or_null("BodySprite") as AnimatedSprite2D
	var eye_focus := visual.get_node_or_null("EyeFocus") as Node2D
	if sprite == null or eye_focus == null:
		printerr("Monster visual missing BodySprite or EyeFocus.")
		return false

	var root_scale_x := visual.scale.x
	monster.face_direction = Vector2.LEFT
	monster.call("_refresh_vision_cone")
	if visual.scale.x != root_scale_x or visual.scale.x < 0.0:
		printerr("Visual root scale should stay stable when facing left.")
		return false
	if not sprite.flip_h or eye_focus.position.x >= 0.0:
		printerr("BodySprite should flip left and EyeFocus should mirror left.")
		return false
	if monster.vision_cone.global_position.distance_to(monster.get_vision_origin_global()) > 0.5:
		printerr("Vision cone should stay anchored to mirrored EyeFocus.")
		return false

	monster.face_direction = Vector2.RIGHT
	monster.call("_refresh_vision_cone")
	if visual.scale.x != root_scale_x or visual.scale.x < 0.0:
		printerr("Visual root scale should stay stable when facing right.")
		return false
	if sprite.flip_h or eye_focus.position.x <= 0.0:
		printerr("BodySprite should face right and EyeFocus should mirror right.")
		return false
	return monster.vision_cone.global_position.distance_to(monster.get_vision_origin_global()) <= 0.5

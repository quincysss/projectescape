extends SceneTree

const RUN_SCENE := preload("res://scenes/run/RunScene.tscn")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")
const MONSTER_DEFS_PATH := "res://setting/monster_defs.tab"
const MONSTER_ID := "black_tide_boundary_essence"
const EXPECTED_HIT_RESPAWN_DELAY_SECONDS := 30.0

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
	var expected_definition := _load_expected_monster_definition()
	if expected_definition.is_empty():
		return _fail_with_restore("Expected monster definition data for behavior check.", game_state, original_profile, run_root)

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
		if not _verify_monster_threat_tuning(monster, expected_definition):
			return _fail_with_restore("Monster should use enlarged threat tuning from monster_defs.tab.", game_state, original_profile, run_root)
		if not _verify_monster_visual_flip_stability(monster):
			return _fail_with_restore("Monster visual facing should not flip the Visual root or desync EyeFocus.", game_state, original_profile, run_root)
		if not _verify_centerline_warning_facing_stability(monster, run_root.player):
			return _fail_with_restore("Monster warning facing should not flicker when player is near the centerline.", game_state, original_profile, run_root)

	var first_monster = monsters[0]
	var first_spawn_point_id := String(first_monster.spawn_point_id)
	var original_respawn_delay := float(run_root.monster_spawn_controller.respawn_delay_seconds)
	if not is_equal_approx(original_respawn_delay, EXPECTED_HIT_RESPAWN_DELAY_SECONDS):
		return _fail_with_restore("Expected monster hit respawn delay to default to %.1f seconds, got %.1f." % [EXPECTED_HIT_RESPAWN_DELAY_SECONDS, original_respawn_delay], game_state, original_profile, run_root)
	run_root.monster_spawn_controller.respawn_delay_seconds = 0.05
	run_root.run_director.stability_component.stop()
	var stability_before := float(run_root.run_director.stability_component.current_stability)
	first_monster.debug_force_hit_player()
	await process_frame
	var stability_after := float(run_root.run_director.stability_component.current_stability)
	if not is_equal_approx(stability_after, stability_before - 20.0):
		return _fail_with_restore("Monster hit should reduce stability by 20, got %.1f -> %.1f." % [stability_before, stability_after], game_state, original_profile, run_root)
	if run_root.run_director.context.monster_hit_count != 1:
		return _fail_with_restore("Expected monster_hit_count to be 1.", game_state, original_profile, run_root)
	if run_root.monster_spawn_controller.active_count() != 3:
		return _fail_with_restore("Monster should not respawn immediately after hit.", game_state, original_profile, run_root)
	await create_timer(0.12).timeout
	if run_root.monster_spawn_controller.active_count() != 4:
		return _fail_with_restore("Monster should respawn once after the hit delay.", game_state, original_profile, run_root)
	if _count_monsters_from_spawn(run_root.monster_spawn_controller.get_active_monsters(), first_spawn_point_id) != 1:
		return _fail_with_restore("Respawned monster should use the same spawn point as the removed monster.", game_state, original_profile, run_root)
	if run_root.run_director.context.active_monster_ids.size() != 4:
		return _fail_with_restore("Context should track the respawned active monster id.", game_state, original_profile, run_root)

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

func _verify_monster_threat_tuning(monster: Node, definition: Dictionary) -> bool:
	var expected_patrol_speed := float(definition.get("patrol_speed_px", 0.0))
	var expected_charge_speed := float(definition.get("charge_speed_px", 0.0))
	var expected_vision_radius := float(definition.get("vision_radius_px", 0.0))
	var expected_vision_angle := float(definition.get("vision_angle_degrees", 0.0))
	var expected_warning_seconds := float(definition.get("warning_seconds", 0.0))
	var expected_hit_radius := float(definition.get("hit_radius_px", 0.0))
	var expected_patrol_reach_distance := float(definition.get("patrol_target_reach_distance_px", 0.0))
	if absf(float(monster.patrol_speed) - expected_patrol_speed) > 0.01:
		printerr("Expected patrol_speed %.1f, got %.1f." % [expected_patrol_speed, monster.patrol_speed])
		return false
	if absf(float(monster.charge_speed) - expected_charge_speed) > 0.01:
		printerr("Expected charge_speed %.1f, got %.1f." % [expected_charge_speed, monster.charge_speed])
		return false
	if absf(float(monster.vision_radius) - expected_vision_radius) > 0.01:
		printerr("Expected vision_radius %.1f, got %.1f." % [expected_vision_radius, monster.vision_radius])
		return false
	if absf(float(monster.vision_angle_degrees) - expected_vision_angle) > 0.01:
		printerr("Expected vision_angle_degrees %.1f, got %.1f." % [expected_vision_angle, monster.vision_angle_degrees])
		return false
	if absf(float(monster.warning_seconds) - expected_warning_seconds) > 0.01:
		printerr("Expected warning_seconds %.1f, got %.1f." % [expected_warning_seconds, monster.warning_seconds])
		return false
	if absf(float(monster.hit_radius) - expected_hit_radius) > 0.01:
		printerr("Expected hit_radius %.1f, got %.1f." % [expected_hit_radius, monster.hit_radius])
		return false
	if absf(float(monster.patrol_target_reach_distance) - expected_patrol_reach_distance) > 0.01:
		printerr("Expected patrol_target_reach_distance %.1f, got %.1f." % [expected_patrol_reach_distance, monster.patrol_target_reach_distance])
		return false
	if monster.vision_cone.radius != expected_vision_radius or monster.vision_cone.angle_degrees != expected_vision_angle:
		printerr("Expected vision cone to mirror enlarged monster vision tuning.")
		return false
	return true

func _load_expected_monster_definition() -> Dictionary:
	var loader = TabDataLoaderScript.new()
	for row in loader.load_tab(MONSTER_DEFS_PATH):
		if String(row.get("monster_id", "")) == MONSTER_ID:
			return row
	if not loader.last_error.is_empty():
		printerr(loader.last_error)
	return {}

func _count_monsters_from_spawn(monsters: Array[Node], spawn_point_id: String) -> int:
	var count := 0
	for monster in monsters:
		if monster != null and is_instance_valid(monster) and String(monster.get("spawn_point_id")) == spawn_point_id:
			count += 1
	return count

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

func _verify_centerline_warning_facing_stability(monster: Node, player: Node2D) -> bool:
	if player == null:
		printerr("Expected player for centerline facing stability check.")
		return false
	var visual := monster.get_node_or_null("Visual") as Node2D
	var sprite := visual.get_node_or_null("BodySprite") as AnimatedSprite2D if visual != null else null
	var eye_focus := visual.get_node_or_null("EyeFocus") as Node2D if visual != null else null
	if visual == null or sprite == null or eye_focus == null:
		printerr("Monster visual missing nodes for centerline facing stability check.")
		return false

	player.global_position = monster.global_position + Vector2(0.0, -360.0)
	monster.face_direction = Vector2.UP
	monster.call("_refresh_vision_cone")
	var initial_flip := sprite.flip_h
	var initial_eye_sign := signf(eye_focus.position.x)
	for _index in range(12):
		monster.call("_face_player")
		monster.call("_refresh_vision_cone")
		if sprite.flip_h != initial_flip:
			printerr("Monster BodySprite flickered while tracking a centerline player.")
			return false
		if signf(eye_focus.position.x) != initial_eye_sign:
			printerr("Monster EyeFocus mirrored back and forth while tracking a centerline player.")
			return false
		if monster.vision_cone.global_position.distance_to(monster.get_vision_origin_global()) > 0.5:
			printerr("Vision cone desynced while tracking a centerline player.")
			return false
		if monster.has_method("get_attention_origin_global"):
			var to_player: Vector2 = player.global_position - monster.get_attention_origin_global()
			if to_player.length_squared() > 0.001 and absf(monster.face_direction.angle_to(to_player.normalized())) > 0.01:
				printerr("Monster should face player from the stable attention origin.")
				return false
	return true

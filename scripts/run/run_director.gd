class_name RunDirector
extends Node

signal run_context_created(context)
signal run_initialized(context)
signal initialization_failed(reason: String)
signal debug_log(message: String)
signal stability_changed(current: float, max_value: float, stage: int)
signal inventory_changed(items: Array)
signal weight_changed(current_weight: float, max_weight: float, stage: int)
signal home_storage_changed(items: Array)
signal outpost_storage_changed(outpost_id: String, items: Array)
signal scene_events_resolved(context)
signal monster_hit_player(monster_id: String, damage: float)

const RunConfigScript := preload("res://scripts/run/run_config.gd")
const RunInitializerScript := preload("res://scripts/run/run_initializer.gd")
const RunStateMachineScript := preload("res://scripts/run/run_state_machine.gd")
const WeightComponentScript := preload("res://scripts/inventory/weight_component.gd")
const ItemTransferServiceScript := preload("res://scripts/inventory/item_transfer_service.gd")
const OutpostStorageControllerScript := preload("res://scripts/outpost/outpost_storage_controller.gd")
const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const SSRunChanceDirectorScript := preload("res://scripts/run/ss_run_chance_director.gd")
const SSLootDirectorScript := preload("res://scripts/run/ss_loot_director.gd")
const SceneRandomEventDirectorScript := preload("res://scripts/events/scene_random_event_director.gd")

@export var spawn_position: Vector2 = Vector2.ZERO
@export var first_outpost_candidates: Array = ["OutpostA_01", "OutpostA_02", "OutpostA_03"]
@export var second_outpost_candidates: Array = ["OutpostB_01", "OutpostB_02", "OutpostB_03", "OutpostB_04"]
@export var prefer_scene_points: bool = true
@export var stability_component_path: NodePath
@export var vision_controller_path: NodePath
@export var camera_controller_path: NodePath
@export var inventory_component_path: NodePath
@export var weight_component_path: NodePath
@export var home_storage_component_path: NodePath

var config = RunConfigScript.new()
var context
var initializer = RunInitializerScript.new()
var state_machine
var stability_component
var vision_controller
var camera_controller
var inventory_component
var weight_component
var home_storage_component
var item_transfer_service = ItemTransferServiceScript.new()
var outpost_storage_controller = OutpostStorageControllerScript.new()
var data_registry = GameDataRegistryScript.new()
var ss_run_chance_director = SSRunChanceDirectorScript.new()
var ss_loot_director = SSLootDirectorScript.new()
var scene_random_event_director = SceneRandomEventDirectorScript.new()
var _data_registry_loaded := false

func _ready() -> void:
	state_machine = get_node_or_null("RunStateMachine")
	if state_machine == null:
		state_machine = RunStateMachineScript.new()
		state_machine.name = "RunStateMachine"
		add_child(state_machine)

	state_machine.phase_changed.connect(_on_phase_changed)
	state_machine.extraction_unlocked.connect(_on_extraction_unlocked)
	state_machine.run_finished.connect(_on_run_finished)
	state_machine.invalid_transition_requested.connect(_on_invalid_transition_requested)
	initializer.initialization_failed.connect(_on_initialization_failed)
	outpost_storage_controller.outpost_storage_changed.connect(_on_outpost_storage_changed)
	_resolve_runtime_components()
	_connect_safe_zones()
	call_deferred("_connect_safe_zones")

func start_new_run() -> bool:
	_log("Starting new run.")
	state_machine.start_new_run()
	_apply_meta_research_to_config()
	var scene_spawn_position := _resolve_spawn_position()
	var first_candidates := _resolve_outpost_candidates("first")
	var second_candidates := _resolve_outpost_candidates("second")
	context = initializer.create_context(
		config,
		scene_spawn_position,
		first_candidates,
		second_candidates
	)
	if context == null:
		return false

	_initialize_ss_run()
	_initialize_scene_random_events()
	run_context_created.emit(context)
	run_initialized.emit(context)
	_log("Run initialized: %s" % context.to_debug_dictionary())
	_initialize_runtime_components()
	return state_machine.complete_initialization()

func on_home_exited() -> void:
	_log("Event: home_exited")
	state_machine.on_home_exited()
	if context:
		context.camera_mode = "transition_to_follow"
		context.darkness_enabled = true
		context.active_safe_zone_id = ""
		context.active_safe_zone_type = ""
	_apply_danger_zone_runtime()

func on_camera_transition_finished() -> void:
	_log("Event: camera_transition_finished")
	state_machine.on_camera_transition_finished()
	if context:
		context.camera_mode = "follow"
		context.darkness_enabled = true

func on_safe_zone_entered(zone_id: String = "home") -> void:
	_log("Event: safe_zone_entered %s" % zone_id)
	state_machine.on_safe_zone_entered(zone_id)
	if context:
		context.darkness_enabled = false
		context.camera_mode = "observe" if zone_id == "home" else "safe_zone"
		context.active_safe_zone_id = zone_id
		context.active_safe_zone_type = "home" if zone_id == "home" else "outpost"
	_apply_safe_zone_runtime(zone_id)

func on_safe_zone_exited(zone_id: String = "home") -> void:
	_log("Event: safe_zone_exited %s" % zone_id)
	state_machine.on_safe_zone_exited(zone_id)
	if context:
		context.darkness_enabled = true
		context.camera_mode = "transition_to_follow"
		context.active_safe_zone_id = ""
		context.active_safe_zone_type = ""
	_apply_danger_zone_runtime()

func on_outpost_repair_started(outpost_id: String) -> void:
	_log("Event: outpost_repair_started %s" % outpost_id)
	state_machine.on_outpost_repair_started(outpost_id)

func on_outpost_repaired(outpost_id: String) -> void:
	_log("Event: outpost_repaired %s" % outpost_id)
	if context:
		context.outpost_states[outpost_id] = "repaired"
		context.repaired_outpost_count += 1
	state_machine.on_outpost_repaired(outpost_id)

func on_extraction_started() -> void:
	_log("Event: extraction_started")
	state_machine.on_extraction_started()

func on_extraction_completed() -> void:
	_log("Event: extraction_completed")
	state_machine.on_extraction_completed()

func on_extraction_interrupted() -> void:
	_log("Event: extraction_interrupted")
	state_machine.on_extraction_interrupted()

func on_player_dead(reason: String = "stability_depleted") -> void:
	_log("Event: player_dead %s" % reason)
	if stability_component and stability_component.has_method("stop"):
		stability_component.stop()
	state_machine.on_player_dead(reason)

func on_run_timeout(reason: String = "time_expired") -> void:
	_log("Event: run_timeout %s" % reason)
	if context:
		context.is_time_expired = true
		context.remaining_seconds = 0.0
	if stability_component and stability_component.has_method("stop"):
		stability_component.stop()
	state_machine.on_run_timeout(reason)

func get_debug_snapshot() -> Dictionary:
	var snapshot := {
		"state_machine": state_machine.get_state_snapshot() if state_machine else {},
		"context": context.to_debug_dictionary() if context else {},
		"ss_loot": ss_loot_director.get_debug_snapshot() if ss_loot_director != null else {},
	}
	return snapshot

func get_ss_loot_director():
	return ss_loot_director

func apply_monster_stability_damage(damage: float, monster_id: String = "") -> void:
	var safe_damage := maxf(0.0, damage)
	if safe_damage <= 0.0:
		return
	if stability_component != null and stability_component.has_method("add_stability"):
		stability_component.add_stability(-safe_damage)
	if context != null:
		context.monster_hit_count += 1
		context.active_monster_ids.erase(monster_id)
	monster_hit_player.emit(monster_id, safe_damage)
	_log("Monster hit player: %s damage=%.1f" % [monster_id, safe_damage])

func debug_add_item(item: Dictionary) -> bool:
	if inventory_component == null:
		_log("InventoryComponent missing; cannot add item.")
		return false
	return inventory_component.add_item(item)

func debug_deposit_first_inventory_item() -> bool:
	return deposit_inventory_item_to_home(0)

func debug_drop_first_inventory_item() -> bool:
	return bool(discard_inventory_item_at(0).get("accepted", false))

func discard_inventory_item_at(slot_index: int) -> Dictionary:
	if inventory_component == null:
		return {"accepted": false, "reason": "missing_inventory", "item": {}}
	var removed: Dictionary = inventory_component.remove_item_at(slot_index)
	if removed.is_empty():
		_log("No inventory item to discard.")
		return {"accepted": false, "reason": "invalid_item", "item": {}}
	_log("Discarded %s x%s." % [removed.item_id, removed.amount])
	return {
		"accepted": true,
		"reason": "discarded",
		"discarded_count": int(removed.get("amount", 1)),
		"removed_stack": true,
		"item": removed,
	}

func deposit_inventory_item_to_home(slot_index: int, amount: int = -1) -> bool:
	if inventory_component == null or home_storage_component == null:
		_log("Inventory or HomeStorage missing; cannot deposit.")
		return false
	if context and context.active_safe_zone_id != "home":
		_log("Cannot deposit outside home.")
		return false
	var stored: bool = home_storage_component.store_from_inventory(inventory_component, slot_index, amount)
	if not stored:
		_log("Deposit failed.")
	return stored

func deposit_inventory_item_to_home_by_selection(slot_index: int, target_storage_slot: int = -1) -> Dictionary:
	if context and context.active_safe_zone_id != "home":
		return {"accepted": false, "reason": "not_home", "item": {}}
	var result: Dictionary = item_transfer_service.transfer_inventory_to_storage(inventory_component, slot_index, home_storage_component, target_storage_slot)
	if not result.accepted:
		_log("Selected deposit failed: %s" % result.reason)
	return result

func withdraw_home_storage_item_to_inventory(slot_index: int) -> Dictionary:
	if context and context.active_safe_zone_id != "home":
		return {"accepted": false, "reason": "not_home", "item": {}}
	var result: Dictionary = item_transfer_service.transfer_storage_to_inventory(home_storage_component, slot_index, inventory_component)
	if not result.accepted:
		_log("Selected withdraw failed: %s" % result.reason)
	return result

func ensure_outpost_storage(outpost_id: String):
	if context == null or not _is_repaired_outpost_id(outpost_id):
		return null
	var capacity := get_outpost_storage_capacity(outpost_id)
	if capacity <= 0:
		return null
	return outpost_storage_controller.ensure_storage(outpost_id, capacity)

func get_outpost_storage_capacity(outpost_id: String) -> int:
	if context != null and outpost_id == context.selected_first_outpost_id:
		return config.first_outpost_storage_slots
	if context != null and outpost_id == context.selected_second_outpost_id:
		return config.second_outpost_storage_slots
	return config.first_outpost_storage_slots

func get_outpost_storage_items_snapshot(outpost_id: String) -> Array:
	var storage = outpost_storage_controller.get_storage(outpost_id)
	if storage == null:
		return []
	return storage.get_items_snapshot()

func get_outpost_storage_slots_snapshot(outpost_id: String) -> Array:
	var storage = outpost_storage_controller.get_storage(outpost_id)
	if storage == null:
		return []
	return storage.get_slots_snapshot()

func get_all_outpost_storage_items_snapshot() -> Array:
	return outpost_storage_controller.get_all_items_snapshot()

func deposit_inventory_item_to_outpost(outpost_id: String, slot_index: int, target_storage_slot: int = -1) -> Dictionary:
	if context == null or context.active_safe_zone_id != outpost_id:
		return {"accepted": false, "reason": "not_outpost", "item": {}}
	if not _is_repaired_outpost_id(outpost_id):
		return {"accepted": false, "reason": "outpost_inactive", "item": {}}
	if get_outpost_storage_capacity(outpost_id) <= 0:
		return {"accepted": false, "reason": "outpost_storage_locked", "item": {}}
	var storage = ensure_outpost_storage(outpost_id)
	var result: Dictionary = item_transfer_service.transfer_inventory_to_storage(inventory_component, slot_index, storage, target_storage_slot)
	if not result.accepted:
		_log("Outpost deposit failed: %s" % result.reason)
	return result

func withdraw_outpost_storage_item_to_inventory(outpost_id: String, slot_index: int) -> Dictionary:
	if context == null or context.active_safe_zone_id != outpost_id:
		return {"accepted": false, "reason": "not_outpost", "item": {}}
	if not _is_repaired_outpost_id(outpost_id):
		return {"accepted": false, "reason": "outpost_inactive", "item": {}}
	if get_outpost_storage_capacity(outpost_id) <= 0:
		return {"accepted": false, "reason": "outpost_storage_locked", "item": {}}
	var storage = ensure_outpost_storage(outpost_id)
	var result: Dictionary = item_transfer_service.transfer_storage_to_inventory(storage, slot_index, inventory_component)
	if not result.accepted:
		_log("Outpost withdraw failed: %s" % result.reason)
	return result

func get_candidate_summary() -> Dictionary:
	return {
		"spawn_position": _resolve_spawn_position(),
		"first_outpost_candidates": _resolve_outpost_candidates("first"),
		"second_outpost_candidates": _resolve_outpost_candidates("second"),
	}

func _resolve_spawn_position() -> Vector2:
	if prefer_scene_points:
		var spawn_points := get_tree().get_nodes_in_group("player_spawn_points")
		if not spawn_points.is_empty() and spawn_points[0] is Node2D:
			return spawn_points[0].global_position
	return spawn_position

func _resolve_outpost_candidates(tier: String) -> Array:
	if not prefer_scene_points:
		return first_outpost_candidates if tier == "first" else second_outpost_candidates

	var group_name := "first_outpost_candidates" if tier == "first" else "second_outpost_candidates"
	var nodes := get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return first_outpost_candidates if tier == "first" else second_outpost_candidates

	var candidates: Array = []
	for node in nodes:
		var candidate_id := node.name
		if node.has_method("get_candidate_id"):
			candidate_id = node.get_candidate_id()
		var candidate_position := Vector2.ZERO
		if node is Node2D:
			candidate_position = node.global_position
		var footprint_units := Vector2.ZERO
		if node.has_method("get_footprint_units"):
			footprint_units = node.get_footprint_units()
		candidates.append({
			"id": candidate_id,
			"position": candidate_position,
			"footprint_units": footprint_units,
		})
	return candidates

func _resolve_runtime_components() -> void:
	stability_component = _get_optional_node(stability_component_path, "StabilityComponent")
	vision_controller = _get_optional_node(vision_controller_path, "VisionController")
	camera_controller = _get_optional_node(camera_controller_path, "RunCameraController")
	inventory_component = _get_optional_node(inventory_component_path, "InventoryComponent")
	weight_component = _get_optional_node(weight_component_path, "WeightComponent")
	home_storage_component = _get_optional_node(home_storage_component_path, "HomeStorageComponent")

	if stability_component:
		if not stability_component.stability_changed.is_connected(_on_stability_changed):
			stability_component.stability_changed.connect(_on_stability_changed)
		if not stability_component.stability_stage_changed.is_connected(_on_stability_stage_changed):
			stability_component.stability_stage_changed.connect(_on_stability_stage_changed)
		if not stability_component.stability_depleted.is_connected(_on_stability_depleted):
			stability_component.stability_depleted.connect(_on_stability_depleted)
	else:
		_log("Warning: StabilityComponent not found; stability runtime disabled.")

	if camera_controller and camera_controller.has_signal("transition_finished"):
		if not camera_controller.transition_finished.is_connected(_on_camera_controller_transition_finished):
			camera_controller.transition_finished.connect(_on_camera_controller_transition_finished)
	else:
		_log("Warning: RunCameraController not found; camera mode stored in context only.")

	if vision_controller == null:
		_log("Warning: VisionController not found; darkness state stored in context only.")

	if inventory_component:
		if weight_component and inventory_component.weight_component == null:
			inventory_component.weight_component = weight_component
		if not inventory_component.inventory_changed.is_connected(_on_inventory_changed):
			inventory_component.inventory_changed.connect(_on_inventory_changed)
		if not inventory_component.item_add_failed.is_connected(_on_item_add_failed):
			inventory_component.item_add_failed.connect(_on_item_add_failed)
	else:
		_log("Warning: InventoryComponent not found; inventory runtime disabled.")

	if weight_component:
		if not weight_component.weight_changed.is_connected(_on_weight_changed):
			weight_component.weight_changed.connect(_on_weight_changed)
	else:
		_log("Warning: WeightComponent not found; weight runtime disabled.")

	if home_storage_component:
		if not home_storage_component.home_storage_changed.is_connected(_on_home_storage_changed):
			home_storage_component.home_storage_changed.connect(_on_home_storage_changed)
		if not home_storage_component.home_storage_full.is_connected(_on_home_storage_full):
			home_storage_component.home_storage_full.connect(_on_home_storage_full)
	else:
		_log("Warning: HomeStorageComponent not found; home storage runtime disabled.")

func _get_optional_node(path: NodePath, fallback_name: String):
	if not path.is_empty():
		return get_node_or_null(path)
	if get_tree():
		return _find_node_by_name(get_tree().root, fallback_name)
	return null

func _find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null

func _apply_meta_research_to_config() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if game_state.has_method("get_inventory_slot_count"):
		config.inventory_slots = int(game_state.get_inventory_slot_count(config.inventory_slots))
	if game_state.has_method("get_home_storage_slot_count"):
		config.home_storage_slots = int(game_state.get_home_storage_slot_count(config.home_storage_slots))
	if game_state.has_method("get_outpost_storage_slot_count"):
		config.first_outpost_storage_slots = int(game_state.get_outpost_storage_slot_count(config.first_outpost_storage_slots))
		config.second_outpost_storage_slots = int(game_state.get_outpost_storage_slot_count(config.second_outpost_storage_slots))
	if game_state.has_method("get_player_max_stability"):
		config.max_stability = float(game_state.get_player_max_stability(config.max_stability))

func _initialize_ss_run() -> void:
	if context == null:
		return
	_ensure_data_registry_loaded()
	ss_run_chance_director.setup(data_registry)
	var game_state := get_node_or_null("/root/GameState")
	var day := 1
	if game_state != null and game_state.has_method("get_current_day"):
		day = int(game_state.get_current_day())
	var ss_rng := RandomNumberGenerator.new()
	ss_rng.seed = maxi(1, int(abs(context.seed)) + day * 100003 + 99173)
	var roll_result: Dictionary = ss_run_chance_director.roll_for_run(game_state, ss_rng)
	ss_loot_director.setup(data_registry, context)
	ss_loot_director.begin_run(roll_result)
	_log("SS roll: active=%s chance=%.3f roll=%.3f budget=%d/%d tier=%d next=%d miss_next=%d" % [
		bool(roll_result.get("active", false)),
		float(roll_result.get("chance", 0.0)),
		float(roll_result.get("roll_value", 0.0)),
		int(roll_result.get("budget_used", 0)),
		int(roll_result.get("budget_total", 0)),
		int(roll_result.get("chance_tier", 0)),
		int(roll_result.get("next_chance_tier", 0)),
		int(roll_result.get("next_miss_count", 0)),
	])

func _initialize_scene_random_events() -> void:
	if context == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var forced_events: Dictionary = {}
	if game_state != null and game_state.has_method("consume_forced_scene_events_for_next_run"):
		forced_events = game_state.consume_forced_scene_events_for_next_run()
	scene_random_event_director.load_config()
	var event_context = scene_random_event_director.resolve_for_run(
		game_state,
		config.run_duration_seconds,
		context.seed,
		forced_events
	)
	context.run_day_index = event_context.run_day_index
	context.run_duration_seconds = event_context.run_duration_seconds
	context.remaining_seconds = event_context.run_duration_seconds
	context.scene_events = event_context.scene_events.duplicate(true)
	context.active_time_event_id = event_context.active_time_event_id
	context.monster_event_active = event_context.monster_event_active
	context.monster_type_id = event_context.monster_type_id
	context.monster_spawn_count = event_context.monster_spawn_count
	context.monster_spawn_group = event_context.monster_spawn_group
	context.monster_spawn_point_ids = event_context.monster_spawn_point_ids.duplicate()
	context.active_monster_ids = event_context.active_monster_ids.duplicate()
	context.event_trigger_reasons = event_context.trigger_reasons.duplicate()
	config.run_duration_seconds = event_context.run_duration_seconds
	scene_events_resolved.emit(context)
	_log("Scene events: %s" % event_context.to_dictionary())

func _ensure_data_registry_loaded() -> bool:
	if _data_registry_loaded:
		return true
	_data_registry_loaded = data_registry.load_all()
	if not _data_registry_loaded:
		_log("Data registry load failed for SS rules: %s" % str(data_registry.load_errors))
	return _data_registry_loaded

func _connect_safe_zones() -> void:
	for zone in get_tree().get_nodes_in_group("safe_zones"):
		if zone.has_signal("safe_zone_entered") and not zone.safe_zone_entered.is_connected(_on_safe_zone_entered):
			zone.safe_zone_entered.connect(_on_safe_zone_entered)
		if zone.has_signal("safe_zone_exited") and not zone.safe_zone_exited.is_connected(_on_safe_zone_exited):
			zone.safe_zone_exited.connect(_on_safe_zone_exited)

func _initialize_runtime_components() -> void:
	outpost_storage_controller.clear()
	if weight_component:
		weight_component.set_weight(0.0, config.base_weight_limit)
	if inventory_component:
		inventory_component.setup(config.inventory_slots, config.base_weight_limit)
	if home_storage_component:
		home_storage_component.setup(config.home_storage_slots)
	if stability_component:
		stability_component.configure(
			config.max_stability,
			config.max_stability,
			config.stability_decay_per_second,
			config.stability_recover_per_second
		)
		stability_component.start_recover()
	if vision_controller:
		vision_controller.set_darkness_enabled(false)
		vision_controller.set_vision_stage(0)
	if camera_controller:
		camera_controller.set_overview_mode()
	_sync_inventory_context()

func _apply_safe_zone_runtime(zone_id: String) -> void:
	if stability_component:
		stability_component.start_recover()
	if vision_controller:
		vision_controller.set_darkness_enabled(false)
	if camera_controller:
		if zone_id == "home":
			camera_controller.set_overview_mode()

func _apply_danger_zone_runtime() -> void:
	if stability_component:
		stability_component.start_decay()
	if vision_controller:
		vision_controller.set_darkness_enabled(true)
	if camera_controller:
		camera_controller.set_player_follow_mode()

func _on_safe_zone_entered(zone_id: StringName, _zone_type: StringName) -> void:
	on_safe_zone_entered(str(zone_id))

func _on_safe_zone_exited(zone_id: StringName, _zone_type: StringName) -> void:
	on_safe_zone_exited(str(zone_id))

func _on_stability_changed(current: float, max_value: float, stage: int) -> void:
	if vision_controller:
		vision_controller.set_vision_from_stability(current, max_value, stage)
	if context:
		context.player_stability = current
		context.stability_stage = StabilityComponent.stage_name(stage)
		context.vision_radius = vision_controller.current_radius if vision_controller else context.vision_radius
	stability_changed.emit(current, max_value, stage)

func _on_stability_stage_changed(_old_stage: int, new_stage: int) -> void:
	if context:
		context.stability_stage = StabilityComponent.stage_name(new_stage)
		context.vision_radius = vision_controller.current_radius if vision_controller else context.vision_radius

func _on_stability_depleted() -> void:
	on_player_dead("stability_depleted")

func _on_camera_controller_transition_finished(_mode: int) -> void:
	if context and camera_controller:
		context.camera_mode = "observe" if camera_controller.current_mode == 0 else "follow"
	if state_machine.current_phase == RunStateMachineScript.RunPhase.LEAVE_HOME:
		on_camera_transition_finished()

func _on_inventory_changed(items: Array) -> void:
	if context:
		context.player_inventory = _snapshot_to_context(items)
		if inventory_component and inventory_component.has_method("get_repair_material_items_snapshot"):
			context.material_inventory = _snapshot_to_context(inventory_component.get_repair_material_items_snapshot())
		context.current_weight = inventory_component.get_current_weight() if inventory_component else context.current_weight
	inventory_changed.emit(items)
	_sync_inventory_context()

func _on_item_add_failed(item_id: StringName, reason: String) -> void:
	_log("Item add failed: %s, %s" % [item_id, reason])

func _on_weight_changed(current_weight: float, max_weight: float, stage: int) -> void:
	if context:
		context.current_weight = current_weight
		context.weight_limit = max_weight
		context.weight_stage = WeightComponentScript.stage_name(stage)
		context.weight_speed_multiplier = weight_component.speed_multiplier if weight_component else 1.0
	weight_changed.emit(current_weight, max_weight, stage)

func _on_home_storage_changed(items: Array) -> void:
	if context:
		context.home_storage = _snapshot_to_context(home_storage_component.get_slots_snapshot() if home_storage_component else items)
	home_storage_changed.emit(items)

func _on_home_storage_full() -> void:
	_log("Home storage is full.")

func _on_outpost_storage_changed(outpost_id: String, items: Array) -> void:
	if context:
		context.outpost_storage[outpost_id] = _snapshot_to_context(outpost_storage_controller.get_slots_snapshot(outpost_id))
	outpost_storage_changed.emit(outpost_id, items)

func _sync_inventory_context() -> void:
	if context == null:
		return
	if inventory_component:
		context.player_inventory = _snapshot_to_context(inventory_component.get_items_snapshot())
		if inventory_component.has_method("get_repair_material_items_snapshot"):
			context.material_inventory = _snapshot_to_context(inventory_component.get_repair_material_items_snapshot())
		context.current_weight = inventory_component.get_current_weight()
	if weight_component:
		context.weight_limit = weight_component.max_weight
		context.weight_stage = WeightComponentScript.stage_name(weight_component.current_stage)
		context.weight_speed_multiplier = weight_component.speed_multiplier
	if home_storage_component:
		context.home_storage = _snapshot_to_context(home_storage_component.get_slots_snapshot())
	context.outpost_storage = outpost_storage_controller.get_debug_snapshot()

func _is_repaired_outpost_id(outpost_id: String) -> bool:
	if context == null:
		return false
	return str(context.outpost_states.get(outpost_id, "")) == "repaired"

func _snapshot_to_context(items: Array) -> Array:
	var snapshot: Array = []
	for item in items:
		if item == null:
			snapshot.append(null)
		elif item is Dictionary:
			snapshot.append(item.duplicate(true))
	return snapshot

func _on_phase_changed(old_phase: int, new_phase: int) -> void:
	_log("Phase changed: %s -> %s" % [
		RunStateMachineScript.phase_name(old_phase),
		RunStateMachineScript.phase_name(new_phase),
	])

func _on_extraction_unlocked() -> void:
	if context:
		context.is_extraction_unlocked = true
	_log("Extraction unlocked.")

func _on_run_finished(result: int) -> void:
	_log("Run finished: %s" % RunStateMachineScript.result_name(result))

func _on_invalid_transition_requested(from_phase: int, to_phase: int, reason: String) -> void:
	_log("Invalid transition: %s -> %s, %s" % [
		RunStateMachineScript.phase_name(from_phase),
		RunStateMachineScript.phase_name(to_phase),
		reason,
	])

func _on_initialization_failed(reason: String) -> void:
	_log("Initialization failed: %s" % reason)
	initialization_failed.emit(reason)

func _log(message: String) -> void:
	print("[RunDirector] %s" % message)
	debug_log.emit(message)

class_name RunEndController
extends RefCounted

const RunResultBuilderScript := preload("res://scripts/run/run_result_builder.gd")

var run_director
var game_state
var result_builder = RunResultBuilderScript.new()
var base_scene_path: String = "res://scenes/base/BaseScene.tscn"

func setup(director, state) -> void:
	run_director = director
	game_state = state

func try_extract(tree: SceneTree) -> Dictionary:
	var validation := validate_extraction()
	if not validation.accepted:
		return validation

	run_director.on_extraction_started()
	var result := result_builder.build_extraction_result(run_director)
	_apply_result_to_game_state(result)
	run_director.on_extraction_completed()
	if tree != null:
		tree.change_scene_to_file(base_scene_path)
	return {"accepted": true, "result": result, "message": result.get("message", "")}

func validate_extraction() -> Dictionary:
	return _validate_extraction()

func handle_player_death(tree: SceneTree, reason: String = "stability_depleted") -> Dictionary:
	if run_director != null and run_director.state_machine != null:
		var state: Dictionary = run_director.state_machine.get_state_snapshot()
		if state.get("current_phase", "") != "FAILED":
			run_director.on_player_dead(reason)
	var result := result_builder.build_death_result(run_director, reason)
	_apply_result_to_game_state(result)
	if tree != null:
		tree.change_scene_to_file(base_scene_path)
	return {"accepted": true, "result": result, "message": result.get("message", "")}

func _validate_extraction() -> Dictionary:
	if run_director == null or run_director.context == null:
		return {"accepted": false, "message": "局内状态尚未准备好。"}
	if not run_director.context.is_extraction_unlocked:
		return {"accepted": false, "message": "需要先修复两座前哨站。"}
	if run_director.context.active_safe_zone_id != "home":
		return {"accepted": false, "message": "请回到家中撤离。"}
	return {"accepted": true, "message": ""}

func _apply_result_to_game_state(result: Dictionary) -> void:
	if game_state == null:
		return
	if game_state.has_method("apply_run_result"):
		game_state.apply_run_result(result)
	else:
		if game_state.has_method("add_to_warehouse"):
			game_state.add_to_warehouse(result.get("warehouse_items", []))
		game_state.last_run_result = result.get("message", "")

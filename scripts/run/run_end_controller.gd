class_name RunEndController
extends RefCounted

const RunResultBuilderScript := preload("res://scripts/run/run_result_builder.gd")

var run_director
var result_builder = RunResultBuilderScript.new()
var base_scene_path: String = "res://scenes/base/BaseScene.tscn"


func setup(director, _state) -> void:
	run_director = director


func try_extract(_tree: SceneTree) -> Dictionary:
	var validation := validate_extraction()
	if not bool(validation.get("accepted", false)):
		return validation

	if _is_run_terminal():
		return {"accepted": false, "message": "Run already finished."}
	if not _is_extraction_phase():
		run_director.on_extraction_started()
	var result := result_builder.build_extraction_result(run_director)
	run_director.on_extraction_completed()
	return {"accepted": true, "result": result, "message": result.get("message", "")}


func validate_extraction() -> Dictionary:
	return _validate_extraction()


func handle_player_death(_tree: SceneTree, reason: String = "stability_depleted") -> Dictionary:
	if run_director != null and run_director.state_machine != null:
		var state: Dictionary = run_director.state_machine.get_state_snapshot()
		if state.get("current_phase", "") in ["FAILED", "SETTLEMENT"]:
			return {"accepted": false, "message": "Run already finished."}
		run_director.on_player_dead(reason)
	var result := result_builder.build_death_result(run_director, reason)
	return {"accepted": true, "result": result, "message": result.get("message", "")}


func handle_timeout(_tree: SceneTree, reason: String = "time_expired") -> Dictionary:
	if run_director != null and run_director.state_machine != null:
		var state: Dictionary = run_director.state_machine.get_state_snapshot()
		if state.get("current_phase", "") in ["FAILED", "SETTLEMENT"]:
			return {"accepted": false, "message": "Run already finished."}
		run_director.on_run_timeout(reason)
	var result := result_builder.build_timeout_result(run_director, reason)
	return {"accepted": true, "result": result, "message": result.get("message", "")}


func _validate_extraction() -> Dictionary:
	if run_director == null or run_director.context == null:
		return {"accepted": false, "message": "局内状态尚未准备好。"}
	if not run_director.context.is_extraction_unlocked:
		return {"accepted": false, "message": "需要先修复两座前哨站。"}
	if run_director.context.active_safe_zone_id != "home":
		return {"accepted": false, "message": "请回到家中撤离。"}
	return {"accepted": true, "message": ""}


func _is_extraction_phase() -> bool:
	return _current_phase_name() == "EXTRACT"


func _is_run_terminal() -> bool:
	return _current_phase_name() in ["SETTLEMENT", "FAILED"]


func _current_phase_name() -> String:
	if run_director == null or run_director.state_machine == null:
		return ""
	return RunStateMachine.phase_name(run_director.state_machine.current_phase)

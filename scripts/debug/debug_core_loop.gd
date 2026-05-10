extends Control

@onready var run_director = $RunDirector
@onready var phase_label: Label = %PhaseLabel
@onready var context_label: Label = %ContextLabel
@onready var log_label: RichTextLabel = %LogLabel

var _log_lines: Array[String] = []

func _ready() -> void:
	run_director.debug_log.connect(_append_log)
	run_director.run_initialized.connect(_on_run_initialized)
	_append_log("DebugCoreLoop ready. Press Start New Run.")
	_refresh()

func _on_start_new_run_pressed() -> void:
	run_director.start_new_run()
	_refresh()

func _on_leave_home_pressed() -> void:
	run_director.on_home_exited()
	_refresh()

func _on_camera_done_pressed() -> void:
	run_director.on_camera_transition_finished()
	_refresh()

func _on_enter_safe_zone_pressed() -> void:
	run_director.on_safe_zone_entered("home")
	_refresh()

func _on_exit_safe_zone_pressed() -> void:
	run_director.on_safe_zone_exited("home")
	_refresh()

func _on_repair_outpost_a_pressed() -> void:
	run_director.on_outpost_repair_started("debug_outpost_a")
	run_director.on_outpost_repaired("debug_outpost_a")
	_refresh()

func _on_repair_outpost_b_pressed() -> void:
	run_director.on_outpost_repair_started("debug_outpost_b")
	run_director.on_outpost_repaired("debug_outpost_b")
	_refresh()

func _on_start_extract_pressed() -> void:
	run_director.on_extraction_started()
	_refresh()

func _on_complete_extract_pressed() -> void:
	run_director.on_extraction_completed()
	_refresh()

func _on_interrupt_extract_pressed() -> void:
	run_director.on_extraction_interrupted()
	_refresh()

func _on_kill_player_pressed() -> void:
	run_director.on_player_dead("debug_stability_depleted")
	_refresh()

func _on_stability_down_pressed() -> void:
	if run_director.stability_component:
		run_director.stability_component.add_stability(-10.0)
	_refresh()

func _on_stability_up_pressed() -> void:
	if run_director.stability_component:
		run_director.stability_component.add_stability(10.0)
	_refresh()

func _on_add_scrap_pressed() -> void:
	run_director.debug_add_item({
		"item_id": "scrap_metal",
		"display_name": "Scrap Metal",
		"amount": 1,
		"weight_per_unit": 2.0,
		"stack_limit": 1,
		"item_type": "material",
	})
	_refresh()

func _on_add_heavy_pressed() -> void:
	run_director.debug_add_item({
		"item_id": "heavy_battery",
		"display_name": "Heavy Battery",
		"amount": 1,
		"weight_per_unit": 12.0,
		"stack_limit": 1,
		"item_type": "material",
	})
	_refresh()

func _on_deposit_first_pressed() -> void:
	run_director.debug_deposit_first_inventory_item()
	_refresh()

func _on_drop_first_pressed() -> void:
	run_director.debug_drop_first_inventory_item()
	_refresh()

func _on_run_success_path_pressed() -> void:
	run_director.start_new_run()
	run_director.on_home_exited()
	run_director.on_camera_transition_finished()
	run_director.on_safe_zone_entered("outpost_debug_a")
	run_director.on_outpost_repair_started("debug_outpost_a")
	run_director.on_outpost_repaired("debug_outpost_a")
	run_director.on_safe_zone_exited("outpost_debug_a")
	run_director.on_camera_transition_finished()
	run_director.on_outpost_repair_started("debug_outpost_b")
	run_director.on_outpost_repaired("debug_outpost_b")
	run_director.on_safe_zone_entered("home")
	run_director.on_extraction_started()
	run_director.on_extraction_completed()
	_refresh()

func _on_run_death_path_pressed() -> void:
	run_director.start_new_run()
	run_director.on_home_exited()
	run_director.on_camera_transition_finished()
	run_director.on_player_dead("debug_stability_depleted")
	_refresh()

func _on_run_initialized(_context) -> void:
	_refresh()

func _refresh() -> void:
	var snapshot = run_director.get_debug_snapshot()
	var state: Dictionary = snapshot.get("state_machine", {})
	phase_label.text = "Phase: %s | Result: %s | Safe: %s | Alive: %s" % [
		state.get("current_phase", "NONE"),
		state.get("run_result", "NONE"),
		state.get("is_player_in_safe_zone", false),
		state.get("is_player_alive", false),
	]
	context_label.text = JSON.stringify({
		"candidate_summary": run_director.get_candidate_summary(),
		"context": snapshot.get("context", {}),
	}, "\t")

func _append_log(message: String) -> void:
	_log_lines.append(message)
	if _log_lines.size() > 20:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)

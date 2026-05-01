class_name RunCameraController
extends Node

signal camera_mode_changed(old_mode: int, new_mode: int)
signal transition_finished(mode: int)

enum CameraMode {
	OVERVIEW,
	PLAYER_FOLLOW,
}

@export var overview_transition_seconds: float = 0.6
@export var follow_transition_seconds: float = 0.5

var current_mode: int = CameraMode.OVERVIEW
var is_transitioning: bool = false

func set_overview_mode() -> void:
	_set_mode(CameraMode.OVERVIEW, overview_transition_seconds)

func set_player_follow_mode() -> void:
	_set_mode(CameraMode.PLAYER_FOLLOW, follow_transition_seconds)

func get_mode_name() -> String:
	return mode_name(current_mode)

func _set_mode(mode: int, _duration: float) -> void:
	if current_mode == mode and not is_transitioning:
		return
	var old_mode := current_mode
	current_mode = mode
	is_transitioning = true
	camera_mode_changed.emit(old_mode, current_mode)
	print("[RunCameraController] Camera %s -> %s." % [mode_name(old_mode), mode_name(current_mode)])
	call_deferred("_finish_transition")

func _finish_transition() -> void:
	is_transitioning = false
	transition_finished.emit(current_mode)

static func mode_name(mode: int) -> String:
	match mode:
		CameraMode.OVERVIEW:
			return "OVERVIEW"
		CameraMode.PLAYER_FOLLOW:
			return "PLAYER_FOLLOW"
		_:
			return "UNKNOWN"

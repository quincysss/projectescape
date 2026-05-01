class_name VisionController
extends Node

signal darkness_changed(enabled: bool)
signal vision_radius_changed(radius: float, stage: int)

const UNIT := 64.0

@export var safe_radius: float = 20.0 * UNIT
@export var tense_radius: float = 18.0 * UNIT
@export var danger_radius: float = 14.0 * UNIT
@export var critical_radius: float = 8.0 * UNIT

var darkness_enabled: bool = false
var current_radius: float = safe_radius
var current_stage: int = 0

func set_darkness_enabled(enabled: bool) -> void:
	if darkness_enabled == enabled:
		return
	darkness_enabled = enabled
	print("[VisionController] Darkness %s." % ("enabled" if enabled else "disabled"))
	darkness_changed.emit(darkness_enabled)

func set_vision_stage(stage: int) -> void:
	current_stage = stage
	var radius := _radius_for_stage(stage)
	if is_equal_approx(current_radius, radius):
		return
	current_radius = radius
	print("[VisionController] Vision radius set to %s for stage %s." % [current_radius, stage])
	vision_radius_changed.emit(current_radius, current_stage)

func transition_to_radius(radius: float, _duration: float = 0.0) -> void:
	current_radius = maxf(0.0, radius)
	vision_radius_changed.emit(current_radius, current_stage)

func _radius_for_stage(stage: int) -> float:
	match stage:
		0:
			return safe_radius
		1:
			return tense_radius
		2:
			return danger_radius
		3:
			return critical_radius
		_:
			return 0.0

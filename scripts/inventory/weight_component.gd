class_name WeightComponent
extends Node

signal weight_changed(current_weight: float, max_weight: float, stage: int)
signal weight_stage_changed(old_stage: int, new_stage: int)

enum WeightStage {
	LIGHT,
	HEAVY,
	OVERLOADED,
}

@export var max_weight: float = 20.0
@export var current_weight: float = 0.0
@export var light_speed_multiplier: float = 1.0
@export var heavy_speed_multiplier: float = 0.85
@export var overloaded_speed_multiplier: float = 0.6

var current_stage: int = WeightStage.LIGHT
var speed_multiplier: float = 1.0

func _ready() -> void:
	set_weight(current_weight, max_weight)

func set_weight(value: float, limit: float = -1.0) -> void:
	if limit > 0.0:
		max_weight = limit
	current_weight = maxf(0.0, value)
	_update_stage()
	weight_changed.emit(current_weight, max_weight, current_stage)

func can_accept(additional_weight: float) -> bool:
	return current_weight + maxf(0.0, additional_weight) <= max_weight

func get_weight_ratio() -> float:
	if max_weight <= 0.0:
		return 0.0
	return current_weight / max_weight

func _update_stage() -> void:
	var old_stage := current_stage
	var ratio := get_weight_ratio()
	if ratio > 1.0:
		current_stage = WeightStage.OVERLOADED
	elif ratio > 0.7:
		current_stage = WeightStage.HEAVY
	else:
		current_stage = WeightStage.LIGHT

	match current_stage:
		WeightStage.LIGHT:
			speed_multiplier = light_speed_multiplier
		WeightStage.HEAVY:
			speed_multiplier = heavy_speed_multiplier
		WeightStage.OVERLOADED:
			speed_multiplier = overloaded_speed_multiplier

	if old_stage != current_stage:
		print("[WeightComponent] Stage %s -> %s." % [stage_name(old_stage), stage_name(current_stage)])
		weight_stage_changed.emit(old_stage, current_stage)

static func stage_name(stage: int) -> String:
	match stage:
		WeightStage.LIGHT:
			return "LIGHT"
		WeightStage.HEAVY:
			return "HEAVY"
		WeightStage.OVERLOADED:
			return "OVERLOADED"
		_:
			return "UNKNOWN"

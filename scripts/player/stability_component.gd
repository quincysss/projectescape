class_name StabilityComponent
extends Node

signal stability_changed(current: float, max_value: float, stage: int)
signal stability_stage_changed(old_stage: int, new_stage: int)
signal stability_depleted()

enum StabilityStage {
	SAFE,
	TENSE,
	DANGER,
	CRITICAL,
	DEPLETED,
}

@export var max_stability: float = 100.0
@export var current_stability: float = 100.0
@export var decay_per_second: float = 1.0
@export var recover_per_second: float = 10.0

var is_decaying: bool = false
var is_recovering: bool = false
var current_stage: int = StabilityStage.SAFE
var _depleted_emitted: bool = false

func _ready() -> void:
	reset(max_stability)

func _process(delta: float) -> void:
	if delta <= 0.0 or _depleted_emitted:
		return
	if is_decaying:
		set_stability(current_stability - decay_per_second * delta)
	elif is_recovering:
		set_stability(current_stability + recover_per_second * delta)

func reset(value: float = -1.0) -> void:
	if value < 0.0:
		value = max_stability
	current_stability = clampf(value, 0.0, max_stability)
	current_stage = _stage_for_value(current_stability)
	is_decaying = false
	is_recovering = false
	_depleted_emitted = current_stability <= 0.0
	stability_changed.emit(current_stability, max_stability, current_stage)

func configure(max_value: float, current_value: float, decay_rate: float, recover_rate: float) -> void:
	max_stability = maxf(1.0, max_value)
	decay_per_second = maxf(0.0, decay_rate)
	recover_per_second = maxf(0.0, recover_rate)
	reset(current_value)

func start_decay() -> void:
	if _depleted_emitted:
		return
	is_decaying = true
	is_recovering = false
	print("[StabilityComponent] Decay started.")

func start_recover() -> void:
	if _depleted_emitted:
		return
	is_decaying = false
	is_recovering = true
	print("[StabilityComponent] Recovery started.")

func stop() -> void:
	is_decaying = false
	is_recovering = false

func set_stability(value: float) -> void:
	var old_stage := current_stage
	current_stability = clampf(value, 0.0, max_stability)
	current_stage = _stage_for_value(current_stability)
	if old_stage != current_stage:
		stability_stage_changed.emit(old_stage, current_stage)
		print("[StabilityComponent] Stage %s -> %s." % [stage_name(old_stage), stage_name(current_stage)])
	stability_changed.emit(current_stability, max_stability, current_stage)
	if current_stage == StabilityStage.DEPLETED and not _depleted_emitted:
		_depleted_emitted = true
		stop()
		stability_depleted.emit()

func add_stability(delta_value: float) -> void:
	set_stability(current_stability + delta_value)

func _stage_for_value(value: float) -> int:
	if value <= 0.0:
		return StabilityStage.DEPLETED
	if value <= 25.0:
		return StabilityStage.CRITICAL
	if value <= 50.0:
		return StabilityStage.DANGER
	if value <= 75.0:
		return StabilityStage.TENSE
	return StabilityStage.SAFE

static func stage_name(stage: int) -> String:
	match stage:
		StabilityStage.SAFE:
			return "SAFE"
		StabilityStage.TENSE:
			return "TENSE"
		StabilityStage.DANGER:
			return "DANGER"
		StabilityStage.CRITICAL:
			return "CRITICAL"
		StabilityStage.DEPLETED:
			return "DEPLETED"
		_:
			return "UNKNOWN"

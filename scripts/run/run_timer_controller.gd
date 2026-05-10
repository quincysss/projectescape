class_name RunTimerController
extends RefCounted

signal time_expired()

var context
var duration_seconds: float = 0.0
var is_running: bool = false
var _expired_emitted: bool = false

func setup(run_context, duration: float) -> void:
	context = run_context
	duration_seconds = maxf(0.0, duration)
	is_running = context != null and duration_seconds > 0.0
	_expired_emitted = false
	if context == null:
		return
	context.run_duration_seconds = duration_seconds
	context.elapsed_seconds = 0.0
	context.remaining_seconds = duration_seconds
	context.is_time_expired = false

func update(delta: float) -> void:
	if not is_running or context == null or _expired_emitted:
		return
	var safe_delta: float = maxf(0.0, delta)
	context.elapsed_seconds += safe_delta
	context.remaining_seconds = maxf(0.0, duration_seconds - context.elapsed_seconds)
	if context.remaining_seconds <= 0.0:
		context.is_time_expired = true
		is_running = false
		_emit_expired_once()

func stop() -> void:
	is_running = false

func _emit_expired_once() -> void:
	if _expired_emitted:
		return
	_expired_emitted = true
	time_expired.emit()

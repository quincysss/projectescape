class_name InteractionProgressController
extends RefCounted

var active_id: String = ""
var active_target
var duration: float = 0.0
var elapsed: float = 0.0
var completion_callback: Callable = Callable()
var cancel_callback: Callable = Callable()

func begin(interaction_id: String, target, interaction_duration: float, on_completed: Callable, on_cancelled: Callable = Callable()) -> bool:
	if interaction_id.is_empty() or target == null or interaction_duration <= 0.0 or not on_completed.is_valid():
		return false
	active_id = interaction_id
	active_target = target
	duration = interaction_duration
	elapsed = 0.0
	completion_callback = on_completed
	cancel_callback = on_cancelled
	return true

func update(delta: float, should_continue: bool = true) -> Dictionary:
	if not is_active():
		return {"active": false, "completed": false, "progress": 0.0}
	if not should_continue:
		cancel()
		return {"active": false, "completed": false, "cancelled": true, "progress": 0.0}
	elapsed = minf(duration, elapsed + maxf(0.0, delta))
	var progress: float = get_progress()
	if elapsed >= duration:
		var target = active_target
		var callback: Callable = completion_callback
		reset()
		callback.call(target)
		return {"active": false, "completed": true, "progress": 1.0}
	return {"active": true, "completed": false, "progress": progress}

func cancel() -> void:
	if cancel_callback.is_valid():
		cancel_callback.call(active_target)
	reset()

func reset() -> void:
	active_id = ""
	active_target = null
	duration = 0.0
	elapsed = 0.0
	completion_callback = Callable()
	cancel_callback = Callable()

func is_active() -> bool:
	return not active_id.is_empty() and active_target != null

func is_target(target) -> bool:
	return is_active() and active_target == target

func get_progress() -> float:
	if duration <= 0.0:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)

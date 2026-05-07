extends SceneTree

const InteractionProgressControllerScript := preload("res://scripts/run/interaction_progress_controller.gd")

var completed_target
var cancelled_target

func _initialize() -> void:
	var ok := _verify_completion()
	if ok:
		ok = _verify_cancel()
	print("Interaction progress verified." if ok else "Interaction progress failed.")
	quit(0 if ok else 1)

func _verify_completion() -> bool:
	completed_target = null
	var target := RefCounted.new()
	var controller = InteractionProgressControllerScript.new()
	if not controller.begin("repair", target, 1.0, Callable(self, "_on_completed")):
		printerr("Expected interaction begin to pass.")
		return false
	var first_tick: Dictionary = controller.update(0.4, true)
	if not first_tick.active or controller.get_progress() <= 0.0:
		printerr("Expected interaction to be active after partial progress.")
		return false
	var finished: Dictionary = controller.update(0.6, true)
	if not finished.completed:
		printerr("Expected interaction to complete.")
		return false
	if completed_target != target:
		printerr("Expected completion callback target.")
		return false
	if controller.is_active():
		printerr("Expected completed interaction to reset.")
		return false
	return true

func _verify_cancel() -> bool:
	cancelled_target = null
	var target := RefCounted.new()
	var controller = InteractionProgressControllerScript.new()
	if not controller.begin("repair", target, 1.0, Callable(self, "_on_completed"), Callable(self, "_on_cancelled")):
		printerr("Expected cancellable interaction begin to pass.")
		return false
	var cancelled: Dictionary = controller.update(0.2, false)
	if not cancelled.cancelled:
		printerr("Expected interaction to cancel.")
		return false
	if cancelled_target != target:
		printerr("Expected cancel callback target.")
		return false
	if controller.is_active():
		printerr("Expected cancelled interaction to reset.")
		return false
	return true

func _on_completed(target) -> void:
	completed_target = target

func _on_cancelled(target) -> void:
	cancelled_target = target

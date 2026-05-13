extends SceneTree

const RunConfigScript := preload("res://scripts/run/run_config.gd")
const StabilityComponentScript := preload("res://scripts/player/stability_component.gd")


func _initialize() -> void:
	var ok := _verify_default_stability_decay_rate()
	print("Stability decay rate verified." if ok else "Stability decay rate failed.")
	quit(0 if ok else 1)


func _verify_default_stability_decay_rate() -> bool:
	var config = RunConfigScript.new()
	if not is_equal_approx(float(config.stability_decay_per_second), 1.5):
		printerr("Expected default stability decay to be 1.5/s, got %.2f." % float(config.stability_decay_per_second))
		return false

	var stability = StabilityComponentScript.new()
	root.add_child(stability)
	stability.configure(100.0, 100.0, config.stability_decay_per_second, config.stability_recover_per_second)
	stability.start_decay()
	stability._process(10.0)
	var expected := 85.0
	if absf(float(stability.current_stability) - expected) > 0.01:
		printerr("Expected 10 seconds of decay to leave %.2f stability, got %.2f." % [expected, float(stability.current_stability)])
		stability.queue_free()
		return false
	stability.queue_free()
	return true

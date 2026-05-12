extends SceneTree

const VisionControllerScript := preload("res://scripts/vision/vision_controller.gd")

func _initialize() -> void:
	var ok := await _verify_continuous_linear_radius()
	print("Vision continuous radius verified." if ok else "Vision continuous radius failed.")
	quit(0 if ok else 1)

func _verify_continuous_linear_radius() -> bool:
	var vision = VisionControllerScript.new()
	get_root().add_child(vision)
	await process_frame

	vision.safe_radius = 20.0
	vision.minimum_exploration_radius = 3.0
	vision.set_vision_from_stability(100.0, 100.0, 0)
	if not is_equal_approx(vision.current_radius, 20.0):
		printerr("Expected full stability to use safe radius.")
		return false

	vision.set_vision_from_stability(75.0, 100.0, 1)
	var radius_75: float = vision.current_radius
	if not is_equal_approx(radius_75, 15.75):
		printerr("Expected 75 stability to be linearly interpolated, got %s." % radius_75)
		return false

	vision.set_vision_from_stability(74.0, 100.0, 1)
	var radius_74: float = vision.current_radius
	if not is_equal_approx(radius_74, 15.58):
		printerr("Expected 74 stability to be linearly interpolated, got %s." % radius_74)
		return false
	if absf(radius_75 - radius_74) > 0.18:
		printerr("Expected crossing stage threshold to avoid a large radius jump.")
		return false

	vision.set_vision_from_stability(50.0, 100.0, 2)
	if not is_equal_approx(vision.current_radius, 11.5):
		printerr("Expected 50 stability to be halfway through the radius range.")
		return false

	vision.set_vision_from_stability(1.0, 100.0, 3)
	if vision.current_radius < vision.minimum_exploration_radius:
		printerr("Expected non-depleted exploration radius to stay above the minimum.")
		return false

	vision.set_vision_from_stability(0.0, 100.0, 4)
	if not is_equal_approx(vision.current_radius, 0.0):
		printerr("Expected depleted stability to collapse radius to zero.")
		return false

	vision.free()
	return true

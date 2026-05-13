extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")


func _initialize() -> void:
	var ok := await _verify()
	print("Base chapter goal position verified." if ok else "Base chapter goal position failed.")
	quit(0 if ok else 1)


func _verify() -> bool:
	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	await process_frame

	var goal := base.get_node_or_null("BaseUIRoot/ChapterGoalLabel") as Label
	var currency_label := base.get_node_or_null("BaseUIRoot/CurrencyLabel") as Label
	var debug_panel := base.get_node_or_null("BaseUIRoot/DebugPanel") as Panel
	if goal == null:
		return await _fail("Expected ChapterGoalLabel.", base)
	if currency_label == null:
		return await _fail("Expected CurrencyLabel.", base)
	if debug_panel == null:
		return await _fail("Expected DebugPanel.", base)
	if goal.anchor_left != 1.0 or goal.anchor_right != 1.0:
		return await _fail("Expected chapter goal to be anchored to the right side.", base)
	if goal.offset_right != currency_label.offset_right:
		return await _fail("Expected chapter goal to right-align with currency label.", base)
	if goal.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		return await _fail("Expected chapter goal text to align right with currency label.", base)
	if goal.offset_top != 92.0 or goal.offset_bottom != 174.0:
		return await _fail("Expected chapter goal to occupy the upper right task area.", base)
	if debug_panel.offset_top < goal.offset_bottom:
		return await _fail("Expected debug panel to sit below the chapter goal.", base)

	_stop_bgm()
	base.queue_free()
	await process_frame
	return true


func _fail(message: String, base: Node) -> bool:
	printerr(message)
	_stop_bgm()
	if is_instance_valid(base):
		base.queue_free()
	await process_frame
	return false


func _stop_bgm() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_bgm"):
		audio_manager.stop_bgm()

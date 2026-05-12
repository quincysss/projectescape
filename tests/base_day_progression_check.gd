extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	quit(0 if ok else 1)

func _verify() -> bool:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		push_error("GameState autoload is missing.")
		return false

	game_state.reset_day()
	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.set_merchant_shop_level(1)
	game_state.refresh_shop_stock(12345)
	if game_state.query_shop_offers().is_empty():
		push_error("Expected merchant stock before day advancement.")
		return false

	if game_state.get_current_day() != 1:
		push_error("Initial day should be 1, got %d." % game_state.get_current_day())
		return false

	if not await _expect_base_day_text("第 1 天"):
		return false

	game_state.apply_run_result({
		"message": "撤离成功",
		"warehouse_items": [],
	})
	if game_state.get_current_day() != 2:
		push_error("Day should advance to 2 after first run result, got %d." % game_state.get_current_day())
		return false
	if not game_state.merchant_shop_offers.is_empty():
		push_error("Merchant stock should be cleared when a new day starts.")
		return false
	if not await _expect_base_day_text("第 2 天"):
		return false

	game_state.apply_run_result({
		"message": "探索失败",
		"warehouse_items": [],
	})
	if game_state.get_current_day() != 3:
		push_error("Day should advance to 3 after second run result, got %d." % game_state.get_current_day())
		return false
	if not await _expect_base_day_text("第 3 天"):
		return false

	print("Base day progression verified.")
	return true

func _expect_base_day_text(expected: String) -> bool:
	var base_scene := BASE_SCENE.instantiate()
	root.add_child(base_scene)
	await process_frame
	var day_label := base_scene.get_node_or_null("%DayLabel") as Label
	if day_label == null:
		push_error("DayLabel is missing from BaseScene.")
		base_scene.queue_free()
		await process_frame
		return false
	if day_label.text != expected:
		push_error("Expected day label '%s', got '%s'." % [expected, day_label.text])
		base_scene.queue_free()
		await process_frame
		return false
	base_scene.queue_free()
	await process_frame
	return true

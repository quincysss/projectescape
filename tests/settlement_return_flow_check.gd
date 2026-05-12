extends SceneTree

const SettlementResultScreenScript := preload("res://scripts/ui/settlement_result_screen.gd")
const ReturnToBaseLoadingScreenScript := preload("res://scripts/ui/return_to_base_loading_screen.gd")

class FakeGameState:
	extends Node

	var apply_count := 0
	var warehouse_items: Array[Dictionary] = []
	var warehouse_capacity := 12
	var surface_day := 7

	func apply_run_result(result: Dictionary) -> void:
		apply_count += 1
		for item in Array(result.get("warehouse_items", [])):
			if item is Dictionary:
				warehouse_items.append(item.duplicate(true))

	func get_warehouse_capacity() -> int:
		return warehouse_capacity

	func get_warehouse_items_snapshot() -> Array[Dictionary]:
		var snapshot: Array[Dictionary] = []
		for item in warehouse_items:
			snapshot.append(item.duplicate(true))
		return snapshot

	func get_current_day() -> int:
		return surface_day

func _initialize() -> void:
	var ok := await _verify()
	print("Settlement return flow verified." if ok else "Settlement return flow failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	return await _verify_settlement_screen_success() and await _verify_settlement_screen_failure() and await _verify_return_loading()

func _verify_settlement_screen_success() -> bool:
	var screen: SettlementResultScreen = SettlementResultScreenScript.new()
	root.add_child(screen)
	await process_frame
	var requested := {"value": false}
	screen.return_to_base_requested.connect(func(): requested["value"] = true)
	screen.show_result({
		"result_type": "EXTRACTED",
		"warehouse_items": [
			_item("scrap_metal", "废金属", "C", "背包", "已带回"),
			_item("scrap_metal", "废金属", "C", "背包", "已带回"),
			_item("gold_data_chip", "金色数据芯片", "S", "安全屋", "已带回"),
		],
	})
	await process_frame
	if screen.title_label.text != "成功返回404哨所":
		printerr("Expected success settlement title, got %s." % screen.title_label.text)
		screen.queue_free()
		return false
	if screen.item_title_label.text != "本次获得的物资":
		printerr("Expected success item title.")
		screen.queue_free()
		return false
	if screen.item_list.get_child_count() != 2:
		printerr("Expected identical settlement items to be grouped into two rows, got %d." % screen.item_list.get_child_count())
		screen.queue_free()
		return false
	screen.return_button.emit_signal("pressed")
	if not bool(requested.get("value", false)):
		printerr("Expected return button to request return loading.")
		screen.queue_free()
		return false
	screen.queue_free()
	await process_frame
	return true

func _verify_settlement_screen_failure() -> bool:
	var screen: SettlementResultScreen = SettlementResultScreenScript.new()
	root.add_child(screen)
	await process_frame
	screen.show_result({
		"result_type": "DEAD",
		"warehouse_items": [],
	})
	await process_frame
	if screen.title_label.text != "你已被黑潮吞噬，将在404重塑躯体。":
		printerr("Expected failure settlement title, got %s." % screen.title_label.text)
		screen.queue_free()
		return false
	if screen.item_title_label.text != "本局带出的物资":
		printerr("Expected failure item title.")
		screen.queue_free()
		return false
	if not screen.empty_label.visible or screen.empty_label.text != "没有带回任何物资":
		printerr("Expected failure empty carried-out item text.")
		screen.queue_free()
		return false
	screen.queue_free()
	await process_frame
	return true

func _verify_return_loading() -> bool:
	var fake := FakeGameState.new()
	root.add_child(fake)
	var loading: ReturnToBaseLoadingScreen = ReturnToBaseLoadingScreenScript.new()
	root.add_child(loading)
	await process_frame

	var state := {"completed": false, "failed": ""}
	loading.return_completed.connect(func(): state["completed"] = true)
	loading.return_failed.connect(func(reason): state["failed"] = String(reason))
	loading.begin_return({
		"result_type": "EXTRACTED",
		"warehouse_items": [
			_item("scrap_metal", "废金属", "C", "背包", "已带回"),
		],
	}, fake, {"change_scene": false})

	for _index in range(120):
		if loading.is_ready_to_continue() or not String(state.get("failed", "")).is_empty():
			break
		await process_frame
		await physics_frame

	if not String(state.get("failed", "")).is_empty():
		printerr("Expected return loading to succeed, failed: %s." % String(state.get("failed", "")))
		_cleanup(fake, loading)
		return false
	if fake.apply_count != 1:
		printerr("Expected return loading to commit result exactly once, got %d." % fake.apply_count)
		_cleanup(fake, loading)
		return false
	if fake.get_current_day() != 7:
		printerr("Expected return loading not to advance surface_day.")
		_cleanup(fake, loading)
		return false
	if loading.percent_label.text != "100%" or loading.stage_label.text != "按下任意按钮继续":
		printerr("Expected return loading to wait at 100%% for input.")
		_cleanup(fake, loading)
		return false
	if not loading.continue_label.visible or loading.continue_label.text != "按下任意按钮继续":
		printerr("Expected return loading continue prompt.")
		_cleanup(fake, loading)
		return false
	if bool(state.get("completed", false)):
		printerr("Expected return loading to wait for input before completion.")
		_cleanup(fake, loading)
		return false

	loading._input(_key(KEY_SPACE))
	await process_frame
	if not bool(state.get("completed", false)):
		printerr("Expected any key to complete return loading.")
		_cleanup(fake, loading)
		return false
	if is_instance_valid(fake):
		fake.queue_free()
	return true

func _item(item_id: String, display_name: String, quality: String, source: String, status: String) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": 0.1,
		"stack_limit": 1,
		"quality": quality,
		"settlement_source": source,
		"settlement_status": status,
		"icon": "res://assets/ui/itemicon/%s.png" % item_id,
	}

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _cleanup(fake, loading) -> void:
	if is_instance_valid(loading):
		loading.queue_free()
	if is_instance_valid(fake):
		fake.queue_free()

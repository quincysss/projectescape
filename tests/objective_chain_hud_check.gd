extends SceneTree

func _initialize() -> void:
	var ok := await _verify_objective_chain_hud()
	await _shutdown_audio()
	print("Objective chain HUD verified." if ok else "Objective chain HUD failed.")
	quit(0 if ok else 1)

func _verify_objective_chain_hud() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var panel := root.get_node_or_null("RunUIRoot/ObjectiveChainHUD") as Panel
	var title := panel.get_node_or_null("ObjectiveTitle") as Label if panel != null else null
	var next_step := panel.get_node_or_null("ObjectiveNextStep") as Label if panel != null else null
	var extraction := panel.get_node_or_null("ObjectiveExtraction") as Label if panel != null else null
	if panel == null or title == null or next_step == null or extraction == null:
		printerr("Expected objective chain HUD labels.")
		return false
	if panel.get_node_or_null("OutpostOneStatus") != null or panel.get_node_or_null("OutpostTwoStatus") != null:
		printerr("Expected old I/II outpost rows to be removed from the left HUD.")
		return false
	if not title.text.contains("当前目标") or not title.text.contains("前哨站材料") or not title.text.contains("菱形") or title.text.contains("◇"):
		printerr("Expected objective title to guide material collection, got: %s" % title.text)
		return false
	if title.autowrap_mode != TextServer.AUTOWRAP_OFF or next_step.autowrap_mode != TextServer.AUTOWRAP_OFF or extraction.autowrap_mode != TextServer.AUTOWRAP_OFF:
		printerr("Expected objective chain HUD labels to stay on one line.")
		return false
	if panel.size.x < 340.0 or panel.size.y > 150.0:
		printerr("Expected objective chain HUD box to be wide and compact, got: %s" % panel.size)
		return false
	if title.get_minimum_size().x > title.size.x:
		printerr("Expected objective title to fit on one line, min=%s size=%s text=%s" % [title.get_minimum_size(), title.size, title.text])
		return false
	if panel.self_modulate.a < 0.95:
		printerr("Expected objective chain HUD to be fully readable at home, got alpha: %s" % panel.self_modulate.a)
		return false
	root.run_director.on_safe_zone_exited("home")
	root._refresh_ui()
	await process_frame
	if panel.self_modulate.a >= 0.75:
		printerr("Expected objective chain HUD to become translucent after leaving home, got alpha: %s" % panel.self_modulate.a)
		return false
	root.run_director.on_safe_zone_entered("home")
	root._refresh_ui()
	await process_frame
	if panel.self_modulate.a < 0.95:
		printerr("Expected objective chain HUD opacity restored inside home, got alpha: %s" % panel.self_modulate.a)
		return false
	if not next_step.text.contains("下一步") or not next_step.text.contains("前哨站修复"):
		printerr("Expected next step to point to outpost repair, got: %s" % next_step.text)
		return false
	if not extraction.text.contains("解锁撤离") or not extraction.text.contains("未解锁"):
		printerr("Expected extraction row to show locked state, got: %s" % extraction.text)
		return false

	var first_outpost = _find_interactable(root, "outpost", String(root.run_director.context.selected_first_outpost_id))
	if first_outpost == null:
		printerr("Expected selected first outpost.")
		return false
	var requirements: Dictionary = first_outpost.payload.get("requirements", {})
	if requirements.is_empty():
		printerr("Expected first outpost requirements.")
		return false
	var first_item_id := String(requirements.keys()[0])
	var first_data: Dictionary = requirements[first_item_id]
	root.run_director.debug_add_item(_item(first_item_id, String(first_data.get("display_name", first_item_id)), int(first_data.get("amount", 1)), float(first_data.get("weight", 1.0))))
	root._refresh_ui()
	await process_frame
	if not title.text.contains("1/"):
		printerr("Expected objective title to update after one material type is available, got: %s" % title.text)
		return false
	var pickup_prompt: String = root.run_ui_controller.outpost_material_pickup_prompt(root, first_outpost.interact_id)
	if not pickup_prompt.contains("前哨材料已获得") or not pickup_prompt.contains("1/"):
		printerr("Expected material pickup prompt with objective progress, got: %s" % pickup_prompt)
		return false

	for item_id in requirements.keys():
		var data: Dictionary = requirements[item_id]
		root.run_director.debug_add_item(_item(String(item_id), String(data.get("display_name", item_id)), int(data.get("amount", 1)), float(data.get("weight", 1.0))))
	root._refresh_ui()
	await process_frame
	if not title.text.contains("前往前哨站") or not next_step.text.contains("长按修复前哨站"):
		printerr("Expected objective chain to switch to outpost repair when materials are ready. title=%s next=%s" % [title.text, next_step.text])
		return false

	root.run_director.context.is_extraction_unlocked = true
	root.run_director.context.active_safe_zone_id = "home"
	root._refresh_ui()
	await process_frame
	if not title.text.contains("撤离已解锁") or not next_step.text.contains("长按 E") or not extraction.text.contains("可撤离"):
		printerr("Expected objective chain to switch to extraction when unlocked. title=%s next=%s extraction=%s" % [title.text, next_step.text, extraction.text])
		return false

	root.queue_free()
	await process_frame
	return true

func _find_interactable(root, interact_type: String, interact_id: String = ""):
	for interactable in root.interactables:
		if not is_instance_valid(interactable):
			continue
		if interactable.interact_type != interact_type:
			continue
		if interact_id.is_empty() or interactable.interact_id == interact_id:
			return interactable
	return null

func _item(item_id: String, display_name: String, amount: int, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": amount,
		"weight_per_unit": weight,
		"stack_limit": 99,
		"repair_material_id": item_id,
	}

func _shutdown_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("shutdown_and_flush"):
		await audio_manager.shutdown_and_flush()

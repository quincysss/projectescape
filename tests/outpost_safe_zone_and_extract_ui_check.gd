extends SceneTree

func _initialize() -> void:
	var ok := await _verify_outpost_safe_zone_and_extract_ui()
	print("Outpost safe zone and extract UI verified." if ok else "Outpost safe zone and extract UI failed.")
	quit(0 if ok else 1)

func _verify_outpost_safe_zone_and_extract_ui() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	if root.deposit_button.get_parent() == root.inventory_panel or root.extract_button.get_parent() == root.inventory_panel:
		printerr("Expected home action buttons outside backpack panel.")
		return false
	if root.deposit_button.get_parent() != root.home_action_panel or root.extract_button.get_parent() != root.home_action_panel:
		printerr("Expected home action buttons under independent home action panel.")
		return false

	var outpost = _find_interactable(root, "outpost")
	if outpost == null:
		printerr("Expected an outpost interactable.")
		return false

	root.run_director.on_safe_zone_exited("home")
	root.run_director.on_camera_transition_finished()
	root.run_director.stability_component.set_stability(50.0)
	outpost.payload.repaired = true
	outpost.payload.repair_state = "ACTIVE"
	root._on_interactable_entered(outpost)
	await process_frame

	if root.run_director.context.active_safe_zone_id == outpost.interact_id:
		printerr("Expected outpost interact radius to stay separate from safe zone.")
		return false

	root.player.global_position = outpost.global_position
	root._on_outpost_safe_zone_body_entered(outpost, root.player)
	await process_frame

	if root.run_director.context.active_safe_zone_id != outpost.interact_id:
		printerr("Expected repaired outpost to become active safe zone.")
		return false
	if not root.run_director.stability_component.is_recovering:
		printerr("Expected stability recovery inside repaired outpost.")
		return false
	if root.vision_mask.visible:
		printerr("Expected darkness mask hidden inside repaired outpost.")
		return false

	root._on_outpost_safe_zone_body_exited(outpost, root.player)
	await process_frame
	if root.run_director.context.active_safe_zone_id != "":
		printerr("Expected outpost safe zone to clear after exit.")
		return false
	if not root.run_director.stability_component.is_decaying:
		printerr("Expected stability decay after leaving repaired outpost.")
		return false

	root.run_director.context.is_extraction_unlocked = true
	root.run_director.on_safe_zone_entered("home")
	root._refresh_ui()
	if root.extract_hud_button.disabled:
		printerr("Expected HUD extraction button enabled at home after unlock.")
		return false
	if not root.prompt_label.text.contains("撤离已准备"):
		printerr("Expected extraction ready prompt at home.")
		return false

	root.queue_free()
	await process_frame
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null

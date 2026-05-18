extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")


func _initialize() -> void:
	var ok := await _verify_base_item_tooltip()
	print("Base item tooltip verified." if ok else "Base item tooltip failed.")
	quit(0 if ok else 1)


func _verify_base_item_tooltip() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load.")
		return false
	game_state.clear_warehouse()
	game_state.add_to_warehouse([registry.make_item_stack("gold_data_chip")])

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	var ok := true
	ok = await _verify_warehouse_tooltip(base_root) and ok
	ok = await _verify_research_tooltip(base_root) and ok

	base_root.queue_free()
	await process_frame
	return ok


func _verify_warehouse_tooltip(base_root) -> bool:
	var button := _first_button(base_root.warehouse_grid_root)
	if button == null:
		printerr("Expected a warehouse item button.")
		return false
	button.emit_signal("mouse_entered")
	await create_timer(0.22).timeout
	var panel := base_root.item_tooltip_panel as Panel
	if panel == null or not panel.visible:
		printerr("Expected warehouse hover to show item tooltip.")
		return false
	if panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		printerr("Expected tooltip panel not to intercept mouse.")
		return false
	if base_root.tooltip_layer == null or base_root.tooltip_layer.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		printerr("Expected tooltip layer not to intercept mouse.")
		return false
	if base_root.item_tooltip_name_label.text != "金色数据芯片":
		printerr("Expected tooltip name from items.tab, got %s." % base_root.item_tooltip_name_label.text)
		return false
	if base_root.item_tooltip_price_label.text != "120矿币":
		printerr("Expected tooltip price from items.tab/currencies.tab, got %s." % base_root.item_tooltip_price_label.text)
		return false
	if not base_root.item_tooltip_description_label.text.contains("高价值芯片"):
		printerr("Expected tooltip description from items.tab.")
		return false
	if not _panel_inside_viewport(base_root, panel):
		printerr("Expected tooltip to stay inside viewport.")
		return false
	button.emit_signal("mouse_exited")
	await process_frame
	if panel.visible:
		printerr("Expected tooltip to hide on mouse exit.")
		return false
	return true


func _verify_research_tooltip(base_root) -> bool:
	base_root._selected_research_id = "move_speed"
	base_root._update_selected_research_state()
	await process_frame
	var requirement_slot := _first_panel(base_root.research_requirement_grid_root)
	if requirement_slot == null:
		printerr("Expected research material requirement slot.")
		return false
	requirement_slot.emit_signal("mouse_entered")
	await create_timer(0.22).timeout
	var panel := base_root.item_tooltip_panel as Panel
	if panel == null or not panel.visible:
		printerr("Expected research material hover to show tooltip.")
		return false
	if base_root.item_tooltip_name_label.text.is_empty():
		printerr("Expected research tooltip item name.")
		return false
	if base_root.item_tooltip_description_label.text.is_empty():
		printerr("Expected research tooltip description.")
		return false
	base_root._hide_item_tooltip("test_done")
	return true


func _first_button(root_control: Control) -> Button:
	if root_control == null:
		return null
	for child in root_control.get_children():
		if child is Button:
			return child
	return null


func _first_panel(root_control: Control) -> Panel:
	if root_control == null:
		return null
	for child in root_control.get_children():
		if child is Panel:
			return child
	return null


func _panel_inside_viewport(base_root, panel: Panel) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, base_root.get_viewport_rect().size)
	var rect := panel.get_global_rect()
	return viewport_rect.encloses(rect)

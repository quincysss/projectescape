extends SceneTree

const BASE_SCENE := preload("res://scenes/base/BaseScene.tscn")

func _initialize() -> void:
	var ok := await _verify()
	print("Chapter popup layout verified." if ok else "Chapter popup layout failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var base = BASE_SCENE.instantiate()
	root.add_child(base)
	await process_frame

	base._show_chapter_goal_popup()
	await process_frame
	var overlay := base.get_node_or_null("StoryPopupOverlay") as Control
	var panel := base.get_node_or_null("StoryPopupOverlay/PopupPanel") as Panel
	var ok_button := _first_button(panel)
	var order_button := _button_with_text(panel, "查看今日订单")
	var old_demand_button := _button_with_text(panel, "查看需求榜")
	var body_label := _label_containing(panel, "查看今日订单")
	var ok := true
	if overlay == null or panel == null:
		printerr("Expected chapter goal popup to be created.")
		ok = false
	else:
		if panel.anchor_left != 0.5 or panel.anchor_right != 0.5 or panel.anchor_top != 0.5 or panel.anchor_bottom != 0.5:
			printerr("Expected chapter goal popup panel to be anchored to screen center.")
			ok = false
		if panel.offset_left != -320.0 or panel.offset_right != 320.0 or panel.offset_top != -170.0 or panel.offset_bottom != 170.0:
			printerr("Expected chapter goal popup panel to use the enlarged centered offsets.")
			ok = false
		if ok_button == null or ok_button.size != Vector2(132, 40):
			printerr("Expected popup buttons to use the enlarged button size.")
			ok = false
		if order_button == null or old_demand_button != null:
			printerr("Expected chapter goal popup to use 今日订单 wording.")
			ok = false
		if body_label == null or body_label.autowrap_mode != TextServer.AUTOWRAP_ARBITRARY:
			printerr("Expected chapter goal popup body to wrap safely inside the panel.")
			ok = false
		elif body_label.position.x < 0.0 or body_label.position.x + body_label.size.x > panel.size.x:
			printerr("Expected chapter goal popup body text box to stay inside the panel.")
			ok = false

	base.queue_free()
	await process_frame
	return ok

func _first_button(node: Node) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button:
			return child
	return null

func _button_with_text(node: Node, text: String) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button and String(child.text) == text:
			return child
	return null

func _label_containing(node: Node, text: String) -> Label:
	if node == null:
		return null
	for child in node.get_children():
		if child is Label and String(child.text).contains(text):
			return child
	return null

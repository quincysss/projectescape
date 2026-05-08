class_name RunUiController
extends RefCounted

func build(scene) -> void:
	scene.hud_label = Label.new()
	scene.hud_label.name = "HUDLabel"
	scene.hud_label.position = Vector2(16, 12)
	scene.hud_label.size = Vector2(760, 78)
	scene.hud_label.add_theme_font_size_override("font_size", 18)
	scene.ui_root.add_child(scene.hud_label)

	scene.prompt_label = Label.new()
	scene.prompt_label.name = "PromptLabel"
	scene.prompt_label.position = Vector2(16, 96)
	scene.prompt_label.size = Vector2(900, 44)
	scene.prompt_label.add_theme_font_size_override("font_size", 18)
	scene.ui_root.add_child(scene.prompt_label)

	scene.backpack_button = Button.new()
	scene.backpack_button.name = "BackpackButton"
	scene.backpack_button.text = "背包"
	scene.backpack_button.position = Vector2(820, 16)
	scene.backpack_button.size = Vector2(96, 38)
	scene.backpack_button.pressed.connect(scene._toggle_inventory_panel)
	scene.ui_root.add_child(scene.backpack_button)

	scene.extract_hud_button = Button.new()
	scene.extract_hud_button.name = "ExtractHUDButton"
	scene.extract_hud_button.text = "撤离未解锁"
	scene.extract_hud_button.position = Vector2(928, 16)
	scene.extract_hud_button.size = Vector2(140, 38)
	scene.extract_hud_button.button_down.connect(scene._begin_extraction_hold_from_button)
	scene.extract_hud_button.button_up.connect(scene._release_extraction_hold_button)
	scene.ui_root.add_child(scene.extract_hud_button)

	scene.inventory_panel = _make_panel(Vector2(16, 154), Vector2(390, 360), "背包")
	scene.inventory_label = Label.new()
	scene.inventory_label.position = Vector2(16, 52)
	scene.inventory_label.size = Vector2(358, 288)
	scene.inventory_label.clip_text = true
	scene.inventory_label.add_theme_font_size_override("font_size", 16)
	scene.inventory_panel.add_child(scene.inventory_label)
	scene.ui_root.add_child(scene.inventory_panel)
	scene.inventory_panel.visible = false

	scene.home_storage_panel = _make_panel(Vector2(422, 154), Vector2(390, 360), "家中储存")
	scene.home_storage_label = Label.new()
	scene.home_storage_label.position = Vector2(16, 52)
	scene.home_storage_label.size = Vector2(358, 230)
	scene.home_storage_label.clip_text = true
	scene.home_storage_label.add_theme_font_size_override("font_size", 16)
	scene.home_storage_panel.add_child(scene.home_storage_label)
	scene.deposit_button = Button.new()
	scene.deposit_button.text = "存入家中"
	scene.deposit_button.position = Vector2(16, 300)
	scene.deposit_button.size = Vector2(172, 40)
	scene.deposit_button.pressed.connect(scene._deposit_all)
	scene.home_storage_panel.add_child(scene.deposit_button)
	scene.extract_button = Button.new()
	scene.extract_button.text = "撤离"
	scene.extract_button.position = Vector2(202, 300)
	scene.extract_button.size = Vector2(172, 40)
	scene.extract_button.button_down.connect(scene._begin_extraction_hold_from_button)
	scene.extract_button.button_up.connect(scene._release_extraction_hold_button)
	scene.home_storage_panel.add_child(scene.extract_button)
	scene.ui_root.add_child(scene.home_storage_panel)
	scene.home_storage_panel.visible = false

	scene.loot_panel = _make_panel(Vector2(422, 154), Vector2(390, 300), "容器 / 材料")
	scene.loot_label = Label.new()
	scene.loot_label.position = Vector2(16, 52)
	scene.loot_label.size = Vector2(358, 170)
	scene.loot_label.clip_text = true
	scene.loot_label.add_theme_font_size_override("font_size", 16)
	scene.loot_panel.add_child(scene.loot_label)
	scene.take_all_button = Button.new()
	scene.take_all_button.text = "全部拾取"
	scene.take_all_button.position = Vector2(16, 240)
	scene.take_all_button.size = Vector2(172, 40)
	scene.take_all_button.pressed.connect(scene._take_all_loot)
	scene.loot_panel.add_child(scene.take_all_button)
	scene.ui_root.add_child(scene.loot_panel)
	scene.loot_panel.visible = false

func refresh(scene) -> void:
	if scene.run_director.context == null:
		return
	var phase: String = scene.run_director.state_machine.phase_name(scene.run_director.state_machine.current_phase)
	scene.hud_label.text = "WASD移动  F交互  Tab背包  E撤离\n阶段：%s    稳定值：%d    负重：%.1f/%.1f（%s）    前哨：%d/2    撤离：%s" % [
		_phase_name_cn(phase),
		int(scene.run_director.context.player_stability),
		scene.run_director.context.current_weight,
		scene.run_director.context.weight_limit,
		_weight_stage_cn(scene.run_director.context.weight_stage),
		scene.run_director.context.repaired_outpost_count,
		"已解锁" if scene.run_director.context.is_extraction_unlocked else "未解锁",
	]
	var extraction_ready_at_home: bool = scene.run_director.context.is_extraction_unlocked and scene.run_director.context.active_safe_zone_id == "home"
	var extraction_unlocked: bool = scene.run_director.context.is_extraction_unlocked
	var is_home_safe_zone: bool = scene.run_director.context.active_safe_zone_id == "home"
	if scene.interaction_progress_controller != null and scene.interaction_progress_controller.is_active():
		var progress_percent: int = int(round(scene.interaction_progress_controller.get_progress() * 100.0))
		scene.prompt_label.text = "%s中：%s%%" % [
			_interaction_progress_text(scene.interaction_progress_controller.active_id),
			progress_percent,
		]
	elif extraction_ready_at_home:
		scene.prompt_label.text = "撤离已准备：按住 E 或按住“撤离”返回基地。"
	elif not scene._status_prompt.is_empty():
		scene.prompt_label.text = scene._status_prompt
	elif scene.nearest_interactable:
		scene.prompt_label.text = "%s：%s（%s）" % [
			_interact_prompt_prefix(scene.nearest_interactable.interact_type),
			scene.nearest_interactable.display_name,
			_interactable_type_name(scene.nearest_interactable.interact_type),
		]
	elif is_home_safe_zone:
		scene.prompt_label.text = "家中安全区：恢复稳定值，可存放物品。修复两座前哨站后可撤离。"
	elif extraction_unlocked:
		scene.prompt_label.text = "撤离已解锁。请返回家中撤离。"
	else:
		scene.prompt_label.text = ""
	scene.inventory_label.text = _items_text(scene.run_director.inventory_component.get_items_snapshot())
	scene.home_storage_label.text = _items_text(scene.run_director.home_storage_component.get_items_snapshot() if scene.run_director.home_storage_component != null else [])
	scene.loot_label.text = _items_text(scene.opened_loot)
	_sync_home_storage_ui(scene, is_home_safe_zone)
	scene.deposit_button.disabled = not is_home_safe_zone
	scene.extract_button.disabled = not extraction_ready_at_home
	scene.extract_hud_button.disabled = not extraction_ready_at_home
	scene.extract_hud_button.text = "撤离(E)" if extraction_ready_at_home else ("返回家中" if extraction_unlocked else "撤离未解锁")

func toggle_inventory(scene) -> void:
	var is_home_safe_zone: bool = scene.run_director.context != null and scene.run_director.context.active_safe_zone_id == "home"
	if is_home_safe_zone:
		if scene.inventory_panel.visible or scene.home_storage_panel.visible:
			scene.home_storage_user_closed = true
			scene.inventory_panel.visible = false
			scene.home_storage_panel.visible = false
		else:
			scene.home_storage_user_closed = false
			scene.inventory_panel.visible = true
			scene.home_storage_panel.visible = true
	else:
		scene.inventory_panel.visible = not scene.inventory_panel.visible
	refresh(scene)

func _make_panel(pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = panel_size
	panel.z_index = 60
	var label := Label.new()
	label.text = title
	label.position = Vector2(16, 12)
	label.size = Vector2(panel_size.x - 32.0, 28.0)
	label.add_theme_font_size_override("font_size", 20)
	panel.add_child(label)
	return panel

func _sync_home_storage_ui(scene, is_home_safe_zone: bool) -> void:
	if not is_home_safe_zone:
		scene.home_storage_user_closed = false
		scene.home_storage_panel.visible = false
		if not scene.loot_panel.visible:
			scene.inventory_panel.visible = false
		return
	if scene.home_storage_user_closed:
		scene.home_storage_panel.visible = false
		return
	scene.inventory_panel.visible = true
	scene.home_storage_panel.visible = true

func _items_text(items: Array) -> String:
	var lines: Array[String] = []
	if items.is_empty():
		lines.append("空")
	for item in items:
		if item is Dictionary:
			lines.append("%s  x%s  单重 %.1f" % [
				item.get("display_name", item.get("item_id", "")),
				item.get("amount", 0),
				float(item.get("weight_per_unit", 0.0)),
			])
	return "\n".join(lines)

func _interaction_progress_text(interaction_id: String) -> String:
	match interaction_id:
		"open_container":
			return "开箱"
		"repair_outpost":
			return "修复"
		"extract":
			return "撤离"
		_:
			return "交互"

func _phase_name_cn(phase: String) -> String:
	match phase:
		"SPAWN":
			return "出生"
		"OBSERVE":
			return "家中观察"
		"LEAVE_HOME":
			return "离家"
		"SCAVENGE":
			return "探索"
		"RECOVER":
			return "恢复"
		"OUTPOST_PUSH":
			return "修复前哨"
		"GREED_DECISION":
			return "撤离抉择"
		"EXTRACT":
			return "撤离"
		"SETTLEMENT":
			return "结算"
		"FAILED":
			return "失败"
		_:
			return phase

func _weight_stage_cn(stage: String) -> String:
	match stage:
		"LIGHT":
			return "轻装"
		"HEAVY":
			return "重载"
		"OVERLOADED":
			return "超重"
		_:
			return stage

func _interactable_type_name(interact_type: String) -> String:
	match interact_type:
		"container":
			return "容器"
		"material":
			return "前哨材料"
		"outpost":
			return "前哨站"
		_:
			return interact_type

func _interact_prompt_prefix(interact_type: String) -> String:
	match interact_type:
		"container":
			return "按住 F"
		"outpost":
			return "按住 F"
		_:
			return "按 F"

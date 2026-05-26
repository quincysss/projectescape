class_name BaseNightPlanPanelController
extends RefCounted

const PHASE_NIGHT_PLAN := "NIGHT_PLAN"
const PHASE_LOADOUT := "LOADOUT"

var game_state: Node
var ui_root: Control
var refresh_callback: Callable
var begin_run_callback: Callable
var plan_panel: Panel
var loadout_panel: Panel


func setup(
	p_game_state: Node,
	p_ui_root: Control,
	p_refresh_callback: Callable,
	p_begin_run_callback: Callable
) -> void:
	game_state = p_game_state
	ui_root = p_ui_root
	refresh_callback = p_refresh_callback
	begin_run_callback = p_begin_run_callback
	_build_surfaces()


func set_game_state(p_game_state: Node) -> void:
	game_state = p_game_state


func update_view(phase: String) -> void:
	if plan_panel == null:
		return
	plan_panel.visible = phase == PHASE_NIGHT_PLAN
	loadout_panel.visible = phase == PHASE_LOADOUT
	if plan_panel.visible:
		_render_plan_panel()
	if loadout_panel.visible:
		_render_loadout_panel()


func _build_surfaces() -> void:
	if ui_root == null or plan_panel != null:
		return
	plan_panel = _make_panel("NightPlanPanel", Vector2(24, 154), Vector2(980, 500), "夜间出发计划")
	plan_panel.visible = false
	ui_root.add_child(plan_panel)
	loadout_panel = _make_panel("LoadoutPanel", Vector2(24, 154), Vector2(980, 500), "出发携行配置")
	loadout_panel.visible = false
	ui_root.add_child(loadout_panel)


func _render_plan_panel() -> void:
	_clear_panel_body(plan_panel)
	if game_state == null:
		plan_panel.add_child(_make_label("GameState 不可用。", Vector2(24, 64), Vector2(260, 32), 15))
		return
	var snapshot: Dictionary = game_state.get_night_plan_snapshot()
	_render_resource_briefing_plan(snapshot)


func _render_resource_briefing_plan(snapshot: Dictionary) -> void:
	plan_panel.add_child(_make_label("角色", Vector2(44, 72), Vector2(160, 28), 20))
	var y := 112.0
	for character in Array(snapshot.get("characters", [])):
		if character is Dictionary:
			plan_panel.add_child(_make_card(
				String(character.get("display_name", "")),
				String(character.get("description", "")),
				Vector2(44, y),
				Vector2(360, 82),
				bool(character.get("selected", false))
			))
			y += 98.0
	plan_panel.add_child(_make_label("地图情报", Vector2(448, 60), Vector2(220, 28), 20))
	plan_panel.add_child(_make_label("只显示类别和倾向，具体掉落保留随机性。", Vector2(448, 88), Vector2(420, 22), 13))
	y = 116.0
	for location in Array(snapshot.get("locations", [])):
		if location is Dictionary:
			plan_panel.add_child(_make_location_card(location, Vector2(448, y), Vector2(492, 96)))
			y += 108.0
	var prepare_button := Button.new()
	prepare_button.text = "准备携行"
	prepare_button.position = Vector2(236, 418)
	prepare_button.size = Vector2(144, 42)
	prepare_button.pressed.connect(_on_prepare_loadout_pressed)
	_style_button(prepare_button, true)
	plan_panel.add_child(prepare_button)


func _render_loadout_panel() -> void:
	_clear_panel_body(loadout_panel)
	if game_state == null:
		loadout_panel.add_child(_make_label("GameState 不可用。", Vector2(24, 64), Vector2(260, 32), 15))
		return
	var snapshot: Dictionary = game_state.get_loadout_snapshot()
	loadout_panel.add_child(_make_label("装备槽", Vector2(44, 72), Vector2(160, 28), 20))
	var equipment_slots: Dictionary = snapshot.get("equipment_slots", {})
	var slot_names: Array[String] = ["HEAD", "BODY", "HAND", "FOOT"]
	var labels := {"HEAD": "头部", "BODY": "身体", "HAND": "手部", "FOOT": "脚部"}
	for index in range(slot_names.size()):
		var slot_id: String = slot_names[index]
		var pos := Vector2(44 + float(index % 2) * 220.0, 116 + float(int(index / 2)) * 104.0)
		loadout_panel.add_child(_make_card(String(labels.get(slot_id, slot_id)), _slot_detail(String(equipment_slots.get(slot_id, ""))), pos, Vector2(184, 78), false))
	loadout_panel.add_child(_make_label("消耗品槽", Vector2(520, 72), Vector2(160, 28), 20))
	var consumables: Array = snapshot.get("consumable_slots", [])
	var unlocked := int(snapshot.get("unlocked_consumable_slots", 1))
	for index in range(int(snapshot.get("consumable_slot_count", 4))):
		var enabled := index < unlocked
		var detail := _slot_detail(String(consumables[index] if index < consumables.size() else ""))
		if not enabled:
			detail = "未开放"
		loadout_panel.add_child(_make_card("消耗品 %d" % (index + 1), detail, Vector2(520, 116 + float(index) * 74.0), Vector2(220, 56), enabled))
	var start_button := Button.new()
	start_button.text = "出发"
	start_button.position = Vector2(760, 418)
	start_button.size = Vector2(144, 42)
	start_button.pressed.connect(_on_begin_run_pressed)
	_style_button(start_button, true)
	loadout_panel.add_child(start_button)


func _on_prepare_loadout_pressed() -> void:
	if game_state != null and game_state.has_method("go_to_loadout"):
		game_state.go_to_loadout()
	_call_refresh()


func _on_begin_run_pressed() -> void:
	if begin_run_callback.is_valid():
		begin_run_callback.call()


func _on_location_card_pressed(location_id: String) -> void:
	if game_state != null and game_state.has_method("set_night_plan_selection"):
		game_state.set_night_plan_selection("", location_id)
	_render_plan_panel()
	_call_refresh()


func _slot_detail(value: String) -> String:
	return "空" if value.is_empty() else value


func _make_card(title: String, detail: String, pos: Vector2, card_size: Vector2, selected: bool) -> Panel:
	var card := Panel.new()
	card.position = pos
	card.size = card_size
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.037, 0.037, 0.94), Color("#D1B850") if selected else Color("#35C9D7"), 2 if selected else 1))
	card.add_child(_make_label(title, Vector2(12, 10), Vector2(card_size.x - 24.0, 24), 16))
	card.add_child(_make_label(detail, Vector2(12, 40), Vector2(card_size.x - 24.0, card_size.y - 46.0), 13))
	return card


func _make_location_card(location: Dictionary, pos: Vector2, card_size: Vector2) -> Panel:
	var location_id := String(location.get("location_id", location.get("map_id", "")))
	var selected := bool(location.get("selected", false))
	var card := Panel.new()
	card.name = "LocationBriefing_%s" % location_id
	card.position = pos
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.037, 0.037, 0.94), Color("#D1B850") if selected else Color("#35C9D7"), 2 if selected else 1))
	card.gui_input.connect(func(event: InputEvent):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_location_card_pressed(location_id)
	)
	card.add_child(_make_label(String(location.get("display_name", location_id)), Vector2(12, 8), Vector2(196, 24), 16))
	card.add_child(_make_label("状态：%s" % String(location.get("state_display_name", location.get("resource_state", ""))), Vector2(214, 8), Vector2(120, 22), 13))
	card.add_child(_make_label("预计容器：%s" % String(location.get("estimated_container_count_text", "?")), Vector2(338, 8), Vector2(138, 22), 13))
	card.add_child(_make_label("主要：%s" % _join_names(Array(location.get("primary_category_names", []))), Vector2(12, 34), Vector2(218, 22), 13))
	card.add_child(_make_label("次要：%s" % _join_names(Array(location.get("secondary_category_names", []))), Vector2(246, 34), Vector2(220, 22), 13))
	card.add_child(_make_label("容器倾向：%s" % _join_names(Array(location.get("typical_container_type_names", []))), Vector2(12, 58), Vector2(278, 22), 13))
	card.add_child(_make_label(String(location.get("state_hint", "")), Vector2(246, 58), Vector2(224, 30), 12))
	return card


func _join_names(values: Array) -> String:
	var names: Array[String] = []
	for value in values:
		var text := String(value)
		if not text.is_empty():
			names.append(text)
	return " / ".join(names) if not names.is_empty() else "未知"


func _call_refresh() -> void:
	if refresh_callback.is_valid():
		refresh_callback.call()


func _clear_panel_body(panel: Panel) -> void:
	for child in panel.get_children():
		if String(child.name) == "PanelTitle":
			continue
		panel.remove_child(child)
		child.queue_free()


func _make_panel(node_name: String, pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.94), Color(0.26, 0.25, 0.23, 0.95), 1))
	var title_label := _make_label(title, Vector2(18, 12), Vector2(panel_size.x - 36.0, 30), 20)
	title_label.name = "PanelTitle"
	panel.add_child(title_label)
	return panel


func _make_label(text: String, pos: Vector2, label_size: Vector2, font_size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#D8D6CE"))
	return label


func _style_button(button: Button, important: bool) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#D8D6CE"))
	var border := Color("#D1B850") if important else Color("#35C9D7")
	button.add_theme_stylebox_override("normal", _panel_style(Color("#071116"), border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#121817"), Color("#D1B850"), 2))


func _panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

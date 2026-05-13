extends Control

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const DialogueServiceScript := preload("res://scripts/dialogue/dialogue_service.gd")
const DialoguePanelScene := preload("res://scenes/ui/DialoguePanel.tscn")
const RunLoadingScreenScene := preload("res://scenes/ui/RunLoadingScreen.tscn")
const FullscreenBackgroundBuilderScript := preload("res://scripts/ui/fullscreen_background_builder.gd")

const TAB_WAREHOUSE := "warehouse"
const TAB_MERCHANT := "merchant"
const TAB_RESEARCH := "research"
const TAB_CRAFTING := "crafting"
const BASE_BACKGROUND_PATH := "res://assets/originalphoto/basementphoto.png"
const WORLD_INTRO_DIALOGUE_PATH := "res://setting/dialogues.tab#world_intro_dialogue"
const FIRST_DEPARTURE_DIALOGUE_PATH := "res://setting/dialogues.tab#first_departure_outpost_dialogue"
const FIRST_RETURN_DIALOGUE_PATH := "res://setting/dialogues.tab#first_return_chapter_1"
const MANUFACTURING_UNLOCK_COST := 5000
const BASE_GRID_COLUMNS := 5
const BASE_GRID_SLOT_SIZE := 62.0
const BASE_GRID_SLOT_GAP := 10.0
const BASE_GRID_FOOTER_HEIGHT := 28.0
const RESEARCH_NODE_SIZE := 70.0
const RESEARCH_NODE_GAP := 116.0
const RESEARCH_ROW_HEIGHT := 106.0
const RESEARCH_MATERIAL_SLOT_WIDTH := 64.0
const RESEARCH_MATERIAL_SLOT_HEIGHT := 58.0
const RESEARCH_MATERIAL_SLOT_GAP := 14.0
const RESEARCH_MATERIAL_ROW_GAP := 14.0
const ITEM_TOOLTIP_DELAY_SECONDS := 0.15
const ITEM_TOOLTIP_MARGIN := 16.0

@onready var warehouse_tab_button: Button = %WarehouseTabButton
@onready var merchant_tab_button: Button = %MerchantTabButton
@onready var research_tab_button: Button = %ResearchTabButton
@onready var crafting_tab_button: Button = %CraftingTabButton
@onready var start_button: Button = %StartRunButton
@onready var warehouse_label: RichTextLabel = %WarehouseLabel
@onready var merchant_panel: Panel = %MerchantPanel
@onready var merchant_list: RichTextLabel = %MerchantList
@onready var shop_stock_list: RichTextLabel = %ShopStockList
@onready var research_panel: Panel = %ResearchPanel
@onready var research_list: RichTextLabel = %ResearchList
@onready var research_quote_label: Label = %ResearchQuoteLabel
@onready var research_button: Button = %ResearchButton
@onready var research_result_label: Label = %ResearchResultLabel
@onready var research_confirm_dialog: ConfirmationDialog = %ResearchConfirmDialog
@onready var sell_count_spin_box: SpinBox = %SellCountSpinBox
@onready var sell_quote_label: Label = %SellQuoteLabel
@onready var sell_button: Button = %SellButton
@onready var buy_count_spin_box: SpinBox = %BuyCountSpinBox
@onready var buy_quote_label: Label = %BuyQuoteLabel
@onready var buy_button: Button = %BuyButton
@onready var merchant_result_label: Label = %MerchantResultLabel
@onready var result_label: Label = %ResultLabel
@onready var day_label: Label = %DayLabel
@onready var currency_label: Label = %CurrencyLabel
@onready var debug_panel: Panel = %DebugPanel
@onready var debug_add_currency_button: Button = %DebugAddCurrencyButton
@onready var debug_add_sell_items_button: Button = %DebugAddSellItemsButton
@onready var debug_add_research_costs_button: Button = %DebugAddResearchCostsButton
@onready var debug_refresh_shop_button: Button = %DebugRefreshShopButton
@onready var debug_max_shop_button: Button = %DebugMaxShopButton
@onready var debug_complete_research_button: Button = %DebugCompleteResearchButton
@onready var debug_reset_research_button: Button = %DebugResetResearchButton
@onready var debug_result_label: Label = %DebugResultLabel

var _game_state: Node
var _active_tab := TAB_WAREHOUSE
var _selected_sell_group_id := ""
var _selected_shop_offer_id := ""
var _selected_research_id := ""
var _selected_sell_slot_index := -1
var _selected_buy_slot_index := -1
var _debug_registry = GameDataRegistryScript.new()
var _debug_data_loaded := false
var warehouse_panel: Panel
var warehouse_grid_root: Control
var warehouse_status_label: Label
var merchant_sell_grid_root: Control
var merchant_shop_grid_root: Control
var research_scroll: ScrollContainer
var research_tree_root: Control
var research_detail_title_label: Label
var research_detail_description_label: Label
var research_requirement_grid_root: Control
var research_currency_cost_label: Label
var crafting_panel: Panel
var crafting_status_label: Label
var crafting_unlock_button: Button
var crafting_result_label: Label
var chapter_goal_label: Label
var manufacturing_confirm_dialog: ConfirmationDialog
var dialogue_service = DialogueServiceScript.new()
var _active_dialogue_panel: Node
var debug_reset_profile_button: Button
var debug_reset_story_button: Button
var debug_add_chapter_currency_button: Button
var debug_surface_day_button: Button
var debug_force_chapter_complete_button: Button
var debug_force_monster_button: Button
var debug_slow_loading_button: Button
var debug_fail_loading_button: Button
var esc_settings_button: Button
var _esc_settings_popup: Control
var _debug_slow_next_loading := false
var _debug_fail_next_loading := false
var tooltip_layer: Control
var item_tooltip_panel: Panel
var item_tooltip_icon: TextureRect
var item_tooltip_quality_marker: ColorRect
var item_tooltip_name_label: Label
var item_tooltip_price_label: Label
var item_tooltip_description_label: Label
var item_tooltip_timer: Timer
var _tooltip_pending_item: Dictionary = {}
var _tooltip_pending_context: Dictionary = {}
var _tooltip_pending_anchor: Control
var _tooltip_current_anchor: Control
var _tooltip_current_item_id := ""

func _ready() -> void:
	_game_state = get_node_or_null("/root/GameState")
	set_process_input(true)
	_play_base_safe_house_bgm()
	_build_background()
	start_button.pressed.connect(_on_start_pressed)
	warehouse_tab_button.pressed.connect(_on_warehouse_tab_pressed)
	merchant_tab_button.pressed.connect(_on_merchant_tab_pressed)
	research_tab_button.pressed.connect(_on_research_tab_pressed)
	crafting_tab_button.pressed.connect(_on_crafting_tab_pressed)
	warehouse_label.meta_clicked.connect(_on_warehouse_item_meta_clicked)
	merchant_list.meta_clicked.connect(_on_merchant_item_meta_clicked)
	shop_stock_list.meta_clicked.connect(_on_shop_stock_meta_clicked)
	research_list.meta_clicked.connect(_on_research_meta_clicked)
	sell_count_spin_box.value_changed.connect(_on_sell_count_changed)
	sell_button.pressed.connect(_on_sell_pressed)
	buy_count_spin_box.value_changed.connect(_on_buy_count_changed)
	buy_button.pressed.connect(_on_buy_pressed)
	research_button.pressed.connect(_on_research_pressed)
	research_confirm_dialog.confirmed.connect(_on_research_confirmed)
	if _is_debug_panel_enabled():
		debug_add_currency_button.pressed.connect(_on_debug_add_currency_pressed)
		debug_add_sell_items_button.pressed.connect(_on_debug_add_sell_items_pressed)
		debug_add_research_costs_button.pressed.connect(_on_debug_add_research_costs_pressed)
		debug_refresh_shop_button.pressed.connect(_on_debug_refresh_shop_pressed)
		debug_max_shop_button.pressed.connect(_on_debug_max_shop_pressed)
		debug_complete_research_button.pressed.connect(_on_debug_complete_research_pressed)
		debug_reset_research_button.pressed.connect(_on_debug_reset_research_pressed)
	elif debug_panel != null:
		debug_panel.visible = false
	_build_visual_surfaces()
	if _is_debug_panel_enabled():
		_build_debug_story_tools()
	_build_esc_settings_button()
	_refresh()
	call_deferred("_maybe_show_base_story_dialogue")

func _input(event: InputEvent) -> void:
	if not _is_escape_pressed(event):
		return
	if _close_esc_settings_popup():
		get_viewport().set_input_as_handled()
		return
	if _can_open_esc_settings_popup():
		_show_esc_settings_popup()
		get_viewport().set_input_as_handled()

func _build_background() -> void:
	if get_node_or_null("BaseBackground") != null:
		return
	FullscreenBackgroundBuilderScript.add_image_background(
		self,
		BASE_BACKGROUND_PATH,
		"BaseBackground",
		Color("#1A1917"),
		Color(0.0, 0.0, 0.0, 0.34)
	)

func _on_start_pressed() -> void:
	_request_start_run()

func _on_warehouse_tab_pressed() -> void:
	_show_tab(TAB_WAREHOUSE)

func _on_merchant_tab_pressed() -> void:
	_show_tab(TAB_MERCHANT)

func _on_research_tab_pressed() -> void:
	_show_tab(TAB_RESEARCH)

func _on_crafting_tab_pressed() -> void:
	if not _is_crafting_tab_available():
		_show_tab(TAB_WAREHOUSE)
		return
	_show_tab(TAB_CRAFTING)

func _request_start_run() -> void:
	if _is_dialogue_playing():
		return
	if _game_state != null and _game_state.has_method("should_play_first_departure_outpost_dialogue") and _game_state.should_play_first_departure_outpost_dialogue():
		_play_dialogue(FIRST_DEPARTURE_DIALOGUE_PATH, Callable(self, "_on_first_departure_dialogue_finished"))
		return
	_begin_run_loading()

func _on_first_departure_dialogue_finished(_dialogue_id: String = "", _skipped: bool = false) -> void:
	if _game_state != null and _game_state.has_method("mark_first_departure_outpost_dialogue_seen"):
		_game_state.mark_first_departure_outpost_dialogue_seen()
	_begin_run_loading()

func _begin_run_loading() -> void:
	var loading = RunLoadingScreenScene.instantiate()
	add_child(loading)
	loading.loading_completed.connect(_on_run_loading_completed)
	loading.loading_failed.connect(_on_run_loading_failed)
	loading.begin_loading({
		"slow_mode": _debug_slow_next_loading,
		"force_fail": _debug_fail_next_loading,
	})
	_debug_slow_next_loading = false
	_debug_fail_next_loading = false

func _on_run_loading_completed(run_scene: PackedScene) -> void:
	if _game_state != null and _game_state.has_method("commit_run_start"):
		var commit_result: Dictionary = _game_state.commit_run_start(false)
		if not bool(commit_result.get("ok", false)):
			_refresh()
			result_label.visible = true
			result_label.text = "进入地面失败：%s" % String(commit_result.get("reason", "save_failed"))
			return
	if run_scene != null:
		get_tree().change_scene_to_packed(run_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/run/RunScene.tscn")

func _on_run_loading_failed(reason: String) -> void:
	_refresh()
	result_label.visible = true
	result_label.text = "地表通道同步失败，请返回哨所重试。(%s)" % reason

func _maybe_show_base_story_dialogue() -> void:
	if _is_dialogue_playing():
		return
	if _game_state != null and _game_state.has_method("should_play_world_intro_dialogue") and _game_state.should_play_world_intro_dialogue():
		_play_dialogue(WORLD_INTRO_DIALOGUE_PATH, Callable(self, "_on_world_intro_dialogue_finished"))
		return
	_maybe_show_first_return_dialogue()

func _on_world_intro_dialogue_finished(_dialogue_id: String = "", _skipped: bool = false) -> void:
	if _game_state != null and _game_state.has_method("mark_world_intro_dialogue_seen"):
		_game_state.mark_world_intro_dialogue_seen()
	_refresh()
	call_deferred("_maybe_show_first_return_dialogue")

func _maybe_show_first_return_dialogue() -> void:
	if _is_dialogue_playing():
		return
	if _game_state == null or not _game_state.has_method("should_play_first_return_dialogue"):
		return
	if not _game_state.should_play_first_return_dialogue():
		return
	_play_dialogue(FIRST_RETURN_DIALOGUE_PATH, Callable(self, "_on_first_return_dialogue_finished"))

func _on_first_return_dialogue_finished(_dialogue_id: String = "", _skipped: bool = false) -> void:
	if _game_state != null and _game_state.has_method("mark_first_return_dialogue_seen_and_activate_chapter"):
		_game_state.mark_first_return_dialogue_seen_and_activate_chapter()
	_refresh()
	_show_chapter_goal_popup()

func _play_dialogue(path: String, finished_callback: Callable) -> void:
	if _is_dialogue_playing():
		return
	var sequence: Dictionary = dialogue_service.load_sequence(path)
	if sequence.is_empty():
		finished_callback.call("", false)
		return
	start_button.release_focus()
	var panel = DialoguePanelScene.instantiate()
	_active_dialogue_panel = panel
	add_child(panel)
	panel.dialogue_finished.connect(func(dialogue_id: String, skipped: bool):
		if _active_dialogue_panel == panel:
			_active_dialogue_panel = null
		finished_callback.call(dialogue_id, skipped)
	)
	panel.tree_exiting.connect(func():
		if _active_dialogue_panel == panel:
			_active_dialogue_panel = null
	)
	panel.play_sequence(sequence)

func _is_dialogue_playing() -> bool:
	return is_instance_valid(_active_dialogue_panel) and bool(_active_dialogue_panel.get("visible"))

func _play_base_safe_house_bgm() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_base_safe_house_bgm"):
		audio_manager.play_base_safe_house_bgm()

func _is_debug_panel_enabled() -> bool:
	return OS.is_debug_build() and not OS.has_feature("web")

func _show_chapter_goal_popup() -> void:
	var popup := _make_overlay_popup("第一章目标", "解锁制造所\n\n出售可售物资，积攒 5000 矿币。\n制造所解锁后，才有机会推进救出妹妹的计划。")
	var panel := popup.get_node("PopupPanel") as Panel
	var ok_button := _make_popup_button("知道了", Vector2(176, 258), func(): popup.queue_free())
	var merchant_button := _make_popup_button("前往商人", Vector2(332, 258), func():
		popup.queue_free()
		_show_tab(TAB_MERCHANT)
	)
	panel.add_child(ok_button)
	panel.add_child(merchant_button)
	add_child(popup)

func _show_chapter_complete_popup(surface_day: int) -> void:
	var text := "你用了 %d 天，成功购买了旧时代制造机。\n也许，救出妹妹的路终于有了第一盏灯。\n\n第一章节结束，后续章节开发中" % surface_day
	var popup := _make_overlay_popup("第一章结束", text, Vector2(680, 380))
	var panel := popup.get_node("PopupPanel") as Panel
	var continue_button := _make_popup_button("继续游戏", Vector2(200, 300), func(): popup.queue_free())
	var reset_button := _make_popup_button("重新开始", Vector2(356, 300), func():
		_reset_progress_and_show_notice(popup)
	)
	panel.add_child(continue_button)
	panel.add_child(reset_button)
	add_child(popup)

func _make_overlay_popup(title: String, body: String, panel_size: Vector2 = Vector2(640, 340), close_on_blank: bool = false) -> Control:
	var overlay := Control.new()
	overlay.name = "StoryPopupOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "DimLayer"
	dim.color = Color(0, 0, 0, 0.62)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_on_blank:
		dim.gui_input.connect(func(event: InputEvent):
			if _is_left_mouse_pressed(event) and is_instance_valid(overlay):
				overlay.queue_free()
		)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.name = "PopupPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_bottom = panel_size.y * 0.5
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.065, 0.06, 0.98), Color("#D1B850"), 2))
	overlay.add_child(panel)
	var title_label := _make_section_label(title, Vector2(36, 34), Vector2(panel_size.x - 72, 42), 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title_label)
	var body_label := _make_section_label(body, Vector2(58, 96), Vector2(panel_size.x - 116, panel_size.y - 198), 17)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(body_label)
	return overlay

func _make_popup_button(text: String, pos: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(132, 40)
	button.pressed.connect(callback)
	_style_button(button, true)
	return button

func _build_esc_settings_button() -> void:
	if esc_settings_button != null or not has_node("BaseUIRoot"):
		return
	var ui_root := get_node("BaseUIRoot") as Control
	esc_settings_button = Button.new()
	esc_settings_button.name = "EscSettingsButton"
	esc_settings_button.text = "ESC 设置"
	esc_settings_button.anchor_left = 1.0
	esc_settings_button.anchor_right = 1.0
	esc_settings_button.anchor_top = 1.0
	esc_settings_button.anchor_bottom = 1.0
	esc_settings_button.offset_left = -156.0
	esc_settings_button.offset_right = -24.0
	esc_settings_button.offset_top = -58.0
	esc_settings_button.offset_bottom = -20.0
	esc_settings_button.pressed.connect(_show_esc_settings_popup)
	_style_button(esc_settings_button, false)
	ui_root.add_child(esc_settings_button)

func _show_esc_settings_popup() -> void:
	if is_instance_valid(_esc_settings_popup) or _is_dialogue_playing():
		return
	var popup := _make_overlay_popup("设置", "", Vector2(420, 260), true)
	popup.name = "EscSettingsPopupOverlay"
	_esc_settings_popup = popup
	popup.tree_exiting.connect(func():
		if _esc_settings_popup == popup:
			_esc_settings_popup = null
	)
	var panel := popup.get_node("PopupPanel") as Panel
	var settings_button := _make_popup_button("设置", Vector2(70, 172), func():
		popup.queue_free()
		_show_notice_popup("设置", "设置页将在后续版本开放。")
	)
	var reset_button := _make_popup_button("重置进度", Vector2(220, 172), func():
		_reset_progress_and_show_notice(popup)
	)
	panel.add_child(settings_button)
	panel.add_child(reset_button)
	add_child(popup)

func _close_esc_settings_popup() -> bool:
	if not is_instance_valid(_esc_settings_popup):
		return false
	_esc_settings_popup.queue_free()
	_esc_settings_popup = null
	return true

func _can_open_esc_settings_popup() -> bool:
	if _is_dialogue_playing():
		return false
	if (
		get_node_or_null("StoryPopupOverlay") != null
		or get_node_or_null("EscSettingsPopupOverlay") != null
		or get_node_or_null("BaseNoticePopupOverlay") != null
	):
		return false
	return true

func _show_notice_popup(title: String, body: String) -> void:
	var popup := _make_overlay_popup(title, body, Vector2(520, 240), true)
	popup.name = "BaseNoticePopupOverlay"
	var panel := popup.get_node("PopupPanel") as Panel
	var ok_button := _make_popup_button("知道了", Vector2(194, 174), func(): popup.queue_free())
	panel.add_child(ok_button)
	add_child(popup)

func _reset_progress_and_show_notice(popup_to_close: Control = null) -> void:
	if is_instance_valid(popup_to_close):
		popup_to_close.queue_free()
	var result := _reset_local_progress()
	if bool(result.get("ok", false)):
		_refresh()
		_show_notice_popup("重置进度", "进度已重置。请重新登陆或刷新界面后查看重置后的进度。")
	else:
		_show_notice_popup("重置进度", "重置进度失败：%s" % String(result.get("reason", result.get("error", "unknown"))))

func _reset_local_progress() -> Dictionary:
	if _game_state == null:
		return {"ok": false, "reason": "GameState 不可用"}
	if _game_state.has_method("reset_local_data_debug_only"):
		return _game_state.reset_local_data_debug_only()
	if _game_state.has_method("delete_profile_debug_only"):
		return _game_state.delete_profile_debug_only()
	return {"ok": false, "reason": "GameState 不支持重置本地数据"}

func _is_escape_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE

func _is_left_mouse_pressed(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

func _show_tab(tab_id: String) -> void:
	if tab_id == TAB_CRAFTING and not _is_crafting_tab_available():
		tab_id = TAB_WAREHOUSE
	_hide_item_tooltip("switch_tab")
	_active_tab = tab_id
	_refresh()

func _refresh() -> void:
	_refresh_tabs()
	result_label.visible = false
	result_label.text = ""
	if _game_state == null:
		warehouse_label.text = "局外仓库：不可用"
		day_label.text = "第 1 天"
		currency_label.text = "矿币: 0"
		merchant_list.text = "商人系统：不可用"
		shop_stock_list.text = "商人库存：不可用"
		research_list.text = "研究所：不可用"
		research_quote_label.text = "选择一个研究项目"
		research_button.disabled = true
		_update_research_detail({})
		_update_chapter_goal_view()
		_update_crafting_panel()
		merchant_result_label.text = ""
		research_result_label.text = ""
		debug_result_label.text = "GameState 不可用"
		_update_sell_quote({})
		_update_buy_quote({})
		return

	day_label.text = _game_state.get_day_display_text()
	currency_label.text = _game_state.get_currency_display_text("mine_coin")
	_set_warehouse_items_text(_game_state.get_warehouse_items_snapshot())
	_set_merchant_items_text(_game_state.query_sellable_items())
	_set_shop_stock_text(_game_state.query_shop_offers())
	_set_research_items_text(_game_state.query_research_items())
	_update_chapter_goal_view()
	_update_crafting_panel()
	_update_selected_sell_state()
	_update_selected_buy_state()
	_update_selected_research_state()

func _refresh_tabs() -> void:
	_hide_item_tooltip("refresh_tabs")
	var crafting_available := _is_crafting_tab_available()
	if _active_tab == TAB_CRAFTING and not crafting_available:
		_active_tab = TAB_WAREHOUSE
	warehouse_label.visible = false
	if warehouse_panel != null:
		warehouse_panel.visible = _active_tab == TAB_WAREHOUSE
	merchant_panel.visible = _active_tab == TAB_MERCHANT
	research_panel.visible = _active_tab == TAB_RESEARCH
	if crafting_panel != null:
		crafting_panel.visible = _active_tab == TAB_CRAFTING
	warehouse_tab_button.button_pressed = _active_tab == TAB_WAREHOUSE
	merchant_tab_button.button_pressed = _active_tab == TAB_MERCHANT
	research_tab_button.button_pressed = _active_tab == TAB_RESEARCH
	crafting_tab_button.button_pressed = _active_tab == TAB_CRAFTING
	warehouse_tab_button.text = "仓库"
	merchant_tab_button.text = "商人"
	research_tab_button.text = "研究所"
	crafting_tab_button.text = "制造所"
	research_tab_button.disabled = false
	crafting_tab_button.disabled = not crafting_available
	crafting_tab_button.tooltip_text = "" if crafting_available else "完成首次地面返回剧情后解锁制造所。"

func _is_crafting_tab_available() -> bool:
	if _game_state == null:
		return false
	return (
		bool(_game_state.get("chapter_1_goal_active"))
		or bool(_game_state.get("manufacturing_station_unlocked"))
		or bool(_game_state.get("chapter_1_completed"))
	)

func _build_visual_surfaces() -> void:
	var ui_root := get_node("BaseUIRoot") as Control
	_style_top_navigation()
	_build_item_tooltip_layer(ui_root)
	warehouse_label.visible = false
	warehouse_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	merchant_list.visible = false
	merchant_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_stock_list.visible = false
	shop_stock_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	research_list.visible = false
	research_list.mouse_filter = Control.MOUSE_FILTER_IGNORE

	chapter_goal_label = _make_section_label("", Vector2.ZERO, Vector2(236, 82), 15)
	chapter_goal_label.name = "ChapterGoalLabel"
	chapter_goal_label.anchor_left = 1.0
	chapter_goal_label.anchor_right = 1.0
	chapter_goal_label.offset_left = -260.0
	chapter_goal_label.offset_right = -24.0
	chapter_goal_label.offset_top = 92.0
	chapter_goal_label.offset_bottom = 174.0
	chapter_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chapter_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_root.add_child(chapter_goal_label)

	warehouse_panel = _make_base_panel("WarehouseGridPanel", Vector2(24, 154), Vector2(980, 500), "局外仓库")
	var warehouse_scroll := _make_scroll_area(Vector2(18, 58), Vector2(388, 394))
	warehouse_grid_root = Control.new()
	warehouse_scroll.add_child(warehouse_grid_root)
	warehouse_panel.add_child(warehouse_scroll)
	warehouse_status_label = _make_section_label("空仓位会显示为细框。每个格子只放一个道具。", Vector2(436, 62), Vector2(500, 96), 16)
	warehouse_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse_panel.add_child(warehouse_status_label)
	ui_root.add_child(warehouse_panel)

	_build_merchant_surface()
	_build_research_surface()
	_build_crafting_surface()

func _build_item_tooltip_layer(ui_root: Control) -> void:
	if tooltip_layer != null:
		return
	tooltip_layer = Control.new()
	tooltip_layer.name = "TooltipLayer"
	tooltip_layer.anchor_left = 0.0
	tooltip_layer.anchor_top = 0.0
	tooltip_layer.anchor_right = 1.0
	tooltip_layer.anchor_bottom = 1.0
	tooltip_layer.offset_left = 0.0
	tooltip_layer.offset_top = 0.0
	tooltip_layer.offset_right = 0.0
	tooltip_layer.offset_bottom = 0.0
	tooltip_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_layer.z_index = 100
	ui_root.add_child(tooltip_layer)

	item_tooltip_panel = Panel.new()
	item_tooltip_panel.name = "ItemTooltipPanel"
	item_tooltip_panel.visible = false
	item_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.033, 0.032, 0.95), Color("#2B8F99"), 1))
	tooltip_layer.add_child(item_tooltip_panel)

	item_tooltip_icon = TextureRect.new()
	item_tooltip_icon.name = "ItemTooltipIcon"
	item_tooltip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_tooltip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_tooltip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(item_tooltip_icon)

	item_tooltip_quality_marker = ColorRect.new()
	item_tooltip_quality_marker.name = "QualityMarker"
	item_tooltip_quality_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(item_tooltip_quality_marker)

	item_tooltip_name_label = _make_section_label("", Vector2.ZERO, Vector2(120, 30), 18)
	item_tooltip_name_label.name = "ItemTooltipName"
	item_tooltip_name_label.clip_text = true
	item_tooltip_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(item_tooltip_name_label)

	item_tooltip_price_label = _make_section_label("", Vector2.ZERO, Vector2(92, 30), 15)
	item_tooltip_price_label.name = "ItemTooltipPrice"
	item_tooltip_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_tooltip_price_label.clip_text = true
	item_tooltip_price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(item_tooltip_price_label)

	var divider := ColorRect.new()
	divider.name = "ItemTooltipDivider"
	var divider_color := Color("#2B8F99")
	divider_color.a = 0.72
	divider.color = divider_color
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(divider)

	item_tooltip_description_label = _make_section_label("", Vector2.ZERO, Vector2(190, 120), 14)
	item_tooltip_description_label.name = "ItemTooltipDescription"
	item_tooltip_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_tooltip_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_tooltip_panel.add_child(item_tooltip_description_label)

	item_tooltip_timer = Timer.new()
	item_tooltip_timer.name = "ItemTooltipDelayTimer"
	item_tooltip_timer.one_shot = true
	item_tooltip_timer.wait_time = ITEM_TOOLTIP_DELAY_SECONDS
	item_tooltip_timer.timeout.connect(_on_item_tooltip_delay_timeout)
	tooltip_layer.add_child(item_tooltip_timer)

func _style_top_navigation() -> void:
	var tabs: Array[Button] = [warehouse_tab_button, merchant_tab_button, research_tab_button, crafting_tab_button]
	var left := 24.0
	for index in range(tabs.size()):
		var button := tabs[index]
		button.toggle_mode = true
		button.position = Vector2(left + float(index) * 120.0, 96)
		button.size = Vector2(108, 42)
		_style_button(button, false)
	_style_button(start_button, true)
	start_button.position = Vector2(528, 96)
	start_button.size = Vector2(140, 42)
	result_label.visible = false
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day_label.anchor_left = 0.0
	day_label.anchor_right = 1.0
	day_label.anchor_top = 0.0
	day_label.anchor_bottom = 0.0
	day_label.offset_left = 0.0
	day_label.offset_right = 0.0
	day_label.offset_top = 22.0
	day_label.offset_bottom = 66.0
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(day_label, 30, Color("#D8D6CE"))
	_style_label(currency_label, 18, Color("#D1B850"))

func _build_merchant_surface() -> void:
	_set_control_rect(merchant_panel, Vector2(24, 154), Vector2(980, 500))
	merchant_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	merchant_panel.add_child(_make_section_label("局外商人", Vector2(18, 12), Vector2(160, 30), 20))
	merchant_panel.add_child(_make_section_label("商人库存", Vector2(18, 48), Vector2(180, 24), 16))
	merchant_panel.add_child(_make_section_label("仓库可售", Vector2(410, 48), Vector2(180, 24), 16))
	var buy_scroll := _make_scroll_area(Vector2(18, 78), Vector2(376, 348))
	merchant_shop_grid_root = Control.new()
	buy_scroll.add_child(merchant_shop_grid_root)
	merchant_panel.add_child(buy_scroll)
	var sell_scroll := _make_scroll_area(Vector2(410, 78), Vector2(376, 348))
	merchant_sell_grid_root = Control.new()
	sell_scroll.add_child(merchant_sell_grid_root)
	merchant_panel.add_child(sell_scroll)

	merchant_panel.add_child(_make_section_label("出售数量", Vector2(812, 76), Vector2(130, 22), 15))
	_set_control_rect(sell_count_spin_box, Vector2(812, 102), Vector2(120, 32))
	_set_control_rect(sell_quote_label, Vector2(812, 146), Vector2(150, 92))
	_set_control_rect(sell_button, Vector2(812, 248), Vector2(120, 38))
	merchant_panel.add_child(_make_section_label("购买数量", Vector2(812, 304), Vector2(130, 22), 15))
	_set_control_rect(buy_count_spin_box, Vector2(812, 330), Vector2(120, 32))
	_set_control_rect(buy_quote_label, Vector2(812, 374), Vector2(150, 70))
	_set_control_rect(buy_button, Vector2(812, 450), Vector2(120, 38))
	_set_control_rect(merchant_result_label, Vector2(18, 438), Vector2(768, 46))
	_style_button(sell_button, true)
	_style_button(buy_button, true)
	_style_label(sell_quote_label, 15, Color("#D8D6CE"))
	_style_label(buy_quote_label, 15, Color("#D8D6CE"))
	_style_label(merchant_result_label, 15, Color("#8DB6B9"))

func _build_research_surface() -> void:
	_set_control_rect(research_panel, Vector2(24, 154), Vector2(980, 500))
	research_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	research_panel.add_child(_make_section_label("研究所", Vector2(18, 12), Vector2(160, 30), 20))
	research_scroll = _make_scroll_area(Vector2(18, 56), Vector2(730, 400), true)
	research_tree_root = Control.new()
	research_scroll.add_child(research_tree_root)
	research_panel.add_child(research_scroll)

	research_quote_label.visible = false
	research_quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	research_detail_title_label = _make_section_label("研究所", Vector2(770, 30), Vector2(180, 40), 28)
	research_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	research_panel.add_child(research_detail_title_label)
	research_detail_description_label = _make_section_label("", Vector2(752, 84), Vector2(220, 58), 14)
	research_detail_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	research_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	research_panel.add_child(research_detail_description_label)
	research_requirement_grid_root = Control.new()
	research_requirement_grid_root.position = Vector2(752, 156)
	research_requirement_grid_root.size = Vector2(220, 130)
	research_panel.add_child(research_requirement_grid_root)
	research_currency_cost_label = _make_section_label("", Vector2(752, 304), Vector2(220, 26), 15)
	research_currency_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	research_panel.add_child(research_currency_cost_label)
	_set_control_rect(research_button, Vector2(797, 338), Vector2(130, 36))
	_set_control_rect(research_result_label, Vector2(752, 386), Vector2(220, 74))
	_style_button(research_button, true)
	_style_label(research_result_label, 15, Color("#8DB6B9"))
	research_button.text = "研发"

func _build_crafting_surface() -> void:
	var ui_root := get_node("BaseUIRoot") as Control
	crafting_panel = _make_base_panel("CraftingPanel", Vector2(24, 154), Vector2(980, 500), "制造所")
	crafting_panel.visible = false
	crafting_status_label = _make_section_label("", Vector2(36, 70), Vector2(650, 190), 18)
	crafting_status_label.name = "CraftingStatusLabel"
	crafting_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_panel.add_child(crafting_status_label)
	crafting_unlock_button = Button.new()
	crafting_unlock_button.name = "CraftingUnlockButton"
	crafting_unlock_button.text = "解锁制造所"
	crafting_unlock_button.position = Vector2(36, 286)
	crafting_unlock_button.size = Vector2(160, 42)
	crafting_unlock_button.pressed.connect(_on_crafting_unlock_pressed)
	_style_button(crafting_unlock_button, true)
	crafting_panel.add_child(crafting_unlock_button)
	crafting_result_label = _make_section_label("", Vector2(36, 350), Vector2(620, 80), 15)
	crafting_result_label.name = "CraftingResultLabel"
	crafting_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_panel.add_child(crafting_result_label)
	ui_root.add_child(crafting_panel)

	manufacturing_confirm_dialog = ConfirmationDialog.new()
	manufacturing_confirm_dialog.name = "ManufacturingConfirmDialog"
	manufacturing_confirm_dialog.title = "确认解锁制造所"
	manufacturing_confirm_dialog.ok_button_text = "确认解锁"
	manufacturing_confirm_dialog.cancel_button_text = "取消"
	manufacturing_confirm_dialog.confirmed.connect(_on_manufacturing_unlock_confirmed)
	ui_root.add_child(manufacturing_confirm_dialog)

func _build_debug_story_tools() -> void:
	if debug_panel == null:
		return
	debug_panel.offset_top = 190.0
	debug_panel.offset_bottom = 876.0
	debug_reset_profile_button = _make_debug_button("重置本地数据", 356.0, _on_debug_reset_profile_pressed)
	debug_reset_story_button = _make_debug_button("重置剧情与章节", 398.0, _on_debug_reset_story_pressed)
	debug_add_chapter_currency_button = _make_debug_button("+5000 矿币", 440.0, _on_debug_add_chapter_currency_pressed)
	debug_surface_day_button = _make_debug_button("地表天数 +1", 482.0, _on_debug_surface_day_pressed)
	debug_force_chapter_complete_button = _make_debug_button("强制完成第一章", 524.0, _on_debug_force_chapter_complete_pressed)
	debug_slow_loading_button = _make_debug_button("下次慢加载", 566.0, _on_debug_slow_loading_pressed)
	debug_fail_loading_button = _make_debug_button("下次加载失败", 608.0, _on_debug_fail_loading_pressed)
	debug_force_monster_button = _make_debug_button("本日必出怪物", 650.0, _on_debug_force_monster_pressed)
	_set_control_rect(debug_result_label, Vector2(12, 696), Vector2(204, 58))

func _make_debug_button(text: String, y: float, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.name = "Debug%sButton" % text.sha256_text().substr(0, 8)
	button.position = Vector2(12, y)
	button.size = Vector2(204, 32)
	button.pressed.connect(callback)
	debug_panel.add_child(button)
	return button

func _set_control_rect(control: Control, pos: Vector2, control_size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = pos
	control.size = control_size

func _make_base_panel(node_name: String, pos: Vector2, panel_size: Vector2, title: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	panel.add_child(_make_section_label(title, Vector2(18, 12), Vector2(panel_size.x - 36.0, 30), 20))
	return panel

func _make_scroll_area(pos: Vector2, scroll_size: Vector2, horizontal_enabled: bool = false) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.position = pos
	scroll.size = scroll_size
	scroll.clip_contents = true
	if not horizontal_enabled:
		scroll.set("horizontal_scroll_mode", 0)
	scroll.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.03, 0.78), Color(0.16, 0.20, 0.20, 0.9), 1))
	return scroll

func _make_section_label(text: String, pos: Vector2, label_size: Vector2, font_size: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	_style_label(label, font_size, Color("#D8D6CE"))
	return label

func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _style_button(button: Button, important: bool) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#D8D6CE"))
	var border := Color("#D1B850") if important else Color("#35C9D7")
	button.add_theme_stylebox_override("normal", _panel_style(Color("#071116"), border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#121817"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.06, 0.06, 0.058, 0.55), Color("#4D575B"), 1))

func _set_warehouse_items_text(items: Array) -> void:
	warehouse_label.clear()
	var capacity: int = _game_state.get_warehouse_capacity() if _game_state != null and _game_state.has_method("get_warehouse_capacity") else items.size()
	var max_capacity := capacity
	if _game_state != null and _game_state.has_method("get_warehouse_max_capacity"):
		max_capacity = int(_game_state.get_warehouse_max_capacity())
	_set_item_grid(warehouse_grid_root, items, max_capacity, TAB_WAREHOUSE, capacity)
	if warehouse_status_label != null:
		warehouse_status_label.text = "仓库容量：%d/%d\n格子规则：每格 1 个道具，不堆叠。" % [items.size(), capacity]
	if items.is_empty():
		warehouse_label.append_text("局外仓库：空（0/%d）" % capacity)
		return
	var lines: Array[String] = ["局外仓库：%d/%d" % [items.size(), capacity]]
	for index in range(items.size()):
		var item = items[index]
		if item is Dictionary:
			var name := String(item.get("display_name", item.get("item_id", "")))
			var weight := float(item.get("weight_per_unit", 0.0))
			lines.append("[url=warehouse:%d]- 第 %d 格：%s  单重 %.2f[/url]" % [index, index + 1, name, weight])
	warehouse_label.append_text("\n".join(lines))

func _set_merchant_items_text(items: Array) -> void:
	merchant_list.clear()
	var sell_slots := _expand_sell_groups_to_slots(items)
	_set_item_grid(merchant_sell_grid_root, sell_slots, maxi(10, sell_slots.size()), "sell")
	if items.is_empty():
		merchant_list.append_text("商人：暂无可出售道具")
		return
	var lines: Array[String] = ["可出售道具："]
	for item in items:
		if item is Dictionary:
			var group_id := String(item.get("warehouse_item_id", ""))
			var name := String(item.get("display_name", item.get("item_id", "")))
			var count := int(item.get("count", 0))
			var unit_value := int(item.get("sell_value", 0))
			var currency_id := String(item.get("sell_currency_id", "mine_coin"))
			lines.append("[url=sell:%s]- %s x%d  单价 %d %s[/url]" % [group_id, name, count, unit_value, _currency_name(currency_id)])
	merchant_list.append_text("\n".join(lines))

func _set_shop_stock_text(items: Array) -> void:
	shop_stock_list.clear()
	var level_text := "Lv.%d" % (_game_state.get_merchant_shop_level() if _game_state != null else 1)
	var shop_slots := _expand_shop_offers_to_slots(items)
	_set_item_grid(merchant_shop_grid_root, shop_slots, maxi(10, shop_slots.size()), "buy")
	if items.is_empty():
		shop_stock_list.append_text("商人库存 %s：暂无资源" % level_text)
		return
	var lines: Array[String] = ["商人库存 %s：" % level_text]
	for item in items:
		if item is Dictionary:
			var offer_id := String(item.get("shop_offer_id", ""))
			var name := String(item.get("display_name", item.get("item_id", "")))
			var count := int(item.get("count", 0))
			var unit_price := int(item.get("buy_price", 0))
			var currency_id := String(item.get("buy_currency_id", "mine_coin"))
			lines.append("[url=buy:%s]- %s x%d  单价 %d %s[/url]" % [offer_id, name, count, unit_price, _currency_name(currency_id)])
	shop_stock_list.append_text("\n".join(lines))

func _set_research_items_text(items: Array) -> void:
	research_list.clear()
	_set_research_tree(items)
	if items.is_empty():
		research_list.append_text("研究所：暂无研究项目")
		return
	var lines: Array[String] = ["研究所："]
	for item in items:
		if item is Dictionary:
			var research_id := String(item.get("research_id", ""))
			var name := String(item.get("display_name", research_id))
			var current_level := int(item.get("current_level", 0))
			var max_level := int(item.get("max_level", 0))
			var effect_text := _format_research_effect(String(item.get("effect_type", "")), float(item.get("effect_value", 0.0)))
			var status := String(item.get("status", "LOCKED"))
			var status_text := "可研究" if bool(item.get("can_research", false)) else "材料不足"
			if status == "COMPLETED":
				status_text = "已满级"
			lines.append("[url=research:%s]- %s Lv.%d/%d  %s  %s[/url]" % [
				research_id,
				name,
				current_level,
				max_level,
				effect_text,
				status_text,
			])
	research_list.append_text("\n".join(lines))

func _expand_sell_groups_to_slots(groups: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group in groups:
		if not (group is Dictionary):
			continue
		var group_dict: Dictionary = group
		var count := maxi(0, int(group_dict.get("count", 0)))
		var group_id := String(group_dict.get("warehouse_item_id", ""))
		for _index in range(count):
			var slot: Dictionary = group_dict.duplicate(true)
			slot["amount"] = 1
			slot["grid_meta_id"] = group_id
			result.append(slot)
	return result

func _expand_shop_offers_to_slots(offers: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for offer in offers:
		if not (offer is Dictionary):
			continue
		var offer_dict: Dictionary = offer
		var count := maxi(0, int(offer_dict.get("count", 0)))
		var offer_id := String(offer_dict.get("shop_offer_id", ""))
		for _index in range(count):
			var slot: Dictionary = offer_dict.duplicate(true)
			slot["amount"] = 1
			slot["grid_meta_id"] = offer_id
			result.append(slot)
	return result

func _set_item_grid(grid_root: Control, items: Array, capacity: int, source_id: String, unlocked_slots: int = -1) -> void:
	if grid_root == null:
		return
	_hide_item_tooltip("grid_refresh")
	for child in grid_root.get_children():
		grid_root.remove_child(child)
		child.queue_free()
	capacity = maxi(capacity, items.size())
	if unlocked_slots < 0:
		unlocked_slots = capacity
	unlocked_slots = clampi(unlocked_slots, 0, capacity)
	var columns := BASE_GRID_COLUMNS
	var slot_size := BASE_GRID_SLOT_SIZE
	var gap := BASE_GRID_SLOT_GAP
	var display_slots := maxi(capacity, 1)
	var rows := ceili(float(display_slots) / float(columns))
	var grid_width := float(columns) * slot_size + float(columns - 1) * gap
	var grid_height := float(rows) * slot_size + float(rows - 1) * gap + BASE_GRID_FOOTER_HEIGHT
	grid_root.custom_minimum_size = Vector2(grid_width, grid_height)
	grid_root.size = grid_root.custom_minimum_size
	for index in range(display_slots):
		var col := index % columns
		var row := int(index / columns)
		var slot_pos := Vector2(float(col) * (slot_size + gap), float(row) * (slot_size + gap))
		var item: Variant = items[index] if index < items.size() else null
		var locked := index >= unlocked_slots
		if item is Dictionary:
			grid_root.add_child(_make_base_item_slot(slot_pos, Vector2(slot_size, slot_size), item, index, source_id, locked))
		else:
			grid_root.add_child(_make_base_empty_slot(slot_pos, Vector2(slot_size, slot_size), locked))
	grid_root.add_child(_make_grid_footer(Vector2(0, grid_height - BASE_GRID_FOOTER_HEIGHT + 4.0), Vector2(grid_width, 22), items.size(), unlocked_slots))

func _make_base_item_slot(pos: Vector2, slot_size: Vector2, item: Dictionary, index: int, source_id: String, locked: bool = false) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = slot_size
	button.text = ""
	button.clip_text = false
	button.tooltip_text = _slot_tooltip(item, source_id)
	button.set_meta("ui_click_sfx", "ui_item_click")
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", _quality_color(item))
	var meta_id := String(item.get("grid_meta_id", str(index)))
	var selected := (
		source_id == "sell"
		and meta_id == _selected_sell_group_id
		and index == _selected_sell_slot_index
	) or (
		source_id == "buy"
		and meta_id == _selected_shop_offer_id
		and index == _selected_buy_slot_index
	)
	var border_color := Color("#D1B850") if selected else Color("#35C9D7")
	var border_width := 3 if selected else 2
	var normal_bg := Color("#151819") if locked else Color("#071116")
	var normal_border := Color("#4D575B") if locked else border_color
	button.disabled = locked
	button.set_meta("warehouse_slot_locked", locked)
	button.add_theme_stylebox_override("normal", _slot_style(normal_bg, normal_border, border_width))
	button.add_theme_stylebox_override("hover", _slot_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _slot_style(Color("#121817"), Color("#D1B850"), 3))
	button.add_theme_stylebox_override("disabled", _slot_style(Color("#151819"), Color("#4D575B"), 1))
	_add_base_item_slot_content(button, slot_size, item, source_id)
	_bind_base_item_tooltip(button, item, source_id)
	if not locked:
		button.button_up.connect(func(): _dispatch_grid_slot(source_id, meta_id, index))
	return button

func _make_base_empty_slot(pos: Vector2, slot_size: Vector2, locked: bool = false) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = slot_size
	panel.set_meta("warehouse_slot_locked", locked)
	var bg_color := Color("#151819") if locked else Color("#071116")
	var border_color := Color("#4D575B") if locked else Color("#354145")
	panel.add_theme_stylebox_override("panel", _slot_style(bg_color, border_color, 1))
	return panel

func _make_grid_footer(pos: Vector2, footer_size: Vector2, used: int, capacity: int) -> Label:
	var footer := Label.new()
	footer.position = pos
	footer.size = footer_size
	footer.text = "容量：%d/%d" % [used, capacity]
	_style_label(footer, 15, Color("#8DB6B9"))
	return footer

func _slot_text(item: Dictionary, source_id: String) -> String:
	var name := String(item.get("display_name", item.get("item_id", "")))
	match source_id:
		"sell":
			return "%s\n%d %s" % [name, int(item.get("sell_value", 0)), _currency_name(String(item.get("sell_currency_id", "mine_coin")))]
		"buy":
			return "%s\n%d %s" % [name, int(item.get("buy_price", 0)), _currency_name(String(item.get("buy_currency_id", "mine_coin")))]
		_:
			return "%s" % name

func _add_base_item_slot_content(button: Button, slot_size: Vector2, item: Dictionary, source_id: String) -> void:
	var texture := _item_icon_texture(item)
	var label_height := clampf(slot_size.y * 0.28, 12.0, 18.0)
	var icon_size := maxf(18.0, minf(slot_size.x - 12.0, slot_size.y - label_height - 6.0))
	var content_height := icon_size + 2.0 + label_height
	var icon_pos := Vector2((slot_size.x - icon_size) * 0.5, maxf(2.0, (slot_size.y - content_height) * 0.38))
	if texture != null:
		var icon := TextureRect.new()
		icon.position = icon_pos
		icon.size = Vector2(icon_size, icon_size)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.position = icon_pos
		fallback.size = Vector2(icon_size, icon_size)
		fallback.text = String(item.get("quality", "C"))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 18)
		fallback.add_theme_color_override("font_color", _quality_color(item))
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(fallback)

	_add_slot_text_box(
		button,
		_slot_display_name(String(item.get("display_name", item.get("item_id", "")))),
		Vector2(3.0, minf(slot_size.y - label_height - 2.0, icon_pos.y + icon_size + 2.0)),
		Vector2(slot_size.x - 6.0, label_height),
		8,
		_quality_color(item)
	)

func _item_icon_texture(item: Dictionary) -> Texture2D:
	var icon_path := String(item.get("icon", ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	var resource := load(icon_path)
	return resource as Texture2D

func _add_slot_text_box(button: Button, text: String, pos: Vector2, box_size: Vector2, font_size: int, color: Color) -> void:
	var box := Control.new()
	box.position = pos
	box.size = box_size
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.custom_minimum_size = Vector2.ZERO
	label.position = Vector2(0.0, -4.0)
	label.size = Vector2(box_size.x, box_size.y + 8.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)

func _compact_item_name(name: String) -> String:
	if name.length() <= 4:
		return name
	return name.substr(0, 4) + "..."

func _slot_display_name(name: String) -> String:
	if name.length() <= 6:
		return name
	return name.substr(0, 6)

func _slot_tooltip(item: Dictionary, source_id: String) -> String:
	var name := String(item.get("display_name", item.get("item_id", "")))
	var quality := String(item.get("quality", "C"))
	match source_id:
		"sell":
			return "%s\n品质：%s\n出售：%d %s" % [
				name,
				quality,
				int(item.get("sell_value", 0)),
				_currency_name(String(item.get("sell_currency_id", "mine_coin"))),
			]
		"buy":
			return "%s\n品质：%s\n购买：%d %s" % [
				name,
				quality,
				int(item.get("buy_price", 0)),
				_currency_name(String(item.get("buy_currency_id", "mine_coin"))),
			]
		_:
			return "%s\n品质：%s\n单格道具" % [name, quality]

func _bind_base_item_tooltip(anchor: Control, item: Dictionary, source_id: String, context: Dictionary = {}) -> void:
	if anchor == null:
		return
	anchor.tooltip_text = ""
	anchor.mouse_filter = Control.MOUSE_FILTER_STOP
	var tooltip_context := context.duplicate(true)
	if not tooltip_context.has("context"):
		tooltip_context["context"] = source_id
	anchor.mouse_entered.connect(func(): _queue_item_tooltip(item, anchor, tooltip_context))
	anchor.mouse_exited.connect(func(): _hide_item_tooltip_for_anchor(anchor, "mouse_exited"))

func _queue_item_tooltip(item: Dictionary, anchor: Control, context: Dictionary = {}) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	_tooltip_pending_item = item.duplicate(true)
	_tooltip_pending_context = context.duplicate(true)
	_tooltip_pending_anchor = anchor
	if item_tooltip_timer != null:
		item_tooltip_timer.start(ITEM_TOOLTIP_DELAY_SECONDS)

func _on_item_tooltip_delay_timeout() -> void:
	if _tooltip_pending_anchor == null or not is_instance_valid(_tooltip_pending_anchor):
		_hide_item_tooltip("anchor_gone")
		return
	_show_item_tooltip(_tooltip_pending_item, _tooltip_pending_anchor, _tooltip_pending_context)

func _show_item_tooltip(item: Dictionary, anchor: Control, context: Dictionary = {}) -> void:
	if item_tooltip_panel == null or anchor == null or not is_instance_valid(anchor):
		return
	var data := _build_item_tooltip_data(item, context)
	if data.is_empty():
		_hide_item_tooltip("empty_data")
		return
	_tooltip_current_anchor = anchor
	_tooltip_current_item_id = String(data.get("item_id", ""))
	_apply_item_tooltip_data(data)
	_position_item_tooltip(anchor)
	item_tooltip_panel.visible = true

func _hide_item_tooltip_for_anchor(anchor: Control, reason: String = "") -> void:
	if anchor == _tooltip_pending_anchor or anchor == _tooltip_current_anchor:
		_hide_item_tooltip(reason)

func _hide_item_tooltip(_reason: String = "") -> void:
	if item_tooltip_timer != null:
		item_tooltip_timer.stop()
	_tooltip_pending_item = {}
	_tooltip_pending_context = {}
	_tooltip_pending_anchor = null
	_tooltip_current_anchor = null
	_tooltip_current_item_id = ""
	if item_tooltip_panel != null:
		item_tooltip_panel.visible = false

func _build_item_tooltip_data(item: Dictionary, context: Dictionary = {}) -> Dictionary:
	var item_id := String(item.get("item_id", ""))
	if item_id.is_empty() and item.has("warehouse_item_id"):
		item_id = String(item.get("warehouse_item_id", ""))
	if item_id.is_empty():
		if OS.is_debug_build():
			push_warning("Item tooltip missing item_id for context %s." % String(context.get("context", "")))
			return {
				"item_id": "missing_item",
				"display_name": "未知道具",
				"quality": "C",
				"icon": "",
				"price_text": "不可出售",
				"sellable": false,
				"description": "Tooltip 缺少 item_id。",
			}
		return {}
	if not _ensure_debug_data_loaded():
		return {}
	var definition := _debug_registry.get_item(item_id)
	if definition.is_empty():
		if OS.is_debug_build():
			push_warning("Item tooltip cannot find item_id: %s." % item_id)
			return {
				"item_id": item_id,
				"display_name": item_id,
				"quality": "C",
				"icon": String(item.get("icon", "")),
				"price_text": "不可出售",
				"sellable": false,
				"description": "items.tab 中没有这个道具定义。",
			}
		return {}
	var sellable := _parse_bool(definition.get("sellable", item.get("sellable", false)))
	var sell_value := int(definition.get("sell_value", item.get("sell_value", 0)))
	var currency_id := String(definition.get("sell_currency_id", item.get("sell_currency_id", "mine_coin")))
	var description := String(definition.get("description", item.get("description", "")))
	if description.strip_edges().is_empty():
		description = "暂无记录。"
	return {
		"item_id": item_id,
		"display_name": String(definition.get("name", item.get("display_name", item_id))),
		"quality": String(definition.get("quality", item.get("quality", "C"))),
		"icon": String(definition.get("icon", item.get("icon", ""))),
		"price_text": "%d%s" % [sell_value, _currency_name(currency_id)] if sellable and sell_value > 0 else "不可出售",
		"sellable": sellable and sell_value > 0,
		"description": description,
	}

func _apply_item_tooltip_data(data: Dictionary) -> void:
	var tooltip_size := _item_tooltip_size()
	var icon_size := _item_tooltip_icon_size()
	item_tooltip_panel.size = tooltip_size
	item_tooltip_icon.position = Vector2((tooltip_size.x - icon_size) * 0.5, 24.0)
	item_tooltip_icon.size = Vector2(icon_size, icon_size)
	item_tooltip_icon.texture = _tooltip_icon_texture(String(data.get("icon", "")))
	item_tooltip_quality_marker.position = Vector2(18.0, icon_size + 54.0)
	item_tooltip_quality_marker.size = Vector2(5.0, 18.0)
	item_tooltip_quality_marker.color = _quality_name_color(String(data.get("quality", "C")))
	item_tooltip_name_label.position = Vector2(28.0, icon_size + 48.0)
	item_tooltip_name_label.size = Vector2(tooltip_size.x - 128.0, 30.0)
	item_tooltip_name_label.text = String(data.get("display_name", ""))
	item_tooltip_name_label.add_theme_color_override("font_color", _quality_name_color(String(data.get("quality", "C"))))
	item_tooltip_price_label.position = Vector2(tooltip_size.x - 96.0, icon_size + 50.0)
	item_tooltip_price_label.size = Vector2(78.0, 26.0)
	item_tooltip_price_label.text = String(data.get("price_text", ""))
	item_tooltip_price_label.add_theme_color_override("font_color", Color("#D8D6CE") if bool(data.get("sellable", false)) else Color("#7D8586"))
	var divider := item_tooltip_panel.get_node_or_null("ItemTooltipDivider") as ColorRect
	if divider != null:
		divider.position = Vector2(18.0, icon_size + 83.0)
		divider.size = Vector2(tooltip_size.x - 36.0, 1.0)
	item_tooltip_description_label.position = Vector2(18.0, icon_size + 118.0)
	item_tooltip_description_label.size = Vector2(tooltip_size.x - 36.0, tooltip_size.y - icon_size - 138.0)
	item_tooltip_description_label.text = String(data.get("description", ""))

func _position_item_tooltip(anchor: Control) -> void:
	var viewport_size := get_viewport_rect().size
	var panel_size := _item_tooltip_size()
	var anchor_rect := anchor.get_global_rect()
	var x := anchor_rect.position.x + anchor_rect.size.x + ITEM_TOOLTIP_MARGIN
	if x + panel_size.x + ITEM_TOOLTIP_MARGIN > viewport_size.x:
		x = anchor_rect.position.x - panel_size.x - ITEM_TOOLTIP_MARGIN
	var y := anchor_rect.position.y
	x = clampf(x, ITEM_TOOLTIP_MARGIN, maxf(ITEM_TOOLTIP_MARGIN, viewport_size.x - panel_size.x - ITEM_TOOLTIP_MARGIN))
	y = clampf(y, ITEM_TOOLTIP_MARGIN, maxf(ITEM_TOOLTIP_MARGIN, viewport_size.y - panel_size.y - ITEM_TOOLTIP_MARGIN))
	var local_position := tooltip_layer.get_global_transform().affine_inverse() * Vector2(x, y)
	item_tooltip_panel.position = local_position

func _item_tooltip_size() -> Vector2:
	var width := get_viewport_rect().size.x
	if width >= 1800.0:
		return Vector2(260.0, 300.0)
	if width >= 1500.0:
		return Vector2(240.0, 280.0)
	return Vector2(224.0, 260.0)

func _item_tooltip_icon_size() -> float:
	var width := get_viewport_rect().size.x
	if width >= 1800.0:
		return 88.0
	if width >= 1500.0:
		return 80.0
	return 72.0

func _tooltip_icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	return load(icon_path) as Texture2D

func _quality_name_color(quality: String) -> Color:
	match quality:
		"SS":
			return Color("#D84B55")
		"S":
			return Color("#D1B850")
		"A":
			return Color("#B9A9FF")
		"B":
			return Color("#6FA8DC")
		_:
			return Color("#D8D6CE")

func _dispatch_grid_slot(source_id: String, meta_id: String, index: int) -> void:
	match source_id:
		TAB_WAREHOUSE:
			_on_warehouse_item_meta_clicked("warehouse:%d" % index)
		"sell":
			sell_count_spin_box.value = 1
			_selected_sell_slot_index = index
			_on_merchant_item_meta_clicked("sell:%s" % meta_id)
			_refresh()
		"buy":
			buy_count_spin_box.value = 1
			_selected_buy_slot_index = index
			_on_shop_stock_meta_clicked("buy:%s" % meta_id)
			_refresh()

func _set_research_tree(items: Array) -> void:
	if research_tree_root == null:
		return
	for child in research_tree_root.get_children():
		research_tree_root.remove_child(child)
		child.queue_free()
	var rows_by_id := _research_rows_by_id()
	if rows_by_id.is_empty():
		research_tree_root.custom_minimum_size = Vector2(680, 120)
		research_tree_root.size = research_tree_root.custom_minimum_size
		research_tree_root.add_child(_make_section_label("研究配置不可用", Vector2(12, 12), Vector2(240, 28), 16))
		return
	var ordered_ids := _ordered_research_ids(rows_by_id, items)
	var max_nodes := 1
	for research_id in ordered_ids:
		max_nodes = maxi(max_nodes, Array(rows_by_id[research_id]).size())
	var content_width := maxf(680.0, 168.0 + float(maxi(max_nodes, 5) - 1) * RESEARCH_NODE_GAP + RESEARCH_NODE_SIZE + 24.0)
	var content_height := maxf(360.0, float(ordered_ids.size()) * RESEARCH_ROW_HEIGHT + 18.0)
	research_tree_root.custom_minimum_size = Vector2(content_width, content_height)
	research_tree_root.size = research_tree_root.custom_minimum_size

	for row_index in range(ordered_ids.size()):
		var research_id := String(ordered_ids[row_index])
		var rows: Array = rows_by_id[research_id]
		rows.sort_custom(func(a, b): return int(a.get("level", 0)) < int(b.get("level", 0)))
		if rows.is_empty():
			continue
		var row_y := float(row_index) * RESEARCH_ROW_HEIGHT
		var title := _research_line_title(rows[0])
		var title_label := _make_section_label(title, Vector2(10, row_y + 28.0), Vector2(136, 28), 16)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		research_tree_root.add_child(title_label)
		var current_level: int = 0
		if _game_state != null and _game_state.has_method("get_research_level"):
			current_level = int(_game_state.get_research_level(research_id))
		var quote: Dictionary = {}
		if _game_state != null and _game_state.has_method("get_research_quote"):
			quote = _game_state.get_research_quote(research_id)
		for level_index in range(rows.size()):
			var row: Dictionary = rows[level_index]
			var node_x := 168.0 + float(level_index) * RESEARCH_NODE_GAP
			var node_y := row_y + 14.0
			var node := _make_research_node(research_id, row, current_level, quote)
			node.position = Vector2(node_x, node_y)
			research_tree_root.add_child(node)
			if level_index < rows.size() - 1:
				research_tree_root.add_child(_make_research_arrow(Vector2(node_x + RESEARCH_NODE_SIZE + 16.0, node_y + 18.0)))

func _research_rows_by_id() -> Dictionary:
	var result := {}
	if not _ensure_debug_data_loaded():
		return result
	for row in _debug_registry.get_research_rows():
		var research_id := String(row.get("research_id", ""))
		if research_id.is_empty():
			continue
		if not result.has(research_id):
			result[research_id] = []
		result[research_id].append(row)
	return result

func _ordered_research_ids(rows_by_id: Dictionary, items: Array) -> Array[String]:
	var preferred: Array[String] = ["move_speed", "inventory_slots", "home_storage_slots", "outpost_storage_slots", "max_stability", "warehouse_capacity"]
	var ids: Array[String] = []
	for research_id in preferred:
		if rows_by_id.has(research_id):
			ids.append(research_id)
	for item in items:
		if item is Dictionary:
			var research_id := String(item.get("research_id", ""))
			if rows_by_id.has(research_id) and not ids.has(research_id):
				ids.append(research_id)
	var extra_ids: Array[String] = []
	for key in rows_by_id.keys():
		var research_id := String(key)
		if not ids.has(research_id):
			extra_ids.append(research_id)
	extra_ids.sort()
	ids.append_array(extra_ids)
	return ids

func _make_research_node(research_id: String, row: Dictionary, current_level: int, quote: Dictionary) -> Button:
	var level := int(row.get("level", 0))
	var max_level := int(row.get("max_level", level))
	var button := Button.new()
	button.size = Vector2(RESEARCH_NODE_SIZE, RESEARCH_NODE_SIZE)
	button.text = _roman_level(level)
	button.tooltip_text = "%s\n%s\n%s" % [
		String(row.get("display_name", research_id)),
		String(row.get("description", "")),
		_format_research_effect(String(row.get("effect_type", "")), float(row.get("effect_value", 0.0))),
	]
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#F0EADF"))
	var is_completed := level <= current_level
	var is_next := level == current_level + 1
	var is_available := is_next and bool(quote.get("ok", false))
	var selected_level := clampi(current_level + 1, 1, max_level)
	var is_selected := _selected_research_id == research_id and level == selected_level
	var fill := Color("#071116")
	var border := Color("#4D575B")
	if is_completed:
		fill = Color(0.12, 0.18, 0.15, 0.96)
		border = Color("#75C77B")
	elif is_available:
		fill = Color("#0B151A")
		border = Color("#35C9D7")
	elif is_next:
		fill = Color(0.11, 0.10, 0.08, 0.96)
		border = Color("#8B6B34")
	if is_selected:
		border = Color("#D1B850")
	button.add_theme_stylebox_override("normal", _circle_style(fill, border, 3 if is_selected else 2))
	button.add_theme_stylebox_override("hover", _circle_style(Color("#121817"), Color("#D1B850"), 3))
	button.add_theme_stylebox_override("pressed", _circle_style(Color("#121817"), Color("#D1B850"), 4))
	button.button_up.connect(func(): _select_research_node(research_id))
	return button

func _make_research_arrow(pos: Vector2) -> Label:
	var arrow := Label.new()
	arrow.position = pos
	arrow.size = Vector2(42, 28)
	arrow.text = "→"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(arrow, 26, Color("#D8C3C8"))
	return arrow

func _select_research_node(research_id: String) -> void:
	_selected_research_id = research_id
	research_result_label.text = ""
	_update_selected_research_state()
	_set_research_tree(_game_state.query_research_items() if _game_state != null else [])

func _research_line_title(row: Dictionary) -> String:
	var display_name := String(row.get("display_name", row.get("research_id", "")))
	for suffix in [" I", " II", " III", " IV", " V"]:
		if display_name.ends_with(suffix):
			return display_name.substr(0, display_name.length() - suffix.length())
	return display_name

func _roman_level(level: int) -> String:
	match level:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
		_:
			return str(level)

func _currency_name(currency_id: String) -> String:
	if _ensure_debug_data_loaded():
		var definition := _debug_registry.get_currency(currency_id)
		if not definition.is_empty():
			return String(definition.get("name", currency_id))
	match currency_id:
		"mine_coin":
			return "矿币"
		_:
			return currency_id

func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"


func _update_selected_sell_state() -> void:
	var selected_group := _find_sell_group(_selected_sell_group_id)
	if selected_group.is_empty():
		_selected_sell_group_id = ""
		_selected_sell_slot_index = -1
		sell_count_spin_box.min_value = 1
		sell_count_spin_box.max_value = 1
		sell_count_spin_box.value = 1
		_update_sell_quote({})
		return

	var max_count: int = maxi(1, int(selected_group.get("count", 1)))
	if not _is_grid_meta_slot_valid("sell", _selected_sell_group_id, _selected_sell_slot_index):
		_selected_sell_slot_index = _first_grid_meta_slot_index("sell", _selected_sell_group_id)
	sell_count_spin_box.min_value = 1
	sell_count_spin_box.max_value = max_count
	sell_count_spin_box.value = clampi(int(sell_count_spin_box.value), 1, max_count)
	_update_sell_quote(_game_state.get_sell_quote(_selected_sell_group_id, int(sell_count_spin_box.value)))

func _update_sell_quote(quote: Dictionary) -> void:
	var ok := bool(quote.get("ok", false))
	sell_button.disabled = not ok
	if not ok:
		sell_quote_label.text = "选择一个可出售道具"
		return
	sell_quote_label.text = "出售 %s x%d，可获得 %d %s。当前 %s" % [
		String(quote.get("display_name", "")),
		int(quote.get("count", 0)),
		int(quote.get("total_value", 0)),
		_currency_name(String(quote.get("sell_currency_id", "mine_coin"))),
		_game_state.get_currency_display_text(String(quote.get("sell_currency_id", "mine_coin"))),
	]

func _update_selected_buy_state() -> void:
	var selected_offer := _find_shop_offer(_selected_shop_offer_id)
	if selected_offer.is_empty():
		_selected_shop_offer_id = ""
		_selected_buy_slot_index = -1
		buy_count_spin_box.min_value = 1
		buy_count_spin_box.max_value = 1
		buy_count_spin_box.value = 1
		_update_buy_quote({})
		return

	var max_count: int = maxi(1, int(selected_offer.get("count", 1)))
	if not _is_grid_meta_slot_valid("buy", _selected_shop_offer_id, _selected_buy_slot_index):
		_selected_buy_slot_index = _first_grid_meta_slot_index("buy", _selected_shop_offer_id)
	buy_count_spin_box.min_value = 1
	buy_count_spin_box.max_value = max_count
	buy_count_spin_box.value = clampi(int(buy_count_spin_box.value), 1, max_count)
	_update_buy_quote(_game_state.get_buy_quote(_selected_shop_offer_id, int(buy_count_spin_box.value)))

func _update_buy_quote(quote: Dictionary) -> void:
	var ok := bool(quote.get("ok", false))
	buy_button.disabled = not ok
	if not ok:
		buy_quote_label.text = "选择一个商人资源"
		return
	buy_quote_label.text = "购买 %s x%d，需要 %d %s。当前 %s" % [
		String(quote.get("display_name", "")),
		int(quote.get("count", 0)),
		int(quote.get("total_price", 0)),
		_currency_name(String(quote.get("buy_currency_id", "mine_coin"))),
		_game_state.get_currency_display_text(String(quote.get("buy_currency_id", "mine_coin"))),
	]

func _update_selected_research_state() -> void:
	if _game_state == null or _selected_research_id.is_empty():
		_selected_research_id = ""
		research_button.disabled = true
		research_quote_label.text = "选择一个研究项目"
		_update_research_detail({})
		return
	var quote: Dictionary = _game_state.get_research_quote(_selected_research_id)
	var ok := bool(quote.get("ok", false))
	research_button.disabled = not ok
	if quote.is_empty():
		research_quote_label.text = "选择一个研究项目"
		_update_research_detail({})
		return
	if not ok:
		research_quote_label.text = _format_research_quote(quote)
		_update_research_detail(quote)
		return
	research_quote_label.text = _format_research_quote(quote)
	_update_research_detail(quote)

func _update_research_detail(quote: Dictionary) -> void:
	if research_detail_title_label == null or research_detail_description_label == null or research_requirement_grid_root == null or research_currency_cost_label == null:
		return
	_clear_research_requirement_slots()
	if _game_state == null or _selected_research_id.is_empty() or quote.is_empty():
		research_detail_title_label.text = "研究所"
		research_detail_description_label.text = ""
		research_currency_cost_label.text = ""
		research_currency_cost_label.add_theme_color_override("font_color", Color("#D8D6CE"))
		research_button.disabled = true
		return
	var row := _selected_research_detail_row()
	var title := _research_line_title(row) if not row.is_empty() else String(quote.get("display_name", _selected_research_id))
	var description := String(row.get("description", quote.get("description", ""))) if not row.is_empty() else String(quote.get("description", ""))
	research_detail_title_label.text = title
	research_detail_description_label.text = description
	_set_research_requirement_slots(Array(quote.get("requirement_details", [])))
	if String(quote.get("error", "")) == "max_level":
		research_currency_cost_label.text = "已满级"
		research_currency_cost_label.add_theme_color_override("font_color", Color("#D1B850"))
		research_button.disabled = true
		return
	var currency_need := int(quote.get("required_currency_amount", 0))
	var currency_owned := int(quote.get("current_currency_amount", 0))
	research_currency_cost_label.text = "矿币消耗：%d" % currency_need
	var currency_enough := currency_owned >= currency_need
	research_currency_cost_label.add_theme_color_override("font_color", Color("#D1B850") if currency_enough else Color("#B96B6B"))
	research_button.disabled = not bool(quote.get("ok", false))

func _update_chapter_goal_view() -> void:
	if chapter_goal_label == null:
		return
	if _game_state == null or not _game_state.has_method("get_chapter_goal_snapshot"):
		chapter_goal_label.text = ""
		return
	var snapshot: Dictionary = _game_state.get_chapter_goal_snapshot()
	if bool(snapshot.get("active", false)):
		chapter_goal_label.text = "第一章：救出妹妹\n目标：解锁制造所\n矿币 %d / %d" % [
			int(snapshot.get("current_currency", 0)),
			int(snapshot.get("required_currency", MANUFACTURING_UNLOCK_COST)),
		]
	elif bool(snapshot.get("completed", false)):
		chapter_goal_label.text = "第一章已完成\n制造所已解锁"
	else:
		chapter_goal_label.text = ""

func _update_crafting_panel() -> void:
	if crafting_panel == null or crafting_status_label == null or crafting_unlock_button == null:
		return
	if _game_state == null:
		crafting_status_label.text = "制造所状态不可用。"
		crafting_unlock_button.disabled = true
		return
	var current_coin: int = int(_game_state.get_currency_amount("mine_coin")) if _game_state.has_method("get_currency_amount") else 0
	var unlocked := bool(_game_state.get("manufacturing_station_unlocked"))
	var goal_active := bool(_game_state.get("chapter_1_goal_active"))
	if unlocked:
		crafting_status_label.text = "制造所已解锁。\n\n旧时代制造机已经接入哨所电力。也许，救出妹妹的路终于有了第一盏灯。"
		crafting_unlock_button.visible = false
		crafting_result_label.text = ""
		return
	crafting_unlock_button.visible = true
	if not goal_active:
		crafting_status_label.text = "制造所尚未开放。\n\n先完成首次地面探索并返回基地。首次返回剧情结束后，第一章目标会正式开启。"
	else:
		crafting_status_label.text = "当前目标：为救出妹妹，解锁制造所\n\n出售可售物资，积攒 5000 矿币。制造所解锁后，才有机会推进救出妹妹的计划。\n\n矿币：%d / %d" % [
			current_coin,
			MANUFACTURING_UNLOCK_COST,
		]
	var can_unlock: bool = bool(_game_state.can_unlock_manufacturing_station()) if _game_state.has_method("can_unlock_manufacturing_station") else false
	crafting_unlock_button.disabled = not can_unlock
	if not goal_active:
		crafting_result_label.text = "完成首次地面返回剧情后开放。"
	elif current_coin < MANUFACTURING_UNLOCK_COST:
		crafting_result_label.text = "还差 %d 矿币。去商人页签出售带回的道具。" % (MANUFACTURING_UNLOCK_COST - current_coin)
	else:
		crafting_result_label.text = "矿币已足够。确认解锁制造所，推进救出妹妹的计划。"

func _clear_research_requirement_slots() -> void:
	if research_requirement_grid_root == null:
		return
	for child in research_requirement_grid_root.get_children():
		research_requirement_grid_root.remove_child(child)
		child.queue_free()

func _set_research_requirement_slots(details: Array) -> void:
	_clear_research_requirement_slots()
	var visible_details := details.slice(0, mini(details.size(), 6))
	for index in range(visible_details.size()):
		var detail = visible_details[index]
		if not (detail is Dictionary):
			continue
		var detail_dict: Dictionary = detail
		var row := int(index / 3)
		var col := index % 3
		var slots_in_row := mini(3, visible_details.size() - row * 3)
		var row_width := float(slots_in_row) * RESEARCH_MATERIAL_SLOT_WIDTH + float(slots_in_row - 1) * RESEARCH_MATERIAL_SLOT_GAP
		var start_x := (research_requirement_grid_root.size.x - row_width) * 0.5
		var slot_pos := Vector2(
			start_x + float(col) * (RESEARCH_MATERIAL_SLOT_WIDTH + RESEARCH_MATERIAL_SLOT_GAP),
			float(row) * (RESEARCH_MATERIAL_SLOT_HEIGHT + RESEARCH_MATERIAL_ROW_GAP)
		)
		research_requirement_grid_root.add_child(_make_research_material_slot(detail_dict, slot_pos))

func _make_research_material_slot(detail: Dictionary, pos: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = Vector2(RESEARCH_MATERIAL_SLOT_WIDTH, RESEARCH_MATERIAL_SLOT_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var enough := bool(detail.get("enough", false))
	panel.add_theme_stylebox_override("panel", _slot_style(Color("#071116"), Color("#35C9D7") if enough else Color("#8B4F4F"), 1))
	var material_name := String(detail.get("display_name", detail.get("item_id", "")))
	panel.tooltip_text = ""
	var item_id := String(detail.get("item_id", ""))
	var item_def := _debug_registry.get_item(item_id) if _ensure_debug_data_loaded() else {}
	var icon_path := String(item_def.get("icon", ""))
	var texture := _tooltip_icon_texture(icon_path)
	if texture != null:
		var icon := TextureRect.new()
		icon.name = "ResearchMaterialIcon"
		icon.position = Vector2((panel.size.x - 28.0) * 0.5, 4.0)
		icon.size = Vector2(28.0, 28.0)
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
	else:
		var name_label := Label.new()
		name_label.position = Vector2(4, 6)
		name_label.size = Vector2(panel.size.x - 8.0, 22)
		name_label.text = material_name
		name_label.clip_text = true
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_style_label(name_label, 10, Color("#D8D6CE"))
		panel.add_child(name_label)

	var count_label := Label.new()
	count_label.position = Vector2(4, 34)
	count_label.size = Vector2(panel.size.x - 8.0, 20)
	count_label.text = "%d/%d" % [int(detail.get("owned", 0)), int(detail.get("required", 0))]
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_label(count_label, 13, Color("#D8D6CE") if enough else Color("#D7A0A0"))
	panel.add_child(count_label)
	var tooltip_item := {
		"item_id": item_id,
		"display_name": material_name,
	}
	_bind_base_item_tooltip(panel, tooltip_item, "research", {
		"context": "research",
		"owned_count": int(detail.get("owned", 0)),
		"required_count": int(detail.get("required", 0)),
		"show_requirement_state": true,
	})
	return panel

func _selected_research_detail_row() -> Dictionary:
	if _selected_research_id.is_empty() or not _ensure_debug_data_loaded():
		return {}
	var current_level: int = 0
	if _game_state != null and _game_state.has_method("get_research_level"):
		current_level = int(_game_state.get_research_level(_selected_research_id))
	var best_row: Dictionary = {}
	var max_level := 0
	for row in _debug_registry.get_research_rows():
		if String(row.get("research_id", "")) != _selected_research_id:
			continue
		var level := int(row.get("level", 0))
		max_level = maxi(max_level, level)
		if level == current_level + 1:
			return row
		if level > int(best_row.get("level", 0)):
			best_row = row
	if current_level >= max_level:
		return best_row
	return best_row

func _find_sell_group(warehouse_item_id: String) -> Dictionary:
	if _game_state == null or warehouse_item_id.is_empty():
		return {}
	for item in _game_state.query_sellable_items():
		if String(item.get("warehouse_item_id", "")) == warehouse_item_id:
			return item
	return {}

func _find_shop_offer(shop_offer_id: String) -> Dictionary:
	if _game_state == null or shop_offer_id.is_empty():
		return {}
	for item in _game_state.query_shop_offers():
		if String(item.get("shop_offer_id", "")) == shop_offer_id:
			return item
	return {}

func _is_grid_meta_slot_valid(source_id: String, meta_id: String, slot_index: int) -> bool:
	if slot_index < 0 or meta_id.is_empty():
		return false
	var slots := _current_merchant_slots(source_id)
	return slot_index < slots.size() and String(slots[slot_index].get("grid_meta_id", "")) == meta_id

func _first_grid_meta_slot_index(source_id: String, meta_id: String) -> int:
	if meta_id.is_empty():
		return -1
	var slots := _current_merchant_slots(source_id)
	for index in range(slots.size()):
		if String(slots[index].get("grid_meta_id", "")) == meta_id:
			return index
	return -1

func _current_merchant_slots(source_id: String) -> Array[Dictionary]:
	if _game_state == null:
		return []
	match source_id:
		"sell":
			return _expand_sell_groups_to_slots(_game_state.query_sellable_items())
		"buy":
			return _expand_shop_offers_to_slots(_game_state.query_shop_offers())
		_:
			return []

func _format_research_quote(quote: Dictionary) -> String:
	var material_parts: Array[String] = []
	for detail in Array(quote.get("requirement_details", [])):
		if detail is Dictionary:
			material_parts.append("%s %d/%d" % [
				String(detail.get("display_name", detail.get("item_id", ""))),
				int(detail.get("owned", 0)),
				int(detail.get("required", 0)),
			])
	var currency_need := int(quote.get("required_currency_amount", 0))
	var currency_owned := int(quote.get("current_currency_amount", 0))
	var effect_text := _format_research_effect(String(quote.get("effect_type", "")), float(quote.get("effect_value", 0.0)))
	return "%s Lv.%d：%s；矿币 %d/%d；完成后%s。" % [
		String(quote.get("display_name", "")),
		int(quote.get("next_level", 0)),
		"、".join(material_parts),
		currency_owned,
		currency_need,
		effect_text,
	]

func _format_research_effect(effect_type: String, effect_value: float) -> String:
	match effect_type:
		"player_move_speed_multiplier":
			return "移速 %.0f%%" % (effect_value * 100.0)
		"inventory_slots":
			return "背包 %d 格" % int(round(effect_value))
		"home_storage_slots":
			return "家箱 %d 格" % int(round(effect_value))
		"outpost_storage_slots":
			return "前哨箱 %d 格" % int(round(effect_value))
		"max_stability":
			return "稳定值 %.0f" % effect_value
		"warehouse_capacity":
			return "仓库 %d 格" % int(round(effect_value))
		_:
			return "%s %.2f" % [effect_type, effect_value]

func _quality_color(item: Dictionary) -> Color:
	var value = item.get("quality_color", Color.WHITE)
	if value is Color:
		return value
	match String(item.get("quality", "C")):
		"S":
			return Color("#D1B850")
		"A":
			return Color("#B9A9FF")
		"B":
			return Color("#6FA8DC")
		_:
			return Color("#D8D6CE")

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

func _slot_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 5
	style.content_margin_top = 5
	style.content_margin_right = 5
	style.content_margin_bottom = 5
	return style

func _circle_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _on_warehouse_item_meta_clicked(meta: Variant) -> void:
	if _game_state == null:
		return
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "warehouse":
		return
	var item: Dictionary = _game_state.select_warehouse_item(int(parts[1]))
	if item.is_empty():
		return
	result_label.text = "已选择：%s" % item.get("display_name", item.get("item_id", ""))
	if warehouse_status_label != null:
		warehouse_status_label.text = "已选择：%s\n品质：%s\n格子规则：每格 1 个道具，不堆叠。" % [
			String(item.get("display_name", item.get("item_id", ""))),
			String(item.get("quality", "C")),
		]

func _on_merchant_item_meta_clicked(meta: Variant) -> void:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "sell":
		return
	_selected_sell_group_id = parts[1]
	merchant_result_label.text = ""
	_update_selected_sell_state()

func _on_shop_stock_meta_clicked(meta: Variant) -> void:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "buy":
		return
	_selected_shop_offer_id = parts[1]
	merchant_result_label.text = ""
	_update_selected_buy_state()

func _on_research_meta_clicked(meta: Variant) -> void:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "research":
		return
	_selected_research_id = parts[1]
	research_result_label.text = ""
	_update_selected_research_state()

func _on_sell_count_changed(_value: float) -> void:
	_update_selected_sell_state()

func _on_buy_count_changed(_value: float) -> void:
	_update_selected_buy_state()

func _on_sell_pressed() -> void:
	if _game_state == null or _selected_sell_group_id.is_empty():
		return
	var result: Dictionary = _game_state.sell_warehouse_item(_selected_sell_group_id, int(sell_count_spin_box.value))
	merchant_result_label.text = String(result.get("message", "出售失败。"))
	if bool(result.get("ok", false)):
		_selected_sell_group_id = ""
		_selected_sell_slot_index = -1
	_refresh()

func _on_buy_pressed() -> void:
	if _game_state == null or _selected_shop_offer_id.is_empty():
		return
	var result: Dictionary = _game_state.buy_shop_item(_selected_shop_offer_id, int(buy_count_spin_box.value))
	merchant_result_label.text = String(result.get("message", "购买失败。"))
	if bool(result.get("ok", false)):
		_selected_shop_offer_id = ""
		_selected_buy_slot_index = -1
	_refresh()

func _on_research_pressed() -> void:
	if _game_state == null or _selected_research_id.is_empty():
		return
	var quote: Dictionary = _game_state.get_research_quote(_selected_research_id)
	if not bool(quote.get("ok", false)):
		research_result_label.text = String(quote.get("message", "研究条件不足。"))
		_update_selected_research_state()
		return
	research_confirm_dialog.dialog_text = "%s\n\n确认后将消耗上列材料与矿币，无法撤销。" % _format_research_quote(quote)
	research_confirm_dialog.popup_centered()

func _on_research_confirmed() -> void:
	if _game_state == null or _selected_research_id.is_empty():
		return
	var result: Dictionary = _game_state.complete_research(_selected_research_id)
	research_result_label.text = String(result.get("message", "研究失败。"))
	if bool(result.get("ok", false)):
		_selected_research_id = ""
	_refresh()

func _on_crafting_unlock_pressed() -> void:
	if _game_state == null:
		return
	if not _game_state.can_unlock_manufacturing_station():
		crafting_result_label.text = "矿币或章节目标条件不足。"
		_update_crafting_panel()
		return
	manufacturing_confirm_dialog.dialog_text = "确认解锁制造所？\n将消耗 5000 矿币。"
	manufacturing_confirm_dialog.popup_centered()

func _on_manufacturing_unlock_confirmed() -> void:
	if _game_state == null:
		return
	var result: Dictionary = _game_state.unlock_manufacturing_station()
	crafting_result_label.text = String(result.get("message", "制造所解锁失败。"))
	_refresh()
	if bool(result.get("ok", false)):
		_show_chapter_complete_popup(int(result.get("surface_day", _game_state.get_current_day())))

func _on_debug_add_currency_pressed() -> void:
	if _game_state == null:
		return
	var result: Dictionary = _game_state.add_currency("mine_coin", 500, "debug_panel")
	debug_result_label.text = "已增加 500 矿币。" if bool(result.get("ok", false)) else "增加矿币失败。"
	_refresh()

func _on_debug_add_sell_items_pressed() -> void:
	if _game_state == null or not _ensure_debug_data_loaded():
		return
	var added := 0
	added += _debug_add_item("field_bandage", 2)
	added += _debug_add_item("gold_data_chip", 1)
	added += _debug_add_item("stability_candy", 2)
	debug_result_label.text = "已加入 %d 个可售卖测试道具。" % added
	_show_tab(TAB_MERCHANT)

func _on_debug_add_research_costs_pressed() -> void:
	if _game_state == null:
		return
	var result := _debug_fill_next_research_costs()
	debug_result_label.text = String(result.get("message", "补齐研究资源失败。"))
	_show_tab(TAB_RESEARCH)

func _on_debug_refresh_shop_pressed() -> void:
	if _game_state == null:
		return
	_game_state.set_merchant_shop_level(1)
	var offers: Array = _game_state.refresh_shop_stock()
	debug_result_label.text = "已刷新 Lv.1 商人库存：%d 项。" % offers.size()
	_show_tab(TAB_MERCHANT)

func _on_debug_max_shop_pressed() -> void:
	if _game_state == null:
		return
	_game_state.set_merchant_shop_level(3)
	var offers: Array = _game_state.refresh_shop_stock()
	debug_result_label.text = "已切到 Lv.3 并刷新商人库存：%d 项。" % offers.size()
	_show_tab(TAB_MERCHANT)

func _on_debug_complete_research_pressed() -> void:
	if _game_state == null:
		return
	var fill_result := _debug_fill_next_research_costs()
	if not bool(fill_result.get("ok", false)):
		debug_result_label.text = String(fill_result.get("message", "补齐研究资源失败。"))
		_show_tab(TAB_RESEARCH)
		return
	var result: Dictionary = _game_state.complete_research(_debug_target_research_id())
	debug_result_label.text = String(result.get("message", "研究失败。"))
	_selected_research_id = ""
	_show_tab(TAB_RESEARCH)

func _on_debug_reset_research_pressed() -> void:
	if _game_state == null:
		return
	_game_state.reset_research()
	_selected_research_id = ""
	debug_result_label.text = "已重置研究等级。"
	_show_tab(TAB_RESEARCH)

func _on_debug_reset_profile_pressed() -> void:
	if _game_state == null:
		return
	var result: Dictionary = {}
	if _game_state.has_method("reset_local_data_debug_only"):
		result = _game_state.reset_local_data_debug_only()
	elif _game_state.has_method("delete_profile_debug_only"):
		result = _game_state.delete_profile_debug_only()
	else:
		debug_result_label.text = "GameState 不支持重置本地数据。"
		return
	debug_result_label.text = String(result.get("message", "已重置本地数据。")) if bool(result.get("ok", false)) else "重置本地数据失败：%s" % String(result.get("reason", result.get("error", "unknown")))
	_refresh()

func _on_debug_reset_story_pressed() -> void:
	if _game_state == null or not _game_state.has_method("reset_story_flags"):
		return
	_game_state.reset_story_flags()
	debug_result_label.text = "已重置剧情 flag 与第一章状态。"
	_refresh()

func _on_debug_add_chapter_currency_pressed() -> void:
	if _game_state == null:
		return
	_game_state.add_currency("mine_coin", 5000, "debug_chapter")
	debug_result_label.text = "已增加 5000 矿币。"
	_refresh()

func _on_debug_surface_day_pressed() -> void:
	if _game_state == null:
		return
	_game_state.reset_day(_game_state.get_current_day() + 1)
	debug_result_label.text = "地表天数已 +1。"
	_refresh()

func _on_debug_force_chapter_complete_pressed() -> void:
	if _game_state == null:
		return
	if _game_state.has_method("activate_chapter_1_goal_debug"):
		_game_state.activate_chapter_1_goal_debug()
	var missing := maxi(0, MANUFACTURING_UNLOCK_COST - _game_state.get_currency_amount("mine_coin"))
	if missing > 0:
		_game_state.add_currency("mine_coin", missing, "debug_force_chapter")
	var result: Dictionary = _game_state.unlock_manufacturing_station()
	debug_result_label.text = String(result.get("message", "强制完成第一章失败。"))
	_refresh()
	if bool(result.get("ok", false)):
		_show_chapter_complete_popup(int(result.get("surface_day", _game_state.get_current_day())))

func _on_debug_force_monster_pressed() -> void:
	if _game_state == null:
		return
	if _game_state.has_method("debug_force_monster_presence_next_run"):
		_game_state.debug_force_monster_presence_next_run()
	elif _game_state.has_method("debug_force_scene_event_next_run"):
		_game_state.debug_force_scene_event_next_run("monster_presence")
	debug_result_label.text = "下一次出发：本日必出怪物。"

func _on_debug_slow_loading_pressed() -> void:
	_debug_slow_next_loading = true
	debug_result_label.text = "下次出发将使用慢速加载。"

func _on_debug_fail_loading_pressed() -> void:
	_debug_fail_next_loading = true
	debug_result_label.text = "下次出发将模拟加载失败。"

func _debug_fill_next_research_costs() -> Dictionary:
	if not _ensure_debug_data_loaded():
		return {"ok": false, "message": "配置表加载失败。"}
	var research_id := _debug_target_research_id()
	var quote: Dictionary = _game_state.get_research_quote(research_id)
	if String(quote.get("error", "")) == "max_level":
		return {"ok": false, "message": "%s 已满级，无需补齐。" % String(quote.get("display_name", research_id))}
	var added_items := 0
	for detail in Array(quote.get("requirement_details", [])):
		if not (detail is Dictionary):
			continue
		var item_id := String(detail.get("item_id", ""))
		var missing := maxi(0, int(detail.get("required", 0)) - int(detail.get("owned", 0)))
		added_items += _debug_add_item(item_id, missing)
	var currency_id := String(quote.get("required_currency_id", "mine_coin"))
	var missing_currency := maxi(0, int(quote.get("required_currency_amount", 0)) - int(quote.get("current_currency_amount", 0)))
	if missing_currency > 0:
		_game_state.add_currency(currency_id, missing_currency, "debug_research_costs")
	return {
		"ok": true,
		"message": "已补齐 %s 下一档：材料 +%d，矿币 +%d。" % [String(quote.get("display_name", research_id)), added_items, missing_currency],
	}

func _debug_target_research_id() -> String:
	return _selected_research_id if not _selected_research_id.is_empty() else "move_speed"

func _debug_add_item(item_id: String, count: int) -> int:
	if count <= 0 or item_id.is_empty():
		return 0
	var items: Array[Dictionary] = []
	for _index in range(count):
		var stack := _debug_registry.make_item_stack(item_id, 1)
		if not stack.is_empty():
			stack["source"] = "debug_panel"
			items.append(stack)
	var accepted: Array = _game_state.add_to_warehouse(items)
	return accepted.size()

func _ensure_debug_data_loaded() -> bool:
	if _debug_data_loaded:
		return true
	_debug_data_loaded = _debug_registry.load_all()
	if not _debug_data_loaded and debug_result_label != null:
		debug_result_label.text = "Debug 配置表加载失败：%s" % str(_debug_registry.load_errors)
	return _debug_data_loaded

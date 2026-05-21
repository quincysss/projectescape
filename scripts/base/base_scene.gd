extends Control

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const DialogueServiceScript := preload("res://scripts/dialogue/dialogue_service.gd")
const BaseMerchantPanelControllerScript := preload("res://scripts/base/base_merchant_panel_controller.gd")
const BaseWarehousePanelControllerScript := preload("res://scripts/base/base_warehouse_panel_controller.gd")
const BaseResearchPanelControllerScript := preload("res://scripts/base/base_research_panel_controller.gd")
const BaseCraftingPanelControllerScript := preload("res://scripts/base/base_crafting_panel_controller.gd")
const BaseCatalogPanelControllerScript := preload("res://scripts/base/base_catalog_panel_controller.gd")
const BaseShopPanelControllerScript := preload("res://scripts/base/base_shop_panel_controller.gd")
const BaseNightPlanPanelControllerScript := preload("res://scripts/base/base_night_plan_panel_controller.gd")
const BaseDebugActionServiceScript := preload("res://scripts/debug/base_debug_action_service.gd")
const DialoguePanelScene := preload("res://scenes/ui/DialoguePanel.tscn")
const RunLoadingScreenScene := preload("res://scenes/ui/RunLoadingScreen.tscn")
const FullscreenBackgroundBuilderScript := preload("res://scripts/ui/fullscreen_background_builder.gd")
const ItemTooltipViewScript := preload("res://scripts/ui/item_tooltip_view.gd")
const ItemGridViewScript := preload("res://scripts/ui/item_grid_view.gd")

const TAB_WAREHOUSE := "warehouse"
const TAB_MERCHANT := "merchant"
const TAB_RESEARCH := "research"
const TAB_CRAFTING := "crafting"
const TAB_CATALOG := "catalog"
const PHASE_DAY_PREP := "DAY_PREP"
const PHASE_SHOP_OPEN := "SHOP_OPEN"
const PHASE_SHOP_SETTLEMENT := "SHOP_SETTLEMENT"
const PHASE_NIGHT := "NIGHT"
const PHASE_NIGHT_PLAN := "NIGHT_PLAN"
const PHASE_LOADOUT := "LOADOUT"
const PHASE_LOADING_TO_RUN := "LOADING_TO_RUN"
const COMPETITION_DIRECT_DEPARTURE := true
const BASE_BACKGROUND_PATH := "res://assets/originalphoto/basementphoto.png"
const WORLD_INTRO_DIALOGUE_PATH := "res://setting/dialogues.tab#world_intro_dialogue"
const FIRST_DEPARTURE_DIALOGUE_PATH := "res://setting/dialogues.tab#first_departure_outpost_dialogue"
const FIRST_RETURN_DIALOGUE_PATH := "res://setting/dialogues.tab#first_return_chapter_1"
const MANUFACTURING_UNLOCK_COST := 100
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
var _selected_research_id := ""
var base_data_registry = GameDataRegistryScript.new()
var base_data_loaded := false
var base_merchant_panel = BaseMerchantPanelControllerScript.new()
var base_warehouse_panel = BaseWarehousePanelControllerScript.new()
var base_research_panel = BaseResearchPanelControllerScript.new()
var base_crafting_panel = BaseCraftingPanelControllerScript.new()
var base_catalog_panel = BaseCatalogPanelControllerScript.new()
var base_shop_panel = BaseShopPanelControllerScript.new()
var base_night_plan_panel = BaseNightPlanPanelControllerScript.new()
var base_debug_actions = BaseDebugActionServiceScript.new()
var item_tooltip_view = ItemTooltipViewScript.new()
var item_grid_view = ItemGridViewScript.new()
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
var crafting_recipe_scroll: ScrollContainer
var crafting_recipe_root: Control
var catalog_tab_button: Button
var catalog_panel: Panel
var catalog_grid_root: Control
var catalog_status_label: Label
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
var _active_run_loading_screen: RunLoadingScreen
var _shop_refresh_accumulator := 0.0

func _ready() -> void:
	_game_state = get_node_or_null("/root/GameState")
	base_merchant_panel.setup(
		_game_state,
		sell_count_spin_box,
		sell_quote_label,
		sell_button,
		buy_count_spin_box,
		buy_quote_label,
		buy_button,
		merchant_result_label,
		Callable(self, "_currency_name")
	)
	base_crafting_panel.set_game_state(_game_state)
	set_process_input(true)
	set_process(true)
	_play_base_safe_house_bgm()
	_build_background()
	_ensure_catalog_tab_button()
	start_button.pressed.connect(_on_start_pressed)
	warehouse_tab_button.pressed.connect(_on_warehouse_tab_pressed)
	merchant_tab_button.pressed.connect(_on_merchant_tab_pressed)
	research_tab_button.pressed.connect(_on_research_tab_pressed)
	crafting_tab_button.pressed.connect(_on_crafting_tab_pressed)
	catalog_tab_button.pressed.connect(_on_catalog_tab_pressed)
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

func _process(delta: float) -> void:
	if _game_state == null or not _game_state.has_method("get_outgame_phase"):
		return
	if String(_game_state.get_outgame_phase()) != PHASE_SHOP_OPEN:
		return
	var result: Dictionary = _game_state.advance_shop_open(delta)
	_shop_refresh_accumulator += delta
	if bool(result.get("ok", false)) and (_shop_refresh_accumulator >= 0.25 or bool(result.get("ended", false))):
		_shop_refresh_accumulator = 0.0
		_refresh()

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
	if not _is_merchant_tab_available():
		_show_locked_tab_notice("商人将在第一次地表回收返回后开放。")
		return
	_show_tab(TAB_WAREHOUSE)

func _on_research_tab_pressed() -> void:
	if not _is_research_tab_available():
		_show_locked_tab_notice("研究所将在第一次地表回收返回后开放。")
		return
	_show_tab(TAB_RESEARCH)

func _on_crafting_tab_pressed() -> void:
	if not _is_crafting_tab_available():
		_show_tab(TAB_WAREHOUSE)
		return
	_show_tab(TAB_CRAFTING)

func _on_catalog_tab_pressed() -> void:
	_show_tab(TAB_CATALOG)

func _request_start_run() -> void:
	if _is_dialogue_playing():
		return
	var phase := _get_outgame_phase()
	if phase == PHASE_DAY_PREP:
		if _game_state != null and _game_state.has_method("start_shop_open"):
			_game_state.start_shop_open()
			_refresh()
		return
	if phase == PHASE_NIGHT:
		if COMPETITION_DIRECT_DEPARTURE:
			_begin_competition_direct_departure()
			return
		if _game_state != null and _game_state.has_method("go_to_night_plan"):
			_game_state.go_to_night_plan()
			_refresh()
		return
	if phase != PHASE_LOADOUT:
		return
	if _game_state != null and _game_state.has_method("should_play_first_departure_outpost_dialogue") and _game_state.should_play_first_departure_outpost_dialogue():
		_play_dialogue(FIRST_DEPARTURE_DIALOGUE_PATH, Callable(self, "_on_first_departure_dialogue_finished"))
		return
	_begin_run_loading()

func _on_first_departure_dialogue_finished(_dialogue_id: String = "", _skipped: bool = false) -> void:
	if _game_state != null and _game_state.has_method("mark_first_departure_outpost_dialogue_seen"):
		_game_state.mark_first_departure_outpost_dialogue_seen()
	_begin_run_loading()

func _begin_competition_direct_departure() -> void:
	# 临时比赛版本：跳过夜间角色/地点选择与携行配置，点出击后直接进地表加载。
	if _game_state != null and _game_state.has_method("mark_first_departure_outpost_dialogue_seen"):
		_game_state.mark_first_departure_outpost_dialogue_seen()
	_begin_run_loading()

func _begin_run_loading() -> void:
	if is_instance_valid(_active_run_loading_screen) and _active_run_loading_screen.is_inside_tree():
		return
	var loading = RunLoadingScreenScene.instantiate()
	_active_run_loading_screen = loading
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
	_active_run_loading_screen = null
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
	_active_run_loading_screen = null
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

func _get_outgame_phase() -> String:
	if _game_state != null and _game_state.has_method("get_outgame_phase"):
		return String(_game_state.get_outgame_phase())
	return PHASE_DAY_PREP

func _is_day_prep_phase() -> bool:
	return _get_outgame_phase() == PHASE_DAY_PREP

func _show_chapter_goal_popup() -> void:
	var popup := _make_overlay_popup("第一章目标", "解锁制造所\n\n出售可售物资，积攒 100 矿币。\n制造所解锁后，也许妹妹还有救。")
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
	var text := "你用了 %d 天，成功购买了旧时代制造机。\n也许，一切都还来得及。\n\n第一章节结束，后续章节开发中" % surface_day
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
	if not _is_day_prep_phase():
		return
	var locked_message := ""
	if tab_id == TAB_MERCHANT and not _is_merchant_tab_available():
		tab_id = TAB_WAREHOUSE
		locked_message = "商人将在第一次地表回收返回后开放。"
	if tab_id == TAB_RESEARCH and not _is_research_tab_available():
		tab_id = TAB_WAREHOUSE
		locked_message = "研究所将在第一次地表回收返回后开放。"
	if tab_id == TAB_CRAFTING and not _is_crafting_tab_available():
		tab_id = TAB_WAREHOUSE
		locked_message = "制造所将在首次返回后作为第一章目标开放。"
	_hide_item_tooltip("switch_tab")
	_active_tab = tab_id
	_refresh()
	if not locked_message.is_empty():
		_show_locked_tab_notice(locked_message)

func _show_locked_tab_notice(message: String) -> void:
	result_label.visible = true
	result_label.text = message

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
		base_research_panel.set_game_state(null)
		_update_chapter_goal_view()
		base_crafting_panel.update_view()
		merchant_result_label.text = ""
		research_result_label.text = ""
		debug_result_label.text = "GameState 不可用"
		base_merchant_panel.clear_selection()
		_set_catalog_items([])
		return

	base_merchant_panel.set_game_state(_game_state)
	base_research_panel.set_game_state(_game_state)
	base_crafting_panel.set_game_state(_game_state)
	base_shop_panel.set_game_state(_game_state)
	base_night_plan_panel.set_game_state(_game_state)
	if _game_state.has_method("ensure_daily_demand"):
		_game_state.ensure_daily_demand()
	day_label.text = _game_state.get_day_display_text()
	currency_label.text = _game_state.get_currency_display_text("mine_coin")
	_set_warehouse_items_text(_game_state.get_warehouse_items_snapshot())
	_set_merchant_items_text(_game_state.query_sellable_items())
	_set_shop_stock_text(_game_state.query_shop_offers())
	_set_research_items_text(_game_state.query_research_items())
	_set_catalog_items(_game_state.query_catalog_items() if _game_state.has_method("query_catalog_items") else [])
	_update_chapter_goal_view()
	base_crafting_panel.update_view()
	if crafting_recipe_scroll != null:
		crafting_recipe_scroll.visible = bool(_game_state.get("manufacturing_station_unlocked"))
	base_merchant_panel.refresh_selection()
	_update_selected_research_state()
	base_shop_panel.update_view(_get_outgame_phase())
	base_night_plan_panel.update_view(_get_outgame_phase())

func _refresh_tabs() -> void:
	_hide_item_tooltip("refresh_tabs")
	var phase := _get_outgame_phase()
	var base_tabs_visible := phase == PHASE_DAY_PREP
	var merchant_available := _is_merchant_tab_available()
	var research_available := _is_research_tab_available()
	var crafting_available := _is_crafting_tab_available()
	if _active_tab == TAB_MERCHANT and not merchant_available:
		_active_tab = TAB_WAREHOUSE
	if _active_tab == TAB_RESEARCH and not research_available:
		_active_tab = TAB_WAREHOUSE
	if _active_tab == TAB_CRAFTING and not crafting_available:
		_active_tab = TAB_WAREHOUSE
	warehouse_label.visible = false
	if warehouse_panel != null:
		warehouse_panel.visible = base_tabs_visible and _active_tab == TAB_WAREHOUSE
	merchant_panel.visible = base_tabs_visible and _active_tab == TAB_MERCHANT
	research_panel.visible = base_tabs_visible and _active_tab == TAB_RESEARCH
	if crafting_panel != null:
		crafting_panel.visible = base_tabs_visible and _active_tab == TAB_CRAFTING
	if catalog_panel != null:
		catalog_panel.visible = base_tabs_visible and _active_tab == TAB_CATALOG
	warehouse_tab_button.visible = base_tabs_visible
	merchant_tab_button.visible = false
	research_tab_button.visible = base_tabs_visible
	crafting_tab_button.visible = base_tabs_visible
	if catalog_tab_button != null:
		catalog_tab_button.visible = base_tabs_visible
	start_button.visible = phase == PHASE_DAY_PREP or phase == PHASE_NIGHT
	start_button.disabled = phase != PHASE_DAY_PREP and phase != PHASE_NIGHT
	if phase == PHASE_DAY_PREP:
		start_button.text = "开店营业"
	elif phase == PHASE_NIGHT:
		start_button.text = "出击"
	warehouse_tab_button.button_pressed = _active_tab == TAB_WAREHOUSE
	merchant_tab_button.button_pressed = _active_tab == TAB_MERCHANT
	research_tab_button.button_pressed = _active_tab == TAB_RESEARCH
	crafting_tab_button.button_pressed = _active_tab == TAB_CRAFTING
	if catalog_tab_button != null:
		catalog_tab_button.button_pressed = _active_tab == TAB_CATALOG
	warehouse_tab_button.text = "仓库"
	merchant_tab_button.text = "商人"
	research_tab_button.text = "研究所"
	crafting_tab_button.text = "制造所"
	merchant_tab_button.disabled = not merchant_available
	research_tab_button.disabled = not research_available
	crafting_tab_button.disabled = not crafting_available
	if catalog_tab_button != null:
		catalog_tab_button.text = "图鉴"
		catalog_tab_button.disabled = false
		catalog_tab_button.tooltip_text = ""
	merchant_tab_button.tooltip_text = "" if merchant_available else "等待第一次地表回收后开放。"
	research_tab_button.tooltip_text = "" if research_available else "等待第一次地表回收后开放。"
	crafting_tab_button.tooltip_text = "" if crafting_available else "完成首次地面返回剧情后解锁制造所。"
	_layout_top_navigation()

func _is_merchant_tab_available() -> bool:
	if _game_state == null:
		return false
	if _game_state.has_method("is_merchant_unlocked"):
		return bool(_game_state.is_merchant_unlocked())
	return bool(_game_state.get("merchant_unlocked"))

func _is_research_tab_available() -> bool:
	if _game_state == null:
		return false
	if _game_state.has_method("is_research_station_unlocked"):
		return bool(_game_state.is_research_station_unlocked())
	return bool(_game_state.get("research_station_unlocked"))

func _is_crafting_tab_available() -> bool:
	return base_crafting_panel.is_tab_available()

func _build_visual_surfaces() -> void:
	var ui_root := get_node("BaseUIRoot") as Control
	_ensure_catalog_tab_button()
	_style_top_navigation()
	_setup_base_ui_helpers(ui_root)
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

	_build_warehouse_surface(ui_root)

	_build_merchant_surface()
	_build_research_surface()
	_build_crafting_surface()
	_build_catalog_surface()
	base_shop_panel.setup(_game_state, ui_root, Callable(self, "_refresh"), Callable(self, "_begin_competition_direct_departure"))
	base_night_plan_panel.setup(_game_state, ui_root, Callable(self, "_refresh"), Callable(self, "_begin_run_loading"))

func _build_warehouse_surface(ui_root: Control) -> void:
	var nodes := base_warehouse_panel.build_surface(ui_root)
	warehouse_panel = nodes.get("panel") as Panel
	warehouse_grid_root = nodes.get("grid_root") as Control
	warehouse_status_label = nodes.get("status_label") as Label
	base_warehouse_panel.setup_views(
		warehouse_label,
		item_grid_view,
		warehouse_grid_root,
		warehouse_status_label
	)

func _setup_base_ui_helpers(ui_root: Control) -> void:
	item_tooltip_view.setup(
		ui_root,
		self,
		base_data_registry,
		Callable(self, "_ensure_base_data_loaded"),
		Callable(self, "_currency_name")
	)
	item_grid_view.setup(
		item_tooltip_view,
		Callable(self, "_dispatch_grid_slot"),
		Callable(self, "_is_grid_slot_selected"),
		Callable(self, "_currency_name")
	)

func _style_top_navigation() -> void:
	_ensure_catalog_tab_button()
	var tabs: Array[Button] = [warehouse_tab_button, merchant_tab_button, research_tab_button, crafting_tab_button, catalog_tab_button]
	for button in tabs:
		button.toggle_mode = true
		button.size = Vector2(108, 42)
		_style_button(button, false)
	_style_button(start_button, true)
	start_button.size = Vector2(140, 42)
	_layout_top_navigation()
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

func _layout_top_navigation() -> void:
	var next_x := 24.0
	var top_y := 96.0
	var tab_step := 120.0
	var visible_tabs := 0
	var tabs: Array[Button] = [warehouse_tab_button, research_tab_button, crafting_tab_button]
	if catalog_tab_button != null:
		tabs.append(catalog_tab_button)
	for button in tabs:
		if button == null or not button.visible:
			continue
		button.position = Vector2(next_x, top_y)
		button.size = Vector2(108, 42)
		next_x += tab_step
		visible_tabs += 1
	if start_button.visible:
		var action_x := 24.0 if visible_tabs == 0 else next_x + 24.0
		start_button.position = Vector2(action_x, top_y)
		start_button.size = Vector2(140, 42)

func _ensure_catalog_tab_button() -> void:
	if catalog_tab_button != null and is_instance_valid(catalog_tab_button):
		return
	var ui_root := get_node_or_null("BaseUIRoot") as Control
	if ui_root == null:
		return
	catalog_tab_button = ui_root.get_node_or_null("CatalogTabButton") as Button
	if catalog_tab_button != null:
		return
	catalog_tab_button = Button.new()
	catalog_tab_button.name = "CatalogTabButton"
	catalog_tab_button.toggle_mode = true
	catalog_tab_button.text = "图鉴"
	catalog_tab_button.position = Vector2(504, 96)
	catalog_tab_button.size = Vector2(108, 42)
	ui_root.add_child(catalog_tab_button)

func _build_merchant_surface() -> void:
	var roots := base_merchant_panel.build_surface(
		merchant_panel,
		sell_count_spin_box,
		sell_quote_label,
		sell_button,
		buy_count_spin_box,
		buy_quote_label,
		buy_button,
		merchant_result_label
	)
	merchant_sell_grid_root = roots.get("sell_grid_root") as Control
	merchant_shop_grid_root = roots.get("shop_grid_root") as Control
	base_merchant_panel.setup_views(
		merchant_list,
		shop_stock_list,
		item_grid_view,
		merchant_sell_grid_root,
		merchant_shop_grid_root
	)

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
	base_research_panel.setup(
		_game_state,
		base_data_registry,
		Callable(self, "_ensure_base_data_loaded"),
		item_tooltip_view,
		research_list,
		research_button,
		research_quote_label,
		research_result_label,
		research_confirm_dialog,
		research_tree_root,
		research_detail_title_label,
		research_detail_description_label,
		research_requirement_grid_root,
		research_currency_cost_label
	)

func _build_crafting_surface() -> void:
	var ui_root := get_node("BaseUIRoot") as Control
	crafting_panel = _make_base_panel("CraftingPanel", Vector2(24, 154), Vector2(980, 500), "制造所")
	crafting_panel.visible = false
	crafting_status_label = _make_section_label("", Vector2(36, 70), Vector2(650, 160), 18)
	crafting_status_label.name = "CraftingStatusLabel"
	crafting_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_panel.add_child(crafting_status_label)
	crafting_recipe_scroll = _make_scroll_area(Vector2(36, 246), Vector2(650, 188), true)
	crafting_recipe_scroll.name = "CraftingRecipeScroll"
	crafting_recipe_root = Control.new()
	crafting_recipe_root.name = "CraftingRecipeRoot"
	crafting_recipe_scroll.add_child(crafting_recipe_root)
	crafting_panel.add_child(crafting_recipe_scroll)
	crafting_unlock_button = Button.new()
	crafting_unlock_button.name = "CraftingUnlockButton"
	crafting_unlock_button.text = "解锁制造所"
	crafting_unlock_button.position = Vector2(36, 286)
	crafting_unlock_button.size = Vector2(160, 42)
	crafting_unlock_button.pressed.connect(_on_crafting_unlock_pressed)
	_style_button(crafting_unlock_button, true)
	crafting_panel.add_child(crafting_unlock_button)
	crafting_result_label = _make_section_label("", Vector2(36, 440), Vector2(620, 42), 15)
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
	base_crafting_panel.setup(
		_game_state,
		crafting_status_label,
		crafting_unlock_button,
		crafting_result_label,
		manufacturing_confirm_dialog,
		MANUFACTURING_UNLOCK_COST,
		crafting_recipe_root
	)

func _build_catalog_surface() -> void:
	var ui_root := get_node("BaseUIRoot") as Control
	var nodes := base_catalog_panel.build_surface(ui_root)
	catalog_panel = nodes.get("panel") as Panel
	catalog_grid_root = nodes.get("grid_root") as Control
	catalog_status_label = nodes.get("status_label") as Label

func _set_catalog_items(items: Array) -> void:
	base_catalog_panel.set_items(items)

func _build_debug_story_tools() -> void:
	if debug_panel == null:
		return
	debug_panel.offset_top = 190.0
	debug_panel.offset_bottom = 876.0
	debug_reset_profile_button = _make_debug_button("重置本地数据", 356.0, _on_debug_reset_profile_pressed)
	debug_reset_story_button = _make_debug_button("重置剧情与章节", 398.0, _on_debug_reset_story_pressed)
	debug_add_chapter_currency_button = _make_debug_button("+100 矿币", 440.0, _on_debug_add_chapter_currency_pressed)
	debug_surface_day_button = _make_debug_button("地表天数 +1", 482.0, _on_debug_surface_day_pressed)
	debug_force_chapter_complete_button = _make_debug_button("强制完成第一章", 524.0, _on_debug_force_chapter_complete_pressed)
	debug_slow_loading_button = _make_debug_button("下次慢加载", 566.0, _on_debug_slow_loading_pressed)
	debug_fail_loading_button = _make_debug_button("下次加载失败", 608.0, _on_debug_fail_loading_pressed)
	debug_force_monster_button = _make_debug_button("本日必出怪物", 650.0, _on_debug_force_monster_pressed)
	_make_debug_button("点亮全部图鉴", 692.0, _on_debug_collect_all_catalog_pressed)
	_make_debug_button("清空图鉴", 734.0, _on_debug_clear_catalog_pressed)
	_set_control_rect(debug_result_label, Vector2(12, 776), Vector2(204, 58))

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
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.54, 0.50, 0.62))
	var border := Color("#D1B850") if important else Color("#35C9D7")
	button.add_theme_stylebox_override("normal", _panel_style(Color("#071116"), border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#121817"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.06, 0.06, 0.058, 0.55), Color("#4D575B"), 1))

func _set_warehouse_items_text(items: Array) -> void:
	var capacity: int = _game_state.get_warehouse_capacity() if _game_state != null and _game_state.has_method("get_warehouse_capacity") else items.size()
	var max_capacity := capacity
	if _game_state != null and _game_state.has_method("get_warehouse_max_capacity"):
		max_capacity = int(_game_state.get_warehouse_max_capacity())
	base_warehouse_panel.set_items(items, capacity, max_capacity, TAB_WAREHOUSE)

func _set_merchant_items_text(items: Array) -> void:
	base_merchant_panel.set_sell_items_text(items)

func _set_shop_stock_text(items: Array) -> void:
	base_merchant_panel.set_shop_stock_text(items)

func _set_research_items_text(items: Array) -> void:
	base_research_panel.set_items_text(items)
	_selected_research_id = base_research_panel.selected_research_id

func _is_grid_slot_selected(source_id: String, meta_id: String, index: int) -> bool:
	return base_merchant_panel.is_slot_selected(source_id, meta_id, index)

func _bind_base_item_tooltip(anchor: Control, item: Dictionary, source_id: String, context: Dictionary = {}) -> void:
	if anchor == null:
		return
	item_tooltip_view.bind(anchor, item, source_id, context)

func _hide_item_tooltip(_reason: String = "") -> void:
	item_tooltip_view.hide(_reason)

func _dispatch_grid_slot(source_id: String, meta_id: String, index: int) -> void:
	match source_id:
		TAB_WAREHOUSE:
			_on_warehouse_item_meta_clicked("warehouse:%d" % index)
		"sell":
			base_merchant_panel.select_sell(meta_id, index)
			_refresh()
		"buy":
			base_merchant_panel.select_buy(meta_id, index)
			_refresh()

func _currency_name(currency_id: String) -> String:
	if _ensure_base_data_loaded():
		var definition: Dictionary = base_data_registry.get_currency(currency_id)
		if not definition.is_empty():
			return String(definition.get("name", currency_id))
	match currency_id:
		"mine_coin":
			return "矿币"
		_:
			return currency_id

func _ensure_base_data_loaded() -> bool:
	if base_data_loaded:
		return true
	base_data_loaded = base_data_registry.load_all()
	if not base_data_loaded and debug_result_label != null:
		debug_result_label.text = "局外配置表加载失败：%s" % str(base_data_registry.load_errors)
	return base_data_loaded

func _update_selected_research_state() -> void:
	base_research_panel.set_selected_research_id(_selected_research_id)
	base_research_panel.update_selected_state()
	_selected_research_id = base_research_panel.selected_research_id

func _update_research_detail(quote: Dictionary) -> void:
	base_research_panel.set_selected_research_id(_selected_research_id)
	base_research_panel.update_selected_state()
	_selected_research_id = base_research_panel.selected_research_id

func _update_chapter_goal_view() -> void:
	if chapter_goal_label == null:
		return
	if _game_state == null or not _game_state.has_method("get_chapter_goal_snapshot"):
		chapter_goal_label.text = ""
		return
	var snapshot: Dictionary = _game_state.get_chapter_goal_snapshot()
	if bool(snapshot.get("active", false)):
		chapter_goal_label.text = "第一章：解锁制造所\n目标：购买制造机，解锁制造所\n矿币 %d / %d" % [
			int(snapshot.get("current_currency", 0)),
			int(snapshot.get("required_currency", MANUFACTURING_UNLOCK_COST)),
		]
	elif bool(snapshot.get("completed", false)):
		chapter_goal_label.text = "第一章已完成\n制造所已解锁"
	else:
		chapter_goal_label.text = ""

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
	base_warehouse_panel.show_selected_item(item)

func _on_merchant_item_meta_clicked(meta: Variant) -> void:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "sell":
		return
	base_merchant_panel.select_sell(parts[1])

func _on_shop_stock_meta_clicked(meta: Variant) -> void:
	var parts := String(meta).split(":", false, 1)
	if parts.size() != 2 or parts[0] != "buy":
		return
	base_merchant_panel.select_buy(parts[1])

func _on_research_meta_clicked(meta: Variant) -> void:
	if base_research_panel.handle_meta_clicked(meta):
		_selected_research_id = base_research_panel.selected_research_id

func _on_sell_count_changed(_value: float) -> void:
	base_merchant_panel.update_selected_sell_state()

func _on_buy_count_changed(_value: float) -> void:
	base_merchant_panel.update_selected_buy_state()

func _on_sell_pressed() -> void:
	var result: Dictionary = base_merchant_panel.sell_selected()
	merchant_result_label.text = String(result.get("message", "出售失败。"))
	_refresh()

func _on_buy_pressed() -> void:
	var result: Dictionary = base_merchant_panel.buy_selected()
	merchant_result_label.text = String(result.get("message", "购买失败。"))
	_refresh()

func _on_research_pressed() -> void:
	base_research_panel.set_selected_research_id(_selected_research_id)
	base_research_panel.request_research()
	_selected_research_id = base_research_panel.selected_research_id

func _on_research_confirmed() -> void:
	base_research_panel.set_selected_research_id(_selected_research_id)
	base_research_panel.confirm_research()
	_selected_research_id = base_research_panel.selected_research_id
	_refresh()

func _on_crafting_unlock_pressed() -> void:
	base_crafting_panel.request_unlock()

func _on_manufacturing_unlock_confirmed() -> void:
	var result: Dictionary = base_crafting_panel.confirm_unlock()
	_refresh()

func _on_debug_add_currency_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.add_currency(_game_state).get("message", "增加矿币失败。"))
	_refresh()

func _on_debug_add_sell_items_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.add_sell_test_items(_game_state).get("message", "加入可售卖测试道具失败。"))
	_show_tab(TAB_WAREHOUSE)

func _on_debug_add_research_costs_pressed() -> void:
	var result := base_debug_actions.fill_next_research_costs(_game_state, _selected_research_id)
	debug_result_label.text = String(result.get("message", "补齐研究资源失败。"))
	_show_tab(TAB_RESEARCH)

func _on_debug_refresh_shop_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.refresh_shop(_game_state, 1).get("message", "刷新商人库存失败。"))
	_show_tab(TAB_WAREHOUSE)

func _on_debug_max_shop_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.refresh_shop(_game_state, 3).get("message", "刷新商人库存失败。"))
	_show_tab(TAB_MERCHANT)

func _on_debug_complete_research_pressed() -> void:
	var result := base_debug_actions.complete_next_research(_game_state, _selected_research_id)
	debug_result_label.text = String(result.get("message", "研究失败。"))
	_selected_research_id = ""
	base_research_panel.clear_selection()
	_show_tab(TAB_RESEARCH)

func _on_debug_reset_research_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.reset_research(_game_state).get("message", "重置研究等级失败。"))
	_selected_research_id = ""
	base_research_panel.clear_selection()
	_show_tab(TAB_RESEARCH)

func _on_debug_reset_profile_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.reset_profile(_game_state).get("message", "重置本地数据失败。"))
	_refresh()

func _on_debug_reset_story_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.reset_story(_game_state).get("message", "重置剧情 flag 失败。"))
	_refresh()

func _on_debug_add_chapter_currency_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.add_chapter_currency(_game_state).get("message", "增加章节矿币失败。"))
	_refresh()

func _on_debug_surface_day_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.advance_surface_day(_game_state).get("message", "地表天数调整失败。"))
	_refresh()

func _on_debug_force_chapter_complete_pressed() -> void:
	var result := base_debug_actions.force_chapter_complete(_game_state, MANUFACTURING_UNLOCK_COST)
	debug_result_label.text = String(result.get("message", "强制完成第一章失败。"))
	_refresh()

func _on_debug_force_monster_pressed() -> void:
	debug_result_label.text = String(base_debug_actions.force_monster_next_run(_game_state).get("message", "强制怪物事件失败。"))

func _on_debug_slow_loading_pressed() -> void:
	_debug_slow_next_loading = true
	debug_result_label.text = "下次出发将使用慢速加载。"

func _on_debug_fail_loading_pressed() -> void:
	_debug_fail_next_loading = true
	debug_result_label.text = "下次出发将模拟加载失败。"

func _on_debug_collect_all_catalog_pressed() -> void:
	if _game_state == null or not _game_state.has_method("mark_all_catalog_items_collected_debug_only"):
		debug_result_label.text = "GameState 不支持图鉴点亮。"
		return
	var result: Dictionary = _game_state.mark_all_catalog_items_collected_debug_only()
	debug_result_label.text = "已点亮全部图鉴：%d 项。" % Array(result.get("marked_item_ids", [])).size()
	_show_tab(TAB_CATALOG)

func _on_debug_clear_catalog_pressed() -> void:
	if _game_state == null or not _game_state.has_method("clear_collected_items_debug_only"):
		debug_result_label.text = "GameState 不支持清空图鉴。"
		return
	_game_state.clear_collected_items_debug_only()
	debug_result_label.text = "已清空图鉴点亮记录。"
	_show_tab(TAB_CATALOG)

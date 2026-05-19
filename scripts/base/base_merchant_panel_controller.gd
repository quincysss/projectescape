class_name BaseMerchantPanelController
extends RefCounted

var game_state: Node
var sell_count_spin_box: SpinBox
var sell_quote_label: Label
var sell_button: Button
var buy_count_spin_box: SpinBox
var buy_quote_label: Label
var buy_button: Button
var result_label: Label
var currency_name_provider: Callable
var merchant_list: RichTextLabel
var shop_stock_list: RichTextLabel
var item_grid_view
var merchant_sell_grid_root: Control
var merchant_shop_grid_root: Control

var selected_sell_group_id := ""
var selected_shop_offer_id := ""
var selected_sell_slot_index := -1
var selected_buy_slot_index := -1

func setup(
	p_game_state: Node,
	p_sell_count_spin_box: SpinBox,
	p_sell_quote_label: Label,
	p_sell_button: Button,
	p_buy_count_spin_box: SpinBox,
	p_buy_quote_label: Label,
	p_buy_button: Button,
	p_result_label: Label,
	p_currency_name_provider: Callable
) -> void:
	game_state = p_game_state
	sell_count_spin_box = p_sell_count_spin_box
	sell_quote_label = p_sell_quote_label
	sell_button = p_sell_button
	buy_count_spin_box = p_buy_count_spin_box
	buy_quote_label = p_buy_quote_label
	buy_button = p_buy_button
	result_label = p_result_label
	currency_name_provider = p_currency_name_provider
	clear_selection()

func build_surface(
	merchant_panel: Panel,
	p_sell_count_spin_box: SpinBox,
	p_sell_quote_label: Label,
	p_sell_button: Button,
	p_buy_count_spin_box: SpinBox,
	p_buy_quote_label: Label,
	p_buy_button: Button,
	p_result_label: Label
) -> Dictionary:
	if merchant_panel == null:
		return {}
	_set_control_rect(merchant_panel, Vector2(24, 154), Vector2(980, 500))
	merchant_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.058, 0.93), Color(0.26, 0.25, 0.23, 0.95), 1))
	merchant_panel.add_child(_make_section_label("局外商人", Vector2(18, 12), Vector2(160, 30), 20))
	merchant_panel.add_child(_make_section_label("商人库存", Vector2(18, 48), Vector2(180, 24), 16))
	merchant_panel.add_child(_make_section_label("仓库可售", Vector2(410, 48), Vector2(180, 24), 16))

	var buy_scroll := _make_scroll_area(Vector2(18, 78), Vector2(376, 348))
	merchant_shop_grid_root = Control.new()
	merchant_shop_grid_root.name = "MerchantShopGrid"
	buy_scroll.add_child(merchant_shop_grid_root)
	merchant_panel.add_child(buy_scroll)

	var sell_scroll := _make_scroll_area(Vector2(410, 78), Vector2(376, 348))
	merchant_sell_grid_root = Control.new()
	merchant_sell_grid_root.name = "MerchantSellGrid"
	sell_scroll.add_child(merchant_sell_grid_root)
	merchant_panel.add_child(sell_scroll)

	merchant_panel.add_child(_make_section_label("出售数量", Vector2(812, 76), Vector2(130, 22), 15))
	_set_control_rect(p_sell_count_spin_box, Vector2(812, 102), Vector2(120, 32))
	_set_control_rect(p_sell_quote_label, Vector2(812, 146), Vector2(150, 92))
	_set_control_rect(p_sell_button, Vector2(812, 248), Vector2(120, 38))
	merchant_panel.add_child(_make_section_label("购买数量", Vector2(812, 304), Vector2(130, 22), 15))
	_set_control_rect(p_buy_count_spin_box, Vector2(812, 330), Vector2(120, 32))
	_set_control_rect(p_buy_quote_label, Vector2(812, 374), Vector2(150, 70))
	_set_control_rect(p_buy_button, Vector2(812, 450), Vector2(120, 38))
	_set_control_rect(p_result_label, Vector2(18, 438), Vector2(768, 46))
	_style_button(p_sell_button, true)
	_style_button(p_buy_button, true)
	_style_label(p_sell_quote_label, 15, Color("#D8D6CE"))
	_style_label(p_buy_quote_label, 15, Color("#D8D6CE"))
	_style_label(p_result_label, 15, Color("#8DB6B9"))
	return {
		"sell_grid_root": merchant_sell_grid_root,
		"shop_grid_root": merchant_shop_grid_root,
	}

func setup_views(
	p_merchant_list: RichTextLabel,
	p_shop_stock_list: RichTextLabel,
	p_item_grid_view,
	p_sell_grid_root: Control = null,
	p_shop_grid_root: Control = null
) -> void:
	merchant_list = p_merchant_list
	shop_stock_list = p_shop_stock_list
	item_grid_view = p_item_grid_view
	if p_sell_grid_root != null:
		merchant_sell_grid_root = p_sell_grid_root
	if p_shop_grid_root != null:
		merchant_shop_grid_root = p_shop_grid_root

func set_game_state(p_game_state: Node) -> void:
	game_state = p_game_state
	refresh_selection()

func clear_selection() -> void:
	selected_sell_group_id = ""
	selected_shop_offer_id = ""
	selected_sell_slot_index = -1
	selected_buy_slot_index = -1
	_reset_sell_controls()
	_reset_buy_controls()

func clear_result() -> void:
	if result_label != null:
		result_label.text = ""

func set_sell_items_text(items: Array) -> void:
	if merchant_list == null:
		return
	merchant_list.clear()
	var sell_slots := expand_sell_groups_to_slots(items)
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

func set_shop_stock_text(items: Array) -> void:
	if shop_stock_list == null:
		return
	shop_stock_list.clear()
	var level := 1
	if game_state != null and game_state.has_method("get_merchant_shop_level"):
		level = int(game_state.get_merchant_shop_level())
	var level_text := "Lv.%d" % level
	var shop_slots := expand_shop_offers_to_slots(items)
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

func select_sell(group_id: String, slot_index: int = -1, reset_count: bool = true) -> void:
	selected_sell_group_id = group_id
	selected_sell_slot_index = slot_index
	clear_result()
	if reset_count and sell_count_spin_box != null:
		sell_count_spin_box.value = 1
	update_selected_sell_state()

func select_buy(offer_id: String, slot_index: int = -1, reset_count: bool = true) -> void:
	selected_shop_offer_id = offer_id
	selected_buy_slot_index = slot_index
	clear_result()
	if reset_count and buy_count_spin_box != null:
		buy_count_spin_box.value = 1
	update_selected_buy_state()

func refresh_selection() -> void:
	update_selected_sell_state()
	update_selected_buy_state()

func update_selected_sell_state() -> void:
	var selected_group := find_sell_group(selected_sell_group_id)
	if selected_group.is_empty():
		selected_sell_group_id = ""
		selected_sell_slot_index = -1
		_reset_sell_controls()
		return
	var max_count := maxi(1, int(selected_group.get("count", 1)))
	if not is_grid_meta_slot_valid("sell", selected_sell_group_id, selected_sell_slot_index):
		selected_sell_slot_index = first_grid_meta_slot_index("sell", selected_sell_group_id)
	sell_count_spin_box.min_value = 1
	sell_count_spin_box.max_value = max_count
	sell_count_spin_box.value = clampi(int(sell_count_spin_box.value), 1, max_count)
	_update_sell_quote(game_state.get_sell_quote(selected_sell_group_id, int(sell_count_spin_box.value)))

func update_selected_buy_state() -> void:
	var selected_offer := find_shop_offer(selected_shop_offer_id)
	if selected_offer.is_empty():
		selected_shop_offer_id = ""
		selected_buy_slot_index = -1
		_reset_buy_controls()
		return
	var max_count := maxi(1, int(selected_offer.get("count", 1)))
	if not is_grid_meta_slot_valid("buy", selected_shop_offer_id, selected_buy_slot_index):
		selected_buy_slot_index = first_grid_meta_slot_index("buy", selected_shop_offer_id)
	buy_count_spin_box.min_value = 1
	buy_count_spin_box.max_value = max_count
	buy_count_spin_box.value = clampi(int(buy_count_spin_box.value), 1, max_count)
	_update_buy_quote(game_state.get_buy_quote(selected_shop_offer_id, int(buy_count_spin_box.value)))

func sell_selected() -> Dictionary:
	if game_state == null or selected_sell_group_id.is_empty():
		return {"ok": false, "message": "请选择要出售的道具。"}
	var result: Dictionary = game_state.sell_warehouse_item(selected_sell_group_id, int(sell_count_spin_box.value))
	if result_label != null:
		result_label.text = String(result.get("message", "出售失败。"))
	if bool(result.get("ok", false)):
		selected_sell_group_id = ""
		selected_sell_slot_index = -1
	return result

func buy_selected() -> Dictionary:
	if game_state == null or selected_shop_offer_id.is_empty():
		return {"ok": false, "message": "请选择要购买的商人库存。"}
	var result: Dictionary = game_state.buy_shop_item(selected_shop_offer_id, int(buy_count_spin_box.value))
	if result_label != null:
		result_label.text = String(result.get("message", "购买失败。"))
	if bool(result.get("ok", false)):
		selected_shop_offer_id = ""
		selected_buy_slot_index = -1
	return result

func is_slot_selected(source_id: String, meta_id: String, slot_index: int) -> bool:
	return (
		source_id == "sell"
		and meta_id == selected_sell_group_id
		and slot_index == selected_sell_slot_index
	) or (
		source_id == "buy"
		and meta_id == selected_shop_offer_id
		and slot_index == selected_buy_slot_index
	)

func expand_sell_groups_to_slots(groups: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group in groups:
		if not (group is Dictionary):
			continue
		var group_dict: Dictionary = group
		var count := maxi(0, int(group_dict.get("count", 0)))
		for _index in range(count):
			var slot := group_dict.duplicate(true)
			slot["grid_meta_id"] = String(group_dict.get("warehouse_item_id", ""))
			slot["amount"] = 1
			slot["count"] = 1
			result.append(slot)
	return result

func expand_shop_offers_to_slots(offers: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for offer in offers:
		if not (offer is Dictionary):
			continue
		var offer_dict: Dictionary = offer
		var count := maxi(0, int(offer_dict.get("count", 0)))
		var offer_id := String(offer_dict.get("shop_offer_id", ""))
		for _index in range(count):
			var slot := offer_dict.duplicate(true)
			slot["grid_meta_id"] = offer_id
			slot["amount"] = 1
			slot["count"] = 1
			result.append(slot)
	return result

func find_sell_group(warehouse_item_id: String) -> Dictionary:
	if game_state == null or warehouse_item_id.is_empty():
		return {}
	for item in game_state.query_sellable_items():
		if String(item.get("warehouse_item_id", "")) == warehouse_item_id:
			return item
	return {}

func find_shop_offer(shop_offer_id: String) -> Dictionary:
	if game_state == null or shop_offer_id.is_empty():
		return {}
	for item in game_state.query_shop_offers():
		if String(item.get("shop_offer_id", "")) == shop_offer_id:
			return item
	return {}

func is_grid_meta_slot_valid(source_id: String, meta_id: String, slot_index: int) -> bool:
	var slots := current_merchant_slots(source_id)
	return slot_index >= 0 and slot_index < slots.size() and String(slots[slot_index].get("grid_meta_id", "")) == meta_id

func first_grid_meta_slot_index(source_id: String, meta_id: String) -> int:
	var slots := current_merchant_slots(source_id)
	for index in range(slots.size()):
		if String(slots[index].get("grid_meta_id", "")) == meta_id:
			return index
	return -1

func current_merchant_slots(source_id: String) -> Array[Dictionary]:
	if game_state == null:
		return []
	match source_id:
		"sell":
			return expand_sell_groups_to_slots(game_state.query_sellable_items())
		"buy":
			return expand_shop_offers_to_slots(game_state.query_shop_offers())
		_:
			return []

func _reset_sell_controls() -> void:
	if sell_count_spin_box != null:
		sell_count_spin_box.min_value = 1
		sell_count_spin_box.max_value = 1
		sell_count_spin_box.value = 1
	_update_sell_quote({})

func _reset_buy_controls() -> void:
	if buy_count_spin_box != null:
		buy_count_spin_box.min_value = 1
		buy_count_spin_box.max_value = 1
		buy_count_spin_box.value = 1
	_update_buy_quote({})

func _update_sell_quote(quote: Dictionary) -> void:
	var ok := bool(quote.get("ok", false))
	if sell_button != null:
		sell_button.disabled = not ok
	if sell_quote_label == null:
		return
	if not ok:
		sell_quote_label.text = "选择一个可出售道具"
		return
	var currency_id := String(quote.get("sell_currency_id", "mine_coin"))
	sell_quote_label.text = "出售 %s x%d，可获得 %d %s。当前 %s" % [
		String(quote.get("display_name", "")),
		int(quote.get("count", 0)),
		int(quote.get("total_value", 0)),
		_currency_name(currency_id),
		_currency_display_text(currency_id),
	]

func _update_buy_quote(quote: Dictionary) -> void:
	var ok := bool(quote.get("ok", false))
	if buy_button != null:
		buy_button.disabled = not ok
	if buy_quote_label == null:
		return
	if not ok:
		buy_quote_label.text = "选择一个商人资源"
		return
	var currency_id := String(quote.get("buy_currency_id", "mine_coin"))
	buy_quote_label.text = "购买 %s x%d，需要 %d %s。当前 %s" % [
		String(quote.get("display_name", "")),
		int(quote.get("count", 0)),
		int(quote.get("total_price", 0)),
		_currency_name(currency_id),
		_currency_display_text(currency_id),
	]

func _currency_name(currency_id: String) -> String:
	if currency_name_provider.is_valid():
		return String(currency_name_provider.call(currency_id))
	match currency_id:
		"mine_coin":
			return "矿币"
		_:
			return currency_id

func _currency_display_text(currency_id: String) -> String:
	if game_state != null and game_state.has_method("get_currency_display_text"):
		return String(game_state.get_currency_display_text(currency_id))
	return "%s 0" % _currency_name(currency_id)

func _set_item_grid(grid_root: Control, items: Array, capacity: int, source_id: String) -> void:
	if grid_root == null or item_grid_view == null:
		return
	item_grid_view.set_grid(grid_root, items, capacity, source_id)

func _set_control_rect(control: Control, pos: Vector2, control_size: Vector2) -> void:
	if control == null:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = pos
	control.size = control_size

func _make_scroll_area(pos: Vector2, scroll_size: Vector2) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.position = pos
	scroll.size = scroll_size
	scroll.clip_contents = true
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
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

func _style_button(button: Button, important: bool) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#D8D6CE"))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.54, 0.50, 0.62))
	var border := Color("#D1B850") if important else Color("#35C9D7")
	button.add_theme_stylebox_override("normal", _panel_style(Color("#071116"), border, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#0B151A"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#121817"), Color("#D1B850"), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.06, 0.06, 0.058, 0.55), Color("#4D575B"), 1))

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

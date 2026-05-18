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

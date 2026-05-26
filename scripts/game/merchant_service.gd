class_name MerchantService
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

const DEFAULT_CURRENCY_ID := "mine_coin"
const DEFAULT_SHOP_ID := "base_merchant"
const DEFAULT_SHOP_LEVEL := 1
const MAX_SHOP_LEVEL := 3

var warehouse_manager: WarehouseManager
var currency_wallet: CurrencyWallet
var shop_offers: Array[Dictionary] = []
var shop_level: int = DEFAULT_SHOP_LEVEL
var data_registry = GameDataRegistryScript.new()
var _data_loaded := false

func bind_dependencies(
	bound_warehouse_manager: WarehouseManager,
	bound_currency_wallet: CurrencyWallet,
	bound_shop_offers: Array[Dictionary] = [],
	bound_shop_level: int = DEFAULT_SHOP_LEVEL
) -> void:
	warehouse_manager = bound_warehouse_manager
	currency_wallet = bound_currency_wallet
	shop_offers = bound_shop_offers
	shop_level = clampi(bound_shop_level, DEFAULT_SHOP_LEVEL, MAX_SHOP_LEVEL)

func query_sellable_items(_filters: Dictionary = {}) -> Array[Dictionary]:
	if warehouse_manager == null:
		return []

	var groups := {}
	var items := warehouse_manager.get_items_snapshot()
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if not _can_sell_item(item):
			continue
		var item_id := String(item.get("item_id", ""))
		var item_type := String(item.get("item_type", ""))
		var quality := String(item.get("quality", "C"))
		var currency_id := _get_sell_currency_id(item)
		var unit_value := int(item.get("sell_value", 0))
		var group_id := _make_group_id(item_id, item_type, quality, currency_id, unit_value)
		if not groups.has(group_id):
			groups[group_id] = {
				"warehouse_item_id": group_id,
				"item_id": item_id,
				"item_type": item_type,
				"quality": quality,
				"display_name": String(item.get("display_name", item_id)),
				"icon": String(item.get("icon", "")),
				"sell_currency_id": currency_id,
				"sell_value": unit_value,
				"count": 0,
				"total_value": 0,
				"warehouse_indexes": [],
			}
		var stack_count := maxi(1, int(item.get("amount", 1)))
		groups[group_id].count += stack_count
		groups[group_id].total_value += unit_value * stack_count
		groups[group_id].warehouse_indexes.append(index)

	var result: Array[Dictionary] = []
	for group in groups.values():
		result.append(Dictionary(group).duplicate(true))
	result.sort_custom(func(a, b):
		var value_delta := int(b.get("sell_value", 0)) - int(a.get("sell_value", 0))
		if value_delta != 0:
			return value_delta < 0
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return result

func get_sell_quote(warehouse_item_id: String, count: int) -> Dictionary:
	var group := _find_group(warehouse_item_id)
	if group.is_empty():
		return _fail("item_not_found", "No sellable warehouse item found.")
	var available := int(group.get("count", 0))
	if count <= 0:
		return _fail("invalid_count", "Sell count must be greater than 0.")
	if count > available:
		return _fail("not_enough_items", "Not enough warehouse items.")

	var unit_value := int(group.get("sell_value", 0))
	var total_value := unit_value * count
	if unit_value <= 0 or total_value <= 0:
		return _fail("invalid_value", "Item has no valid sell value.")
	return {
		"ok": true,
		"warehouse_item_id": warehouse_item_id,
		"item_id": String(group.get("item_id", "")),
		"display_name": String(group.get("display_name", "")),
		"count": count,
		"max_count": available,
		"sell_currency_id": String(group.get("sell_currency_id", DEFAULT_CURRENCY_ID)),
		"unit_value": unit_value,
		"total_value": total_value,
	}

func sell_warehouse_item(warehouse_item_id: String, count: int) -> Dictionary:
	if warehouse_manager == null or currency_wallet == null:
		return _fail("service_unavailable", "Merchant service unavailable.")

	var quote := get_sell_quote(warehouse_item_id, count)
	if not bool(quote.get("ok", false)):
		return quote

	var group := _find_group(warehouse_item_id)
	var removed := _remove_group_quantity(group, count)
	if _count_removed_amount(removed) != count:
		warehouse_manager.restore_removed_items(removed)
		return _fail("remove_failed", "Sale failed because warehouse removal failed.")

	var currency_id := String(quote.get("sell_currency_id", DEFAULT_CURRENCY_ID))
	var total_value := int(quote.get("total_value", 0))
	var currency_result: Dictionary = currency_wallet.add_currency(currency_id, total_value, "merchant_sell")
	if not bool(currency_result.get("ok", false)):
		warehouse_manager.restore_removed_items(removed)
		return _fail("currency_failed", String(currency_result.get("message", "Currency settlement failed.")))

	var result := quote.duplicate(true)
	result["message"] = "Sold %s x%d for %d %s." % [
		String(quote.get("display_name", "")),
		count,
		total_value,
		_currency_name(currency_id),
	]
	result["currency_amount"] = int(currency_result.get("amount", 0))
	return result

func query_shop_offers(_filters: Dictionary = {}) -> Array[Dictionary]:
	if shop_offers.is_empty():
		refresh_shop_stock()
	var result: Array[Dictionary] = []
	for offer in shop_offers:
		if int(offer.get("count", 0)) <= 0:
			continue
		result.append(offer.duplicate(true))
	result.sort_custom(func(a, b):
		var level_delta := int(a.get("min_shop_level", 1)) - int(b.get("min_shop_level", 1))
		if level_delta != 0:
			return level_delta < 0
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return result

func refresh_shop_stock(seed: int = -1) -> Array[Dictionary]:
	_ensure_data_loaded()
	shop_offers.clear()
	var rows := data_registry.get_shop_stock_rows_for_level(shop_level, DEFAULT_SHOP_ID)
	if rows.is_empty():
		return []

	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()

	var candidates: Array[Dictionary] = []
	for row in rows:
		candidates.append(row.duplicate(true))
	var offer_slots := mini(_get_offer_slot_count(shop_level), candidates.size())
	for offer_index in range(offer_slots):
		var picked_index := _pick_weighted_shop_row_index(candidates, rng)
		if picked_index < 0:
			break
		var row: Dictionary = candidates[picked_index]
		candidates.remove_at(picked_index)
		var offer := _make_shop_offer(row, rng, offer_index)
		if not offer.is_empty():
			shop_offers.append(offer)
	return query_shop_offers()

func get_buy_quote(shop_offer_id: String, count: int) -> Dictionary:
	var offer := _find_shop_offer(shop_offer_id)
	if offer.is_empty():
		return _fail("offer_not_found", "Merchant stock offer not found.")
	var available := int(offer.get("count", 0))
	if count <= 0:
		return _fail("invalid_count", "Buy count must be greater than 0.")
	if count > available:
		return _fail("not_enough_stock", "Merchant stock is not enough.")

	var unit_price := int(offer.get("buy_price", 0))
	var total_price := unit_price * count
	if unit_price <= 0 or total_price <= 0:
		return _fail("invalid_price", "Offer has no valid buy price.")
	var currency_id := String(offer.get("buy_currency_id", DEFAULT_CURRENCY_ID))
	var current_amount := currency_wallet.get_currency_amount(currency_id) if currency_wallet != null else 0
	if current_amount < total_price:
		return _fail("not_enough_currency", "Not enough currency.")
	return {
		"ok": true,
		"shop_offer_id": shop_offer_id,
		"item_id": String(offer.get("item_id", "")),
		"display_name": String(offer.get("display_name", "")),
		"count": count,
		"max_count": available,
		"buy_currency_id": currency_id,
		"unit_price": unit_price,
		"total_price": total_price,
		"currency_amount": current_amount,
	}

func buy_shop_item(shop_offer_id: String, count: int) -> Dictionary:
	if warehouse_manager == null or currency_wallet == null:
		return _fail("service_unavailable", "Merchant service unavailable.")
	var quote := get_buy_quote(shop_offer_id, count)
	if not bool(quote.get("ok", false)):
		return quote

	_ensure_data_loaded()
	var item_id := String(quote.get("item_id", ""))
	var stack := data_registry.make_item_stack(item_id, count)
	if stack.is_empty():
		return _fail("item_not_found", "Item configuration missing.")
	stack["source"] = "merchant_shop"

	var currency_id := String(quote.get("buy_currency_id", DEFAULT_CURRENCY_ID))
	var total_price := int(quote.get("total_price", 0))
	var spend_result: Dictionary = currency_wallet.spend_currency(currency_id, total_price, "merchant_buy")
	if not bool(spend_result.get("ok", false)):
		return _fail(String(spend_result.get("reason", "currency_failed")), "Currency spend failed.")

	var accepted := warehouse_manager.add_items([stack])
	if accepted.size() != 1 or int(accepted[0].get("amount", 0)) != count:
		currency_wallet.add_currency(currency_id, total_price, "merchant_buy_refund")
		return _fail("warehouse_add_failed", "Purchase failed because warehouse add failed.")

	var offer := _find_shop_offer(shop_offer_id)
	if not offer.is_empty():
		offer["count"] = maxi(0, int(offer.get("count", 0)) - count)

	var result := quote.duplicate(true)
	result["message"] = "Bought %s x%d for %d %s." % [
		String(quote.get("display_name", "")),
		count,
		total_price,
		_currency_name(currency_id),
	]
	result["currency_amount"] = int(spend_result.get("new_currency_amount", 0))
	return result

func _find_group(warehouse_item_id: String) -> Dictionary:
	for group in query_sellable_items():
		if String(group.get("warehouse_item_id", "")) == warehouse_item_id:
			return group
	return {}

func _find_shop_offer(shop_offer_id: String) -> Dictionary:
	for offer in shop_offers:
		if String(offer.get("shop_offer_id", "")) == shop_offer_id:
			return offer
	return {}

func _remove_group_quantity(group: Dictionary, count: int) -> Array[Dictionary]:
	var removed: Array[Dictionary] = []
	if warehouse_manager == null or count <= 0:
		return removed
	var indexes: Array = Array(group.get("warehouse_indexes", []))
	indexes.sort_custom(func(a, b):
		return int(a) > int(b)
	)
	var remaining := count
	for raw_index in indexes:
		if remaining <= 0:
			break
		var removed_item := warehouse_manager.remove_item_quantity_at_index(int(raw_index), remaining)
		if removed_item.is_empty():
			break
		removed.append({"index": int(raw_index), "item": removed_item})
		remaining -= int(removed_item.get("amount", 0))
	return removed

func _count_removed_amount(removed_entries: Array) -> int:
	var count := 0
	for entry in removed_entries:
		if entry is Dictionary and entry.has("item") and entry.get("item", {}) is Dictionary:
			count += maxi(1, int(Dictionary(entry.get("item", {})).get("amount", 1)))
	return count

func _make_shop_offer(row: Dictionary, rng: RandomNumberGenerator, offer_index: int) -> Dictionary:
	var item_id := String(row.get("item_id", ""))
	var item_def := data_registry.get_item(item_id)
	if item_def.is_empty():
		return {}
	var min_count: int = maxi(1, int(row.get("min_count", 1)))
	var max_count: int = maxi(min_count, int(row.get("max_count", min_count)))
	var count := rng.randi_range(min_count, max_count)
	var buy_price := maxi(0, int(item_def.get("sell_value", 0)))
	var buy_currency_id := String(item_def.get("sell_currency_id", row.get("buy_currency_id", DEFAULT_CURRENCY_ID)))
	if buy_currency_id.is_empty():
		buy_currency_id = DEFAULT_CURRENCY_ID
	if count <= 0 or buy_price <= 0:
		return {}
	return {
		"shop_offer_id": "%s:%d:%s" % [DEFAULT_SHOP_ID, offer_index, item_id],
		"shop_id": DEFAULT_SHOP_ID,
		"shop_level": shop_level,
		"min_shop_level": int(row.get("min_shop_level", 1)),
		"item_id": item_id,
		"display_name": String(item_def.get("name", item_id)),
		"icon": String(item_def.get("icon", "")),
		"item_type": String(item_def.get("item_type", "")),
		"quality": String(item_def.get("quality", "C")),
		"count": count,
		"buy_currency_id": buy_currency_id,
		"buy_price": buy_price,
	}

func _pick_weighted_shop_row_index(rows: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	var total_weight := 0
	for row in rows:
		total_weight += maxi(0, int(row.get("weight", 0)))
	if total_weight <= 0:
		return -1
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for index in range(rows.size()):
		cursor += maxi(0, int(rows[index].get("weight", 0)))
		if roll <= cursor:
			return index
	return rows.size() - 1

func _get_offer_slot_count(level: int) -> int:
	match clampi(level, DEFAULT_SHOP_LEVEL, MAX_SHOP_LEVEL):
		1:
			return 3
		2:
			return 4
		_:
			return 5

func _ensure_data_loaded() -> void:
	if _data_loaded:
		return
	_data_loaded = data_registry.load_all()

func _can_sell_item(item: Dictionary) -> bool:
	if String(item.get("item_id", "")).is_empty():
		return false
	if not _parse_bool(item.get("sellable", false)):
		return false
	if int(item.get("sell_value", 0)) <= 0:
		return false
	if String(item.get("item_type", "")) == "material":
		return false
	if not String(item.get("repair_material_id", "")).is_empty():
		return false
	for tag in _get_tags(item):
		var normalized := String(tag)
		if normalized == "quest" or normalized == "key" or normalized == "debug":
			return false
	return true

func _get_sell_currency_id(item: Dictionary) -> String:
	var currency_id := String(item.get("sell_currency_id", DEFAULT_CURRENCY_ID))
	return DEFAULT_CURRENCY_ID if currency_id.is_empty() else currency_id

func _get_tags(item: Dictionary) -> Array:
	var tags = item.get("tags", [])
	if tags is Array:
		return tags
	if tags is PackedStringArray:
		return Array(tags)
	var tag_text := String(tags)
	if tag_text.is_empty():
		return []
	return tag_text.split(";", false)

func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"

func _make_group_id(item_id: String, item_type: String, quality: String, currency_id: String, unit_value: int) -> String:
	return "%s__%s__%s__%s__%d" % [item_id, item_type, quality, currency_id, unit_value]

func _currency_name(currency_id: String) -> String:
	match currency_id:
		DEFAULT_CURRENCY_ID:
			return "mine_coin"
		_:
			return currency_id

func _fail(code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error": code,
		"message": message,
	}

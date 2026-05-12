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
		var currency_id := _get_sell_currency_id(item)
		var unit_value := int(item.get("sell_value", 0))
		var group_id := _make_group_id(item_id, currency_id, unit_value)
		if not groups.has(group_id):
			groups[group_id] = {
				"warehouse_item_id": group_id,
				"item_id": item_id,
				"display_name": String(item.get("display_name", item_id)),
				"icon": String(item.get("icon", "")),
				"sell_currency_id": currency_id,
				"sell_value": unit_value,
				"count": 0,
				"total_value": 0,
				"warehouse_indexes": [],
			}
		groups[group_id].count += 1
		groups[group_id].total_value += unit_value
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
		return _fail("item_not_found", "没有可出售的仓库道具。")
	var available := int(group.get("count", 0))
	if count <= 0:
		return _fail("invalid_count", "出售数量必须大于 0。")
	if count > available:
		return _fail("not_enough_items", "仓库内该道具数量不足。")

	var unit_value := int(group.get("sell_value", 0))
	var total_value := unit_value * count
	if unit_value <= 0 or total_value <= 0:
		return _fail("invalid_value", "该道具没有可出售价值。")
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
		return _fail("service_unavailable", "商人系统不可用。")

	var quote := get_sell_quote(warehouse_item_id, count)
	if not bool(quote.get("ok", false)):
		return quote

	var group := _find_group(warehouse_item_id)
	var indexes: Array = Array(group.get("warehouse_indexes", [])).slice(0, count)
	var removed := warehouse_manager.remove_items_at_indexes(indexes)
	if removed.size() != count:
		warehouse_manager.restore_removed_items(removed)
		return _fail("remove_failed", "出售失败，仓库道具未被移除。")

	var currency_id := String(quote.get("sell_currency_id", DEFAULT_CURRENCY_ID))
	var total_value := int(quote.get("total_value", 0))
	var currency_result: Dictionary = currency_wallet.add_currency(currency_id, total_value, "merchant_sell")
	if not bool(currency_result.get("ok", false)):
		warehouse_manager.restore_removed_items(removed)
		return _fail("currency_failed", String(currency_result.get("message", "货币结算失败。")))

	var result := quote.duplicate(true)
	result["message"] = "已出售 %s x%d，获得 %d %s。" % [
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
		return _fail("offer_not_found", "商人库存中没有该资源。")
	var available := int(offer.get("count", 0))
	if count <= 0:
		return _fail("invalid_count", "购买数量必须大于 0。")
	if count > available:
		return _fail("not_enough_stock", "商人库存数量不足。")

	var unit_price := int(offer.get("buy_price", 0))
	var total_price := unit_price * count
	if unit_price <= 0 or total_price <= 0:
		return _fail("invalid_price", "该资源没有有效购买价格。")
	var currency_id := String(offer.get("buy_currency_id", DEFAULT_CURRENCY_ID))
	var current_amount := currency_wallet.get_currency_amount(currency_id) if currency_wallet != null else 0
	if current_amount < total_price:
		return _fail("not_enough_currency", "矿币不足。")
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
		return _fail("service_unavailable", "商人系统不可用。")
	var quote := get_buy_quote(shop_offer_id, count)
	if not bool(quote.get("ok", false)):
		return quote

	_ensure_data_loaded()
	var item_id := String(quote.get("item_id", ""))
	var purchased_items: Array[Dictionary] = []
	for _index in range(count):
		var stack := data_registry.make_item_stack(item_id, 1)
		if stack.is_empty():
			return _fail("item_not_found", "购买资源配置不存在。")
		stack["source"] = "merchant_shop"
		purchased_items.append(stack)

	var currency_id := String(quote.get("buy_currency_id", DEFAULT_CURRENCY_ID))
	var total_price := int(quote.get("total_price", 0))
	var spend_result: Dictionary = currency_wallet.spend_currency(currency_id, total_price, "merchant_buy")
	if not bool(spend_result.get("ok", false)):
		return _fail(String(spend_result.get("reason", "currency_failed")), "矿币扣除失败。")

	var accepted := warehouse_manager.add_items(purchased_items)
	if accepted.size() != count:
		currency_wallet.add_currency(currency_id, total_price, "merchant_buy_refund")
		return _fail("warehouse_add_failed", "购买失败，资源未能进入仓库。")

	var offer := _find_shop_offer(shop_offer_id)
	if not offer.is_empty():
		offer["count"] = maxi(0, int(offer.get("count", 0)) - count)

	var result := quote.duplicate(true)
	result["message"] = "已购买 %s x%d，花费 %d %s。" % [
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

func _make_shop_offer(row: Dictionary, rng: RandomNumberGenerator, offer_index: int) -> Dictionary:
	var item_id := String(row.get("item_id", ""))
	var item_def := data_registry.get_item(item_id)
	if item_def.is_empty():
		return {}
	var min_count: int = maxi(1, int(row.get("min_count", 1)))
	var max_count: int = maxi(min_count, int(row.get("max_count", min_count)))
	var count := rng.randi_range(min_count, max_count)
	var buy_price := maxi(0, int(row.get("buy_price", 0)))
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
		"buy_currency_id": String(row.get("buy_currency_id", DEFAULT_CURRENCY_ID)),
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
	var item_type := String(item.get("item_type", ""))
	if item_type == "material" or item_type == "outpost_material":
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

func _make_group_id(item_id: String, currency_id: String, unit_value: int) -> String:
	return "%s__%s__%d" % [item_id, currency_id, unit_value]

func _currency_name(currency_id: String) -> String:
	match currency_id:
		DEFAULT_CURRENCY_ID:
			return "矿币"
		_:
			return currency_id

func _fail(code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error": code,
		"message": message,
	}

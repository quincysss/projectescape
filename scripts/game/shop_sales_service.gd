class_name ShopSalesService
extends RefCounted

const DEFAULT_SALE_INTERVAL_SECONDS := 5.0
const DEFAULT_CURRENCY_ID := "mine_coin"

var shelf_service
var demand_entries: Array[Dictionary] = []
var sales_records: Array[Dictionary] = []


func bind_dependencies(
	bound_shelf_service,
	bound_demand_entries: Array[Dictionary],
	bound_sales_records: Array[Dictionary]
) -> void:
	shelf_service = bound_shelf_service
	demand_entries = bound_demand_entries
	sales_records = bound_sales_records


func advance(
	delta_seconds: float,
	elapsed_seconds: float,
	duration_seconds: float,
	next_sale_second: float
) -> Dictionary:
	var new_elapsed := clampf(elapsed_seconds + maxf(0.0, delta_seconds), 0.0, maxf(1.0, duration_seconds))
	var resolved_next := next_sale_second
	if resolved_next <= 0.0:
		resolved_next = DEFAULT_SALE_INTERVAL_SECONDS
	var sold_records: Array[Dictionary] = []
	while new_elapsed >= resolved_next and shelf_service != null and shelf_service.has_shelf_goods():
		var sale := _sell_best_available_item()
		if sale.is_empty():
			break
		sold_records.append(sale)
		resolved_next += DEFAULT_SALE_INTERVAL_SECONDS
	return {
		"ok": true,
		"elapsed_seconds": new_elapsed,
		"next_sale_second": resolved_next,
		"sold_records": sold_records,
		"ended": new_elapsed >= duration_seconds,
	}


func build_settlement_snapshot(
	elapsed_seconds: float,
	duration_seconds: float,
	settlement_applied: bool
) -> Dictionary:
	var lines: Array[Dictionary] = []
	var total := 0
	for record in sales_records:
		if not (record is Dictionary):
			continue
		var unit_price := int(record.get("unit_price", 0))
		var count := int(record.get("count", 1))
		var subtotal := unit_price * count
		total += subtotal
		lines.append({
			"item_id": String(record.get("item_id", "")),
			"display_name": String(record.get("display_name", "")),
			"count": count,
			"unit_price": unit_price,
			"subtotal": subtotal,
			"currency_id": String(record.get("currency_id", DEFAULT_CURRENCY_ID)),
			"demand_rank": int(record.get("demand_rank", 0)),
		})
	return {
		"ok": true,
		"elapsed_seconds": elapsed_seconds,
		"duration_seconds": duration_seconds,
		"records": lines,
		"total_earned": total,
		"settlement_applied": settlement_applied,
	}


func apply_settlement(currency_wallet: CurrencyWallet, already_applied: bool) -> Dictionary:
	var snapshot := build_settlement_snapshot(0.0, 0.0, already_applied)
	if already_applied:
		return {
			"ok": true,
			"already_applied": true,
			"total_earned": int(snapshot.get("total_earned", 0)),
		}
	if currency_wallet == null:
		return {"ok": false, "reason": "wallet_unavailable", "message": "货币钱包不可用。"}
	var totals_by_currency := {}
	for record in sales_records:
		if not (record is Dictionary):
			continue
		var currency_id := String(record.get("currency_id", DEFAULT_CURRENCY_ID))
		totals_by_currency[currency_id] = int(totals_by_currency.get(currency_id, 0)) + int(record.get("unit_price", 0)) * int(record.get("count", 1))
	var total_earned := 0
	for currency_id in totals_by_currency.keys():
		var amount := int(totals_by_currency[currency_id])
		if amount <= 0:
			continue
		var result: Dictionary = currency_wallet.add_currency(String(currency_id), amount, "shop_settlement")
		if not bool(result.get("ok", false)):
			return result
		total_earned += amount
	return {"ok": true, "total_earned": total_earned}


func _sell_best_available_item() -> Dictionary:
	if shelf_service == null:
		return {}
	var shelf_items: Array = shelf_service.get_shelf_items()
	var best_slot := -1
	var best_score := -9999.0
	var best_demand := {}
	for index in range(shelf_items.size()):
		var item: Dictionary = shelf_items[index]
		if item.is_empty():
			continue
		var demand := _demand_for_item(String(item.get("item_id", "")))
		var score := float(demand.get("demand_score", 0.75))
		score += float(item.get("sell_value", 0)) * 0.01
		if score > best_score:
			best_score = score
			best_slot = index
			best_demand = demand
	if best_slot < 0:
		return {}
	var sold_item: Dictionary = shelf_service.pop_slot_for_sale(best_slot)
	if sold_item.is_empty():
		return {}
	var demand_multiplier := float(best_demand.get("sell_multiplier", 1.0))
	var unit_price := maxi(1, int(round(float(sold_item.get("sell_value", 1)) * demand_multiplier)))
	var record := {
		"sale_id": "%s:%d" % [String(sold_item.get("item_id", "")), sales_records.size() + 1],
		"item_id": String(sold_item.get("item_id", "")),
		"display_name": String(sold_item.get("display_name", sold_item.get("item_id", ""))),
		"count": 1,
		"unit_price": unit_price,
		"subtotal": unit_price,
		"currency_id": String(sold_item.get("sell_currency_id", DEFAULT_CURRENCY_ID)),
		"demand_rank": int(best_demand.get("rank", 0)),
		"shelf_slot_index": best_slot,
	}
	sales_records.append(record)
	return record.duplicate(true)


func _demand_for_item(item_id: String) -> Dictionary:
	for entry in demand_entries:
		if entry is Dictionary and String(entry.get("item_id", "")) == item_id:
			return entry
	return {
		"item_id": item_id,
		"demand_score": 0.75,
		"sell_multiplier": 1.0,
		"rank": 0,
	}

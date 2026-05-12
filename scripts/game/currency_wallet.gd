class_name CurrencyWallet
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const CURRENCIES_PATH := "res://data/currencies.tab"
const DEFAULT_CURRENCY_ID := "mine_coin"

var currencies: Dictionary = {}
var currency_definitions: Dictionary = {}

func bind_currencies(currency_store: Dictionary) -> void:
	currencies = currency_store
	_load_currency_definitions()

func get_currency_amount(currency_id: String = DEFAULT_CURRENCY_ID) -> int:
	return max(0, int(currencies.get(currency_id, 0)))

func add_currency(currency_id: String, amount: int, reason: String = "") -> Dictionary:
	if currency_id.is_empty():
		return {"ok": false, "reason": "missing_currency_id"}
	if amount <= 0:
		return {"ok": false, "reason": "invalid_amount"}
	var new_amount := get_currency_amount(currency_id) + amount
	currencies[currency_id] = new_amount
	return {
		"ok": true,
		"currency_id": currency_id,
		"amount_added": amount,
		"new_currency_amount": new_amount,
		"reason": reason,
	}

func spend_currency(currency_id: String, amount: int, reason: String = "") -> Dictionary:
	if currency_id.is_empty():
		return {"ok": false, "reason": "missing_currency_id"}
	if amount <= 0:
		return {"ok": false, "reason": "invalid_amount"}
	var current_amount := get_currency_amount(currency_id)
	if current_amount < amount:
		return {"ok": false, "reason": "not_enough_currency"}
	var new_amount := current_amount - amount
	currencies[currency_id] = new_amount
	return {
		"ok": true,
		"currency_id": currency_id,
		"amount_spent": amount,
		"new_currency_amount": new_amount,
		"reason": reason,
	}

func clear() -> void:
	currencies.clear()

func get_currencies_snapshot() -> Dictionary:
	return currencies.duplicate(true)

func get_currency_definition(currency_id: String = DEFAULT_CURRENCY_ID) -> Dictionary:
	return currency_definitions.get(currency_id, {}).duplicate(true)

func get_currency_display_text(currency_id: String = DEFAULT_CURRENCY_ID) -> String:
	var definition := get_currency_definition(currency_id)
	var display_name := String(definition.get("name", currency_id))
	return "%s: %d" % [display_name, get_currency_amount(currency_id)]

func _load_currency_definitions() -> void:
	if not currency_definitions.is_empty():
		return
	var loader = TabDataLoaderScript.new()
	for row in loader.load_tab(CURRENCIES_PATH):
		var currency_id := String(row.get("id", ""))
		if currency_id.is_empty():
			continue
		currency_definitions[currency_id] = row

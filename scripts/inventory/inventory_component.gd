class_name InventoryComponent
extends Node

signal inventory_changed(items: Array)
signal item_add_failed(item_id: StringName, reason: String)
signal item_removed(item_id: StringName, amount: int)

@export var max_slots: int = 8
@export var max_weight: float = 20.0
@export var weight_component_path: NodePath

var items: Array[Dictionary] = []
var weight_component

func _ready() -> void:
	if not weight_component_path.is_empty():
		weight_component = get_node_or_null(weight_component_path)
	if weight_component == null:
		weight_component = get_node_or_null("WeightComponent")
	_refresh_weight()

func setup(slot_count: int, weight_limit: float) -> void:
	max_slots = maxi(0, slot_count)
	max_weight = maxf(0.0, weight_limit)
	clear()

func can_accept_item(item: Dictionary) -> Dictionary:
	var normalized := _normalize_item(item)
	var item_id: StringName = normalized.get("item_id", &"")
	if item_id == &"":
		return {"accepted": false, "reason": "invalid_item"}
	if normalized.amount <= 0:
		return {"accepted": false, "reason": "invalid_amount"}
	if normalized.weight_per_unit < 0.0:
		return {"accepted": false, "reason": "invalid_weight"}
	var additional_weight := _stack_weight(normalized)
	var weight_limit: float = weight_component.max_weight if weight_component else max_weight
	var current_weight: float = get_current_weight()
	if current_weight + additional_weight > weight_limit:
		return {"accepted": false, "reason": "over_weight"}

	var required_slots: int = normalized.amount
	var empty_slots: int = max_slots - items.size()
	if required_slots > empty_slots:
		return {"accepted": false, "reason": "no_slot"}
	return {"accepted": true, "reason": ""}

func add_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	var result := can_accept_item(normalized)
	if not result.accepted:
		item_add_failed.emit(normalized.get("item_id", &""), result.reason)
		print("[InventoryComponent] Add failed %s: %s." % [normalized.get("item_id", &""), result.reason])
		return false

	var added_amount: int = normalized.amount
	for _index in range(added_amount):
		var stack := normalized.duplicate(true)
		stack.amount = 1
		stack.stack_limit = 1
		items.append(stack)

	_refresh_weight()
	print("[InventoryComponent] Added %s x%s as single items." % [normalized.item_id, added_amount])
	inventory_changed.emit(get_items_snapshot())
	return true

func remove_item_at(slot_index: int, amount: int = -1) -> Dictionary:
	if slot_index < 0 or slot_index >= items.size():
		return {}
	var stack := items[slot_index]
	var remove_amount := int(stack.amount) if amount < 0 else mini(amount, int(stack.amount))
	if remove_amount <= 0:
		return {}
	var removed := stack.duplicate(true)
	removed.amount = remove_amount
	items[slot_index].amount -= remove_amount
	if int(items[slot_index].amount) <= 0:
		items.remove_at(slot_index)
	_refresh_weight()
	item_removed.emit(removed.item_id, removed.amount)
	inventory_changed.emit(get_items_snapshot())
	return removed

func remove_item(item_id: StringName, amount: int) -> int:
	var remaining := amount
	var removed := 0
	for i in range(items.size() - 1, -1, -1):
		if remaining <= 0:
			break
		if items[i].item_id != item_id:
			continue
		var moved := mini(remaining, int(items[i].amount))
		items[i].amount -= moved
		remaining -= moved
		removed += moved
		if int(items[i].amount) <= 0:
			items.remove_at(i)
	if removed > 0:
		_refresh_weight()
		item_removed.emit(item_id, removed)
		inventory_changed.emit(get_items_snapshot())
	return removed

func clear() -> void:
	items.clear()
	_refresh_weight()
	inventory_changed.emit(get_items_snapshot())

func get_current_weight() -> float:
	var total := 0.0
	for stack in items:
		total += _stack_weight(stack)
	return total

func get_items_snapshot() -> Array:
	var snapshot: Array = []
	for stack in items:
		snapshot.append(stack.duplicate(true))
	return snapshot

func _refresh_weight() -> void:
	var current_weight := get_current_weight()
	if weight_component:
		weight_component.set_weight(current_weight, max_weight)

func _normalize_item(item: Dictionary) -> Dictionary:
	return {
		"item_id": StringName(str(item.get("item_id", ""))),
		"display_name": str(item.get("display_name", item.get("item_id", ""))),
		"amount": int(item.get("amount", 1)),
		"weight_per_unit": float(item.get("weight_per_unit", 0.0)),
		"stack_limit": 1,
		"item_type": StringName(str(item.get("item_type", "material"))),
		"quality": StringName(str(item.get("quality", "C"))),
		"quality_color": item.get("quality_color", Color.WHITE),
		"tags": item.get("tags", []),
		"icon": str(item.get("icon", "")),
		"sellable": _parse_bool(item.get("sellable", false)),
		"sell_currency_id": str(item.get("sell_currency_id", "mine_coin")),
		"sell_value": int(item.get("sell_value", 0)),
	}

func _can_stack_together(a: Dictionary, b: Dictionary) -> bool:
	return false

func _stack_weight(stack: Dictionary) -> float:
	return maxf(0.0, float(stack.get("weight_per_unit", 0.0))) * maxi(0, int(stack.get("amount", 0)))

func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"

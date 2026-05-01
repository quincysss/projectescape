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
	if normalized.stack_limit <= 0:
		return {"accepted": false, "reason": "invalid_stack_limit"}

	var additional_weight := _stack_weight(normalized)
	var weight_limit: float = weight_component.max_weight if weight_component else max_weight
	var current_weight: float = get_current_weight()
	if current_weight + additional_weight > weight_limit:
		return {"accepted": false, "reason": "over_weight"}

	var remaining_amount: int = normalized.amount
	for stack in items:
		if _can_stack_together(stack, normalized):
			remaining_amount -= max(0, int(stack.stack_limit) - int(stack.amount))
			if remaining_amount <= 0:
				return {"accepted": true, "reason": ""}

	var empty_slots := max_slots - items.size()
	while remaining_amount > 0 and empty_slots > 0:
		remaining_amount -= normalized.stack_limit
		empty_slots -= 1

	if remaining_amount > 0:
		return {"accepted": false, "reason": "no_slot"}
	return {"accepted": true, "reason": ""}

func add_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	var result := can_accept_item(normalized)
	if not result.accepted:
		item_add_failed.emit(normalized.get("item_id", &""), result.reason)
		print("[InventoryComponent] Add failed %s: %s." % [normalized.get("item_id", &""), result.reason])
		return false

	var remaining_amount: int = normalized.amount
	for i in range(items.size()):
		if remaining_amount <= 0:
			break
		if _can_stack_together(items[i], normalized):
			var free_space := int(items[i].stack_limit) - int(items[i].amount)
			var moved := mini(free_space, remaining_amount)
			items[i].amount += moved
			remaining_amount -= moved

	while remaining_amount > 0:
		var stack := normalized.duplicate(true)
		stack.amount = mini(normalized.stack_limit, remaining_amount)
		items.append(stack)
		remaining_amount -= stack.amount

	_refresh_weight()
	print("[InventoryComponent] Added %s x%s." % [normalized.item_id, normalized.amount])
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
		"stack_limit": int(item.get("stack_limit", 1)),
		"item_type": StringName(str(item.get("item_type", "material"))),
	}

func _can_stack_together(a: Dictionary, b: Dictionary) -> bool:
	return a.item_id == b.item_id and int(a.amount) < int(a.stack_limit) and int(a.stack_limit) == int(b.stack_limit)

func _stack_weight(stack: Dictionary) -> float:
	return maxf(0.0, float(stack.get("weight_per_unit", 0.0))) * maxi(0, int(stack.get("amount", 0)))

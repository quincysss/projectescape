class_name StorageContainer
extends RefCounted

signal storage_changed(items: Array)
signal storage_full()
signal item_stored(item_id: StringName, amount: int)

var storage_id: String = ""
var owner_id: String = ""
var max_slots: int = 0
var is_temporary: bool = true
var items: Array[Dictionary] = []
var slots: Array = []

func setup(p_storage_id: String, p_owner_id: String, slot_count: int, temporary: bool = true) -> void:
	storage_id = p_storage_id
	owner_id = p_owner_id
	max_slots = maxi(0, slot_count)
	is_temporary = temporary
	clear()

func can_store_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	if normalized.item_id == &"" or normalized.amount <= 0:
		return false
	return _empty_slot_count() >= int(normalized.amount)

func store_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	if not can_store_item(normalized):
		storage_full.emit()
		return false
	var stored_amount: int = normalized.amount
	for _index in range(stored_amount):
		var single := normalized.duplicate(true)
		single.amount = 1
		single.stack_limit = 1
		var target_slot := _first_empty_slot()
		if target_slot < 0:
			storage_full.emit()
			return false
		slots[target_slot] = single
	_sync_items_from_slots()
	item_stored.emit(normalized.item_id, stored_amount)
	storage_changed.emit(get_items_snapshot())
	return true

func store_item_at(item: Dictionary, target_slot: int) -> bool:
	var normalized := _normalize_item(item)
	if target_slot < 0 or target_slot >= max_slots:
		return false
	if not _is_slot_empty(target_slot):
		storage_full.emit()
		return false
	if normalized.item_id == &"" or normalized.amount != 1:
		return false
	var single := normalized.duplicate(true)
	single.amount = 1
	single.stack_limit = 1
	slots[target_slot] = single
	_sync_items_from_slots()
	item_stored.emit(normalized.item_id, 1)
	storage_changed.emit(get_items_snapshot())
	return true

func store_from_inventory(inventory, slot_index: int, amount: int = -1) -> bool:
	if inventory == null:
		return false
	if slot_index < 0 or slot_index >= inventory.items.size():
		return false
	var source: Dictionary = inventory.items[slot_index].duplicate(true)
	if amount > 0:
		source.amount = mini(amount, int(source.amount))
	if not can_store_item(source):
		storage_full.emit()
		return false
	var removed: Dictionary = inventory.remove_item_at(slot_index, int(source.amount))
	if removed.is_empty():
		return false
	return store_item(removed)

func store_from_inventory_at(inventory, slot_index: int, target_slot: int, amount: int = -1) -> bool:
	if inventory == null:
		return false
	if slot_index < 0 or slot_index >= inventory.items.size():
		return false
	if target_slot < 0 or target_slot >= max_slots:
		return false
	if not _is_slot_empty(target_slot):
		storage_full.emit()
		return false
	var source: Dictionary = inventory.items[slot_index].duplicate(true)
	if amount > 0:
		source.amount = mini(amount, int(source.amount))
	if int(source.amount) != 1 or not can_store_item(source):
		storage_full.emit()
		return false
	var removed: Dictionary = inventory.remove_item_at(slot_index, int(source.amount))
	if removed.is_empty():
		return false
	return store_item_at(removed, target_slot)

func remove_item_at(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {}
	var item = slots[slot_index]
	if not item is Dictionary:
		return {}
	var removed: Dictionary = item.duplicate(true)
	slots[slot_index] = null
	_sync_items_from_slots()
	storage_changed.emit(get_items_snapshot())
	return removed

func clear() -> void:
	items.clear()
	slots.clear()
	for _index in range(max_slots):
		slots.append(null)
	storage_changed.emit(get_items_snapshot())

func select_item_at(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size():
		return {}
	var item = slots[slot_index]
	if item is Dictionary:
		return item.duplicate(true)
	return {}

func get_items_snapshot() -> Array:
	var snapshot: Array = []
	for stack in items:
		snapshot.append(stack.duplicate(true))
	return snapshot

func get_slots_snapshot() -> Array:
	var snapshot: Array = []
	for slot in slots:
		if slot is Dictionary:
			snapshot.append(slot.duplicate(true))
		else:
			snapshot.append(null)
	while snapshot.size() < max_slots:
		snapshot.append(null)
	return snapshot

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

func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"

func _empty_slot_count() -> int:
	var count := 0
	for index in range(max_slots):
		if _is_slot_empty(index):
			count += 1
	return count

func _first_empty_slot() -> int:
	for index in range(max_slots):
		if _is_slot_empty(index):
			return index
	return -1

func _is_slot_empty(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < slots.size() and slots[slot_index] == null

func _sync_items_from_slots() -> void:
	items.clear()
	for slot in slots:
		if slot is Dictionary:
			items.append(slot.duplicate(true))

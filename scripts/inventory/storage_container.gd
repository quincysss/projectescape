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
	return _required_new_slots(normalized) <= _empty_slot_count()

func store_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	if not can_store_item(normalized):
		storage_full.emit()
		return false
	var stored_amount: int = normalized.amount
	var remaining := stored_amount
	var stack_limit := _stack_limit(normalized)
	if _parse_bool(normalized.get("stackable", false)):
		for slot_index in range(slots.size()):
			if remaining <= 0:
				break
			if not (slots[slot_index] is Dictionary):
				continue
			var existing: Dictionary = slots[slot_index]
			if not _can_stack_together(existing, normalized):
				continue
			var available := maxi(0, stack_limit - int(existing.get("amount", 0)))
			if available <= 0:
				continue
			var moved := mini(remaining, available)
			existing["amount"] = int(existing.get("amount", 0)) + moved
			slots[slot_index] = existing
			remaining -= moved
	while remaining > 0:
		var moved := mini(remaining, stack_limit)
		var stack := normalized.duplicate(true)
		stack.amount = moved
		stack.stack_limit = stack_limit
		var target_slot := _first_empty_slot()
		if target_slot < 0:
			storage_full.emit()
			return false
		slots[target_slot] = stack
		remaining -= moved
	_sync_items_from_slots()
	item_stored.emit(normalized.item_id, stored_amount)
	storage_changed.emit(get_items_snapshot())
	return true

func store_item_at(item: Dictionary, target_slot: int) -> bool:
	var normalized := _normalize_item(item)
	if target_slot < 0 or target_slot >= max_slots:
		return false
	if normalized.item_id == &"" or normalized.amount != 1:
		return false
	if not _is_slot_empty(target_slot):
		var existing = slots[target_slot]
		if existing is Dictionary and _can_stack_together(existing, normalized) and int(existing.get("amount", 0)) < _stack_limit(existing):
			existing["amount"] = int(existing.get("amount", 0)) + 1
			slots[target_slot] = existing
		else:
			storage_full.emit()
			return false
	else:
		var single := normalized.duplicate(true)
		single.amount = 1
		single.stack_limit = _stack_limit(single)
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
	var source: Dictionary = inventory.items[slot_index].duplicate(true)
	if amount > 0:
		source.amount = mini(amount, int(source.amount))
	if int(source.amount) != 1:
		storage_full.emit()
		return false
	if not _is_slot_empty(target_slot):
		var existing = slots[target_slot]
		if not (existing is Dictionary) or not _can_stack_together(existing, source) or int(existing.get("amount", 0)) >= _stack_limit(existing):
			storage_full.emit()
			return false
	if not can_store_item(source):
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
	var normalized := {
		"item_id": StringName(str(item.get("item_id", ""))),
		"display_name": str(item.get("display_name", item.get("item_id", ""))),
		"amount": int(item.get("amount", 1)),
		"weight_per_unit": float(item.get("weight_per_unit", 0.0)),
		"stackable": _parse_bool(item.get("stackable", false)),
		"stack_limit": maxi(1, int(item.get("stack_limit", 1))),
		"item_type": StringName(str(item.get("item_type", "material"))),
		"quality": StringName(_normalize_quality(str(item.get("quality", "C")))),
		"quality_color": item.get("quality_color", Color.WHITE),
		"tags": item.get("tags", []),
		"icon": str(item.get("icon", "")),
		"sellable": _parse_bool(item.get("sellable", false)),
		"sell_currency_id": str(item.get("sell_currency_id", "mine_coin")),
		"sell_value": int(item.get("sell_value", 0)),
	}
	for key in ["source", "source_container_type", "source_container_id", "source_ring", "outpost_id", "description"]:
		if item.has(key):
			normalized[key] = item[key]
	return normalized

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

func _required_new_slots(normalized: Dictionary) -> int:
	var remaining: int = maxi(0, int(normalized.get("amount", 0)))
	if remaining <= 0:
		return 0
	var stack_limit := _stack_limit(normalized)
	if _parse_bool(normalized.get("stackable", false)):
		for slot in slots:
			if remaining <= 0:
				break
			if not (slot is Dictionary) or not _can_stack_together(slot, normalized):
				continue
			var available := maxi(0, stack_limit - int(slot.get("amount", 0)))
			remaining -= mini(remaining, available)
	return int(ceil(float(remaining) / float(stack_limit)))

func _can_stack_together(a: Dictionary, b: Dictionary) -> bool:
	if not _parse_bool(a.get("stackable", false)) or not _parse_bool(b.get("stackable", false)):
		return false
	if String(a.get("item_id", "")) != String(b.get("item_id", "")):
		return false
	if String(a.get("item_type", "")) != String(b.get("item_type", "")):
		return false
	if String(a.get("quality", "")) != String(b.get("quality", "")):
		return false
	return true

func _stack_limit(item: Dictionary) -> int:
	if not _parse_bool(item.get("stackable", false)):
		return 1
	return maxi(1, int(item.get("stack_limit", 1)))

func _is_slot_empty(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < slots.size() and slots[slot_index] == null

func _sync_items_from_slots() -> void:
	items.clear()
	for slot in slots:
		if slot is Dictionary:
			items.append(slot.duplicate(true))

func _normalize_quality(value: String) -> String:
	var normalized := value.strip_edges().to_upper()
	if ["C", "B", "A", "S"].has(normalized):
		return normalized
	return "C"

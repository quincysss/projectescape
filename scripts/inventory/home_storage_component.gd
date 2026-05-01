class_name HomeStorageComponent
extends Node

signal home_storage_changed(items: Array)
signal home_storage_full()
signal item_stored(item_id: StringName, amount: int)

@export var max_slots: int = 4

var items: Array[Dictionary] = []

func setup(slot_count: int) -> void:
	max_slots = maxi(0, slot_count)
	clear()

func can_store_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	if normalized.item_id == &"" or normalized.amount <= 0:
		return false
	if _find_merge_slot(normalized) != -1:
		return true
	return items.size() < max_slots

func store_item(item: Dictionary) -> bool:
	var normalized := _normalize_item(item)
	if not can_store_item(normalized):
		home_storage_full.emit()
		print("[HomeStorageComponent] Store failed: full.")
		return false

	var merge_index := _find_merge_slot(normalized)
	if merge_index != -1:
		items[merge_index].amount += normalized.amount
	else:
		items.append(normalized)

	item_stored.emit(normalized.item_id, normalized.amount)
	home_storage_changed.emit(get_items_snapshot())
	print("[HomeStorageComponent] Stored %s x%s." % [normalized.item_id, normalized.amount])
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
		home_storage_full.emit()
		return false
	var removed: Dictionary = inventory.remove_item_at(slot_index, int(source.amount))
	if removed.is_empty():
		return false
	return store_item(removed)

func clear() -> void:
	items.clear()
	home_storage_changed.emit(get_items_snapshot())

func get_items_snapshot() -> Array:
	var snapshot: Array = []
	for stack in items:
		snapshot.append(stack.duplicate(true))
	return snapshot

func get_slots_snapshot() -> Array:
	var snapshot := get_items_snapshot()
	while snapshot.size() < max_slots:
		snapshot.append(null)
	return snapshot

func _find_merge_slot(item: Dictionary) -> int:
	for i in range(items.size()):
		if items[i].item_id == item.item_id and int(items[i].stack_limit) == int(item.stack_limit):
			if int(items[i].amount) + int(item.amount) <= int(items[i].stack_limit):
				return i
	return -1

func _normalize_item(item: Dictionary) -> Dictionary:
	return {
		"item_id": StringName(str(item.get("item_id", ""))),
		"display_name": str(item.get("display_name", item.get("item_id", ""))),
		"amount": int(item.get("amount", 1)),
		"weight_per_unit": float(item.get("weight_per_unit", 0.0)),
		"stack_limit": int(item.get("stack_limit", 1)),
		"item_type": StringName(str(item.get("item_type", "material"))),
	}

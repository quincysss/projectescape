class_name ItemTransferService
extends RefCounted

func select_item(items: Array, index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	var item = items[index]
	if item is Dictionary:
		return item.duplicate(true)
	return {}

func transfer_index_to_inventory(source_items: Array, source_index: int, inventory_component) -> Dictionary:
	var item := select_item(source_items, source_index)
	if item.is_empty():
		return {"accepted": false, "reason": "invalid_item", "item": {}}
	if inventory_component == null:
		return {"accepted": false, "reason": "missing_inventory", "item": item}
	if not inventory_component.add_item(item):
		return {"accepted": false, "reason": "inventory_rejected", "item": item}
	source_items.remove_at(source_index)
	return {"accepted": true, "reason": "", "item": item}

func transfer_inventory_to_storage(inventory_component, slot_index: int, storage_component, target_storage_slot: int = -1) -> Dictionary:
	if inventory_component == null or storage_component == null:
		return {"accepted": false, "reason": "missing_storage", "item": {}}
	var item := select_item(inventory_component.items, slot_index)
	if item.is_empty():
		return {"accepted": false, "reason": "invalid_item", "item": {}}
	var stored := false
	if target_storage_slot >= 0 and storage_component.has_method("store_from_inventory_at"):
		stored = storage_component.store_from_inventory_at(inventory_component, slot_index, target_storage_slot, 1)
	else:
		stored = storage_component.store_from_inventory(inventory_component, slot_index, 1)
	if not stored:
		return {"accepted": false, "reason": "storage_rejected", "item": item}
	return {"accepted": true, "reason": "", "item": item}

func transfer_storage_to_inventory(storage_component, slot_index: int, inventory_component) -> Dictionary:
	if storage_component == null or inventory_component == null:
		return {"accepted": false, "reason": "missing_inventory", "item": {}}
	var item: Dictionary = storage_component.select_item_at(slot_index) if storage_component.has_method("select_item_at") else select_item(storage_component.items, slot_index)
	if item.is_empty():
		return {"accepted": false, "reason": "invalid_item", "item": {}}
	if not inventory_component.add_item(item):
		return {"accepted": false, "reason": "inventory_rejected", "item": item}
	var removed: Dictionary = storage_component.remove_item_at(slot_index)
	if removed.is_empty():
		return {"accepted": false, "reason": "remove_failed", "item": item}
	return {"accepted": true, "reason": "", "item": removed}

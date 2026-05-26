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

func transfer_storage_to_inventory(storage_component, slot_index: int, inventory_component, amount: int = 1) -> Dictionary:
	if storage_component == null or inventory_component == null:
		return {"accepted": false, "reason": "missing_inventory", "item": {}}
	var item: Dictionary = storage_component.select_item_at(slot_index) if storage_component.has_method("select_item_at") else select_item(storage_component.items, slot_index)
	if item.is_empty():
		return {"accepted": false, "reason": "invalid_item", "item": {}}
	var move_amount := mini(maxi(1, amount), maxi(1, int(item.get("amount", 1))))
	var moving_item := item.duplicate(true)
	moving_item["amount"] = move_amount
	if not inventory_component.add_item(moving_item):
		return {"accepted": false, "reason": "inventory_rejected", "item": moving_item}
	var removed: Dictionary
	if storage_component.has_method("remove_item_at"):
		removed = storage_component.remove_item_at(slot_index, move_amount)
	else:
		removed = item
		removed["amount"] = move_amount
		storage_component.items.remove_at(slot_index)
	if removed.is_empty():
		inventory_component.remove_item_at(_last_matching_inventory_index(inventory_component, moving_item), move_amount)
		return {"accepted": false, "reason": "remove_failed", "item": moving_item}
	return {"accepted": true, "reason": "", "item": removed}


func _last_matching_inventory_index(inventory_component, item: Dictionary) -> int:
	if inventory_component == null:
		return -1
	for index in range(inventory_component.items.size() - 1, -1, -1):
		var stack: Dictionary = inventory_component.items[index]
		if String(stack.get("item_id", "")) != String(item.get("item_id", "")):
			continue
		if String(stack.get("item_type", "")) != String(item.get("item_type", "")):
			continue
		if String(stack.get("quality", "")) != String(item.get("quality", "")):
			continue
		return index
	return -1

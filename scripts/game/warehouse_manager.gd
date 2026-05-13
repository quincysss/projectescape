class_name WarehouseManager
extends RefCounted

const DEFAULT_MAX_SLOTS := 80

var items: Array[Dictionary] = []
var max_slots: int = DEFAULT_MAX_SLOTS

func bind_items(item_store: Array[Dictionary]) -> void:
	items = item_store

func set_capacity(slot_count: int) -> void:
	max_slots = maxi(0, slot_count)

func get_capacity() -> int:
	return max_slots

func get_used_slots() -> int:
	return items.size()

func get_available_slots() -> int:
	return maxi(0, max_slots - get_used_slots())

func can_accept_items(new_items: Array) -> bool:
	var required_slots := _count_item_units(new_items)
	return required_slots > 0 and required_slots <= get_available_slots()

func add_items(new_items: Array) -> Array[Dictionary]:
	var accepted: Array[Dictionary] = []
	if not can_accept_items(new_items):
		return accepted
	for item in new_items:
		if item is Dictionary and int(item.get("amount", 0)) > 0:
			var amount := int(item.get("amount", 1))
			for _index in range(amount):
				var stored: Dictionary = item.duplicate(true)
				stored.amount = 1
				stored.stack_limit = 1
				items.append(stored)
				accepted.append(stored.duplicate(true))
	return accepted

func select_item_at(index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	return items[index].duplicate(true)

func remove_item_at(index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	var removed := items[index].duplicate(true)
	items.remove_at(index)
	return removed

func remove_items_at_indexes(indexes: Array) -> Array[Dictionary]:
	var normalized := _normalize_indexes(indexes)
	if normalized.is_empty() or normalized.size() != indexes.size():
		return []

	var removed: Array[Dictionary] = []
	for reverse_index in range(normalized.size() - 1, -1, -1):
		var item_index: int = normalized[reverse_index]
		removed.append({
			"index": item_index,
			"item": items[item_index].duplicate(true),
		})
		items.remove_at(item_index)
	removed.reverse()
	return removed

func get_item_count(item_id: String) -> int:
	if item_id.is_empty():
		return 0
	var count := 0
	for item in items:
		if item is Dictionary and String(item.get("item_id", "")) == item_id:
			count += maxi(1, int(item.get("amount", 1)))
	return count

func has_items(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if get_item_count(String(item_id)) < int(requirements[item_id]):
			return false
	return true

func consume_items(requirements: Dictionary) -> Dictionary:
	if requirements.is_empty():
		return {"ok": true, "removed_entries": []}
	if not has_items(requirements):
		return {"ok": false, "reason": "not_enough_items", "removed_entries": []}

	var indexes: Array[int] = []
	for item_id in requirements.keys():
		var needed := int(requirements[item_id])
		var candidates := _find_item_indexes(String(item_id))
		if candidates.size() < needed:
			return {"ok": false, "reason": "not_enough_items", "removed_entries": []}
		for index in candidates.slice(0, needed):
			indexes.append(index)

	var removed := remove_items_at_indexes(indexes)
	if removed.size() != indexes.size():
		restore_removed_items(removed)
		return {"ok": false, "reason": "remove_failed", "removed_entries": []}
	return {
		"ok": true,
		"removed_entries": removed,
	}

func restore_removed_items(removed_entries: Array) -> void:
	var entries: Array = []
	for entry in removed_entries:
		if entry is Dictionary and entry.has("index") and entry.has("item") and entry.item is Dictionary:
			entries.append(entry.duplicate(true))
	entries.sort_custom(func(a, b): return int(a.get("index", 0)) < int(b.get("index", 0)))
	for entry in entries:
		var index: int = clampi(int(entry.get("index", items.size())), 0, items.size())
		items.insert(index, Dictionary(entry.get("item", {})).duplicate(true))

func clear() -> void:
	items.clear()

func get_items_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for item in items:
		snapshot.append(item.duplicate(true))
	return snapshot

func get_warehouse_text() -> String:
	if items.is_empty():
		return "局外仓库：空（0/%d）" % max_slots
	var lines: Array[String] = ["局外仓库：%d/%d" % [items.size(), max_slots]]
	for item in items:
		lines.append("- %s x%s" % [item.get("display_name", item.get("item_id", "")), item.get("amount", 0)])
	return "\n".join(lines)

func _count_item_units(new_items: Array) -> int:
	var required_slots := 0
	for item in new_items:
		if item is Dictionary:
			required_slots += maxi(0, int(item.get("amount", 1)))
	return required_slots

func _normalize_indexes(indexes: Array) -> Array[int]:
	var normalized: Array[int] = []
	for raw_index in indexes:
		var index := int(raw_index)
		if index < 0 or index >= items.size() or normalized.has(index):
			return []
		normalized.append(index)
	normalized.sort()
	return normalized

func _find_item_indexes(item_id: String) -> Array[int]:
	var result: Array[int] = []
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if String(item.get("item_id", "")) == item_id:
			result.append(index)
	result.sort_custom(func(a, b):
		var item_a: Dictionary = items[int(a)]
		var item_b: Dictionary = items[int(b)]
		var amount_delta := int(item_a.get("amount", 1)) - int(item_b.get("amount", 1))
		if amount_delta != 0:
			return amount_delta < 0
		return int(a) < int(b)
	)
	return result

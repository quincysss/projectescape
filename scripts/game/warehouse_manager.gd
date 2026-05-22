class_name WarehouseManager
extends RefCounted

const DEFAULT_MAX_SLOTS := 80
const ALLOWED_QUALITIES := ["C", "B", "A", "S"]

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
	var required_slots := _required_new_slots(new_items)
	return _has_valid_new_item(new_items) and required_slots <= get_available_slots()

func add_items(new_items: Array) -> Array[Dictionary]:
	var accepted: Array[Dictionary] = []
	if not can_accept_items(new_items):
		return accepted
	for item in new_items:
		if not (item is Dictionary) or int(item.get("amount", 0)) <= 0:
			continue
		var normalized := _normalize_item(item)
		_add_item_to_stacks(normalized, items)
		accepted.append(normalized.duplicate(true))
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

func remove_item_quantity_at_index(index: int, amount: int = 1) -> Dictionary:
	if index < 0 or index >= items.size() or amount <= 0:
		return {}
	var remove_amount := mini(amount, maxi(1, int(items[index].get("amount", 1))))
	var removed := items[index].duplicate(true)
	removed["amount"] = remove_amount
	items[index]["amount"] = int(items[index].get("amount", 1)) - remove_amount
	if int(items[index].get("amount", 0)) <= 0:
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

func query_items(filters: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if not _matches_filters(item, filters):
			continue
		var view := item.duplicate(true)
		view["warehouse_index"] = index
		view["count"] = maxi(1, int(item.get("amount", 1)))
		view["category"] = String(item.get("item_type", ""))
		view["usage_tags"] = _get_tags(item)
		result.append(view)
	return result

func get_items_by_category(category: String) -> Array[Dictionary]:
	return query_items({"category": category})

func get_items_by_quality(quality: String) -> Array[Dictionary]:
	return query_items({"quality": quality})

func get_items_by_usage(usage: String) -> Array[Dictionary]:
	return query_items({"usage": usage})

func has_items(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if get_item_count(String(item_id)) < int(requirements[item_id]):
			return false
	return true

func has_materials(requirements: Dictionary) -> bool:
	return has_items(requirements)

func consume_items(requirements: Dictionary) -> Dictionary:
	if requirements.is_empty():
		return {"ok": true, "removed_entries": []}
	if not has_items(requirements):
		return {"ok": false, "reason": "not_enough_items", "removed_entries": []}

	var removed_entries: Array[Dictionary] = []
	for item_id in requirements.keys():
		var needed := int(requirements[item_id])
		while needed > 0:
			var index := _first_item_index(String(item_id))
			if index < 0:
				restore_removed_items(removed_entries)
				return {"ok": false, "reason": "not_enough_items", "removed_entries": []}
			var removed_item := remove_item_quantity_at_index(index, needed)
			if removed_item.is_empty():
				restore_removed_items(removed_entries)
				return {"ok": false, "reason": "remove_failed", "removed_entries": []}
			removed_entries.append({"index": index, "item": removed_item})
			needed -= int(removed_item.get("amount", 0))
	return {"ok": true, "removed_entries": removed_entries}

func consume_materials(requirements: Dictionary) -> Dictionary:
	return consume_items(requirements)

func restore_removed_items(removed_entries: Array) -> void:
	for entry in removed_entries:
		if entry is Dictionary and entry.has("item") and entry.get("item", {}) is Dictionary:
			add_items([Dictionary(entry.get("item", {})).duplicate(true)])

func clear() -> void:
	items.clear()

func get_items_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for item in items:
		snapshot.append(item.duplicate(true))
	return snapshot

func get_warehouse_text() -> String:
	if items.is_empty():
		return "Warehouse: empty (0/%d)" % max_slots
	var lines: Array[String] = ["Warehouse: %d/%d" % [items.size(), max_slots]]
	for item in items:
		lines.append("- %s x%s" % [item.get("display_name", item.get("item_id", "")), item.get("amount", 0)])
	return "\n".join(lines)

func _required_new_slots(new_items: Array) -> int:
	var simulated: Array[Dictionary] = []
	for item in items:
		simulated.append(item.duplicate(true))
	for item in new_items:
		if not (item is Dictionary):
			continue
		var normalized := _normalize_item(item)
		if String(normalized.get("item_id", "")).is_empty() or int(normalized.get("amount", 0)) <= 0:
			continue
		_add_item_to_stacks(normalized, simulated)
	return simulated.size() - items.size()

func _has_valid_new_item(new_items: Array) -> bool:
	for item in new_items:
		if not (item is Dictionary):
			continue
		var normalized := _normalize_item(item)
		if not String(normalized.get("item_id", "")).is_empty() and int(normalized.get("amount", 0)) > 0:
			return true
	return false

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

func _first_item_index(item_id: String) -> int:
	var indexes := _find_item_indexes(item_id)
	return -1 if indexes.is_empty() else int(indexes[0])

func _normalize_item(item: Dictionary) -> Dictionary:
	var normalized := item.duplicate(true)
	normalized["item_id"] = StringName(str(item.get("item_id", "")))
	normalized["display_name"] = str(item.get("display_name", item.get("item_id", "")))
	normalized["amount"] = maxi(1, int(item.get("amount", 1)))
	normalized["weight_per_unit"] = maxf(0.0, float(item.get("weight_per_unit", 0.0)))
	normalized["stackable"] = _parse_bool(item.get("stackable", false))
	normalized["stack_limit"] = _stack_limit(normalized)
	normalized["item_type"] = StringName(str(item.get("item_type", "")))
	normalized["quality"] = StringName(_normalize_quality(str(item.get("quality", "C"))))
	normalized["tags"] = _get_tags(normalized)
	normalized["sellable"] = _parse_bool(item.get("sellable", false))
	normalized["sell_currency_id"] = str(item.get("sell_currency_id", "mine_coin"))
	normalized["sell_value"] = int(item.get("sell_value", 0))
	return normalized

func _add_item_to_stacks(normalized: Dictionary, target: Array[Dictionary]) -> void:
	var remaining: int = maxi(0, int(normalized.get("amount", 0)))
	if remaining <= 0:
		return
	var stack_limit := _stack_limit(normalized)
	if _parse_bool(normalized.get("stackable", false)):
		for index in range(target.size()):
			if remaining <= 0:
				break
			if not _can_stack_together(target[index], normalized):
				continue
			var available := maxi(0, stack_limit - int(target[index].get("amount", 0)))
			if available <= 0:
				continue
			var moved := mini(remaining, available)
			target[index]["amount"] = int(target[index].get("amount", 0)) + moved
			remaining -= moved
	while remaining > 0:
		var moved := mini(remaining, stack_limit)
		var stack := normalized.duplicate(true)
		stack["amount"] = moved
		stack["stack_limit"] = stack_limit
		target.append(stack)
		remaining -= moved

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

func _matches_filters(item: Dictionary, filters: Dictionary) -> bool:
	if filters.has("item_id") and String(filters.get("item_id", "")) != String(item.get("item_id", "")):
		return false
	var category := String(filters.get("category", filters.get("item_type", "")))
	if not category.is_empty() and category != String(item.get("item_type", "")):
		return false
	var quality := String(filters.get("quality", ""))
	if not quality.is_empty() and quality != String(item.get("quality", "")):
		return false
	var usage := String(filters.get("usage", filters.get("tag", "")))
	if not usage.is_empty() and not _get_tags(item).has(usage):
		return false
	return true

func _get_tags(item: Dictionary) -> Array:
	var tags = item.get("tags", [])
	if tags is PackedStringArray:
		return Array(tags)
	if tags is Array:
		return tags
	var tag_text := String(tags)
	if tag_text.is_empty():
		return []
	return tag_text.split(";", false)

func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var normalized := String(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"

func _normalize_quality(value: String) -> String:
	var normalized := value.strip_edges().to_upper()
	if ALLOWED_QUALITIES.has(normalized):
		return normalized
	return "C"

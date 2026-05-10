class_name WarehouseManager
extends RefCounted

var items: Array[Dictionary] = []

func bind_items(item_store: Array[Dictionary]) -> void:
	items = item_store

func add_items(new_items: Array) -> Array[Dictionary]:
	var accepted: Array[Dictionary] = []
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

func clear() -> void:
	items.clear()

func get_items_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for item in items:
		snapshot.append(item.duplicate(true))
	return snapshot

func get_warehouse_text() -> String:
	if items.is_empty():
		return "局外仓库：空"
	var lines: Array[String] = ["局外仓库："]
	for item in items:
		lines.append("- %s x%s" % [item.get("display_name", item.get("item_id", "")), item.get("amount", 0)])
	return "\n".join(lines)

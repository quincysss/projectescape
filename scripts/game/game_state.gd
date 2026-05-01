extends Node

var warehouse_items: Array[Dictionary] = []
var last_run_result: String = ""

func add_to_warehouse(items: Array) -> void:
	for item in items:
		if item is Dictionary and int(item.get("amount", 0)) > 0:
			warehouse_items.append(item.duplicate(true))

func clear_warehouse() -> void:
	warehouse_items.clear()
	last_run_result = ""

func get_warehouse_text() -> String:
	if warehouse_items.is_empty():
		return "Warehouse: empty"
	var lines: Array[String] = ["Warehouse:"]
	for item in warehouse_items:
		lines.append("- %s x%s" % [item.get("display_name", item.get("item_id", "")), item.get("amount", 0)])
	return "\n".join(lines)

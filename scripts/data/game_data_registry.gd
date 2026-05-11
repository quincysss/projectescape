class_name GameDataRegistry
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const ITEMS_PATH := "res://setting/items.tab"
const ITEM_QUALITY_COLORS_PATH := "res://setting/item_quality_colors.tab"
const CONTAINER_TYPES_PATH := "res://setting/container_types.tab"
const DROP_TABLES_PATH := "res://setting/drop_tables.tab"

var items_by_id: Dictionary = {}
var quality_colors_by_id: Dictionary = {}
var containers_by_id: Dictionary = {}
var drop_rows_by_context: Dictionary = {}
var load_errors: Array[String] = []

func load_all() -> bool:
	load_errors.clear()
	items_by_id = _index_rows(_load_rows(ITEMS_PATH), "id")
	quality_colors_by_id = _index_rows(_load_rows(ITEM_QUALITY_COLORS_PATH), "quality")
	containers_by_id = _index_rows(_load_rows(CONTAINER_TYPES_PATH), "type_id")
	drop_rows_by_context.clear()
	for row in _load_rows(DROP_TABLES_PATH):
		var context := String(row.get("context", ""))
		if context.is_empty():
			continue
		if not drop_rows_by_context.has(context):
			drop_rows_by_context[context] = []
		drop_rows_by_context[context].append(row)
	return load_errors.is_empty()

func get_item(item_id: String) -> Dictionary:
	return items_by_id.get(item_id, {})

func get_item_quality_color(quality: String) -> Color:
	var row: Dictionary = quality_colors_by_id.get(quality, {})
	return TabDataLoader.parse_color(String(row.get("text_color_hex", "")), Color.WHITE)

func get_container_type(type_id: String) -> Dictionary:
	return containers_by_id.get(type_id, {})

func get_container_types_for_ring(ring: String) -> Array[Dictionary]:
	var normalized_ring := _normalize_ring(ring)
	var result: Array[Dictionary] = []
	for container in containers_by_id.values():
		var allowed := TabDataLoader.split_list(String(container.get("allowed_rings", "")))
		if allowed.has(normalized_ring):
			result.append(container)
	return result

func pick_container_type_for_ring(ring: String, rng: RandomNumberGenerator) -> Dictionary:
	var candidates := get_container_types_for_ring(ring)
	if candidates.is_empty():
		candidates = containers_by_id.values()
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func generate_container_loot(container_def: Dictionary, ring: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var context := String(container_def.get("loot_context", ""))
	var rows: Array = drop_rows_by_context.get(context, [])
	if rows.is_empty():
		return []
	var min_slots: int = max(1, int(container_def.get("loot_slots_min", 1)))
	var max_slots: int = max(min_slots, int(container_def.get("loot_slots_max", min_slots)))
	var slot_count := rng.randi_range(min_slots, max_slots)
	var result: Array[Dictionary] = []
	for _index in range(slot_count):
		var row := _pick_weighted_drop(rows, rng)
		if row.is_empty():
			continue
		var item_id := String(row.get("item_id", ""))
		var min_count: int = max(1, int(row.get("min_count", 1)))
		var max_count: int = max(min_count, int(row.get("max_count", min_count)))
		var amount: int = rng.randi_range(min_count, max_count)
		for _unit_index in range(amount):
			var stack := make_item_stack(item_id, 1)
			if stack.is_empty():
				continue
			stack["source_container_type"] = String(container_def.get("type_id", ""))
			stack["source_ring"] = _normalize_ring(ring)
			result.append(stack)
	return result

func make_item_stack(item_id: String, amount: int = 1) -> Dictionary:
	var item := get_item(item_id)
	if item.is_empty():
		return {}
	var quality := String(item.get("quality", "C"))
	return {
		"item_id": StringName(item_id),
		"display_name": String(item.get("name", item_id)),
		"amount": 1,
		"weight_per_unit": float(item.get("weight", 0.0)),
		"stack_limit": 1,
		"item_type": StringName(String(item.get("item_type", "material"))),
		"quality": StringName(quality),
		"quality_color": get_item_quality_color(quality),
		"tags": TabDataLoader.split_list(String(item.get("tags", ""))),
		"icon": String(item.get("icon", "")),
		"sellable": TabDataLoader.parse_bool(String(item.get("sellable", "false")), false),
		"sell_currency_id": String(item.get("sell_currency_id", "mine_coin")),
		"sell_value": int(item.get("sell_value", 0)),
	}

func _load_rows(path: String) -> Array[Dictionary]:
	var loader = TabDataLoaderScript.new()
	var rows: Array[Dictionary] = loader.load_tab(path)
	if not loader.last_error.is_empty():
		load_errors.append(loader.last_error)
	return rows

func _index_rows(rows: Array[Dictionary], id_field: String) -> Dictionary:
	var indexed := {}
	for row in rows:
		var id := String(row.get(id_field, ""))
		if id.is_empty():
			continue
		indexed[id] = row
	return indexed

func _pick_weighted_drop(rows: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0
	for row in rows:
		total_weight += max(0, int(row.get("weight", 0)))
	if total_weight <= 0:
		return {}
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for row in rows:
		cursor += max(0, int(row.get("weight", 0)))
		if roll <= cursor:
			return row
	return rows.back()

func _normalize_ring(ring: String) -> String:
	if ring == "deep_outer":
		return "far_outer"
	return ring

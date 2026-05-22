class_name ItemCatalogService
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

var collected_item_ids: Dictionary = {}
var data_registry = GameDataRegistryScript.new()
var _data_loaded := false

func bind_collected_items(bound_collected_item_ids: Dictionary) -> void:
	collected_item_ids = bound_collected_item_ids

func mark_collected(item_id: String, _source: String = "") -> Dictionary:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty():
		return {"ok": false, "changed": false, "reason": "missing_item_id"}
	if not _is_catalog_item(normalized_id):
		return {"ok": false, "changed": false, "reason": "unknown_item", "item_id": normalized_id}
	if bool(collected_item_ids.get(normalized_id, false)):
		return {"ok": true, "changed": false, "item_id": normalized_id}
	collected_item_ids[normalized_id] = true
	return {"ok": true, "changed": true, "item_id": normalized_id}

func mark_many_collected(item_ids: Array, source: String = "") -> Dictionary:
	var changed := false
	var marked: Array[String] = []
	for raw_id in item_ids:
		var result := mark_collected(String(raw_id), source)
		if bool(result.get("ok", false)):
			marked.append(String(result.get("item_id", raw_id)))
		if bool(result.get("changed", false)):
			changed = true
	return {
		"ok": true,
		"changed": changed,
		"marked_item_ids": marked,
	}

func is_collected(item_id: String) -> bool:
	return bool(collected_item_ids.get(item_id, false))

func get_collected_item_ids() -> Dictionary:
	return collected_item_ids.duplicate(true)

func clear_collected_debug_only() -> void:
	collected_item_ids.clear()

func mark_all_collected_debug_only() -> Dictionary:
	var ids: Array[String] = []
	for item in query_catalog_items():
		ids.append(String(item.get("item_id", "")))
	return mark_many_collected(ids, "debug_all")

func query_catalog_items(_filters: Dictionary = {}) -> Array[Dictionary]:
	if not _ensure_data_loaded():
		return []
	var rows: Array[Dictionary] = []
	for item in data_registry.items_by_id.values():
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var item_id := String(row.get("id", ""))
		if item_id.is_empty():
			continue
		var description := String(row.get("description", "")).strip_edges()
		if description.is_empty():
			description = "暂无记录。"
		rows.append({
			"item_id": item_id,
			"display_name": String(row.get("name", item_id)),
			"description": description,
			"icon": String(row.get("icon", "")),
			"quality": String(row.get("quality", "C")),
			"item_type": String(row.get("item_type", "")),
			"collected": is_collected(item_id),
		})
	rows.sort_custom(func(a, b):
		var quality_delta := _quality_rank(String(b.get("quality", "C"))) - _quality_rank(String(a.get("quality", "C")))
		if quality_delta != 0:
			return quality_delta < 0
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return rows

func _is_catalog_item(item_id: String) -> bool:
	if not _ensure_data_loaded():
		return false
	return not data_registry.get_item(item_id).is_empty()

func _ensure_data_loaded() -> bool:
	if _data_loaded:
		return true
	_data_loaded = data_registry.load_all()
	return _data_loaded

func _quality_rank(quality: String) -> int:
	match quality:
		"S":
			return 4
		"A":
			return 3
		"B":
			return 2
		_:
			return 1

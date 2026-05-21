class_name DailyDemandService
extends RefCounted

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const TAG_BONUS := {
	"medical": 0.16,
	"tool": 0.13,
	"electronic": 0.12,
	"food": 0.10,
	"stability": 0.08,
	"common": 0.04,
}

var data_registry = GameDataRegistryScript.new()
var _data_loaded := false


func generate_for_day(day: int) -> Array[Dictionary]:
	if not _ensure_data_loaded():
		return []
	var sale_goods := _get_sale_good_rows()
	if sale_goods.is_empty():
		return []

	var rng := RandomNumberGenerator.new()
	rng.seed = int(maxi(1, day)) * 7919 + 37
	var entries: Array[Dictionary] = []
	for row in sale_goods:
		var item_id := String(row.get("id", ""))
		var base_value := maxi(1, int(row.get("sell_value", 1)))
		var tag_score := _tag_bonus(row)
		var roll := rng.randf_range(0.82, 1.28)
		var score := clampf((1.0 + tag_score) * roll, 0.70, 1.65)
		var multiplier := clampf(0.88 + score * 0.22, 0.95, 1.35)
		entries.append({
			"demand_id": "%s:%d" % [item_id, maxi(1, day)],
			"item_id": item_id,
			"display_name": String(row.get("name", item_id)),
			"rank": 0,
			"demand_score": score,
			"sell_multiplier": multiplier,
			"base_sell_value": base_value,
			"estimated_unit_price": maxi(1, int(round(float(base_value) * multiplier))),
			"tags": TabDataLoaderScript.split_list(String(row.get("tags", ""))),
		})
	entries.sort_custom(func(a, b):
		var score_delta := float(b.get("demand_score", 0.0)) - float(a.get("demand_score", 0.0))
		if absf(score_delta) > 0.001:
			return score_delta < 0.0
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	for index in range(entries.size()):
		entries[index]["rank"] = index + 1
	return entries


func get_sale_good_item_ids() -> Array[String]:
	if not _ensure_data_loaded():
		return []
	var result: Array[String] = []
	for row in _get_sale_good_rows():
		result.append(String(row.get("id", "")))
	return result


func is_sale_good_item(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	if String(item.get("item_type", "")) == "sale_good":
		return true
	var tags = item.get("tags", [])
	if tags is Array:
		return Array(tags).has("sale_good")
	if tags is PackedStringArray:
		return Array(tags).has("sale_good")
	return TabDataLoaderScript.split_list(String(tags)).has("sale_good")


func _get_sale_good_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw_row in data_registry.items_by_id.values():
		if not (raw_row is Dictionary):
			continue
		var row: Dictionary = raw_row
		if not _is_enabled(row):
			continue
		if not _is_sale_good_row(row):
			continue
		if int(row.get("sell_value", 0)) <= 0:
			continue
		rows.append(row.duplicate(true))
	rows.sort_custom(func(a, b): return String(a.get("name", "")) < String(b.get("name", "")))
	return rows


func _is_sale_good_row(row: Dictionary) -> bool:
	if String(row.get("item_type", "")) == "sale_good":
		return true
	return TabDataLoaderScript.split_list(String(row.get("tags", ""))).has("sale_good")


func _is_enabled(row: Dictionary) -> bool:
	var enabled_version := String(row.get("enabled_version", ""))
	return not enabled_version.is_empty()


func _tag_bonus(row: Dictionary) -> float:
	var total := 0.0
	for tag in TabDataLoaderScript.split_list(String(row.get("tags", ""))):
		total += float(TAG_BONUS.get(tag, 0.0))
	return total


func _ensure_data_loaded() -> bool:
	if _data_loaded:
		return true
	_data_loaded = data_registry.load_all()
	return _data_loaded

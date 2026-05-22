extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const VALID_ITEM_QUALITIES := ["C", "B", "A", "S"]

func _initialize() -> void:
	var ok := _verify_high_tier_quality_removed()
	print("High-tier quality cleanup verified." if ok else "High-tier quality cleanup failed.")
	quit(0 if ok else 1)

func _verify_high_tier_quality_removed() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false
	var ok := true
	for item_id in registry.items_by_id.keys():
		if String(item_id).begins_with("ss_"):
			printerr("Item id must not use legacy ss_ prefix: %s" % item_id)
			ok = false
	for item in registry.items_by_id.values():
		var quality := String(item.get("quality", ""))
		if not VALID_ITEM_QUALITIES.has(quality):
			printerr("Item uses invalid quality: %s" % item)
			ok = false
	for row in registry.quality_colors_by_id.values():
		var quality := String(row.get("quality", ""))
		if not VALID_ITEM_QUALITIES.has(quality):
			printerr("Quality color table must only define C/B/A/S: %s" % row)
			ok = false
	for row in registry.ss_chance_tier_rows:
		if TabDataLoaderScript.parse_bool(String(row.get("enabled", "false")), false):
			printerr("Legacy high-tier chance rows must stay disabled: %s" % row)
			ok = false
		if float(row.get("hit_chance", 0.0)) > 0.0:
			printerr("Legacy high-tier chance rows must have zero chance: %s" % row)
			ok = false
	for row in registry.ss_container_chance_rows_by_type.values():
		if TabDataLoaderScript.parse_bool(String(row.get("enabled", "false")), false):
			printerr("Legacy high-tier container rows must stay disabled: %s" % row)
			ok = false
		if float(row.get("roll_chance", 0.0)) > 0.0:
			printerr("Legacy high-tier container rows must have zero chance: %s" % row)
			ok = false
	if not registry.get_ss_loot_pool_rows().is_empty():
		printerr("Legacy high-tier loot pool must resolve empty.")
		ok = false
	return ok

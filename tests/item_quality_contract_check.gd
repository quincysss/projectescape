extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

const ALLOWED_QUALITIES := ["C", "B", "A", "S"]

func _initialize() -> void:
	var ok := _verify_quality_contract()
	print("Item quality contract verified." if ok else "Item quality contract failed.")
	quit(0 if ok else 1)

func _verify_quality_contract() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load: %s" % registry.load_errors)
		return false
	for item_id in registry.items_by_id.keys():
		var item: Dictionary = registry.get_item(String(item_id))
		var quality := String(item.get("quality", ""))
		if not ALLOWED_QUALITIES.has(quality):
			printerr("Invalid item quality %s for %s." % [quality, item_id])
			return false
		var stack: Dictionary = registry.make_item_stack(String(item_id), 2)
		if not ALLOWED_QUALITIES.has(String(stack.get("quality", ""))):
			printerr("Invalid generated stack quality for %s: %s" % [item_id, stack])
			return false
	if not registry.get_ss_chance_tier_rows().is_empty() or registry.get_ss_chance_for_tier(0) != 0.0 or not registry.pick_ss_item_stack(RandomNumberGenerator.new()).is_empty():
		printerr("SS loot path should be disabled; only C/B/A/S qualities are allowed.")
		return false
	return true

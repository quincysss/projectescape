extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

func _initialize() -> void:
	var ok := _verify_loot_expansion()
	print("Loot expansion verified." if ok else "Loot expansion failed.")
	quit(0 if ok else 1)

func _verify_loot_expansion() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false
	var ok := true
	var expected_by_quality := _expected_items_by_quality()
	var dropped_ids := _collect_dropped_item_ids(registry)
	for quality in expected_by_quality.keys():
		var ids: Array = expected_by_quality[quality]
		var expected_count := _expected_quality_count(String(quality))
		if ids.size() != expected_count:
			printerr("Expected %s new %s quality drops, got %s." % [expected_count, quality, ids.size()])
			ok = false
		for item_id in ids:
			var item: Dictionary = registry.get_item(String(item_id))
			if item.is_empty():
				printerr("Missing expanded loot item: %s" % item_id)
				ok = false
				continue
			if String(item.get("quality", "")) != String(quality):
				printerr("Expanded loot item %s has wrong quality: %s" % [item_id, item.get("quality", "")])
				ok = false
			if String(item.get("stackable", "")) != "false" or int(item.get("stack_limit", 0)) != 1:
				printerr("Expanded loot item %s must be single-slot and non-stackable." % item_id)
				ok = false
			if not dropped_ids.has(String(item_id)):
				printerr("Expanded loot item %s is not attached to any drop table." % item_id)
				ok = false
			var item_type := String(item.get("item_type", ""))
			var sellable := TabDataLoaderScript.parse_bool(String(item.get("sellable", "")), false)
			var sell_value := int(item.get("sell_value", 0))
			if item_type == "material" or item_type == "outpost_material":
				if sellable or sell_value != 0:
					printerr("Expanded material %s should not have merchant value." % item_id)
					ok = false
			elif not sellable or sell_value <= 0:
				printerr("Expanded non-material %s should have merchant value." % item_id)
				ok = false
	if not _verify_context_contents(registry):
		ok = false
	return ok

func _expected_items_by_quality() -> Dictionary:
	return {
		"C": ["ration_bar", "cracked_lens", "duct_tape_roll", "rusted_bolts", "cracked_compass"],
		"B": ["sterile_patch", "reinforced_strap", "pulse_battery", "street_map_fragment", "signal_resonator_coil"],
		"A": ["sealed_medkit", "survey_drone_core", "thermal_scope_module"],
		"S": ["blackbox_memory_core", "prefall_access_key", "anomaly_heart_shard", "sanctuary_nav_chip"],
	}

func _expected_quality_count(quality: String) -> int:
	match quality:
		"C":
			return 5
		"B":
			return 5
		"A":
			return 3
		"S":
			return 4
	return 0

func _collect_dropped_item_ids(registry) -> Dictionary:
	var dropped_ids := {}
	for context in registry.drop_rows_by_context.keys():
		for row in registry.drop_rows_by_context[context]:
			dropped_ids[String(row.get("item_id", ""))] = true
	return dropped_ids

func _verify_context_contents(registry) -> bool:
	var ok := true
	var expected_contexts := {
		"container_cardboard": ["ration_bar", "cracked_lens", "duct_tape_roll", "cracked_compass"],
		"container_wooden": ["rusted_bolts", "duct_tape_roll", "reinforced_strap"],
		"container_tool": ["pulse_battery", "signal_resonator_coil", "thermal_scope_module"],
		"container_medical": ["sterile_patch", "sealed_medkit"],
		"container_small_safe": ["street_map_fragment", "survey_drone_core", "prefall_access_key"],
		"container_large_safe": ["sealed_medkit", "survey_drone_core", "blackbox_memory_core", "sanctuary_nav_chip"],
		"container_anomaly": ["anomaly_heart_shard", "blackbox_memory_core", "sanctuary_nav_chip", "prefall_access_key"],
	}
	for context in expected_contexts.keys():
		var rows: Array = registry.drop_rows_by_context.get(String(context), [])
		var context_ids := {}
		for row in rows:
			context_ids[String(row.get("item_id", ""))] = true
		for item_id in expected_contexts[context]:
			if not context_ids.has(String(item_id)):
				printerr("Expected %s to include expanded loot item %s." % [context, item_id])
				ok = false
	return ok

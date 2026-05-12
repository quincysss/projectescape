extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := _verify_container_loot_balance()
	print("Container loot balance verified." if ok else "Container loot balance failed.")
	quit(0 if ok else 1)

func _verify_container_loot_balance() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected game data registry to load: %s" % registry.load_errors)
		return false
	var ok := true
	ok = _verify_context_quality_coverage(registry) and ok
	ok = _verify_box_quality_surprises(registry) and ok
	ok = _verify_safe_quality_bias(registry) and ok
	ok = _verify_container_type_weights(registry) and ok
	return ok

func _verify_context_quality_coverage(registry) -> bool:
	var ok := true
	for context in registry.drop_rows_by_context.keys():
		for quality in ["C", "B", "A", "S"]:
			if not _context_has_quality(registry, String(context), quality):
				printerr("Expected %s to include %s quality candidates." % [context, quality])
				ok = false
	return ok

func _verify_box_quality_surprises(registry) -> bool:
	var ok := true
	for case_data in [
		{"type_id": "cardboard_box", "ring": "middle", "seed": 31001},
		{"type_id": "wooden_crate", "ring": "middle", "seed": 31002},
	]:
		var counts := _sample_loot_qualities(registry, case_data.type_id, case_data.ring, int(case_data.seed), 20000)
		for quality in ["B", "A", "S"]:
			if int(counts.get(quality, 0)) <= 0:
				printerr("Expected %s in %s/%s loot sample, got %s." % [quality, case_data.type_id, case_data.ring, counts])
				ok = false
	return ok

func _verify_safe_quality_bias(registry) -> bool:
	var ok := true
	for case_data in [
		{"type_id": "small_safe", "ring": "outer", "seed": 42001},
		{"type_id": "small_safe", "ring": "far_outer", "seed": 42002},
		{"type_id": "large_safe", "ring": "outer", "seed": 42003},
		{"type_id": "large_safe", "ring": "far_outer", "seed": 42004},
	]:
		var counts := _sample_loot_qualities(registry, case_data.type_id, case_data.ring, int(case_data.seed), 5000)
		var common_count := int(counts.get("C", 0)) + int(counts.get("B", 0))
		var rare_count := int(counts.get("A", 0)) + int(counts.get("S", 0))
		var total_count := common_count + rare_count
		if int(counts.get("C", 0)) <= 0 or int(counts.get("B", 0)) <= 0:
			printerr("Expected %s/%s to produce both C and B loot, got %s." % [case_data.type_id, case_data.ring, counts])
			ok = false
		if common_count <= rare_count:
			printerr("Expected %s/%s to favor C/B over A/S, got %s." % [case_data.type_id, case_data.ring, counts])
			ok = false
		if total_count > 0 and int(counts.get("S", 0)) * 10 > total_count:
			printerr("Expected %s/%s S quality to stay below 10%%, got %s." % [case_data.type_id, case_data.ring, counts])
			ok = false
	return ok

func _verify_container_type_weights(registry) -> bool:
	var ok := true
	var outer_counts := _sample_container_types(registry, "outer", 51001, 2000)
	var far_counts := _sample_container_types(registry, "far_outer", 51002, 2000)
	for type_id in ["small_safe", "large_safe"]:
		if int(outer_counts.get(type_id, 0)) <= 0:
			printerr("Expected outer ring to be able to spawn %s, got %s." % [type_id, outer_counts])
			ok = false
		if int(far_counts.get(type_id, 0)) <= 0:
			printerr("Expected far_outer ring to be able to spawn %s, got %s." % [type_id, far_counts])
			ok = false
	for type_id in ["tool_cabinet", "medical_cabinet", "anomaly_case"]:
		if int(far_counts.get(type_id, 0)) <= 0:
			printerr("Expected far_outer ring to be able to spawn %s, got %s." % [type_id, far_counts])
			ok = false
	return ok

func _context_has_quality(registry, context: String, quality: String) -> bool:
	var rows: Array = registry.drop_rows_by_context.get(context, [])
	for row in rows:
		var item: Dictionary = registry.get_item(String(row.get("item_id", "")))
		if String(item.get("quality", "")) == quality:
			return true
	return false

func _sample_loot_qualities(registry, type_id: String, ring: String, seed: int, iterations: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var container_def: Dictionary = registry.get_container_type(type_id)
	var counts := {"C": 0, "B": 0, "A": 0, "S": 0}
	for _index in range(iterations):
		var loot: Array[Dictionary] = registry.generate_container_loot(container_def, ring, rng)
		for item in loot:
			var quality := String(item.get("quality", "C"))
			counts[quality] = int(counts.get(quality, 0)) + 1
	return counts

func _sample_container_types(registry, ring: String, seed: int, iterations: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var counts := {}
	for _index in range(iterations):
		var container_def: Dictionary = registry.pick_container_type_for_ring(ring, rng)
		var type_id := String(container_def.get("type_id", ""))
		counts[type_id] = int(counts.get(type_id, 0)) + 1
	return counts

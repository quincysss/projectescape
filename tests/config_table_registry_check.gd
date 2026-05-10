extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")

func _initialize() -> void:
	var ok := _verify_registry()
	print("Config table registry verified." if ok else "Config table registry failed.")
	quit(0 if ok else 1)

func _verify_registry() -> bool:
	var registry = GameDataRegistryScript.new()
	var ok: bool = registry.load_all()
	if not ok:
		printerr("Data registry load errors: %s" % str(registry.load_errors))
		return false
	if registry.items_by_id.size() < 10:
		printerr("Expected item table content.")
		ok = false
	for item in registry.items_by_id.values():
		if String(item.get("stackable", "")) != "false" or int(item.get("stack_limit", 0)) != 1:
			printerr("Item %s must be single-slot and non-stackable." % item.get("id", ""))
			ok = false
	if registry.containers_by_id.size() < 7:
		printerr("Expected seven configured container types.")
		ok = false
	for container in registry.containers_by_id.values():
		if container.has("quality") or container.has("grade") or container.has("rarity"):
			printerr("Container config must not expose S/A/B/C grade fields.")
			ok = false
		if String(container.get("visual_color_hex", "")) != "#3A8DFF":
			printerr("Container %s does not use unified blue." % container.get("type_id", ""))
			ok = false
		if String(container.get("quality_label_enabled", "")) != "false":
			printerr("Container %s should hide quality labels." % container.get("type_id", ""))
			ok = false
	for context in registry.drop_rows_by_context.keys():
		for row in registry.drop_rows_by_context[context]:
			if registry.get_item(String(row.get("item_id", ""))).is_empty():
				printerr("Drop row references missing item: %s" % row.get("item_id", ""))
				ok = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var wooden := registry.get_container_type("wooden_crate")
	var loot: Array[Dictionary] = registry.generate_container_loot(wooden, "middle", rng)
	if loot.is_empty():
		printerr("Expected generated loot for wooden_crate.")
		ok = false
	for item in loot:
		if not item.has("quality") or not item.has("quality_color"):
			printerr("Generated item lacks quality display fields.")
			ok = false
		if int(item.get("amount", 0)) != 1 or int(item.get("stack_limit", 0)) != 1:
			printerr("Generated loot must be split into single non-stackable items.")
			ok = false
	return ok

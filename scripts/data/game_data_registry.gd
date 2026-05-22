class_name GameDataRegistry
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

const ITEMS_PATH := "res://setting/items.tab"
const REPAIR_MATERIALS_PATH := "res://setting/repairmaterial.tab"
const CURRENCIES_PATH := "res://data/currencies.tab"
const ITEM_QUALITY_COLORS_PATH := "res://setting/item_quality_colors.tab"
const CONTAINER_TYPES_PATH := "res://setting/container_types.tab"
const DROP_TABLES_PATH := "res://setting/drop_tables.tab"
const SHOP_STOCK_PATH := "res://setting/shop_stock.tab"
const RESEARCH_PATH := "res://setting/research.tab"
const CRAFTING_RECIPES_PATH := "res://setting/crafting_recipes.tab"
const SS_CHANCE_TIERS_PATH := "res://setting/ss_chance_tiers.tab"
const SS_CONTAINER_CHANCES_PATH := "res://setting/ss_container_chances.tab"
const SS_LOOT_POOL_PATH := "res://setting/ss_loot_pool.tab"
const MAP_RESOURCE_PROFILES_PATH := "res://setting/map_resource_profiles.tab"
const LOCATION_STATE_RULES_PATH := "res://setting/location_state_rules.tab"

const QUALITY_ORDER := ["C", "B", "A", "S"]
const RING_CONTAINER_TYPE_WEIGHTS := {
	"inner": {
		"cardboard_box": 60,
		"wooden_crate": 40,
	},
	"middle": {
		"cardboard_box": 30,
		"wooden_crate": 30,
		"tool_cabinet": 20,
		"medical_cabinet": 20,
	},
	"outer": {
		"wooden_crate": 10,
		"tool_cabinet": 30,
		"medical_cabinet": 25,
		"small_safe": 25,
		"large_safe": 10,
	},
	"far_outer": {
		"tool_cabinet": 10,
		"medical_cabinet": 10,
		"small_safe": 20,
		"large_safe": 45,
		"anomaly_case": 15,
	},
}
const RING_QUALITY_WEIGHTS := {
	"inner": {"C": 850.0, "B": 140.0, "A": 9.0, "S": 1.0},
	"middle": {"C": 650.0, "B": 300.0, "A": 45.0, "S": 5.0},
	"outer": {"C": 350.0, "B": 450.0, "A": 180.0, "S": 20.0},
	"far_outer": {"C": 200.0, "B": 400.0, "A": 320.0, "S": 80.0},
}
const CONTAINER_QUALITY_MODIFIERS := {
	"cardboard_box": {"C": 1.10, "B": 0.80, "A": 0.55, "S": 0.45},
	"wooden_crate": {"C": 1.00, "B": 0.95, "A": 0.70, "S": 0.55},
	"tool_cabinet": {"C": 0.95, "B": 1.10, "A": 0.90, "S": 0.75},
	"medical_cabinet": {"C": 0.95, "B": 1.05, "A": 1.00, "S": 0.75},
	"small_safe": {"C": 0.90, "B": 1.15, "A": 0.90, "S": 0.65},
	"large_safe": {"C": 0.90, "B": 1.15, "A": 1.00, "S": 0.80},
	"anomaly_case": {"C": 0.55, "B": 0.90, "A": 1.15, "S": 1.30},
}

var items_by_id: Dictionary = {}
var repair_materials_by_id: Dictionary = {}
var currencies_by_id: Dictionary = {}
var quality_colors_by_id: Dictionary = {}
var containers_by_id: Dictionary = {}
var drop_rows_by_context: Dictionary = {}
var shop_stock_rows: Array[Dictionary] = []
var research_rows: Array[Dictionary] = []
var crafting_recipe_rows: Array[Dictionary] = []
var ss_chance_tier_rows: Array[Dictionary] = []
var ss_container_chance_rows_by_type: Dictionary = {}
var ss_loot_pool_rows: Array[Dictionary] = []
var map_resource_profiles_by_id: Dictionary = {}
var location_state_rules_by_id: Dictionary = {}
var load_errors: Array[String] = []

func load_all() -> bool:
	load_errors.clear()
	items_by_id = _index_rows(_load_rows(ITEMS_PATH), "id")
	repair_materials_by_id = _index_rows(_load_rows(REPAIR_MATERIALS_PATH), "id")
	currencies_by_id = _index_rows(_load_rows(CURRENCIES_PATH), "id")
	quality_colors_by_id = _index_rows(_load_rows(ITEM_QUALITY_COLORS_PATH), "quality")
	containers_by_id = _index_rows(_load_rows(CONTAINER_TYPES_PATH), "type_id")
	shop_stock_rows = _load_rows(SHOP_STOCK_PATH)
	research_rows = _load_rows(RESEARCH_PATH)
	crafting_recipe_rows = _load_rows(CRAFTING_RECIPES_PATH)
	ss_chance_tier_rows = _load_rows(SS_CHANCE_TIERS_PATH)
	ss_container_chance_rows_by_type = _index_rows(_load_rows(SS_CONTAINER_CHANCES_PATH), "type_id")
	ss_loot_pool_rows = _load_rows(SS_LOOT_POOL_PATH)
	map_resource_profiles_by_id = _index_rows(_load_rows(MAP_RESOURCE_PROFILES_PATH), "map_id")
	location_state_rules_by_id = _index_rows(_load_rows(LOCATION_STATE_RULES_PATH), "state_id")
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

func get_repair_material(material_id: String) -> Dictionary:
	return repair_materials_by_id.get(material_id, {})

func get_currency(currency_id: String) -> Dictionary:
	return currencies_by_id.get(currency_id, {})

func get_repair_material_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in repair_materials_by_id.values():
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		result.append(row.duplicate(true))
	result.sort_custom(func(a, b): return String(a.get("id", "")) < String(b.get("id", "")))
	return result

func get_item_quality_color(quality: String) -> Color:
	var row: Dictionary = quality_colors_by_id.get(_normalize_quality(quality), {})
	return TabDataLoader.parse_color(String(row.get("text_color_hex", "")), Color.WHITE)

func get_container_type(type_id: String) -> Dictionary:
	return containers_by_id.get(type_id, {})

func get_map_resource_profile(map_id: String) -> Dictionary:
	var row: Dictionary = map_resource_profiles_by_id.get(map_id, {})
	if row.is_empty() and map_resource_profiles_by_id.has("abandoned_house"):
		row = map_resource_profiles_by_id.get("abandoned_house", {})
	return row.duplicate(true)

func get_map_resource_profiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in map_resource_profiles_by_id.values():
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		result.append(row.duplicate(true))
	result.sort_custom(func(a, b): return String(a.get("map_id", "")) < String(b.get("map_id", "")))
	return result

func get_location_state_rule(state_id: String) -> Dictionary:
	var row: Dictionary = location_state_rules_by_id.get(state_id, {})
	if row.is_empty() and location_state_rules_by_id.has("normal"):
		row = location_state_rules_by_id.get("normal", {})
	return row.duplicate(true)

func get_container_types_for_ring(ring: String) -> Array[Dictionary]:
	var normalized_ring := _normalize_ring(ring)
	var result: Array[Dictionary] = []
	for container in containers_by_id.values():
		var allowed := TabDataLoader.split_list(String(container.get("allowed_rings", "")))
		if allowed.has(normalized_ring):
			result.append(container)
	return result

func get_research_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in research_rows:
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		result.append(row.duplicate(true))
	result.sort_custom(func(a, b):
		var id_a := String(a.get("research_id", ""))
		var id_b := String(b.get("research_id", ""))
		if id_a != id_b:
			return id_a < id_b
		return int(a.get("level", 0)) < int(b.get("level", 0))
	)
	return result

func get_crafting_recipe_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in crafting_recipe_rows:
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		var output_item_id := String(row.get("output_item_id", ""))
		if output_item_id.is_empty() or get_item(output_item_id).is_empty():
			continue
		result.append(row.duplicate(true))
	result.sort_custom(func(a, b): return String(a.get("recipe_id", "")) < String(b.get("recipe_id", "")))
	return result

func get_ss_chance_tier_rows() -> Array[Dictionary]:
	return []

func get_ss_chance_for_tier(tier: int) -> float:
	return 0.0

func get_ss_container_chance(type_id: String) -> float:
	return 0.0

func is_ss_pity_container(type_id: String) -> bool:
	return false

func get_ss_loot_pool_rows() -> Array[Dictionary]:
	return []

func get_ss_loot_pool_item_ids() -> Array[String]:
	var result: Array[String] = []
	for row in get_ss_loot_pool_rows():
		result.append(String(row.get("item_id", "")))
	return result

func pick_ss_item_stack(rng: RandomNumberGenerator) -> Dictionary:
	return {}

func pick_container_type_for_ring(ring: String, rng: RandomNumberGenerator) -> Dictionary:
	var normalized_ring := _normalize_ring(ring)
	var candidates := get_container_types_for_ring(normalized_ring)
	if candidates.is_empty():
		candidates = containers_by_id.values()
	if candidates.is_empty():
		return {}
	var weighted_candidate := _pick_weighted_container_type(candidates, normalized_ring, rng)
	if not weighted_candidate.is_empty():
		return weighted_candidate
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func pick_container_type_for_profile(ring: String, map_profile: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var normalized_ring := _normalize_ring(ring)
	var candidates := get_container_types_for_ring(normalized_ring)
	if candidates.is_empty():
		candidates = containers_by_id.values()
	if candidates.is_empty():
		return {}
	var weighted_candidate := _pick_weighted_container_type(candidates, normalized_ring, rng, map_profile)
	if not weighted_candidate.is_empty():
		return weighted_candidate
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func get_shop_stock_rows_for_level(shop_level: int, shop_id: String = "base_merchant") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in shop_stock_rows:
		if String(row.get("shop_id", "")) != shop_id:
			continue
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		var min_level: int = max(1, int(row.get("min_shop_level", 1)))
		var max_level: int = max(min_level, int(row.get("max_shop_level", min_level)))
		if shop_level < min_level or shop_level > max_level:
			continue
		var item_id := String(row.get("item_id", ""))
		var item := get_item(item_id)
		if item.is_empty():
			continue
		if not _is_shop_stock_item(item):
			continue
		result.append(row)
	return result

func _is_shop_stock_item(item: Dictionary) -> bool:
	if String(item.get("item_type", "")).is_empty():
		return false
	if not TabDataLoader.parse_bool(String(item.get("sellable", "false")), false):
		return false
	if int(item.get("sell_value", 0)) <= 0:
		return false
	return QUALITY_ORDER.has(String(item.get("quality", "")))

func generate_container_loot(container_def: Dictionary, ring: String, rng: RandomNumberGenerator, generation_context: Dictionary = {}) -> Array[Dictionary]:
	var context := String(container_def.get("loot_context", ""))
	var rows: Array = _normal_drop_rows(drop_rows_by_context.get(context, []))
	if rows.is_empty():
		return []
	var min_slots: int = max(1, int(container_def.get("loot_slots_min", 1)))
	var max_slots: int = max(min_slots, int(container_def.get("loot_slots_max", min_slots)))
	var quantity_multiplier := _context_quantity_multiplier(generation_context)
	min_slots = max(1, int(round(float(min_slots) * quantity_multiplier)))
	max_slots = max(min_slots, int(round(float(max_slots) * quantity_multiplier)))
	var slot_count := rng.randi_range(min_slots, max_slots)
	var result: Array[Dictionary] = []
	for _index in range(slot_count):
		var quality := _pick_loot_quality(rows, container_def, ring, rng, generation_context)
		var candidate_rows := _drop_rows_for_quality(rows, quality)
		var row := _pick_weighted_drop(candidate_rows, rng, generation_context)
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
	var quality := _normalize_quality(String(item.get("quality", "C")))
	return {
		"item_id": StringName(item_id),
		"display_name": String(item.get("name", item_id)),
		"amount": maxi(1, amount),
		"weight_per_unit": float(item.get("weight", 0.0)),
		"stackable": TabDataLoader.parse_bool(String(item.get("stackable", "false")), false),
		"stack_limit": maxi(1, int(item.get("stack_limit", 1))),
		"item_type": StringName(String(item.get("item_type", "material"))),
		"quality": StringName(quality),
		"quality_color": get_item_quality_color(quality),
		"tags": TabDataLoader.split_list(String(item.get("tags", ""))),
		"icon": String(item.get("icon", "")),
		"sellable": TabDataLoader.parse_bool(String(item.get("sellable", "false")), false),
		"sell_currency_id": String(item.get("sell_currency_id", "mine_coin")),
		"sell_value": int(item.get("sell_value", 0)),
	}

func make_repair_material_stack(material_id: String, amount: int = 1, outpost_id: String = "") -> Dictionary:
	var material := get_repair_material(material_id)
	if material.is_empty():
		return {}
	return {
		"repair_material_id": StringName(material_id),
		"item_id": StringName(material_id),
		"display_name": String(material.get("display_name", material_id)),
		"amount": maxi(1, amount),
		"weight_per_unit": float(material.get("weight", 0.0)),
		"stack_limit": 1,
		"icon": String(material.get("icon", "")),
		"description": String(material.get("description", "")),
		"source": "repair_material_spawn",
		"outpost_id": outpost_id,
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

func _pick_weighted_drop(rows: Array, rng: RandomNumberGenerator, generation_context: Dictionary = {}) -> Dictionary:
	var total_weight := 0.0
	for row in rows:
		total_weight += _drop_row_weight(row, generation_context)
	if total_weight <= 0:
		return {}
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for row in rows:
		cursor += _drop_row_weight(row, generation_context)
		if roll <= cursor:
			return row
	return rows.back()

func _pick_weighted_container_type(candidates: Array, ring: String, rng: RandomNumberGenerator, map_profile: Dictionary = {}) -> Dictionary:
	var weights: Dictionary = RING_CONTAINER_TYPE_WEIGHTS.get(ring, {})
	if weights.is_empty():
		return {}
	var overrides := _parse_weight_overrides(String(map_profile.get("container_type_weight_overrides", "")))
	var total_weight := 0.0
	for container in candidates:
		var type_id := String(container.get("type_id", ""))
		total_weight += maxf(0.0, float(weights.get(type_id, 0)) * float(overrides.get(type_id, 1.0)))
	if total_weight <= 0:
		return {}
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for container in candidates:
		var type_id := String(container.get("type_id", ""))
		cursor += maxf(0.0, float(weights.get(type_id, 0)) * float(overrides.get(type_id, 1.0)))
		if roll <= cursor:
			return container
	return candidates.back()

func _pick_loot_quality(rows: Array, container_def: Dictionary, ring: String, rng: RandomNumberGenerator, generation_context: Dictionary = {}) -> String:
	var normalized_ring := _normalize_ring(ring)
	var base_weights: Dictionary = RING_QUALITY_WEIGHTS.get(normalized_ring, RING_QUALITY_WEIGHTS.get("inner", {}))
	var modifier_weights: Dictionary = CONTAINER_QUALITY_MODIFIERS.get(String(container_def.get("type_id", "")), {})
	var rare_multiplier := _context_rare_multiplier(generation_context)
	var low_tier_multiplier := _context_low_tier_multiplier(generation_context)
	var quality_weights := {}
	var total_weight := 0.0
	for quality in QUALITY_ORDER:
		if not _has_drop_rows_for_quality(rows, quality):
			continue
		var adjusted_weight := float(base_weights.get(quality, 0.0)) * float(modifier_weights.get(quality, 1.0))
		if quality == "A" or quality == "S":
			adjusted_weight *= rare_multiplier
		elif quality == "C":
			adjusted_weight *= low_tier_multiplier
		if adjusted_weight <= 0.0:
			continue
		quality_weights[quality] = adjusted_weight
		total_weight += adjusted_weight
	if total_weight <= 0.0:
		return _first_available_quality(rows)
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for quality in QUALITY_ORDER:
		cursor += float(quality_weights.get(quality, 0.0))
		if roll <= cursor:
			return quality
	return _first_available_quality(rows)

func _drop_rows_for_quality(rows: Array, quality: String) -> Array:
	var result: Array = []
	for row in rows:
		if _drop_row_quality(row) == quality:
			result.append(row)
	if result.is_empty():
		return rows
	return result

func _has_drop_rows_for_quality(rows: Array, quality: String) -> bool:
	for row in rows:
		if _drop_row_quality(row) == quality:
			return true
	return false

func _first_available_quality(rows: Array) -> String:
	for quality in QUALITY_ORDER:
		if _has_drop_rows_for_quality(rows, quality):
			return quality
	return "C"

func _normal_drop_rows(rows: Array) -> Array:
	var result: Array = []
	for row in rows:
		if not QUALITY_ORDER.has(_drop_row_quality(row)):
			continue
		result.append(row)
	return result

func _drop_row_quality(row: Dictionary) -> String:
	var item := get_item(String(row.get("item_id", "")))
	if item.is_empty():
		return ""
	return _normalize_quality(String(item.get("quality", "C")))

func _fallback_ss_chance_for_tier(tier: int) -> float:
	return 0.0

func _normalize_ring(ring: String) -> String:
	if ring == "deep_outer":
		return "far_outer"
	return ring

func _normalize_quality(quality: String) -> String:
	var normalized := quality.strip_edges().to_upper()
	if QUALITY_ORDER.has(normalized):
		return normalized
	return "C"

func _context_quantity_multiplier(generation_context: Dictionary) -> float:
	var state_rule: Dictionary = generation_context.get("location_state_rule", {})
	return maxf(0.10, float(state_rule.get("quantity_multiplier", 1.0)))

func _context_rare_multiplier(generation_context: Dictionary) -> float:
	var state_rule: Dictionary = generation_context.get("location_state_rule", {})
	return maxf(0.0, float(state_rule.get("rare_multiplier", 1.0)))

func _context_low_tier_multiplier(generation_context: Dictionary) -> float:
	var state_rule: Dictionary = generation_context.get("location_state_rule", {})
	return maxf(0.0, float(state_rule.get("low_tier_multiplier", 1.0)))

func _drop_row_weight(row: Dictionary, generation_context: Dictionary) -> float:
	var weight := maxf(0.0, float(row.get("weight", 0)))
	if weight <= 0.0:
		return 0.0
	var map_profile: Dictionary = generation_context.get("map_profile", {})
	if map_profile.is_empty():
		return weight
	var tags := _drop_row_tags(row)
	var primary_multiplier := maxf(0.0, float(map_profile.get("primary_weight_multiplier", 1.75)))
	var secondary_multiplier := maxf(0.0, float(map_profile.get("secondary_weight_multiplier", 1.25)))
	if _tags_match_any(tags, TabDataLoader.split_list(String(map_profile.get("primary_categories", "")))):
		weight *= primary_multiplier
	elif _tags_match_any(tags, TabDataLoader.split_list(String(map_profile.get("secondary_categories", "")))):
		weight *= secondary_multiplier
	return weight

func _drop_row_tags(row: Dictionary) -> Array[String]:
	var result: Array[String] = []
	result.append_array(TabDataLoader.split_list(String(row.get("required_tags", ""))))
	var item := get_item(String(row.get("item_id", "")))
	if not item.is_empty():
		result.append(String(item.get("item_type", "")))
		result.append_array(TabDataLoader.split_list(String(item.get("tags", ""))))
	for index in range(result.size()):
		result[index] = result[index].to_lower()
	return result

func _tags_match_any(tags: Array[String], categories: Array[String]) -> bool:
	for category in categories:
		var normalized := category.to_lower()
		if tags.has(normalized):
			return true
	return false

func _parse_weight_overrides(value: String) -> Dictionary:
	var result := {}
	for part in TabDataLoader.split_list(value):
		var bits := part.split(":", false, 1)
		if bits.size() != 2:
			continue
		var key := String(bits[0]).strip_edges()
		if key.is_empty():
			continue
		result[key] = float(String(bits[1]).strip_edges())
	return result

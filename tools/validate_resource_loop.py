from __future__ import annotations

import csv
import sys
from pathlib import Path
from posixpath import basename


ROOT = Path(__file__).resolve().parents[1]
SETTING = ROOT / "setting"
VALID_QUALITIES = {"C", "B", "A", "S"}

REQUIRED_COLUMNS = {
    "resource_categories.tab": {
        "category_id",
        "display_name",
        "stack_policy",
        "default_stack_limit",
        "primary_outlet",
        "quality_strategy",
        "source_hint",
        "enabled_version",
    },
    "resource_outlets.tab": {
        "item_id",
        "category_id",
        "outlet_type",
        "target_id",
        "min_chapter",
        "priority",
        "enabled_version",
    },
    "map_resource_profiles.tab": {
        "map_id",
        "display_name",
        "map_type",
        "primary_categories",
        "secondary_categories",
        "container_count_min",
        "container_count_max",
        "primary_weight_multiplier",
        "secondary_weight_multiplier",
        "container_type_weight_overrides",
        "default_state",
        "enabled",
    },
    "room_resource_profiles.tab": {
        "room_profile_id",
        "room_type",
        "category_bias",
        "container_bias",
        "rare_tag_bias",
        "enabled_version",
    },
    "location_state_rules.tab": {
        "state_id",
        "display_name",
        "container_count_multiplier",
        "quantity_multiplier",
        "rare_multiplier",
        "low_tier_multiplier",
        "regen_hours_multiplier",
        "notes",
        "enabled_version",
    },
    "container_resource_bias.tab": {
        "context",
        "category_id",
        "weight",
        "quality_bias",
        "notes",
        "enabled_version",
    },
}


def read_tab(name: str) -> list[dict[str, str]]:
    path = SETTING / name
    rows: list[dict[str, str]] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        filtered = (line for line in handle if line.strip() and not line.startswith("#"))
        reader = csv.DictReader(filtered, delimiter="\t")
        for row in reader:
            rows.append({key: (value or "").strip() for key, value in row.items()})
    return rows


def read_header(name: str) -> list[str]:
    path = SETTING / name
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for line in handle:
            if line.strip() and not line.startswith("#"):
                return [part.strip() for part in line.rstrip("\r\n").split("\t")]
    return []


def split_list(value: str) -> list[str]:
    return [part.strip() for part in value.split(";") if part.strip()]


def parse_requirements(value: str) -> dict[str, int]:
    result: dict[str, int] = {}
    for part in split_list(value):
        if ":" not in part:
            raise ValueError(f"bad requirement token: {part}")
        item_id, count = part.split(":", 1)
        result[item_id.strip()] = result.get(item_id.strip(), 0) + int(count.strip())
    return result


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def validate_required_columns(errors: list[str]) -> None:
    for table_name, required in REQUIRED_COLUMNS.items():
        header = set(read_header(table_name))
        missing = sorted(required - header)
        if missing:
            fail(errors, f"{table_name}: missing required columns {', '.join(missing)}")


def main() -> int:
    errors: list[str] = []
    validate_required_columns(errors)
    items = read_tab("items.tab")
    research = read_tab("research.tab")
    recipes = read_tab("crafting_recipes.tab")
    categories = read_tab("resource_categories.tab")
    outlets = read_tab("resource_outlets.tab")
    quality_colors = read_tab("item_quality_colors.tab")
    drop_rows = read_tab("drop_tables.tab")
    container_bias = read_tab("container_resource_bias.tab")
    map_profiles = read_tab("map_resource_profiles.tab")
    room_profiles = read_tab("room_resource_profiles.tab")
    state_rules = read_tab("location_state_rules.tab")
    ss_chances = read_tab("ss_chance_tiers.tab")
    ss_container_chances = read_tab("ss_container_chances.tab")
    ss_pool = read_tab("ss_loot_pool.tab")

    item_by_id = {row["id"]: row for row in items}
    recipe_by_id = {row["recipe_id"]: row for row in recipes}
    category_ids = {row["category_id"] for row in categories}
    drop_contexts = {row["context"] for row in drop_rows}
    state_ids = {row["state_id"] for row in state_rules}

    for row in items:
        item_id = row["id"]
        if item_id.startswith("ss_"):
            fail(errors, f"{item_id}: item_id must not use legacy ss_ prefix")
        quality = row.get("quality", "")
        if quality not in VALID_QUALITIES:
            fail(errors, f"{item_id}: invalid quality {quality}")
        icon_name = basename(row.get("icon", "").lower())
        if icon_name.startswith("ss_"):
            fail(errors, f"{item_id}: icon path still points at legacy high-tier asset {row['icon']}")
        if row.get("item_type") == "material":
            category = row.get("material_category", "")
            if category not in category_ids:
                fail(errors, f"{item_id}: material_category {category!r} is not defined")
            if row.get("stackable") != "true" or int(row.get("stack_limit", "0")) <= 1:
                fail(errors, f"{item_id}: material must be stackable")
        if row.get("item_type") == "sale_good":
            if int(row.get("base_sale_value", "0")) <= 0:
                fail(errors, f"{item_id}: sale_good must have positive base_sale_value")

    for row in quality_colors:
        if row.get("quality") not in VALID_QUALITIES:
            fail(errors, f"item_quality_colors.tab defines invalid quality {row.get('quality')}")

    for row in research:
        if row.get("required_items", ""):
            fail(errors, f"{row.get('research_id')}: research required_items must be empty")
        if row.get("required_currency_id") != "mine_coin":
            fail(errors, f"{row.get('research_id')}: research must consume mine_coin")
        if int(row.get("required_currency_amount", "0")) <= 0:
            fail(errors, f"{row.get('research_id')}: research mine_coin cost must be positive")

    for row in recipes:
        output = row.get("output_item_id", "")
        if output not in item_by_id:
            fail(errors, f"{row.get('recipe_id')}: missing output item {output}")
        for item_id in parse_requirements(row.get("required_items", "")).keys():
            if item_id not in item_by_id:
                fail(errors, f"{row.get('recipe_id')}: missing required item {item_id}")

    direct_recipe_ids = set()
    combo_sale_values: list[int] = []
    for row in recipes:
        requirements = parse_requirements(row.get("required_items", ""))
        output_item = item_by_id.get(row.get("output_item_id", ""), {})
        if output_item.get("item_type") != "sale_good":
            continue
        if len(requirements) == 1 and next(iter(requirements.values())) == 1:
            direct_recipe_ids.add(row["recipe_id"])
        if len(requirements) >= 2:
            combo_sale_values.append(int(output_item.get("base_sale_value", "0")))
    if not direct_recipe_ids:
        fail(errors, "No single carried-out item -> basic sale_good recipe found")
    if not combo_sale_values or max(combo_sale_values) <= 40:
        fail(errors, "No higher-value multi-material sale_good recipe found")

    material_ids = {row["id"] for row in items if row.get("item_type") == "material"}
    outlets_by_material: dict[str, list[dict[str, str]]] = {}
    for row in outlets:
        item_id = row.get("item_id", "")
        if item_id in material_ids:
            outlets_by_material.setdefault(item_id, []).append(row)
    outlet_material_ids = set(outlets_by_material)
    for item_id in sorted(material_ids - outlet_material_ids):
        fail(errors, f"{item_id}: material has no resource_outlets row")
    for item_id, material_outlets in outlets_by_material.items():
        has_basic_sale = any(row.get("outlet_type") == "basic_sale" for row in material_outlets)
        has_explicit_non_basic = any(row.get("outlet_type") in {"craft", "order", "non_basic_sale"} for row in material_outlets)
        if not has_basic_sale and not has_explicit_non_basic:
            fail(errors, f"{item_id}: material needs basic_sale outlet or explicit non-basic-sale outlet")
    for row in outlets:
        if row.get("category_id") not in category_ids:
            fail(errors, f"{row.get('item_id')}: outlet category is not defined")
        target = row.get("target_id", "")
        if row.get("outlet_type") == "basic_sale" and target not in recipe_by_id:
            fail(errors, f"{row.get('item_id')}: basic_sale target is not a recipe: {target}")

    for row in categories:
        if row.get("quality_strategy") != "C/B/A/S":
            fail(errors, f"{row.get('category_id')}: category must declare C/B/A/S quality strategy")

    for row in container_bias:
        if row.get("context") not in drop_contexts:
            fail(errors, f"{row.get('context')}: container_resource_bias context has no drop table")
        if row.get("category_id") not in category_ids:
            fail(errors, f"{row.get('context')}: container bias category is not defined")

    for row in map_profiles:
        if row.get("default_state") not in state_ids:
            fail(errors, f"{row.get('map_id')}: map default_state is not defined")
        for category in split_list(row.get("primary_categories", "")) + split_list(row.get("secondary_categories", "")):
            if category not in category_ids:
                fail(errors, f"{row.get('map_id')}: map category is not defined: {category}")

    for row in room_profiles:
        for category in split_list(row.get("category_bias", "")):
            if category not in category_ids:
                fail(errors, f"{row.get('room_profile_id')}: room category is not defined: {category}")

    for row in ss_chances:
        if row.get("enabled") == "true" or float(row.get("hit_chance", "0")) > 0.0:
            fail(errors, "legacy high-tier chance rows must stay disabled and zero")
    for row in ss_container_chances:
        if row.get("enabled") == "true" or float(row.get("roll_chance", "0")) > 0.0:
            fail(errors, "legacy high-tier container rows must stay disabled and zero")
    for row in ss_pool:
        if any(value for value in row.values()):
            fail(errors, "legacy high-tier loot pool must stay empty, not just disabled")

    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        return 1

    print("Resource loop data validation passed.")
    print(f"Items: {len(items)}; materials: {len(material_ids)}; recipes: {len(recipes)}; maps: {len(map_profiles)}")
    print(f"Direct sale-good recipes: {len(direct_recipe_ids)}; resource categories: {len(category_ids)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

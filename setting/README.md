# Setting Tables

This directory stores project configuration tables in UTF-8 `.tab` TSV format.

Rules:
- The first non-comment row is the header.
- Columns are separated by a tab character.
- Empty lines and rows beginning with `#` may be skipped by loaders.
- IDs use lowercase English letters, numbers, and underscores.
- List fields use `;`.
- Key/value parameter fields use `key:value`.

Current item/container/resource tables:
- `items.tab`: base item definitions used by inventory, containers, storage, settlement, and UI.
- `repairmaterial.tab`: six run-only outpost repair material definitions used by material spawn points and outpost repair.
- `item_quality_colors.tab`: item quality display order and text colors.
- `container_types.tab`: container type, size, interaction, unified blue visual style, and loot context.
- `drop_tables.tab`: initial item candidates by container context, item quality, and quantity range.
- `resource_categories.tab`: player-facing resource categories and C/B/A/S expansion strategy.
- `resource_outlets.tab`: minimum outlets for carried-out resources.
- `map_resource_profiles.tab`, `room_resource_profiles.tab`, `location_state_rules.tab`, and `container_resource_bias.tab`: map, room, state, and container resource ecology data.
- `dialogue_speakers.tab`: story dialogue speaker display data, portrait paths, default side, and nameplate colors.

Item rule:
- Only C/B/A/S item qualities are valid. Do not add a separate high-tier quality.
- `material` and `sale_good` rows may be stackable. Equipment, most consumables, and rare/route items stay instance-only unless a later rule says otherwise.
- `sellable`, `sell_currency_id`, and `sell_value` drive actual direct merchant selling, merchant buy prices, and day-shop unit prices before demand multipliers. `sale_good.base_sale_value` is the table-side baseline for economy review and should mirror the current unmodified sale-good list price unless a later balancing rule intentionally separates baseline value from transaction value.
- Permanent research rows in `research.tab` must leave `required_items` empty and consume only `mine_coin`.
- `items.tab` is only for carried-out warehouse items. Run-only outpost repair materials live in `repairmaterial.tab` and must not be referenced by container drops, shops, or research costs.
- Repair materials have no item quality. At run start, each selected outpost randomly requires two different `repairmaterial.tab` materials, one of each.

Container rule:
- Containers do not have S/A/B/C grades.
- Containers use a unified blue interaction/readability color.
- Item quality alone owns S/A/B/C display and rarity colors.

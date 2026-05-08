# Setting Tables

This directory stores project configuration tables in UTF-8 `.tab` TSV format.

Rules:
- The first non-comment row is the header.
- Columns are separated by a tab character.
- Empty lines and rows beginning with `#` may be skipped by loaders.
- IDs use lowercase English letters, numbers, and underscores.
- List fields use `;`.
- Key/value parameter fields use `key:value`.

Current V0.1 item/container tables:
- `items.tab`: base item definitions used by inventory, containers, storage, settlement, and UI.
- `item_quality_colors.tab`: item quality display order and text colors.
- `container_types.tab`: container type, size, interaction, unified blue visual style, and loot context.
- `drop_tables.tab`: initial item candidates by container context, item quality, and quantity range.

Container rule:
- Containers do not have S/A/B/C grades.
- Containers use a unified blue interaction/readability color.
- Item quality alone owns S/A/B/C display and rarity colors.

# Map Art Source Sheets

These source sheets follow `Doc/17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md`.

Style target:
- Dark hand-drawn manga line art.
- Dirty grayscale wasteland city assets.
- Sparse purple, blue, muted red, and warm yellow accents only.
- Top-down or slightly top-down modular Godot 2D map assembly.

## Folder Layout

| Folder | File | Purpose |
|---|---|---|
| `_concept/` | `scene_wasteland_city_modular_preview_01.png` | Overall modular city scene preview and art-direction target. |
| `roads/sheets/` | `road_ground_tiles_sheet_01.png` | Road, intersection, sidewalk, curb, gutter, manhole, puddle, and pavement modules. |
| `buildings/sheets/` | `building_modular_sheet_01.png` | Small shops, apartments, alley buildings, rooftop structures, shed, door, and stair modules. |
| `props/sheets/` | `street_props_sheet_01.png` | Streetlamps, planters, trash bins, fences, barricades, signboards, benches, poles, stairs, cones, and guardrail props. |
| `details/sheets/` | `rooftop_wall_details_sheet_01.png` | Rooftop equipment, pipes, vents, AC units, wall panels, windows, awning, tarp, and blank lightbox modules. |
| `interactables/sheets/` | `containers_interactables_sheet_01.png` | Loot containers, open/closed crates, backpack container, supply boxes, extraction beacon, barriers, barrels, and scrap props. |
| `decals/sheets/` | `ground_decals_debris_sheet_01.png` | Cracks, rubble, stains, puddles, graffiti decals, sparks, rust, weeds, cables, and small ground overlays. |

## Cutting Notes

- Treat these files as source sheets, not final sliced runtime assets.
- Slice each visible object into a separate PNG before production use.
- Remove the flat chroma-key background and export transparent PNGs.
- Keep final sliced names lowercase with underscores, matching the document 17 naming convention.
- Suggested final paths include:
  - `res://assets/map/roads/road_straight_01.png`
  - `res://assets/map/buildings/building_small_shop_01.png`
  - `res://assets/map/props/streetlamp_warm_01.png`
  - `res://assets/map/interactables/container_safe_closed.png`
  - `res://assets/map/decals/crack_concrete_01.png`

## Source

Copied from the generated image batch:
`C:\Users\KSG\.codex\generated_images\019dd89a-25a0-75d1-b65e-60b52f3992ab`

The original generated files were left in place.

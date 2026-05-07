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
| `terrain/sheets/` | `terrain_ground_base_tiles_sheet_01.png` | Whole-map base land parcel / wasteland city ground sheet; use under all streets, blocks, buildings, and decals. |
| `roads/sheets/` | `road_ground_tiles_sheet_01.png` | Road, intersection, sidewalk, curb, gutter, manhole, puddle, and pavement modules. |
| `blocks/sheets/` | `block_district_tiles_sheet_01.png` | District block foundation tiles: non-walkable city block fill, edges, corners, cuts, and decals. |
| `buildings/sheets/` | `building_modular_sheet_01.png` | Concept mixed building sheet; keep as visual reference, not the preferred slicing source. |
| `buildings/sheets/` | `building_small_corner_shop_assembly_01.png` | Recommended production assembly sheet for an 8x6-ish small corner shop road-boundary building. |
| `buildings/sheets/` | `building_small_residential_block_assembly_01.png` | Recommended production assembly sheet for a small residential block. |
| `buildings/sheets/` | `building_medium_apartment_rooftop_assembly_01.png` | Recommended production assembly sheet for a 12x12-ish apartment landmark with rooftop utilities. |
| `buildings/sheets/` | `building_medium_shop_blank_neon_assembly_01.png` | Recommended production assembly sheet for a medium shop with blank lightbox/sign pieces. |
| `buildings/sheets/` | `building_narrow_alley_assembly_01.png` | Recommended production assembly sheet for a narrow alley-forming building. |
| `buildings/sheets/` | `building_large_ruined_market_assembly_01.png` | Recommended production assembly sheet for a large ruined market obstacle/landmark. |
| `safe/sheets/` | `safe_house_active_sheet_01.png` | Player home / safe house concept sheet with visible interior, warm lights, living objects, and collision-footprint guide. |
| `safe/sheets/` | `safe_house_active_sheet_02.png` | Recommended production assembly sheet: assembled home plus matching floor, walls, doorway, furniture, device, and safe-area pieces. |
| `outposts/sheets/` | `outpost_broken_repaired_sheet_01.png` | Broken and repaired outpost concept state sheet with near-matching footprint for `repair_state` sprite switching. |
| `outposts/sheets/` | `outpost_broken_repaired_sheet_02.png` | Recommended production assembly sheet: matching broken/repaired references plus paired construction pieces for state switching. |
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
  - `res://assets/map/blocks/fill/block_fill_clean_01.png`
  - `res://assets/map/blocks/edge/block_edge_straight_01.png`
  - `res://assets/map/blocks/edge/block_corner_outer_01.png`
  - `res://assets/map/roads/road_straight_01.png`
  - `res://assets/map/buildings/building_small_shop_01.png`
  - `res://assets/map/safe/safe_house_active_01.png`
  - `res://assets/map/outposts/outpost_broken_01.png`
  - `res://assets/map/outposts/outpost_repaired_01.png`
  - `res://assets/map/props/streetlamp_warm_01.png`
  - `res://assets/map/interactables/container_safe_closed.png`
  - `res://assets/map/decals/crack_concrete_01.png`

## Safe Building Notes

- `safe_house_active_sheet_02.png` is the recommended slicing source for the home because its separated pieces are intended to reconstruct the assembled reference on the same sheet.
- `outpost_broken_repaired_sheet_02.png` is the recommended slicing source for outposts because its broken/repaired pieces are paired around the same footprint and state-switching silhouette.
- `safe_house_active_sheet_01.png` and `outpost_broken_repaired_sheet_01.png` are retained as concept sheets.
- Broken outposts should stay grey, damaged, and inactive.
- Repaired outposts should be clearly activated, but more temporary and tool-focused than the player's home.
- In Godot, use the home as a special `SafeHouseScene`; use the outpost sheet with `repair_state` switching between broken and repaired sprites.

### Safe House Split Output

`safe_house_active_sheet_02.png` has been split into transparent PNGs:

| Folder | Purpose |
|---|---|
| `safe/safe_house_active_01.png` | Runtime-ready full assembled safe house at the document 17 recommended path. |
| `safe/assembled/` | Full assembled safe house reference copy. |
| `safe/parts/` | Structural parts: floor, walls, doorway, windows, corner caps, parapet segments, wall patch. |
| `safe/props/` | Interior props and gameplay markers: bed, desk, shelves, cabinet, lamps, devices, plant, rug, safe-area ring. |
| `safe/concept_parts/` | Older `safe_house_active_sheet_01.png` split for archival reuse; prefer `_02` outputs for production. |
| `safe/guides/` | Collision guide and split-preview sheet for review. |

The split manifest is `safe/safe_house_active_02_manifest.json`.

## Runtime Split Output

The remaining sheets under `assets/map` have also been split into transparent PNGs. Source sheets stay in `*/sheets/`; generated manifests and previews stay beside their category as audit artifacts.

| Category | Runtime folders | Standard notes |
|---|---|---|
| Blocks | `blocks/fill/`, `blocks/edge/`, `blocks/cut/`, `blocks/overlay/` | Follow `13_街道区块基底与区块资源规格.md`: city block foundations are non-walkable; buildings sit on top of blocks; street width is defined by block edges, not irregular building silhouettes. |
| Roads | `roads/tiles/`, `roads/details/`, root aliases `road_straight_01.png`, `road_cross_01.png`, `road_t_junction_01.png`, `road_corner_01.png` | Follow `02_道路拓扑与通行碰撞.md`: main roads 5-7 units, secondary roads 3-4, alleys 2-3, transitions >=3, plazas >=8x8. |
| Buildings | `buildings/assembled/`, `buildings/parts/`, root aliases for each `building_*_01.png` | Follow `03_建筑障碍与视觉遮挡.md`: ordinary buildings sit on non-walkable blocks as visual landmarks and optional local obstacles; do not use irregular building silhouettes to define street collision. |
| Props | `props/placement/` | Street props for placement; add collision only for props that block movement. |
| Rooftop/Wall Details | `details/rooftop/`, `details/walls/` | Decorative or modular facade/roof equipment; attach to buildings as needed. |
| Interactables | `interactables/containers/`, `interactables/loot/`, `interactables/props/`, `interactables/barriers/` | Container state naming preserves closed/open or role where available. |
| Outposts | `outposts/assembled/`, `outposts/parts/`, root aliases `outpost_broken_01.png`, `outpost_repaired_01.png` | Use root aliases for `repair_state` switching; parts are for reconstruction/variants. |
| Decals | `decals/overlays/` | Visual overlays only; do not define collision from decals. |

Each split run writes:
- `*_manifest.json` with source sheet, crop boxes, and metadata.
- `guides/*_split_preview.png` for visual review.

## Scene Road Ground Base Refresh

The 2026-05-07 street refresh follows `Doc/17` and `Doc/22`: the map now uses a whole-map `TerrainGroundBase` underlay first. Streets are expressed above it with road decals/overlays and readable block edges; they should not require building the entire map from separate road segment sprites.

| Folder | Purpose |
|---|---|
| `terrain/sheets/terrain_ground_base_tiles_sheet_01.png` | Source sheet for whole-map base land/ground tiles. |
| `terrain/ground/` | Runtime-ready 1024x1024 base terrain tiles plus preview images. Use as the lowest visual ground layer. |
| `roads/sheets/road_ground_base_tiles_sheet_01.png` | Source sheet for whole-scene road-ground texture tiles. |
| `roads/ground/` | Runtime-ready 1024x1024 road-surface texture tiles. Keep these as road-surface variants or references; do not treat them as the whole-map underlay. |
| `roads/sheets/road_decor_overlays_sheet_01.png` | Source sheet for road decoration decals. |
| `roads/overlays/` | Transparent overlay decals for lane remnants, cracks, stains, drains, rubble, skid marks, and edge dirt. |
| `blocks/sheets/block_district_tiles_sheet_02.png` | Refreshed block foundation and curb source sheet for the new road scale. |
| `blocks/fill/`, `blocks/edge/`, `blocks/cut/`, `blocks/overlay/` | Additional block foundation, curb, entrance gap, ramp, and rubble/decal pieces. |
| `roads/base/` | Transitional/manual road-piece outputs from the earlier pass; use only for special-case placement, not as the main map ground. |

Use `terrain/ground/terrain_ground_base_tile_1024_01.png` through `_06.png` as the visual underlay under `WorldRoot/MapVisual/TerrainGroundBase`. Avoid building the new map from the older `road_straight/road_corner/road_t_junction/road_cross` pieces except as special-case intersection references. Decorations in `roads/overlays/` are visual-only and should not define navigation or collision.

`RunScene.tscn` now keeps `RoadVisualGenerator.visual_mode = "street_decor"` so it places transparent street decals over the whole-map terrain instead of covering street rectangles with `roads/ground` tiles.

New manifests:
- `terrain/terrain_ground_base_tiles_sheet_01_manifest.json`
- `roads/road_ground_base_tiles_sheet_01_manifest.json`
- `roads/road_ground_base_large_sheet_01_manifest.json`
- `roads/road_decor_overlays_sheet_01_manifest.json`
- `blocks/block_district_tiles_sheet_02_manifest.json`

Runtime catalog:
- `roads/road_runtime_asset_catalog.json` lists the refreshed road/block runtime assets with size, semantic role, collision policy, and recommended Godot visual node.
- `roads/guides/road_runtime_asset_contact_sheet_01.png` is a quick visual audit sheet for the refreshed runtime outputs.

## Building Assembly Notes

## Editor Placement Notes

- Streets and blocks must be editable by designers in Godot, preferably through TileMap/TileSet terrain.
- `blocks/fill` tiles should repeat cleanly for large non-walkable city blocks.
- `blocks/edge` and `blocks/cut` tiles are for manually shaping readable curbs, corners, alleys, and driveways.
- Buildings are placed on top of blocks as visual landmarks; they should not define the main street collision.
- After changing street/block layout, run map validation before decorating.

- Prefer the `*_assembly_01.png` building sheets for slicing because each sheet includes an assembled reference plus matching construction pieces.
- `building_small_corner_shop_assembly_01.png` and `building_small_residential_block_assembly_01.png` cover small 8x6 to 10x8 road-boundary buildings.
- `building_medium_apartment_rooftop_assembly_01.png` and `building_medium_shop_blank_neon_assembly_01.png` cover main street-block anchors and visual landmarks.
- `building_narrow_alley_assembly_01.png` is for compressing route width and forming tight alley boundaries. Avoid placing it so close to another collider that it creates gaps under 2 map units.
- `building_large_ruined_market_assembly_01.png` is for large obstacle masses and landmarks. Check that broken edges do not obscure critical points or produce unreadable collision.
- Ordinary building assets should be placed on block foundations. The block layer provides primary street collision; building scenes may add small local `CollisionShape2D` only when needed. Do not depend on transparent pixels for collision.

## Source

Copied from the generated image batch:
`C:\Users\KSG\.codex\generated_images\019dd89a-25a0-75d1-b65e-60b52f3992ab`

The original generated files were left in place.

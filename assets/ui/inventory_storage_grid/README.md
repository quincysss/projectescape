# Inventory Storage Grid UI

Scope: opened backpack, home storage, repaired outpost temporary storage, and out-of-run warehouse.

This folder records the shared grid-language mockups for inventory and storage screens. The current direction follows the user's 2026-05-10 reference: a dark translucent panel, thin cyan grid frames, sparse text, and a small yellow selected state. It intentionally moves these screens away from the previous heavy paper/metal inventory layout.

## Mockups

- `mockups/ui_run_backpack_open_grid_mockup_01.png`
  - Clean in-run opened backpack mockup over the current HUD reference.
  - Use this for composition, panel placement, and map obstruction review.
- `mockups/ui_run_backpack_open_grid_mockup_02.png`
  - Revised in-run backpack mockup.
  - Current approved direction: no baked item icons, title + capacity in one row, connected category tabs, square reusable slots.
- `mockups/ui_inventory_storage_grid_variants_mockup_01.png`
  - Shared design board for in-run backpack, home storage, outpost storage, and warehouse variants.
  - Use this for rules and layout comparison, not as a runtime screen.

## Shared Visual Rules

- Panel background: nearly black translucent fill. The playfield or base scene may remain faintly visible behind it.
- Main backpack outline: cyan / blue-green `#35C9D7`.
- Header row: title on the left, capacity on the right using `容量：xx/xx`. Do not add English subtitles under the title.
- Category tabs: use one connected segmented tab strip with vertical dividers. Do not draw each tab as a separated floating box.
- Default slot border: cyan / blue-green, square reusable frame.
- Selected slot: yellow outer border plus a small purple corner accent.
- Locked / unavailable slot: dark grey border, clipped diagonal hatch inside the slot only.
- Invalid drop / blocked transfer: muted red border.
- Item icon, stack count, item name, capacity, weight, price, and storage title are drawn by UI code.
- Runtime assets should not bake localized text into sliced PNGs.

## Layout Rules At 1920x1080

- In-run opened backpack:
  - Prefer a right-side vertical panel so the character and map center stay readable.
  - Suggested panel width: `500px`.
  - Suggested slot size: `78px`.
  - Suggested slot gap: `12px`.
  - Suggested grid: `5 columns x data-driven rows`.
  - Slot placement formula: `slot_x = grid_left + column * (78 + 12)`, `slot_y = grid_top + row * (78 + 12)`.
  - Current title line: `背包` at `29px`, capacity text at `18px`.
  - Current tab strip: `5 tabs`, each `76x36px`, connected into one top navigation control.
  - Current bottom area: `负重`, numeric load value, load progress bar, and selected item name.
- Home storage and outpost storage:
  - Use a two-pane layout: player backpack on the left, storage on the right.
  - A transfer arrow/button may sit between panes.
  - Both panes use the same slot component and state colors.
- Outpost storage:
  - Use the same grid, but add a grey-green frame accent to show temporary safe status.
  - Do not make it look like a permanent warehouse.
- Out-of-run warehouse:
  - Use a larger grid and optional right-side item detail panel.
  - Warehouse capacity is shown as capacity, not load. It must not use the in-run weight wording.

## Color Reference

```json
{
  "panel_bg": "#04070D",
  "panel_inner_bg": "#0B151A",
  "slot_bg": "#071116",
  "slot_border_default": "#35C9D7",
  "slot_border_inner": "#163D43",
  "slot_border_selected": "#D1B850",
  "slot_selected_corner": "#7868D8",
  "slot_border_locked": "#4D575B",
  "slot_hatch_locked": "#2E3437",
  "slot_border_invalid": "#B55356",
  "outpost_accent": "#5D8B6F",
  "warehouse_accent": "#C49B3A",
  "weight_fill": "#8A72DE",
  "text_primary": "#E5E2D9",
  "text_secondary": "#8DB6B9",
  "count_text": "#B9A9FF",
  "quality_text_S": "#D1B850",
  "quality_text_A": "#B9A9FF",
  "quality_text_B": "#6FA8DC",
  "quality_text_C": "#D8D6CE"
}
```

## Item Icon Display Rules

The current backpack mockup intentionally does not show item icons. Runtime icon drawing should follow these rules:

- Source icon asset: `128x128px` transparent PNG.
- Runtime display inside a `78x78px` slot: centered, maximum `54x54px`.
- Minimum clear padding from slot frame: `12px`.
- Long or vertical icons may use maximum height `58px` if width remains inside `54px`.
- Stack count remains bottom-right aligned and must not overlap the icon silhouette.
- Item name in the bottom selected-item row uses `ItemDefinition.quality` color:
  - `S`: `#D1B850`
  - `A`: `#B9A9FF`
  - `B`: `#6FA8DC`
  - `C`: `#D8D6CE`

## Slot States

- Non-selected: `78x78px`, dark fill, `#35C9D7` square outline, no icon baked into the state asset.
- Selected: same square size, `#D1B850` outline plus `#7868D8` top-left corner marker.
- Disabled / locked: same square size, dark grey outline, clipped diagonal hatch, optional muted blocked marker.

## Font Rules

- Chinese UI text: `Noto Sans SC` or `Microsoft YaHei` during prototype.
- English UI text: `Inter` or `Noto Sans`.
- Numbers: `JetBrains Mono`, `IBM Plex Mono`, or `Consolas` during prototype.
- Suggested title size at 1080p: `24-30px`.
- Suggested body size at 1080p: `16-18px`.
- Suggested stack count size at 1080p: `18-20px`, bottom-right aligned inside slot.

## Slicing Plan For The Next Sheet

When this design is approved, split the runtime sheet into:

- `ui_inventory_grid_panel_frame_9slice_01.png`
- `ui_inventory_grid_slot_empty_01.png`
- `ui_inventory_grid_slot_selected_01.png`
- `ui_inventory_grid_slot_locked_01.png`
- `ui_inventory_grid_slot_invalid_01.png`
- `ui_inventory_grid_filter_chip_empty_01.png`
- `ui_inventory_grid_filter_chip_selected_01.png`
- `ui_inventory_grid_filter_tab_strip_5_01.png`
- `ui_inventory_grid_capacity_bar_frame_01.png`
- `ui_inventory_grid_capacity_bar_fill_purple_01.png`
- `ui_inventory_grid_transfer_arrow_frame_01.png`

Panel frames should be prepared as nine-slice assets. Slots can be single sprites at the approved base size, with UI code scaling only through fixed layout constants.

# Run Backpack HUD UI

This folder contains right-bottom in-run backpack HUD assets based on
`assets/ui/_mockups/ig_0785fddc4c6e9089016a00430051548190ba1fea0d35bf2000.png`.

Frames, count digits, and load bar pieces are strict reference extractions. The backpack icon is normalized from the reference backpack crop into a 128x128 transparent UI icon.

## Files

Component PNGs:

- `components/ui_run_consumable_slot_frame_empty_01.png`
- `components/ui_run_consumable_count_digit_1_purple_01.png`
- `components/ui_run_consumable_count_digit_2_purple_01.png`
- `components/ui_run_backpack_panel_frame_empty_01.png`
- `components/ui_run_backpack_icon_01.png`
- `components/ui_run_backpack_occupied_count_frame_empty_01.png`
- `components/ui_run_backpack_capacity_count_frame_empty_01.png`
- `components/ui_run_load_bar_frame_empty_01.png`
- `components/ui_run_load_bar_fill_overlay_current_01.png`
- `components/ui_run_load_bar_fill_strip_purple_01.png`

Sheet and metadata:

- `sheets/ui_run_backpack_hud_sheet_01.png`
- `sheets/ui_run_backpack_hud_sheet_01_manifest.json`

Preview:

- `previews/ui_run_backpack_hud_extract_preview_01.png`

## Consumable Slots

Use `ui_run_consumable_slot_frame_empty_01.png` for each quick item slot.

Reference layout:

```text
slot_size: 122 x 135
slot_spacing_x: 124
count_anchor_x: 96
count_anchor_y: 104
```

The item icon is intentionally not included. Draw item icons below the slot frame and clip them inside the transparent well.

The count digits `1` and `2` are extracted as purple reference assets. For runtime-generated counts, match:

```text
font: JetBrains Mono
fallback: IBM Plex Mono / Roboto Mono
weight: Bold
size: 25px at source scale
color: #7D65C6
align: bottom-right
```

## Backpack Panel

Use `ui_run_backpack_panel_frame_empty_01.png` as the panel border and `ui_run_backpack_icon_01.png` as the backpack icon.

Backpack icon:

```text
size: 128 x 128
background: transparent
source: reference backpack crop
style: grey-black worn backpack, thick hand-drawn outline
```

Reference panel layout:

```text
panel_size: 455 x 125
icon_x: 8
icon_y: 8
occupied_count_frame_x: 188
occupied_count_frame_y: 22
slash_center_x: 291
slash_center_y: 45
capacity_count_frame_x: 300
capacity_count_frame_y: 22
load_bar_x: 134
load_bar_y: 80
```

## Backpack Count Text

Use these frames:

- occupied count: `ui_run_backpack_occupied_count_frame_empty_01.png`
- total capacity: `ui_run_backpack_capacity_count_frame_empty_01.png`

The number text and slash are rendered by code.

Recommended number style:

```text
font: JetBrains Mono
fallback: IBM Plex Mono / Roboto Mono
weight: Bold
size: 27px at source scale
color: #D7D0C3
shadow: #151311
align: center
```

Recommended slash style:

```text
font: JetBrains Mono
weight: Bold
size: 28px at source scale
color: #D7D0C3
shadow: #151311
align: center
```

Frame and slash spacing:

```text
count_frame_size: 82 x 56
number_text_rect: x 15, y 12, w 52, h 31
slash_width: 28
slash_gap_left: 10
slash_gap_right: 10
```

## Load Bar

Use:

- frame: `ui_run_load_bar_frame_empty_01.png`
- current purple fill: `ui_run_load_bar_fill_overlay_current_01.png`
- fill strip: `ui_run_load_bar_fill_strip_purple_01.png`

Draw order:

1. Draw `ui_run_load_bar_frame_empty_01.png`.
2. Draw the purple fill clipped by `current_weight / max_weight`.
3. Draw runtime load text centered over the bar if needed.

Recommended load value text:

```text
font: JetBrains Mono
fallback: IBM Plex Mono / Roboto Mono
weight: Bold
size: 14px at source scale
color: #D7D0C3
shadow: #151311
align: center
text_rect: x 134, y 80, w 280, h 24 inside the panel
```

Color references are also stored in the JSON manifest.

## Import Notes

All PNG files are transparent-background `Format32bppArgb` assets. Avoid compression that blurs the rough paper edge and purple inner border.

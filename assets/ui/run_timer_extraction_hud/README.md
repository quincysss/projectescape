# Run Timer And Extraction HUD UI

This folder contains the in-run top-center HUD assets redrawn to match
`assets/ui/_mockups/ig_0785fddc4c6e9089016a00430051548190ba1fea0d35bf2000.png`.
They are not direct crops from the reference; the existing runtime file names and sizes are preserved.

Current scope:

- countdown timer frame
- extraction availability status frame
- extraction status dot fills

Text is intentionally not baked into the PNGs. Render countdown and status text in code so localization can change the copy without replacing art.

## Files

Component PNGs:

- `components/ui_run_timer_countdown_frame_empty_01.png`
- `components/ui_run_extraction_status_frame_full_empty_01.png`
- `components/ui_run_extraction_status_frame_left_01.png`
- `components/ui_run_extraction_status_frame_center_tile_01.png`
- `components/ui_run_extraction_status_frame_right_01.png`
- `components/ui_run_extraction_status_dot_unavailable_01.png`
- `components/ui_run_extraction_status_dot_available_01.png`

Sheet and metadata:

- `sheets/ui_run_timer_extraction_hud_sheet_01.png`
- `sheets/ui_run_timer_extraction_hud_sheet_01_manifest.json`

Preview:

- `previews/ui_run_timer_extraction_hud_extract_preview_01.png`

## Countdown Timer

Use `ui_run_timer_countdown_frame_empty_01.png` as the countdown frame.

Recommended text:

- font: `JetBrains Mono`
- fallback: `IBM Plex Mono`, `Roboto Mono`
- weight: Bold
- alignment: center
- reference size: `54px` at source asset scale

Text colors are recorded in the JSON manifest:

- default grey-white: `#D7D0C3`
- default shadow: `#1A1714`
- urgent black-red fill: `#2A0709`
- urgent red stroke: `#8F3038`
- urgent shadow: `#080304`

For the black-red countdown state, use the red stroke or outline. The dark red fill alone is too close to the timer panel and should not be rendered without an outline.

Suggested text rect for the source frame:

```text
x: 61
y: 18
w: 194
h: 50
```

## Extraction Status

Use code-rendered localized text. Do not bake Chinese, English, or Japanese copy into the image asset.

Status dot assets:

- unavailable: `ui_run_extraction_status_dot_unavailable_01.png` dark grey fill
- available: `ui_run_extraction_status_dot_available_01.png`

Dot placement in the default reference frame:

```text
dot_draw_x: 17
dot_draw_y: 10
dot_center_x: 31
dot_center_y: 24
```

Recommended status text:

- Chinese: `Noto Sans SC`
- English: `Inter`
- Japanese: `Noto Sans JP`
- weight: Medium
- reference size: `18px`
- text start x: `64`
- baseline hint y: `31`

## Variable Width Frame

The extraction status frame must support localization. Use the three sliced assets:

- left cap: `ui_run_extraction_status_frame_left_01.png`, width `76`
- center tile: `ui_run_extraction_status_frame_center_tile_01.png`, width `32`
- right cap: `ui_run_extraction_status_frame_right_01.png`, width `24`

Composition rule:

```text
target_width = max(180, text_start_x + localized_text_width + 24)
center_width = target_width - left_width - right_width
```

Draw order:

1. Draw left cap at `x = 0`.
2. Repeat or stretch the center tile from `x = 76` to `target_width - 24`.
3. Draw right cap at `x = target_width - 24`.
4. Draw status dot at `x = 17, y = 10`.
5. Draw localized status text at `x = 64`.

The full empty frame is included only as a default-width convenience asset for the reference English layout. Prefer the three-slice composition for production UI.

## States

Unavailable:

```text
frame: extraction status frame slices
dot: unavailable dark grey dot
text key: extraction.unavailable
text color: grey-white
```

Available:

```text
frame: extraction status frame slices
dot: available black-green dot
text key: extraction.available
text color: grey-white
```

Countdown warning:

```text
frame: countdown frame
text color: black-red fill with red stroke
```

## Import Notes

All PNG files are transparent-background `Format32bppArgb` assets. Keep filtering off or use nearest/linear according to the final HUD scale, but avoid aggressive compression that blurs the hand-drawn border grit.

# Player Sprite Assets

## Layout

```text
player/
  male/
    base/
      player_male_idle_4dir_sheet_01.png
      player_male_idle_4dir_sheet_01_manifest.json
      directions/
        player_male_idle_down_01.png
        player_male_idle_up_01.png
        player_male_idle_left_01.png
        player_male_idle_right_01.png
    idle/
      down/
        player_male_idle_down_8f_sheet_01.png
        player_male_idle_down_8f_sheet_01_manifest.json
        frames/
          player_male_idle_down_8f_01_frame_01.png
          ...
    _work/
      base/
      idle/
        down/
```

## Rules

- Runtime-ready animation sheets live under `male/<animation>/<direction>/`.
- Optional split frames live under the animation direction's `frames/` folder.
- Base four-direction reference assets live under `male/base/`.
- Chroma-key sources, transparent source sheets, GIF previews, and other production intermediates live under `male/_work/`.
- Keep filenames lowercase English with underscores: `player_male_<animation>_<direction>_<frame-count>f_sheet_<index>.png`.
- Keep each character variant under its own folder, such as `male/` or a future `female/`.

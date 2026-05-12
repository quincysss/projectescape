# 音频资源目录

本目录只存放游戏音频资源。脚本读取 `res://data/audio/audio_manifest.json`，所以后续替换或补资源时，优先保持 manifest 中的路径不变。

## 命名规则

- BGM 使用 `snake_case_bgm.wav`。
- 循环音效使用 `snake_case_loop.wav`。
- 一次性短音效使用 `snake_case.wav`。
- UI 点击音效使用 `ui_snake_case.wav`。
- 结算/死亡等短提示使用 `cue_snake_case.wav`。
- 当前统一预期格式为 `.wav`。

## 当前预留资源

- `res://assets/audio/bgm/base_safe_house_bgm.wav`
- `res://assets/audio/bgm/run_safe_house_bgm.wav`
- `res://assets/audio/bgm/run_exploration_bgm.wav`
- `res://assets/audio/sfx/stability_critical_loop.wav`
- `res://assets/audio/sfx/container_open_loop.wav`
- `res://assets/audio/sfx/container_open_complete.wav`
- `res://assets/audio/sfx/outpost_repair_complete.wav`
- `res://assets/audio/sfx/cue_extraction_success.wav`
- `res://assets/audio/sfx/cue_player_death.wav`
- `res://assets/audio/sfx/ui_button_click.wav`
- `res://assets/audio/sfx/ui_item_click.wav`

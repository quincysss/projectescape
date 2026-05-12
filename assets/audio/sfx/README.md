# 音效占位路径

后续把资源放到这些固定路径即可：

| 用途 | 文件名 | 播放方式 |
|---|---|---|
| 濒临崩溃音效 | `stability_critical_loop.wav` | loop |
| 容器打开读条音效 | `container_open_loop.wav` | loop |
| 容器打开完成音效 | `container_open_complete.wav` | one shot |
| 前哨站修复完成音效 | `outpost_repair_complete.wav` | one shot |
| 撤离成功短 cue | `cue_extraction_success.wav` | one shot |
| 死亡短 cue | `cue_player_death.wav` | one shot |
| 通用按钮点击音效 | `ui_button_click.wav` | one shot |
| 道具格点击音效 | `ui_item_click.wav` | one shot |

## UI 点击音效命名规范

UI 点击音效统一放在：

```text
assets/audio/sfx/
```

Godot 资源路径统一为：

```text
res://assets/audio/sfx/<文件名>.wav
```

当前点击类资源：

```text
ui_button_click.wav   # 普通按钮、页签、确认/取消/售卖/购买/研发等通用点击
ui_item_click.wav     # 道具格、背包格、仓库格、商人库存格等道具选择点击
```

规则：
- 使用 `.wav`。
- 文件名全小写，单词之间使用 `_`。
- UI 类音效统一使用 `ui_` 前缀。
- 点击音效应为短 one shot，建议长度 50-180ms。
- 默认音量由 `data/audio/audio_manifest.json` 控制，不要通过提高素材响度硬顶。

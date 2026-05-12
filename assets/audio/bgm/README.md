# BGM 占位路径

后续把资源放到这些固定路径即可：

| 用途 | 文件名 |
|---|---|
| 局外安全屋 BGM | `base_safe_house_bgm.wav` |
| 局内安全屋 BGM | `run_safe_house_bgm.wav` |
| 局内探索时 BGM | `run_exploration_bgm.wav` |

三个 BGM 都按循环播放处理，循环由 `AudioManager` 根据 manifest 的 `loop` 字段兜底控制。

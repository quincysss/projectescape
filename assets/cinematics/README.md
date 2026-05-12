# 剧情视频资源路径

项目已接入 `addons/ffmpeg/ffmpeg.gdextension`，运行时视频优先使用 MP4。Godot 原生仍只稳定支持 Ogg Theora `.ogv`，所以 `.ogv` 可以作为兼容回退资源保留。

主流程开场视频放在：

```text
assets/cinematics/source/opening_intro_cinematic_720p.mp4
```

Godot 资源路径：

```text
res://assets/cinematics/source/opening_intro_cinematic_720p.mp4
```

当前开场剧情配置：

```text
data/cinematics/opening_intro_cinematic.json
```

配置中 `resource_path` 指向 MP4，`fallback_resource_path` 指向旧的 `.ogv`。如果 FFmpeg 扩展不可用，代码会尝试回退到 `.ogv` 或黑屏占位。

主菜单循环背景视频放在：

```text
assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4
```

Godot 资源路径：

```text
res://assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4
```

命名规则：
- 使用剧情或用途 ID 作为文件名前缀。
- 分辨率追加 `_720p`、`_1080p` 等后缀。
- 当前主流程开场剧情 ID 是 `opening_intro_cinematic`。
- 主菜单循环背景固定使用 `main_menu_background_loop_1080p.mp4`。
- 新增剧情视频沿用 `剧情ID_分辨率.mp4`，例如 `chapter_1_complete_720p.mp4`。

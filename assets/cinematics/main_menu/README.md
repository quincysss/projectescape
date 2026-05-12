# 主菜单背景视频

主菜单循环背景视频放在本目录：

```text
assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4
```

Godot 资源路径：

```text
res://assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4
```

播放规则：
- 作为主菜单全屏循环视频背景。
- 画面按 16:9 等比覆盖窗口，避免拉伸变形。
- 视频音量会被静音，避免和局外安全屋 BGM 冲突。
- MP4 播放依赖 `res://addons/ffmpeg/ffmpeg.gdextension`。

命名规则：
- `main_menu_background_loop` 表示主菜单循环背景。
- 1080P 资源追加 `_1080p`。
- 当前固定命名为 `main_menu_background_loop_1080p.mp4`。

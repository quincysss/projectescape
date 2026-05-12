# 开场剧情视频

这里存放主流程开场剧情视频。当前运行时直接引用 MP4：

```text
opening_intro_cinematic_720p.mp4
```

Godot 资源路径：

```text
res://assets/cinematics/source/opening_intro_cinematic_720p.mp4
```

注意：
- MP4 播放依赖 `res://addons/ffmpeg/ffmpeg.gdextension`。
- 旧 `.ogv` 文件保留在上一级目录，作为扩展不可用时的回退。
- 不要把 `.mp4` 直接改后缀成 `.ogv`；两者是不同的视频封装/编码。

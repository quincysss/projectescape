# 黑潮界质表现资产

黑潮界质是漂浮型黑潮怪物表现资产，当前包用于首版游戏内展示和后续敌人逻辑接入。

## 文件

- `black_tide_boundary_essence_cutout_01.png`：从确认过的原画中提取的透明底主图。
- `idle/frames/black_tide_boundary_essence_idle_8f_01_frame_01.png` 至 `08.png`：512x384 透明底 idle 漂浮帧。
- `sheets/black_tide_boundary_essence_idle_8f_01_sheet.png`：8 帧横向序列图。
- `previews/black_tide_boundary_essence_preview_01.png`：深灰底预览图。
- `black_tide_boundary_essence_manifest.json`：资源路径和帧规格。
- `res://scenes/entities/monsters/BlackTideBoundaryEssence.tscn`：可直接实例化的 Godot 表现场景。

## 表现规格

- 动画：`idle`
- 帧率：8 fps
- 帧尺寸：512x384
- 场景根节点：`CharacterBody2D`
- 视觉节点：`BodySprite`
- 预留定位点：`EyeFocus`

## 美术方向

主体应保持一团凝聚黑色气体的轮廓，眼球是最高识别点。拖尾保留半透明黑潮烟雾，不建议在游戏内添加厚重实体阴影，否则会削弱烟雾感。

# 17_美术资源规格与GPT生图提示词规范.md

# 《废土生存法则》美术资源规格与 GPT 生图提示词规范（修订版）

> 文档版本：v0.2  
> 所属项目：《废土生存法则》  
> 前置文档：01_项目总纲.md / 03_地图与安全区规则.md / 13_数据配置表与TAB规范.md  
> 适用阶段：美术资产生成、场景拆件、资源替换  
> 本次修订重点：根据新参考图调整整体美术风格；将场景生产方式改为通过 GPT-image-2.0 生成可拆件资产，包括街道、区块地基、不同规格楼房、路灯、花坛、围栏、装饰物等，便于 Godot 拼装。地图地基采用“街道可通行 + 区块不可通行 + 楼房放在区块上”。

---

## 1. 本文档一句话说明

美术风格应是“灰黑手绘漫画线稿 + 脏旧废土城市 + 少量霓虹点缀 + 俯视可拼装场景拆件”。

---

## 2. 核心美术方向

关键词：

```text
俯视角或轻微斜俯视。
灰黑主色。
高密度手绘线稿。
粗黑轮廓。
脏旧纹理。
废弃城市街区。
漫画分镜质感。
局部霓虹点缀。
紫色、蓝色、红色小面积高亮。
灯光小面积暖黄。
潮湿、破败、压抑。
```

角色关键词：

```text
瘦弱少年或少女。
凌乱长发或遮眼短发。
灰黑脏旧 T 恤。
短裤或破旧工装裤。
厚重旧运动鞋。
旧背包。
身上有少量紫色或蓝色电子模块。
孤独、麻木、废土幸存者气质。
```

场景关键词：

```text
密集城市街区。
水泥路面。
老旧楼房。
街区区块。
水泥区块地砖。
屋顶管线。
空调外机。
楼梯。
围栏。
路灯。
花坛。
涂鸦。
垃圾桶。
铁皮棚。
破旧招牌。
少量霓虹灯箱。
```

---

## 3. 风格边界

需要避免：

```text
明亮可爱卡通。
纯像素风。
写实照片。
干净科幻。
高饱和赛博朋克。
军事硬核写实。
厚涂油画。
Q版大头身。
过度血腥恐怖。
复杂不可切分的大背景。
```

允许：

```text
少量紫色霓虹。
少量蓝色电子灯。
少量红色涂鸦或警示标记。
暖黄色路灯。
粗糙纸面纹理。
线稿不完全规整。
```

核心判断：

```text
整体必须是灰黑脏旧。
彩色只能作为小面积信息点。
场景必须能服务俯视玩法和碰撞边界。
```

---

## 3.1 特殊安全建筑风格

“家”和“修复后的前哨站”是特殊建筑，不完全遵守普通街区建筑的灰黑压抑风格。

它们的视觉目标：

```text
一眼看出这是安全地点。
一眼看出这里和普通建筑不同。
能看到内部结构。
有灯光。
更干净。
更有生活痕迹。
有高饱和色彩点缀。
```

主色调：

```text
白色。
浅灰。
暖灰。
少量木色。
少量暖黄灯光。
少量高饱和点缀色。
```

允许的高饱和点缀：

```text
暖黄色灯光。
红色小毯子、标识、工具箱。
蓝色屏幕、设备灯。
紫色电子模块。
绿色植物。
橙色维修灯。
```

与普通建筑的区别：

| 建筑类型 | 主色 | 彩色比例 | 内部结构 | 情绪 |
|---|---|---|---|---|
| 普通街区建筑 | 灰黑、炭黑 | 很少 | 通常不可见 | 压迫、危险、废弃 |
| 家 | 白灰、暖灰 | 较多但受控 | 必须可见 | 安全、休息、可归属 |
| 修复前前哨站 | 灰色、破损灰黑 | 很少 | 可部分可见但杂乱 | 未激活、废弃、等待修复 |
| 修复后前哨站 | 白灰、暖灰 | 较多但受控 | 必须可见 | 临时安全、被点亮、可使用 |

规则：

```text
家和修复后前哨站可以比普通建筑更明亮。
家和修复后前哨站必须有清晰室内结构，如床、桌子、灯、储物柜、工作台、地毯、植物。
修复后前哨站和家的视觉逻辑一致，但更临时、更工具化。
修复前前哨站必须灰暗、破损、未点亮，不能提前表现得安全。
```

---

## 4. 资源生产策略

## 4.1 场景不直接生成整张地图

整张地图可以作为概念图参考，但正式游戏资源不建议直接使用一张大图。

正式生产方式：

```text
拆楼房。
拆道路。
拆区块地基。
拆区块边缘。
拆路口。
拆台阶。
拆围栏。
拆路灯。
拆花坛。
拆垃圾桶。
拆招牌。
拆涂鸦墙。
拆集装箱。
拆临时棚。
拆容器。
拆家。
拆前哨。
拆撤离点。
```

原因：

```text
Godot 中更容易拼装地图。
碰撞体更容易制作。
后续能复用资产。
能快速扩展不同街区。
能避免 AI 生成整图后无法编辑。
```

---

## 4.2 场景拆件优先级

P0：

```text
家 / 安全屋。
区块填充地砖。
区块边缘 / 角。
道路直线块。
十字路口。
T 字路口。
转角路口。
小型楼房。
中型楼房。
可交互容器。
路灯。
花坛。
围栏。
```

P1：

```text
前哨站修复前。
前哨站修复后。
大型楼房。
楼梯。
屋顶设备。
空调外机。
垃圾桶。
破招牌。
涂鸦墙。
路障。
铁皮棚。
废弃车辆。
```

P2：

```text
撤离点装置。
稀有容器。
音乐耳机相关装饰。
特殊异常区域装饰。
```

---

## 5. 资源规格

## 5.1 场景拆件规格

推荐尺寸：

| 类型 | 建议尺寸 | 说明 |
|---|---|---|
| 小装饰 | 128x128 / 256x256 | 路灯、垃圾桶、花坛 |
| 区块填充地砖 | 256x256 | 不可通行街区内部，可无缝平铺 |
| 区块边缘/角 | 256x256 | 区块 curb、边框、外角、内凹角 |
| 区块覆盖贴花 | 256x256 透明 | 裂纹、污渍、杂草、排水口 |
| 道路块 | 512x512 | 可平铺 |
| 小楼 | 512x512 | 单栋小建筑 |
| 中楼 | 768x768 / 1024x1024 | 街区主建筑 |
| 大楼 | 1024x1024 / 1536x1536 | 大型遮挡或地标 |
| 家 / 安全屋 | 768x768 / 1024x1024 | 可见内部结构，安全地点 |
| 前哨站 | 768x768 / 1024x1024 | 需要修复前与修复后两版 |
| UI 图标 | 128x128 | 背包、装备、消耗品、货币 |
| 角色立绘参考 | 1024x1024 | 用于角色风格定义 |
| 角色局内 sprite | 128x128 / 256x256 | 需后续拆动画 |

场景拆件要求：

```text
普通独立物件使用透明背景 PNG。
区块填充/道路 tile 可以是不透明方形 tile。
俯视或轻微斜俯视统一。
主体完整，不被裁切。
边缘干净，方便切图。
无文字水印。
不要生成完整街区背景。
不要带大面积投影覆盖外部区域。
碰撞边界可读。
```

### 5.1.1 区块地基资源规格

区块资源用于铺出不可通行街区底座，对应地图规则中的 `TileMap_BlockSolid` 和 `TileMap_BlockEdge`。

首批区块 Sheet 建议：

```text
assets/map/blocks/sheets/block_district_tiles_sheet_01.png
```

切片输出建议：

```text
assets/map/blocks/fill/block_fill_clean_01.png
assets/map/blocks/fill/block_fill_cracked_01.png
assets/map/blocks/fill/block_fill_dirty_01.png
assets/map/blocks/edge/block_edge_straight_01.png
assets/map/blocks/edge/block_corner_outer_01.png
assets/map/blocks/edge/block_corner_inner_01.png
assets/map/blocks/cut/block_alley_cut_01.png
assets/map/blocks/cut/block_driveway_cut_01.png
assets/map/blocks/overlay/block_decal_cracks_01.png
```

Sheet 内容：

| 类型 | 单元尺寸 | 背景 | 要求 |
|---|---:|---|---|
| 填充地砖 | 256x256 | 不透明 | 四边无缝平铺 |
| 直边 | 256x256 | 不透明或透明边缘 | 有清晰 curb/边框 |
| 外角 | 256x256 | 不透明或透明边缘 | 与直边可拼接 |
| 内凹角 | 256x256 | 不透明或透明边缘 | 用于凹形区块 |
| 缺口 | 256x256 | 不透明或透明边缘 | 小巷、车道、入口 |
| 覆盖贴花 | 256x256 | 透明 | 裂纹、污渍、草、井盖 |

视觉要求：

```text
灰黑脏旧水泥地面。
高密度但低对比的手绘裂纹。
边缘有清晰 curb、台阶、砖线或破损边。
填充地砖重复 4×4 后不能出现明显接缝。
不要自带楼房。
不要自带完整街道。
不要有大面积方向性阴影。
不要有文字和水印。
```

关于“可拉伸”：

```text
可以制作可重复填充的区块纹理，但不要依赖单张图片直接缩放。
推荐用 TileMap/Terrain 逐格铺 block_fill，并用 edge/corner 收边。
如果需要编辑器中快速拉出大区块，可使用可无缝平铺的 fill 纹理做 repeat texture，
再用 edge/corner 或 curb 资源补边。
资源必须服务制作人在 Godot 编辑器中手动绘制和摆放，而不是只适合整图合成。
```

Godot 推荐：

```text
长期方案：TileMapLayer + TileSet terrain。
快速方案：BlockArea.tscn 使用 Polygon2D/Sprite2D repeat texture + CollisionPolygon2D。
原型方案：灰色 Polygon2D + CollisionShape2D，后续替换成区块 TileSet。
```

编辑器使用要求：

```text
区块 tile 必须适合 TileSet/Terrain 配置。
区块 fill 必须适合重复填充。
edge/corner/cut 必须能人工补边。
楼房资源必须能作为独立 Sprite/Scene 手动摆到区块上。
道路资源必须能作为 TileMap 或可拼接 tile 手动铺设。
```

禁止：

```text
把一张带明显边框的 512x512 图直接拉伸成大区块。
拉伸后让裂纹和地砖线变形。
让楼房贴图承担区块边界。
让区块纹理比道路纹理更亮、更抢眼。
```

---

## 5.2 家与前哨站规格

家和前哨站是特殊建筑资产。

家需要：

```text
俯视或轻微斜俯视。
可见室内结构。
白灰或暖灰主色。
暖黄色灯光。
高饱和小面积点缀。
有明确安全感。
可以看到床、桌子、柜子、灯、地毯、植物、储物区。
与普通灰黑建筑形成强烈区分。
```

修复前前哨站需要：

```text
灰色为主。
破损。
未点亮或只有少量故障灯。
内部结构可部分看到，但杂乱、残缺、不可用。
有修复潜力，但不是安全状态。
```

修复后前哨站需要：

```text
与家的表现逻辑一致。
白灰或暖灰主色。
内部结构清晰。
灯光点亮。
有工具、补给箱、简易工作台、信号装置。
高饱和点缀更多，用来表达被修复、被激活。
```

状态命名：

```text
safe_house_active
outpost_broken
outpost_repaired
```

资源路径建议：

```text
res://assets/map/safe/safe_house_active_01.png
res://assets/map/outposts/outpost_broken_01.png
res://assets/map/outposts/outpost_repaired_01.png
```

---

## 5.3 角色规格

角色概念图：

```text
正面 + 背面。
灰黑线稿。
脏旧衣服。
旧背包。
少量紫/蓝电子模块。
白色或透明背景。
```

局内角色 sprite：

```text
俯视或轻微斜俯视。
四方向优先。
尺寸 128x128 或 256x256。
透明背景。
动作先做 idle / walk。
```

注意：

```text
参考图中的角色是立绘/设定图方向。
真正局内 sprite 需要再转成俯视可动版本。
不要直接把立绘当局内角色。
```

---

## 5.4 图标规格

推荐：

```text
128x128 PNG。
透明背景。
灰黑主色。
粗黑轮廓。
物体表面有脏旧纹理。
小面积紫/蓝/红点缀可用于稀有度或电子感。
中心构图。
小尺寸可识别。
```

---

## 6. 命名规则

路径推荐：

```text
res://assets/map/buildings/building_small_shop_01.png
res://assets/map/buildings/building_medium_apartment_01.png
res://assets/map/safe/safe_house_active_01.png
res://assets/map/outposts/outpost_broken_01.png
res://assets/map/outposts/outpost_repaired_01.png
res://assets/map/blocks/fill/block_fill_clean_01.png
res://assets/map/blocks/edge/block_edge_straight_01.png
res://assets/map/roads/road_straight_01.png
res://assets/map/roads/road_cross_01.png
res://assets/map/props/streetlamp_01.png
res://assets/map/props/planter_box_01.png
res://assets/icons/items/scrap_metal.png
res://assets/icons/currency/mine_coin.png
res://assets/icons/equipment/backpack_small_reinforced.png
res://assets/sprites/player/player_idle_down.png
```

命名：

```text
小写英文。
下划线。
类别_规格_主题_序号。
与 data 表 id 对齐。
状态后缀放最后。
```

示例：

```text
building_small_shop_01.png
building_medium_rooftop_02.png
road_corner_01.png
block_fill_cracked_01.png
block_corner_outer_01.png
streetlamp_warm_01.png
container_safe_closed.png
container_safe_open.png
```

## 6.1 Godot 场景放置规则

正式地图资源不直接替代白盒布局节点，而是放入 `RunScene` 的表现层。

```text
WorldRoot/MapLayout
  白盒数据层：WhiteboxMapRect、点位、碰撞生成依据

WorldRoot/MapVisual/RoadVisual
  道路、广场、人行道、井盖、斑马线

WorldRoot/MapVisual/BlockVisual
  街区地块底图、废墟块、不可进入区域视觉

WorldRoot/MapVisual/BuildingVisual
  家、前哨站、楼房主体

WorldRoot/MapVisual/PropVisual
  路灯杆、垃圾桶、围栏、路障、容器外观等

WorldRoot/MapVisual/DecalVisual
  裂痕、血迹、水渍、脏污、涂鸦等地表叠加物

WorldRoot/MapLights
  路灯、建筑灯、整体氛围光
```

放置原则：

```text
WhiteboxMapRect 决定位置、尺寸、碰撞和可通行规则。
Sprite2D / TileMapLayer / PackedScene 只负责视觉表现。
街区、道路这类大面积资源可以由脚本根据 WhiteboxMapRect 自动生成。
家、前哨站、可交互建筑适合做成独立 .tscn，再挂到 BuildingVisual。
路灯适合做成 Sprite2D + PointLight2D 的独立 .tscn，再挂到 MapLights/StreetLights。
```

---

## 7. GPT-image-2.0 通用提示词结构

提示词必须包含：

```text
资产类型。
主体。
视角。
风格锚点。
颜色限制。
用途。
背景要求。
可拆件要求。
禁止项。
```

通用模板：

```text
Create a standalone game asset for a 2D top-down wasteland extraction game.
Asset type: [building / road tile / street prop / inventory icon / character concept].
Subject: [specific subject].
View: top-down or slightly top-down, consistent with a modular city map.
Style: dark hand-drawn manga line art, dense black ink outlines, rough sketch texture, dirty grey concrete, worn urban wasteland, high detail, grim but readable.
Color palette: mostly grayscale and charcoal, small accents of neon purple, electric blue, muted red, and tiny warm yellow lamps only where appropriate.
Production requirement: isolated standalone asset, transparent background, full object visible, clean cutout edges, suitable for Godot 2D map assembly.
Avoid: full map background, photorealism, glossy 3D render, cute cartoon, bright saturated colors, clean sci-fi, readable text, watermark, logo.
```

---

## 8. 场景拆件提示词模板

## 8.0 区块地基拆件

```text
Create a modular city block foundation tile sheet for a 2D top-down wasteland extraction game.
Subject: non-walkable city district block ground tiles, concrete block interiors, curb edges, outer corners, inner corners, alley cuts, driveway cuts, cracked concrete decals.
View: top-down orthographic tile sheet, designed for Godot TileMap assembly.
Style: dark hand-drawn manga line art, dense black ink outlines, rough sketch texture, dirty grey concrete, worn urban wasteland, subtle cracks, stains, weeds, chipped curbs.
Color palette: grayscale and charcoal, low contrast, tiny muted stains only, no bright colors.
Production requirement: clean grid-based sheet, each tile 256x256, include seamless fill tiles and edge/corner tiles, suitable for drawing large non-walkable city blocks; no buildings attached; no complete street scene.
Important: fill tiles must be seamless on all four edges and look natural when repeated in a 4x4 area; edge and corner tiles must connect cleanly.
Avoid: full map background, buildings, cars as main subject, strong directional shadows, photorealism, glossy 3D render, readable text, watermark, logo.
```

建议批量主题：

```text
block_fill_clean
block_fill_cracked
block_fill_dirty
block_edge_straight
block_corner_outer
block_corner_inner
block_alley_cut
block_driveway_cut
block_decal_cracks
block_decal_grass
```

---

## 8.1 楼房拆件

```text
Create a standalone modular building asset for a 2D top-down wasteland extraction game.
Subject: [small old shop / medium apartment block / rooftop building / narrow alley building].
View: top-down or slightly top-down, orthographic game asset, consistent perspective.
Style: dark hand-drawn manga line art, dense black ink outlines, rough sketch texture, dirty grey concrete, old urban wasteland, layered rooftops, pipes, vents, air conditioners, damaged signs, worn walls.
Color palette: grayscale and charcoal, tiny neon purple or blue details, small warm yellow lamp if needed.
Production requirement: transparent background, complete building visible, no surrounding full street, clean cutout edges, collision boundary easy to read, suitable for Godot 2D map assembly.
Avoid: photorealistic render, clean modern architecture, bright cyberpunk, full city map, readable text, watermark, logo, cropped edges.
```

建议批量主题：

```text
small old corner shop
small residential block
medium apartment with rooftop pipes
medium shop with neon sign
large ruined market building
narrow alley building
rooftop utility structure
```

---

## 8.2 家与前哨站拆件

家和前哨站必须使用独立提示词，不要套普通楼房模板。

### 家 / 安全屋

```text
Create a standalone safe house building asset for a 2D top-down wasteland extraction game.
Subject: a small safe house with visible interior rooms, cozy survival shelter, bed, desk, storage cabinet, warm lamps, small rug, plants, supply shelves, repaired walls.
View: top-down or slightly top-down, orthographic game asset, complete building visible.
Style: hand-drawn manga line art, dense black ink outlines, rough sketch texture, but cleaner and brighter than the surrounding wasteland city.
Color palette: white, light grey, warm grey as the main colors; warm yellow lights; controlled high-saturation accents such as red blanket, blue monitor lights, purple electronic module, green plants.
Mood: clearly safe, warm, lived-in, protected, visually distinct from dark grey ruined buildings.
Production requirement: standalone asset, transparent background, visible interior layout, clean cutout edges, suitable for Godot 2D map assembly, collision boundary easy to read.
Avoid: dark ruined building, full city map, closed roof hiding the interior, photorealism, glossy 3D render, unreadable text, watermark, logo.
```

### 前哨站：修复前

```text
Create a standalone broken outpost building asset for a 2D top-down wasteland extraction game.
Subject: an abandoned small outpost shelter before repair, partially visible interior, broken workbench, scattered supplies, damaged signal device, cracked walls, unlit lamps, messy floor.
View: top-down or slightly top-down, orthographic game asset, complete building visible.
Style: dark hand-drawn manga line art, dense black ink outlines, rough dirty texture, damaged urban survival shelter.
Color palette: mostly grey, dark grey, dusty concrete, very little color, maybe one tiny broken red or blue indicator light.
Mood: not safe yet, broken, inactive, waiting to be repaired.
Production requirement: standalone asset, transparent background, visible but messy interior structure, clean cutout edges, suitable for Godot 2D map assembly.
Avoid: warm safe house feeling, bright lights, clean white interior, full city map, photorealism, glossy 3D render, readable text, watermark.
```

### 前哨站：修复后

```text
Create a standalone repaired outpost building asset for a 2D top-down wasteland extraction game.
Subject: the same small outpost shelter after repair, visible interior rooms, working lamps, repair workbench, supply boxes, signal device, clean floor patches, repaired walls, small colored markers.
View: top-down or slightly top-down, orthographic game asset, complete building visible.
Style: hand-drawn manga line art, dense black ink outlines, rough sketch texture, brighter and safer than normal wasteland buildings, but more temporary and utilitarian than the player's home.
Color palette: white, light grey, warm grey as main colors; warm yellow lamps; high-saturation accents such as orange repair light, blue screen, purple signal module, red tool box, green medical pack.
Mood: repaired, activated, temporarily safe, clearly different from grey ruined buildings.
Production requirement: standalone asset, transparent background, visible interior layout, clean cutout edges, suitable for Godot 2D map assembly. It should share the same footprint and silhouette as the broken outpost version when possible.
Avoid: dark abandoned state, closed roof hiding the interior, full city map, photorealism, glossy 3D render, readable text, watermark.
```

重要规则：

```text
修复前和修复后前哨站最好保持相同占地轮廓。
修复后的前哨站可以更亮，但不能比家更豪华。
家是长期安全，前哨是临时安全。
```

落地规则：前哨站美术不挂在逻辑 `Area2D` 下面，而是作为 `WorldRoot/YSortRoot/Outpost*_Visual/ArtSprite` 直接子节点摆放；`candidate_id` 绑定对应的前哨站候选逻辑点。所有候选点都常驻显示 broken 资源，被本局抽中的点位才有逻辑交互和修复气泡。修复气泡采用一个整体面板：标题“前哨站”较大，下方一行显示 `需要材料A：n/N        需要材料B：n/N`，不显示背包数量或调试缩写。修复完成时只替换同一个 `ArtSprite.texture` 为 repaired 资源，不自动覆盖编辑器里调好的缩放和位置。前哨站表现保持 `z_index = 0` 参与 YSort，和其他建筑互相遮挡时按脚点排序。

---

## 8.3 道路拆件

### 8.3.1 V0.1 推荐道路地面方案

当前白盒地图采用“红框街区为不可进入区，红框之外为道路”的结构。道路不适合继续用 `road_straight / corner / T junction / cross` 一条街一条街拼接。

推荐方案：

```text
道路主体 = 一整块或少数几块可平铺的大面积废土城市地面。
街区/楼房 = 盖在道路地面上方。
道路装饰 = 井盖、斑马线、裂缝、路沿、人行道边、污渍、路标等局部 Sprite。
```

Godot 放置层级：

```text
WorldRoot/MapVisual/RoadVisual/RoadGroundBase
  大面积道路地面底图，可用 TextureRect / Sprite2D / TileMapLayer 表示

WorldRoot/MapVisual/RoadVisual/ManualRoadPieces
  手工调试道路样例、特殊路口、局部装饰

WorldRoot/MapVisual/BlockVisual
  街区、楼房、不可进入地块视觉，盖在 RoadGroundBase 上方
```

当前地图尺寸参考：

```text
1 Size Unit = 64 px
Street_RoadField_280x158 = 当前道路底板范围
道路底板目标像素范围 = 17920 px × 10112 px
```

由于 `17920 × 10112` 作为单张贴图过大，不建议一次生成整张完整道路图。推荐生成可平铺底图：

```text
road_ground_base_tile_1024_01.png    # 1024 × 1024，可无缝平铺
road_ground_base_tile_1024_02.png    # 轻微变化版本，避免重复感
road_ground_base_tile_1024_03.png    # 轻微变化版本，避免重复感
road_ground_noise_overlay_1024_01.png
road_ground_crack_decal_512_01.png
road_ground_stain_decal_512_01.png
```

道路底图要求：

```text
正交俯视。
无透视地平线。
不包含楼房、车辆主体、大件路障。
可以包含细碎裂痕、污渍、磨损、浅色旧标线残留。
四边必须可无缝平铺。
整体明度应低于街区/建筑，避免和可进入区域抢视觉。
不要有明显方向性大线条，否则平铺后会暴露重复。
```

### 8.3.2 道路地面底图提示词

```text
Create a seamless square ground texture tile for a 2D top-down wasteland city extraction game.
Asset type: road ground base tile.
Subject: cracked asphalt and dirty concrete urban road surface, worn pavement, subtle old lane paint fragments, dust, grime, small cracks and stains.
View: strict top-down orthographic, no perspective, no horizon.
Style: dark hand-drawn manga line art texture, gritty ink details, dirty grey concrete and asphalt, readable but not too busy.
Color palette: charcoal, dark grey, concrete grey, faded off-white road paint, tiny muted rust stains only.
Production requirement: seamless tile on all four edges, 1024x1024 square texture, no transparent background, suitable for repeated tiling in Godot as the base RoadGround layer.
Avoid: buildings, vehicles, characters, big props, readable text, logos, arrows, bright colors, strong directional shadows, obvious border frame, photorealism, glossy 3D render, single huge crack dominating the tile.
```

变化版提示词：

```text
Create a variation of the same seamless 1024x1024 top-down wasteland road ground tile.
Keep the same scale, color palette, and edge continuity.
Change only the distribution of cracks, stains, old paint fragments, small rubble specks, and dust patches.
Do not add buildings, props, cars, characters, readable text, or strong directional markings.
```

### 8.3.3 道路装饰提示词

道路装饰应作为独立透明 PNG，放在道路底图上方。

```text
Create a standalone transparent decal asset for a 2D top-down wasteland city road.
Subject: [crosswalk remnant / manhole cover / cracked curb edge / oil stain / puddle / faded lane marking / small rubble strip / drainage gutter].
View: strict top-down orthographic.
Style: dark hand-drawn manga line art, gritty dirty texture, worn urban wasteland.
Color palette: grey, charcoal, faded white paint, muted brown rust, very low saturation.
Production requirement: transparent background, clean alpha edges, no surrounding full road tile, suitable as a Sprite2D decal on top of a tiled road ground base.
Avoid: buildings, vehicles, characters, large props, readable text, watermark, bright saturated color, perspective.
```

### 8.3.4 旧道路 tile 的定位

`road_straight / road_corner / road_t_junction / road_cross` 不再作为 V0.1 道路主体的主要拼接方式。它们保留为：

```text
特殊路口装饰参考。
小范围手工拼接测试。
后续 TileMap 方案的候选资源。
```

V0.1 主体道路优先使用 `RoadGroundBase` 大面积地面层。

---

## 8.3.5 旧道路拆件提示词

```text
Create a modular road tile asset for a 2D top-down wasteland city game.
Subject: [straight road / corner road / T junction / cross intersection / sidewalk plaza].
View: top-down orthographic tile, designed to connect with other road tiles.
Style: dark hand-drawn manga line art, cracked concrete, worn lane marks, dirty grey pavement, subtle ink texture.
Color palette: grayscale concrete, faded white road markings, very small muted stains.
Production requirement: transparent background or clean square tile background, seamless edges, readable driving/walking area, no buildings attached unless requested, suitable for Godot tile or sprite assembly.
Avoid: perspective horizon, cars as main subject, bright colors, full map, readable text, watermark.
```

道路变体：

```text
road_straight
road_corner
road_t_junction
road_cross
sidewalk_tile
crosswalk_tile
alley_path
plaza_concrete
```

---

## 8.4 装饰件拆件

```text
Create a standalone street prop asset for a 2D top-down wasteland city game.
Subject: [streetlamp / planter box / trash bin / fence segment / barricade / broken sign / flower bed / bench / utility pole].
View: top-down or slightly top-down, consistent with modular map props.
Style: dark hand-drawn manga line art, thick black outline, rough dirty texture, worn urban object, high detail but readable.
Color palette: grayscale and charcoal, tiny accent colors only if needed; warm yellow glow for lamps, muted red or blue for small details.
Production requirement: transparent background, full object visible, clean cutout edges, no surrounding scene, suitable for Godot 2D prop placement.
Avoid: photorealism, glossy 3D, bright cartoon, full street background, readable text, watermark.
```

装饰件清单：

```text
streetlamp_warm
planter_box_rect
flower_bed_round
trash_bin_metal
fence_segment_black
chain_link_fence
barricade_wood_metal
broken_signboard
graffiti_wall_panel
utility_pole
roof_vent
air_conditioner_unit
stairs_short
stairs_wide
```

---

## 8.5 容器拆件

```text
Create a standalone loot container asset for a 2D top-down wasteland extraction game.
Subject: [small supply box / rusty locker / metal safe / medical box / tool crate].
View: top-down or slightly top-down, game-ready prop.
Style: dark hand-drawn manga line art, thick black outline, dirty scratched metal, worn wasteland object, high detail, readable silhouette.
Color palette: grayscale and charcoal, tiny muted red/blue/purple marks for interaction readability.
Production requirement: transparent background, closed state, full object visible, clean cutout edges, suitable for Godot 2D placement.
Avoid: full room background, readable text, photorealism, glossy 3D, watermark.
```

状态要求：

```text
closed。
open。
empty。
highlight 可用 shader 或 UI 做，不一定生图。
```

---

## 9. 角色提示词模板

## 9.1 角色设定图

```text
Create a character concept sheet for a 2D wasteland extraction game.
Subject: a lonely teenage survivor, thin body, messy hair covering part of the face, dirty oversized grey T-shirt, worn black shorts, heavy old sneakers, rugged backpack, small purple and blue electronic modules attached to clothes and backpack.
Views: front view and back view on the same image, full body, neutral standing pose.
Style: dark hand-drawn manga line art, dense black ink outlines, rough sketch shading, dirty grayscale clothing, melancholic post-apocalyptic urban mood.
Color palette: mostly grayscale and charcoal, small neon purple and electric blue device lights only.
Background: plain white or transparent background.
Requirements: clear costume design, readable backpack and shoes, no weapon, no text, no watermark.
Avoid: cute chibi, glossy anime, photorealism, bright colors, military armor, gore.
```

## 9.2 局内角色 sprite

```text
Create a 2D top-down character sprite for a wasteland extraction game.
Subject: the same lonely teenage survivor with messy hair, dirty grey shirt, black shorts, rugged backpack, heavy shoes, tiny purple/blue electronic details.
View: top-down or slightly top-down, game sprite, [idle_down / idle_up / idle_side / walk_down].
Style: dark hand-drawn manga line art, thick black outline, dirty grayscale texture, readable silhouette.
Background: transparent.
Requirements: full body visible, consistent proportions, suitable for 128x128 or 256x256 sprite, no text, no watermark.
Avoid: front-facing concept art, photorealism, chibi proportions, complex background, weapon focus.
```

---

## 10. 图标提示词模板

```text
Create a 128x128 inventory icon for a 2D wasteland extraction game.
Subject: [item name and description].
Style: dark hand-drawn manga line art, thick black outline, rough dirty texture, grayscale and charcoal palette, small muted accent color if useful.
Composition: centered object, transparent background, readable silhouette at small size.
Use: inventory icon.
Requirements: no text, no watermark, no background scene, clean cutout edges.
Avoid: glossy 3D, bright cartoon, photorealism, complex shadow, neon-dominant colors.
```

示例：安定糖

```text
Create a 128x128 consumable inventory icon for a 2D wasteland extraction game.
Subject: a small wrapped calming candy, dirty paper wrapper, handmade survival supply, one tiny muted pink-purple mark.
Style: dark hand-drawn manga line art, thick black outline, rough dirty texture, grayscale and charcoal palette with a tiny purple accent.
Composition: centered object, transparent background, readable silhouette at small size.
Use: consumable icon.
Requirements: no text, no watermark, no background scene, clean cutout edges.
Avoid: glossy candy art, bright cartoon, photorealism, complex shadow.
```

---

## 11. UI 资源提示词模板

```text
Create a UI icon for a dark hand-drawn 2D wasteland game.
Subject: [inventory / safe storage / extract / merchant / mine coin currency / research / crafting / earphone signal].
Style: rough black ink line icon, dirty grayscale fill, minimal shape, small purple or blue accent only if useful.
Background: transparent.
Requirements: readable at 32x32, no text, no watermark, simple strong silhouette.
Avoid: glossy app icon, 3D render, bright color, complex illustration.
```

矿币 icon 补充要求：

```text
Subject: mine coin currency icon, a small rough metal coin or ore-stamped token used in a wasteland mining town.
Style: dark hand-drawn manga line art, thick black outline, scratched dull metal, muted grey and dirty brass, tiny warm yellow edge highlight.
Background: transparent.
Requirements: readable at 32x32 and 64x64, no text, no watermark, not a shiny fantasy gold coin.
Use path: res://assets/icons/currency/mine_coin.png
```

---

## 12. 场景拆件生产流程

推荐流程：

```text
1. 先生成 1 张完整街区概念图，只作为风格参考。
2. 从概念图中列出可复用拆件清单。
3. 先生成区块地基 Sheet，确认街道/区块基底可施工。
4. 再生成道路、楼房、装饰等独立 PNG。
5. 每个拆件至少生成 3 个变体。
6. 人工筛选风格最统一的一批。
7. 在 Godot 中先用街道 + 区块拼装测试街区，再放楼房。
8. 由制作人在编辑器中实际手动摆放一次，检查是否顺手。
9. 根据碰撞、遮挡、可读性和编辑器摆放体验反向调整提示词。
10. 形成固定资产库后再批量扩展。
```

安全建筑生产流程：

```text
1. 先生成家 / 安全屋，确定安全建筑视觉标准。
2. 再生成修复前前哨站，保持灰色、破损、未点亮。
3. 最后生成修复后前哨站，沿用家的安全逻辑，但更临时、更工具化。
4. 确认修复前后前哨站的占地轮廓接近，便于 Godot 中直接替换状态。
5. 把家和修复后前哨站放到灰黑街区中测试识别度。
```

不要：

```text
直接把完整街区图当地图。
一口气生成所有建筑。
跳过区块地基直接用楼房围出街道。
生成只能看不能摆、不能拼、不能重复的区块/街道图。
混用不同透视角度。
混用完全不同线稿密度。
让装饰件自带不可控阴影和背景。
让家和修复后前哨站看起来像普通废弃建筑。
让修复前前哨站提前出现强安全灯光。
```

---

## 13. 与 Godot 拼装的关系

场景拆件进入 Godot 后：

```text
街道作为 TileMap 或 NavigationRegion2D。
区块作为 TileMap_BlockSolid / BlockArea，提供主不可通行碰撞。
区块边缘作为 TileMap_BlockEdge 或独立 curb 资源。
建筑作为放在区块上的 Sprite2D/Node2D，必要时追加局部 StaticBody2D。
家作为特殊 SafeHouseScene。
前哨站作为 OutpostScene，按 repair_state 切换 broken / repaired 资源。
路灯、花坛、垃圾桶作为 Prop Scene。
容器作为可交互 Scene。
围栏、墙体作为碰撞边界。
灯光可用 Light2D 或 shader 追加。
```

每个场景件建议有：

```text
Sprite2D
CollisionShape2D
InteractionMarker，可选
OcclusionPolygon2D，可选
DebugName，可选
```

---

## 14. 验收标准

所有资源需要检查：

```text
风格接近参考图。
灰黑为主。
线稿足够粗且细节密度高。
彩色只作为小面积点缀。
主体完整没有裁切。
没有文字。
没有水印。
透明背景或可直接平铺。
边缘适合切图。
小尺寸仍可读。
```

场景拆件额外检查：

```text
俯视角一致。
可单独摆放。
不依赖背景才成立。
碰撞边界清晰。
不会挡住玩家读图。
道路边缘能和其他道路块连接。
区块填充 tile 4×4 平铺无明显接缝。
区块边缘/角能围出清晰不可通行街区。
楼房放在区块上后，不改变街道通行宽度。
街道和区块资源能在 Godot 编辑器中手动铺设、移动和替换。
建筑底部边缘适合放置碰撞。
```

家与前哨站额外检查：

```text
家必须一眼看出是安全屋。
家必须能看到内部结构。
家必须使用白灰或暖灰主色，而不是普通灰黑废楼。
家必须有暖光和生活物件。
修复前前哨站必须灰暗、破损、未激活。
修复后前哨站必须与家的安全逻辑一致，但更像临时工作站。
修复前后前哨站占地轮廓应尽量一致。
修复后前哨站不能比家更豪华。
```

角色额外检查：

```text
正背面服装一致。
背包结构清晰。
紫/蓝电子模块面积很小。
不偏向干净校园风。
不偏向重装军事风。
```

---

## 15. 与数据表联动

可从 `.tab` 表读取：

```text
id
name
description
item_type
quality
tags
icon
sellable
sell_currency_id
sell_value
appearance_scene
```

货币 icon 从 `data/currencies.tab` 读取：

```text
id
name
icon
currency_type
```

场景拆件建议后续增加：

```text
data/map_assets.tab
```

建议字段：

| 字段 | 说明 |
|---|---|
| id | 场景资产ID |
| asset_type | block/road/building/prop/container/home/outpost/extract |
| size_class | small/medium/large/tile |
| state | normal/broken/repaired/active |
| theme_tags | 风格标签 |
| sprite_path | PNG路径 |
| scene_path | Godot场景路径 |
| collision_type | none/box/polygon/custom |
| notes | 制作说明 |
| enabled_version | 启用版本 |

---

## 16. 当前设计体检与建议

合理点：

```text
新参考图的灰黑漫画线稿更成熟，也更适合压迫感。
少量霓虹点缀能强化废土科技感和可交互可读性。
场景拆件方式比整图更适合实际游戏制作。
家和修复后前哨站单独使用白灰、灯光和室内结构，可以在压抑地图中形成明确安全锚点。
```

风险：

```text
GPT-image-2.0 可能输出不可拆的大场景，需要反复强调 standalone asset。
不同批次线稿密度可能不一致。
道路块如果不是正交俯视，拼接会困难。
建筑如果阴影太重，会遮挡角色和交互物。
如果家和前哨站不够亮，玩家会难以快速识别安全点。
如果修复前后前哨站轮廓差异过大，状态切换会产生拼装成本。
```

建议：

```text
先生成一套 P0 拆件：2 个小楼、2 个中楼、4 个道路块、3 个路灯/花坛/围栏。
同时生成 1 个家、1 个修复前前哨、1 个修复后前哨，作为安全建筑风格锚点。
先在 Godot 拼一个 1 屏测试街区。
测试可读性后再批量生成。
把通过验收的图片作为后续提示词参考图。
```

---

## 17. 本文档结论

美术生产应从“概念整图”转向“可拼装拆件库”。

后续 GPT-image-2.0 生图必须稳定遵守：

```text
灰黑手绘漫画线稿。
脏旧废土城市。
少量霓虹点缀。
俯视或轻微斜俯视。
独立拆件。
透明背景。
无文字水印。
适合 Godot 2D 拼装。
家和修复后前哨站必须明显更安全、更明亮、可见内部。
修复前前哨站必须灰暗破损，等待玩家修复。
```

只有拆件可控，地图才能真正进入可迭代制作阶段。

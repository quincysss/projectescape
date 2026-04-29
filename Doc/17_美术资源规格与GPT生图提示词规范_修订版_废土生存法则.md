# 17_美术资源规格与GPT生图提示词规范.md

# 《废土生存法则》美术资源规格与 GPT 生图提示词规范（修订版）

> 文档版本：v0.2  
> 所属项目：《废土生存法则》  
> 前置文档：01_项目总纲.md / 03_地图与安全区规则.md / 13_数据配置表与TAB规范.md  
> 适用阶段：美术资产生成、场景拆件、资源替换  
> 本次修订重点：根据新参考图调整整体美术风格；将场景生产方式改为通过 GPT-image-2.0 生成可拆件资产，包括不同规格楼房、道路、路灯、花坛、围栏、装饰物等，便于 Godot 拼装。

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

## 4. 资源生产策略

## 4.1 场景不直接生成整张地图

整张地图可以作为概念图参考，但正式游戏资源不建议直接使用一张大图。

正式生产方式：

```text
拆楼房。
拆道路。
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
前哨建筑。
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
| 道路块 | 512x512 | 可平铺 |
| 小楼 | 512x512 | 单栋小建筑 |
| 中楼 | 768x768 / 1024x1024 | 街区主建筑 |
| 大楼 | 1024x1024 / 1536x1536 | 大型遮挡或地标 |
| UI 图标 | 128x128 | 背包、装备、消耗品 |
| 角色立绘参考 | 1024x1024 | 用于角色风格定义 |
| 角色局内 sprite | 128x128 / 256x256 | 需后续拆动画 |

场景拆件要求：

```text
透明背景 PNG。
俯视或轻微斜俯视统一。
主体完整，不被裁切。
边缘干净，方便切图。
无文字水印。
不要生成完整街区背景。
不要带大面积投影覆盖外部区域。
碰撞边界可读。
```

---

## 5.2 角色规格

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

## 5.3 图标规格

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
res://assets/map/roads/road_straight_01.png
res://assets/map/roads/road_cross_01.png
res://assets/map/props/streetlamp_01.png
res://assets/map/props/planter_box_01.png
res://assets/icons/items/scrap_metal.png
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
streetlamp_warm_01.png
container_safe_closed.png
container_safe_open.png
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

## 8.2 道路拆件

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

## 8.3 装饰件拆件

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

## 8.4 容器拆件

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
Subject: [inventory / safe storage / extract / research / crafting / earphone signal].
Style: rough black ink line icon, dirty grayscale fill, minimal shape, small purple or blue accent only if useful.
Background: transparent.
Requirements: readable at 32x32, no text, no watermark, simple strong silhouette.
Avoid: glossy app icon, 3D render, bright color, complex illustration.
```

---

## 12. 场景拆件生产流程

推荐流程：

```text
1. 先生成 1 张完整街区概念图，只作为风格参考。
2. 从概念图中列出可复用拆件清单。
3. 按拆件类型分别生成独立 PNG。
4. 每个拆件至少生成 3 个变体。
5. 人工筛选风格最统一的一批。
6. 在 Godot 中拼装测试街区。
7. 根据碰撞、遮挡、可读性反向调整提示词。
8. 形成固定资产库后再批量扩展。
```

不要：

```text
直接把完整街区图当地图。
一口气生成所有建筑。
混用不同透视角度。
混用完全不同线稿密度。
让装饰件自带不可控阴影和背景。
```

---

## 13. 与 Godot 拼装的关系

场景拆件进入 Godot 后：

```text
道路作为 TileMap 或大块 Sprite。
建筑作为 StaticBody2D + Sprite2D。
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
建筑底部边缘适合放置碰撞。
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
appearance_scene
```

场景拆件建议后续增加：

```text
data/map_assets.tab
```

建议字段：

| 字段 | 说明 |
|---|---|
| id | 场景资产ID |
| asset_type | building/road/prop/container/outpost/extract |
| size_class | small/medium/large/tile |
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
```

风险：

```text
GPT-image-2.0 可能输出不可拆的大场景，需要反复强调 standalone asset。
不同批次线稿密度可能不一致。
道路块如果不是正交俯视，拼接会困难。
建筑如果阴影太重，会遮挡角色和交互物。
```

建议：

```text
先生成一套 P0 拆件：2 个小楼、2 个中楼、4 个道路块、3 个路灯/花坛/围栏。
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
```

只有拆件可控，地图才能真正进入可迭代制作阶段。

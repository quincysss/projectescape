# 20_UI视觉规范与界面资源Sheet提示词.md

# 《废土生存法则》UI视觉规范与界面资源 Sheet 提示词（修订版）

> 文档版本：v0.1  
> 所属项目：《废土生存法则》  
> 前置文档：04_稳定值与视野系统.md / 05_容器刷新与开箱系统.md / 06_前哨材料与前哨站修复系统.md / 07_背包、存储与负重系统.md / 08_撤离与结算系统.md / 09_局外仓库系统.md / 10_研究所与制作所系统.md / 17_美术资源规格与GPT生图提示词规范.md  
> 适用阶段：UI视觉设计、UI资源拆件、Godot UI制作  
> 文档目标：定义同风格局内 UI、局外 UI、字体建议、控件状态、可交互描边规则和 GPT-image-2.0 UI sheet 生成提示词，确保生成结果不是概念整图，而是可切分、可直接用于 Godot 的资源 sheet。

---

## 1. 本文档一句话说明

UI 要像“从废土城市里拆下来的手绘仪表和纸片面板”，但必须足够清晰、可读、可切图、可复用。

---

## 2. UI 总体风格

关键词：

```text
灰黑手绘漫画线稿。
粗黑描边。
脏旧纸面和磨损金属。
低饱和灰色主色。
少量高饱和功能色。
局部霓虹紫、电子蓝、警示红、撤离绿。
边缘略不规则。
读数清晰。
控件可复用。
```

UI 不应变成：

```text
干净现代 SaaS 界面。
高亮赛博霓虹整屏。
写实金属质感。
Q版糖果 UI。
复杂厚涂插画面板。
只有概念图不可切分。
```

---

## 3. 色彩规则

基础色：

| 用途 | 建议色感 |
|---|---|
| UI 面板底 | 炭黑、深灰、脏灰 |
| 安全面板底 | 白灰、暖灰 |
| 线框 | 黑色粗线、深灰手绘线 |
| 普通文字 | 近白、浅灰 |
| 弱文字 | 中灰 |
| 稳定值 | 粉红偏灰、低饱和红 |
| 警告 | 高饱和红、小面积使用 |
| 可交互提示 | 紫色或蓝色描边 |
| 撤离进度 | 高饱和偏黑渐变绿 |
| 安全地点 | 暖黄灯光、白灰底 |

撤离绿色建议：

```text
顶部：偏亮高饱和绿。
中部：深绿色。
底部：接近黑绿。
整体从上到下渐变。
外圈可有黑色手绘描边。
```

---

## 4. 字体建议

## 4.1 字体原则

UI 字体必须优先保证可读。

建议：

```text
标题可以略粗、略压缩。
正文必须清晰。
数字要稳定等宽或近似等宽。
中文、英文、日文要统一字重和视觉高度。
不要使用过度花哨的手写字体承载主要信息。
```

---

## 4.2 推荐字体

中文：

```text
首选：Noto Sans SC / 思源黑体 CN
备选：Source Han Sans SC / 思源黑体
用途：正文、按钮、仓库、研究、制作、结算文字
```

英文：

```text
首选：Inter
备选：IBM Plex Sans / Roboto Condensed
用途：英文 UI、系统标签、按钮、页签
```

日文：

```text
首选：Noto Sans JP
备选：Source Han Sans JP / 源ノ角ゴシック
用途：日文版本正文、按钮、说明
```

数字和参数：

```text
首选：JetBrains Mono
备选：IBM Plex Mono / Roboto Mono
用途：负重、数量、倒计时、进度、材料需求
```

建议组合：

```text
中文主 UI：Noto Sans SC
英文主 UI：Inter
日文主 UI：Noto Sans JP
数字：JetBrains Mono
```

注意：

```text
正式商用前需要检查字体授权。
如果希望三语统一，优先使用 Noto Sans CJK 系列。
```

---

## 5. UI 资源 Sheet 总规则

使用 GPT-image-2.0 生成 UI 时，必须要求输出资源 sheet，而不是完整 UI 概念图。

Sheet 规则：

```text
透明背景 PNG。
所有元素按网格排列。
每个格子只放一个 UI 元素。
格子之间留足间距。
不要把元素互相重叠。
不要包含说明文字、序号、标签。
不要生成完整游戏截图。
不要生成整张界面 mockup 代替拆件。
边缘干净，便于切图。
同一张 sheet 内风格、线宽、阴影一致。
```

推荐 sheet 尺寸：

```text
1024x1024：小型 UI 图标 sheet。
1536x1536：中型控件 sheet。
2048x2048：完整控件状态 sheet。
```

推荐网格：

```text
4x4：大型控件。
5x5：图标和按钮。
8x8：小图标、状态角标。
```

---

## 6. 局内 UI 清单

局内 UI 必须覆盖：

```text
角色头像。
头像框。
稳定值条。
局内倒计时。
背包入口。
负重显示。
消耗品快捷栏。
耳机信号图标，后续。
前哨站材料气泡。
资源道具 icon。
可交互物描边。
交互按键提示。
容器剩余时间提示。
撤离按钮与撤离进度条。
背包 + 装备界面。
打开容器界面。
家 / 前哨站安全格子界面。
低稳定值警告。
获得物品短提示。
读条进度条。
```

局内 UI 原则：

```text
尽量少挡地图。
只在需要时出现。
重要危险信息优先级最高。
背包、容器、安全格子尽量复用同一套格子资源。
```

当前 V0.1 局内 HUD 布局规则（2026-05-10）：

```text
左上角为角色状态区：角色头像框在最左，稳定值条紧贴头像右侧，头像框允许轻微压在稳定值底框之上，但不能遮挡稳定值刻度和读数。
稳定值条保留 100 / 60 / 35 / 15 / 0 分段感，正式资源到齐前允许使用白盒面板、白盒进度条和功能色占位。
顶部中央为局内倒计时，默认字体为灰白色；剩余时间小于等于 30 秒时变为灰红色。
倒计时下方为撤离状态条：两座前哨站修复完成前显示灰色圆点和“不可撤离”；撤离解锁后显示深绿色圆点和“可返回家中撤离”。
左侧中部金黄色框为前哨站修复信息区：标题显示“前哨 xx/xx”；下方仅显示第一、第二前哨站图标和状态，避免遮挡场景内信息。状态分为“未修复”、“修复中 xx%”和“修复完成”，修复中百分比必须接入当前按住修复交互的实时进度。
右下角为背包信息区：显示背包图标预留位、当前占用格数 / 背包格子上限，以及负重进度条。
负重进度条必须直接写明“负重: current / max”；接近上限可转黄，达到或超过上限转红。
消耗品快捷栏位置预留在背包信息区上方；V0.1 没有消耗品概念时不显示，避免空 UI 占屏。
常驻 HUD 不显示长段操作说明；WASD、F、Tab、E 等教学文本只允许在调试或必要提示中短时出现。
```

---

## 7. 局内 HUD 模块

## 7.1 角色头像与头像框

内容：

```text
角色头像。
头像框。
低稳定值裂纹状态。
安全区暖光状态。
危险状态红色边缘。
```

风格：

```text
头像框为粗黑手绘边框。
灰黑旧金属或纸片底。
少量紫蓝电子点。
危险时边缘可有红色污痕。
```

---

## 7.2 稳定值条

表现：

```text
横向条或头像旁竖条。
底框粗黑手绘。
填充为低饱和粉红 / 灰红。
低稳定值时抖动、闪烁或出现裂纹。
```

状态：

```text
normal
low
critical
recovering
```

---

## 7.3 负重与背包入口

表现：

```text
背包 icon。
负重数字：current / max。
接近上限时变黄。
超重时变红。
```

建议：

```text
数字使用 JetBrains Mono。
背包图标用灰黑手绘旧背包。
```

---

## 7.4 前哨材料气泡

用途：

```text
当玩家进入前哨交互范围，显示当前可提交材料。
显示已提交进度，如 1/2、1/2。
未满足数量也可以显示可部分提交。
```

表现：

```text
小气泡。
材料 icon + 数量进度。
修复前为灰色气泡。
可提交时边缘出现暖黄或蓝色轻微高亮。
提交完成时气泡变成安全白灰与暖光。
```

---

## 7.5 可交互物换色描边

该规则属于“功能 + UI 表现”。

功能归属：

```text
容器系统。
前哨系统。
交互检测系统。
```

UI 表现归属：

```text
InteractionHighlightView。
InteractableOutlineShader。
ShaderMaterial 或 outline 材质参数。
```

实现优先级：

```text
第一优先级：Shader 根据目标 Sprite 的 alpha 轮廓自动生成外描边。
第二优先级：特殊 VFX 叠加纹理，如流光、扫描线、警告闪烁。
不推荐：为每一种容器或前哨站单独生成固定 PNG 边框。
```

原因：

```text
不同容器形状不同，固定边框很难适配。
Shader 可以自动贴合纸箱、柜子、保险箱、前哨站等不同轮廓。
后续新增容器时，只需要复用同一套材质参数。
```

当前版本需要描边的对象：

```text
所有可交互容器。
前哨站。
```

描边状态：

| 状态 | 表现 |
|---|---|
| 可交互但未进入范围 | 轻微暗紫或暗蓝外轮廓，可选 |
| 进入交互范围 | 明显紫蓝描边 |
| 正在读条 | 描边沿轮廓流动或脉冲 |
| 可提交材料 | 前哨站描边偏暖黄或蓝色 |
| 已修复 / 安全 | 白灰暖光边缘 |
| 不可交互 / 已消失 | 无描边 |

规则：

```text
描边必须尽量按物件真实轮廓生成。
描边不能替代 F/E 交互提示。
描边不能太厚，避免遮挡美术。
描边颜色要和普通霓虹点缀区分。
容器倒计时即将结束时可轻微闪烁。
UI sheet 中的描边资源只作为风格参考或特殊叠加效果，不作为普通容器的固定边框。
```

---

## 7.6 撤离按钮

撤离按钮是局内关键 UI。

规则：

```text
玩家进入撤离范围后显示。
按住 E 时按钮内绿色进度条增长。
进度满 3 秒后撤离成功。
松开 E 或离开范围中断。
按住 E 时玩家不可移动。
如果对局时间归零，撤离失败。
```

视觉：

```text
按钮底为黑灰手绘边框。
进度填充为高饱和偏黑绿。
绿色从上到下渐变：亮绿 -> 深绿 -> 黑绿。
进度条可以从左到右涨，也可以环形涨。
文字或图标必须清晰。
```

---

## 8. 局内界面模块

## 8.1 背包 + 装备界面

内容：

```text
背包格子。
装备槽。
当前负重。
物品详情。
丢弃或移动操作，后续。
关闭按钮。
```

装备槽：

```text
HEAD
BODY
HAND
LEG
BACK
SPECIAL
```

视觉：

```text
灰黑面板。
手绘粗框。
格子可复用。
装备槽边框略更亮。
超重时负重区域红色提示。
```

---

## 8.2 容器界面

内容：

```text
容器名称。
容器剩余倒计时。
容器物品格子。
玩家背包简化区域。
一键拿取，后续。
关闭按钮。
```

规则：

```text
打开容器界面时锁玩家移动。
容器倒计时继续流逝。
离开触发范围强制关闭界面。
容器空了关闭后容器消失。
```

视觉：

```text
容器格子与背包格子复用。
容器标题条可根据容器类型变色。
倒计时接近 0 时边缘红色闪烁。
```

---

## 8.3 家和前哨站安全格子界面

用途：

```text
家：安全存储、临时整理、出发准备入口。
修复后前哨站：前哨安全格子、临时存放或提交材料展示。
```

建议复用：

```text
背包格子。
仓库格子。
安全存储格子。
前哨格子。
```

差异：

| 界面 | 主色 | 情绪 |
|---|---|---|
| 家 | 白灰、暖灰、暖黄 | 安全、稳定 |
| 修复后前哨 | 白灰、工具橙、蓝色屏幕 | 临时安全、功能性 |
| 普通容器 | 灰黑、暗紫蓝 | 未知收益、风险 |

---

## 8.4 局内遗漏补充

建议补充的局内 UI：

```text
局内时间倒计时。
当前安全区 / 暗区状态。
低稳定值屏幕边缘提示。
容器读条 UI。
前哨提交读条 UI。
获得物品 toast。
背包满提示。
安全存储成功提示。
撤离失败提示。
```

---

## 9. 局外 UI 总框架

局外 UI 应先做总体框架，再拆模块。

顶层结构：

```text
顶部页签导航。
主内容区域。
右侧详情区域，可选。
底部操作区。
全局资源提示区。
```

顶部页签：

```text
仓库。
商人。
研究所。
制作所。
出发准备。
后续预留：装备、耳机、图鉴、设置。
```

页签规则：

```text
页签数量会扩展，所以右侧必须预留空间。
当前选中页签有高亮描边。
未解锁页签可以锁定态显示。
未开发完成页签必须置灰并禁止点击。
V0.1 局外顶部页签顺序为：仓库、商人、研究所、制作所。
顶部或右上角显示当前矿币数量。
```

---

## 10. 成功撤离与结算界面

内容：

```text
成功撤离标题。
临时背包。
安全存储内容。
仓库区域。
手动选择入库。
一键入库。
确认入库按钮。
未入库遗弃警告弹窗。
返回基地按钮。
```

规则：

```text
玩家点击确认入库时，未入库且仍在背包中的道具视为遗弃。
遗弃前必须弹确认提示。
遗弃道具销毁，不返回局内，也不进入仓库。
```

视觉：

```text
标题可以更亮。
仓库为灰黑面板。
确认按钮使用暖黄或安全绿。
遗弃警告使用红色边缘。
```

---

## 11. 仓库界面

内容：

```text
仓库格子。
物品分类筛选。
排序按钮。
物品详情。
一键存入 / 一键整理。
容量显示。
```

分类：

```text
全部。
材料。
装备。
消耗品。
图纸。
稀有物资。
```

视觉：

```text
灰黑仓库面板。
格子可复用。
选中物品有紫蓝描边。
稀有物资可有小面积亮色角标。
```

---

## 11.5 商人界面

内容：

```text
可出售物品列表。
物品图标。
物品名称。
当前拥有数量。
单价。
出售数量选择器。
本次出售总价。
当前矿币数量。
出售按钮。
出售结果提示。
```

规则：

```text
商人页签从局外顶部第二个页签进入。
未选择物品时出售按钮禁用。
出售数量小于 1 或大于拥有数量时出售按钮禁用。
不可出售物品不显示，或显示为置灰不可选。
数量变化后总价实时更新。
出售成功后刷新仓库数量和矿币显示。
```

视觉：

```text
商人界面延续灰黑手绘面板。
货币数字使用 JetBrains Mono。
矿币 icon 使用小型金属币/矿石币风格，避免变成明亮金币。
出售按钮可使用暖黄描边，但不要过度商业化。
禁用状态必须明显置灰。
```

---

## 12. 研究所界面

内容：

```text
研究节点列表。
研究分类。
研究详情。
材料需求。
当前进度。
提交按钮。
已完成标记。
前置条件提示。
```

视觉：

```text
研究节点像手绘线路图或旧电路图。
完成节点有蓝色或暖黄点亮。
未解锁节点为灰色。
可研究节点有轻微紫蓝描边。
```

---

## 13. 制作所界面

内容：

```text
配方列表。
分类筛选。
产物预览。
材料需求。
制作按钮。
缺材料提示。
已解锁 / 未解锁状态。
```

视觉：

```text
更偏工具台。
灰黑金属面板。
橙色维修灯点缀。
材料满足时按钮暖黄高亮。
缺材料时按钮灰掉。
```

---

## 14. 出发准备界面

内容：

```text
角色预览。
装备槽。
背包选择。
消耗品槽，初始锁定。
耳机槽，后续。
当前负重。
开始探索按钮。
```

视觉：

```text
角色区域略亮。
装备槽为灰黑手绘框。
锁定槽显示灰色锁标。
开始探索按钮使用危险但明确的颜色，如暗红或暖黄。
```

---

## 15. UI Sheet 提示词模板

## 15.1 通用 UI Sheet

```text
Create a game UI asset sheet for a 2D wasteland extraction game.
Output type: transparent PNG UI sprite sheet, not a full interface mockup.
Grid: [4x4 / 5x5 / 8x8], evenly spaced cells, one UI element per cell, no labels, no numbers.
Style: dark hand-drawn manga UI, thick black ink outlines, rough dirty paper and worn metal texture, grayscale and charcoal base, small neon purple, electric blue, muted red, warm yellow accents.
Elements: [list each element].
Requirements: transparent background, clean cutout edges, consistent line width, consistent padding, each element fully visible, suitable for slicing into individual Godot UI sprites.
Avoid: full screen concept art, readable text, watermark, logo, photorealistic UI, glossy 3D buttons, overlapping elements.
```

---

## 15.2 局内 HUD Sheet

```text
Create a transparent PNG UI sprite sheet for in-run HUD elements in a 2D wasteland extraction game.
Grid: 5x5, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, dirty grayscale paper and metal, small neon purple and electric blue accents, warning red only for danger states.
Elements: player portrait frame normal, player portrait frame low stability, stability bar frame, stability bar fill, backpack icon, weight badge, consumable slot empty, consumable slot locked, item pickup toast frame, interaction key prompt frame, outpost material bubble, outpost material bubble active, container timer badge, low stability warning corner, earphone signal icon, safe zone icon.
Requirements: transparent background, clean cutout edges, consistent line weight, suitable for Godot UI slicing.
Avoid: full HUD screenshot, text labels, watermark, overlapping elements.
```

---

## 15.3 可交互描边 Sheet

注意：

```text
可交互描边的正式实现优先使用 Shader 自动描边。
本 sheet 只用于定义描边风格、流光纹理、扫描线、闪烁形态和特殊叠加素材。
不要为不同容器形状生成固定边框 PNG。
```

```text
Create a transparent PNG VFX/UI sprite sheet for interactable object outline effects in a 2D top-down wasteland game.
Grid: 4x4, one outline style per cell, no labels.
Style: hand-drawn irregular outline, neon accent but controlled, dark manga wasteland UI.
Elements: subtle purple outline, active blue-purple outline, pulsing read-bar outline, warm yellow outpost-submit outline, white-grey safe outline, red countdown warning outline, disabled grey outline, repaired outpost warm outline.
Requirements: transparent background, abstract outline/VFX samples only, no complete object-specific frames, no object silhouettes, clean edges, suitable for shader reference, flow texture, scanline texture, or special overlay sprites.
Avoid: full objects, full UI mockup, container-shaped frames, safe-shaped frames, text, watermark, bright cyberpunk glow covering the asset.
```

---

## 15.4 撤离按钮 Sheet

```text
Create a transparent PNG UI sprite sheet for extraction button and progress states in a 2D wasteland extraction game.
Grid: 4x4, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black frame, worn metal, dirty paper texture.
Elements: extraction button empty, extraction button 25 percent progress, extraction button 50 percent progress, extraction button 75 percent progress, extraction button full progress, interrupted state, failed state, success state, green vertical gradient fill, black-green progress fill strip, warning red edge, key hold icon frame.
Color: progress fill is high-saturation dark green gradient from brighter green at top to deep black-green at bottom.
Requirements: transparent background, clean cutout edges, no readable text, suitable for Godot progress UI.
Avoid: full screen UI, glossy modern button, watermark, huge glow.
```

---

## 15.5 背包 / 容器 / 安全格子 Sheet

```text
Create a transparent PNG UI sprite sheet for inventory, loot container, and safe storage grid elements in a 2D wasteland extraction game.
Grid: 5x5, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, worn metal and dirty paper texture, grayscale base.
Elements: empty item slot, selected item slot, occupied item slot frame, locked slot, equipment slot frame, safe storage slot white-grey warm version, outpost safe slot repaired version, container loot slot dark version, rare item corner badge, material count badge, durability mini bar, weight badge, close button frame, confirm button frame, warning dialog frame.
Requirements: transparent background, consistent padding, clean cutout edges, reusable in Godot UI.
Avoid: full inventory screen, text labels, item illustrations mixed into slots, watermark.
```

---

## 15.6 局外导航与面板 Sheet

```text
Create a transparent PNG UI sprite sheet for out-of-run base interface elements in a 2D wasteland extraction game.
Grid: 4x4, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey panels, worn paper tabs, small warm yellow and blue-purple accents.
Elements: top navigation tab normal, top navigation tab selected, top navigation tab locked, warehouse panel frame, research panel frame, crafting panel frame, settlement panel frame, item detail panel, primary confirm button, secondary button, warning button, category filter chip, scroll bar handle, page title plaque.
Requirements: transparent background, clean cutout edges, consistent line width, suitable for slicing.
Avoid: full menu screenshot, readable text, watermark, modern flat UI.
```

---

## 15.7 研究所 / 制作所 Sheet

```text
Create a transparent PNG UI sprite sheet for research and crafting interface elements in a 2D wasteland extraction game.
Grid: 5x5, one element per cell, no labels.
Style: hand-drawn dark manga UI, old circuit diagram mixed with dirty paper and worn metal, grayscale base, blue-purple electronic accents, warm orange crafting lights.
Elements: research node locked, research node available, research node completed, research connection line, material requirement badge, blueprint badge, recipe card frame, crafting output frame, missing material warning badge, craft button active, craft button disabled, progress strip, completed stamp without text, small tool icon frame, small circuit icon frame.
Requirements: transparent background, no text, consistent line style, suitable for Godot slicing.
Avoid: full interface mockup, readable labels, watermark, bright sci-fi UI.
```

---

## 15.8 商人与货币 Sheet

```text
Create a transparent PNG UI sprite sheet for merchant selling and currency interface elements in a 2D wasteland extraction game.
Grid: 5x5, one element per cell, no labels.
Style: hand-drawn dark manga wasteland UI, dirty metal and paper panels, muted greys, controlled warm yellow accents, rough black outlines.
Elements: mine coin icon, small currency badge frame, price tag frame, sell button active, sell button disabled, quantity stepper minus, quantity stepper plus, total price strip, merchant item row frame, selected item row frame, disabled item row frame, sale success stamp without text, warning badge, small trade arrow icon, top currency bar frame.
Requirements: transparent background, no readable text, consistent line width, suitable for Godot slicing, disabled states clearly greyed out.
Avoid: full shop screenshot, bright fantasy gold coins, modern e-commerce UI, readable labels, watermark.
```

---

## 16. UI 模块拆分建议

推荐 Godot UI 资源目录：

```text
assets/ui/hud/
assets/ui/inventory/
assets/ui/container/
assets/ui/storage/
assets/ui/settlement/
assets/ui/base_nav/
assets/ui/research/
assets/ui/crafting/
assets/ui/outlines/
assets/ui/buttons/
```

推荐场景：

```text
RunHUD.tscn
InventoryPanel.tscn
EquipmentPanel.tscn
LootPanelUI.tscn
SafeStoragePanel.tscn
ExtractionHoldButton.tscn
SettlementPanel.tscn
BaseNavigationTabs.tscn
WarehousePanel.tscn
ResearchPanel.tscn
CraftingPanel.tscn
InteractionHighlightView.tscn
```

---

## 17. 交互描边功能落点

需要同步到功能文档：

```text
05_容器刷新与开箱系统：容器可交互描边规则。
06_前哨材料与前哨站修复系统：前哨站可交互与修复状态描边规则。
16_Godot工程结构与代码模块规划：InteractionHighlightView / InteractionHighlightService 模块。
```

功能判断：

```text
检测玩家是否进入交互范围，是功能。
决定对象当前是否可交互，是功能。
显示何种描边，是 UI / VFX。
描边颜色、sheet、shader，是 UI 资源。
```

---

## 18. 验收标准

UI sheet 验收：

```text
不是完整界面截图。
每个元素独立成格。
透明背景。
无文字、无水印、无 logo。
线宽统一。
颜色符合灰黑废土 UI。
高饱和颜色只用于功能提示。
切到 Godot 后边缘干净。
```

局内 UI 验收：

```text
玩家能一眼看到稳定值。
玩家能一眼看到背包负重。
玩家能一眼识别可交互容器和前哨站。
撤离进度清晰。
容器、背包、安全格子复用一致。
```

局外 UI 验收：

```text
顶部页签扩展空间足够。
仓库、商人、研究、制作视觉同源但能区分。
未开发完成页签置灰并禁止点击。
矿币数量显示清晰。
成功撤离界面能明确区分临时背包、仓库、确认入库。
遗弃警告足够明显。
```

---

## 19. 当前设计体检与建议

合理点：

```text
局内 UI 使用少量高饱和功能色，能在灰黑地图上快速识别。
背包、容器、安全格子复用，可以减少资源量。
交互描边能降低玩家识别成本，尤其适合灰黑复杂地图。
局外顶部页签能承载后续扩展。
```

风险：

```text
如果所有东西都有霓虹描边，玩家会失去重点。
如果 UI sheet 没有严格要求拆格，GPT 容易生成整张概念图。
如果字体太风格化，中文和日文会很难读。
```

建议：

```text
先生成 HUD sheet、格子 sheet、局外导航 sheet 三套基础资源。
交互描边优先用 Shader 自动贴合 Sprite alpha 轮廓，sheet 只做风格参考或特殊状态。
局外界面先做总体框架，再拆仓库、商人、研究、制作的细节控件。
```

---

## 20. 本文档结论

UI 资源生产的关键不是“画一张漂亮界面”，而是生成可切分、可复用、可进入 Godot 的资源 sheet。

第一批 UI 应优先完成：

```text
局内 HUD。
可交互描边。
撤离按钮。
背包 / 容器 / 安全格子。
局外页签导航。
成功撤离结算界面。
仓库、研究所、制作所基础面板。
```

只要这批资源风格统一，后续新增系统就可以沿同一套 UI 语言继续扩展。

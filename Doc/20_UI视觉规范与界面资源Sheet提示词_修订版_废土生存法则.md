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
左上角为角色状态区：角色头像框在最左，稳定值条紧贴头像右侧，头像框需要略微压在稳定值底框之上，但不能遮挡关键读数。
稳定值条必须保持当前批准的刻度与读数布局：`0 / 25 / 50 / 75 / 100`，从左到右递增；左上角头像框与稳定值条正式资源从 `assets/ui/run_character_hud/character_status/components/` 接入，稳定值填充通过裁剪填充条宽度动态表现。
顶部中央为局内倒计时，正式资源从 `assets/ui/run_timer_extraction_hud/components/` 接入；显示 `RunContext.run_duration_seconds` 的实际倒计时，默认局为 05:00，超级时间为 08:00，超短时间为 03:30；默认字体为灰白色，剩余时间小于等于 30 秒时变为灰红色并加深色描边。
倒计时下方为撤离状态条，正式资源从 `assets/ui/run_timer_extraction_hud/components/` 接入：两座前哨站修复完成前显示不可撤离 dot 和“不可撤离”；撤离解锁后切换可撤离 dot 和“可返回家中撤离”。文字必须代码渲染，不烘进 PNG。
左侧中部金黄色框改为目标链 HUD，不再以“I / II 未修复”作为主信息。三行固定排版且三行都不自动换行：第一行标题显示“当前目标：收集前哨站材料（菱形） n/N”，第二行显示“下一步：前哨站修复”，第三行显示“解锁撤离：未解锁/已解锁/可撤离”。外框需要横向放宽、纵向收紧，保证第一行完整显示。当材料足够时，第二行改为“下一步：长按修复前哨站”；修复中第一行改为“当前目标：修复前哨站 xx%”；修复完成后第一行改为“当前目标：撤离已解锁”，第二行改为“下一步：返回家中撤离”。HUD 不再使用小号菱形符号作为标题提示，改用“（菱形）”文字说明；地图中的前哨材料拾取物仍使用菱形图标。玩家在家中全图观察时目标链外框保持高可读性，离家进入近景探索后外框降低透明度，避免遮挡场景信息。文字必须代码渲染，不烘进 PNG。
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

当前局内 HUD 的默认角色使用 `assets/ui/run_character_hud/character_status/components/ui_run_character_portrait_male_01.png` 作为头像，叠放在 `ui_run_character_portrait_frame_empty_ref_01.png` 头像框下方，合成效果参考 `assets/ui/run_character_hud/character_status/previews/ui_run_character_portrait_male_preview_01.png`。头像和头像框都属于角色配置层：后续新增角色时，应通过角色配置提供自己的 `portrait_path` 与 `portrait_frame_path`，不要把具体角色资源硬编码到通用 HUD 布局里。

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
一个前哨站需求面板。
上方标题：前哨站。
下方一行：需要材料A：n/N        需要材料B：n/N。
修复前为灰色或低饱和面板。
可提交时边缘出现暖黄或蓝色轻微高亮。
提交完成时气泡变成安全白灰与暖光。
```

不要在面板内显示背包数量、调试字段或“包：0”等缩写。

前哨材料拾取物本体使用菱形图标：深色底层承托彩色填充，彩色填充比例表示该材料剩余存在时间。随着时间减少，填充逐渐减少；材料过期换点重刷后，新点位恢复完整填充。

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

## 7.6 怪物扇形视野 UI

怪物扇形视野是局内世界 UI，必须显示在地图上，不是 HUD 面板。

状态规则：

| 状态 | 表现 |
|---|---|
| 默认巡逻 | 淡绿色扇形，透明度低 |
| 玩家进入扇形 | 黄色警戒填充从 0% 增长 |
| 玩家持续 5 秒 | 黄色填满后转为红色 |
| 冲撞 | 红色扇形短暂保留，怪物冲向玩家 |

视觉要求：

```text
扇形边缘可以有轻微手绘抖动。
绿色必须淡，不要压过地图和拾取物。
黄色填充必须表达“正在累计危险”。
红色只在冲撞状态出现，避免常态过度紧张。
扇形 UI 必须跟随怪物朝向或警戒时锁向玩家。
文字计时不对普通玩家显示，只在 Debug 模式显示。
```

颜色建议：

```text
默认：#8BE07A，alpha 0.18
警戒：#E5C84A，alpha 0.30-0.45
冲撞：#D94A3A，alpha 0.45
```

---

## 7.7 场景随机事件提示

场景随机事件提示只在进入局内后的短时间内显示一次，不做常驻说明。

规则：

```text
默认局不显示事件提示。
超级时间显示：探索窗口延长至 8 分钟。
超短时间显示：暗潮提前压近，探索窗口缩短至 3 分 30 秒。
随机障碍显示：街道出现临时阻挡，请绕路探索。
怪物事件不额外弹窗，依靠地图中的怪物和扇形视野让玩家发现。
```

视觉：

```text
提示使用小型系统 toast，不占用目标链 HUD。
位置优先放在顶部倒计时下方或右侧，不遮挡左侧目标链。
显示 2-3 秒后淡出。
文字必须代码渲染，不烘进 PNG。
```

---

## 7.8 撤离按钮

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

当前 V0.1 局内背包打开界面规则（2026-05-10）：

```text
打开背包时固定使用右侧竖向面板，靠近右下角背包状态 HUD 向上展开，避免遮挡地图中心和角色；回到家中或进入前哨安全区后，背包仍在右侧展开。
背包、家中存储、前哨临时存储、容器内容共用同一套格子语言；家中 / 前哨存储面板显示在背包左侧。
当前实现允许先使用 Godot 代码绘制格子、面板、选中态和锁定态；正式切片资源到齐后替换 StyleBox，不改变转移逻辑。
背包外框高度按参考图使用较长竖向面板；格子区域铺满 5 列多行，超过当前容量的格子显示锁定 / 禁止使用状态，而不是直接不显示。
运行时格子显示物品名、数量和品质色；物品图标后续接入 128x128 透明 PNG 后，在格子内居中绘制。
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

### 8.3.1 当前库存 / 存储格子统一规则（2026-05-10）

背包打开界面、家中存储、修复后前哨站存储、局外仓库统一改为轻量格子设计：

```text
深色半透明面板。
细青色手绘格子描边，当前主线框色号为 #35C9D7。
少量黄色选中态。
锁定和不可用格子使用深灰描边与格内斜纹。
异常 / 无法放置状态使用低饱和红色描边。
物品图标、数量、容量、负重、售价和本地化文字由程序绘制，不烘进切图；整体 mockup 可临时显示文字用于评审，但切图资源不包含文字。
背包、家存储、前哨临时存储、局外仓库共用同一套 slot 资源。
背包打开界面顶部只显示标题“背包”和容量“容量：xx/xx”，不显示英文副标题。
分类页签使用连续的顶部页签导航，不使用互相分离的独立按钮框。
背包格子使用标准正方形，不做不规则外轮廓；按 grid_left + column * (slot_size + slot_gap)、grid_top + row * (slot_size + slot_gap) 平铺。
局内背包当前建议 slot_size 为 78px，slot_gap 为 12px。
```

局内打开背包固定靠右侧屏幕边缘显示，避免遮挡角色周围地图信息；家中存储和前哨存储使用“左侧存储 + 右侧背包”的双栏；局外仓库可使用更大的同源格子网格和右侧详情面板。

物品 icon 显示规范：

```text
原始 icon 建议为 128x128 透明 PNG。
在 78x78 背包格中居中显示，常规最大显示尺寸为 54x54。
格子内边缘至少保留 12px 安全距离。
窄长 icon 可放宽到最高 58px，但宽度仍应控制在 54px 内。
堆叠数量固定在右下角，不能压住 icon 主轮廓。
```

选中物品名称可根据品质显示颜色：

| 品质 | 名称文字色 |
|---|---|
| S | `#D1B850` |
| A | `#B9A9FF` |
| B | `#6FA8DC` |
| C | `#D8D6CE` |

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

进入局外 UI 前还有主菜单与玩家档案流程，详见 `Doc/25_主菜单玩家档案与剧情章节目标系统`。

主菜单 V0.1：

```text
左侧展示游戏 Logo（资源位：assets/ui/logos/black_tide_project/processed/）
背景：全屏循环 MP4 视频（assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4）
主按钮：开始游戏
次按钮：设置
首次开始游戏：弹出用户名输入
```

主菜单背景视频按 16:9 等比覆盖窗口，避免拉伸变形；视频自身静音，音频由 BGM 系统控制。

用户名输入弹窗：

```text
标题：创建档案
输入框：请输入你的名字
提示：2-12 个字符
按钮：确认 / 返回
```

剧情对白界面 V0.1：

```text
背景：当前流程背景暗化，或黑色/局外背景暗化。
左侧：404 哨所管理员半身原画。
右侧：主角半身原画。
底部：对白框、说话人名、对白正文、继续提示。
右上或对白框角落：跳过按钮。
```

对白原画规则：

```text
operator_404 默认显示 404 哨所管理员原画，位于左侧。
player 默认显示主角原画，位于右侧。
当前说话者 alpha 1.0，轻微提亮或描边。
未说话者 alpha 0.35-0.5，降低饱和度。
首次返回玩家独白只显示主角原画，不显示管理员。
窄屏只显示当前说话者，优先保证对白文本完整可读。
角色原画不烘焙进对白框背景，必须作为独立 PNG 叠放。
```

详细规则见 `Doc/25_主菜单玩家档案与剧情章节目标系统/08_剧情对白角色原画显示规则.md`。

章节目标卡：

```text
第一章目标
救出妹妹
解锁制造所
出售可售物资，积攒 5000 矿币。
按钮：知道了 / 前往商人
```

第一章结束弹窗：

```text
第一章结束
你用了 {surface_day} 天，成功购买了旧时代制造机。
也许，救出妹妹的路终于有了第一盏灯。
按钮：进入制造所 / 继续整理
```

出发进入对局加载界面 V0.1：

```text
标题：正在前往地面
阶段文本：同步地表地图...
进度：42%
提示：前哨材料以菱形标记，收集足够后优先修复前哨站。
```

加载完成态：

```text
标题：正在前往地面
阶段文本：按下任意按钮继续
进度：100%
操作提示：WASD 移动 / Tab 背包 / F 拾取与交互 / E 撤离
机制提示：暗潮会压缩视野，稳定值会持续下降；回到基地后稳定值会恢复。
```

加载界面排版：

```text
全屏暗色背景。
标题在中上区域，字号大于阶段文本。
阶段文本位于进度条上方。
横向进度条位于屏幕下半区，宽度约为屏幕 40%-55%。
百分比可放在进度条右侧或条内右端。
操作提示位于进度条下方，可用键帽式小框分组。
机制提示位于底部，只显示一到两行短句。
```

加载界面交互规则：

```text
加载中不显示跳过按钮。
加载中屏蔽局内移动、交互、背包等输入。
加载完成后不自动淡入局内。
加载完成后阶段文本改为“按下任意按钮继续”。
玩家按任意按钮后才淡入局内。
加载失败时显示“地表通道同步失败，请返回哨所重试。”并返回出发准备界面。
文字必须由 Godot UI 渲染，不烘焙进 PNG。
```

顶层结构：

```text
顶部页签导航。
主内容区域。
右侧详情区域，可选。
底部操作区。
全局资源提示区。
TooltipLayer，位于所有局外面板之上。
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
V0.1 局外顶部页签顺序为：仓库、商人、研究所、制造所/制作所。
顶部或右上角显示当前矿币数量。
```

---

## 10. 成功撤离与结算界面

内容：

```text
全屏黑色背景。
结果主文案。
物资列表标题。
物资展示区。
返回哨所按钮。
```

成功结算：

```text
主文案：成功返回404哨所
物资标题：本次获得的物资
按钮：返回哨所
```

失败结算：

```text
主文案：你已被黑潮吞噬，将在404重塑躯体。
物资标题：本局带出的物资
空状态：没有带回任何物资
按钮：返回哨所
```

规则：

```text
玩家点击返回哨所后，不直接切回局外。
必须进入返回哨所 loading。
返回 loading 到 100% 后显示“按下任意按钮继续”。
玩家按任意按钮后才回到局外哨所界面。
如果存在未处理或仓库溢出的物资，点击返回哨所前必须处理或弹确认。
```

视觉：

```text
背景必须全黑，避免结算时还能看到局内地图。
成功主文案使用灰白或偏暖白。
失败主文案使用灰白，可有极轻的红黑边缘。
物资卡片使用低亮度灰黑底，不做明亮卡片墙。
返回哨所按钮使用暗金/灰白边框。
```

返回哨所 loading：

```text
标题：正在返回404哨所
阶段文本：同步哨所记录...
进度：42%
完成态阶段文本：按下任意按钮继续
完成态提示：物资已同步至哨所记录。
失败返回完成态提示：躯体重塑完成，保留物资已同步。
```

---

## 11. 仓库界面

内容：

```text
仓库格子。
物品分类筛选。
排序按钮。
物品详情。
道具图标 hover 详情 Tooltip。
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
道具图标 hover 详情 Tooltip。
```

规则：

```text
商人页签从局外顶部第二个页签进入。
未选择物品时出售按钮禁用。
出售数量小于 1 或大于拥有数量时出售按钮禁用。
不可出售物品不显示，或显示为置灰不可选。
数量变化后总价实时更新。
出售成功后刷新仓库数量和矿币显示。
物品图标 hover 时显示局外道具详情 Tooltip；Tooltip 显示单价，不显示本次出售总价。
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

## 11.6 局外道具详情 Tooltip

适用范围：

```text
局外仓库物品图标。
商人可出售物品图标。
商人确认区物品图标。
研究所材料需求图标。
制作所材料需求和产物预览图标。
后续出发准备、装备页签中的局外道具图标。
```

不适用：

```text
局内背包。
局内容器。
局内拾取提示。
撤离结算界面。
主菜单。
```

布局：

```text
接近黑色半透明底。
细蓝绿色描边。
顶部居中道具图标。
中部左侧道具名。
中部右侧单价或“不可出售”。
一条细分隔线。
底部道具描述，自动换行。
```

尺寸：

```text
1280x720：宽 224，高 260，图标 72。
1600x900：宽 240，高 280，图标 80。
1920x1080：宽 260，高 300，图标 88。
边距 14-16。
圆角 0-2，保持硬边废土 UI。
```

交互：

```text
hover 0.15 秒显示。
鼠标离开、拖拽、滚动、切页、弹窗打开、离开局外时隐藏。
默认显示在图标右侧 16 px；右侧空间不足时翻到左侧。
上下必须夹取在屏幕内，离窗口边缘至少 16 px。
Tooltip 本身不拦截鼠标输入，避免 hover 抖动。
```

视觉限制：

```text
主边框统一使用蓝绿色，不随品质大面积变红。
SS 道具可以在名称左侧小点、图标阴影或小标签上体现红色品质。
不要把描述文字烘焙进 PNG。
不要做高亮商业卡牌风格。
```

详细功能规则见：

```text
Doc/09_局外仓库系统/18_局外道具详情Tooltip.md
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
材料图标 hover 详情 Tooltip。
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
材料与产物图标 hover 详情 Tooltip。
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

## 15.5.1 剧情对白 UI Sheet

```text
Create a transparent PNG UI sprite sheet for story dialogue interface elements in a 2D wasteland extraction game.
Grid: 4x4, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black ink outlines, dirty worn metal and paper, grayscale base, muted blue-purple and warm yellow accents.
Elements: wide bottom dialogue box frame, speaker nameplate active, speaker nameplate inactive, next indicator, skip button frame, portrait shadow plate left, portrait shadow plate right, active speaker glow edge, inactive speaker dim overlay, important keyword highlight strip, dialogue choice button normal, dialogue choice button selected, small warning note frame, black background dim overlay sample.
Requirements: transparent background, clean cutout edges, reusable in Godot UI, no readable text, no character portraits inside the sheet.
Avoid: full dialogue screenshot, baked character art, visual novel glossy UI, readable labels, watermark.
```

角色原画本身不放入 UI Sheet，按 `Doc/17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md` 的角色原画规格单独生成。

---

## 15.6 局外导航与面板 Sheet

```text
Create a transparent PNG UI sprite sheet for out-of-run base interface elements in a 2D wasteland extraction game.
Grid: 4x4, one element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey panels, worn paper tabs, small warm yellow and blue-purple accents.
Elements: top navigation tab normal, top navigation tab selected, top navigation tab locked, warehouse panel frame, research panel frame, crafting panel frame, settlement panel frame, item detail panel, out-of-run item tooltip panel with thin teal border, primary confirm button, secondary button, warning button, category filter chip, scroll bar handle, page title plaque.
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
assets/ui/item_tooltip/
assets/ui/loading/
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
ItemTooltipPanel.tscn
RunLoadingScreen.tscn
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
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 20_UI视觉规范与界面资源Sheet提示词.md
  作为 开发者
  我希望按本文规则完成 20_UI视觉规范与界面资源Sheet提示词.md
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "Doc 顶层专题"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。

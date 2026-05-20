# 21_UI资源Sheet生成清单与提示词包.md

# 《废土生存法则》UI资源 Sheet 生成清单与提示词包

> 文档版本：v0.1  
> 依据文档：20_UI视觉规范与界面资源Sheet提示词_修订版_废土生存法则.md / 17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md  
> 适用目标：先生成局内、局外各系统整体设计稿，再从整体设计稿拆出高精度可切分 UI sheet。  
> 输出原则：整体设计稿用于统一风格和布局；拆分 sheet 用于 Godot 实际切图，不允许混为一张。

---

## 1. 生产总原则

UI 资源分两层生成：

```text
第一层：系统整体设计稿
用途：确定布局、信息层级、视觉气质、模块比例。
允许：完整界面 mockup、示意文字、状态演示。
禁止：直接当作可切分资源使用。

第二层：高精度 UI 拆分 sheet
用途：Godot 切图、九宫格、按钮状态、图标、格子、面板复用。
允许：透明背景、网格排列、单格单元素。
禁止：完整界面截图、说明文字、序号、水印、元素重叠。
```

核心风格锚点：

```text
灰黑手绘漫画线稿。
粗黑描边。
脏旧纸面。
磨损金属。
低饱和灰色主色。
小面积紫色、蓝色、红色、暖黄、安全绿功能色。
边缘略不规则，但读数清晰。
```

当前库存 / 存储格子规则（2026-05-10）：

```text
背包打开界面、家中存储、修复后前哨站存储、局外仓库统一使用轻量格子设计。
参考方向：深色半透明面板，细青色手绘格子描边（主线框 #35C9D7），少量黄色选中态，深灰锁定态，低饱和红色异常态。
物品图标、数量、容量、负重、售价和本地化文字由程序绘制，不烘进可切资源。
背包、家存储、前哨临时存储、局外仓库优先共用同一套 slot、面板边框、容量条和筛选 chip 资源。
背包格子必须是标准正方形，便于按坐标平铺复用；不要生成每个格子轮廓都不同的不规则框。
背包分类页签必须是连续顶部页签导航，不要生成分离的独立小框。
背包 item icon 原始资源建议 128x128 透明 PNG；在 78x78 格子中居中显示，常规最大显示 54x54。
```

---

## 2. Sheet 生产批次

建议按以下批次生成，先锁定基础控件，再扩展系统差异。

| 批次 | 类型 | 目标 | 尺寸建议 |
|---|---|---|---|
| UI-00 | UI 风格基准板 | 统一按钮、面板、格子、功能色、描边强度 | 2048x2048 |
| UI-01 | 局内 HUD 整体设计稿 | 确定局内信息层级和遮挡控制 | 1920x1080 |
| UI-02 | 局内 HUD 拆分 sheet | 头像、稳定值、负重、快捷栏、提示框 | 2048x2048 |
| UI-03 | 可交互与读条 VFX sheet | 描边风格、读条、容器倒计时、前哨提交反馈 | 2048x2048 |
| UI-04 | 背包/容器/安全格子整体稿 | 统一格子系统和面板结构 | 1920x1080 |
| UI-05 | 背包/容器/安全格子拆分 sheet | 格子、装备槽、详情面板、关闭/确认按钮 | 2048x2048 |
| UI-06 | 撤离与结算整体设计稿 | 成功撤离、入库、遗弃警告流程 | 1920x1080 |
| UI-07 | 撤离与结算拆分 sheet | 撤离按钮状态、结算面板、警告弹窗 | 2048x2048 |
| UI-08 | 局外基地整体框架设计稿 | 昼夜阶段、白天入口、主内容、右侧详情、底部操作 | 1920x1080 |
| UI-09 | 局外导航与通用面板 sheet | 功能入口、按钮、筛选、滚动条、标题牌 | 2048x2048 |
| UI-09A | 剧情对白界面与控件 sheet | 底部对白框、说话人名牌、跳过、继续提示、原画阴影底 | 2048x2048 |
| UI-10 | 仓库系统整体稿 | 仓库格、分类筛选、物品详情、整理操作 | 1920x1080 |
| UI-11 | 仓库系统拆分 sheet | 仓库专用格子、分类 chip、排序按钮、容量条 | 2048x2048 |
| UI-12 | 店铺货台与需求整体稿 | 需求榜、货台格、可售物资、成交反馈、矿币栏 | 1920x1080 |
| UI-13 | 店铺货台与货币拆分 sheet | 矿币 icon、货台格、需求榜、上架按钮、成交条目 | 2048x2048 |
| UI-14 | 研究所整体稿 | 节点线路图、需求、进度、前置条件 | 1920x1080 |
| UI-15 | 研究所拆分 sheet | 研究节点、连接线、完成标记、需求徽章 | 2048x2048 |
| UI-16 | 制作所整体稿 | 配方列表、产物预览、材料需求、制作状态 | 1920x1080 |
| UI-17 | 制作所拆分 sheet | 配方卡、产物框、工具灯、制作按钮状态 | 2048x2048 |
| UI-18 | 出发准备整体稿 | 角色预览、装备槽、背包选择、确认出发 | 1920x1080 |
| UI-19 | 出发准备拆分 sheet | 装备槽、锁定槽、开始按钮、角色底座 | 2048x2048 |
| UI-20 | 通用图标 sheet | 系统入口、资源分类、状态角标、稀有度 | 2048x2048 |

---

## 3. 通用负面提示词

所有 UI 生成任务都追加：

```text
Avoid: photorealistic UI, glossy 3D render, cute cartoon, candy UI, clean SaaS interface, high-saturation cyberpunk full screen, complex painting panels, readable text in sliced assets, watermark, logo, labels, serial numbers, overlapping elements, cropped elements, inconsistent perspective, inconsistent line width.
```

拆分 sheet 额外追加：

```text
Output must be a transparent PNG sprite sheet. Every cell contains exactly one isolated UI element. No complete interface screenshot. No explanatory labels. No mockup text. Clean cutout edges. Consistent padding. Suitable for slicing into Godot UI sprites.
```

整体设计稿额外追加：

```text
This is a full interface visual design mockup for layout reference only. It may include placeholder UI text blocks and numbers for composition, but it must remain readable and game-like. Do not create marketing art or a loading screen.
```

---

## 4. UI-00 风格基准板

用途：第一张先做风格锚点，后续所有 UI sheet 都参考它。

```text
Create a full UI style board for a 2D wasteland extraction game named "Wasteland Survival Rules".
Output type: complete UI style board mockup, not a sliced asset sheet.
Canvas: 2048x2048.
Style: dark hand-drawn manga UI, thick black ink outlines, rough dirty paper texture, worn grey metal, charcoal and grayscale base, controlled accents of neon purple, electric blue, muted red, warm yellow, and dark extraction green.
Content: sample panel frames, navigation tabs, inventory slots, item detail panel, warning dialog, extraction progress button, stability bar, small icon frames, research node samples, crafting recipe card samples, selected and locked states, low stability danger state.
Layout: clean design board with grouped UI components, consistent spacing, consistent line weight, clear visual hierarchy.
Requirement: establish one unified visual language for all in-run and out-of-run UI systems.
Avoid: modern clean SaaS UI, glossy 3D buttons, full gameplay screenshot, photorealism, cute fantasy UI, large cyberpunk neon glow, watermark, logo.
```

---

## 5. UI-01 局内 HUD 整体设计稿

```text
Create a full in-run HUD interface mockup for a 2D top-down wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey paper and worn metal panels, grayscale base, small purple-blue interaction accents, muted red danger accents, dark green extraction progress accents.
Scene context: the UI floats over a dark grey top-down ruined city map, but the focus is the HUD layout.
HUD elements: top-left player portrait frame, stability bar with normal and low state hint, in-run countdown timer, backpack entry icon, current weight display, consumable quick slots, earphone signal icon placeholder, interact key prompt, container remaining timer badge, outpost material bubble, item pickup toast, low stability warning edge, extraction hold button with green progress.
Layout rule: minimal map obstruction, danger information has highest priority, backpack and interaction feedback are clear but compact.
Requirement: full interface visual design mockup for layout and hierarchy reference only.
Avoid: sliced asset sheet, marketing splash art, oversized decorative panels, readable brand logos, photorealism, glossy UI, cute cartoon style.
```

---

## 6. UI-02 局内 HUD 高精度拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for in-run HUD elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels, no numbers.
Style: dark hand-drawn manga UI, thick black ink outlines, dirty grayscale paper, worn grey metal, small neon purple and electric blue accents, muted red only for danger states.
Elements: player portrait frame normal, player portrait frame low stability cracked, player portrait frame safe warm light, stability bar frame, stability bar fill normal, stability bar fill low, stability bar fill critical, countdown timer frame, backpack icon, weight badge normal, weight badge warning, consumable slot empty, consumable slot locked, consumable slot selected, earphone signal icon, interaction key prompt frame, container timer badge, outpost material bubble inactive, outpost material bubble active, item pickup toast frame, low stability warning corner, safe zone icon, backpack full warning badge, small close button frame, compact system message frame.
Requirements: transparent background, clean cutout edges, consistent padding, consistent line weight, each element fully visible, suitable for Godot slicing.
Avoid: full HUD screenshot, text labels, watermark, overlapping elements, item illustrations mixed into slot frames.
```

---

## 7. UI-03 可交互与读条 VFX Sheet

注意：普通容器和前哨站外描边正式实现优先使用 Shader。本 sheet 只定义流光、扫描线、特殊状态纹理和 UI/VFX 风格。

```text
Create a transparent PNG VFX and UI sprite sheet for interactable object feedback in a 2D top-down wasteland extraction game.
Canvas: 2048x2048.
Grid: 4x4, evenly spaced cells, one abstract effect element per cell, no labels.
Style: hand-drawn irregular outline samples, controlled neon accents, dark manga wasteland UI, thick but not excessive black ink edges, rough texture.
Elements: subtle dark purple interactable outline sample, active blue-purple outline sample, pulsing read-bar outline sample, warm yellow outpost material-submit outline sample, white-grey repaired safe outline sample, red countdown warning outline sample, disabled grey outline sample, thin scanline texture, flowing edge light texture, circular hold progress ring, linear read progress strip, container expiring warning flare, repair completed warm flash, small material submit pulse, safe storage success shimmer, interaction interrupted break mark.
Requirements: transparent background, abstract outline and VFX samples only, no complete object-specific frames, no container silhouettes, no safe-house silhouettes, clean edges, suitable for shader reference or overlay sprites.
Avoid: full objects, full UI mockup, fixed container-shaped borders, fixed outpost-shaped borders, readable text, watermark, huge cyberpunk glow.
```

---

## 8. UI-04 背包 / 容器 / 安全格子整体设计稿

```text
Create a full interface mockup showing the shared inventory, loot container, and safe storage UI system for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey panels, worn metal and paper texture, purple-blue selection accents, muted red warning accents, warm grey safe storage accents.
Content: player backpack grid, equipment slots labeled by shape only, current weight area, item detail panel, loot container panel with remaining timer, safe storage panel variant, close button, confirm button, warning state, selected item state.
Layout rule: demonstrate that backpack, container, and safe storage reuse the same grid language while color accents distinguish risk, safety, and selection.
Requirement: full interface visual design mockup for layout and visual consistency reference only.
Avoid: sliced asset sheet, clean modern inventory UI, fantasy RPG ornament, photorealism, unreadable clutter, oversized decorative art.
```

---

## 9. UI-05 背包 / 容器 / 安全格子拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for inventory, loot container, equipment, and safe storage grid elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, worn metal, dirty paper texture, grayscale base, small purple-blue selection accents, warm grey and warm yellow safe accents, muted red warning accents.
Elements: empty item slot, selected item slot, occupied item slot frame, locked slot, equipment slot frame, equipment slot selected, safe storage slot warm white-grey, repaired outpost storage slot, container loot slot dark version, rare item corner badge, material count badge, durability mini bar, weight badge normal, weight badge overweight red, item detail panel frame, compact item tooltip frame, close button frame, confirm button frame, secondary button frame, warning dialog frame, drag ghost frame, invalid drop marker, split stack mini panel, category filter chip, scrollbar handle.
Requirements: transparent background, clean cutout edges, consistent line weight, consistent padding, reusable in Godot UI, no readable text.
Avoid: full inventory screen, item illustrations mixed into slots, labels, watermark, overlapping elements.
```

---

## 10. UI-06 撤离与结算整体设计稿

```text
Create a full extraction success and settlement interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, grey worn metal panels, dirty paper texture, safety green progress accents, warm yellow confirm accents, red abandonment warning accents.
Content: successful extraction title area, temporary backpack panel, safe storage content panel, warehouse destination panel, manual transfer layout, one-click store button, confirm storage button, abandoned item warning dialog, return to base button.
Layout rule: clearly separate temporary backpack, safe storage, and warehouse. The warning dialog must feel serious and irreversible.
Requirement: full interface visual design mockup for flow and hierarchy reference only.
Avoid: sliced asset sheet, celebratory bright mobile game UI, glossy 3D, cute cartoon, full map screenshot, unreadable clutter.
```

---

## 11. UI-07 撤离与结算拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for extraction button, extraction progress states, settlement panels, and warning dialogs in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 4x4, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black ink outlines, worn metal, dirty paper, grayscale base, dark green extraction gradient, warm yellow confirm accents, muted red warning accents.
Elements: extraction hold button empty, extraction hold button 25 percent progress, extraction hold button 50 percent progress, extraction hold button 75 percent progress, extraction hold button full progress, extraction interrupted state, extraction failed state, extraction success state, vertical green progress fill strip, black-green horizontal progress fill strip, settlement panel frame, temporary backpack panel frame, warehouse transfer panel frame, confirm storage button frame, abandonment warning dialog frame, return to base button frame.
Color rule: extraction progress fill uses high-saturation dark green gradient from brighter green at top to deep black-green at bottom.
Requirements: transparent background, clean cutout edges, consistent line weight, suitable for Godot progress UI and nine-slice panels, no readable text.
Avoid: full screen UI, glossy modern buttons, huge glow, labels, watermark, overlapping elements.
```

---

## 12. UI-08 局外基地整体框架设计稿

```text
Create a full out-of-run base interface framework mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey panels, worn paper tabs, worn metal frames, small warm yellow and purple-blue accents.
Content: day prep function entries for warehouse, crafting, research, catalog, daily demand panel, global mine coin indicator area, main content region, optional right detail panel, bottom action bar, night departure state placeholder.
Layout rule: day prep entries must appear in this order: warehouse, crafting, research, catalog. Current selected entry has clear purple-blue or warm yellow hand-drawn highlight. Unfinished entries are visible but greyed out and disabled.
Requirement: full interface visual design mockup for the base UI shell, not a sliced sheet.
Avoid: modern SaaS dashboard, clean sci-fi, marketing landing page, glossy UI, photorealistic room background, oversized decorative illustration.
```

---

## 13. UI-09 局外导航与通用面板 Sheet

```text
Create a transparent PNG UI sprite sheet for out-of-run base navigation and reusable panel elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 4x4, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey paper panels, worn metal frames, small warm yellow and blue-purple accents.
Elements: function entry normal, function entry selected, function entry locked, page title plaque, large main panel frame, right detail panel frame, bottom action bar frame, global resource badge frame, primary confirm button frame, secondary button frame, warning button frame, category filter chip, small icon button frame, scrollbar track, scrollbar handle, disabled button frame.
Requirements: transparent background, clean cutout edges, consistent line width, suitable for slicing and nine-slice usage in Godot, no readable text.
Avoid: full menu screenshot, labels, watermark, modern flat UI, glossy 3D, overlapping elements.
```

---

## 13.5 UI-09A 剧情对白界面与控件 Sheet

```text
Create a transparent PNG UI sprite sheet for story dialogue interface elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 4x4, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black ink outlines, dirty worn metal and paper, grayscale base, muted blue-purple and warm yellow accents.
Elements: wide bottom dialogue box frame, speaker nameplate active, speaker nameplate inactive, next indicator, skip button frame, portrait shadow plate left, portrait shadow plate right, active speaker glow edge, inactive speaker dim overlay, important keyword highlight strip, dialogue choice button normal, dialogue choice button selected, small warning note frame, black background dim overlay sample.
Requirements: transparent background, clean cutout edges, reusable in Godot UI, no readable text, no character portraits inside the sheet.
Avoid: full dialogue screenshot, baked character art, visual novel glossy UI, labels, watermark.
```

角色原画不放在 UI-09A 中，主角和 404 哨所管理员半身原画按角色资源规格单独生成。

---

## 14. UI-10 仓库系统整体设计稿

```text
Create a full warehouse interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, grey worn warehouse panels, dirty paper texture, purple-blue selected item accents, small rare item color corner marks.
Content: warehouse grid, category filters, sorting button, capacity display, item detail panel, selected item state, one-click store button, organize button, rare material highlight, disabled action state.
Layout rule: dense but readable, made for repeated item management, no oversized hero art.
Requirement: full interface visual design mockup for warehouse layout reference only.
Avoid: sliced sheet, clean mobile inventory, fantasy ornament, photorealism, glossy 3D, unreadable clutter.
```

---

## 15. UI-11 仓库系统拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for warehouse-specific UI elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey panels, worn storage metal, paper texture, purple-blue selection accents, small rare color accents.
Elements: warehouse empty slot, warehouse selected slot, warehouse occupied frame, warehouse locked capacity slot, capacity display frame, category chip all, category chip materials, category chip equipment, category chip consumables, category chip blueprint, category chip rare goods, sort button frame, organize button frame, one-click store button frame, item detail panel frame, item rarity corner common, item rarity corner uncommon, item rarity corner rare, item rarity corner special, stack count badge, transfer arrow button, disabled transfer marker, storage success toast frame, warehouse warning toast frame, small search field frame.
Requirements: transparent background, clean cutout edges, consistent line weight, no readable text, suitable for Godot slicing.
Avoid: full warehouse screen, item illustrations, labels, watermark, overlapping elements.
```

---

## 16. UI-12 店铺货台与需求整体设计稿

```text
Create a full shop shelf and daily demand interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, dirty grey shelf panels, worn paper demand tags, muted warm yellow currency accents, controlled purple-blue selection accents.
Content: daily demand ranking panel, three initial shelf slots, shelf item cards, sale_good item list, selected item detail, item icon, owned count, estimated base price, mine coin currency display, put-on-shelf button active and disabled states, shop settlement toast.
Layout rule: practical out-of-run shop operation screen, no buy shop, no market board, no decorative storefront hero art.
Requirement: full interface visual design mockup for shop shelf layout reference only.
Avoid: sliced sheet, fantasy shop UI, shiny gold coins, e-commerce layout, photorealism, glossy 3D, readable generated text.
```

---

## 17. UI-13 店铺货台与货币拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for shop shelf and currency interface elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: hand-drawn dark manga UI, dirty paper and worn metal, muted grey base, rough black outlines, small warm yellow mine coin accents.
Elements: mine coin icon, currency badge frame, shelf slot empty, shelf slot selected, shelf slot locked, demand rank row normal, demand rank row highlighted, put-on-shelf button active frame, put-on-shelf button disabled frame, settlement total strip, shelf item row normal, shelf item row selected, sold success toast frame, sale failure toast frame, deal arrow icon, top currency bar frame, small coin stack icon, selected price glow, warning mini badge, disabled grey overlay.
Requirements: transparent background, no text, clean cutout edges, consistent line style, disabled states clearly greyed out, suitable for Godot slicing.
Avoid: full shop screen, readable labels, watermark, bright fantasy gold, modern e-commerce icons, glossy 3D.
```

---

## 18. UI-14 研究所整体设计稿

```text
Create a full research lab interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, old circuit diagram mixed with dirty paper and worn metal, grayscale base, blue-purple electronic accents, warm yellow completed node accents.
Content: research node map, locked nodes, available nodes, completed nodes, connection lines, research category panel, research detail panel, material requirement area, current progress strip, submit button, prerequisite warning.
Layout rule: the research tree should feel like a hand-drawn old electrical circuit, readable and game-functional.
Requirement: full interface visual design mockup for research layout reference only.
Avoid: sliced sheet, bright sci-fi hologram UI, clean tech dashboard, photorealism, huge glowing effects, unreadable tiny nodes.
```

---

## 19. UI-15 研究所拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for research interface elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: hand-drawn dark manga UI, old circuit diagram, dirty paper, worn grey metal, thick black outlines, blue-purple electronic accents, warm yellow completed accents.
Elements: research node locked, research node available, research node selected, research node completed, research node blocked, straight connection line, corner connection line, broken connection line, glowing completed connection line, material requirement badge, prerequisite badge, research progress strip empty, research progress strip filled, submit button active frame, submit button disabled frame, completed stamp without text, blueprint badge, small circuit icon frame, research category chip, detail panel frame, warning mini badge, available pulse ring, locked grey overlay, node hover frame, compact tooltip frame.
Requirements: transparent background, clean cutout edges, consistent line style, no text, suitable for Godot slicing.
Avoid: full interface mockup, readable labels, watermark, bright sci-fi UI, overlapping elements.
```

---

## 20. UI-16 制作所整体设计稿

```text
Create a full crafting workshop interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, grey worn metal workbench panels, dirty paper texture, warm orange repair lights, warm yellow craft-ready accents, muted red missing-material warning accents.
Content: recipe list, category filters, selected recipe card, output preview frame, material requirements, craft button, missing material warning, unlocked and locked recipes, progress strip.
Layout rule: utilitarian workshop feeling, compact and repeated-use friendly, visually related to warehouse but warmer and more tool-like.
Requirement: full interface visual design mockup for crafting layout reference only.
Avoid: sliced sheet, fantasy crafting book, clean modern app, photorealism, glossy 3D, oversized decorative illustration.
```

---

## 21. UI-17 制作所拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for crafting workshop interface elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: hand-drawn dark manga UI, thick black outlines, worn metal, dirty paper, grayscale base, warm orange repair lights, warm yellow active crafting accents, muted red missing-material accents.
Elements: recipe card normal, recipe card selected, recipe card locked, recipe card craftable, recipe card missing material, crafting output frame, material requirement badge satisfied, material requirement badge missing, craft button active frame, craft button disabled frame, craft progress strip empty, craft progress strip filled, completed output stamp without text, small tool icon frame, workshop category chip, unlock condition badge, warning mini badge, preview panel frame, recipe list frame, quantity stepper button, small orange work light icon, repair tape corner, disabled grey overlay, success toast frame, failure toast frame.
Requirements: transparent background, no text, clean cutout edges, consistent line style, suitable for Godot slicing.
Avoid: full interface mockup, readable labels, watermark, bright fantasy colors, glossy 3D.
```

---

## 22. UI-18 出发准备整体设计稿

```text
Create a full expedition preparation interface mockup for a 2D wasteland extraction game.
Canvas: 1920x1080.
Style: dark hand-drawn manga UI, thick black outlines, grey worn equipment panels, dirty paper texture, small purple-blue electronics, warm yellow ready accents, muted red danger-start accents.
Content: character preview area, equipment slots for head body hand leg back special by shape only, backpack selection panel, consumable slots initially locked, earphone slot placeholder locked, current weight display, start exploration button, readiness warning.
Layout rule: character area is slightly brighter, equipment slots are clear and reusable, start button feels serious and dangerous.
Requirement: full interface visual design mockup for expedition prep layout reference only.
Avoid: sliced sheet, character gacha screen, clean sci-fi loadout, fantasy ornament, glossy 3D, oversized hero art.
```

---

## 23. UI-19 出发准备拆分 Sheet

```text
Create a transparent PNG UI sprite sheet for expedition preparation interface elements in a 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 5x5, evenly spaced cells, one UI element per cell, no labels.
Style: dark hand-drawn manga UI, thick black outlines, grey worn equipment panels, dirty paper, worn metal, small purple-blue electronic accents, warm yellow ready accents, muted red danger-start accents.
Elements: character preview frame, character base shadow frame, head equipment slot, body equipment slot, hand equipment slot, leg equipment slot, back equipment slot, special equipment slot, equipment slot selected, equipment slot locked, backpack selection frame, backpack selected frame, consumable slot locked, consumable slot empty, earphone slot locked, weight display frame, readiness warning badge, start exploration button normal, start exploration button ready, start exploration button disabled, loadout warning dialog frame, small remove equipment button, small swap equipment button, equipment detail panel, compact requirement badge.
Requirements: transparent background, no text, clean cutout edges, consistent line style, suitable for Godot slicing.
Avoid: full interface mockup, readable labels, character illustration inside frame, watermark, glossy 3D.
```

---

## 22. UI-18 通用系统图标 Sheet

```text
Create a transparent PNG UI icon sprite sheet for a dark hand-drawn 2D wasteland extraction game.
Canvas: 2048x2048.
Grid: 8x8, evenly spaced cells, one icon per cell, no labels.
Style: rough black ink line icons, dirty grayscale fill, readable silhouette at 32x32, small purple or blue accent only when useful, warm yellow for safe or completed states, muted red for danger states, dark green for extraction.
Elements: backpack, warehouse, research, crafting, expedition prep, equipment, consumable, material, blueprint, rare goods, safe storage, extraction, home safe zone, repaired outpost, broken outpost, container loot, timer, warning, low stability, stability recovery, overweight, locked, unlocked, selected, completed, missing material, submit material, transfer item, sort, filter, close, confirm, cancel, one-click store, organize, earphone signal, signal weak, signal strong, item pickup, item discard, return to base, progress hold, danger area, safe area, repair, tool, circuit, battery, medicine, food, scrap metal, cloth, electronic part, small gear, key prompt, info, settings, reserved locked tab, toast success, toast failure, toast warning, rare corner marker, disabled state.
Requirements: transparent background, clean cutout edges, consistent icon stroke weight, no readable text, no watermark, no overlapping icons.
Avoid: app store icons, glossy 3D, colorful cartoon icons, photorealism, complex illustration backgrounds.
```

---

## 23. Godot 资源目录建议

```text
res://assets/ui/_style/ui_style_board_01.png
res://assets/ui/hud/sheets/ui_hud_sheet_01.png
res://assets/ui/outlines/sheets/ui_interaction_vfx_sheet_01.png
res://assets/ui/inventory/sheets/ui_inventory_container_storage_sheet_01.png
res://assets/ui/extraction/sheets/ui_extraction_settlement_sheet_01.png
res://assets/ui/base_nav/sheets/ui_base_nav_panels_sheet_01.png
res://assets/ui/warehouse/sheets/ui_warehouse_sheet_01.png
res://assets/ui/research/sheets/ui_research_sheet_01.png
res://assets/ui/crafting/sheets/ui_crafting_sheet_01.png
res://assets/ui/prep/sheets/ui_expedition_prep_sheet_01.png
res://assets/ui/icons/sheets/ui_system_icons_sheet_01.png
```

整体设计稿建议放入：

```text
res://assets/ui/_mockups/ui_hud_mockup_01.png
res://assets/ui/_mockups/ui_inventory_container_storage_mockup_01.png
res://assets/ui/_mockups/ui_extraction_settlement_mockup_01.png
res://assets/ui/_mockups/ui_base_shell_mockup_01.png
res://assets/ui/_mockups/ui_warehouse_mockup_01.png
res://assets/ui/_mockups/ui_research_mockup_01.png
res://assets/ui/_mockups/ui_crafting_mockup_01.png
res://assets/ui/_mockups/ui_expedition_prep_mockup_01.png
```

---

## 24. 切图与命名规则

拆出单件后按模块命名：

```text
ui_hud_portrait_frame_normal.png
ui_hud_portrait_frame_low_stability.png
ui_hud_stability_bar_frame.png
ui_hud_weight_badge_warning.png
ui_inventory_slot_empty.png
ui_inventory_slot_selected.png
ui_storage_slot_safe_warm.png
ui_extraction_button_progress_50.png
ui_settlement_warning_dialog_frame.png
ui_base_tab_selected.png
ui_warehouse_capacity_frame.png
ui_research_node_available.png
ui_crafting_recipe_card_selected.png
ui_prep_equipment_slot_locked.png
ui_icon_backpack.png
```

命名规则：

```text
ui_[system]_[element]_[state].png
全部小写。
使用下划线。
状态放最后。
同一控件的 normal / selected / disabled / warning / locked / completed 状态必须成组。
```

---

## 25. 验收清单

整体设计稿验收：

```text
局内 UI 没有遮挡主要地图阅读。
局外框架能容纳昼夜阶段和后续功能入口扩展。
白天准备入口顺序包含仓库、制造所、研究所、图鉴。
未开发完成功能入口有明确置灰禁用态。
仓库、制造、研究、图鉴、货台视觉同源但有系统差异。
矿币 icon 在顶部货币栏和营业结算总价中都清晰可读。
撤离、遗弃、低稳定值等危险信息优先级足够高。
安全格子和前哨修复态能明显区别于普通容器。
```

拆分 sheet 验收：

```text
透明背景。
网格清晰。
单格单元素。
无文字、无序号、无水印、无 logo。
元素不重叠、不裁切。
线宽统一。
高饱和色只用于功能状态。
切到 Godot 后边缘干净。
同一系统状态成组完整。
```

进入 Godot 前检查：

```text
面板类资源是否适合九宫格。
按钮是否包含 normal / selected / disabled / warning。
进度条是否能拆成 frame 与 fill。
格子是否能复用于背包、容器、仓库、安全存储。
图标在 32x32 和 64x64 下仍可识别。
```

---

## 26. 推荐首轮生成顺序

第一轮只生成最能锁定风格和基础复用的 6 张：

```text
1. UI-00 风格基准板。
2. UI-01 局内 HUD 整体设计稿。
3. UI-02 局内 HUD 高精度拆分 Sheet。
4. UI-04 背包 / 容器 / 安全格子整体设计稿。
5. UI-05 背包 / 容器 / 安全格子拆分 Sheet。
6. UI-08 局外基地整体框架设计稿。
```

第二轮补全关键流程：

```text
7. UI-06 撤离与结算整体设计稿。
8. UI-07 撤离与结算拆分 Sheet。
9. UI-09 局外导航与通用面板 Sheet。
10. UI-09A 剧情对白界面与控件 Sheet。
11. UI-18 通用系统图标 Sheet。
```

第三轮做局外系统深化：

```text
12. UI-10 仓库系统整体稿。
13. UI-11 仓库系统拆分 Sheet。
14. UI-12 店铺货台与需求整体稿。
15. UI-13 店铺货台与货币拆分 Sheet。
16. UI-14 研究所整体稿。
17. UI-15 研究所拆分 Sheet。
18. UI-16 制作所整体稿。
19. UI-17 制作所拆分 Sheet。
20. UI-18 出发准备整体稿。
21. UI-19 出发准备拆分 Sheet。
```

---

## 27. 美术管理备注

批量生成时每张图都要记录：

```text
sheet_id
prompt_version
source_prompt
generation_date
selected_candidate
accepted_elements
rejected_reason
slice_output_path
godot_import_status
```

建议后续建立：

```text
res://assets/ui/ui_asset_manifest.tab
```

字段建议：

| 字段 | 说明 |
|---|---|
| id | UI 单件 ID |
| sheet_id | 来源 sheet |
| system | hud / inventory / warehouse / research / crafting / prep |
| element | 控件名 |
| state | normal / selected / disabled / warning / locked / completed |
| source_rect | 在 sheet 中的切图区域 |
| sprite_path | 单件 PNG 路径 |
| nine_slice | 是否需要九宫格 |
| notes | 备注 |

---

## 28. 结论

本批 UI 资源不以“漂亮整图”为终点，而以“风格统一、可切分、可复用、可进 Godot”为终点。

最关键的资源优先级是：

```text
局内 HUD。
背包 / 容器 / 安全格子。
撤离与结算。
局外导航框架。
仓库 / 制造 / 研究 / 图鉴 / 货台 / 出发准备。
通用系统图标。
```

只要 UI-00 到 UI-09 风格统一，后续局外系统可以稳定沿同一套控件语言扩展。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 21_UI资源Sheet生成清单与提示词包.md
  作为 开发者
  我希望按本文规则完成 21_UI资源Sheet生成清单与提示词包.md
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

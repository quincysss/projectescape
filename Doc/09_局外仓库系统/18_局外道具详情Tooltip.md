# 09-18 局外道具详情 Tooltip

> 来源需求：局外仓库、商人、研究所等局外界面中，凡是出现道具图标的位置，鼠标 hover 道具图标时显示道具详细信息浮层。  
> 关联文档：`06_仓库界面与手动整理.md`、`16_局外商人与货币系统.md`、`09_研究制作出发准备接口.md`、`13_数据配置表与TAB规范_修订版_废土生存法则.md`、`20_UI视觉规范与界面资源Sheet提示词_修订版_废土生存法则.md`。

## 1. 实现目标

建立一个局外通用的道具详情 Tooltip 组件。

该组件只在局外 BaseScene 中启用，覆盖以下界面：

- 局外仓库物品格。
- 商人可出售物品列表。
- 商人出售确认区中的物品图标。
- 研究所材料需求图标。
- 制作所/制造所材料需求、产物预览图标。
- 后续局外出发准备、装备页签中出现的道具图标。

不覆盖：

- 局内背包。
- 局内容器。
- 局内拾取提示。
- 撤离结算界面。
- 主菜单。

这些界面如需 Tooltip，后续单独扩展，不能直接复用局外规则导致局内遮挡地图信息。

## 2. 触发规则

基础规则：

```text
鼠标进入道具图标 Control
-> 等待 hover_delay_seconds
-> 读取 item_id / warehouse_item_id
-> 构建 ItemTooltipData
-> 在 TooltipLayer 显示 ItemTooltipPanel
```

推荐延迟：

```text
hover_delay_seconds = 0.15
```

隐藏条件：

- 鼠标离开道具图标。
- 道具图标所属界面关闭。
- 切换顶部页签。
- 开始拖拽物品。
- 仓库排序、筛选、滚动导致图标位置改变。
- 右键菜单或出售确认弹窗打开。
- 进入局内或离开 BaseScene。

同一帧内从一个道具图标移动到另一个道具图标时：

- 不需要播放关闭动画。
- 直接刷新内容和位置。

## 3. 数据来源

Tooltip 不新增 `items.tab` 字段。

基础数据全部来自 `items.tab / ItemDefinition`：

| 字段 | Tooltip 用途 |
| --- | --- |
| id | 查表 key |
| name | 道具名 |
| quality | 品质色、边框强调 |
| item_type | 类型标签，可选显示 |
| icon | 顶部道具图标 |
| sellable | 是否可出售 |
| sell_currency_id | 售价货币 |
| sell_value | 单个售价 |
| description | 道具描述正文 |
| tags | 后续可用于收藏品、前哨材料、研究材料等标签 |

货币名和货币图标来自 `currencies.tab / CurrencyDefinition`。

上下文可补充：

```gdscript
{
    "context": "warehouse" | "merchant" | "research" | "crafting" | "loadout",
    "owned_count": 0,
    "required_count": 0,
    "selected_sell_count": 0,
    "warehouse_item_id": "",
    "show_requirement_state": false
}
```

V0.1 主 Tooltip 面板只强制显示：图标、道具名、售价/不可出售、描述。

数量、拥有量、需求量、品质字样可由图标格或列表行显示，不强制放入 Tooltip，避免浮层过重。

## 4. 显示内容

参考布局：

```text
┌────────────────────────┐
│                        │
│          icon          │
│                        │
│ 道具名            500矿币 │
│ ────────────────────── │
│ 道具描述文本。          │
│ 道具描述文本换行。      │
└────────────────────────┘
```

内容规则：

- 图标使用 `items.tab.icon`，居中显示。
- 道具名使用 `items.tab.name`。
- 售价区域：
  - `sellable == true && sell_value > 0`：显示 `{sell_value}{currency_name}`，例如 `120矿币`。
  - `sellable == false || sell_value <= 0`：显示 `不可出售`，使用低亮灰色。
  - 商人界面中只显示可出售物品，但 Tooltip 仍按同一规则构建。
- 描述使用 `items.tab.description`。
- description 为空时显示：`暂无记录。`
- 道具缺失或 item_id 无效时，Debug 模式显示错误占位；正式模式不显示 Tooltip，并记录 warning。

## 5. 视觉规格

面板风格：

```text
背景：接近黑色，透明度 92%-96%
边框：细蓝绿色描边
外发光：弱蓝绿色，不能喧宾夺主
圆角：0-2 px，保持废土硬边 UI 气质
内边距：14-16 px
宽度：220-260 px
最小高度：260 px
最大高度：360 px
```

推荐尺寸：

| 分辨率 | 宽 | 最小高 | 图标尺寸 |
| --- | ---: | ---: | ---: |
| 1280x720 | 224 | 260 | 72 |
| 1600x900 | 240 | 280 | 80 |
| 1920x1080 | 260 | 300 | 88 |

层级：

- Tooltip 挂在 `BaseUIRoot/TooltipLayer`。
- `TooltipLayer` 必须高于仓库、商人、研究所、制作所面板。
- Tooltip 本身设置为不拦截鼠标，避免鼠标进入浮层导致图标误判离开/进入循环。

字体：

- 道具名：正文偏大，16-18 px。
- 售价：14-16 px，可使用等宽数字。
- 描述：13-14 px，行高 18-20 px。

品质色：

- 品质不强制显示文字。
- 可用道具名或图标背光轻微体现品质。
- SS 道具使用红色品质强调，但 Tooltip 主边框仍使用统一蓝绿色，只在图标阴影或名称左侧小点体现红色，避免全屏红框过度抢眼。

## 6. 定位规则

默认定位：

```text
Tooltip 显示在道具图标右侧，水平偏移 16 px。
Tooltip 顶部与道具图标顶部对齐。
```

屏幕边界处理：

- 右侧空间不足时，显示在图标左侧。
- 下方空间不足时，向上夹取。
- 上方空间不足时，向下夹取。
- 与屏幕边缘保持至少 `16 px` 安全距离。
- 不允许面板超出窗口。

滚动容器内：

- 鼠标 hover 后如果列表滚动，立即隐藏 Tooltip。
- 如果只是 UI 重排且图标仍在 hover 状态，可重新计算 anchor 并显示。

## 7. 交互细节

仓库：

- hover 仓库格内的物品图标显示 Tooltip。
- 空格子不显示 Tooltip。
- 拖拽物品时禁用 Tooltip。
- 选中物品详情面板与 Tooltip 可以同时存在，但 Tooltip 只作为临时快速查看，不取代选中详情。

商人：

- hover 可出售列表中的物品图标显示 Tooltip。
- 售价显示单个物品基础售价。
- 数量选择器改变时，不改变 Tooltip 的单价字段；总价仍由商人列表/确认区负责显示。
- SS 道具 hover 时可以在描述下方追加 `超稀有，可出售或保留收藏。`，但这行应来自 tags/quality 判断，不写死 item_id。

研究所：

- hover 材料需求图标显示 Tooltip。
- 如果研究 UI 已显示 `拥有/需求`，Tooltip 不重复显示数量。
- 如果空间允许，可以在 Tooltip 描述下方用一行低亮文字显示 `拥有 {owned_count} / 需要 {required_count}`。
- 未拥有的材料也能 hover 查看，帮助玩家知道缺的是什么。

制作所/制造所：

- hover 配方材料和产物预览图标显示 Tooltip。
- 产物 Tooltip 使用同一套 ItemDefinition。
- 配方材料不足状态由图标格或配方行显示，不由 Tooltip 负责主提示。

键盘/手柄预留：

- V0.1 主要实现鼠标 hover。
- 如果有 UI focus，焦点停留在道具图标上超过 0.2 秒也可调用同一 Tooltip。
- 手柄长按查看详情暂不实现。

Web 版：

- 鼠标 hover 与桌面一致。
- 触屏长按查看详情暂不实现，后续可扩展 `long_press_seconds = 0.45`。

## 8. Godot 落地范围

推荐新增：

```text
systems/ui/item_tooltip/item_tooltip_service.gd
systems/ui/item_tooltip/item_tooltip_data_builder.gd
systems/ui/item_tooltip/item_tooltip_data.gd
systems/ui/item_tooltip/hoverable_item_icon.gd
scenes/ui/common/ItemTooltipPanel.tscn
scenes/ui/common/ItemTooltipPanel.gd
```

BaseScene 推荐节点：

```text
BaseScene
  BaseUIRoot
    BaseTopTabs
    CurrencyBar
    WarehousePanel
    MerchantPanel
    ResearchPanel
    CraftingPanel
    TooltipLayer
      ItemTooltipPanel
```

推荐接口：

```gdscript
func show_for_item(item_id: String, anchor: Control, context: Dictionary = {}) -> void
func show_for_warehouse_item(warehouse_item_id: String, anchor: Control, context: Dictionary = {}) -> void
func update_anchor(anchor: Control) -> void
func hide(reason: String = "") -> void
func is_visible_for(item_id: String) -> bool
```

`HoverableItemIcon` 职责：

- 持有 `item_id` 或 `warehouse_item_id`。
- 监听 `mouse_entered` / `mouse_exited`。
- 在 hover 延迟后调用 `ItemTooltipService.show_for_item()`。
- 在离开、拖拽、禁用、销毁时调用 `ItemTooltipService.hide()`。

`ItemTooltipDataBuilder` 职责：

- 通过 DataRegistry 读取 ItemDefinition。
- 通过 CurrencyRegistry 读取 CurrencyDefinition。
- 合并上下文字段。
- 返回 UI 可直接消费的 `ItemTooltipData`。

## 9. AI/MCP 开工提示词

```text
请实现局外通用道具详情 Tooltip。

必须先读取：
- Doc/09_局外仓库系统/18_局外道具详情Tooltip.md
- Doc/09_局外仓库系统/06_仓库界面与手动整理.md
- Doc/09_局外仓库系统/16_局外商人与货币系统.md
- Doc/10_研究所与制作所系统/01_研究所移动速度研究规则.md
- Doc/13_数据配置表与TAB规范_修订版_废土生存法则.md
- Doc/20_UI视觉规范与界面资源Sheet提示词_修订版_废土生存法则.md

任务：
1. 新增 ItemTooltipService、ItemTooltipDataBuilder、HoverableItemIcon、ItemTooltipPanel。
2. Tooltip 只在局外 BaseScene 启用，不接入局内背包、容器、拾取和结算界面。
3. 局外仓库、商人、研究所、制作所中凡是道具图标 Control，都接入 HoverableItemIcon。
4. Hover 0.15 秒后显示 Tooltip；鼠标离开、切页、滚动、拖拽、弹出菜单、离开局外时隐藏。
5. Tooltip 数据来自 items.tab / ItemDefinition 和 currencies.tab / CurrencyDefinition，不新增表字段，不写死道具名、售价或描述。
6. Tooltip 布局为黑色面板、蓝绿色细边框、顶部居中图标、中部道具名和单价、分隔线、底部描述。
7. 售价规则：sellable=true 且 sell_value>0 显示售价；否则显示“不可出售”。
8. Tooltip 必须自动根据屏幕边界选择显示在图标右侧或左侧，并且不能超出窗口。
9. Tooltip 不拦截鼠标输入，不能导致 hover 抖动。
10. Debug 模式下 item_id 缺失时打印 warning；正式模式不显示错误 Tooltip。
```

## 10. 验收标准

| 编号 | 标准 |
| --- | --- |
| A1 | 局外仓库物品图标 hover 后显示 Tooltip |
| A2 | 商人列表物品图标 hover 后显示 Tooltip |
| A3 | 研究所材料需求图标 hover 后显示 Tooltip |
| A4 | Tooltip 显示图标、道具名、售价/不可出售、描述 |
| A5 | Tooltip 数据来自 `items.tab`，不写死 |
| A6 | 售价货币来自 `currencies.tab` |
| A7 | 空格子、无效 item_id、局内界面不显示 Tooltip |
| A8 | 鼠标离开、切页、滚动、拖拽时 Tooltip 隐藏 |
| A9 | Tooltip 不超出屏幕边界 |
| A10 | Tooltip 不拦截鼠标，不产生闪烁 |
| A11 | SS 道具 hover 时保留红色品质识别 |
| A12 | Markdown/实现提示词明确该功能仅局外启用 |

## 11. 暂不实现

- 局内背包 Tooltip。
- 结算界面 Tooltip。
- 触屏长按查看。
- 对比当前装备属性。
- 动态市场价格解释。
- 长描述滚动条。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 09-18 局外道具详情 Tooltip
  作为 系统设计与实现线程
  我希望按本文规则完成 09-18 局外道具详情 Tooltip
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "09_局外仓库系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。

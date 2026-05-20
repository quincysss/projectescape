# 09-18 局外道具详情 Tooltip

> 来源需求：局外仓库、制造所、研究所、货台、图鉴和夜晚出发准备中，凡是出现道具图标的位置，鼠标 hover 道具图标时显示道具详细信息浮层。
> 最新口径：旧独立售卖入口已废弃；Tooltip 不展示“直接出售”规则，不承担成交总价计算。

## 1. 实现目标

建立一个局外通用的道具详情 Tooltip 组件。

覆盖界面：
- 白天准备阶段的仓库物品格。
- 制造所材料需求和产物预览图标。
- 研究所材料需求图标。
- 货台已上架物资图标。
- 当日需求排行榜中的物资图标。
- 图鉴卡片中的道具图标。
- 夜晚出发准备中的仓库、装备格和消耗品格。

不覆盖：
- 局内背包。
- 局内容器。
- 局内拾取提示。
- 撤离结算界面。
- 主菜单。

这些界面如需 Tooltip，后续单独扩展，避免局内遮挡地图信息。

## 2. 触发规则

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
- 切换局外阶段或功能入口。
- 开始拖拽物品。
- 仓库排序、筛选、滚动导致图标位置改变。
- 右键菜单、丢弃确认、上架确认或出发确认弹窗打开。
- 进入局内或离开 BaseScene。

同一帧内从一个道具图标移动到另一个道具图标时：
- 不需要播放关闭动画。
- 直接刷新内容和位置。

## 3. 数据来源

Tooltip 不新增 `items.tab` 字段。

基础数据来自 `items.tab / ItemDefinition`：

| 字段 | Tooltip 用途 |
| --- | --- |
| id | 查表 key |
| name | 道具名 |
| quality | 品质颜色、边框强调 |
| item_type | 类型标签，可选显示 |
| icon | 顶部道具图标 |
| description | 道具描述正文 |
| tags | 用于材料、可售物资、装备、消耗品等标签 |

上下文数据可补充：

```gdscript
{
    "context": "warehouse" | "shelf" | "research" | "crafting" | "catalog" | "loadout" | "demand_rank",
    "owned_count": 0,
    "required_count": 0,
    "warehouse_item_id": "",
    "show_requirement_state": false,
    "show_sale_hint": false,
    "estimated_unit_price": 0
}
```

V0.2 强制显示：图标、道具名、品质、类型、描述。

可选显示：
- 拥有数量。
- 需求数量。
- 是否可作为制造材料。
- 是否为可售物资。
- 货台预估基础成交价。

## 4. 显示内容

参考布局：

```text
┌────────────────────────┐
│          icon          │
│                        │
│        道具名          │
│      品质 / 类型       │
├────────────────────────┤
│ 道具描述文本。         │
│ 道具描述文本换行。     │
│                        │
│ 拥有 3 / 需要 2        │
└────────────────────────┘
```

内容规则：
- 图标使用 `items.tab.icon`，居中显示。
- 道具名使用 `items.tab.name`。
- 描述使用 `items.tab.description`。
- `description` 为空时显示：`暂无记录。`
- 如果上下文为 `shelf` 或 `demand_rank`，可以显示“预估基础成交价”，但真实成交总价仍由营业结算系统计算。
- 不能显示“直接出售”或“不可出售”作为仓库通用规则。
- 道具缺失或 `item_id` 无效时，Debug 模式显示错误占位；正式模式不显示 Tooltip，并记录 warning。

## 5. 视觉规格

面板风格：

```text
背景：接近黑色，透明度 92%-96%
边框：细蓝绿色描边
外发光：弱蓝绿色
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
- `TooltipLayer` 必须高于仓库、制造所、研究所、货台、图鉴、出发准备面板。
- Tooltip 本身设置为不拦截鼠标，避免 hover 抖动。

## 6. 定位规则

```text
Tooltip 默认显示在道具图标右侧，水平偏移 16 px。
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

制造所：
- hover 配方材料和产物预览图标显示 Tooltip。
- 材料不足状态由配方行负责表现，Tooltip 只补充详情。

研究所：
- hover 材料需求图标显示 Tooltip。
- 如果研究 UI 已显示“拥有/需要”，Tooltip 不重复显示数量；空间允许时可显示一行低亮文字。

货台：
- hover 已上架物资图标显示 Tooltip。
- Tooltip 可显示预估基础成交价，但不负责显示本日总成交收益。

图鉴：
- hover 图鉴卡片图标显示 Tooltip。
- 未获得道具也可显示名称和描述，不额外点亮图鉴。

夜晚出发准备：
- hover 仓库候选物、装备格、消耗品格显示 Tooltip。
- 装备对比属性后续独立扩展，V0.2 不做。

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
    DayPrepPanel
    ShopOpenPanel
    NightPlanPanel
    DepartureLoadoutPanel
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

## 9. AI 开工提示词

```text
请实现局外通用道具详情 Tooltip。
必须先读取 Doc/09_局外仓库系统/18_局外道具详情Tooltip.md、Doc/29_局外杂货店经营与界面重构路线图.md、Doc/30_昼夜局外流程_店铺营业与夜间出发准备.md、Doc/31_掉落物资与制造经济规划.md。
要求：
1. Tooltip 只在局外 BaseScene 启用，不接入局内背包、容器、拾取和结算界面。
2. 仓库、制造所、研究所、货台、图鉴、夜晚出发准备中的道具图标 Control 都接入 HoverableItemIcon。
3. Hover 0.15 秒后显示 Tooltip；鼠标离开、切功能、滚动、拖拽、弹窗、离开局外时隐藏。
4. Tooltip 数据来自 items.tab / ItemDefinition，不新增表字段，不写死道具名或描述。
5. Tooltip 展示图标、道具名、品质、类型、描述，可按上下文显示拥有/需要和预估基础成交价。
6. 不实现旧直接出售价格展示。
7. Tooltip 必须自动根据屏幕边界选择左右位置，并且不能超出窗口。
8. Tooltip 不拦截鼠标输入，不能导致 hover 抖动。
```

## 10. 验收标准

| 编号 | 标准 |
| --- | --- |
| A1 | 仓库物品图标 hover 后显示 Tooltip |
| A2 | 制造所材料和产物图标 hover 后显示 Tooltip |
| A3 | 研究所材料需求图标 hover 后显示 Tooltip |
| A4 | 货台物资图标 hover 后显示 Tooltip |
| A5 | 图鉴卡片图标 hover 后显示 Tooltip |
| A6 | 夜晚出发准备装备和消耗品图标 hover 后显示 Tooltip |
| A7 | Tooltip 显示图标、道具名、品质、类型和描述 |
| A8 | Tooltip 数据来自 `items.tab`，不写死 |
| A9 | 空格子、无效 item_id、局内界面不显示 Tooltip |
| A10 | 鼠标离开、切功能、滚动、拖拽时 Tooltip 隐藏 |
| A11 | Tooltip 不超出屏幕边界 |
| A12 | Tooltip 不拦截鼠标，不产生闪烁 |

## 11. 暂不实现

- 局内背包 Tooltip。
- 结算界面 Tooltip。
- 触屏长按查看。
- 对比当前装备属性。
- 动态市场价格解释。
- 长描述滚动条。

## BDD 场景补充

```gherkin
Feature: 09-18 局外道具详情 Tooltip
  Scenario: 货台物资 hover 显示详情但不计算成交
    Given 货台上架 sale_good_simple_gear
    When 玩家 hover sale_good_simple_gear 图标
    Then Tooltip 显示图标、名称、品质、类型和描述
    And Tooltip 不触发成交
    And Tooltip 不改变 mine_coin
```

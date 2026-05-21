# 32-05 Godot 模块、数据字段与验收

> 本文给工程落地使用，重点约束脚本职责、数据字段、Debug 和验收。实际命名可按工程现状微调，但职责不能退回 `base_scene.gd` 一把梭。

## 1. 推荐模块

```text
scripts/base/outgame_flow_controller.gd
scripts/base/shop_day_prep_controller.gd
scripts/base/shop_open_controller.gd
scripts/base/shop_settlement_controller.gd
scripts/base/daily_demand_service.gd
scripts/base/shelf_inventory_service.gd
scripts/base/shop_sales_service.gd
scripts/base/currency_wallet.gd
```

职责：

| 模块 | 职责 |
|---|---|
| `outgame_flow_controller.gd` | 管理 DAY_PREP、SHOP_OPEN、SHOP_SETTLEMENT、NIGHT 流转 |
| `shop_day_prep_controller.gd` | 开店前界面、功能入口、开店按钮 |
| `shop_open_controller.gd` | 开店中界面、倒计时、货台操作、提前结束按钮 |
| `shop_settlement_controller.gd` | 营业结算面板、进入夜晚按钮 |
| `daily_demand_service.gd` | 每日需求榜生成、保存、查询成交参数 |
| `shelf_inventory_service.gd` | 上架、补货、撤下、售出扣货、回仓 |
| `shop_sales_service.gd` | 成交计时、成交记录、收益计算 |
| `currency_wallet.gd` | 货币增加、扣除、保存 |

`BaseScene` 只负责装配和转发，不直接写业务规则。

## 1.1 推荐公开接口

`outgame_flow_controller.gd`：

```text
get_phase()
can_enter_shop_open()
enter_shop_open()
enter_shop_settlement(ended_by)
close_shop_settlement_to_night()
```

`shelf_inventory_service.gd`：

```text
get_shelf_slots()
get_available_sale_goods()
can_place(slot_id, item_id, quantity)
place_item(slot_id, item_id, quantity, source_stack_id)
restock_item(slot_id, quantity)
withdraw_item(slot_id, quantity)
sell_one(slot_id)
return_unsold_goods()
has_any_sellable_stock()
```

`shop_sales_service.gd`：

```text
start_session(shop_session_id, demand_entries, duration_seconds)
tick(delta_seconds)
schedule_next_sale(slot_id)
build_settlement_snapshot(ended_by)
get_sales_records()
get_total_earned()
get_missed_customer_count()
```

`currency_wallet.gd`：

```text
get_amount(currency_id)
can_add(currency_id, amount)
add_once(currency_id, amount, source_session_id)
was_source_applied(source_session_id)
```

接口命名可按工程现状微调，但职责不能退回 `base_scene.gd`。

## 2. 阶段枚举

```gdscript
enum OutgamePhase {
    DAY_PREP,
    SHOP_OPEN,
    SHOP_SETTLEMENT,
    NIGHT,
    NIGHT_PLAN,
    LOADOUT,
    LOADING_TO_RUN,
}
```

白天经营实现本目录只要求前四个阶段。

## 3. 存档字段

建议追加到局外存档：

```text
outgame_phase
surface_day
daily_demand_seed
daily_demand_entries
shop_session_id
shop_elapsed_seconds
shop_duration_seconds
shop_ended_by
shop_sales_records
shop_total_earned
shop_settlement_applied
shelf_items
pending_return_shelf_items
last_applied_shop_session_id
shop_settlement_snapshot
shop_history
```

`shop_ended_by` 可选值：

```text
timer_end
early_end
debug_end
```

`shop_settlement_snapshot` 用于恢复结算面板，不用于重新计算收益。

`shop_history` 为简短历史记录，可只保存最近 7-14 天，避免存档无限增长。

## 4. 货台数据结构

```text
shelf_slot_id
unlocked
item_id
quality
quantity
source_stack_id
state
next_sale_second
last_sale_second
```

`state`：

```text
empty
active
sold_out
locked
```

货台状态语义：

| state | 含义 |
|---|---|
| `empty` | 已解锁但没有上架物资 |
| `active` | 有货且可成交 |
| `sold_out` | 本格曾上架但数量为 0 |
| `locked` | 未解锁或配置不可用 |

`sold_out` 可在玩家撤下、补货或离开结算时恢复为 `empty`。

## 5. 成交记录结构

```text
sale_record_id
shop_session_id
item_id
display_name
quality
quantity
unit_price
price_multiplier
demand_rank
sold_at_second
currency_id
earned_amount
source_shelf_slot_id
sold_at_second
flags
```

结算面板按 `item_id + quality + unit_price` 或 `item_id + quality` 聚合显示均可，但底层记录必须保留明细，方便 Debug。

`flags` 可记录：

```text
price_missing
debug_forced
restored_from_save
```

## 5.1 结算 Snapshot 结构

```text
shop_session_id
shop_day
ended_by
elapsed_seconds
duration_seconds
sales_records
sold_summary
missed_customer_count
total_earned
unsold_returned_goods
pending_return_shelf_items
settlement_applied
created_at
```

`sold_summary` 可由 `sales_records` 聚合后保存，方便 UI 直接展示；但 Debug 仍应能查看明细记录。

## 6. Debug 工具

Debug 面板建议增加：

- 切换到 DAY_PREP。
- 切换到 SHOP_OPEN。
- 剩余营业时间设为 5 秒。
- 清空货台。
- 清空仓库 sale_good。
- 添加 3 个 C 级 sale_good。
- 强制触发下一次成交。
- 强制提前结束营业。
- 重置本日需求榜。
- 查看 shop_settlement_applied。
- 打印当前 shop_session_id。
- 打印货台 slot 状态和 next_sale_second。
- 打印 shop_settlement_snapshot。
- 模拟读档恢复 SHOP_OPEN。
- 模拟读档恢复 SHOP_SETTLEMENT。
- 修复 last_applied_shop_session_id 与 shop_settlement_applied 不一致。

## 7. 验收清单

最小交付：

- [ ] DAY_PREP 不显示出发探索。
- [ ] DAY_PREP 显示仓库、制造所、研究所、图鉴、需求榜和开店营业。
- [ ] 点击开店营业进入 SHOP_OPEN。
- [ ] SHOP_OPEN 显示 60 秒倒计时。
- [ ] SHOP_OPEN 显示初始 3 个货台格。
- [ ] 只有 `sale_good` 可上架。
- [ ] 原材料不能上架。
- [ ] 货台商品能自动成交并生成成交记录。
- [ ] 货台售空后停止该格成交计时。
- [ ] 补货不会刷新已有货台的临近成交时间。
- [ ] 未上榜货物使用低频成交和低售价修正。
- [ ] 没有匹配货物时能记录未满足需求。
- [ ] 货台为空且仓库无 sale_good 时提示没货。
- [ ] SHOP_OPEN 全程有提前结束营业按钮。
- [ ] 提前结束后立刻进入 SHOP_SETTLEMENT。
- [ ] 自然结束和提前结束共用同一套结算管线。
- [ ] SHOP_SETTLEMENT 显示卖出物资、数量、收益和总收入。
- [ ] SHOP_SETTLEMENT 显示营业时长、未满足需求人数和结束原因。
- [ ] 关闭 SHOP_SETTLEMENT 后进入 NIGHT。
- [ ] NIGHT 才显示出发探索。
- [ ] 读档不重复加币。
- [ ] 未售出货物回仓或保持可恢复 pending 状态。
- [ ] 存在 pending_return_shelf_items 时不能进入 NIGHT。
- [ ] SHOP_OPEN 读档时若剩余时间已归零，应直接进入结算管线。

## 8. AI 开工提示词

```text
请按 Doc/32_局外白天经营流程 实现白天经营流程。

重点：
- 新增或拆分 outgame_flow_controller、shop_day_prep_controller、shop_open_controller、shop_settlement_controller。
- DAY_PREP 只做开店前准备，不显示出发探索。
- SHOP_OPEN 只做货台经营，不允许制造和研究。
- SHOP_OPEN 全程显示提前结束营业按钮；没货时高亮。
- 提前结束和倒计时结束共用结算流程。
- 结算必须防重复加币。
- 关闭结算后进入 NIGHT。

验收时至少跑：
- 白天准备到开店中
- 上架 sale_good 成交
- 原材料不能上架
- 没货提前结束
- 有货提前结束二次确认
- 结算关闭进入夜晚
- 读档不重复结算
```

## 9. BDD 场景

Feature: 白天经营工程验收

  Scenario: 完整白天经营闭环
    Given 当前阶段为 DAY_PREP
    And 仓库中有 sale_good_simple_gear x3
    When 玩家点击开店营业
    And 玩家上架 sale_good_simple_gear x3
    And 营业时间推进到 60 秒
    Then 当前阶段应变为 SHOP_SETTLEMENT
    And 结算面板应显示卖出记录和总收入
    When 玩家点击进入夜晚
    Then 当前阶段应变为 NIGHT

  Scenario: 没货提前结束进入夜晚链路
    Given 当前阶段为 SHOP_OPEN
    And 所有货台为空
    And 仓库中没有 sale_good
    When 玩家点击提前结束营业并确认
    Then 当前阶段应变为 SHOP_SETTLEMENT
    When 玩家关闭结算面板
    Then 当前阶段应变为 NIGHT

  Scenario: 结算防重复加币
    Given 当前阶段为 SHOP_SETTLEMENT
    And shop_session_id 为 shop_day_3_001
    And shop_total_earned 为 80
    And CurrencyWallet 已应用 shop_day_3_001
    When 玩家读取该结算存档
    Then CurrencyWallet 不应再次增加 80
    And shop_settlement_applied 应保持或修复为 true

  Scenario: 货台未售商品安全回仓
    Given 当前阶段为 SHOP_OPEN
    And 货台 0 上有 sale_good_patch_roll x2
    When 系统进入 SHOP_SETTLEMENT
    Then sale_good_patch_roll x2 应恢复为仓库 AVAILABLE 状态
    And pending_return_shelf_items 应为空

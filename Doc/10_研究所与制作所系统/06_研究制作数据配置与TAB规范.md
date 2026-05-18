# 10-06 研究制作数据配置与 TAB 规范

> 来源文档：`10_研究所与制作所系统_修订版_废土生存法则.md`、`13_数据配置表与TAB规范_修订版_废土生存法则.md`  
> 目标：统一研究、图纸和配方的表格字段，确保新增成长内容优先改表，不改脚本。

## 1. 实现目标

10 模块至少维护三类表：

```text
setting/research.tab
setting/blueprints.tab
setting/recipes.tab
```

当前已落地：

```text
setting/research.tab
```

后续新增图纸和制作时，再补 `blueprints.tab` 与 `recipes.tab`。

## 2. 通用规则

- 文件使用 UTF-8。
- 后缀使用 `.tab`。
- 字段用 tab 分隔。
- 列表字段使用 `;`。
- 需求字段使用 `item_id:count;item_id:count`。
- ID 使用小写英文、数字和下划线。
- 表格中只写配置，不写脚本表达式。
- 表格启停使用 `enabled` 和 `enabled_version`。

## 3. research.tab

当前路径：

```text
setting/research.tab
```

当前表头：

```text
research_id	display_name	category	level	max_level	required_items	required_currency_id	required_currency_amount	effect_type	effect_value	enabled	enabled_version	description
```

字段说明：

| 字段 | 说明 |
| --- | --- |
| `research_id` | 研究线 ID，同一研究线多档共用 |
| `level` | 当前档位 |
| `max_level` | 最大档位 |
| `required_items` | 材料需求 |
| `required_currency_id` | 货币 ID，当前为 `mine_coin` |
| `required_currency_amount` | 货币数量 |
| `effect_type` | 效果类型 |
| `effect_value` | 最终生效值，不是增量 |

当前已支持 `effect_type`：

| effect_type | effect_value 语义 |
| --- | --- |
| `player_move_speed_multiplier` | 玩家基础移动速度最终倍率 |
| `inventory_slots` | 玩家局内背包最终格数 |
| `home_storage_slots` | 家中安全箱最终格数 |
| `outpost_storage_slots` | 已修复前哨安全箱最终格数 |
| `max_stability` | 玩家稳定值最终上限 |
| `warehouse_capacity` | 局外仓库最终格数 |
| `merchant_shop_level` | 商人库存最终等级 |

仓库容量必须按当前工程口径：

```text
未研究：80
Lv.1：80
Lv.2：90
Lv.3：100
Lv.4：110
Lv.5：120
```

## 4. blueprints.tab

建议路径：

```text
setting/blueprints.tab
```

建议表头：

```text
blueprint_id	display_name	item_id	unlock_recipe_id	quality	consume_on_learn	duplicate_policy	enabled	enabled_version	description
```

示例：

```text
bp_backpack_small	小型加固背包图纸	bp_backpack_small	craft_backpack_small	A	true	keep_as_item	true	v0.2	学习后解锁小型加固背包配方。
```

## 5. recipes.tab

建议路径：

```text
setting/recipes.tab
```

建议表头：

```text
recipe_id	display_name	category	output_item_id	output_quantity	required_items	required_currency_id	required_currency_amount	required_research_ids	required_blueprint_id	craft_time_seconds	instant_craft	enabled	enabled_version	description
```

示例：

```text
craft_backpack_small	小型加固背包	backpack	backpack_small_reinforced	1	cloth_dirty:6;duct_tape_roll:3;reinforced_strap:1	mine_coin	0		bp_backpack_small	0	true	true	v0.2	制作一个小型加固背包。
```

## 6. 数据校验

实现表格后必须校验：

```text
research.tab 中 required_items 都存在于 setting/items.tab。
research.tab 不引用 setting/repairmaterial.tab。
research_id + level 不重复。
effect_type 属于白名单。
warehouse_capacity 数值不低于当前基础容量 80。
blueprints.tab.item_id 必须是 items.tab 中 type=blueprint 的物品。
blueprints.tab.unlock_recipe_id 必须存在于 recipes.tab。
recipes.tab.output_item_id 必须存在于 items.tab。
recipes.tab.required_items 必须存在于 items.tab。
recipes.tab.required_blueprint_id 为空或存在于 blueprints.tab。
recipes.tab.required_research_ids 为空或存在于 research.tab 的 research_id。
```

## 7. 暂不实现

```text
Excel 直接读取。
嵌套 JSON 配方字段。
复杂条件表达式写入表格。
多语言文本表拆分。
运行时热更新表格。
```
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 10-06 研究制作数据配置与 TAB 规范
  作为 开发者
  我希望按本文规则完成 10-06 研究制作数据配置与 TAB 规范
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "10_研究所与制作所系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。

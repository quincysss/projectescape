# 06_研究制作数据配置与TAB规范

> 对应母版章节：14
> 本文件只定义研究与制作配方数据。不存在配方道具或配方学习物品。

---

## 1. 表格范围

10 模块至少维护两类表：

```text
research.tab
recipes.tab
```

研究只消耗矿币。制作配方的开放条件写在 `recipes.tab.required_research` 与 `recipes.tab.required_conditions` 中。

---

## 2. research.tab

用途：定义研究节点。

建议字段：

```text
research_id
display_name
category
cost_currency
cost_amount
required_research
effect_type
effect_value
enabled_version
```

规则：

```text
cost_currency 当前只允许 mine_coin。
不得把局内随机材料写成研究消耗。
required_research 只能引用 research.tab。
```

---

## 3. recipes.tab

用途：定义制作配方、产物、材料消耗、研究需求和其他开放条件。

建议字段：

```text
recipe_id
display_name
category
output_item
output_count
required_items
required_research
required_conditions
craft_time_seconds
output_quality
enabled_version
```

`required_conditions` 允许引用：

```text
chapter
task
shop_level
fixture
vendor
location_event
```

示例：

```text
recipe_sale_good_simple_gear	连轴齿轮	sale_good	sale_good_simple_gear	1	scrap_metal:1;cloth_strip:1		shop_level:1	3	C	v0.3
recipe_backpack_small	小型加固背包	equipment	backpack_small	1	cloth_strip:4;simple_part_b:2	research_backpack_1	fixture:basic_workbench	8	B	v0.3
```

---

## 4. 校验规则

```text
research.tab.cost_currency 必须是 mine_coin。
research.tab 不允许配置材料消耗。
recipes.tab.output_item 必须存在于 items.tab。
recipes.tab.required_items 中的 item_id 必须存在于 items.tab。
recipes.tab.required_research 非空时必须存在于 research.tab。
recipes.tab.required_conditions 非空时必须使用受支持的条件类型。
不得出现配方来源物或配方道具字段。
```

---

## 5. AI/MCP 开工提示词

```text
请实现研究制作数据配置与 TAB 校验。
读取 Doc/10_研究所与制作所系统/06_研究制作数据配置与TAB规范.md。
research.tab 只允许矿币消耗；recipes.tab 通过 required_research 和 required_conditions 控制配方可用条件。
不要实现配方道具、配方学习或重复配方道具处理。
```

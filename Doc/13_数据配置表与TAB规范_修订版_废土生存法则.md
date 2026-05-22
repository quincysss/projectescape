# 13_数据配置表与TAB规范.md

# 《废土生存法则》数据配置表与 TAB 规范（修订版）

> 文档版本：v0.1  
> 所属项目：《废土生存法则》  
> 前置文档：07_背包、存储与负重系统.md / 10_研究所与制作所系统.md / 11_出发准备与局外装备系统.md / 12_消耗品与装备效果系统.md  
> 适用阶段：V0.3 / V0.4 数据配置化准备  
> 文档目标：统一物品、材料、装备、消耗品、研究、制作、配方开放、效果等静态数据的表格规范，确保后续新增、删改内容时优先修改 `.tab` 配置表，而不是修改脚本逻辑。

---

## 1. 本文档一句话说明

`.tab` 配置表是游戏内容数据的源头。

脚本负责规则，表格负责内容。

---

## 2. 设计目标

## 2.1 核心目标

数据配置表系统需要达成：

```text
让道具、材料、装备、消耗品、研究、制作配方可维护。
让策划能用电子表格增删改内容。
让 Godot 读取统一格式的数据定义。
减少脚本中硬编码的物品、装备、配方和效果。
方便后续生成 Godot 代码提示词。
方便后续生成美术资源提示词。
为版本迭代、平衡调整和批量校验打基础。
```

---

## 2.2 不做什么

V0.3 / V0.4 初期不建议做：

```text
复杂数据库。
在线热更新。
运行中动态改表。
多语言文本表全量系统。
Excel 公式驱动逻辑。
策划表直接写复杂脚本表达式。
```

核心原则：

```text
表格描述静态数据。
脚本解释静态数据。
存档只保存动态结果。
```

---

## 3. TAB 文件基础规范

## 3.1 文件格式

`.tab` 文件本质是 TSV 文件。

规则：

```text
文件扩展名：.tab
编码：UTF-8
分隔符：制表符 TAB
第一行：字段名表头
第二行开始：数据行
空行：允许，读取时跳过
注释行：允许，以 # 开头，读取时跳过
```

不建议使用：

```text
逗号分隔 CSV。
单元格内换行。
单元格内制表符。
富文本。
合并单元格。
公式单元格。
```

原因：

```text
Godot 读取 TSV 比读取复杂 Excel 更稳定。
Git diff 更清晰。
电子表格仍然可以打开和编辑。
AI 也更容易生成和修改。
```

---

## 3.2 文件路径

推荐统一放在：

```text
res://data/
```

工程内对应路径：

```text
project-escape/data/
```

推荐文件：

```text
data/items.tab
data/currencies.tab
data/materials.tab
data/equipment.tab
data/consumables.tab
data/effects.tab
data/research.tab
data/recipes.tab
data/recipes.tab
data/drop_tables.tab
data/outpost_requirements.tab
```

剧情和对白配置使用：

```text
setting/dialogues.tab
setting/dialogue_speakers.tab
```

V0.2 局外店铺经营开工时必须先有 `data/currencies.tab`、`data/sale_goods.tab` 或等价可售物资配置。

V0.3 初期可以先做 `items.tab`、`currencies.tab`、`materials.tab`、`equipment.tab`、`consumables.tab`、`effects.tab`、`research.tab`、`recipes.tab`。

`drop_tables.tab` 和 `outpost_requirements.tab` 可以在局内刷新和前哨配置复杂后再拆。

`dialogue_speakers.tab` 用于按 `speaker_id` 配置剧情对白角色原画、默认站位和名牌颜色；对白正文仍由 `dialogues.tab` 管理。

---

## 3.3 单元格通用写法

基础值：

| 类型 | 写法 | 示例 |
|---|---|---|
| 字符串 | 直接写文本 | 小型加固背包 |
| 整数 | 数字 | 3 |
| 浮点数 | 小数 | 1.25 |
| 布尔值 | true / false | true |
| 空值 | 留空 |  |
| ID列表 | 用 ; 分隔 | item_a;item_b |
| 数量列表 | id:count;id:count | scrap:2;cloth:1 |
| 参数列表 | key:value;key:value | amount:15;duration:0 |
| 标签列表 | 用 ; 分隔 | material;rare;outpost |

规则：

```text
列表分隔符统一用 ;
键值分隔符统一用 :
不要在同一个单元格内写 JSON，除非确实无法表达。
所有 ID 使用英文小写、数字和下划线。
所有显示名可以使用中文。
```

推荐 ID 风格：

```text
scrap_metal
cloth_dirty
backpack_small_reinforced
consumable_stability_candy
research_consumable_slot_1
recipe_backpack_small
```

---

## 4. 数据分层原则

## 4.1 静态定义与动态实例分离

静态定义来自 `.tab`：

```text
物品名
品质
重量
图标
描述
装备槽位
装备效果
消耗品效果
研究需求
制作材料
```

动态实例来自存档或局内运行：

```text
item_instance_id
当前位置
当前数量
当前耐久
是否已装备
本局穿戴时长
是否已学习
是否已放入安全存储
```

示例：

```text
equipment.tab 定义“小型加固背包”的最大耐久、重量、图标和效果。
EquipmentInstance 只保存这一个背包实例的当前耐久、来源和本局穿戴时长。
```

---

## 4.2 物品基表与扩展表

`items.tab` 是所有可进入背包、仓库、掉落或奖励系统的物品基表。

其他表是扩展表：

```text
materials.tab 扩展材料。
equipment.tab 扩展装备。
consumables.tab 扩展消耗品。
recipes.tab 扩展配方开放。
```

规则：

```text
凡是能进入背包或仓库的对象，必须先在 items.tab 中存在。
equipment.tab 的 id 必须能在 items.tab 中找到。
consumables.tab 的 id 必须能在 items.tab 中找到。
materials.tab 的 id 必须能在 items.tab 中找到。
recipes.tab 的 id 必须能在 items.tab 中找到。
```

设计原因：

```text
背包、仓库、掉落、结算都只需要先识别 item_id。
具体是装备、材料还是消耗品，再按 item_type 查询扩展定义。
```

---

## 5. 表格清单

## 5.1 items.tab

用途：

```text
定义所有物品的基础信息。
背包、仓库、掉落、结算、制造所、货台、图鉴、UI 都优先读取这张表。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 物品唯一ID |
| item_type | enum | material/outpost_material/equipment/consumable/rare/sale_good |
| name | string | 显示名 |
| quality | enum | C/B/A/S |
| stackable | bool | 是否可堆叠 |
| stack_limit | int | 堆叠上限 |
| weight | float | 单个重量 |
| icon | path | 图标路径 |
| sellable | bool | 历史兼容字段；新经济不表示仓库原材料可直接变现 |
| sell_currency_id | string | 历史兼容字段；成交货币由货台结算读取 |
| sell_value | int | 历史兼容字段；新经济优先使用可售物资基础成交价 |
| base_sale_value | int | 可售物资基础成交价，仅 item_type=sale_good 时有效 |
| description | string | 描述文本 |
| tags | list | 标签 |
| enabled_version | string | 启用版本 |

当前 V0.2 经济规则覆写：

```text
材料、基础零件和可售物资允许按 stackable / stack_limit 堆叠，以支撑一次探索带回足够制造材料并支撑白天开店供货。
装备、耐久不同的消耗品、任务物品仍按单件实例处理。
仓库、制造所和货台必须按 item_id + quality + 状态字段判断是否可合堆，不能无脑合并所有同 ID 物品。
```

示例表头：

```text
id	item_type	name	quality	stackable	stack_limit	weight	icon	sellable	sell_currency_id	sell_value	base_sale_value	description	tags	enabled_version
```

示例行：

```text
scrap_metal	material	废金属	C	true	20	0.1	res://assets/icons/items/scrap_metal.png	false	mine_coin	0	0	常见的金属废料，可用于修复和制作。	material;craft;metal	v0.3
sale_good_simple_gear	sale_good	连轴齿轮	C	true	20	0.1	res://assets/icons/items/simple_gear.png	false	mine_coin	0	12	由废金属和布条加工出的基础可售物资。	sale_good;shop_goods;metal	v0.3
```

局外道具详情 Tooltip 读取规则：

```text
局外仓库、制造所、研究所、货台、图鉴、夜晚出发准备中的道具图标 hover Tooltip 不新增表字段。
道具图标、名称、品质、类型、描述都从 items.tab 读取。
货币显示名和图标从 currencies.tab 读取。
Tooltip 不显示仓库原材料“直接出售”价格；只有货台/需求榜上下文可显示可售物资预估基础成交价。
description 为空时，Tooltip 显示“暂无记录。”。
品质只使用 C/B/A/S；不要再配置额外品质或独立超稀有掉落池。
```

---

## 5.1.5 currencies.tab

用途：

```text
定义货币静态信息。
玩家实际持有数量不写在表里，只按 currency_id 保存在存档中。
```

V0.1 只有一种货币：

```text
mine_coin / 矿币
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 货币唯一 ID |
| name | string | 显示名 |
| icon | path | 图标路径 |
| currency_type | enum | standard/premium/event/debug |
| sort_order | int | UI 显示排序 |
| enabled_version | string | 启用版本 |
| description | string | 描述文本 |

示例表头：

```text
id	name	icon	currency_type	sort_order	enabled_version	description
```

示例行：

```text
mine_coin	矿币	res://assets/icons/currency/mine_coin.png	standard	10	v0.1	废土城镇间通用的矿区铸币。
```

规则：

```text
存档保存 currency_id -> amount。
不要在存档中保存 name、icon、currency_type。
后续新增货币时新增 currencies.tab 行，并在玩家存档 currencies 字典中增加对应 key。
currency_id 一旦进入存档，按稳定接口处理，不随意改名。
```

---

## 5.2 materials.tab

用途：

```text
定义材料分类、制作价值、商品化价值和前哨用途。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 材料ID，必须存在于 items.tab |
| material_category | enum | basic/part/component/food_medical/weapon_gear/luxury/outpost |
| commerce_value | int | 商品化用途权重 |
| crafting_value | int | 制作用途权重 |
| outpost_material | bool | 是否用于前哨修复 |
| default_drop_weight | int | 默认掉落权重 |

示例表头：

```text
id	material_category	commerce_value	crafting_value	outpost_material	default_drop_weight
```

示例行：

```text
scrap_metal	basic	2	2	false	100
```

---

## 5.3 equipment.tab

用途：

```text
定义装备类型、槽位、耐久、属性效果、外观和拆解信息。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 装备ID，必须存在于 items.tab |
| type | enum | backpack/hat/coat/shoes/tool/special |
| slot | enum | HEAD/BODY/HAND/LEG/BACK/SPECIAL |
| name | string | 装备名 |
| quality | enum | C/B/A/S |
| weight | float | 装备重量，原则上与 items.tab 保持一致 |
| durability_max | int | 最大耐久 |
| initial_durability_min | int | 掉落时最小初始耐久 |
| initial_durability_max | int | 掉落时最大初始耐久 |
| durability_drain_multiplier | float | 按穿戴时长扣耐久时的装备系数 |
| effect_ids | list | 装备效果ID列表 |
| effect_values | params | 装备效果参数 |
| appearance_scene | path | 局内外观场景路径 |
| icon | path | 图标路径 |
| description | string | 描述文本 |
| dismantle_group | string | 拆解掉落组 |
| drop_tags | list | 掉落标签 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	type	slot	name	quality	weight	durability_max	initial_durability_min	initial_durability_max	durability_drain_multiplier	effect_ids	effect_values	appearance_scene	icon	description	dismantle_group	drop_tags	enabled_version
```

示例行：

```text
backpack_small_reinforced	backpack	BACK	小型加固背包	C	1.0	100	100	100	1.0	add_carry_weight	amount:3	res://assets/equipment/backpack_small.tscn	res://assets/icons/equipment/backpack_small.png	加固过的小型背包，可略微提高负重。	dismantle_cloth_basic	backpack;crafted	v0.3
```

---

## 5.4 consumables.tab

用途：

```text
定义消耗品效果、使用条件、冷却、图标和表现。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 消耗品ID，必须存在于 items.tab |
| name | string | 消耗品名 |
| category | enum | stability/medical/tool/buff |
| weight | float | 重量，原则上与 items.tab 保持一致 |
| effect_id | string | 使用后触发的效果ID |
| effect_params | params | 效果参数 |
| cooldown_seconds | float | 使用冷却 |
| use_condition | string | 使用条件 |
| icon | path | 图标路径 |
| appearance_scene | path | 局内表现资源 |
| description | string | 描述文本 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	name	category	weight	effect_id	effect_params	cooldown_seconds	use_condition	icon	appearance_scene	description	enabled_version
```

示例行：

```text
stability_candy	安定糖	stability	0.1	restore_stability	amount:15	3	stability_not_full	res://assets/icons/consumables/stability_candy.png	res://assets/effects/use_stability_candy.tscn	能短暂稳定情绪的小糖块。	v0.3
```

---

## 5.5 effects.tab

用途：

```text
定义消耗品效果、装备效果和后续 Buff 效果的注册信息。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 效果ID |
| effect_type | enum | instant/stat_modifier/timed_modifier/unlock |
| target_stat | string | 目标属性 |
| default_params | params | 默认参数 |
| stack_rule | enum | none/replace/add/max |
| duration_seconds | float | 持续时间，0 表示瞬时或永久 |
| icon | path | Buff 或效果图标 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	effect_type	target_stat	default_params	stack_rule	duration_seconds	icon	enabled_version
```

示例行：

```text
restore_stability	instant	stability	amount:15	none	0	res://assets/icons/effects/restore_stability.png	v0.3
```

---

## 5.6 research.tab

用途：

```text
定义研究节点、等级、矿币成本、前置条件和解锁效果。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| research_id | string | 研究线 ID，同一研究多档共用同一个 ID |
| display_name | string | 当前档位显示名 |
| category | enum | storage/crafting/consumable/equipment/outpost |
| level | int | 当前等级 |
| max_level | int | 最大等级 |
| required_items | requirements | 历史字段；永久研发不再消耗材料，必须留空或由兼容层忽略 |
| required_currency_id | string | 货币 ID，例如 mine_coin |
| required_currency_amount | int | 货币消耗 |
| required_conditions | string | 章节、任务、店铺等级、任务条件、设备等前置条件 |
| effect_type | string | 研究效果类型 |
| effect_value | float | 最终生效值，不是增量 |
| enabled | bool | 是否启用 |
| enabled_version | string | 启用版本 |
| description | string | 描述 |

示例表头：

```text
research_id	display_name	category	level	max_level	required_items	required_currency_id	required_currency_amount	required_conditions	effect_type	effect_value	enabled	enabled_version	description
```

示例行：

```text
inventory_slots	背包改装 I	storage	1	3		mine_coin	120		inventory_slots	12	true	v0.2	永久提高玩家局内背包容量至 12 格。
```

---

## 5.7 recipes.tab

用途：

```text
定义制作配方、产物、材料消耗、研究需求和配方开放需求。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 配方ID |
| name | string | 配方名 |
| category | enum | equipment/consumable/material/tool |
| output_item | string | 产物物品ID |
| output_count | int | 产物数量 |
| required_items | requirements | 材料需求 |
| required_research | list | 前置研究 |
| required_conditions | string | 前置配方开放 |
| craft_time_seconds | float | 制作时间，V0.2 可为 0 |
| output_quality | enum | 产物品质 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	name	category	output_item	output_count	required_items	required_research	required_conditions	craft_time_seconds	output_quality	enabled_version
```

示例行：

```text
recipe_stability_candy	制作安定糖	consumable	stability_candy	1	sugar_pack:1;medical_powder:1	research_consumable_slot_1		0	C	v0.3
```

---

## 5.9 drop_tables.tab

用途：

```text
定义容器、区域、稀有度与物品掉落池。
```

V0.3 如果掉落还简单，可以先不拆。

后续建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 掉落表ID |
| context | string | 使用场景，如 container_small / container_safe |
| item_id | string | 掉落物品ID |
| min_count | int | 最小数量 |
| max_count | int | 最大数量 |
| weight | int | 权重 |
| required_tags | list | 需要满足的标签 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	context	item_id	min_count	max_count	weight	required_tags	enabled_version
```

---

### 5.9.1 资源闭环与地图生态扩展表

以下表用于承接资源类别、地图资源生态、店面设备和出门前目标面板。它们可以在 V0.3 后分批接入，但字段口径应提前统一，避免后续再次出现“局内随机捡、局外完全用不上”的断裂。

#### resource_categories.tab

用途：定义玩家可见资源类别。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| category_id | string | 类别 ID，如 basic/part/component/food_medical/weapon_gear/luxury/outpost |
| display_name | string | 玩家可见名称 |
| stack_policy | enum | material_stack/small_stack/instance_only |
| default_stack_limit | int | 默认堆叠上限 |
| primary_outlet | enum | sale/craft/equipment/fixture/order |
| source_hint | string | 常见来源描述 |
| enabled_version | string | 启用版本 |

#### resource_outlets.tab

用途：定义常规资源的保底出口。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| item_id | string | 资源物品 ID |
| category_id | string | 资源类别 ID |
| outlet_type | enum | basic_sale/direct_sale/convert/craft_fixture/craft_equipment/order |
| target_id | string | 商品、配方、转化或订单 ID |
| min_chapter | int | 最早出现章节 |
| priority | int | 展示优先级 |
| enabled_version | string | 启用版本 |

#### map_resource_profiles.tab

用途：定义每张地图的主要产出、次要产出和风险。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| map_id | string | 地图 ID |
| display_name | string | 地图名称 |
| primary_categories | list | 主要资源类别 |
| secondary_categories | list | 次要资源类别 |
| special_tags | list | 特殊资源或事件标签 |
| base_risk | int | 基础风险等级 |
| default_state | enum | rich/searched/poor/recovering/event |
| enabled_version | string | 启用版本 |

#### room_resource_profiles.tab

用途：定义房间类型对资源池的二次筛选。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| room_profile_id | string | 房间资源配置 ID |
| room_type | string | 房间类型 |
| category_bias | list | 房间倾向资源类别 |
| container_bias | list | 常见容器类型 |
| rare_tag_bias | list | 稀有标签倾向 |
| enabled_version | string | 启用版本 |

#### location_state_rules.tab

用途：定义地点状态对数量、稀有度和恢复的影响。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| state_id | enum | rich/searched/poor/recovering/event |
| quantity_multiplier | float | 数量修正 |
| rare_multiplier | float | 稀有权重修正 |
| regen_days | int | 自然恢复所需天数 |
| unique_drop_policy | enum | allow_once/blocked/event_only |
| ui_label | string | UI 显示文本 |

#### shop_fixture_slots.tab

用途：定义店面固定槽位。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| slot_id | string | 槽位 ID |
| display_name | string | 槽位显示名 |
| allowed_fixture_types | list | 允许设备类型 |
| unlock_conditions | string | 解锁条件 |
| first_version_required | bool | 是否首版必做 |
| enabled_version | string | 启用版本 |

#### shop_fixtures.tab

用途：定义店面设备、矿币价格、电力和经营效果。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| fixture_id | string | 设备 ID |
| display_name | string | 设备名 |
| fixture_type | enum | generator/shelf/workbench/refrigerator/storage/sign/intel/security |
| slot_id | string | 默认安装槽位或槽位类型 |
| tier | int | 设备档位 |
| power_provided | int | 发电机供电，非发电设备为 0 |
| power_cost | int | 启用耗电 |
| coin_price | int | 矿币购买价格 |
| craft_recipe_id | string | 可选制作配方 |
| unlock_conditions | string | 解锁条件 |
| effect_type | enum | shelf_capacity/unlock_recipe/storage_limit/demand_bias/intel_hint/risk_reduce |
| effect_value | string | 效果参数 |
| enabled_version | string | 启用版本 |

#### fixture_vendor.tab

用途：定义设备商人出售内容。

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| vendor_id | string | 商人或供应商 ID |
| fixture_id | string | 可售设备 ID |
| unlock_conditions | string | 解锁条件 |
| price_modifier | float | 价格修正 |
| stock_policy | enum | always/limited/rotation |
| enabled_version | string | 启用版本 |

---

## 5.10 outpost_requirements.tab

用途：

```text
定义前哨站修复阶段、所需材料和完成奖励。
```

V0.3 如果前哨需求仍然很少，可以先保留在脚本或 JSON 配置中。

后续建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 前哨需求ID |
| outpost_id | string | 前哨站ID |
| stage | int | 修复阶段 |
| required_items | requirements | 材料需求 |
| reward_effects | list | 完成后效果 |
| description | string | UI 描述 |
| enabled_version | string | 启用版本 |

示例表头：

```text
id	outpost_id	stage	required_items	reward_effects	description	enabled_version
```

---

## 5.11 scene_random_events.tab

用途：

```text
定义从第 3 日开始进入事件池的场景随机事件。
```

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| event_id | string | 事件 ID |
| display_name | string | 调试/提示显示名 |
| slot | enum | threat/time_modifier/map_blocker/weather/hazard/reward |
| min_day | int | 最早自然出现日 |
| guaranteed_day | int | 必出日，可空 |
| daily_chance | float | 自然概率 |
| conflict_group | string | 互斥组，可空 |
| can_stack | bool | 是否可与其他槽位叠加 |
| gm_forceable | bool | GM 是否可强制 |
| payload | keyvalue | 事件参数 |
| notes | string | 策划备注 |

示例表头：

```text
event_id	display_name	slot	min_day	guaranteed_day	daily_chance	conflict_group	can_stack	gm_forceable	payload	notes
```

当前建议行：

```text
monster_presence	怪物出现	threat	3	3	0.50		false	true	monster_count=4;spawn_group=monster_spawn_street	第三日必出
super_time	超级时间	time_modifier	3		0.10	run_duration	false	true	duration_seconds=480	本局8分钟
short_time	超短时间	time_modifier	3		0.10	run_duration	false	true	duration_seconds=210	本局3分30秒
road_obstacle	随机障碍	map_blocker	3		0.30		true	true	count_min=2;count_max=4;spawn_group=random_obstacle_spawn	玩家阻挡怪物忽略
```

---

## 5.12 monster_defs.tab

用途：

```text
定义怪物基础移动、视野、警戒和碰撞伤害参数。
```

示例表头：

```text
monster_id	display_name	patrol_speed	charge_speed	vision_angle	vision_radius	warning_seconds	stability_damage	patrol_radius
```

---

## 5.13 random_obstacle_defs.tab

用途：

```text
定义随机障碍可用资源、阻挡形状、碰撞规则和权重。
```

示例表头：

```text
obstacle_id	display_name	texture_path	block_shape	collider_size	player_blocks	monster_blocks	weight
```

规则：

```text
player_blocks 必须为 true。
monster_blocks 必须为 false。
ground_decal_overlay_002.png 作为障碍时必须配合不可见碰撞体。
```

---

## 6. 数据引用关系

## 6.1 推荐引用图

```text
items.tab
  materials.tab
  equipment.tab
  consumables.tab
  recipes.tab

effects.tab
  equipment.tab
  consumables.tab
  research.tab

research.tab
  recipes.tab

recipes.tab
  recipes.tab

recipes.tab
  items.tab

drop_tables.tab
  items.tab
  map_resource_profiles.tab
  room_resource_profiles.tab
  location_state_rules.tab

map_resource_profiles.tab
  resource_categories.tab

room_resource_profiles.tab
  resource_categories.tab

resource_outlets.tab
  items.tab
  resource_categories.tab
  recipes.tab

shop_fixtures.tab
  shop_fixture_slots.tab
  recipes.tab

outpost_requirements.tab
  items.tab

currencies.tab
  sale_good 结算货币配置
  items.tab.sell_currency_id（仅历史兼容字段非空时校验）
```

---

## 6.2 关键校验规则

Godot 启动或开发调试时必须校验：

```text
所有 id 不重复。
所有引用的 item_id 必须存在于 items.tab。
所有 equipment.tab 的 id 必须在 items.tab 中 item_type = equipment。
所有 consumables.tab 的 id 必须在 items.tab 中 item_type = consumable。
所有 materials.tab 的 id 必须在 items.tab 中 item_type = material 或 outpost_material。
所有 effect_id 必须存在于 effects.tab，除非该效果由代码内置并明确登记。
所有 recipe.output_item 必须存在于 items.tab。
所有 required_items 中的 item_id 必须存在于 items.tab。
历史兼容字段 items.tab.sell_currency_id 非空时必须存在于 currencies.tab；新经济不要求原材料配置该字段。
所有 currencies.tab.id 不重复。
`sellable`、`sell_value`、`sell_currency_id` 为历史兼容字段，不得作为仓库直接出售的实现依据。
所有 `item_type = sale_good` 的物品必须配置 `base_sale_value > 0`。
所有可售物资的成交货币必须能从店铺结算规则或 currencies.tab 映射到有效 currency_id，当前默认为 mine_coin。
所有 required_research 必须存在于 research.tab。
所有 required_conditions 必须引用有效条件来源，例如 research、chapter、task、shop_level、fixture、vendor 或 location_event。
所有 materials.tab.material_category 必须存在于 resource_categories.tab，除非该扩展表尚未接入当前版本。
所有常规 material 必须至少存在一个 resource_outlets.tab 出口，剧情物、唯一物和订单物可例外但必须有明确标签。
所有 map_resource_profiles.primary_categories / secondary_categories 必须存在于 resource_categories.tab。
所有 shop_fixtures.slot_id 必须能匹配 shop_fixture_slots.tab，且设备类型必须被槽位允许。
所有启用设备的 power_cost 与发电机 power_provided 必须满足电力系统校验；超过上限时拒绝启用，不做随机停机。
research.tab 只允许消耗矿币，不允许把局内随机材料写成研发消耗。
所有 icon 路径允许为空，但填写后资源必须存在。
所有 enabled_version 不能高于当前构建允许版本，除非调试模式开启。
```

校验失败时：

```text
开发模式：弹出错误面板并阻止进入游戏。
发布模式：记录错误并禁用错误行，避免崩溃。
```

V0.3 建议先使用开发模式强校验。

---

## 7. Godot 实现建议

## 7.1 推荐模块

```text
TabDataLoader
DataRegistry
DataValidator
ItemDefinition
MaterialDefinition
EquipmentDefinition
ConsumableDefinition
EffectDefinition
ResearchDefinition
RecipeDefinition
RecipeDefinition
DropTableDefinition
ResourceCategoryDefinition
ResourceOutletDefinition
MapResourceProfileDefinition
RoomResourceProfileDefinition
LocationStateRuleDefinition
ShopFixtureSlotDefinition
ShopFixtureDefinition
FixtureVendorDefinition
OutpostRequirementDefinition
```

---

## 7.2 TabDataLoader

职责：

```text
读取 .tab 文件。
跳过空行。
跳过 # 注释行。
按第一行表头解析字段。
返回 Array[Dictionary]。
保留原始行号，方便报错。
```

伪代码：

```gdscript
func load_tab(path: String) -> Array[Dictionary]:
    var file := FileAccess.open(path, FileAccess.READ)
    var rows: Array[Dictionary] = []
    var headers: PackedStringArray = []
    var line_index := 0

    while not file.eof_reached():
        var line := file.get_line()
        line_index += 1

        if line.strip_edges().is_empty():
            continue

        if line.begins_with("#"):
            continue

        var cells := line.split("\t", false)

        if headers.is_empty():
            headers = cells
            continue

        var row := {}
        for i in headers.size():
            var key := headers[i]
            var value := ""
            if i < cells.size():
                value = cells[i].strip_edges()
            row[key] = value

        row["_source_path"] = path
        row["_line"] = line_index
        rows.append(row)

    return rows
```

注意：

```text
这是伪代码，实际实现时需要处理 FileAccess.open 失败。
不要在 TabDataLoader 中写具体业务规则。
```

---

## 7.3 DataRegistry

职责：

```text
统一加载所有表。
生成 Definition 字典。
提供按 id 查询的接口。
避免每个系统重复读文件。
```

推荐接口：

```text
get_item(id)
get_material(id)
get_equipment(id)
get_consumable(id)
get_effect(id)
get_research(id)
get_recipe(id)
get_resource_category(id)
get_resource_outlets(item_id)
get_map_resource_profile(map_id)
get_location_state_rule(state_id)
get_shop_fixture(fixture_id)
get_shop_fixture_slot(slot_id)
has_item(id)
reload_all_for_debug()
```

规则：

```text
游戏启动时加载一次。
开发调试可允许热重载。
正式版本不做运行中热重载。
```

---

## 7.4 DataValidator

职责：

```text
检查字段完整性。
检查 ID 唯一性。
检查跨表引用。
检查数值范围。
检查版本可用性。
检查资源路径是否存在。
```

推荐输出：

```text
[ERROR] equipment.tab:12 item_id backpack_a not found in items.tab
[ERROR] recipes.tab:8 required_items contains unknown id battery_old
[WARN] items.tab:20 icon is empty
```

错误等级：

| 等级 | 含义 | 处理 |
|---|---|---|
| ERROR | 会导致逻辑错误 | 阻止进入游戏 |
| WARN | 资源或表现缺失 | 允许运行但提示 |
| INFO | 可优化项 | 只打印日志 |

---

## 8. 版本字段规则

## 8.1 enabled_version

每张表都建议包含：

```text
enabled_version
```

用途：

```text
标记该行从哪个版本开始启用。
方便提前写未来内容，但不在当前版本加载。
方便保留废弃数据用于对比。
```

示例：

```text
v0.3
v0.4
v1.0
disabled
prototype
```

读取规则：

```text
enabled_version 为空：默认启用，但不推荐。
enabled_version = disabled：不加载。
enabled_version 高于当前构建版本：不加载。
enabled_version <= 当前构建版本：加载。
prototype：只在开发模式加载。
```

---

## 8.2 废弃数据处理

不建议直接删除已进入存档的 ID。

推荐做法：

```text
短期废弃：enabled_version = disabled。
长期废弃：保留迁移表或存档兼容逻辑后再删除。
重命名 ID：新增新 ID，旧 ID 通过迁移表转换。
```

原因：

```text
玩家仓库、背包、装备实例、研究进度都可能保存了旧 ID。
直接删除会导致存档无法解析。
```

---

## 9. 存档兼容规则

存档里不保存完整静态数据。

存档只保存：

```text
item_id
item_instance_id
currency_id
count
durability_current
source
flags
research_completed_ids
unlocked_recipe_ids
```

读取存档时：

```text
先加载 DataRegistry。
再用存档中的 id 查询静态定义。
如果 id 已废弃但有迁移规则，转成新 id。
如果 id 缺失且无法迁移，将该实例转成 unknown_item 或放入错误隔离区。
```

V0.3 可以先不做复杂迁移，但需要预留：

```text
SaveDataVersion
DataVersion
UnknownItemFallback
```

---

## 10. 数值平衡规则

## 10.1 表格只给基础值

表格中允许写：

```text
重量
品质
耐久上限
掉落权重
效果数值
制作材料数量
研究矿币成本
研究前置条件
```

不建议写：

```text
复杂公式。
依赖局内状态的表达式。
需要运行脚本计算的条件。
```

例如：

```text
durability_drain_multiplier = 1.2
```

而不是：

```text
if_rain_then_drain_x2
```

雨天、受伤、战斗等活动倍率应该由代码中的耐久服务计算。

---

## 10.2 装备耐久与表格关系

装备按穿戴时长扣耐久时，表格提供：

```text
durability_max
durability_drain_multiplier
```

代码提供：

```text
equipped_seconds_this_run
drain_rate_per_minute
source_multiplier
activity_multiplier
max_loss_ratio
```

公式仍以 11 文档为准：

```text
loss_ratio = equipped_minutes * drain_rate_per_minute * source_multiplier * activity_multiplier * equipment_multiplier
durability_loss = durability_max * loss_ratio
```

`equipment_multiplier` 来自：

```text
equipment.tab.durability_drain_multiplier
```

---

## 11. 美术资源字段规范

## 11.1 icon 字段

图标路径推荐：

```text
res://assets/icons/items/item_id.png
res://assets/icons/equipment/item_id.png
res://assets/icons/consumables/item_id.png
```

规则：

```text
icon 可以先为空。
用于 UI 的物品必须最终配置 icon。
缺失 icon 时使用 fallback_unknown_icon。
```

---

## 11.2 appearance_scene 字段

局内表现路径推荐：

```text
res://assets/equipment/backpack_small.tscn
res://assets/effects/use_stability_candy.tscn
```

规则：

```text
装备需要显示在角色身上时填写 appearance_scene。
消耗品只有使用表现时才填写 appearance_scene。
材料和普通道具通常不需要 appearance_scene。
```

---

## 11.3 后续 GPT 生图提示词关系

后续生成美术提示词时，可从表格提取：

```text
name
quality
description
tags
icon
appearance_scene
category
type
slot
```

示例生成方向：

```text
根据 equipment.tab 生成装备 icon 提示词。
根据 consumables.tab 生成消耗品 icon 提示词。
根据 items.tab + materials.tab 生成材料图标提示词。
根据 appearance_scene 需求生成角色外观部件提示词。
```

---

## 12. 命名规范

## 12.1 ID 命名

推荐：

```text
小写英文
下划线
名词优先
分类前缀可选
```

推荐示例：

```text
scrap_metal
cloth_dirty
medicine_powder
backpack_small_reinforced
stability_candy
research_consumable_slot_1
recipe_stability_candy
research_backpack_1
```

不推荐：

```text
物品01
BackpackSmall
backpack-small
new_item
test
```

---

## 12.2 显示名命名

显示名可以使用中文。

规则：

```text
短。
具体。
能体现用途或质感。
同类物品保持命名结构一致。
```

示例：

```text
废金属
脏布条
安定糖
小型加固背包
破旧耳机
```

---

## 13. 电子表格维护规则

## 13.1 编辑规则

策划或 AI 生成表格后，需要遵守：

```text
不要合并单元格。
不要删除表头。
不要改字段名，除非同步修改读取代码。
不要在单元格内换行。
不要使用自动科学计数法保存 ID。
保存时保持 TAB 分隔。
```

推荐使用：

```text
Excel
WPS
LibreOffice Calc
VS Code
任意纯文本编辑器
```

保存时需要确认：

```text
文件仍然是 .tab。
分隔符仍然是 TAB。
编码仍然是 UTF-8。
```

---

## 13.2 AI 生成规则

让 AI 生成表格时，提示词必须要求：

```text
只输出 TSV 内容。
第一行是表头。
字段顺序必须与文档一致。
不要输出 Markdown 表格。
不要输出解释。
列表字段用 ;。
需求字段用 item_id:count;item_id:count。
参数字段用 key:value;key:value。
```

示例提示词结构：

```text
请根据《废土生存法则》数据配置表规范，生成 equipment.tab 的 10 行装备数据。
要求：
1. 只输出 TSV 内容。
2. 第一行必须是指定表头。
3. ID 使用小写英文和下划线。
4. 不要输出 Markdown 表格。
5. effect_values 使用 key:value;key:value 格式。
```

---

## 14. 调试工具要求

V0.3 建议增加以下调试入口：

```text
重新加载所有 TAB 配置。
检查所有配置错误。
查看某个 item_id 的完整合并定义。
查看某个装备的耐久参数。
查看某个配方的材料需求。
查看某个研究节点的前置链。
查看某个效果的注册来源。
导出当前 DataRegistry 为 JSON 调试快照。
```

调试输出示例：

```text
item_id: backpack_small_reinforced
base: items.tab line 12
equipment: equipment.tab line 4
effects: add_carry_weight amount:3
icon: exists
enabled: true
```

---

## 15. 验证清单

## 15.1 文件验证

```text
所有必要 .tab 文件能被读取。
空行能跳过。
# 注释行能跳过。
表头缺字段时能报错。
多余字段不导致崩溃，但给出 WARN。
```

---

## 15.2 ID 验证

```text
重复 id 会报错。
非法 id 会报错。
跨表引用缺失会报错。
item_type 与扩展表不匹配会报错。
```

---

## 15.3 数值验证

```text
weight 不能小于 0。
stack_limit 不能小于 1。
durability_max 不能小于 1。
initial_durability_min 不能大于 initial_durability_max。
drop weight 不能小于 0。
craft_time_seconds 不能小于 0。
```

---

## 15.4 资源验证

```text
填写 icon 时，资源路径必须存在。
填写 appearance_scene 时，资源路径必须存在。
缺失可选资源时给 WARN。
缺失必需资源时给 ERROR。
```

---

## 16. 当前设计体检与建议

## 16.1 合理点

当前方案合理的地方：

```text
用 .tab 而不是复杂数据库，符合单机独立游戏早期制作成本。
items.tab 作为基表，可以统一背包、仓库、掉落和结算。
装备、消耗品、配方开放用扩展表，避免一张表过度膨胀。
enabled_version 能支持提前规划未来内容。
静态定义与动态实例分离，适合存档兼容。
```

---

## 16.2 需要注意的点

需要提前规避：

```text
不要让表格字段无限增加，否则会变成难维护的巨表。
不要在表格中写复杂条件表达式，否则调试困难。
不要频繁改 ID，ID 一旦进入存档就要视为稳定接口。
不要让 items.tab 和扩展表的 weight、name、icon 长期不一致。
不要让美术路径过早卡住玩法验证，早期可以用 fallback icon。
```

建议：

```text
V0.3 先实现 items.tab / equipment.tab / consumables.tab / effects.tab。
研究和制作仍可先半配置化。
等局外成长稳定后，再把 research.tab / recipes.tab / recipes.tab 全量接入。
```

---

## 17. V0.3 最小交付规格

V0.3 若要开始配置表系统，最小需要：

```text
TabDataLoader 可读取 .tab。
DataRegistry 可加载 items.tab 和 currencies.tab。
ItemDefinition 可被背包、仓库、结算、制造所、货台、图鉴引用。
CurrencyDefinition 可被货台结算、局外货币栏、研究制造消耗和存档读取引用。
equipment.tab 可生成 EquipmentDefinition。
consumables.tab 可生成 ConsumableDefinition。
effects.tab 可注册基础效果。
DataValidator 能检查重复 ID 和缺失引用。
调试界面能重新加载数据。
```

V0.3 可以暂缓：

```text
drop_tables.tab。
outpost_requirements.tab。
复杂存档迁移。
多语言文本表。
运行中热更新。
```

---

## 18. 后续待拆分内容

后续可以继续拆分：

```text
14_耳机模块与音乐系统.md
15_多人模式预留架构.md
16_Godot工程结构与代码模块规划.md
17_美术资源规格与GPT生图提示词规范.md
18_数据校验工具与编辑器插件规范.md
19_数值平衡表与掉落权重规范.md
20_UI视觉规范与界面资源Sheet提示词.md
```

---

## 19. 本文档结论

数据配置表不是为了把系统做复杂，而是为了让内容生产变得可控。

V0.3 / V0.4 的目标应是：

```text
脚本少写内容。
表格多写定义。
校验提前发现错误。
存档只保存动态状态。
AI 后续可以稳定生成表格、代码和美术提示词。
```

只要 `items.tab` 作为基表稳定下来，后续装备、消耗品、材料、研究和制作都可以逐步转向数据驱动。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 13_数据配置表与TAB规范.md
  作为 开发者
  我希望按本文规则完成 13_数据配置表与TAB规范.md
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

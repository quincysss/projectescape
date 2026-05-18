# 07-13 Godot 模块与数据配置

> 来源文档：`07_背包_存储与负重系统_修订版_废土生存法则.md`
> 施工补充：开工前必须读取 `16_模块功能规则细化与AI开工提示词.md`。

## 1. 推荐模块

```text
systems/inventory/item_definition.gd
systems/inventory/item_stack.gd
systems/inventory/inventory_grid.gd
systems/inventory/inventory_service.gd
systems/inventory/weight_component.gd
systems/inventory/equipment_slots.gd
systems/inventory/storage_container.gd
systems/inventory/storage_service.gd
systems/inventory/inventory_ui.gd
systems/inventory/storage_ui.gd
systems/inventory/inventory_debug_panel.gd
```

## 2. 推荐数据

```text
data/items/item_definitions.tres
data/items/item_quality_colors.tres
data/inventory/default_player_inventory.tres
data/inventory/home_storage_config.tres
```

## 3. 服务职责

InventoryService：

- 管理玩家背包。
- 提供 try_add_item。
- 提供 discard_stack。
- 导出结算物品。

StorageService：

- 管理家中存储。
- 管理临时存储。
- 提供转移接口。

WeightComponent：

- 计算负重。
- 发出 weight_changed。
- 提供移动惩罚倍率。

## 4. AI/MCP 开工提示词

```text
请建立 07 背包/存储/负重系统的 Godot 模块骨架。

要求：
1. 创建 ItemDefinition、ItemStack、InventoryGrid、InventoryService、WeightComponent、StorageContainer、StorageService。
2. UI 脚本只调用服务接口，不直接改物品数据。
3. 05 容器通过 try_add_item 接入。
4. 06 前哨存储通过 StorageService 创建 temporary storage。
5. 配置尽量使用 Resource 或项目已有数据格式。
```

## 5. 验收标准

- 脚本边界清楚。
- 外部系统有稳定接口。
- 数据定义可配置。

## 6. 暂不实现

- 完整视觉皮肤。
- 复杂装备属性。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 07-13 Godot 模块与数据配置
  作为 开发者
  我希望按本文规则完成 07-13 Godot 模块与数据配置
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "07_背包_存储与负重系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。

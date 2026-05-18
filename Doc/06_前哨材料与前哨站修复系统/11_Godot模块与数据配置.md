# 06-11 Godot 模块与数据配置

> 来源文档：`06_前哨材料与前哨站修复系统_修订版_废土生存法则.md`
> 施工补充：开工前必须读取 `14_模块功能规则细化与AI开工提示词.md`。

## 1. 实现目标

汇总 06 模块推荐 Godot 脚本、资源和配置结构，让后续实现能从明确文件边界开始。

## 2. 推荐模块

```text
systems/outposts/outpost_definition.gd
systems/outposts/outpost_manager.gd
systems/outposts/outpost_entity.gd
systems/outposts/outpost_material_definition.gd
systems/outposts/outpost_material_spawner.gd
systems/outposts/outpost_repair_interaction.gd
systems/outposts/outpost_storage_adapter.gd
systems/outposts/outpost_debug_panel.gd
```

## 3. 推荐资源

```text
data/outposts/outpost_stage_01.tres
data/outposts/outpost_stage_02.tres
data/outposts/outpost_materials.tres
data/outposts/outpost_candidate_points.tres
data/outposts/outpost_material_spawn_points.tres
```

如果项目已有地图点位数据格式，应优先复用，不另起孤立格式。

## 4. OutpostManager 职责

- 初始化本局前哨站。
- 选择候选点。
- 管理前哨站列表。
- 转发前哨激活事件。
- 收集结算 payload。

## 5. OutpostMaterialSpawner 职责

- 读取材料点位池。
- 按需求生成材料。
- 处理 90 秒保底。
- 记录拾取。

## 6. OutpostEntity 职责

- 保存状态机。
- 保存需求进度。
- 控制视觉表现。
- 管理修复交互入口。
- 注册/注销安全区。

## 7. AI/MCP 开工提示词

```text
请根据 06 拆分文档建立 Godot 前哨站模块骨架和数据配置。

要求：
1. 创建或复用 systems/outposts 下的脚本。
2. 建立 OutpostDefinition、OutpostManager、OutpostEntity、OutpostMaterialSpawner、OutpostRepairInteraction。
3. 数据优先做成 Resource 或项目已有配置格式，不要全部硬编码。
4. 所有模块通过信号/服务接口和背包、安全区、撤离系统交互。
5. 不要实现与 07 背包系统重复的存储逻辑，只做 adapter。
```

## 8. 验收标准

- 模块文件边界清楚。
- 数据配置可在编辑器或配置文件中调整。
- 前哨系统不复制背包、安全区、撤离系统的核心逻辑。

## 9. 暂不实现

- 完整美术资源。
- 网络同步资源。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 06-11 Godot 模块与数据配置
  作为 开发者
  我希望按本文规则完成 06-11 Godot 模块与数据配置
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "06_前哨材料与前哨站修复系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。

# 10-07 Godot 模块与接口边界

> 来源文档：`10_研究所与制作所系统_修订版_废土生存法则.md`  
> 目标：定义研究、图纸、配方、制作和制造所解锁的脚本边界，避免 UI 直接改核心数据。

## 1. 当前已落地模块

```text
res://scripts/game/research_manager.gd
res://scripts/game/game_state.gd
res://scripts/game/warehouse_manager.gd
res://scripts/game/shelf_inventory_service.gd
res://scripts/game/currency_wallet.gd
res://scripts/base/base_scene.gd
res://setting/research.tab
```

当前 `BaseScene` 已承担研究 UI 和制造所解锁页，后续可继续拆分为独立面板控制器。

## 2. 推荐新增模块

研究：

```text
scripts/game/research_manager.gd
scripts/game/research_effect_applier.gd
```

图纸与配方：

```text
scripts/game/blueprint_manager.gd
scripts/game/recipe_manager.gd
scripts/game/crafting_manager.gd
```

局外 UI：

```text
scripts/base/base_research_panel_controller.gd
scripts/base/base_crafting_panel_controller.gd
scripts/ui/item_tooltip_view.gd
```

章节与功能解锁：

```text
scripts/game/manufacturing_unlock_service.gd
scripts/chapters/chapter_progress_service.gd
```

## 3. GameState 对外接口

研究接口：

```gdscript
func query_research_items(filters: Dictionary = {}) -> Array[Dictionary]
func get_research_quote(research_id: String) -> Dictionary
func complete_research(research_id: String) -> Dictionary
func get_research_level(research_id: String) -> int
func reset_research() -> void
```

研究效果接口：

```gdscript
func get_player_move_speed_multiplier() -> float
func get_inventory_slot_count(default_slots: int) -> int
func get_home_storage_slot_count(default_slots: int) -> int
func get_outpost_storage_slot_count(default_slots: int) -> int
func get_player_max_stability(default_value: float) -> float
func get_warehouse_capacity(default_capacity: int) -> int
```

制造所解锁接口：

```gdscript
func can_unlock_manufacturing_station() -> bool
func unlock_manufacturing_station() -> Dictionary
func can_unlock_advanced_manufacturing_station() -> bool
func unlock_advanced_manufacturing_station() -> Dictionary
```

后续制作接口：

```gdscript
func query_recipes(filters: Dictionary = {}) -> Array[Dictionary]
func get_crafting_quote(recipe_id: String, count: int = 1) -> Dictionary
func craft_recipe(recipe_id: String, count: int = 1) -> Dictionary
func learn_blueprint(blueprint_id: String) -> Dictionary
func convert_same_grade_material(input_items: Array[Dictionary], target_item_id: String) -> Dictionary
```

## 4. Manager 职责

ResearchManager：

```text
加载 research.tab。
计算下一档研究 quote。
检查材料和货币。
调用 WarehouseManager 和 CurrencyWallet 原子扣除。
写入 research_levels。
返回 UI 可展示结果。
```

BlueprintManager：

```text
加载 blueprints.tab。
查询仓库中可学习图纸。
检查配方是否已解锁。
消耗图纸物品。
写入 learned_blueprint_ids 和 unlocked_recipe_ids。
```

RecipeManager：

```text
加载 recipes.tab。
判断配方是否可见、已解锁、可制作。
处理默认解锁、图纸解锁、研究解锁。
区分 basic / advanced 制造所等级。
```

CraftingManager：

```text
生成制作 quote。
检查材料、货币、前置研究、前置图纸和仓库空间。
检查配方产物是 sale_good、equipment 还是 consumable。
原子扣除材料和货币。
生成产物 ItemInstance。
调用 WarehouseManager 入库。
```

ManufacturingUnlockService：

```text
校验第一章目标状态。
校验 5000 mine_coin。
调用 CurrencyWallet 扣币。
写入 advanced_manufacturing_station_unlocked 和 chapter_1_completed。
保存玩家档案。
```

## 5. 信号建议

```gdscript
signal research_completed(research_id: StringName, level: int)
signal research_failed(research_id: StringName, reason: StringName)
signal blueprint_learned(blueprint_id: StringName, recipe_id: StringName)
signal recipe_unlocked(recipe_id: StringName, source: StringName)
signal crafting_completed(recipe_id: StringName, output_item_id: StringName, count: int)
signal crafting_failed(recipe_id: StringName, reason: StringName)
signal advanced_manufacturing_station_unlocked(surface_day: int)
signal sale_good_crafted(recipe_id: StringName, output_item_id: StringName, count: int)
```

## 6. UI 边界

- UI 只展示 quote 和调用服务。
- UI 不直接扣仓库物品。
- UI 不直接扣矿币。
- UI 不直接写 `research_levels`。
- UI 不直接写 `unlocked_recipe_ids`。
- UI 不直接写 `advanced_manufacturing_station_unlocked`。
- UI 不直接把仓库原材料换成货币。

## 7. 保存边界

玩家档案需要保存：

```text
research_levels
learned_blueprint_ids
unlocked_recipe_ids
pending_claim_items
advanced_manufacturing_station_unlocked
chapter_1_completed
currencies
warehouse_items
shelf_items
```

首版如果没有图纸/制作，可先不写 `learned_blueprint_ids`、`unlocked_recipe_ids`、`pending_claim_items`，但字段命名需要预留。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 10-07 Godot 模块与接口边界
  作为 开发者
  我希望按本文规则完成 10-07 Godot 模块与接口边界
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

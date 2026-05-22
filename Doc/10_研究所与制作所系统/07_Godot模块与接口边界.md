# 07_Godot模块与接口边界

> 对应母版章节：13
> 本文件定义研究、配方可用性和制作接口。不存在配方道具或配方来源物管理器。

---

## 1. 推荐模块

```text
ResearchManager
RecipeService
CraftingManager
ResearchEffectApplier
CraftingResultStore
```

---

## 2. RecipeService 职责

```text
加载 recipes.tab。
判断 required_research 与 required_conditions 是否满足。
维护需要永久记录的 unlocked_recipe_ids。
向制作所提供可制作、条件不足和隐藏配方列表。
条件变化时发出 recipe_availability_changed 信号。
```

`RecipeService` 不读取仓库配方道具，不消耗配方物品。

---

## 3. 信号建议

```gdscript
signal recipe_availability_changed(recipe_id: StringName, available: bool)
signal recipe_permanently_unlocked(recipe_id: StringName, source: StringName)
signal craft_started(recipe_id: StringName)
signal craft_completed(recipe_id: StringName, output_item_id: StringName, count: int)
signal craft_failed(recipe_id: StringName, reason: StringName)
```

---

## 4. 接口建议

```text
RecipeService.is_recipe_available(recipe_id) -> bool
RecipeService.get_missing_conditions(recipe_id) -> Array
RecipeService.get_visible_recipes(category) -> Array
CraftingManager.can_craft(recipe_id) -> bool
CraftingManager.craft(recipe_id) -> CraftResult
```

---

## 5. 边界规则

```text
ResearchManager 只处理研究状态和矿币消耗。
RecipeService 只处理配方可用条件。
CraftingManager 只处理材料扣除、产物生成和入库。
WarehouseManager 不负责学习配方。
```

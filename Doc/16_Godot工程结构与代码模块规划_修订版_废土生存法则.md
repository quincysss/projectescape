# 16_Godot工程结构与代码模块规划.md

# 《废土生存法则》Godot 工程结构与代码模块规划（修订版）

> 文档版本：v0.1  
> 所属项目：《废土生存法则》  
> 前置文档：01-15 全部系统规则文档  
> 适用阶段：工程搭建与代码生成提示词准备  
> 文档目标：定义 Godot 工程目录、核心模块边界、数据流、场景结构和命名规则，作为后续生成代码提示词与拆分开发任务的基础。

---

## 1. 本文档一句话说明

Godot 工程要按“系统边界”组织，而不是按临时脚本堆叠。

---

## 2. 工程目录建议

推荐结构：

```text
project-escape/
  assets/
    audio/
    icons/
    sprites/
    tilesets/
    ui/
  data/
    items.tab
    materials.tab
    equipment.tab
    consumables.tab
    effects.tab
    research.tab
    recipes.tab
    blueprints.tab
  scenes/
    boot/
    game/
    run/
    base/
    ui/
    entities/
    containers/
    outposts/
  scripts/
    core/
    data/
    run/
    player/
    containers/
    inventory/
    storage/
    outpost/
    extraction/
    research/
    crafting/
    equipment/
    consumables/
    audio/
    save/
    ui/
    debug/
  tests/
  Doc/
```

规则：

```text
assets 放资源。
data 放配置表。
scenes 放场景。
scripts 放逻辑。
Doc 放设计文档。
```

---

## 3. 启动流程

推荐启动顺序：

```text
BootScene
  加载 ProjectConfig
  加载 DataRegistry
  运行 DataValidator
  加载 SaveGame
  进入 MainMenu 或 BaseScene
```

V0.1 可简化：

```text
直接进入 BaseScene。
调试按钮进入 RunScene。
```

但仍建议保留 BootScene。

---

## 4. 核心单例建议

可作为 Autoload 的模块：

```text
GameApp
DataRegistry
SaveManager
SceneRouter
CommandBus
RunEventBus
AudioManager
DebugManager
```

注意：

```text
不要把所有业务逻辑塞进 Autoload。
Autoload 只负责跨场景生命周期和服务入口。
具体系统仍放在各自 Manager。
```

---

## 5. 场景结构

## 5.1 BaseScene

局外基地场景负责：

```text
仓库入口。
研究所入口。
制作所入口。
出发准备入口。
局外导航 UI。
保存与读取。
```

推荐节点：

```text
BaseScene
  BaseUIRoot
  WarehousePanel
  ResearchPanel
  CraftingPanel
  LoadoutPanel
  StartRunButton
```

---

## 5.2 RunScene

局内场景负责：

```text
地图。
玩家。
安全屋。
容器刷新。
前哨点。
撤离点。
HUD。
局内时间。
稳定值与视野。
```

推荐节点：

```text
RunScene
  WorldRoot
  TileMapRoot
  PlayerRoot
  ContainerRoot
  OutpostRoot
  ExtractionRoot
  EffectRoot
  CameraRoot
  RunUIRoot
```

---

## 5.3 SettlementScene 或 SettlementPanel

结算负责：

```text
展示带出物。
安全存储入库。
手动选择入库。
确认遗弃未入库物品。
写入仓库。
返回局外基地。
```

V0.1 可做成 Panel，不必独立场景。

---

## 6. 系统模块边界

推荐模块：

```text
RunManager
PlayerController
StabilityManager
VisionController
ContainerManager
OutpostManager
InventoryManager
WarehouseManager
SafeStorageManager
ExtractionManager
SettlementManager
ResearchManager
CraftingManager
EquipmentManager
ConsumableManager
AudioManager
InteractionHighlightService
SaveManager
```

原则：

```text
Manager 处理规则。
Data 保存状态。
Definition 保存静态配置。
View 处理 UI 显示。
Controller 处理输入和角色行为。
Service 处理可复用计算。
```

---

## 6.1 交互描边模块

推荐模块：

```text
InteractionHighlightService
InteractionHighlightView
InteractableTarget
InteractableOutlineShader
InteractableOutlineMaterial
```

职责：

```text
InteractionHighlightService：根据交互对象状态和玩家距离，计算描边状态。
InteractionHighlightView：负责把描边状态写入 Sprite 的 ShaderMaterial 或特殊 Overlay。
InteractableTarget：由容器、前哨站等对象实现，提供 target_id、interactable_type、interaction_state。
InteractableOutlineShader：根据 Sprite alpha 轮廓自动生成外描边。
```

第一版需要支持：

```text
容器描边。
前哨站描边。
进入范围高亮。
读条中脉冲。
修复完成暖光。
倒计时危险闪烁。
```

规则：

```text
交互判定属于功能系统。
描边颜色和资源属于 UI / VFX 系统。
UI 不直接决定对象是否可交互。
默认实现使用 Shader 自动描边，不为每种容器制作固定 PNG 边框。
描边 sheet 只作为流光、扫描线、闪烁和风格参考资源。
```

---

## 7. 数据流规则

## 7.1 局内开始

```text
BaseSaveData
  -> LoadoutData
  -> RunStartRequest
  -> RunState
  -> RunScene
```

进入局内时：

```text
读取出发装备。
生成玩家局内状态。
生成地图与刷新点。
生成容器候选。
初始化稳定值、时间、视野。
```

---

## 7.2 局内结束

```text
RunState
  -> RunResult
  -> SettlementData
  -> WarehouseTransaction
  -> SaveGame
```

规则：

```text
局内结果不要直接写仓库。
先进入结算。
玩家确认入库后再写入仓库。
未入库物品确认遗弃后销毁。
```

---

## 8. Command 规则

所有关键行为建议走 Command：

```text
StartRunCommand
InteractContainerCommand
TakeContainerItemCommand
SubmitOutpostMaterialCommand
StoreToSafeCommand
StartExtractCommand
ConfirmSettlementCommand
EquipItemCommand
UseConsumableCommand
CraftItemCommand
StartResearchCommand
```

好处：

```text
方便调试。
方便日志。
方便未来多人。
方便测试。
```

---

## 9. 信号与事件规则

Godot signal 用于表现层通知。

RunEvent 用于规则层记录。

区别：

```text
signal：按钮刷新、UI 更新、动画播放。
RunEvent：容器打开、物品拿取、前哨提交、撤离成功。
```

不要把 signal 当作唯一事实来源。

---

## 10. 命名规范

文件：

```text
snake_case.gd
player_controller.gd
container_manager.gd
```

类名：

```text
PascalCase
PlayerController
ContainerManager
```

变量：

```text
snake_case
item_id
container_id
durability_current
```

场景：

```text
PascalCase.tscn
RunScene.tscn
WarehousePanel.tscn
```

---

## 11. 存档模块

推荐：

```text
SaveManager
SaveData
RunArchiveData
WarehouseSaveData
ResearchSaveData
SettingsSaveData
```

存档原则：

```text
保存动态状态。
不保存完整静态配置。
通过 item_id 关联 DataRegistry。
保存 SaveDataVersion。
保存 DataVersion。
```

---

## 12. UI 模块

推荐 UI 目录：

```text
scenes/ui/hud/
scenes/ui/inventory/
scenes/ui/warehouse/
scenes/ui/research/
scenes/ui/crafting/
scenes/ui/settlement/
```

UI 原则：

```text
UI 不直接改核心数据。
UI 发送 Command 或调用 Manager 接口。
UI 从状态快照刷新。
UI 关闭时释放输入锁。
```

---

## 13. 调试工具

建议内置 DebugPanel：

```text
重新加载数据表。
生成测试容器。
设置稳定值。
传送到撤离点。
模拟撤离成功。
模拟撤离失败。
给仓库添加物品。
清空仓库。
打印 RunState。
打印 DataRegistry。
```

调试工具必须只在开发模式启用。

---

## 14. 测试建议

优先测试：

```text
背包负重计算。
容器读条中断。
容器倒计时消失。
前哨部分提交。
撤离按住 E 中断和成功。
结算入库与遗弃。
装备耐久扣除。
数据表引用校验。
```

测试方式：

```text
可先做 GDScript 单元测试或调试场景。
不要等所有 UI 完成才测试规则。
```

---

## 15. V0.1 最小工程闭环

最小需要：

```text
BootScene。
BaseScene。
RunScene。
PlayerController。
RunManager。
ContainerManager。
InventoryManager。
ExtractionManager。
SettlementManager。
WarehouseManager。
SaveManager。
```

可以暂缓：

```text
研究所。
制作所。
耳机。
多人。
数据表完整化。
```

---

## 16. 当前设计体检与建议

合理点：

```text
系统边界已经比较清晰。
Command 和 DataRegistry 能支撑后续扩展。
局内和局外分离有利于存档和结算。
```

风险：

```text
如果 Autoload 过多，会变成全局泥潭。
如果 UI 直接修改数据，后续测试和多人都会困难。
如果先做美术表现再做规则，容易返工。
```

建议：

```text
先实现规则闭环，再逐步替换美术。
每个系统先有调试入口。
代码提示词按模块生成，不要一次生成整个工程。
```

---

## 17. 本文档结论

Godot 工程的第一目标不是“看起来完整”，而是“系统边界稳定”。

后续生成代码时，应按以下顺序：

```text
数据结构。
核心 Manager。
Command。
UI View。
调试工具。
表现资源。
```

这样能让每个模块可测试、可替换、可继续扩展。

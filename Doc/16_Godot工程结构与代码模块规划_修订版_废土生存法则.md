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
    currencies.tab
    materials.tab
    equipment.tab
    consumables.tab
    effects.tab
    research.tab
    recipes.tab
    recipes.tab
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
    monsters/
    events/
    extraction/
    research/
    crafting/
    equipment/
    consumables/
    audio/
    save/
    flow/
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

### 3.1 V0.1 启动场景硬规则

V0.1 阶段项目初始场景必须明确设置为：

```text
res://scenes/boot/BootScene.tscn
```

落地操作：

```text
1. 打开 Project Settings。
2. 进入 Application > Run。
3. 将 Main Scene 设置为 res://scenes/boot/BootScene.tscn。
4. 确认 project.godot 中出现：
   [application]
   run/main_scene="res://scenes/boot/BootScene.tscn"
5. 运行项目，确认首先进入 BootScene。
```

V0.1 的 BootScene 可以非常薄，只负责启动分流，不承载业务系统。

初期允许 BootScene 直接跳转：

```text
BootScene
  -> BaseScene
```

当 BaseScene 的出发按钮可用后，进入局内的正式路径为：

```text
BootScene
  -> BaseScene
  -> RunScene
```

DebugCoreLoop 不是项目初始场景，只用于开发验证：

```text
res://scenes/debug/DebugCoreLoop.tscn
```

禁止把 DebugCoreLoop 长期设置为项目 Main Scene。需要调试时，应从编辑器直接运行该场景，或通过开发用 Debug 入口进入。

验收标准：

```text
[ ] project.godot 明确设置 run/main_scene。
[ ] 运行项目不会进入空白场景。
[ ] BootScene 存在并能进入 BaseScene。
[ ] BaseScene 有进入 RunScene 的入口或临时调试按钮。
[ ] DebugCoreLoop 可独立运行，但不是正式启动入口。
```

---

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
  DayPrepPanel
  ShopOpenPanel
  NightPlanPanel
  DepartureLoadoutPanel
  CurrencyBar
  WarehousePanel
  ShelfPanel
  DemandRankPanel
  ResearchPanel
  CraftingPanel
```

白天准备阶段功能入口顺序：

```text
仓库
制造所
研究所
图鉴
```

规则：

```text
DayPrepPanel 只负责白天准备入口协调，不直接改仓库或货币数据。
未开发完成的功能入口置灰并禁止点击。
CurrencyBar 显示玩家持有货币，V0.1 至少显示 mine_coin。
ShelfPanel 通过 ShelfInventoryService 上架、撤下和成交可售物资，不直接修改 WarehouseData.items 或 currencies。
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

### 5.2.1 V0.1 白盒地图节点规则

当前 V0.1 白盒地图使用 `WhiteboxMapRect` 作为地图块编辑节点。该节点应是 `Node2D`，不是 `Area2D`。

```text
StreetWalkable 下的 WhiteboxMapRect 表示可通行街道/广场。
BlockSolid 下的 WhiteboxMapRect 表示默认不可进入街区。
Buildings 下的 WhiteboxMapRect 可用于家、前哨、建筑视觉或后续可进入例外区。
OutpostCandidates 下的点位用于前哨候选位置。
```

碰撞生成规则：

```text
运行时根据 BlockSolid 生成实体碰撞。
家安全区和前哨候选区是可进入例外区。
当例外区压在 BlockSolid 上时，运行时会从街区碰撞中切出对应矩形。
玩家移动白名单同时包含街道、广场、家安全区和前哨候选区。
```

重要约束：

```text
不要给 WhiteboxMapRect 保存 CollisionShape2D 子节点作为白盒地图编辑入口。
地图编辑优先选择 WhiteboxMapRect 父节点，修改 position 与 size_units。
运行时碰撞由 RunScene 根据 WhiteboxMapRect 数据生成，不保存在白盒编辑节点下。
```

### 5.2.2 地图美术分层规则

`RunScene` 中地图相关节点按“规则层”和“表现层”拆分：

```text
WorldRoot
  MapLayout              # 白盒规则层，只保存地图数据、点位和可编辑矩形
    StreetWalkable
    BlockSolid
    Buildings
    Points
  MapVisual              # 地图表现层，只放美术显示，不决定玩法碰撞
    RoadVisual           # 道路 tile、广场地面、斑马线、井盖
      ManualRoadPieces   # 手工拼接道路资源，用于确定正式道路尺寸和资源用法
    BlockVisual          # 街区地块贴图、不可进入大块视觉
    BuildingVisual       # 家、前哨站、楼房主体
    PropVisual           # 路灯、路障、垃圾桶、围栏等摆件
    DecalVisual          # 裂痕、血迹、涂鸦、水渍等地表叠加物
  MapLights              # 地图灯光层
    StreetLights
    BuildingLights
    AmbientLights
```

落地规则：

```text
MapLayout 是权威布局来源。
MapVisual 可以由脚本根据 MapLayout 自动生成，也可以后续放少量手工摆放的装饰节点。
正式美术资源不要反向承担碰撞职责，碰撞仍由 BlockSolid / Buildings / 特殊交互对象生成。
路灯、建筑灯、氛围光放入 MapLights，不混入 RoadVisual 或 BlockVisual。
```

2026-05-07 起，左下角区域先作为正式资源试验区：

```text
道路：使用 res://assets/map/roads/tiles/ 下的道路资源按邻接关系生成。
当前自动生成默认关闭，先允许在 RoadVisual/ManualRoadPieces 下手工拼接参考版。
街区：暂时保持白盒灰块，不生成正式 plot 资源。
白盒灰图仍保留在下层，便于对照尺寸与继续调图。
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
RunLoadingController
SceneRandomEventDirector
MonsterManager
RandomObstacleManager
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
scenes/ui/loading/
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
本日必出怪物。
强制超级时间。
强制超短时间。
强制随机障碍。
显示怪物点位。
显示怪物视野。
显示障碍点位。
验证障碍路径。
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
RunLoadingController。
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
## 2026-05-07 V0.1 道路视觉层落地

`RunScene` 的道路视觉层采用 `WorldRoot/MapVisual/RoadVisual` 统一生成。

当前推荐结构：

```text
WorldRoot
└── MapVisual
    └── RoadVisual
        └── RoadGround_*     # 运行时/编辑器预览生成，不手工维护
```

`RoadVisual` 挂载 `res://scripts/map/road_visual_generator.gd`：

- `enabled = true`
- `visual_mode = "ground_field"`
- `ground_tile_units = Vector2(16, 16)`

该模式使用 `res://assets/map/roads/ground` 下的无缝地面 tile，按 `StreetWalkable` 整块铺满道路底图。它只负责视觉，不改变 `MapLayout`、点位、碰撞和玩家通行规则。

旧的 `cell_tiles` 模式保留为实验用途，但 V0.1 不再默认使用，避免直路/路口资源不足时产生碎裂和错贴。

## 2026-05-07 V0.1 街区块视觉层试替换

街区块的正式美术不直接替换 `MapLayout/BlockSolid` 节点。`BlockSolid` 继续负责：

- 白盒尺寸锚点；
- 编辑器中移动/缩放；
- 街区不可进入碰撞；
- 家/前哨可进入例外区的碰撞开洞依据。

正式街区资源生成到：

```text
WorldRoot
└── MapVisual
    └── BlockVisual
        └── {BlockSolid 节点名}_Art
            ├── SingleFill
```

当前对 `WorldRoot/MapLayout/BlockSolid` 下所有街区块启用，用于验证全图街区主体资源比例。每个街区生成一个 `{BlockSolid 节点名}_Art`，内部暂时只使用单张填充图缩放到对应白盒尺寸。

注意：`block_corner_outer_01.png` 自带大面积内填充，放在当前“只补边框”的结构里会形成过重的方形角块；`block_corner_outer_round_01.png` 与当前直边比例也尚未完全匹配。直边 edge 资源重复摆放后也会干扰街区主体视觉判断。因此 V0.1 试替换阶段暂时关闭 edge、corner、入口缺口和废墟叠加，只保留街区主体填充图。等确认正确的边角/门口专用资源后再恢复。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 16_Godot工程结构与代码模块规划.md
  作为 开发者
  我希望按本文规则完成 16_Godot工程结构与代码模块规划.md
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

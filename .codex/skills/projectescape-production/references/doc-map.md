# Project Escape Document Map

Use this file to choose which project documents must be read before editing docs, code, scenes, or assets.

## Global

- Product direction and total scope: `Doc/01_项目总纲_修订版_废土生存法则.md`
- AI task entry: `Doc/00_AI开工入口.md`
- AI document reading and maintenance rules: `Doc/00_AI文档读取规则.md`
- BDD requirements documentation rules: `Doc/00_BDD需求文档规范.md`
- AI/system routing table: `Doc/系统文档索引表.md`
- Execution writing rules: `Doc/00_落地执行文档总则.md`
- Godot project structure and initial scene: `Doc/16_Godot工程结构与代码模块规划_修订版_废土生存法则.md`
- Data tables and TAB format: `Doc/13_数据配置表与TAB规范_修订版_废土生存法则.md`
- Validation tools and editor plugins: `Doc/18_数据校验工具与编辑器插件规范_修订版_废土生存法则.md`
- Worldbuilding, narrative packaging, and copy voice: `Doc/23_世界观包装_废土生存法则.md`

## Module Routing

| Task Area | Master Document | Operational Folder / Checklist |
| --- | --- | --- |
| Core loop, run state, day flow | `Doc/02_核心循环规则_修订版_废土生存法则.md` | `Doc/02_核心循环规则/` |
| Map, streets, blocks, safe zones, navigation, collision | `Doc/03_地图与安全区规则_修订版_废土生存法则.md` | `Doc/03_地图与安全区规则/` |
| Stability, vision, pressure | `Doc/04_稳定值与视野系统_修订版_废土生存法则.md` | `Doc/04_稳定值与视野系统/` |
| Containers, search, loot refresh | `Doc/05_容器刷新与开箱系统_修订版_废土生存法则.md` | `Doc/05_容器刷新与开箱系统/` |
| Materials, outpost repair | `Doc/06_前哨材料与前哨站修复系统_修订版_废土生存法则.md` | `Doc/06_前哨材料与前哨站修复系统/` |
| Backpack, storage, load | `Doc/07_背包_存储与负重系统_修订版_废土生存法则.md` | `Doc/07_背包_存储与负重系统/` |
| Extraction, settlement | `Doc/08_撤离与结算系统_修订版_废土生存法则.md` | `Doc/08_撤离与结算系统/` |
| Meta warehouse | `Doc/09_局外仓库系统_修订版_废土生存法则.md` | `Doc/09_局外仓库系统/` |
| Research and crafting | `Doc/10_研究所与制作所系统_修订版_废土生存法则.md` | `Doc/10_研究所与制作所系统/` |
| Loadout and pre-run prep | `Doc/11_出发准备与局外装备系统_修订版_废土生存法则.md` | Use master document until split docs exist |
| Consumables and equipment effects | `Doc/12_消耗品与装备效果系统_修订版_废土生存法则.md` | Use master document until split docs exist |
| Audio and earphone module | `Doc/14_耳机模块与音乐系统_修订版_废土生存法则.md` | Use master document until split docs exist |
| Multiplayer reservation | `Doc/15_多人模式预留架构_修订版_废土生存法则.md` | Use master document until split docs exist |
| Art resources and image prompts | `Doc/17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md` | `assets/map/README.md`, documents 20 and 21 for UI |
| Balance and drop weights | `Doc/19_数值平衡表与掉落权重规范_修订版_废土生存法则.md` | Use master document until split docs exist |
| UI visual rules and sheets | `Doc/20_UI视觉规范与界面资源Sheet提示词_修订版_废土生存法则.md` | `Doc/21_UI资源Sheet生成清单与提示词包_废土生存法则.md` |
| Worldbuilding, narrative packaging, in-game copy voice, item and place naming | `Doc/23_世界观包装_废土生存法则.md` | Use master document until split docs exist |
| Main menu, player profile, chapter goals | `Doc/25_主菜单玩家档案与剧情章节目标系统/00_系统总览与落地边界.md` | `Doc/25_主菜单玩家档案与剧情章节目标系统/` |
| Monsters and random scene events | `Doc/26_怪物与场景随机事件系统/00_系统总览与落地边界.md` | `Doc/26_怪物与场景随机事件系统/` |
| Audio resource playback framework | `Doc/27_音频资源与播放框架/00_音频资源路径与播放框架.md` | `Doc/27_音频资源与播放框架/` |

## V0.1 Map Mandatory Reads

For any city map or in-run scene task, read these in order:

1. `Doc/03_地图与安全区规则/00_拆分规范与落地文档写法.md`
2. `Doc/03_地图与安全区规则/11_V0_1地图最小交付清单.md`
3. `Doc/03_地图与安全区规则/13_街道区块基底与区块资源规格.md`
4. `Doc/03_地图与安全区规则/12_模块功能规则细化与AI开工提示词.md` when generating implementation prompts or assigning work to another thread

Key invariant: streets and blocks are designer-editable in Godot. Streets are walkable. Blocks are non-walkable. Buildings are placed on blocks and must not define the main street collision.

## V0.1 System Mandatory Reads

For each listed module, read these files before implementation:

| Module | Required Files |
| --- | --- |
| Stability and vision | `Doc/04_稳定值与视野系统/00_拆分规范与落地文档写法.md`, `Doc/04_稳定值与视野系统/12_V0_1最小交付清单.md`, `Doc/04_稳定值与视野系统/13_模块功能规则细化与AI开工提示词.md` |
| Containers and loot | `Doc/05_容器刷新与开箱系统/00_拆分规范与落地文档写法.md`, `Doc/05_容器刷新与开箱系统/13_V0_1最小交付清单.md`, `Doc/05_容器刷新与开箱系统/14_模块功能规则细化与AI开工提示词.md` |
| Outposts, materials, and repair | `Doc/06_前哨材料与前哨站修复系统/00_拆分规范与落地文档写法.md`, `Doc/06_前哨材料与前哨站修复系统/13_V0_1最小交付清单.md`, `Doc/06_前哨材料与前哨站修复系统/14_模块功能规则细化与AI开工提示词.md` |
| Backpack, storage, and load | `Doc/07_背包_存储与负重系统/00_拆分规范与落地文档写法.md`, `Doc/07_背包_存储与负重系统/15_V0_1最小交付清单.md`, `Doc/07_背包_存储与负重系统/16_模块功能规则细化与AI开工提示词.md` |
| Extraction and settlement | `Doc/08_撤离与结算系统/00_拆分规范与落地文档写法.md`, `Doc/08_撤离与结算系统/14_V0_1最小交付清单.md`, `Doc/08_撤离与结算系统/15_模块功能规则细化与AI开工提示词.md` |
| Meta warehouse, merchant, and currency | `Doc/09_局外仓库系统/00_拆分规范与落地文档写法.md`, `Doc/09_局外仓库系统/14_V0_1最小交付清单.md`, `Doc/09_局外仓库系统/15_模块功能规则细化与AI开工提示词.md`, `Doc/09_局外仓库系统/16_局外商人与货币系统.md` |
| Research and crafting | `Doc/10_研究所与制作所系统/00_AI开工入口.md`, `Doc/10_研究所与制作所系统/00_拆分规范与落地文档写法.md`, `Doc/10_研究所与制作所系统/08_调试工具与验证清单.md`, `Doc/10_研究所与制作所系统/09_V0_2最小交付清单.md`, `Doc/10_研究所与制作所系统/10_模块功能规则细化与AI开工提示词.md` |

Key invariant: these systems are connected. Containers create loot for backpack rules. Backpack and storage feed extraction and settlement. Settlement deposits into the meta warehouse. The merchant sells warehouse items into currency through currency_id. Research and crafting consume and output warehouse item instances through documented interfaces. Outposts can create safe zones and storage. Stability and vision respond to map zones, items, interactions, and outpost safety. Any item action must select a concrete single item instance by list index before transfer, sale, consume, equip, or discard.

## V0.1 Implementation Gate

For requirements documentation tasks, first ensure the relevant behavior is expressed as BDD:

1. At least one `Feature` names the behavior.
2. Each key behavior has a `Scenario`.
3. Scenarios use `Given / When / Then`.
4. Success, failure, and boundary cases are represented or explicitly marked as not yet covered.
5. Each scenario maps to an acceptance, Debug, manual, or text validation path.

Before claiming a task is complete:

1. Point to the exact acceptance checklist used.
2. Confirm the Godot nodes, data files, or asset paths match the docs.
3. Run the relevant validation tool if it exists.
4. If validation does not exist yet, state the manual inspection performed and whether a validation doc needs to be updated.

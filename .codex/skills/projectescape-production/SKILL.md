---
name: projectescape-production
description: Use this skill for any Project Escape / 废土生存法则 documentation maintenance, Godot implementation, data configuration, asset specification, map editing, gameplay system work, validation, or production planning. Before changing code, scenes, data, assets, or docs, read the required project documents and follow the module acceptance checklist.
metadata:
  short-description: Project Escape production rules
---

# Project Escape Production

This skill is the mandatory entry point for Project Escape work. It does not replace `Doc/`; it tells the agent which project documents to read before acting and how to prove the work still follows them.

## Hard Rule

Before editing any file, answer these four questions internally:

1. Which project module is this work touching?
2. Which `Doc/系统文档索引表.md` row and module `00_AI开工入口.md` define the read route?
3. Which checklist, validation document, or acceptance section proves the work is done?
4. If this is requirements documentation, which BDD `Feature` and `Scenario` describe the behavior?
5. Are there newer user instructions in the current thread that override or extend the docs?

If the answer to question 2 or 3 is unknown, inspect `Doc/00_AI开工入口.md`, `Doc/00_AI文档读取规则.md`, `Doc/系统文档索引表.md`, `references/doc-map.md`, and the relevant `Doc/` files before editing.

## Required Start Sequence

For all tasks:

1. Read `Doc/00_AI开工入口.md`.
2. Read `Doc/00_AI文档读取规则.md`.
3. Read `Doc/00_BDD需求文档规范.md` when creating, restructuring, or maintaining requirements docs, acceptance checklists, feature rules, or AI work prompts.
4. Read `Doc/系统文档索引表.md` and the matching module `00_AI开工入口.md`.
5. Read only the master document, split document, checklist, and AI prompt named by that module entry.
6. Read `Doc/00_落地执行文档总则.md` when creating or restructuring execution documents.
7. Read `Doc/01_项目总纲_修订版_废土生存法则.md` when the task affects product direction, core experience, scope, or priority.
8. If implementing in Godot, read `Doc/16_Godot工程结构与代码模块规划_修订版_废土生存法则.md`.
9. If touching assets, prompts, sprite sheets, UI art, or map art resources, read document 17 and, for UI, documents 20 and 21.
10. If touching worldbuilding, narrative packaging, in-game copy voice, item naming, or place naming, read `Doc/23_世界观包装_废土生存法则.md`.

## Execution Discipline

- Use `Doc/00_AI开工入口.md` and `Doc/系统文档索引表.md` to route work before reading long documents.
- For design, rule, requirements, BDD, acceptance, index, AI prompt, or documentation synchronization work, use `projectescape-doc-bdd-sync` when available. Prefer updating existing authoritative docs before creating new docs.
- Future requirements documentation must be organized with BDD. Use `Doc/00_BDD需求文档规范.md`, and express key behavior with `Feature`, `Scenario`, `Given`, `When`, and `Then`.
- Treat split documents under `Doc/02_*` to `Doc/10_*` as the operational source for implementation tasks.
- Treat module `00_AI开工入口.md` files as routing documents only; do not copy full system rules into them.
- Treat revised master documents as the source for intent and cross-module consistency.
- All project text files must be read and written as UTF-8. On Windows, explicitly use UTF-8-aware reads/writes for Chinese docs, GDScript strings, `.tscn`, `.tab`, `.md`, and skill files; never rely on the shell default code page. Before finishing, inspect any touched Chinese text through a UTF-8 read and fix mojibake immediately.
- Do not implement from a framework-only summary when a module AI entry, split landing document, or checklist exists.
- When docs and implementation conflict, prefer the current docs and call out the conflict in the final response.
- When the user changes a rule in the current thread, update the docs first or in the same patch as the implementation.
- When maintaining docs or iterating features, check whether this skill and `references/doc-map.md` also need updates. If project rules, required reads, module routing, acceptance gates, or cross-module invariants change, update both the relevant `Doc/` files and this skill in the same work pass.
- Keep implementation small enough to validate against the relevant checklist.

## Skill And Document Maintenance

This skill is part of the project production source of truth. Keep it synchronized with the docs.

Update this skill when:

- A new module document or split folder is added.
- A V0.1 checklist, acceptance gate, required read order, or implementation workflow changes.
- Requirements documentation format or BDD scenario requirements change.
- A rule becomes cross-module and should constrain future implementation threads.
- A user correction changes how production work should be started, routed, validated, or reported.
- A document is renamed, moved, split, deprecated, or replaced.

For documentation maintenance tasks, inspect both directions:

1. If a `Doc/` change affects future execution, update `SKILL.md` or `references/doc-map.md`.
2. If a skill rule is updated, ensure the corresponding `Doc/` source exists or is updated.
3. In the final response, state whether the skill was checked and whether it needed changes.

## Map And City Rules

For map, safe zone, city block, street, building, navigation, collision, or editor placement work:

1. Read `Doc/03_地图与安全区规则_修订版_废土生存法则.md`.
2. Read `Doc/03_地图与安全区规则/00_拆分规范与落地文档写法.md`.
3. Read `Doc/03_地图与安全区规则/11_V0_1地图最小交付清单.md`.
4. Read `Doc/03_地图与安全区规则/13_街道区块基底与区块资源规格.md`.

Mandatory rule: the city base is built from walkable streets and non-walkable blocks. Buildings sit on blocks as visual subjects or local obstacles; irregular building outlines must not be the main way to carve streets.

## Core V0.1 System Rules

For containers, stability and vision, outposts and repair materials, backpack and storage, extraction and settlement, meta warehouse, research, or crafting work, read the matching module `00_AI开工入口.md` first. Then read the master document, split landing document, checklist, and AI prompt listed there.

### Stability And Vision

Required docs: `Doc/04_稳定值与视野系统_修订版_废土生存法则.md` and `Doc/04_稳定值与视野系统/`.

Mandatory rules:

- Stability is a core runtime value with a single authoritative component; do not scatter stability math across UI, items, map, and interaction code.
- Stability stages, curves, modifiers, and thresholds must be data-driven where the docs require configuration.
- Vision radius is controlled by stability state and related modifiers; UI, darkness mask, audio pressure, and death collapse must reflect the same state.
- Safe zones, outposts, interactions, items, equipment, and area modifiers may affect stability only through documented interfaces.
- Failure/death caused by stability must route into the documented failure and settlement flow.

### Containers And Loot

Required docs: `Doc/05_容器刷新与开箱系统_修订版_废土生存法则.md` and `Doc/05_容器刷新与开箱系统/`.

Mandatory rules:

- Container types, information tiers, loot tables, spawn points, circle weights, and refresh behavior must be data-driven.
- A refresh manager owns refresh rounds and point selection; individual containers should not invent their own global spawning rules.
- Container lifecycle must follow the documented states for unsearched, opening, opened, locked, or reserved behavior. Ordinary containers do not expire or despawn on a countdown.
- Opening uses the documented interaction/read-bar flow and must respect interruption, lock, and multiplayer-reservation boundaries where applicable.
- Loot generation hands items to the backpack/load interface; containers must not bypass inventory rules or silently create persistent meta items.

### Outposts, Materials, And Repair

Required docs: `Doc/06_前哨材料与前哨站修复系统_修订版_废土生存法则.md` and `Doc/06_前哨材料与前哨站修复系统/`.

Mandatory rules:

- Outpost candidate selection, mutual exclusion, material requirements, and material refresh must follow documented configuration and validation rules.
- Outposts use a documented state machine; do not implement repair as a one-off boolean.
- Repair interaction uses the documented hold/read-bar flow and consumes required materials through inventory/storage interfaces.
- Repaired outposts unlock their documented safe-zone, vision, storage, and extraction/settlement links.
- Death, extraction, and settlement must preserve or discard outpost progress according to the module docs.

### Backpack, Storage, And Load

Required docs: `Doc/07_背包_存储与负重系统_修订版_废土生存法则.md` and `Doc/07_背包_存储与负重系统/`.

Mandatory rules:

- Item definition, size, quality, stackability, tags, and value must come from item data, not hardcoded scene logic.
- Backpack placement follows grid occupancy and stacking rules; ordinary resources can stack according to item data, and pickup, transfer, split, merge, discard, and sort must use shared inventory interfaces.
- Load is calculated from carried items and equipment, then mapped to documented load stages, speed multipliers, and penalties. Load does not block ordinary resource pickup by itself.
- Home storage, outpost storage, container leftovers, carried backpack, and meta warehouse are separate scopes with documented transfer boundaries.
- Death, extraction, and settlement must call the documented inventory/warehouse interfaces rather than directly moving arbitrary item nodes.
- Item selection and transfer must operate on a single item instance by list index; new UI surfaces must not merge, sell, consume, or transfer by `item_id` unless the user explicitly chooses a batch action that internally iterates single-item transfers.

### Extraction And Settlement

Required docs: `Doc/08_撤离与结算系统_修订版_废土生存法则.md` and `Doc/08_撤离与结算系统/`.

Mandatory rules:

- End-of-run result types must be explicit: successful extraction, death/failure, cancellation, or other documented endings.
- Extraction availability, activation display, hold progress, interruption, and success flow must follow the module docs.
- Settlement item rows must preserve documented source fields and item state; do not collapse all rewards into anonymous totals.
- One-click deposit, manual deposit, overflow, discard, and confirmation must route through inventory and warehouse rules.
- Run reset must clear temporary run state while preserving documented persistent state.

### Meta Warehouse

Required docs: `Doc/09_局外仓库系统_修订版_废土生存法则.md` and `Doc/09_局外仓库系统/`.

Mandatory rules:

- The meta warehouse is persistent outside-run storage; it is not the same scope as backpack, home storage, outpost storage, or container contents.
- Warehouse capacity, grid occupancy, stack merging, sorting, discard confirmation, and overflow handling must follow documented rules.
- Settlement deposit is the main entry path from a run into the warehouse and must respect one-click/manual priority and full-warehouse behavior.
- Out-of-run merchant selling must use documented warehouse and currency interfaces: selectable item, selectable count, atomic item removal plus currency gain.
- Currency must be stored by currency_id. V0.1 only has `mine_coin`, but data and save structure must allow future currencies.
- BaseScene top tabs must follow the documented order: warehouse, merchant, research, crafting. Unfinished tabs are disabled and greyed out.
- Research, crafting, and departure preparation may read/write warehouse items only through documented interfaces.
- Warehouse, merchant, research, crafting, and departure preparation item actions must select a concrete warehouse item instance before selling, consuming, equipping, or moving it.
- Save data fields must be stable and compatible with the data configuration rules.

### Research And Crafting

Required docs: `Doc/10_研究所与制作所系统_修订版_废土生存法则.md` and `Doc/10_研究所与制作所系统/00_AI开工入口.md`.

Mandatory rules:

- Research and crafting must be data-driven through documented TAB fields where the docs require table configuration.
- Research consumes `mine_coin` and documented `required_conditions` only; it must not consume meta warehouse materials.
- Crafting costs may consume items from the meta warehouse through documented warehouse interfaces.
- Warehouse capacity research currently uses the 80 -> 120 capacity line: unresearched 80, then 80 / 90 / 100 / 110 / 120.
- There is no blueprint system, blueprint item, or blueprint unlock path in this round; recipe availability must come from documented data/configuration and required conditions.
- Crafting outputs must enter the meta warehouse through the same capacity, stack, overflow, and item-instance rules used by warehouse and settlement systems.
- Manufacturing/crafting unlocks tied to chapter progress must remain synchronized with the player profile and chapter goal documents.

## Art And Asset Rules

For image generation prompts, sprite sheets, tiles, UI icons, scene props, or asset slicing:

1. Read `Doc/17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md`.
2. Read `assets/map/README.md` when touching map assets.
3. Read documents 20 and 21 when touching UI assets.

Map block resources must support editor placement. Prefer TileMap / TileSet terrain or repeatable fill textures plus edge and corner tiles over stretching a single painted image.

## Validation

Every final response must include:

- The documents consulted or updated.
- The files changed.
- The validation performed, or the reason validation was not run.
- Any remaining mismatch between docs, implementation, and user intent.

For Godot work, use `projectescape-godot-validation` when available to discover and run the narrowest relevant check from repository evidence. If no automated check exists, perform a scene/file inspection and say so.

For TAB, TSV, JSON, manifest, or other data configuration work, use `projectescape-tab-data-guardian` when available to discover current data conventions, protect references and UTF-8 text, and select relevant data validation evidence.

For documentation-only or design-rule work, use `projectescape-doc-bdd-sync` when available to verify existing-doc-first maintenance, BDD or acceptance coverage, routing/index synchronization, and stale wording searches.

## Reference

Use `references/doc-map.md` as the routing table from task type to required documents.

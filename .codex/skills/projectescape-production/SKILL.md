---
name: projectescape-production
description: Use this skill for any Project Escape / 废土生存法则 documentation maintenance, Godot implementation, asset specification, map editing, gameplay system work, validation, or production planning. Before changing code, scenes, assets, or docs, read the required project documents and follow the module acceptance checklist.
metadata:
  short-description: Project Escape production rules
---

# Project Escape Production

This skill is the mandatory entry point for Project Escape work. It does not replace `Doc/`; it tells the agent which project documents to read before acting and how to prove the work still follows them.

## Hard Rule

Before editing any file, answer these four questions internally:

1. Which project module is this work touching?
2. Which master document and split landing document define that module?
3. Which V0.1 checklist or acceptance section proves the work is done?
4. Are there newer user instructions in the current thread that override or extend the docs?

If the answer to question 2 or 3 is unknown, inspect `references/doc-map.md` and the relevant `Doc/` files before editing.

## Required Start Sequence

For all tasks:

1. Read `Doc/00_落地执行文档总则.md`.
2. Read `Doc/01_项目总纲_修订版_废土生存法则.md` when the task affects product direction, core experience, scope, or priority.
3. Read `references/doc-map.md` and then the matching module docs.
4. If implementing in Godot, read `Doc/16_Godot工程结构与代码模块规划_修订版_废土生存法则.md`.
5. If touching assets, prompts, sprite sheets, UI art, or map art resources, read document 17 and, for UI, documents 20 and 21.

## Execution Discipline

- Treat split documents under `Doc/02_*` to `Doc/09_*` as the operational source for implementation tasks.
- Treat revised master documents as the source for intent and cross-module consistency.
- Do not implement from a framework-only summary when a split landing document or V0.1 checklist exists.
- When docs and implementation conflict, prefer the current docs and call out the conflict in the final response.
- When the user changes a rule in the current thread, update the docs first or in the same patch as the implementation.
- When maintaining docs or iterating features, check whether this skill and `references/doc-map.md` also need updates. If project rules, required reads, module routing, acceptance gates, or cross-module invariants change, update both the relevant `Doc/` files and this skill in the same work pass.
- Keep implementation small enough to validate against the relevant checklist.

## Skill And Document Maintenance

This skill is part of the project production source of truth. Keep it synchronized with the docs.

Update this skill when:

- A new module document or split folder is added.
- A V0.1 checklist, acceptance gate, required read order, or implementation workflow changes.
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

For containers, stability and vision, outposts and repair materials, backpack and storage, extraction and settlement, or meta warehouse work, read the matching master document plus the module split folder listed in `references/doc-map.md`. Always read that module's `00_拆分规范与落地文档写法.md`, `V0_1最小交付清单.md`, and `模块功能规则细化与AI开工提示词.md` before implementation.

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
- Container lifecycle must follow the documented states for unsearched, opening, opened, locked, expired, or reserved behavior.
- Opening uses the documented interaction/read-bar flow and must respect interruption, lock, multiplayer-reservation boundaries, and expiry rules where applicable.
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
- Backpack placement follows grid occupancy and stacking rules; pickup, transfer, split, merge, discard, and sort must use shared inventory interfaces.
- Load is calculated from carried items and equipment, then mapped to documented load stages and penalties.
- Home storage, outpost storage, container leftovers, carried backpack, and meta warehouse are separate scopes with documented transfer boundaries.
- Death, extraction, and settlement must call the documented inventory/warehouse interfaces rather than directly moving arbitrary item nodes.

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
- Research, crafting, and departure preparation may read/write warehouse items only through documented interfaces.
- Save data fields must be stable and compatible with the data configuration rules.

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

For Godot work, run the narrowest relevant check available. If no automated check exists, perform a scene/file inspection and say so.

## Reference

Use `references/doc-map.md` as the routing table from task type to required documents.

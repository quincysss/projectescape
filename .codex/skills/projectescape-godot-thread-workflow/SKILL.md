---
name: projectescape-godot-thread-workflow
description: Use this skill for ProjectEscape multi-thread Godot feature delivery. It guides new implementation threads to declare agent identity, responsibility and write boundaries, Godot MCP discovery and connection, dynamic 9081-9099 port selection, current resource-loop design red lines, validation discipline, integration-risk reporting, and final acceptance reports. Trigger when Codex is asked to start or coordinate a ProjectEscape Godot MCP landing thread, parallel implementation lane, module delivery thread, or multi-thread integration workflow.
---

# ProjectEscape Godot Thread Workflow

Guide ProjectEscape Godot implementation threads so each thread has a clear identity, bounded write scope, Godot MCP validation path, port record, and integration report.

## Operating Boundary

This skill is for multi-thread Godot delivery workflow. It does not implement game features by itself.

Use it when starting or reviewing a ProjectEscape landing thread such as:
- technical producer or lead integration owner;
- senior game balance or configuration engineer;
- senior Godot gameplay systems engineer;
- senior Godot item, inventory, or save engineer;
- senior game economy or Godot gameplay engineer;
- senior progression or Godot gameplay engineer;
- senior Godot UI or UX engineer.

Pair this skill with:
- `projectescape-production` for project document routing and module rules;
- `projectescape-doc-bdd-sync` when design docs, BDD, acceptance, or old wording must be maintained;
- `projectescape-tab-data-guardian` when data tables, JSON, manifests, IDs, or references change;
- `projectescape-godot-validation` when selecting and running automated checks.

## Start Contract

At thread start, state:
- Agent identity;
- responsible module or workflow;
- deliverable closure;
- allowed write scope;
- explicit out-of-scope systems;
- expected validation path;
- expected Godot MCP strategy.

Identity is not decoration. It binds responsibility, write boundaries, and acceptance method. The first responsibility of each thread is not to write more code; it is to make its assigned loop runnable, verifiable, and minimally disruptive to other threads.

Example start line:

```text
Agent identity: Senior Godot UI/UX Engineer.
Thread responsibility: BaseScene warehouse/merchant tab interaction closure.
Write boundary: UI controllers, related scenes, narrow tests, and required data references only.
Acceptance: Godot MCP interaction check plus discovered headless checks; report port, steps, result, and integration risks.
```

## Write Boundary Rules

Each thread must declare:
- what it owns;
- what it does not own;
- directories and file types it may modify;
- systems it should not touch;
- expected interface needs from other threads.

Rules:
- Do not roll back user or other-thread changes.
- Do not perform broad refactors outside the assigned module.
- Do not rewrite shared managers, autoloads, scenes, or data contracts unless the thread explicitly owns that boundary.
- Do not modify `.godot/`, import cache, build output, temporary files, or binary resources unless the task explicitly requires it and the report explains why.
- When another thread's area has a problem, record the interface need or integration risk instead of silently rewriting that area.
- If a required cross-boundary edit is unavoidable, make it small, explain the reason, and include it in integration risks.

Prefer maintaining existing authoritative code, scenes, and data over creating parallel systems.

## Godot MCP First

Every functional landing thread should first attempt Godot MCP validation.

Rules:
- If Godot MCP tools are not directly exposed, search available tools for `godot`, `godot_mcp`, or `godot_mcp_pro` capability before falling back.
- Do not fake MCP validation. If MCP was not connected or not used, say so.
- If MCP validation fails, report the failure reason, relevant logs or errors, port, startup command, and reproduction steps.
- Data configuration threads may first use data loading or validation tests instead of MCP. If no MCP validation is performed, state why.
- Map containers, backpack/warehouse, crafting/shop, research, UI, and lead integration threads should prioritize Godot MCP validation.

Use MCP to prove real editor/runtime behavior where practical: scene loads, node presence, signal wiring, UI state, interaction flow, and visible runtime state.

## MCP Port Protocol

Do not default to a fixed port.

Port selection:
1. Search for a free port in `9081-9099`.
2. If a port is occupied, identify the occupying process before acting.
3. Only close a process when it is clearly this thread's old process or a confirmed zombie Godot MCP process for the current `ProjectEscape/project-escape` workspace.
4. If ownership is uncertain, do not kill the process. Try the next port.
5. Record the actual port, startup command, MCP connection status, and validation result.

Never terminate an unknown process merely to obtain a preferred port.

## Current Resource-Loop Red Lines

Before implementing resource-loop work, enforce these current ProjectEscape red lines unless the user explicitly changes scope:

- No blueprints, blueprint items, or recipe-unlock items.
- Research consumes only `mine_coin`; it does not consume in-run materials.
- Normal containers do not disappear by countdown.
- On map entry, generate the container list for the current map instance.
- After leaving the map, clean up residual state for that map instance.
- A single extracted in-run item must directly become a sellable good or have a clearly documented purpose.
- Item quality is only `C`, `B`, `A`, or `S`; there is no `SS` quality.
- Shop decoration, electricity, furniture, and appliances are outside the first resource-loop landing batch unless the user explicitly switches scope.

If implementation or data conflicts with these red lines, stop widening the feature and report the mismatch or route it to the responsible doc/data thread.

## Thread Role Patterns

Use role patterns to constrain behavior:

- Technical producer / lead integration owner: owns integration order, interface risks, final smoke path, and cross-thread conflict report; avoid rewriting specialist modules.
- Senior balance / configuration engineer: owns tables, IDs, references, values, and data checks; avoid scene or UI rewrites unless needed for validation.
- Senior Godot gameplay systems engineer: owns runtime rules and managers in assigned module; avoid data schema or UI expansion outside the contract.
- Senior Godot item / save engineer: owns item instance identity, storage, persistence, settlement transfer, and save boundaries; avoid economic tuning unless assigned.
- Senior economy / gameplay engineer: owns sale value, currency flow, merchant/shop transaction rules, and economic validation; avoid inventory storage rewrites unless contractually required.
- Senior progression / gameplay engineer: owns research/progression unlock state and applied effects; avoid adding blueprint or material-cost mechanics unless explicitly requested.
- Senior Godot UI / UX engineer: owns UI flow, state display, input locking, scene/node interaction, and usability validation; avoid core data mutation outside existing interfaces.

When a role discovers a cross-role defect, record an interface requirement, blocking dependency, or integration risk.

## Validation Workflow

Use a layered validation path:

1. Read project routing and module documents through `projectescape-production`.
2. Connect or attempt Godot MCP according to this skill.
3. Use `projectescape-godot-validation` to discover relevant automated checks.
4. Use `projectescape-tab-data-guardian` for data integrity when data changed.
5. Use `projectescape-doc-bdd-sync` when implementation reveals doc drift.
6. Rerun failed checks after fixes.
7. If MCP or tests cannot run, report the exact blocker and perform manual inspection only as a fallback.

Do not claim completion when the assigned loop is not runnable or when validation was skipped without a reason.

## Completion Report

Every thread must finish with this report shape:

```text
Agent identity:
Thread responsibility:
Write boundary:
Modified files:
Godot MCP port:
Godot MCP connection status:
Godot MCP startup command:
Validation steps:
Validation result:
Unfinished items:
Integration risks:
Needs lead integration owner intervention: yes/no
```

Include data checks, headless checks, manual inspections, and failed-then-fixed reruns when applicable.

If no files changed, say so. If no MCP port was used, write `not used` and explain why.

## Usage

Future threads can invoke this skill with:

```text
请使用 ProjectEscape 多线程 Godot 落地协作 skill，作为[某某线程]开工。
```

The thread should then produce the start contract before editing and the completion report before handing off.

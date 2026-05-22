---
name: projectescape-godot-validation
description: Use this skill for Project Escape Godot validation. It discovers the project root, guidance files, validation commands, tests, changed surfaces, and relevant regression checks from the repository itself instead of relying on hardcoded path maps. Trigger when Codex needs to validate Godot, GDScript, scenes, data, assets, docs, or project configuration changes; choose checks; run headless tests; diagnose failures; rerun verification; or report completion evidence.
---

# Project Escape Godot Validation

Validate Project Escape changes by discovering the current repository's own validation surfaces and proving the result with executed checks or explicit manual evidence.

## Operating Boundary

This skill is a validation orchestrator.

Use it to:
- discover how this repo currently runs Godot checks;
- choose relevant automated checks from local evidence;
- run checks and read outputs;
- diagnose failures;
- rerun after fixes;
- report verification evidence.

Do not use this skill as a replacement for implementation, design routing, or gameplay rules. When project documents define behavior, use the production/document skill first, then use this skill to prove the result.

## Maintenance Rule

Do not add file-to-test routing tables to this skill.

Update this skill only when the validation strategy changes, such as:
- the repo stops using Godot headless script checks;
- the repo adopts a test runner or CI wrapper;
- the repo guidance format changes;
- validation evidence requirements change.

Do not update this skill merely because new scripts, scenes, systems, data tables, docs, or tests were added.

## Discovery Sequence

Before selecting checks, discover the current project facts:

1. Find the Godot project root by locating `project.godot`, starting from the current workspace.
2. Read applicable guidance files such as `AGENTS.md`, `.codexignore`, `.rgignore`, and project-local skill guidance when present.
3. Discover validation commands from existing docs, scripts, tests, and prior project conventions.
4. Discover test or check files from repository text, not from a hardcoded list.
5. Discover the changed or requested surface from:
   - user request;
   - `git status` and `git diff --name-only` when available;
   - files edited in the current turn;
   - referenced docs, scenes, data tables, scripts, classes, node names, IDs, and behavior keywords.

Respect project guidance about avoiding binary, generated, build, editor-cache, or ignored folders.

## Candidate Check Discovery

Build candidate checks by searching local text for evidence.

Useful signals include:
- direct references to changed file paths;
- `load`, `preload`, `extends`, `class_name`, scene paths, resource paths;
- changed class names, function names, signal names, node names, IDs, table names, and JSON keys;
- assertion text or error messages matching the requested behavior;
- documentation acceptance items naming a validation command or expected behavior;
- check filenames semantically related to the task.

Rank candidates by evidence strength:

1. Directly loads or references the changed artifact.
2. Asserts the changed behavior or affected invariant.
3. Exercises the affected scene, manager, service, data registry, or UI flow.
4. Covers a broader smoke path that would catch integration breakage.
5. Manual inspection only when no relevant automated check is discoverable or runnable.

When confidence is low, run the narrowest direct candidate plus the smallest broader flow check discovered from evidence.

## Running Checks

Prefer the repository's discovered validation command.

If no wrapper command exists, use the Godot headless script pattern discovered or implied by existing checks:

```powershell
Godot --headless --path . --script res://path/to/check.gd
```

If `Godot` is unavailable:

1. Search for the executable convention in project docs or scripts.
2. Try only locally reasonable executable names or configured paths.
3. If still unavailable, report validation as blocked and perform manual validation where meaningful.

Never claim a check passed until the command output has been read.

## Failure Loop

When validation fails:

1. Read the first actionable assertion, error, and stack trace.
2. Classify the cause:
   - implementation defect;
   - scene or node wiring defect;
   - data or config defect;
   - missing asset or import issue;
   - stale test;
   - doc or behavior mismatch;
   - environment or tooling blocker.
3. Fix the narrow cause when it is within the current task.
4. Rerun the failed check.
5. Rerun adjacent discovered checks when the fix touches shared state, shared data, scene flow, or common services.

Update tests only when current docs or user instructions changed the expected behavior.

## Missing Coverage

If no suitable automated check exists, do not silently pass.

Report:
- what behavior changed;
- what automated checks were searched for;
- why none applied;
- what manual validation was performed;
- what test should be added if the risk justifies it.

For non-trivial behavior changes, prefer adding or updating a focused check before claiming completion.

## Manual Validation

Manual validation is acceptable only when:
- no automated check exists;
- the task is documentation-only or structural;
- Godot CLI is unavailable;
- visual or asset validation requires inspection beyond headless checks.

Manual validation must name:
- files inspected;
- rule, doc, or invariant used;
- exact condition verified;
- reason automated validation was not run or was insufficient.

## Completion Evidence

Final validation evidence must include:
- project root used;
- how checks were discovered;
- checks run and pass/fail results;
- failed-then-fixed checks, if any;
- manual validation, if used;
- remaining risk or blocked validation.

If validation is blocked, state the blocker plainly and do not describe the work as fully verified.

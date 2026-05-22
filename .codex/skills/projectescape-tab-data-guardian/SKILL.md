---
name: projectescape-tab-data-guardian
description: Use this skill for Project Escape data table and structured data work. It validates and edits TAB, TSV, JSON, manifest, and configuration data by discovering current table conventions, loaders, registry code, docs, tests, and cross-reference rules from the repository itself instead of relying on hardcoded table maps. Trigger when Codex needs to modify, add, audit, repair, or validate Project Escape data files, item definitions, drop tables, shop stock, research or crafting config, dialogue/audio/chapter JSON, manifests, IDs, references, UTF-8 text, or data-driven gameplay configuration.
---

# Project Escape TAB Data Guardian

Maintain Project Escape data files by discovering the repository's current data conventions, preserving UTF-8 text, validating references, and proving changes with automated or explicit manual evidence.

## Operating Boundary

This skill is a data integrity orchestrator.

Use it to:
- discover current data file formats and conventions;
- edit TAB, TSV, JSON, manifests, and configuration data safely;
- preserve IDs, references, columns, ordering, comments, and UTF-8 text;
- discover loader, registry, and validation behavior from code;
- run or recommend relevant data validation checks;
- report data integrity evidence.

Do not use this skill as a replacement for gameplay design rules. When data semantics are defined by project documents, use the production/document skill first, then use this skill to apply and validate the data change.

## Maintenance Rule

Do not add fixed table schemas, table lists, or field maps to this skill.

Update this skill only when the data maintenance strategy changes, such as:
- the project stops using TAB, TSV, or JSON configuration;
- data files move to a different source-of-truth system;
- validation moves to a dedicated runner or external tool;
- evidence requirements change;
- encoding or formatting conventions change.

Do not update this skill merely because new tables, fields, IDs, systems, data folders, manifests, or validation tests were added.

## Discovery Sequence

Before editing or validating data, discover the current project facts:

1. Find the Godot project root by locating `project.godot`.
2. Read applicable guidance files such as `AGENTS.md`, `.codexignore`, `.rgignore`, project-local skills, and data-related docs when present.
3. Discover data conventions from nearby README files, data docs, loaders, registries, validators, tests, and existing files with the same extension.
4. Discover affected data surfaces from:
   - user request;
   - `git status` and `git diff --name-only` when available;
   - files edited in the current turn;
   - referenced IDs, item names, table names, JSON keys, manifests, docs, scripts, scenes, and tests.
5. Discover validation commands or checks from repository text rather than from a hardcoded list.

Respect project guidance about avoiding binary, generated, build, editor-cache, and ignored folders.

## Format Handling

Before editing a data file, infer its format from the current file and loader code.

For TAB or TSV-like files:
- preserve tab separators;
- preserve header names unless the task explicitly changes schema;
- preserve comments and blank-line conventions;
- keep row IDs stable unless renaming is explicitly required;
- avoid converting tabs to spaces;
- avoid spreadsheet-style quoting unless existing files use it;
- preserve UTF-8 exactly.

For JSON-like files:
- preserve existing indentation and key ordering style where practical;
- avoid adding unrelated keys;
- preserve UTF-8 strings;
- validate syntax after editing.

For manifest-like files:
- discover whether paths, IDs, dimensions, generated flags, hashes, or asset metadata are authoritative;
- do not invent asset references without verifying the target file or documented placeholder rule.

## Data Integrity Discovery

Build an integrity checklist from repository evidence.

Useful signals include:
- loader code parsing headers, separators, list fields, key/value fields, booleans, numbers, or paths;
- registry code requiring IDs, item types, currencies, recipes, dialogue IDs, audio IDs, or asset paths;
- tests asserting data invariants;
- docs describing validation rules;
- existing rows showing accepted values and naming patterns;
- scene or script references to data IDs;
- comments inside data files.

Check likely invariants:
- required columns or keys exist;
- IDs are unique in the relevant scope;
- ID style matches current project convention;
- referenced IDs exist in their source table or manifest;
- paths exist or are allowed to be blank by current rules;
- numeric values parse and stay within documented or existing ranges;
- booleans and enums match current conventions;
- list and key/value fields use the existing separator style;
- generated/source data boundaries are respected.

Do not hardcode the invariant source. Cite the doc, loader, test, or neighboring rows that established the rule.

## Editing Discipline

When changing data:

1. Make the smallest data change that satisfies the request.
2. Preserve existing row order unless the file has a discovered ordering convention.
3. Add new rows near related rows when no explicit sort order exists.
4. Keep semantic fields synchronized across related files only when repository evidence shows they are linked.
5. Avoid broad cleanup, reformatting, or normalization unless explicitly requested.
6. For Chinese text, read and write as UTF-8 and inspect touched text before completion.
7. If docs and current data conflict, prefer current user instruction or current authoritative docs, then report the conflict.

When adding new IDs, choose names that match neighboring IDs and project naming conventions.

## Validation Selection

Prefer automated validation discovered from the repository.

Discover candidate checks by searching local text for:
- changed data filename;
- changed ID;
- changed column or JSON key;
- loader or registry class names;
- assertion text related to the changed invariant;
- docs naming validation commands;
- tests that load the changed file or registry.

Rank candidates by evidence strength:

1. Directly loads or references the changed data file.
2. Asserts the changed ID, field, or invariant.
3. Exercises the loader, registry, or manager that consumes the data.
4. Covers a broader gameplay or UI flow that consumes the data.
5. Manual validation only when no relevant automated check is discoverable or runnable.

When Godot checks are needed, use `projectescape-godot-validation` to discover and run them.

## Failure Loop

When validation fails:

1. Read the first actionable parser error, assertion, stack trace, or missing-reference report.
2. Classify the cause:
   - syntax or separator defect;
   - missing required field;
   - duplicate or invalid ID;
   - broken cross-reference;
   - invalid path or missing asset;
   - value type or range defect;
   - stale test;
   - doc or data mismatch;
   - environment or tooling blocker.
3. Fix the narrow cause when it is within the current task.
4. Rerun the failed check.
5. Rerun adjacent discovered checks when the fix touches shared data, loaders, registries, or common gameplay systems.

Update tests only when current docs or user instructions changed the expected data behavior.

## Missing Coverage

If no suitable automated check exists, do not silently pass.

Report:
- which data files changed;
- what invariants were searched for;
- what automated checks were searched for;
- why none applied;
- what manual validation was performed;
- what focused validation should be added if risk justifies it.

For non-trivial data changes, prefer adding or updating a focused check before claiming completion.

## Manual Validation

Manual validation is acceptable only when:
- no automated data check exists;
- the task is data-only and low risk;
- Godot CLI or the discovered validator is unavailable;
- validation requires visual or asset inspection beyond text checks.

Manual validation must name:
- files inspected;
- docs, loaders, tests, or neighboring rows used as evidence;
- exact invariants verified;
- reason automated validation was not run or was insufficient.

## Completion Evidence

Final data evidence must include:
- project root used;
- data conventions discovered;
- files changed;
- IDs, rows, columns, or keys changed;
- automated checks run and pass/fail results;
- manual validation, if used;
- failed-then-fixed checks, if any;
- remaining risk or blocked validation.

If validation is blocked, state the blocker plainly and do not describe the data change as fully verified.

---
name: projectescape-doc-bdd-sync
description: Use this skill for Project Escape documentation, requirements, BDD, acceptance checklist, AI entry, index, and production-rule synchronization. It discovers current document routing, module entries, BDD scenarios, acceptance gates, references, and stale wording from the repository itself instead of relying on hardcoded document maps. Trigger when Codex needs to create, edit, reorganize, audit, or validate Project Escape docs, requirements, module rules, checklists, AI prompts, document indexes, doc-map references, or behavior changes that must stay synchronized with implementation and validation.
---

# Project Escape Doc BDD Sync

Maintain Project Escape documentation by discovering the current document routing system, updating existing authoritative docs first, preserving BDD and acceptance links, and proving that changed rules stay synchronized across docs, skills, and implementation references.

## Operating Boundary

This skill is a documentation synchronization orchestrator.

Use it to:
- discover the current documentation routing system;
- maintain existing authoritative documents before creating new ones;
- update requirements, BDD scenarios, acceptance checklists, module entries, indexes, and AI prompts consistently;
- find old wording or stale rules after a design change;
- check whether project-local skills or doc maps need synchronization;
- report documentation evidence and remaining conflicts.

Do not use this skill as a replacement for gameplay design judgment. When the user changes behavior, capture the user instruction as the newest authority, then synchronize the relevant docs and validation chain.

## Maintenance Rule

Do not add fixed document routing tables to this skill.

Update this skill only when the documentation maintenance strategy changes, such as:
- the project stops using BDD-style requirements;
- module entry or index conventions change;
- acceptance evidence format changes;
- production skill or doc-map synchronization rules change;
- document encoding or naming conventions change.

Do not update this skill merely because new modules, docs, checklists, prompts, indexes, BDD scenarios, or acceptance sections were added.

## Existing-Doc-First Rule

When the user changes design, rules, acceptance, terminology, or module behavior, default to maintaining existing authoritative documents.

Do not create a new document until these checks are complete:

1. Discover the existing module, feature, or system docs through:
   - current document indexes and entry files;
   - filename and module keyword search;
   - BDD feature names;
   - acceptance checklist references;
   - implementation, data, scene, or test references;
   - old terminology and new terminology searches.
2. Identify the current authoritative surfaces:
   - master design doc;
   - split operational doc;
   - module entry doc;
   - acceptance or minimum-delivery checklist;
   - AI prompt or implementation guidance;
   - project-local skill or doc-map only when future agent routing changes.
3. Patch the existing documents that own the changed rule.
4. Search for stale old wording after the patch.
5. Create a new document only when:
   - no existing authoritative document owns the topic;
   - the user explicitly asks for a new document;
   - the change is a genuinely new system or module;
   - current project guidance requires a new split doc;
   - the existing document is intentionally deprecated and a replacement path is documented.

If creating a new document, update the routing surface that makes it discoverable: index, entry doc, parent README or landing doc, checklist links, and any project-local skill or doc-map affected by future agent routing.

## Discovery Sequence

Before editing or validating docs, discover the current project facts:

1. Find the project root by locating `project.godot` or the project-local `AGENTS.md`.
2. Read applicable guidance files such as `AGENTS.md`, `.codexignore`, `.rgignore`, project-local skills, and top-level document entry files when present.
3. Discover document routing from current entry docs, indexes, module `00_*` entry files, references, and existing cross-links.
4. Discover affected documentation surfaces from:
   - user request;
   - changed files;
   - `git status` and `git diff --name-only` when available;
   - behavior keywords;
   - module names;
   - linked implementation files;
   - acceptance or checklist references.
5. Discover validation expectations from the docs themselves, not from a hardcoded checklist.

Respect project guidance about avoiding generated, binary, build, editor-cache, ignored, or unrelated folders.

## Authority Order

When sources disagree, resolve in this order:

1. Newest explicit user instruction in the current thread.
2. Current authoritative module docs and acceptance checklists.
3. Current implementation facts that are stable and verified.
4. Older master docs, summaries, or stale references.
5. Inferred intent from neighboring docs.

When conflict remains, do not silently merge. Record the mismatch and either fix all affected surfaces or report the unresolved decision.

## BDD Handling

When creating or changing requirements, discover the current BDD convention from existing docs and project guidance.

Check that behavior changes have:
- a `Feature` naming the behavior or module;
- one or more `Scenario` entries for key flows;
- `Given`, `When`, and `Then` statements;
- success cases;
- failure or boundary cases, or an explicit gap note;
- a path to automated, manual, text, scene, data, or Godot validation.

Do not force BDD into purely navigational notes, generated indexes, or operational metadata unless current project guidance requires it.

## Synchronization Discovery

After a doc rule changes, search for surfaces that may need synchronization.

Useful signals include:
- same feature or module name;
- same rule phrase;
- same ID, item, system, UI label, scene path, data table, or script class;
- old terminology from the replaced rule;
- references to the changed doc filename;
- checklist items that mention the changed behavior;
- AI prompt files that tell future agents how to implement the behavior;
- project-local skills and doc maps that route future work.

Check likely surfaces:
- module entry docs;
- master docs;
- split operational docs;
- acceptance or minimum-delivery checklists;
- AI prompt docs;
- system index docs;
- project-local skill files;
- doc-map references;
- implementation comments, tests, or data files when the doc change implies behavior.

Do not hardcode these surfaces. Discover them from current links, filenames, search results, and project guidance.

## Stale Wording Search

When replacing or clarifying a rule:

1. Extract old terms, new terms, behavior keywords, IDs, and file references.
2. Search source-text areas for old wording.
3. Classify matches:
   - must update;
   - historical or contextual mention;
   - unrelated false positive;
   - generated or ignored content.
4. Update only the matches that affect current guidance, implementation, or validation.
5. Report unresolved stale wording if any remains intentionally.

For Chinese docs, read and write as UTF-8 and inspect touched text before completion.

## Editing Discipline

When changing docs:

1. Prefer updating existing authoritative docs over creating new docs.
2. Treat new docs as an exception that requires evidence.
3. Make the smallest consistent change to the owning document.
4. Preserve existing heading style, numbering style, terminology style, and BDD style.
5. Keep master intent, split operational rules, checklists, and AI prompts aligned.
6. Update indexes or entry docs only when routing actually changes.
7. Update project-local skills only when future agent behavior changes.
8. If implementation and docs diverge, either update implementation in the same task when requested or clearly report the mismatch.

Prefer adding precise acceptance text over broad explanatory prose.

## Validation Selection

Prefer evidence discovered from the repository.

Discover candidate validation by searching local text for:
- changed doc filename;
- changed rule phrase;
- related BDD feature or scenario;
- linked script, scene, data file, or test;
- acceptance checklist naming validation;
- old wording that should no longer appear.

Rank validation by evidence strength:

1. Text search proves old wording was removed or intentionally retained.
2. BDD structure check proves changed behavior has scenarios and boundaries.
3. Index, entry, and doc-map links resolve to existing files.
4. Related data or Godot checks cover the changed behavior.
5. Manual inspection only when the change is textual and no automated check exists.

When data config validation is needed, use `projectescape-tab-data-guardian`.
When Godot validation is needed, use `projectescape-godot-validation`.

## Missing Coverage

If a behavior-changing doc update has no acceptance or validation path, do not silently pass.

Report:
- what behavior changed;
- which docs were synchronized;
- whether BDD exists;
- whether an acceptance or checklist path exists;
- whether implementation, data, or tests appear to need follow-up;
- what validation should be added if risk justifies it.

For non-trivial behavior changes, prefer adding or updating a focused acceptance or BDD scenario before claiming completion.

## Manual Validation

Manual validation is acceptable for doc-only changes when automated checks are not meaningful.

Manual validation must name:
- files inspected;
- routing or BDD rule used;
- stale wording searches performed;
- links or references checked;
- remaining known doc or implementation mismatch.

## Completion Evidence

Final documentation evidence must include:
- project root used;
- routing docs or guidance discovered;
- files changed;
- whether existing docs were updated or why a new doc was justified;
- BDD or acceptance updates made;
- index, entry, skill, or doc-map synchronization performed or ruled out;
- stale wording searches performed;
- automated checks run, if any;
- manual validation, if used;
- remaining risks or unresolved mismatches.

If validation is blocked, state the blocker plainly and do not describe the docs as fully synchronized.

---
name: writing-specs
description: Use when authoring or updating a detailed specification in a spec-driven codebase, especially when reading or editing specs is slow — agents take too long to find the owning spec, understand scope, locate the code, or plan a change from it.
---

# Writing Specs

## Overview

A spec is the single source of truth for one concept, detailed enough to plan and build a change without reverse-engineering the code. Implementation detail belongs here — pinned modules, schemas, contracts, key formulas, function names — because that detail is exactly what lets an engineer plan a change from the spec instead of spelunking the codebase. Do not strip it out.

**The bottleneck is readability, not detail.** A spec is read far more often than it is written, almost always to answer one of: *which spec owns this concept? what is its scope? where is the code? what changes if I touch it?* When those answers take an agent an hour to assemble, the spec failed — not because it had too much detail, but because the detail wasn't structured for lookup. Optimize every spec so a reader resolves those four questions in seconds.

**Detail is not the enemy of readability — unstructured detail is.** Keep detail scannable: tables and bold lead-in term lists over wall-of-prose, numbered sections so any fact has an address, and a header that states ownership, status, and code location up front. Pin implementation by *pointing* to it (module + symbol) rather than pasting large code blocks the spec doesn't own — the pointer stays detailed and stays readable, and it won't drift from the code.

**One concept, one owner, one file — everyone else points.** Each concept (auth, mounts, run lifecycle) is owned by exactly one spec. When another spec needs it, it links with a backtick filename + section anchor (`see serve-auth.md §3`), never a copy. This is what stops a reader from having to read five coupled files to understand one: each file owns its slice and defers the rest. Size follows from this — a file is large only when its one concept is genuinely rich, never because it absorbed a second concept.

---

## Execution Rules

- **Announce:** Write exactly one line before starting: "I'm using the writing-specs skill to author/update the spec."
- **Triage before writing.** Never open a blank spec file until Phase 1 has located where the concept belongs in the registry. Most "new spec" requests are edits to an existing owner.
- **Detail is welcome — structure it.** Pin implementation modules, schemas, and contracts; mark each as shipped vs. target; point to code by module + symbol. The job is to make detail *findable*, not to remove it.
- **Hand off to planning.** This skill produces or updates a spec; it does not implement. After the spec is settled, hand off to `writing-plans`.

---

## Phases

### 1. Triage — Locate the Concept in the Registry

**Task:** Decide where this change belongs *before* writing. Launch **one** `development:code-explorer` to read the spec registry (the `overview.md` capability index that maps each concept to its owning file) and the candidate owners, or read them yourself if scope is small. Map the request to one outcome:

- **Extend** an existing spec — the concept is already owned. Amend the relevant *numbered section* in place. Default and most common.
- **New surface spec** — a distinct capability under an existing domain hub (`domain-subtopic.md` under `domain.md`). Register it and add it to the hub's family index + `See also`.
- **New hub** — a whole new domain. Rare; it owns the abstract contract and defers detail to surface children.
- **Split** — an existing spec has grown a second concept; carve that concept into its own file and replace the moved content with a pointer.

**Output:** The chosen outcome naming the exact target file(s) and whether it's a hub or surface spec, plus every existing spec that owns a concept this one touches (to point at, not duplicate). State this in 2-3 lines and proceed.

---

### 2. Scope & Decouple

**Task:** Pin the boundary and the pointers before writing prose.

- **Own one thing:** State the spec's ownership claim in one sentence ("this file owns the **mount model**"). Anything outside it goes under `## Non-goals` with a pointer to the spec that does own it.
- **Point, don't copy:** List every concept this spec depends on that another spec already owns. Each becomes a `file.md §N` reference, never copied prose. If you're about to restate another spec's content, stop and point. If the concept is currently duplicated across files, consolidate it into the one owner now and replace the copies with pointers.
- **Locate the code:** Identify the implementing modules and symbols so the spec's header can point a reader straight at the code.

**Output:** The one-sentence ownership claim, the non-goals list (each with its owning spec), the cross-reference set (`file.md §N`), and the implementing-modules list.

---

### 3. Write or Update — Structured for Lookup

**Task:** Apply the spec template (see Output Format), acting on Phase 1's outcome. Structure for scanning, not reading: numbered `## N.` sections, tables and bold lead-in term lists instead of long prose, status markers inline. When **updating**, amend the relevant numbered section in place — never append a section that restates context already above, never leave a stale version beside the new one. When **creating** or **splitting**, write the file under the spec directory with the domain-prefixed name, add its capability bullet to `overview.md`, and wire it into the parent hub's family index and `See also`. If this change retires a spec, record it under the owner's `## Open questions` as a `Superseded`/`Reversal` note and point forward — never silently drop a decision.

**Output:** The written/updated spec file path(s) and the updated registry/hub entries.

---

### 4. Verify Readability

**Task:** Before handoff, walk the reader's four questions against the spec and confirm each resolves fast:

- **Findable?** Is the concept reachable from `overview.md` to this exact file? If new, is it registered and linked from its hub?
- **Scoped at a glance?** Does the opening status block state what the file owns, its shipped/target status, and where the code lives — without reading the body?
- **Navigable?** Are sections numbered so any fact has a `§N` address? Would a table or bold-term list scan faster than the prose you wrote?
- **Decoupled?** Is every borrowed concept a `file.md §N` pointer, not a copy? Is every concept this file owns absent from all other specs? Are all coupled specs reachable via `See also`?

**Output:** Confirmation on all four, then hand off to `writing-plans`.

---

## Output Format

### Spec Document

````markdown
# [Concept Name]

> **Status — [shipped | target | partial | reserved] ([phase/context]).** This file
> owns the **[concept]**. Implementing modules: `path/to/module.ts` (`SymbolA`, `funcB`),
> `path/to/other.py` (`ClassC`). [One line on what's in scope vs. deferred.]

## 1. [First aspect]

Behavioral contract + the implementation detail that pins it. Prefer tables and bold
lead-in term lists for definitions:

- **Term**: precise meaning.
- **Term**: precise meaning, with `module §anchor` where another spec owns the detail.

Mark divergence from shipped code inline — e.g. (SHIPPED) / (TARGET) on a heading or row.
Point to code by module + symbol; don't paste large blocks the spec doesn't own.

## 2. [Next aspect]
…

## Non-goals

What this file deliberately does NOT own — each with the spec that does (`other.md`).

## Open questions

Unresolved cross-spec decisions, kept with annotations rather than deleted:
`RESOLVED — …`, `Superseded by other.md — …`, `Reversal — …`.

## See also

- `related.md` — one line on what it owns and why it's relevant here.
````

### Naming & Hierarchy

- **Hub + surface specs.** A domain is a `domain.md` hub (abstract contract + a family index of its children) plus `domain-subtopic.md` surface specs that each open by deferring to the hub. Children are named by domain prefix: `app.md` → `app-runs.md`, `backends.md` → `backends-aws.md`.
- **Use-case / scenario specs** live in their own subtree (e.g. `cases/`), separate from normative domain specs; **UI specs** under their own umbrella subfolder. Don't mix a plan or a use-case into a domain spec's folder.
- **One concept per file**, domain-prefixed kebab-case — never `spec-1.md`, `misc.md`, or a date-stamped dump folder.

### Registry & Cross-References

- **`overview.md` is the index.** Every spec earns one capability bullet there ending in its owning filename (`**Serve** — expose a route as HTTP… (\`serve.md\`)`). A new or split spec updates `overview.md` in the same change. This is how a reader finds the owner of a concept instead of grepping.
- **Cross-reference with a backtick filename + section anchor** (`serve-auth.md §3`), not a copy and not a pasted code block. Shared prerequisites that every spec assumes live once in a global `assumptions.md`, referenced — not restated per file.

### Rules

These are **spec failures** — never write them:

- No ownership claim in the opening — a reader can't tell if this is the right file.
- No implementing-modules pointer — the agent has to grep for the code the spec describes.
- A wall of prose where a table or bold-term list would scan faster.
- Unnumbered sections in a spec of any size — facts have no `§N` address to reference.
- A duplicated concept — restating a rule, schema, or definition another spec owns instead of pointing to it. Every copy is future drift and an extra file the reader must hold.
- A pasted large code block the spec doesn't own — point to the module + symbol instead.
- A multi-concept file — one whose ownership can't be stated in one sentence; split it.
- A new file for a concept an existing spec already owns — extend the owner.
- Append-on-update, or a stale version left beside the amended one — edit the numbered section in place.
- An unregistered spec (absent from `overview.md`) or one not linked from its hub.
- A silently dropped decision — record reversals/supersessions under `## Open questions`.

Always:

- Lead with ownership + status + code location; one concept per file; point, don't copy; structure detail to be scanned; register every spec.

---

## Integration

**Required follow-up skill:** Hand a settled spec to `writing-plans` to turn it into an implementation plan.

**Subagents this skill uses:** `development:code-explorer` (Phase 1, to read the `overview.md` registry and candidate owners).

**Related:** If updating specs keeps surfacing the same readability gap (concepts duplicated, missing ownership headers, unnumbered sections), invoke `preventing-recurrence` to route the fix into the spec template or registry conventions.

---
name: preventing-recurrence
description: Use when a bug, defect, missing-logic gap, or design omission was just caught — in code review, deep-review, plan refinement, or investigation — and you want to ensure that class of mistake does not recur. Covers routing the lesson to a hook, skill/reviewer edit, project instruction, or memory.
---

# Preventing Recurrence

## Overview

A catch is a one-time event. A mechanism is permanent.

When something slips through and gets caught, fixing the instance is not enough — the same class will recur unless you route the lesson into the **strongest mechanism that catches the whole class automatically next time.**

**Core principle:** Don't just fix the bug and move on, and don't stop at describing options. Classify the catch, remediate the existing twins, then install the most enforceable mechanism available — and actually install it.

## When to Use

- A reviewer (human or `deep-review`) found a bug that was introduced and slipped past build.
- Plan refinement exposed a missing case the planning process should have surfaced.
- `investigate` found a shipped bug with no test that should have caught it.
- Your partner says "make sure this never happens again" / "we keep missing X."

## When Not to Use

- A genuinely one-off issue that will not recur — fix it and move on. Do not manufacture a mechanism for a unique event.
- The constraint is already enforced mechanically (a hook/CI check already catches it).

## The Process

```
1. CLASSIFY   one-off instance, or a recurring class?  (with evidence, not intuition)
2. REMEDIATE  if a class, fix the twins already in the codebase now
3. PICK       choose the strongest enforceable mechanism for the class
4. PLACE      install it at the earliest point that could have caught it
5. COMPLETE   make the edit/commit now — do not stop at a menu
```

### 1. Classify — with evidence

A one-off and a class get different treatment, so do not guess which it is.

- **Search the codebase for siblings** — other code with the same defect. If twins exist, it's a class.
- **Check whether this class was caught before** (past reviews, a blind-spot log, the partner saying "we keep missing this").
- Intuition ("this feels common") is not evidence. Grep first.

A confirmed one-off → fix it and stop.

### 2. Remediate existing instances

If it's a class, the twins already in the codebase are bugs too. Fix them in this same change. Prevention that only guards the future leaves known defects shipped.

### 3. Pick the mechanism — strongest first

Prefer the most enforceable mechanism the defect allows. **Prose and checklists get skimmed; deterministic gates do not.**

| Mechanism | Enforcement | Where it lives / persists | Use when |
|---|---|---|---|
| **Hook / CI check / compiler flag / lint** | Deterministic — cannot be skipped | consumer repo (`settings.json`, CI config, `tsconfig`) — survives plugin updates | a script can detect the defect |
| **Project-local skill / hook** (`.claude/`) | Judgment or deterministic | consumer repo `.claude/` — survives plugin updates | a recurring **project-specific** class |
| **CLAUDE.md / project instructions** | Always loaded, high priority | consumer repo — survives plugin updates | a durable project-specific "always/never" rule |
| **Plugin skill / subagent / reviewer-prompt edit** | Runs every flow, but relies on judgment | **plugin source repo + republish/PR** — NOT the install cache | a **universal** workflow improvement for *all* projects |
| **Memory** | Soft recall, probabilistic | per-project, agent-managed — survives | one non-obvious fact; backstop only |

Strength ranking: **hook > CLAUDE.md / project-local skill > memory.** Never rely on memory as a gate.

**If the language's type system or compiler can be configured to reject the class outright** — a strictness flag (`strictNullChecks`, `noUncheckedIndexedAccess`), an exhaustiveness check, a stricter type — that beats any hook or lint rule. It is deterministic, needs no separate tool, and rejects the whole class at compile time. Reach for it first when the defect is a type-level mistake.

### Distribution check (do this before you pick "edit the skill")

Skills, subagents, and reviewer prompts in this workflow are **distributed as a plugin**. That changes where a mechanism must live to persist:

- **Never edit the installed copy** under `~/.claude/plugins/cache/...` — plugin auto-update overwrites it. The edit is silently lost.
- A plugin skill/agent/prompt edit persists **only** if made in the **plugin source repo and republished** (or via a PR to the marketplace). It is also **global** — it changes the workflow for *every* project and does not reach consumers until they update.
- So decide first: is the lesson **universal** (improve the shared tooling → plugin source + publish/PR) or **project-specific** (→ a consumer-repo mechanism: hook, project-local `.claude/` skill, `CLAUDE.md`, or memory)? **Most caught defects are project-specific** — keep them out of the shared plugin.

When the catch needs judgment and a plugin edit is genuinely warranted (universal), prefer the **automated reviewer/subagent lane** (fires every run) over **author-side prose** (the author skims their own checklist). Add both if you can; the reviewer lane is the real safety net.

Before writing any convention down, **inspect how this repo already enforces conventions** (existing hooks, `CLAUDE.md`, reviewer prompts, project-local skills) — install into the existing machinery, don't invent a parallel doc no one reads.

### 4. Place it — biased by where it was caught

Install the mechanism at the **earliest** point that could have caught the defect. Where it was *actually* caught tells you which direction to shift left. For typed languages the earliest point is not CI — it is the developer's **editor**, via compiler config (e.g. `tsconfig`): the error shows up as they type, before any commit or pipeline. Prefer that over a CI-only check when the defect is type-detectable.

| Caught during | Push the mechanism into |
|---|---|
| Planning / plan refinement | the planning machinery: `writing-plans` / `scope-requirements` + the plan reviewer prompt |
| Code review / `deep-review` | one phase up — build/TDD discipline, or a `deep-review` lane/subagent that catches it next time; **+ a hook if mechanical** |
| Receiving external feedback | same as review, and confirm the reviewer actually had context |
| `investigate` (shipped bug) | the missing test + earliest detection (already core to `investigate`) |

These targets name the **plugin-source** path, for *universal* lessons. For a *project-specific* lesson, install the equivalent in the consumer repo at the same point in the flow — a project-local `.claude/` skill, a hook, or a scoped `CLAUDE.md` rule — never an edit to the shared plugin.

### 5. Complete the capture

Make the edit and commit it now. Do **not** present a menu and stop at "want me to do that?" — a lesson you described but did not institutionalize will recur. If the mechanism is non-obvious to pick, propose one and install it; iterate after.

**Migration cost is not an escape hatch.** The strongest mechanism may surface pre-existing violations — flipping `strictNullChecks` can reveal dozens of existing errors. That cost is not a reason to fall back to a weaker, instant mechanism (a `CLAUDE.md` note). Adopt it in phases instead: enable it scoped to new/changed code, or turn it on and ratchet down the existing violations over follow-up commits. Install the strong mechanism now; pay the migration down over time.

**Confirm before any global propagation.** "Complete the capture" means *install the mechanism* — local edits, project-local config, commits to the repo you are in. It does **not** authorize an outward-facing action that changes other people's setup. Publishing or releasing a plugin change so consumers **auto-update**, opening a marketplace PR, or anything that propagates beyond the current repo has a broad blast radius — **confirm with the user before triggering it.** Make the source edit and commit, then ask before you publish/release.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Stop at a menu, ask "want me to?" | Complete the capture — make the edit now. |
| Assume class vs. one-off by intuition | Get evidence: grep for siblings; check if caught before. |
| Only guard the future | Remediate the twins already in the codebase now. |
| Pick prose when a hook is possible | Prefer the enforceable gate; prose gets skimmed. |
| Author-side checklist as the whole fix | Add the automated reviewer/hook lane too. |
| Write a doc without checking repo enforcement | Inspect existing hooks/CLAUDE.md/reviewer prompts first. |
| Edit the installed plugin copy (`~/.claude/plugins/cache/...`) | Auto-update overwrites it. Edit the plugin source + republish, or use a consumer-repo mechanism. |
| Put a project-specific lesson in the shared plugin | Plugin edits are global. Project-specific → `CLAUDE.md`/project-local `.claude/`/hook/memory. |

## The Bottom Line

Fix the instance, fix its twins, then install the strongest mechanism that catches the class without anyone remembering to look — and install it now, not "later."

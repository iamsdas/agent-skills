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

| Mechanism | Enforcement | Use when |
|---|---|---|
| **Hook / CI check / compiler flag / lint** | Deterministic — cannot be skipped | a script can detect the defect |
| **Skill / subagent / reviewer-prompt edit** | Runs every flow, but relies on judgment | recurring class needing reasoning |
| **CLAUDE.md / project instructions** | Always loaded, high priority | a durable "always/never" convention |
| **Memory** | Soft recall, probabilistic | one non-obvious fact; backstop only |

Strength ranking: **hook > CLAUDE.md / skill-or-reviewer edit > memory.** Never rely on memory as a gate.

When the catch needs judgment and you'd reach for a skill edit, prefer the **automated reviewer/subagent lane** (fires every run) over **author-side prose** (the author skims their own checklist). Add both if you can; the reviewer lane is the real safety net.

Before writing any convention down, **inspect how this repo already enforces conventions** (existing hooks, `CLAUDE.md`, reviewer prompts) — install into the existing machinery, don't invent a parallel doc no one reads.

### 4. Place it — biased by where it was caught

Install the mechanism at the **earliest** point that could have caught the defect. Where it was *actually* caught tells you which direction to shift left.

| Caught during | Push the mechanism into |
|---|---|
| Planning / plan refinement | the planning machinery: `writing-plans` / `scope-requirements` + the plan reviewer prompt |
| Code review / `deep-review` | one phase up — build/TDD discipline, or a `deep-review` lane/subagent that catches it next time; **+ a hook if mechanical** |
| Receiving external feedback | same as review, and confirm the reviewer actually had context |
| `investigate` (shipped bug) | the missing test + earliest detection (already core to `investigate`) |

### 5. Complete the capture

Make the edit and commit it now. Do **not** present a menu and stop at "want me to do that?" — a lesson you described but did not institutionalize will recur. If the mechanism is non-obvious to pick, propose one and install it; iterate after.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Stop at a menu, ask "want me to?" | Complete the capture — make the edit now. |
| Assume class vs. one-off by intuition | Get evidence: grep for siblings; check if caught before. |
| Only guard the future | Remediate the twins already in the codebase now. |
| Pick prose when a hook is possible | Prefer the enforceable gate; prose gets skimmed. |
| Author-side checklist as the whole fix | Add the automated reviewer/hook lane too. |
| Write a doc without checking repo enforcement | Inspect existing hooks/CLAUDE.md/reviewer prompts first. |

## The Bottom Line

Fix the instance, fix its twins, then install the strongest mechanism that catches the class without anyone remembering to look — and install it now, not "later."

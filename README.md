# Agent Skills

A marketplace of Claude Code skills and subagents, organized into two plugins:

- **`development/`** — skills and subagents for the full feature/bugfix lifecycle: scoping, planning, building, testing, reviewing, and shipping.
- **`utilities/`** — general-purpose helpers: meta-skills for authoring skills/agents, conversation tooling, and integrations.

This README explains **which skill to reach for**, **what order they chain in**, and **which are used passively** (auto-invoked by Claude rather than chosen by you).

---

## The development lifecycle

Skills are designed to chain. Two canonical flows:

### Building a feature / change

```
scope-requirements      →  agree on WHAT and WHY (product intent, no implementation)
        ↓
writing-plans           →  turn the agreed scope into a step-by-step implementation plan
        ↓
using-git-worktrees     →  carve out an isolated workspace for the work
        ↓
executing-plans         →  execute the plan with review checkpoints (separate session)
   or
subagent-driven-development →  execute independent tasks via subagents in the current session
        ↓
requesting-code-review  →  verify the work meets requirements
        ↓
deep-review             →  deep pre-merge review (breaking changes, migrations, coverage)
        ↓
finishing-a-development-branch → decide how to integrate: merge, PR, or cleanup
        ↓
creating-pull-requests  →  open the PR with summary, mermaid visuals, usage, and test plan
```

### Fixing a bug

```
investigate             →  diagnose: end-user impact, exact root cause, missing test
        ↓
(scope-requirements)    →  ONLY if the correct behavior needs product decisions
        ↓
writing-plans / test-driven-development → plan and fix
        ↓
requesting-code-review → deep-review → finishing-a-development-branch
```

> **scope-requirements vs. investigate** — `investigate` looks *backward* (why is it broken?) and is the right entry point for a bug or error. `scope-requirements` looks *forward* (what should change?) and assumes you already know the desired behavior. For a bug, start with `investigate`; only reach for `scope-requirements` afterward if the fix involves real product decisions.

> **preventing-recurrence (cross-cutting)** — not a phase but an *event handler*. Whenever a real defect or missing-logic gap is caught — during `writing-plans` refinement, `deep-review`, `receiving-code-review`, or `investigate` — those skills invoke `preventing-recurrence` to route the lesson into a durable mechanism (hook, skill/reviewer edit, project instruction, or memory) so the same class is caught automatically next time. It biases the fix toward the *earliest* point that could have caught the defect.

---

## Subagents (always passive)

Subagents in `development/agents/` are **never invoked directly by you** — skills and Claude dispatch them in the background (often in parallel) to do focused, context-isolated work. You'll see them referenced from within skills like `investigate`, `deep-review`, `writing-plans`, and `scope-requirements`.

| Agent | Dispatched to… |
|-------|----------------|
| **code-explorer** | Trace execution paths and map architecture to understand existing behavior. |
| **code-architect** | Design a feature's architecture and produce an implementation blueprint. |
| **focused-builder** | Implement a single well-scoped task (writes code, TDD, commits, self-reviews). |
| **code-reviewer** | Review code for bugs, logic errors, security, and convention adherence. |
| **code-simplifier** | Simplify recently written code for clarity without changing behavior. |
| **tests-analyzer** | Assess test coverage quality and identify gaps / missing tests. |
| **silent-failure-hunter** | Find swallowed errors, bad fallbacks, and inadequate error handling. |
| **comment-analyzer** | Check comments for accuracy, staleness, and missing rationale. |
| **type-design-analyzer** | Rate type design for invariant strength, encapsulation, and usefulness. |

---


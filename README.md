# Agent Skills

A marketplace of Claude Code skills and subagents, organized into three plugins:

- **`development/`** — skills and subagents for the full feature/bugfix lifecycle: scoping, building, testing, reviewing, and shipping.
- **`utilities/`** — general-purpose helpers: meta-skills for authoring skills/agents, conversation tooling, and integrations.
- **`ui/`** — frontend work: diagnosing why something looks wrong, exploring design options, and staying inside a codebase's existing conventions.

This README explains **which skill to reach for**, **what order they chain in**, and **which are used passively** (auto-invoked by Claude rather than chosen by you).

---

## The development lifecycle

Skills are designed to chain. Two canonical flows:

### Building a feature / change

```
scope-requirements      →  agree on WHAT and WHY (product intent, no implementation).
                           You answer the refinement questions; the agreed scope is
                           both the approval and the builder's brief.
        ↓
building-with-subagent  →  isolate the workspace (worktree/branch), then hand the
                           agreed scope to a builder subagent that builds
                           everything, then runs /code-review, then pauses
        ↓
   (building-with-subagent runs these automatically, hands-off, then pauses):
   creating-pull-requests →  push branch + open PR (summary, mermaid visuals, usage, test plan)
   /code-review           →  inbuilt pre-merge review of the diff
        ↓  ── PAUSE: you review the open PR and decide how to land it ──
finishing-a-development-branch → only when you explicitly choose: local merge, or discard/cleanup
```

> **One approval, then hands-off** — the single human checkpoint is agreeing the scope in `scope-requirements`. After that, everything runs without check-ins: `building-with-subagent` isolates the workspace and hands the brief to a builder subagent, which builds it, opens a PR, and runs the inbuilt `/code-review`, then **pauses** with the PR link and findings. It never merges on its own. The interactive merge/discard menu in `finishing-a-development-branch` only appears if you ask for it after the pause.
>
> **Builders are disposable.** A builder is retired when it reports done, and each fix or continuation round gets a fresh one briefed from the branch — the commits, brief, and decisions log are the state, not the agent's conversation. Keeping one builder alive across review rounds was costing 3-5x the context of the build itself.
>
> `building-with-subagent` is generic — it also builds directly from a written spec (`writing-specs`), a triaged review set (`receiving-code-review`), or a clear ad-hoc task, not just an agreed scope.

### Fixing a bug

```
investigate             →  diagnose: end-user impact, exact root cause, missing test
        ↓
(scope-requirements)    →  ONLY if the correct behavior needs product decisions
        ↓
building-with-subagent / test-driven-development → fix it
        ↓
requesting-code-review → /code-review → finishing-a-development-branch
```

> **scope-requirements vs. investigate** — `investigate` looks *backward* (why is it broken?) and is the right entry point for a bug or error. `scope-requirements` looks *forward* (what should change?) and assumes you already know the desired behavior. For a bug, start with `investigate`; only reach for `scope-requirements` afterward if the fix involves real product decisions.

> **preventing-recurrence (cross-cutting)** — not a phase but an *event handler*. Whenever a real defect or missing-logic gap is caught — during `scope-requirements` refinement, `/code-review`, `receiving-code-review`, or `investigate` — those skills invoke `preventing-recurrence` to route the lesson into a durable mechanism (hook, skill/reviewer edit, project instruction, or memory) so the same class is caught automatically next time. It biases the fix toward the *earliest* point that could have caught the defect.

---

## Subagents (always passive)

Subagents in `development/agents/` are **never invoked directly by you** — skills and Claude dispatch them in the background (often in parallel) to do focused, context-isolated work. You'll see them referenced from within skills like `investigate`, `writing-specs`, and `scope-requirements`.

| Agent | Dispatched to… |
|-------|----------------|
| **code-explorer** | Trace execution paths and map architecture to understand existing behavior. |
| **code-architect** | Design a feature's architecture and produce an implementation blueprint. |
| **code-reviewer** | Review code for bugs, logic errors, security, and convention adherence. |
| **code-simplifier** | Simplify recently written code for clarity without changing behavior. |
| **tests-analyzer** | Assess test coverage quality and identify gaps / missing tests. |
| **silent-failure-hunter** | Find swallowed errors, bad fallbacks, and inadequate error handling. |
| **comment-analyzer** | Check comments for accuracy, staleness, and missing rationale. |
| **type-design-analyzer** | Rate type design for invariant strength, encapsulation, and usefulness. |

---


## UI work

Three skills, split by what you're doing. They are deliberately repo-agnostic — project vocabulary belongs in that project's own `CLAUDE.md` or skills, not in here.

| Skill | Invoked | For |
|-------|---------|-----|
| **diagnosing-ui** | when you complain | You point at something and say it looks bad. Returns the named problem, the mechanism, and the fix — not an audit. |
| **ui-variants** | when you ask | "Show me some options for X." Builds one HTML page of genuinely different takes, made decidable. |
| **ui-conventions** | passively | Any CSS or styled-component edit. Puts a read of the existing vocabulary between the impulse and the file. |

**Why these exist.** Generic design skills underperform inside a codebase that already has a partial design system. Two failure modes drove the split, both reproduced with baseline tests before anything was written:

- Asked why a screen "feels off," a domain-routing review skill produced 13 findings of which ~2 addressed the question, then ended on a verdict of **Approve**. Routing to six domains means six tables want filling.
- Asked to build a new settings page, an agent with no conventions skill committed 8 violations — including inventing a button class that loses a specificity fight it couldn't see, and naming a stylesheet that already existed.

So `diagnosing-ui` resolves the complaint before looking and reports only what explains it; `ui-conventions` makes reuse the default; `ui-variants` optimizes for deciding rather than generating.

---

## Credits

Skills here borrow structure and ideas from prior art. Where something is derived, it's noted below.

| Source | Taken |
|--------|-------|
| [jakubkrehel/skills](https://github.com/jakubkrehel/skills) (`interfaces`) | Form, mostly: the `Mistake \| Fix` "Before you finish" table, cue-gated checklists, calibration lines, and cheapest-fix ordering (Delete → Use the platform → Reuse → Correct → Add), which `diagnosing-ui` and `ui-conventions` both use. Its review posture and severity ladders were deliberately *not* carried over. |
| [jakubkrehel/make-interfaces-feel-better](https://github.com/jakubkrehel/make-interfaces-feel-better) | The authoring pattern: name constants instead of adjectives, state the failure mode inside each anti-rule, and scope every rule with when it stops applying. |
| [anthropics/claude-code](https://github.com/anthropics/claude-code) (`frontend-design`) | Its taxonomy of AI-design tells — the reflexes that make generated UI read as templated. |
| [obra/superpowers](https://github.com/obra/superpowers) | The TDD-for-skills method used to build these (baseline first, write against observed failures, retest), and much of `development/` and `utilities/`. |

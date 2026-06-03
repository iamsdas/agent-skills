---
name: writing-plans
description: Use when you have a clear spec or requirements for a multi-step coding task, and the user wants to plan out the final implementation details.
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, where to look for reference, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**No code blocks in plans.** Point to where things are instead — exact file paths and line numbers. The engineer reads the code; the plan tells them where to look and what to do.

---

## Execution Rules

- **Announce:** Write exactly one line before starting: "I'm using the writing-plans skill to create the implementation plan."
- **Task tracking:** Before starting, create one task per phase using TaskCreate. Mark each task `in_progress` when beginning it, `completed` when done. This renders a live-updating checklist for the user.
- **Sequential:** Run phases in order. Each must complete before the next begins.
- **Two routes — pick in Phase 1.** Don't fan out by default. The full multi-agent path (Phases 2–4) is for large or unfamiliar work; for small, well-understood changes take the **fast path** (one combined pass). Phase 1 presents its scope read and lets the user choose. Over-provisioning agents on a localized change is the main reason planning feels slow.
- **Never execute the plan yourself.** This skill *writes* the plan; it does not build. After the plan is approved, hand off to the `subagent-driven-development` skill (Phase 6) — do not start editing files, writing tests, or running the plan's steps in this conversation.

---

## Phases

### 1. Scope Check & Route

**Task:** Two things. First, determine if the spec covers multiple independent subsystems — each plan should produce working, testable software on its own; propose a split if so. Second, do a quick scope read and choose the route:

- **Which subsystem(s)** the change touches and a rough file count.
- **Whether the approach is obvious** (clear where the code goes, an established pattern to follow, no real design fork) or has **genuine ambiguity** (multiple viable architectures, unfamiliar area, cross-cutting impact).

Present that read to the user in 2-3 lines and ask them to choose, recommending one:

- **Fast path** — small, localized, approach is obvious. Skips the parallel fan-out (Phase 2 collapses to a single combined pass; Phase 3's architecture tournament is skipped). Use for most single-subsystem changes.
- **Thorough path** — large, unfamiliar, or design ambiguity worth comparing approaches. Runs the full multi-agent Phases 2–4.

Use `AskUserQuestion`. Default the recommendation to Fast unless the scope read surfaced real ambiguity or breadth.

**Output:** Single-vs-split decision, the scope read, and the user's route choice.

---

### 2. Codebase Exploration

Scale the agent count to the route — do not fan out wider than the task needs.

**Fast path:** Launch **one** code-explorer (or read the relevant files yourself if it's a handful) targeting the change site and its immediate patterns. It MUST still enumerate every parallel/duplicate implementation and call site of the code being changed (sibling handlers, the same operation for another entity/platform, copy-pasted branches) — that completeness check is non-negotiable on either route. Then go straight to Phase 4 (Phase 3 is skipped on the fast path).

**Thorough path:** Launch **2-3** code-explorer agents in parallel, each targeting a different aspect (e.g. similar features, high-level architecture, control flow), each reading 5-10 key files and tracing abstractions end-to-end. One explorer MUST do the parallel-implementation/call-site enumeration above.

**Output:** Summary of existing patterns and architecture relevant to this task, including every parallel implementation or sibling call site that must change in lockstep (file:line each).

---

### 3. Architecture Design

**Skip this phase entirely on the fast path** — go to Phase 4.

**Thorough path:** Launch 2-3 code-architect agents in parallel with different focuses — minimal changes (smallest change, maximum reuse), clean architecture (maintainability, elegant abstractions), or pragmatic balance (speed + quality). Pass each architect the exploration summary from Phase 2 (patterns, parallel implementations, call sites) — they design the high-level approach on those findings rather than re-tracing the codebase. **Only if** the change plausibly makes existing code dead or consolidatable, add one `code-simplifier` agent to the same batch (analysis only — it must not edit) to flag dead branches, duplication to consolidate, and abstractions to collapse; skip it when the change is purely additive. Review all approaches and form a recommendation.

**Output:** Brief summary of each approach, trade-offs comparison, recommendation with reasoning, and any simplification opportunities worth folding into the plan. Present to user and wait for confirmation before continuing.

**HARD GATE: do NOT ask the user to pick an approach (via AskUserQuestion or otherwise) until the per-approach summaries and trade-offs have been output as visible text in the conversation.** Labels like "Approach A/B/C" mean nothing to the user on their own — each option must have already been described (what it changes, its key trade-off) before any selection question, and the question's option descriptions must restate the one-line essence of each approach. The architects' raw outputs are in your context, not the user's — having read them is not a substitute for showing the comparison.

---

### 4. File Structure

**Task:** Map out all files to create or modify. Each file gets one clear responsibility. Follow established codebase patterns. Files that change together should live together — split by responsibility, not technical layer.

**Output:** File map with each file's responsibility. This locks in decomposition decisions.

---

### 5. Present for Execution

**Task:** Enter plan mode via `EnterPlanMode`. Write the full plan document directly to the plan file path provided by plan mode (shown in the plan mode system message). A review hook fires automatically after the Write — address any feedback before calling `ExitPlanMode`.

**Output:** User approves and exits plan mode.

---

### 6. Hand Off to Execution

**This phase runs *after* plan mode has exited.** Both steps below modify files — `preventing-recurrence` edits the planning machinery, and execution builds the code — so neither can run inside plan mode. Phase 5 ends at `ExitPlanMode`; only then does this phase begin.

**Do not start building.** Writing the plan is the end of *this* skill's job. The moment the plan is approved, STOP and hand off — even though the plan's tasks list exact files, TDD steps, and commit commands, you do not run them yourself in this conversation.

**Task:**

1. **First, check for a systemic planning gap.** If review or the user's refinement exposed a *systemic* gap — a class of case the plan dropped that the planning process should have surfaced (e.g. "we keep missing concurrency") — invoke the `preventing-recurrence` sub-skill before handing off. Tell it the gap was caught *at planning*, so the fix lands in the planning machinery (this skill or the plan reviewer prompt), not downstream.
2. **Then hand off execution.** Invoke the `subagent-driven-development` skill to execute the approved plan (or `executing-plans` if the user wants a separate parallel session). That skill dispatches a fresh subagent per task with review checkpoints — it is what actually builds.

**Output:** Execution begins under `subagent-driven-development`, not under this skill.

**Red flag — STOP if you catch yourself:** opening a file to edit, writing a test, or running a plan step right after approval. That means you skipped the handoff. Invoke `subagent-driven-development` instead.

---

## Output Format

### Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about approach]

---
```

### Task Structure

Each task follows this format. Tasks are bite-sized — each step is one action (2-5 minutes):

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

Add a test to `tests/path/test.py` modeled after the existing test at `tests/path/test.py:45`. It should assert that `function(input)` returns `expected`.

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement**

Add `function` to `src/path/file.py` following the pattern at `src/path/file.py:78`. See `src/path/other.py:12-30` for how similar logic is handled.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

`git add tests/path/test.py src/path/file.py && git commit -m "feat: add specific feature"`
````

### Rules

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without pointing to a specific file and reference pattern
- "Similar to Task N" — repeat the pointer, the engineer may be reading tasks out of order
- Changing one path while leaving its siblings untouched — when the same logic lives in multiple parallel places (sibling call sites, duplicated handlers, the same operation for another entity/platform), every task that modifies one MUST list all the others by file:line and apply the same change to each
- Steps that say what to do without pointing to where (exact file:line references required)
- Code blocks — describe what to build and where to look, not what to write

Always use:

- Exact file paths and line numbers — point to where things are, never write them out
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

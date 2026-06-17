---
name: writing-plans
description: Use when you have a clear spec or requirements for a multi-step coding task, and the user wants to plan out the final implementation details.
---

# Writing Plans

## Overview

Write implementation plans for a capable engineer who can read code, follow established patterns, and fill in routine details on their own — but who starts with zero context for our codebase and its decisions. Document what they can't infer from the code: which files to touch for each task, the pattern to follow and where it lives, project-specific gotchas, parallel implementations that must change in lockstep, and how to verify the work. Don't spell out what a competent engineer would do anyway. DRY. YAGNI. TDD. Commit per task.

The plan's job is to transfer *decisions and pointers*, not to be an instruction tape. Each task is one subagent's entire job — size it so the subagent keeps the thread and its diff reviews in one sitting, yet so it still earns its spin-up and context reload. Both directions cost you: many tiny tasks waste reloads, while one sprawling task overwhelms the subagent and produces a diff no one can review. Aim for the largest coherent slice that still reviews cleanly.

**Plan the leanest thing that works.** The plan is where over-engineering is *introduced* — the implementer just builds what you specify. So every task, abstraction, and dependency must earn its place here: does it need to exist *now*, or is it speculative ("for later")? Cut speculative scope or mark it explicitly deferred. Prefer the standard library, then native platform features, then an already-installed dependency — never plan a new dependency for what a few lines do. No abstraction with a single implementation, no config for a value that never changes, fewest files that hold the responsibilities cleanly; an abstraction earns its place only with a second concrete caller in scope. This is design discipline, not corner-cutting — never plan away input validation at trust boundaries, error handling that prevents data loss, security, or accessibility.

**No code blocks in plans.** Point to where things are instead — exact file paths and line numbers. The engineer reads the code; the plan tells them where to look and what to do.

---

## Execution Rules

- **Announce:** Write exactly one line before starting: "I'm using the writing-plans skill to create the implementation plan."
- **Task tracking:** Before starting, create one task per phase using TaskCreate. Mark each task `in_progress` when beginning it, `completed` when done. This renders a live-updating checklist for the user. These tasks are scaffolding for this skill only — when the skill ends (the Phase 6 handoff, or planning abandoned mid-way), delete every task it created via TaskUpdate with status `deleted`, so the checklist doesn't linger and absorb later, unrelated work.
- **Sequential:** Run phases in order. Each must complete before the next begins.
- **Two routes — decide in Phase 1.** Don't fan out by default. The full multi-agent path (Phases 2–4) is for large or unfamiliar work; for small, well-understood changes take the **fast path** (one combined pass). Phase 1 does the scope read and picks the route itself — it does not stop to ask. Over-provisioning agents on a localized change is the main reason planning feels slow.
- **Never execute the plan yourself.** This skill *writes* the plan; it does not build. After the plan is approved, hand off to the `subagent-driven-development` skill (Phase 6) — do not start editing files, writing tests, or running the plan's steps in this conversation.

---

## Phases

### 1. Scope Check & Route

**Task:** Two things. First, determine if the spec covers multiple independent subsystems — each plan should produce working, testable software on its own; propose a split if so. Also split on *size*, not just subsystem boundaries: if executing the whole thing would be one very long session (a dozen-plus tasks, or completed work that piles up faster than it's needed downstream), sequence it into stages that each ship something testable and get executed in a separate session. A fresh session per stage resets accumulated context instead of re-sending an ever-growing history on every turn — the single biggest driver of execution cost. Second, do a quick scope read and choose the route:

- **Which subsystem(s)** the change touches and a rough file count.
- **Whether the approach is obvious** (clear where the code goes, an established pattern to follow, no real design fork) or has **genuine ambiguity** (multiple viable architectures, unfamiliar area, cross-cutting impact).

State that read to the user in 2-3 lines, then pick the route yourself and proceed — do not ask:

- **Fast path** — small, localized, approach is obvious. Skips the parallel fan-out (Phase 2 collapses to a single combined pass; Phase 3's architecture tournament is skipped). Use for most single-subsystem changes.
- **Thorough path** — large, unfamiliar, or design ambiguity worth comparing approaches. Runs the full multi-agent Phases 2–4.

Default to Fast; take the Thorough path only when the scope read surfaced real ambiguity or breadth. Announce the chosen route in one line ("Taking the fast path — single subsystem, obvious approach") and continue to Phase 2. The user can redirect if they disagree; don't block on `AskUserQuestion`.

**Output:** Single-vs-split decision (by subsystem and by size), the scope read, and the chosen route.

---

### 2. Codebase Exploration

Scale the agent count to the route — do not fan out wider than the task needs.

**Fast path:** Launch **one** development:code-explorer (or read the relevant files yourself if it's a handful) targeting the change site and its immediate patterns. It MUST still enumerate every parallel/duplicate implementation and call site of the code being changed (sibling handlers, the same operation for another entity/platform, copy-pasted branches) — that completeness check is non-negotiable on either route. Then go straight to Phase 4 (Phase 3 is skipped on the fast path).

**Thorough path:** Launch **2-3** development:code-explorer agents in parallel, each targeting a different aspect (e.g. similar features, high-level architecture, control flow), each reading 5-10 key files and tracing abstractions end-to-end. One explorer MUST do the parallel-implementation/call-site enumeration above.

**Output:** Summary of existing patterns and architecture relevant to this task, including every parallel implementation or sibling call site that must change in lockstep (file:line each).

---

### 3. Architecture Design

**Skip this phase entirely on the fast path** — go to Phase 4.

**Thorough path:** Launch 2-3 development:code-architect agents in parallel with different focuses — minimal changes (smallest change, maximum reuse), clean architecture (maintainability, elegant abstractions), or pragmatic balance (speed + quality). Pass each architect the exploration summary from Phase 2 (patterns, parallel implementations, call sites) — they design the high-level approach on those findings rather than re-tracing the codebase. **Only if** the change plausibly makes existing code dead or consolidatable, add one `development:code-simplifier` agent to the same batch (analysis only — it must not edit) to flag dead branches, duplication to consolidate, and abstractions to collapse; skip it when the change is purely additive. Review all approaches and form a recommendation. **Default the recommendation to the leanest approach that meets the spec** — the clean-architecture approach wins only where its abstractions have a concrete second caller or a named, near-term need; otherwise prefer fewer files, fewer layers, and reuse over new structure.

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
2. **Clean up the phase checklist.** Delete every phase-tracking task this skill created (TaskUpdate with status `deleted`). The checklist was scaffolding for planning; leaving it alive makes every subsequent task in the session pile into it.
3. **Then hand off execution.** Invoke the `subagent-driven-development` skill to execute the approved plan (or `executing-plans` if the user wants a separate parallel session). That skill dispatches a fresh subagent per task with review checkpoints — it is what actually builds.

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

Each task is one coherent unit of work that ends in a passing test suite and a commit — and it is also one subagent's entire assignment, so it must stay reviewable as a single diff. Split at boundaries where the guidance genuinely changes (different subsystem, different pattern to follow, a checkpoint worth reviewing between them), **and** split a task that has grown too broad — it spans several unrelated concerns, you can't state its goal without saying "and also", or its diff would be too large to review in one pass — even when it all lives in one subsystem. Don't split merely to make tasks smaller, and don't break a task into write-test / run-test / implement / commit micro-steps; state the TDD expectation once and let the engineer execute it. Task count falls out of these boundaries, not a target you steer toward — most plans land around 3-7, but a genuinely broad feature needs more, and forcing it into fewer just makes each task too big to execute or review well.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**What to do:**

Test-first: add tests to `tests/path/test.py` modeled after the existing test at `tests/path/test.py:45`, asserting that `function(input)` returns `expected` (cover the empty-input and duplicate-key cases — see `tests/path/test.py:60` for how those are set up). Then implement `function` in `src/path/file.py` following the pattern at `src/path/file.py:78`; see `src/path/other.py:12-30` for how similar logic is handled.

**Verify:** `pytest tests/path/test.py -v` — all pass.

**Commit:** `feat: add specific feature`
````

### Rules

Every task must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without pointing to a specific file and reference pattern
- "Similar to Task N" — repeat the pointer, the engineer may be reading tasks out of order
- Changing one path while leaving its siblings untouched — when the same logic lives in multiple parallel places (sibling call sites, duplicated handlers, the same operation for another entity/platform), every task that modifies one MUST list all the others by file:line and apply the same change to each
- Tasks that say what to do without pointing to where (exact file:line references required)
- Code blocks — describe what to build and where to look, not what to write
- Micro-step checklists (write test / run test / implement / commit as separate steps) — that's the engineer's job to sequence, not the plan's
- Over-broad tasks — one task spanning several unrelated concerns, or whose diff is too large to review in one pass; split it at the seam even within a single subsystem
- Speculative scope — a task, abstraction, or new dependency with no concrete caller or named near-term need in this plan; cut it or mark it explicitly deferred
- A new dependency for what the stdlib, a native platform feature, or a few lines already do

Always use:

- Exact file paths and line numbers — point to where things are, never write them out
- Exact verification commands with expected outcome
- DRY, YAGNI, TDD, one commit per task

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
- **Subagent driven execution:** use the subagent-driven-development skill for execution once user is ready.

---

## Phases

### 1. Scope Check

**Task:** Determine if the spec covers multiple independent subsystems. Each plan should produce working, testable software on its own.

**Output:** Confirm single plan, or propose a split into sub-plans with one per subsystem.

---

### 2. Codebase Exploration

**Task:** Launch 2-3 code-explorer agents in parallel. Each targets a different aspect (e.g. similar features, high-level architecture, control flow). Each reads 5-10 key files and traces abstractions end-to-end. One explorer MUST enumerate every parallel/duplicate implementation and all call sites of the code being changed — sibling handlers, the same operation for a different entity or platform, copy-pasted branches — so no path that needs the same change is missed.

**Output:** Comprehensive summary of existing patterns and architecture relevant to this task, including a list of every parallel implementation or sibling call site that must change in lockstep with the primary change (file:line each).

---

### 3. Architecture Design

**Task:** Launch 2-3 code-architect agents in parallel with different focuses — minimal changes (smallest change, maximum reuse), clean architecture (maintainability, elegant abstractions), or pragmatic balance (speed + quality). Review all approaches and form a recommendation.

**Output:** Brief summary of each approach, trade-offs comparison, and recommendation with reasoning. Present to user and wait for confirmation before continuing.

---

### 4. File Structure

**Task:** Map out all files to create or modify. Each file gets one clear responsibility. Follow established codebase patterns. Files that change together should live together — split by responsibility, not technical layer.

**Output:** File map with each file's responsibility. This locks in decomposition decisions.

---

### 5. Present for Execution

**Task:** Enter plan mode via `EnterPlanMode`. Write the full plan document directly to the plan file path provided by plan mode (shown in the plan mode system message). A review hook fires automatically after the Write — address any feedback before calling `ExitPlanMode`.

**Output:** User approves and exits plan mode to begin execution.

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

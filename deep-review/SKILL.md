---
name: deep-review
description: Performs deep branch and PR reviews with subagent-first analysis, including breaking changes, migration compatibility, testing coverage gaps, redundant changes, dependency additions, and logic edge cases. Use when the user asks for /deep-review or requests a comprehensive code review before merge.
disable-model-invocation: true
---

# Deep Review

## Instructions

Spawn all subagents defined below in a single message so they run concurrently. Collect all results, then synthesize the final review. If a PR exists, pass PR title/body/discussion into relevant subagents. If no PR exists, proceed with branch-only review and note that limitation in the summary.

## Execution Rules

- **Model parameter:** You MUST pass the `model` parameter on every Agent tool call. Never omit it. Subagents spawned without a model parameter are a bug.
- **Task tracking:** Before spawning any subagent, create one task per subagent using TaskCreate. Mark all tasks `in_progress` when spawning. As each background agent returns, mark its task `completed`. This renders a live-updating checklist in the UI.
- **Parallelism:** Spawn ALL subagents in a single message. Do NOT wait for one to finish before launching the next. Use `run_in_background: true` for every subagent.
- **Output suppression:** Write exactly one line before spawning: `Running deep review…`. Write nothing else until all subagents have returned.
- **Final output:** Prioritize findings by severity with concrete file/symbol references.

## Subagents

### context (haiku)
**Task:**
- Summarize branch purpose and scope of changes
- Extract and list commit messages
- Capture PR title, body, and any linked discussion
**Output:** branch summary, PR context paragraph, changed file list

---

### deps (haiku)
**Task:**
- List every new package added and any version changes to existing packages
- Note if a package is dev-only vs runtime
**Output:** table of added/changed packages with old→new versions and dev/runtime classification

---

### breaking (sonnet)
**Task:**
- Identify changes to public APIs, exported interfaces, function signatures, and schema definitions that are not backwards-compatible
- Flag removed or renamed exports, changed parameter types, and removed fields
**Output:** list of breaking changes with file:line references and description of what breaks

---

### migrations (sonnet)
**Task:**
- Find database migrations, schema changes, and data transformations
- Check whether each migration is backwards-compatible (old code can run against new schema and vice versa)
- Flag irreversible migrations or missing rollback paths
**Output:** list of migrations with compatibility assessment and any rollback concerns

---

### tests (sonnet)
**Task:**
- For each changed component or code path, identify whether tests exist that cover the change
- Flag missing unit tests, integration tests, and edge case coverage
- Note if existing tests were deleted without replacement
**Output:** per-component coverage assessment with specific gaps called out at file:line

---

### redundancy (sonnet)
**Task:**
- Find code that duplicates existing functionality elsewhere in the diff or codebase
- Identify dead code, unreachable branches, and unused variables introduced by this diff
- Flag old code paths that are logically superseded by a new path (e.g., old endpoint) but are neither removed nor marked deprecated
**Output:** list of redundant/dead/stale code with file:line and description

---

### logic (sonnet)
**Task:**
- Find edge cases not handled by the new logic (off-by-one, null/empty inputs, concurrency, overflow, race conditions)
- Identify outright bugs: wrong operator, incorrect conditional, missing await, etc.
**Output:** list of logic issues with file:line, description of the problem, and suggested fix

---

### comments-params (sonnet)
**Task:**
- Flag removed comments that captured information not obvious from the code alone (hidden constraints, workarounds, subtle invariants)
- Flag new parameters, config values, or flags that lack documentation when the information is non-obvious
- For every newly introduced parameter, config value, or flag: validate the name and value are correct against source type definitions or official documentation. Never assume validity without evidence.
**Output:** list of documentation gaps and param validation findings with file:line

---

## Required Output Format

- **Omit any section entirely if there is nothing to report.** Do not write "None found" placeholders.
- Always include the Summary section.
- Use severity tags: `[critical]`, `[high]`, `[medium]`, `[low]`.
- Include file and line references for every finding.

```markdown
# Review: <branch or PR name>

<One sentence: what this branch does.>

---

## 🔴 Critical / 🟠 High Priority

> Only include if there are critical or high severity findings.

- **[critical] Title** — `file:line`
  Impact and why it matters. What breaks or who is affected.

- **[high] Title** — `file:line`
  Impact and why it matters.

---

## 🟡 Needs Attention

> Medium severity: logic edge cases, missing tests, deprecated paths not removed, removed context comments, etc.

- **[medium] Title** — `file:line`
  What the issue is and what to do about it.

---

## 🔵 Low / Informational

> Low severity: style, minor redundancy, new packages, suggestions.

- **[low] Title** — `file:line`
  Note.

---

## Summary

**Merge readiness:** Ready / Needs fixes / Blocked

- <key finding or required action 1>
- <key finding or required action 2>
```

## Quality Bar

- Do not claim certainty without evidence from diffs, commits, or tests.
- Flag assumptions explicitly.
- Omit sections with nothing to report — a short, dense review is better than a padded one.

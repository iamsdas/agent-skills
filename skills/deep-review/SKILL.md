---
name: deep-review
description: Performs deep branch and PR reviews with subagent-first analysis, including breaking changes, migration compatibility, testing coverage gaps, redundant changes, dependency additions, and logic edge cases. Use when the user asks for /deep-review or requests a comprehensive code review before merge.
disable-model-invocation: true
---

# Deep Review

## Instructions

Spawn all subagents defined below in a single message so they run concurrently. Collect all results, then synthesize the final review. If a PR exists, pass PR title/body/discussion into relevant subagents. If no PR exists, proceed with branch-only review and note that limitation in the summary.

## Execution Rules

- **Model parameter:** Named agents (`subagent_type` specified) define their own model — do not pass a `model` parameter. General-purpose agents (no `subagent_type`) MUST have an explicit `model` parameter. Omitting model on a general-purpose call is a bug.
- **Task tracking:** Before spawning any subagent, create one task per **applicable** subagent (after triage) using TaskCreate. Mark all tasks `in_progress` when spawning. As each background agent returns, mark its task `completed`. This renders a live-updating checklist in the UI.
- **Parallelism:** Spawn ALL subagents in a single message. Do NOT wait for one to finish before launching the next. Use `run_in_background: true` for every subagent.
- **Triage (before spawning):** Collect `CHANGED_FILES` and `DIFF_CONTENT` via `git diff` (see Triage section below). Evaluate the rule table to determine which subagents to spawn. Then spawn only the applicable set — all in a single message with `run_in_background: true`.
- **Output suppression:** Write `Running deep review…` before spawning (after triage is complete), then optionally a skipped-subagents note if applicable (see Triage section). Write nothing else until all subagents have returned.
- **Final output:** Prioritize findings by severity with concrete file/symbol references.
- **Unused code severity cap:** Any finding (bug, logic error, missing test, etc.) in code identified as dead, unreachable, or unused MUST be capped at `[low]` severity. Do not mark errors in unused code as `[high]` or `[critical]`.

## Triage

Collect diff data before spawning anything:

```bash
BASE_COMMIT=$(git merge-base HEAD ${BASE_BRANCH:-main})
CHANGED_FILES=$(git diff --name-only ${BASE_COMMIT}..HEAD)
DIFF_CONTENT=$(git diff ${BASE_COMMIT}..HEAD)
```

Evaluate each subagent against these rules:

| Subagent | Always spawn | Spawn only if |
|---|---|---|
| `context` | ✓ | — |
| `tests` | ✓ | — |
| `redundancy` | ✓ | — |
| `logic-and-conventions` | ✓ | — |
| `deps` | — | CHANGED_FILES includes a package manifest or lock file: `package.json`, `bun.lockb`, `yarn.lock`, `package-lock.json`, `Cargo.toml`, `Cargo.lock`, `requirements.txt`, `pyproject.toml`, `go.mod`, `go.sum`, `pom.xml`, `*.gemspec` |
| `breaking` | — | DIFF_CONTENT has removed or changed exported/public symbols: diff lines matching `-.*export `, `-.*interface `, `-.*type `, `-.*pub fn`, `-.*pub struct`, `-.*pub enum`; or CHANGED_FILES includes API route definition files or GraphQL schema files |
| `migrations` | — | CHANGED_FILES includes paths containing `migration`, `schema`, `.sql`, `alembic`, `prisma`, or a dedicated `db/` directory |
| `silent-failures` | — | DIFF_CONTENT contains error-handling patterns: `try`, `catch`, `except`, `rescue`, `.catch(`, `handleError`, `onError`, `Result<`, `Err(` |
| `comments-params` | — | DIFF_CONTENT adds or removes comment lines (`+//`, `-//`, `+#`, `-#`, `+/*`, `-/*`, `+ *`, `- *`), or adds new function parameters, config flags, or env vars |
| `types` | — | DIFF_CONTENT contains type definition patterns: `interface `, `type .* =`, `dataclass`, `TypedDict`, `type .* struct`, `struct `, `enum ` (check for these on `+` diff lines — added type definitions) |

Spawn only the subagents whose condition is met. Write the skipped-subagents note on the line immediately after "Running deep review…" — this note precedes the output suppression window. Example: `(skipping: deps, migrations, types — not applicable to this diff)`. If no subagents are skipped, omit this note.

## Subagents

### context (code-explorer)
**subagent_type:** `code-explorer`
**Task:**
- Analyze this branch to understand the scope and purpose of changes
- Summarize what the branch is trying to accomplish in 1-3 sentences
- List the changed files grouped by concern (e.g., "API layer", "data model", "tests")
- Extract and list commit messages in order
- If a PR exists, capture the PR title, body, and any linked discussion
**Output:** branch summary paragraph, changed-file list grouped by concern, PR context paragraph (if applicable)

---

### deps (haiku)
**model:** `haiku`
**Task:**
- List every new package added and any version changes to existing packages
- Note if a package is dev-only vs runtime
**Output:** table of added/changed packages with old→new versions and dev/runtime classification

---

### breaking (code-architect)
**subagent_type:** `code-architect`
**Task:**
- Analyze this diff for backwards-compatibility issues
- Identify changes to public APIs, exported interfaces, function signatures, and schema definitions that are not backwards-compatible
- Flag removed or renamed exports, changed parameter types, and removed fields
- Note any implicit contracts (undocumented behavior callers may depend on) that changed
**Output:** list of breaking changes with file:line references and description of what breaks

---

### migrations (sonnet)
**model:** `sonnet`
**Task:**
- Find database migrations, schema changes, and data transformations
- Check whether each migration is backwards-compatible (old code can run against new schema and vice versa)
- Flag irreversible migrations or missing rollback paths
**Output:** list of migrations with compatibility assessment and any rollback concerns

---

### tests (tests-analyzer)
**subagent_type:** `tests-analyzer`
**Task:**
- For each changed component or code path, identify whether tests exist that cover the change
- Flag missing unit tests, integration tests, and edge case coverage
- Note if existing tests were deleted without replacement
**Output:** per-component coverage assessment with specific gaps called out at file:line, rated by criticality

---

### redundancy (code-simplifier)
**subagent_type:** `code-simplifier`
**Task:** Analysis only — do not apply any changes.
- Find code that duplicates existing functionality elsewhere in the diff or codebase
- Identify dead code, unreachable branches, and unused variables introduced by this diff
- Flag old code paths that are logically superseded by a new path (e.g., old endpoint) but are neither removed nor marked deprecated
**Output:** list of redundant/dead/stale code with file:line and description

---

### logic-and-conventions (code-reviewer)
**subagent_type:** `code-reviewer`
**Task:**
- Find edge cases not handled (off-by-one, null/empty inputs, concurrency, overflow, race conditions)
- Identify outright bugs: wrong operator, incorrect conditional, missing await, etc.
- Check adherence to conventions already established in the codebase: testing framework, assertion style, file naming, import style, error handling patterns
- If a bug or edge case is in dead, unreachable, or unused code, note that explicitly and do NOT escalate its severity
- Only report issues with confidence ≥ 80
**Output:** grouped list of logic issues and convention violations with file:line, confidence score, severity, and suggested fix

---

### comments-params (comment-analyzer)
**subagent_type:** `comment-analyzer`
**Task:**
- Flag removed comments that captured information not obvious from the code alone (hidden constraints, workarounds, subtle invariants)
- Flag new parameters, config values, or flags that lack documentation when the information is non-obvious
- For every newly introduced parameter, config value, or flag: validate the name and value are correct against source type definitions or official documentation. Never assume validity without evidence.
**Output:** list of documentation gaps and param validation findings with file:line

---

### silent-failures (silent-failure-hunter)
**subagent_type:** `silent-failure-hunter`
**Task:**
- Identify catch blocks that swallow errors without logging or user feedback
- Flag fallback logic that masks underlying problems
- Check that every error path surfaces actionable information to the user or logs sufficient context for debugging
**Output:** list of silent failure risks with file:line, severity (CRITICAL/HIGH/MEDIUM), and recommended fix

---

### types (type-design-analyzer)
**subagent_type:** `type-design-analyzer`
**Task:**
- Analyze new or modified types introduced in this diff
- Identify whether illegal states can be constructed — look for types where invalid combinations of fields are possible or constructors that skip validation
- Flag mutable internals exposed externally and missing construction-time validation
- Note anemic types with no behavior and types with too many responsibilities
**Output:** per-type analysis with encapsulation/invariant ratings, concerns, and recommended improvements

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

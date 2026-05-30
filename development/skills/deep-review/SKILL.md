---
name: deep-review
description: Performs deep branch and PR reviews with subagent-first analysis, including breaking changes, migration compatibility, testing coverage gaps, redundant changes, dependency additions, and logic edge cases. Use when the user asks for /deep-review or requests a comprehensive code review before merge.
disable-model-invocation: true
---

# Deep Review

## Instructions

Spawn all subagents defined below in a single message so they run concurrently. Collect all results, then synthesize the final review. If a PR exists, pass PR title/body/discussion into relevant subagents. If no PR exists, proceed with branch-only review and note that limitation in the summary.

## Execution Rules

- **Subagent types:** For every subagent that has a `subagent_type` field, you MUST pass that exact value as the `subagent_type` parameter to the Agent tool. Never spawn a general-purpose agent when a `subagent_type` is specified — this is a correctness requirement.
- **Model parameter:** Named agents (`subagent_type` specified) define their own model — do not pass a `model` parameter. General-purpose agents (no `subagent_type`) MUST have an explicit `model` parameter. Omitting model on a general-purpose call is a bug.
- **Task tracking:** Before spawning any subagent, create one task per **applicable** subagent (after triage) using TaskCreate. Mark all tasks `in_progress` when spawning. As each background agent returns, mark its task `completed`. This renders a live-updating checklist in the UI.
- **Parallelism:** Spawn ALL subagents in a single message. Do NOT wait for one to finish before launching the next. Use `run_in_background: true` for every subagent.
- **Triage (before spawning):** Collect `CHANGED_FILES` and `DIFF_CONTENT` via `git diff` (see Triage section below). Evaluate the rule table to determine which subagents to spawn. Then spawn only the applicable set — all in a single message with `run_in_background: true`.
- **Output suppression:** Write `Running deep review…` before spawning (after triage is complete), then optionally a skipped-subagents note if applicable (see Triage section). Write nothing else until all subagents have returned.
- **Final output:** Prioritize findings by severity with concrete file/symbol references. You (the orchestrator) are the final authority on severity — apply the **Severity Rubric** below to every finding during synthesis, downgrading subagent-proposed severities wherever a cap applies. Subagents propose; you decide.

## Triage

Collect diff data before spawning anything:

```bash
git fetch origin ${BASE_BRANCH:-main} --quiet
BASE_COMMIT=$(git merge-base HEAD origin/${BASE_BRANCH:-main})
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
| `comments-params` | — | DIFF_CONTENT adds or removes comment lines (`+//`, `-//`, `+#`, `-#`, `+/*`, `-/*`, `+ *`, `- *`, `+"""`, `-"""`, `+'''`, `-'''`), or adds new function parameters, config flags, or env vars |
| `types` | — | DIFF_CONTENT contains type definition patterns: `interface `, `type .* =`, `dataclass`, `TypedDict`, `type .* struct`, `struct `, `enum ` (check for these on `+` diff lines — added type definitions) |

Spawn only the subagents whose condition is met. Write the skipped-subagents note on the line immediately after "Running deep review…" (before the output suppression window begins). Example: `(skipping: deps, migrations, types — not applicable to this diff)`. If no subagents are skipped, omit this note.

## Subagents

**Every finding from every subagent MUST be tagged with the three attributes the Severity Rubric needs, so the orchestrator can apply caps:**
- **Origin:** `introduced` (the diff added or modified the responsible line(s), within `BASE_COMMIT..HEAD`) or `pre-existing` (the responsible code is unchanged by this diff — outside the `+`/`-` hunks and its behavior is not altered by surrounding changes).
- **Reach:** `common-path` (hit by default/typical usage) or `narrow` (only reachable via a specific/unlikely input, rare state, or uncommon configuration).
- **Kind:** `bug` (provably incorrect behavior) or `suggestion` (style, naming, preference, optional refactor, "consider…").

If a subagent cannot determine an attribute with evidence, it must say so and mark the finding `unverified`.

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
**Task:** Focus on changed components and code paths in this diff. Note if existing tests were deleted without replacement.

---

### redundancy (code-simplifier)
**subagent_type:** `code-simplifier`
**Task:** Analysis only — do not apply any changes.
- Find code that duplicates existing functionality elsewhere in the diff or codebase
- Identify dead code, unreachable branches, and unused variables introduced by this diff
- Flag old code paths that are logically superseded by a new path (e.g., old endpoint) but are neither removed nor marked deprecated
- Flag **incomplete parallel changes**: a change applied to one of several duplicate or sibling code paths but missed in its twins — e.g. a fix made in one handler but not in an identical sibling handler, or logic updated for one entity/platform but not the others that do the same thing. Search the codebase for siblings of each changed function/branch, not just the diff.
**Output:** list of redundant/dead/stale code with file:line and description, including any sibling paths that should have changed but did not

---

### logic-and-conventions (code-reviewer)
**subagent_type:** `code-reviewer`
**Task:**
- Specialist agents are running alongside you in this review (tests, silent-failures, comments, types). Defer those lanes to them — focus only on the items below.
- Find edge cases not handled (off-by-one, null/empty inputs, concurrency, overflow, race conditions). For each, state whether the trigger is `common-path` or `narrow`.
- Identify outright bugs: wrong operator, incorrect conditional, missing await, etc. Distinguish a real `bug` from a `suggestion` (style/preference/optional refactor).
- For every finding, determine Origin (`introduced` vs `pre-existing`) against `BASE_COMMIT..HEAD` — do not propose `[high]`/`[critical]` for `pre-existing` code, narrow edge cases, suggestions, or dead/unreachable code (per the Severity Rubric).
**Output:** grouped list of logic issues and convention violations with file:line, confidence score, the Origin/Reach/Kind attributes, proposed severity, and suggested fix

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
**Task:** Focus only on error-handling code added or changed in this diff.

---

### types (type-design-analyzer)
**subagent_type:** `type-design-analyzer`
**Task:** Analyze only types introduced or modified in this diff.

---

## Severity Rubric

Apply this during synthesis to **every** finding. Subagents propose a severity; you normalize it here. When multiple caps apply, take the **lowest** resulting severity.

### Severity definitions

- **`[critical]`** — A `bug` **`introduced`** by this branch on a **`common-path`** that breaks core functionality, corrupts/loses data, opens a security hole, or breaks a public contract.
- **`[high]`** — A `bug` **`introduced`** by this branch on a **`common-path`** with clear user/system impact and concrete evidence from the diff, but short of critical.
- **`[medium]`** — A real, `introduced` issue with limited blast radius: `narrow` edge cases, missing tests, deprecated-but-unremoved paths, removed context comments, doc gaps.
- **`[low]`** — Suggestions, style, naming, minor redundancy, new packages, informational notes, and anything capped below.

### Mandatory caps (override any subagent-proposed severity)

A finding qualifies for `[high]` or `[critical]` **only if it is `introduced` AND `common-path` AND `kind: bug`.** Apply these caps in order:

1. **Pre-existing → `[low]`.** Any finding whose responsible code is `pre-existing` (not introduced or worsened by this diff) is capped at `[low]` and labeled `(pre-existing)`. Exception: if the diff measurably *worsens* a pre-existing issue (e.g., widens its reach or adds a new caller), treat the worsening delta as `introduced` and rate that on its own merits.
2. **Narrow edge case → `[medium]`.** A `bug` reachable only via a `narrow` trigger is capped at `[medium]`. It may exceed `[medium]` **only** when the impact is severe (data loss, corruption, or security) *and* the trigger is plausible in normal operation — state both justifications explicitly if you escalate.
3. **Suggestion → `[low]`.** Anything with `kind: suggestion` (style, naming, preference, optional refactor, "consider…") is capped at `[low]`, regardless of how confidently it is argued.
4. **Unused/dead code → `[low]`.** Any finding (bug, logic error, missing test, etc.) in code identified as dead, unreachable, or unused is capped at `[low]`. Never mark errors in unused code `[high]`/`[critical]`.
5. **Unverified → `[medium]`.** A finding lacking concrete evidence from the diff/commits/tests, or missing an Origin/Reach/Kind attribute, is capped at `[medium]` and labeled `(unverified)`. Do not promote a guess to `[high]`.

When you downgrade a finding via a cap, keep it in the report at its capped severity with the label — do not silently drop it.

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

**Purpose:** <1-2 sentences: what this branch/PR is trying to accomplish and why.>

**Merge readiness:** Ready / Needs fixes / Blocked

- <key finding or required action 1>
- <key finding or required action 2>
```

## Quality Bar

- Do not claim certainty without evidence from diffs, commits, or tests.
- Flag assumptions explicitly.
- Omit sections with nothing to report — a short, dense review is better than a padded one.

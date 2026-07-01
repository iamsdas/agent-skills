---
name: deep-review
description: Performs deep branch and PR reviews with subagent-first analysis, including breaking changes, migration compatibility, testing coverage gaps, redundant changes, dependency additions, and logic edge cases. Use when the user asks for /deep-review or requests a comprehensive code review before merge.
disable-model-invocation: true
---

# Deep Review

## Instructions

Spawn all subagents defined below in a single message so they run concurrently. Collect all results, run the **Verification** pass to refute false positives, then synthesize the final review. If a PR exists, pass PR title/body/discussion into relevant subagents. If no PR exists, proceed with branch-only review and note that limitation in the summary.

## Execution Rules

- **Subagent types:** For every subagent that has a `subagent_type` field, you MUST pass that exact value as the `subagent_type` parameter to the Agent tool. Never spawn a general-purpose agent when a `subagent_type` is specified — this is a correctness requirement.
- **Model parameter:** Named agents (`subagent_type` specified) define their own model — do not pass a `model` parameter. General-purpose agents (no `subagent_type`) MUST have an explicit `model` parameter. Omitting model on a general-purpose call is a bug.
- **Task tracking:** Before spawning any subagent, create one task per **applicable** subagent (after triage) using TaskCreate, plus one `verification` task for the refute pass. Mark all finder tasks `in_progress` when spawning. As each background agent returns, mark its task `completed`. This renders a live-updating checklist in the UI. These tasks are scaffolding for this skill only — once the final review is delivered (or the review is abandoned), delete every task it created via TaskUpdate with status `deleted`, so the checklist doesn't linger and absorb later, unrelated work.
- **Parallelism:** Spawn ALL subagents in a single message. Do NOT wait for one to finish before launching the next. Use `run_in_background: true` for every subagent.
- **Triage (before spawning):** Collect `CHANGED_FILES` and `DIFF_CONTENT` via `git diff` (see Triage section below). Evaluate the rule table to determine which subagents to spawn. Then spawn only the applicable set — all in a single message with `run_in_background: true`.
- **Two waves:** The finder subagents are wave one. After they all return, run the **Verification** wave (see below) — one adversarial verifier per qualifying finding, again all in a single message with `run_in_background: true`. Synthesis happens only after the verification wave returns.
- **Output suppression:** Write `Running deep review…` before spawning (after triage is complete), then optionally a skipped-subagents note if applicable (see Triage section). Write nothing else until the finder wave AND the verification wave have both returned.
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

**External-artifact existence claims MUST be fact-checked online before being reported.** Any claim that a version, package, GitHub Action, API, library function, or config option "does not exist", "is not released", "is not a real version", or "is not available" is unreliable from model knowledge alone — training cutoffs make newer releases invisible. Before reporting such a finding, the subagent MUST verify it against the authoritative source via WebSearch/WebFetch (e.g. the action's GitHub releases/tags page, the npm/PyPI/crates registry, official docs/changelog). Include the checked URL as evidence. If online verification is unavailable, the claim MUST be marked `unverified` — never assert non-existence from memory.

### context (development:code-explorer)
**subagent_type:** `development:code-explorer`
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

### breaking (development:code-architect)
**subagent_type:** `development:code-architect`
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

### tests (development:tests-analyzer)
**subagent_type:** `development:tests-analyzer`
**Task:** Focus on changed components and code paths in this diff. Note if existing tests were deleted without replacement.

---

### redundancy (development:code-simplifier)
**subagent_type:** `development:code-simplifier`
**Task:** Analysis only — do not apply any changes.
- Find code that duplicates existing functionality elsewhere in the diff or codebase
- Identify dead code, unreachable branches, and unused variables introduced by this diff
- Flag old code paths that are logically superseded by a new path (e.g., old endpoint) but are neither removed nor marked deprecated
- Flag **incomplete parallel changes**: a change applied to one of several duplicate or sibling code paths but missed in its twins — e.g. a fix made in one handler but not in an identical sibling handler, or logic updated for one entity/platform but not the others that do the same thing. Search the codebase for siblings of each changed function/branch, not just the diff.
**Output:** list of redundant/dead/stale code with file:line and description, including any sibling paths that should have changed but did not

---

### logic-and-conventions (development:code-reviewer)
**subagent_type:** `development:code-reviewer`
**Task:**
- Specialist agents are running alongside you in this review (tests, silent-failures, comments, types). Defer those lanes to them — focus only on the items below.
- Find edge cases not handled (off-by-one, null/empty inputs, concurrency, overflow, race conditions). For each, state whether the trigger is `common-path` or `narrow`.
- Identify outright bugs: wrong operator, incorrect conditional, missing await, etc. Distinguish a real `bug` from a `suggestion` (style/preference/optional refactor).
- For every finding, determine Origin (`introduced` vs `pre-existing`) against `BASE_COMMIT..HEAD` — do not propose `[high]`/`[critical]` for `pre-existing` code, narrow edge cases, suggestions, or dead/unreachable code (per the Severity Rubric).
- If you believe a referenced external artifact (GitHub Action version, package version, API, function) does not exist, you MUST verify online (WebSearch/WebFetch against the releases page or registry) before reporting it, citing the URL — your training data is stale relative to recent releases. No online check → mark `unverified`, never assert non-existence.
**Output:** grouped list of logic issues and convention violations with file:line, confidence score, the Origin/Reach/Kind attributes, proposed severity, and suggested fix

---

### comments-params (development:comment-analyzer)
**subagent_type:** `development:comment-analyzer`
**Task:**
- Flag removed comments that captured information not obvious from the code alone (hidden constraints, workarounds, subtle invariants)
- Flag new parameters, config values, or flags that lack documentation when the information is non-obvious
- For every newly introduced parameter, config value, or flag: validate the name and value are correct against source type definitions or official documentation. Never assume validity without evidence.
**Output:** list of documentation gaps and param validation findings with file:line

---

### silent-failures (development:silent-failure-hunter)
**subagent_type:** `development:silent-failure-hunter`
**Task:** Focus only on error-handling code added or changed in this diff.

---

### types (development:type-design-analyzer)
**subagent_type:** `development:type-design-analyzer`
**Task:** Analyze only types introduced or modified in this diff.

---

## Verification

After every finder subagent returns and **before** synthesis, run an adversarial verification pass. Its purpose is to **kill false positives**: each verifier tries to *refute* its finding, not confirm it. An unrefuted finding earns its place in the report; a refuted one is dropped. This is deep-review's precision mechanism — finders optimize for recall, verification claws back precision.

**What to verify.** Every finding tagged `kind: bug` (any severity), plus every finding proposed at `[medium]` or above. Skip only `kind: suggestion` findings capped at `[low]` (style, naming, preference — there is no truth-value to refute).

**How.** Spawn one verifier per qualifying finding, **all in a single message** with `run_in_background: true` (same discipline as the finder wave). Each verifier is a general-purpose agent — no `subagent_type`, so it MUST be passed an explicit `model: sonnet` (per the Execution Rules). Give it **only** the finding: the claim, `file:line`, proposed severity, and the finder's stated reasoning/evidence. The finder's reasoning is a claim to be tested, **not** trusted. Instruct each verifier to:

- Independently open the cited code and the diff — pass it the resolved base SHA in its prompt (the `BASE_COMMIT` from Triage), or have it recompute `git merge-base HEAD origin/${BASE_BRANCH:-main}` itself, then `git diff <base>..HEAD` — and try to prove the finding **wrong**: Is the flagged code actually reached on the described path? Is it actually incorrect? Was it actually `introduced` by this diff (vs. `pre-existing`)? Look for the guard, prior validation, caller contract, or existing test the finder may have missed.
- Fact-check any external-artifact non-existence claim online (per the rule above) before accepting it — a "version/package/API does not exist" claim with no cited verification URL is refuted by default.
- Return a verdict with concrete evidence (`file:line` or URL):
  - **`CONFIRMED`** — the code concretely exhibits the problem; cite the proof.
  - **`REFUTED`** — the code does not exhibit it (a guard exists, the path is unreachable, the claim rests on a misread, or the artifact exists); cite what disproves it.
  - **`UNCERTAIN`** — cannot determine from available evidence.

**Applying verdicts at synthesis:**

- **`REFUTED` → drop.** Do not report the finding. Tally the drop count for the Summary.
- **`CONFIRMED` → keep** and apply the Severity Rubric normally.
- **`UNCERTAIN` → keep but treat as `unverified`:** capped at `[medium]` and labeled `(unverified)` per rubric cap 5.

Findings never eligible for verification (`[low]` suggestions) carry through unchanged.

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
6. **Unverified non-existence claim → verify or cap at `[low]`.** A finding asserting an external artifact (action/package/API version) "does not exist" without a cited verification URL is a likely training-cutoff hallucination. Verify it yourself with WebSearch/WebFetch during synthesis: if the artifact exists, drop the finding; if you cannot verify, cap at `[low]` and label `(unverified — possible stale model knowledge)`.

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

<If the verification pass refuted any findings, add one line: "Verification refuted and dropped N candidate finding(s)." Omit if none were dropped.>
```

## Quality Bar

- Do not claim certainty without evidence from diffs, commits, or tests.
- Flag assumptions explicitly.
- Omit sections with nothing to report — a short, dense review is better than a padded one.

## After the Review

When the review surfaces a `[critical]` or `[high]` bug that was `introduced` on this branch — a defect the build/test process should have caught — invoke the `preventing-recurrence` sub-skill once findings are fixed. It routes the lesson into a durable mechanism (caught *at review* → shift the fix one phase up: build/TDD discipline, a new review lane, or a hook if the defect is script-detectable) so the class doesn't slip past build again.

---
name: deep-review
description: Performs deep branch and PR reviews with subagent-first analysis, including breaking changes, migration compatibility, testing coverage gaps, redundant changes, dependency additions, and logic edge cases. Use when the user asks for /deep-review or requests a comprehensive code review before merge.
disable-model-invocation: true
---

# Deep Review

## Instructions

Follow this workflow whenever the skill is invoked:

1. Try using subagents for individual tasks as much as possible.
2. Get context from the current branch and summarize changes being done. Also check commit messages of the branch compared to `main` and PR info for extra context.
3. Check for any breaking changes.
4. Check for any migrations done while keeping backwards compatibility.
5. Consolidate testing information for each part of code being changed and flag missing test cases.
6. Check for redundant code changes (duplicates/already existing stuff).
7. Check for dead code and stale paths that should be removed.
8. If a new code path logically replaces an older path (for example, an endpoint), flag when the old path is neither removed nor marked as deprecated.
9. Note new packages being added, if any.
10. Find edge cases or bugs in logic.
11. Check if any context comments were removed without a clear reason or if parameters/arguments lack documentation when added or updated. Flag cases where removed comments captured information not obvious from the code alone, and flag missing documentation on parameter additions or updates.
12. For any parameter, config value, or flag that is newly introduced in this diff, validate that the name and value are correct — check source code (type definitions, compiler errors) or look up official documentation (search online if necessary). Never assume a new parameter is valid without evidence.
13. Summarize with a final review.

## Execution Pattern

**Model selection:**
- Use `haiku` for exploratory/data-gathering subagents (branch context, dependency delta, file listings, git log, PR info)
- Use `sonnet` for analysis subagents that require judgment (breaking changes, migration compatibility, test coverage, redundancy/dead-code, logic bugs, comment/param validation)

**Parallelism:**
- Spawn ALL subagents in a single message so they run concurrently. Do NOT wait for one to finish before launching the next.
- Run data-gathering agents first (haiku) and pass their output into analysis agents (sonnet) only when there is a true dependency. If analysis can proceed from the diff alone, launch it immediately in parallel with the exploratory agents.
- Use `run_in_background: true` for every subagent. Collect all results before synthesizing the final review.

**Output suppression:**
- Do NOT narrate subagent launches, progress, or individual completions. No "Launching breaking-change agent…", no "context agent returned…".
- Write exactly one text line before spawning: `Running deep review…`
- Write nothing else until all subagents have returned. Then output the final review directly.

**Subagent prompt style:**
- Write all subagent prompts in caveman mode: drop articles, filler, pleasantries, hedging. Fragments OK. Technical substance stays exact.
- Final review output to the user is normal prose — caveman applies only to inter-agent communication.

**Subagent split:**

| Subagent | Model | Task |
|---|---|---|
| context | haiku | Branch name, commit messages vs main, PR title/body/discussion |
| deps | haiku | New packages added, version changes |
| breaking | sonnet | Breaking API/schema/interface changes |
| migrations | sonnet | Migration compatibility and backwards compatibility |
| tests | sonnet | Test coverage gaps per changed component |
| redundancy | sonnet | Duplicate code, dead code, stale paths, unreachable branches |
| logic | sonnet | Edge cases, bugs, logic errors |
| comments-params | sonnet | Removed context comments, undocumented new params/configs/flags, param name/value validation |

- If a PR exists, include PR title/body/discussion context in the review input.
- If no PR exists, proceed with branch-only review and explicitly note that limitation.
- Prioritize findings by severity and include concrete file/symbol references.
- Prefer actionable findings over stylistic comments.

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

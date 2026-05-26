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
11. Summarize with a final review.

## Execution Pattern

- Split analysis into focused subagent tasks where possible:
  - Branch and PR context
  - API/schema/breaking-change risk
  - Migration and compatibility checks
  - Test coverage analysis by changed component
  - Redundancy, dead-code, and logic bug scan
  - Dependency delta review
- If a PR exists, include PR title/body/discussion context in the review input.
- If no PR exists, proceed with branch-only review and explicitly note that limitation.
- Prioritize findings by severity and include concrete file/symbol references.
- Prefer actionable findings over stylistic comments.

## Required Output Format

Use this structure:

```markdown
## Findings
- [Severity] Finding with impact and location

## Breaking Changes
- None found / list with affected consumers

## Migrations and Backward Compatibility
- Migration summary + compatibility verdict

## Testing Coverage
- Changed area -> existing tests -> missing tests

## Redundant or Duplicate Changes
- None found / list of overlaps

## Dead Code and Replacement Paths
- None found / list dead code
- For replacement paths, confirm old path is removed or explicitly deprecated

## New Packages
- None added / package + reason + risk note

## Logic Edge Cases and Bugs
- None found / list with reproduction idea

## Final Review Summary
- Merge readiness and required follow-ups
```

## Quality Bar

- Do not claim certainty without evidence from diffs, commits, or tests.
- Flag assumptions explicitly.
- If there are no issues, say so clearly and still report residual risk and test gaps.

---
name: modernizing-pull-requests
description: Use when an old or stale pull request needs bringing up to date - the user asks to rebase, refresh, revive, or "modernize" a PR, or a PR has fallen far behind its base branch and may have been superseded.
---

# Modernizing Pull Requests

## Overview

Modernize the idea, not just the branch. A clean rebase does not prove the PR still belongs in the product: the problem may already be solved, or the code it changes may be gone.

**Core principle:** Establish what the PR was for, look at what changed around it, and decide **MODERNIZE**, **REWORK**, or **CLOSE** *before* pushing anything.

**Announce at start:** "I'm using the modernizing-pull-requests skill to bring this PR up to date."

## Guardrails

- Fetch the latest base branch, the PR head, and any related branch before starting.
- Treat uncommitted changes in the current worktree as the user's. Work in a disposable worktree (`using-git-worktrees`) when the active one is dirty or in use.
- Modernizing authorizes rebasing and updating the PR branch. It does **not** authorize merging, closing, changing the base branch, or expanding scope.
- Never use a bare force push. Push with `--force-with-lease=<branch>:<sha>`, where `<sha>` is the remote head you recorded before rebasing.
- Do not post a PR comment unless the user asked for one.

## 1. Establish the PR's Intent

Resolve the PR and record its URL, state, base, head repo and branch, head SHA, author, checks, and review state. Read the title, body, linked issues, commits, review threads, and the complete diff. State the smallest coherent goal the PR was trying to reach before judging how it gets there.

Use the PR's actual base branch, not an assumed `main`. Record the merge base so the PR's own changes and the base's later changes can be compared separately.

## 2. Check What Changed Around It

Inspect commits on the base since the merge base (`git log <merge-base>..origin/<base> -- <files the PR touches>`). Search merged and open PRs when titles, code paths, or behavior suggest a replacement or competing implementation.

Look beyond overlapping lines:

- Has the same user-facing problem already been solved?
- Did APIs, types, schemas, dependencies, or architectural boundaries change?
- Do both sides now claim ownership of the same behavior or invariant?
- Was the code being changed deleted, moved, or deliberately simplified?
- Would landing the PR bring back old behavior, or create two ways to do the same thing?
- Is the original benefit still worth its maintenance cost?

A PR is not current just because Git reports no conflicts.

## 3. Choose a Disposition Before Pushing

| Disposition | When | Action |
|---|---|---|
| **MODERNIZE** | Goal still useful, implementation still the right shape | Rebase, resolve, test, push (step 4) |
| **REWORK** | Goal still useful, but a mechanical rebase would keep the wrong implementation | Describe the smallest credible rewrite and stop, unless the user also asked for the rework |
| **CLOSE** | Superseded, obsolete, directionally wrong, or no longer worth it | Cite concrete evidence and stop. Don't rebase it, and don't close it without explicit permission |

Be willing to recommend CLOSE. Age alone is not evidence, and sunk effort is not a reason to keep a PR alive.

## 4. Rebase Without Losing Intent

For MODERNIZE:

1. Create a local branch or disposable worktree at the recorded PR head.
2. Rebase its commits onto the freshly fetched base.
3. Resolve each conflict by the PR's intent *and* the base's newer invariants. If a conflict exposes a product or architecture disagreement, stop and reconsider the disposition rather than guessing.
4. Compare the commit series before and after the rebase with `git range-diff <old-base>..<old-head> <new-base>..HEAD`, then read the final diff. Confirm that no intended behavior disappeared and no behavior that already landed on the base came back.
5. Run the repo's focused checks for the touched area. Tell real failures apart from pre-existing or infrastructure ones.
6. Push with `--force-with-lease` tied to the recorded head. If the lease fails, someone pushed in the meantime: fetch and reassess, never overwrite.

Do not merge the PR. If the user wants it watched through CI afterwards, continue with `babysitting-pull-requests`.

## Report

Lead with **MODERNIZE**, **REWORK**, or **CLOSE** and the reason. Then:

- meaningful changes on the base branch;
- conceptual conflicts, or confirmation that none were found;
- the rebase and push result, if performed;
- checks run and their results;
- the remaining decision or work, with the PR link.

Separate what you observed from what you judged. Say what could not be verified rather than projecting confidence.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Rebasing first, deciding later | Pick the disposition before any push |
| "No conflicts, so it's current" | Check for conceptual overlap: solved elsewhere, moved code, changed invariants |
| Resolving conflicts by taking the PR's side | Honor the base's newer invariants too; stop on real disagreements |
| Skipping `range-diff` | It is the only check that intent survived the rebase |
| Plain `--force` | `--force-with-lease` against the recorded head |
| Closing an obsolete PR yourself | Recommend CLOSE; the user closes it |

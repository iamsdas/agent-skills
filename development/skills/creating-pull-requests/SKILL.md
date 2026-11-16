---
name: creating-pull-requests
description: Use when opening a pull request, pushing a branch for review, or running `gh pr create` - ensures the PR body has a summary, a visual section with a mermaid diagram of the changes, a usage guide, and a test plan
---

# Creating Pull Requests

## Overview

A PR is read far more often than it is written. Every PR in this repo ships with the same four sections so reviewers can orient fast: **Summary**, **Visuals** (mermaid diagram of what changed), **Usage**, and **Test Plan**.

**Core principle:** Inspect the diff → draft all four sections → embed a mermaid diagram → push → open PR with the full body.

**Announce at start:** "I'm using the creating-pull-requests skill to open this PR."

## The Process

### Step 1: Gather Diff Context

```bash
gh pr view --json url,state 2>/dev/null   # a PR for this branch already? update it with `gh pr edit`, don't open a second
BASE=${BASE:-main}
git fetch origin $BASE --quiet
git log --oneline origin/$BASE..HEAD
git diff --stat origin/$BASE..HEAD
git diff origin/$BASE..HEAD
```

Read the actual diff — do not infer the PR contents from the branch name or commit subjects alone.

### Step 2: Verify Tests Pass

Run the project's test suite. If tests fail, fix them or call it out explicitly in the Test Plan as a known gap. Never imply a PR is verified when it isn't.

### Step 3: Draft the Body

Fill the template below. Every section is required — if one genuinely doesn't apply, keep the header and write one line explaining why (e.g. "No user-facing change").

**Title.** Titles usually become commit messages, so follow the repo's convention (check `gh pr list --state merged --limit 10` and `git log`). Within that convention, say why the change matters, not which mechanism it touches:

> ❌ `perf(server): negotiate permessage-deflate on the websocket`
> ✅ `perf(server): cut websocket frame size by 70%+ with gzipping`

**Summary opens with the problem.** Start with what was wrong, in the terms the user used when asking, then the fix. Never lead with an inventory of what was renamed, deleted, or moved:

> ❌ Removed implicit workspace carry-over from every "new thread" entry point (cmd+n, sidebar buttons, command palette). Deleted buildContextualThreadOptions and the seed-context machinery.
> ✅ My "new worktree" default was ignored when starting threads on existing worktrees. Now the configured default always applies.

Before submitting, check the title, body, and any quoted output or screenshots for secrets and private details.

### Step 4: Build the Mermaid Diagram

The Visuals section MUST contain a mermaid diagram (GitHub renders ```mermaid fenced blocks natively — no image upload needed). Pick the diagram type that matches the change:

| Change type | Diagram |
|---|---|
| New/changed control flow, request lifecycle | `flowchart` |
| Sequence of calls between components/services | `sequenceDiagram` |
| Data model / schema / type relationships | `erDiagram` or `classDiagram` |
| State machine, status transitions | `stateDiagram-v2` |

Diagram the **delta** — what this PR adds or rewires — not the entire system. If the change is purely textual (docs, config) and has no flow worth drawing, replace the diagram with a screenshot placeholder and say so.

**The Visuals section is a glance, not documentation.** Its job is to orient a reviewer in a few seconds, not to reconstruct every decision in the PR. A wall of large or deep diagrams overwhelms the reader as badly as no diagram at all. Keep it small, and enforce these:

- **Keep it shallow — 5 levels deep, max.** Count the longest chain of nodes from an entry point to a leaf. If it exceeds ~5, the diagram has stopped being a glance. Trim to the essential hops, or lift a sub-flow into prose/a table. Do not chase completeness in the diagram.
- **One diagram. Two is already a lot.** Default to a *single* diagram of the most important delta — that is almost always enough. A second is a rare exception, justified only by a genuine before/after pair. If the PR touches several independent concerns, do NOT draw one diagram per concern — pick the one flow most worth seeing and let the Summary bullets and tables carry the rest.
- **One idea per diagram.** Do NOT place two or more subgraphs at the same level (e.g. a `before` and an `after` box) — sibling subgraphs render side-by-side and blow out the width. Split a before/after comparison into **separate** ```mermaid blocks, one per code fence, each with its own heading.
- **Grow down, not across.** Prefer top-down orientation (`flowchart TD`, `stateDiagram-v2`) over `LR`. Vertical growth scrolls naturally; horizontal growth does not.
- **Short node labels.** Keep each node to a few words. Push detail (full URLs, env-var values, error strings, port numbers) into the surrounding prose or bullets, not into the node. Long labels — especially with `<br/>` lines — set the minimum width of the whole diagram.
- **Cap the fan-out.** More than ~4-5 sibling nodes on one row overflows; break wide branches into a second diagram or a nested vertical chain.

If the delta genuinely needs a before *and* after view, use two consecutive diagrams:

```markdown
**Before**
​```mermaid
flowchart TD
    ...
​```

**After**
​```mermaid
flowchart TD
    ...
​```
```

### Step 5: Push and Open

```bash
git push -u origin HEAD
gh pr create --title "<concise title>" --body-file <path-to-body.md>
```

Write the body to a file first (mermaid + checklists survive cleanly through `--body-file`; heredocs mangle backticks). Use the scratchpad directory for the body file.

If `gh pr create` fails because the GraphQL rate limit is used up, open it through REST, which has its own limit:

```bash
gh api repos/<owner>/<repo>/pulls -f title="<title>" -f head=<branch> -f base=$BASE -F body=@<path-to-body.md>
```

If the user asked for the PR to be watched through CI and review, continue with `babysitting-pull-requests`.

## PR Body Template

```markdown
## Summary

<Open with the problem in one or two plain sentences, then the fix. Optional 2-4 bullets for detail. Impact first, never the file list.>

## Visuals

<Mermaid diagram of the change. For UI changes, also add a screenshot:
"![description](paste-image-url)".>

​```mermaid
flowchart TD
    A[Request] --> B{New guard}
    B -->|valid| C[Handler]
    B -->|invalid| D[401]
​```

## Usage

<How to use the new behavior: API call, command, code snippet, or UI steps.
If nothing new is user-invocable, say so.>

## Test Plan

- [ ] <Automated tests added/updated — name them>
- [ ] <Manual verification steps a reviewer can reproduce>
- [ ] <Edge cases / regressions checked>
```

## Quick Reference

| Section | Must contain |
|---|---|
| Title | Repo convention, says why it matters |
| Summary | Problem first, then the fix; impact over file list |
| Visuals | A mermaid diagram of the delta (+ screenshot for UI) |
| Usage | Concrete invocation or "not user-invocable" |
| Test Plan | Checklist of automated + manual verification |

## Common Mistakes

- **Empty or omitted sections** — keep all four headers; explain inapplicability rather than deleting.
- **Diagramming the whole system** — show only what this PR changes.
- **Overflowing the width** — side-by-side subgraphs, `LR` orientation, or long node labels force a horizontal scrollbar. Split into separate top-down diagrams with short labels.
- **Overwhelming with depth or count** — a diagram deeper than ~5 levels, or more than one diagram, buries the signal. Default to a single shallow diagram (a second only for a real before/after); move the rest to prose and tables.
- **Summarizing commit messages** — describe impact, not a git log replay.
- **Leading with an inventory** — the first sentence names the problem, not the functions you deleted.
- **Mechanism titles** — "negotiate permessage-deflate" says what you touched; "cut frame size 70%" says why it matters.
- **Opening a second PR for the same branch** — check `gh pr view` first and edit the existing one.
- **Heredoc PR bodies** — backticks and mermaid fences break; use `--body-file`.
- **Claiming verified without running tests** — run them in Step 2 first.

## Red Flags

- About to run `gh pr create` without a mermaid diagram in the body → stop, add it.
- Diagram has two+ subgraphs side by side, uses `LR`, or crams URLs/env vars into node labels → it will overflow horizontally; split it into separate top-down diagrams first.
- Diagram runs more than ~5 levels deep, or the PR has two+ diagrams → you're overwhelming the reader; trim depth and cut down to a single diagram (keep a second only if it's a true before/after), prose covers the rest.
- Test Plan with no concrete steps → reviewers can't reproduce; write real steps.
- Body written from branch name instead of the actual diff → re-read the diff.

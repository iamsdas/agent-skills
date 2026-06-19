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

### Step 4: Build the Mermaid Diagram

The Visuals section MUST contain a mermaid diagram (GitHub renders ```mermaid fenced blocks natively — no image upload needed). Pick the diagram type that matches the change:

| Change type | Diagram |
|---|---|
| New/changed control flow, request lifecycle | `flowchart` |
| Sequence of calls between components/services | `sequenceDiagram` |
| Data model / schema / type relationships | `erDiagram` or `classDiagram` |
| State machine, status transitions | `stateDiagram-v2` |

Diagram the **delta** — what this PR adds or rewires — not the entire system. If the change is purely textual (docs, config) and has no flow worth drawing, replace the diagram with a screenshot placeholder and say so.

### Step 5: Push and Open

```bash
git push -u origin HEAD
gh pr create --title "<concise title>" --body-file <path-to-body.md>
```

Write the body to a file first (mermaid + checklists survive cleanly through `--body-file`; heredocs mangle backticks). Use the scratchpad directory for the body file.

## PR Body Template

```markdown
## Summary

<2-4 bullets: what changed and why. Lead with the user/system impact, not the file list.>

## Visuals

<Mermaid diagram of the change. For UI changes, also add a screenshot:
"![description](paste-image-url)".>

​```mermaid
flowchart LR
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
| Summary | What + why, impact-first bullets |
| Visuals | A mermaid diagram of the delta (+ screenshot for UI) |
| Usage | Concrete invocation or "not user-invocable" |
| Test Plan | Checklist of automated + manual verification |

## Common Mistakes

- **Empty or omitted sections** — keep all four headers; explain inapplicability rather than deleting.
- **Diagramming the whole system** — show only what this PR changes.
- **Summarizing commit messages** — describe impact, not a git log replay.
- **Heredoc PR bodies** — backticks and mermaid fences break; use `--body-file`.
- **Claiming verified without running tests** — run them in Step 2 first.

## Red Flags

- About to run `gh pr create` without a mermaid diagram in the body → stop, add it.
- Test Plan with no concrete steps → reviewers can't reproduce; write real steps.
- Body written from branch name instead of the actual diff → re-read the diff.

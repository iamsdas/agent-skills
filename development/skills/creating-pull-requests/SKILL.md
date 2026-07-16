---
name: creating-pull-requests
description: Use when opening a pull request, pushing a branch for review, or running `gh pr create` - ensures the PR body has a summary, a visuals section (a screenshot for UI-visible features and/or a mermaid diagram for architectural changes), a usage guide, and a test plan
---

# Creating Pull Requests

## Overview

A PR is read far more often than it is written. Every PR in this repo ships with the same four sections so reviewers can orient fast: **Summary**, **Visuals** (a screenshot for a UI-visible feature, a mermaid diagram for an architectural/decision change — often both), **Usage**, and **Test Plan**.

**Core principle:** Inspect the diff → draft all four sections → build the visuals (screenshot and/or mermaid) → push → open PR with the full body.

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

### Step 4: Build the Visuals

The Visuals section adapts to the change. There are two kinds of visual, and a PR may need both — a mermaid diagram alone is NOT enough for a UI feature.

**Screenshot — REQUIRED for a UI-visible feature.** If the change adds or alters a drivable visible surface (a web page, an app screen), the PR MUST show a screenshot of the feature actually running. (A backend/API/CLI-only change has no visible surface — skip the screenshot; the mermaid diagram or a "no user-facing UI" line covers it.)

1. **Capture** the feature running, saving the PNG to the scratchpad directory:
   - Prefer the **cmux browser** in a cmux workspace — drive to the feature and screenshot (see the `cmux-browser` skill).
   - Otherwise use an **agent browser** (drive a browser via whatever browser automation is available) to load the surface and capture.
   - Pick whichever is available; if neither is, say so in the section rather than faking it.
2. **Upload** to get a GitHub-hosted URL. `gh` cannot embed images natively (no public attachments API), so use the `gh-image` extension:
   ```bash
   gh extension install drogers0/gh-image        # once per machine
   url=$(gh image /path/to/screenshot.png)       # prints a github.com/user-attachments/assets/… URL
   ```
   `gh-image` authenticates via your browser's GitHub **session cookie** (a plain `gh auth` PAT will NOT work for the upload endpoint); if no cookie is available, supply the web-session token via `GH_SESSION_TOKEN`. Embed the URL in the body: `![feature](<url>)`.
   - **Fallback** if the upload genuinely can't run (no session cookie/token here): commit the PNG into the branch and reference its `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>` URL, and note the fallback (this URL breaks if the branch is deleted after merge).

**Mermaid diagram — for an architectural or decision change.** When the PR rewires control flow, call sequences, the data model, or a state machine, add a mermaid diagram of the **delta** (GitHub renders ```mermaid fenced blocks natively — no upload). Pick the type:

| Change type | Diagram |
|---|---|
| New/changed control flow, request lifecycle | `flowchart` |
| Sequence of calls between components/services | `sequenceDiagram` |
| Data model / schema / type relationships | `erDiagram` or `classDiagram` |
| State machine, status transitions | `stateDiagram-v2` |

Diagram the **delta**, not the whole system. A pure UI feature with no architectural change needs only the screenshot; a backend refactor needs only the diagram; a feature that adds UI *and* rewires flow needs both. A purely textual change (docs, config) with neither: keep the header and write "No visual — <reason>".

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

<UI-visible feature → REQUIRED screenshot: "![feature](https://github.com/user-attachments/assets/…)".
Architectural/decision change → mermaid diagram of the delta (below). Often both.>

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
| Visuals | Screenshot for a UI-visible feature (via cmux/agent browser + `gh image`); mermaid diagram of the delta for architectural changes; both when both apply |
| Usage | Concrete invocation or "not user-invocable" |
| Test Plan | Checklist of automated + manual verification |

## Common Mistakes

- **Empty or omitted sections** — keep all four headers; explain inapplicability rather than deleting.
- **A mermaid diagram standing in for a missing screenshot** — a UI-visible feature needs the actual screenshot; a diagram doesn't show the reviewer the feature.
- **Committing the PNG into the repo when the upload path works** — use `gh image` for a permanent `user-attachments` URL; the raw-URL commit is only the fallback.
- **Diagramming the whole system** — show only what this PR changes.
- **Summarizing commit messages** — describe impact, not a git log replay.
- **Heredoc PR bodies** — backticks and mermaid fences break; use `--body-file`.
- **Claiming verified without running tests** — run them in Step 2 first.

## Red Flags

- About to open a PR for a UI-visible feature with no screenshot → stop, capture and embed it.
- About to open a PR for an architectural/decision change with no mermaid diagram → stop, add it.
- Test Plan with no concrete steps → reviewers can't reproduce; write real steps.
- Body written from branch name instead of the actual diff → re-read the diff.

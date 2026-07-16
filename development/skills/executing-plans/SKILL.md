---
name: executing-plans
description: Use when you have an approved implementation plan to build, and you want it built hands-off through to an opened PR and review.
---

# Executing Plans

## Overview

Hand the approved plan to **one Opus builder subagent** that builds the whole thing, then open a PR and run review — pausing only before final integration. The plan (the self-contained HTML file from `writing-plans`) is a complete, self-sufficient handoff: the builder reads it and the codebase and builds every task without further input. This session stays the orchestrator — it dispatches, waits, opens the PR, and reviews. It does not build.

**Announce at start:** "I'm using the executing-plans skill to build this plan."

**Hands-off by default.** Once the plan is approved, the user does not want to babysit execution. Dispatch the builder, then open a PR and run review automatically. Stop only on a true blocker (see **When to Stop**) or at the single intended pause: after the PR is open and reviewed, before the work is landed.

## Process

### 1. Prepare

1. Confirm you have the approved plan file path (the `.html` from `writing-plans`).
2. Ensure an isolated workspace exists — invoke `using-git-worktrees` (creates one or verifies the existing one). **Never build on `main`/`master` without explicit user consent.**
3. Read the plan yourself once. Only a **true blocker** stops you here (a critical gap, a contradiction, a missing dependency the plan assumes) — raise those before dispatching. Note non-blocking observations in one line and proceed; the plan is approved.

### 2. Dispatch the Builder

Dispatch **one** subagent via the Agent tool with `model: "opus"` and `subagent_type: "general-purpose"`, running in the background. Give it exactly this job:

- Read the approved plan at `<path>` — it lists every task with exact file:line pointers, the pattern to follow, verification commands, and commit messages.
- Build the tasks **in order**, following TDD (test first, watch it fail, implement, watch it pass). Apply the same change to every parallel/sibling call site the plan lists in lockstep.
- Run each task's verification command; a task is done only when it passes.
- **Commit per task** using the plan's commit message. Do not squash tasks into one commit.
- Self-review each diff before committing. Report final status: what was built, any deviations from the plan and why, and the state of the test suite.

Do **not** split the build across multiple subagents or micro-manage it task-by-task — the plan is the handoff, one builder owns the whole build. Wait for the builder's completion notification before continuing.

### 3. Hands-Off Completion (PR + review, then pause)

Once the builder reports done, run this sequence automatically — no menu, no "what would you like to do?":

1. **Verify the full suite.** Run the project's test command. If it fails, dispatch the builder again (via SendMessage to the same agent, with its context intact) to fix it, or fix a small failure yourself. Do not open a PR on a red suite.
2. **Open a PR, hands-off.** Invoke `creating-pull-requests` to push the branch and open the PR (summary, mermaid visuals, usage, test plan). Do not present the `finishing-a-development-branch` menu here.
3. **Review the diff.** Run the inbuilt `/code-review` skill over the branch diff.
4. **Pause here.** Report the PR link and the review findings, then STOP. Do **not** merge or land the work — the human decides final integration. If they then want to merge locally / discard / clean up, that's when `finishing-a-development-branch` runs.

This is the one intended pause after plan approval.

## When to Stop and Ask

**Stop and ask the user rather than guessing when:**
- The plan has a critical gap that prevents dispatching the builder.
- The builder reports it is genuinely blocked (missing dependency, contradictory instruction, verification that can't pass).
- The full suite fails and you can't get it green after the builder's fix attempt.

**Don't force through blockers** — surface them.

## Remember

- Read the plan critically before dispatching.
- One Opus builder owns the whole build — dispatch, don't micro-manage.
- Don't skip verifications; never open a PR on a red suite.
- Stop when blocked, don't guess.
- Never build on `main`/`master` without explicit user consent.

## Integration

**Required workflow skills:**
- **writing-plans** — produces the approved HTML plan this skill builds.
- **using-git-worktrees** — ensures an isolated workspace before the builder starts.
- **creating-pull-requests** — opens the PR automatically in hands-off completion.
- **finishing-a-development-branch** — only when the user explicitly chooses local merge / discard / cleanup after the pause.

**Review:** the inbuilt `/code-review` skill handles the pre-merge diff review.

**Future enhancement (not wired in):** Claude Code's experimental *agent teams* (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) could run the builder and a reviewer as coordinating teammates the orchestrator messages mid-build. Skipped for now — it's experimental, costs more tokens, and the self-sufficient HTML plan makes mid-run messaging mostly unnecessary.

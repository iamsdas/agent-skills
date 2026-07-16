---
name: building-with-subagent
description: Use when you have a well-defined thing to build — an approved plan, a written spec, or a clear task — and want it built hands-off by an Opus subagent rather than implementing it inline.
---

# Building with a Subagent

## Overview

Hand a well-defined build off to **one Opus subagent** that implements the whole thing, then open a PR and run review — pausing only before final integration. The input can be anything self-sufficient: an approved HTML plan from `writing-plans`, a written spec, or a clear ad-hoc task. This session stays the orchestrator — it isolates the workspace, dispatches, waits, opens the PR, and reviews. It does not build.

**Announce at start:** "I'm using the building-with-subagent skill to build this."

**Isolate first, then hands-off.** A new worktree or branch is created **before** the builder starts — never build on `main`/`master` without explicit user consent. After dispatch, run to an opened PR and review automatically. Stop only on a true blocker (see **When to Stop**) or at the single intended pause before the work is landed.

## Process

### 1. Confirm What's Being Built

The input must be self-sufficient enough for a subagent to build without further back-and-forth: a plan file, a spec, or a task with clear acceptance criteria. Read it. If it's vague, underspecified, or spans real design forks, **do not dispatch** — clarify with the user, or route to `writing-plans` (multi-step work) or `scope-requirements` (unclear product intent) first. A subagent can't be steered mid-run, so an ambiguous handoff produces an unreviewable diff.

### 2. Isolate the Workspace (before anything is built)

Invoke `using-git-worktrees` to create an isolated worktree (or a new branch as its fallback). This happens **first**, before the builder is dispatched, so all of the builder's work lands off `main`. **Never build on `main`/`master` without explicit user consent.**

### 3. Dispatch the Builder

Dispatch **one** subagent via the Agent tool with `model: "opus"` and `subagent_type: "general-purpose"`, running in the background. Give it exactly this job:

- Build what the handoff specifies. If it's a plan/spec with file:line pointers, patterns, verification commands, and commit messages, follow them; if it's a looser task, follow the codebase's existing patterns.
- Follow TDD (test first, watch it fail, implement, watch it pass). Apply the same change to every parallel/sibling call site in lockstep.
- Run verifications; a unit of work is done only when its tests pass.
- **Commit per logical unit** with clear messages. Do not squash everything into one commit.
- Self-review each diff before committing. Report final status: what was built, any deviations from the handoff and why, and the state of the test suite.

Do **not** split the build across multiple subagents or micro-manage it — one builder owns the whole build. Wait for the builder's completion notification before continuing.

### 4. Hands-Off Completion (PR + review, then pause)

Once the builder reports done, run this sequence automatically — no menu, no "what would you like to do?":

1. **Verify the full suite.** Run the project's test command. If it fails, message the same builder (via SendMessage, its context intact) to fix it, or fix a small failure yourself. Do not open a PR on a red suite.
2. **Open a PR, hands-off.** Invoke `creating-pull-requests` to push the branch and open the PR (summary, visuals — a screenshot for a UI-visible feature and/or a mermaid diagram — usage, test plan). Do not present the `finishing-a-development-branch` menu here.
3. **Review the diff.** Run the inbuilt `/code-review` skill over the branch diff.
4. **Pause here.** Report the PR link and the review findings, then STOP. Do **not** merge or land the work — the human decides final integration. If they then want to merge locally / discard / clean up, that's when `finishing-a-development-branch` runs.

This is the one intended pause.

## When to Stop and Ask

**Stop and ask the user rather than guessing when:**
- The handoff is too vague or contradictory to dispatch a builder against.
- The builder reports it is genuinely blocked (missing dependency, contradictory instruction, verification that can't pass).
- The full suite fails and you can't get it green after the builder's fix attempt.

**Don't force through blockers** — surface them.

## Remember

- Confirm the handoff is self-sufficient before dispatching; route vague work to `writing-plans` / `scope-requirements`.
- Isolate the workspace (worktree or branch) **before** the builder starts.
- One Opus builder owns the whole build — dispatch, don't micro-manage.
- Don't skip verifications; never open a PR on a red suite.
- Stop when blocked, don't guess.
- Never build on `main`/`master` without explicit user consent.

## Integration

**Required workflow skills:**
- **using-git-worktrees** — isolates the workspace before the builder starts.
- **creating-pull-requests** — opens the PR automatically in hands-off completion.
- **finishing-a-development-branch** — only when the user explicitly chooses local merge / discard / cleanup after the pause.

**Upstream:** `writing-plans` hands its approved HTML plan here, but this skill also builds from a spec or a clear ad-hoc task directly.

**Review:** the inbuilt `/code-review` skill handles the pre-merge diff review.

**Future enhancement (not wired in):** Claude Code's experimental *agent teams* (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) could run the builder and a reviewer as coordinating teammates the orchestrator messages mid-build. Skipped for now — it's experimental and costs more tokens.

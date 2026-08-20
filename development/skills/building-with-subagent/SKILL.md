---
name: building-with-subagent
description: Use when you have a well-defined thing to build — an approved plan, a written spec, or a clear task — and want it built hands-off by a Sonnet subagent rather than implementing it inline.
---

# Building with a Subagent

## Overview

Hand a well-defined build off to **one Sonnet subagent** that implements the whole thing, then open a PR and run review — pausing only before final integration. The input can be anything self-sufficient: an approved HTML plan from `writing-plans`, a written spec, or a clear ad-hoc task. This session stays the orchestrator — it isolates the workspace, dispatches, waits, opens the PR, and reviews. It does not build.

**The orchestrator never writes code.** Not a one-line fix, not a lint cleanup, not a "quick" test repair. Every code change — including fixing what the builder got wrong — goes back to the builder via SendMessage. The orchestrator's only tools are dispatch, verification, PR, and review.

**Fast inner loop, one full suite at the end.** Per-commit verification runs only the tests touching the changed code. The full suite runs exactly once, by the orchestrator, after the builder reports done.

**Push a draft PR the moment the builder finishes.** The PR goes up before local verification so CI runs in parallel with the orchestrator's full-suite run and code review. It stays a draft until both are green.

**Announce at start:** "I'm using the building-with-subagent skill to build this."

**Isolate first, then hands-off.** A new worktree or branch is created **before** the builder starts — never build on `main`/`master` without explicit user consent. After dispatch, run to an opened PR and review automatically. Stop only on a true blocker (see **When to Stop**) or at the single intended pause before the work is landed.

## Process

### 1. Confirm What's Being Built

The input must be self-sufficient enough for a subagent to build without further back-and-forth: a plan file, a spec, or a task with clear acceptance criteria. Read it. If it's vague, underspecified, or spans real design forks, **do not dispatch** — clarify with the user, or route to `writing-plans` (multi-step work) or `scope-requirements` (unclear product intent) first. A subagent can't be steered mid-run, so an ambiguous handoff produces an unreviewable diff.

### 2. Isolate the Workspace (before anything is built)

Invoke `using-git-worktrees` to create an isolated worktree (or a new branch as its fallback). This happens **first**, before the builder is dispatched, so all of the builder's work lands off `main`. **Never build on `main`/`master` without explicit user consent.**

### 3. Dispatch the Builder

Dispatch **one** subagent via the Agent tool with `model: "sonnet"` and `subagent_type: "general-purpose"`, running in the background at medium thinking effort. Give it exactly this job:

- Build what the handoff specifies. If it's a plan/spec with file:line pointers, patterns, verification commands, and commit messages, follow them; if it's a looser task, follow the codebase's existing patterns.
- Follow TDD (test first, watch it fail, implement, watch it pass). Apply the same change to every parallel/sibling call site in lockstep.
- **Keep the inner loop fast — never run the full test suite per change or per commit.** Run only the narrowest thing that covers the change: the single test, then that file, then at most that module/package. Use the test runner's filters (`-k`, `-t`, path args, `--only-changed`) rather than a bare test command. Skip full type-check/lint/build sweeps between commits too; scope them to changed files if the tooling allows.
- A unit of work is done when its **scoped** tests pass. The full suite is the orchestrator's job at the end, not the builder's — run it at most once, before reporting done, and only if the project's suite is fast (under ~a minute).
- **Commit per logical unit** with clear messages. Do not squash everything into one commit.
- Self-review each diff before committing. Report final status: what was built, any deviations from the handoff and why, and the state of the test suite.

Do **not** split the build across multiple subagents or micro-manage it — one builder owns the whole build. Wait for the builder's completion notification before continuing.

### 4. Hands-Off Completion (draft PR first, then verify in parallel)

Once the builder reports done, run this sequence automatically — no menu, no "what would you like to do?":

1. **Open a draft PR immediately.** Before any local verification, invoke `creating-pull-requests` to push the branch and build the full PR body (summary, mermaid visuals, usage, test plan). That skill takes no flags — **you** add `--draft` when you run its command: `gh pr create --draft --title "<title>" --body-file <path>`. Pushing first is the point: CI starts compiling and running the suite remotely while you work locally. Draft status is what makes this safe — the suite is unverified at this moment, so the PR must not read as ready for a human. Do not present the `finishing-a-development-branch` menu here.
2. **Verify locally while CI runs.** With CI in flight, run the project's full test command — the first and only full-suite run on this machine; the builder deliberately stayed scoped. Run `/code-review` over the branch diff in the same window. Local verification and CI overlap by design; don't sit and watch the CI checks.
3. **Reconcile both signals.** Collect the local suite result and the CI checks (`gh pr checks --watch` once local work is done). If either is red, message the same builder (via SendMessage, its context intact) with the failing output to fix it — **do not fix it yourself, however small it looks.** The builder re-runs scoped tests on the fix; you re-run the full suite and let CI re-run on the new push.
4. **Mark ready, then pause.** Once local suite and CI are both green, flip the PR out of draft (`gh pr ready`). Report the PR link, CI status, and review findings, then STOP. Do **not** merge or land the work — the human decides final integration. If they then want to merge locally / discard / clean up, that's when `finishing-a-development-branch` runs.

**Never leave a red PR marked ready.** A draft PR on an unverified branch is correct; a ready PR on a red one is not.

This is the one intended pause.

## When to Stop and Ask

**Stop and ask the user rather than guessing when:**
- The handoff is too vague or contradictory to dispatch a builder against.
- The builder reports it is genuinely blocked (missing dependency, contradictory instruction, verification that can't pass).
- The full suite or CI is still red after the builder's fix attempt. Surface it — leave the PR in draft and do not pick up the keyboard yourself.

**Don't force through blockers** — surface them.

## Remember

- Confirm the handoff is self-sufficient before dispatching; route vague work to `writing-plans` / `scope-requirements`.
- Isolate the workspace (worktree or branch) **before** the builder starts.
- One Sonnet builder owns the whole build — dispatch, don't micro-manage.
- **The orchestrator never writes code.** Every fix, however trivial, routes back to the builder via SendMessage.
- Scoped tests in the builder's inner loop; the full suite runs once, at the end, by the orchestrator.
- Draft PR first, then verify — CI and the local suite overlap on purpose.
- Don't skip verifications; never mark a PR ready on a red suite or red CI.
- Stop when blocked, don't guess.
- Never build on `main`/`master` without explicit user consent.

## Integration

**Required workflow skills:**
- **using-git-worktrees** — isolates the workspace before the builder starts.
- **creating-pull-requests** — pushes the branch and composes the PR body immediately after the builder finishes, so CI starts before local verification. It takes no flags: the orchestrator appends `--draft` to its `gh pr create` command itself, and later runs `gh pr ready`.
- **finishing-a-development-branch** — only when the user explicitly chooses local merge / discard / cleanup after the pause.

**Upstream:** `writing-plans` hands its approved HTML plan here, but this skill also builds from a spec or a clear ad-hoc task directly.

**Review:** the inbuilt `/code-review` skill handles the pre-merge diff review.

**Future enhancement (not wired in):** Claude Code's experimental *agent teams* (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) could run the builder and a reviewer as coordinating teammates the orchestrator messages mid-build. Skipped for now — it's experimental and costs more tokens.

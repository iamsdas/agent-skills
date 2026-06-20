---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks directly in this session, then run hands-off to an opened PR and review — pausing only before final integration. This is the **default** execution path after a plan is approved.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Hands-off by default.** Once the plan is approved, the user does not want to babysit execution. Run all tasks without check-ins, then open a PR and run review automatically. Stop only on a true blocker (see "When to Stop and Ask") or at the single intended pause: after the PR is open and reviewed, before the work is merged/landed.

**This is the default — not subagents.** Execute the plan's tasks yourself in this session. Only reach for `subagent-driven-development` instead when the user explicitly opts into it for a large, mostly-independent task set; do not fan out to a subagent per task unasked.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. **Only a true blocker stops you here** (a critical gap that prevents starting, a contradiction, a missing dependency the plan assumes). Raise those with the user before starting. Non-blocking observations: note them in one line and proceed — the plan is approved, so don't wait for sign-off on minor concerns.
4. Create TodoWrite and proceed

### Step 2: Execute Tasks

Execute all tasks without pausing between them. Do not check in or ask "should I continue?" — the plan is approved; run it to completion.

For each task:
1. Mark as in_progress
2. Do the work the task describes, using its file:line pointers and following the referenced patterns
3. Run verifications as specified
4. Mark as completed

### Step 3: Hands-Off Completion (PR + review, then pause)

After all tasks complete and verified, run this sequence automatically — no menu, no "what would you like to do?" prompt:

1. **Verify the full suite.** Run the project's test command. If it fails, fix it (or, if you can't, stop and report the failures). Do not open a PR on a red suite.
2. **Open a PR, hands-off.** Invoke the `creating-pull-requests` skill to push the branch and open the PR (summary, mermaid visuals, usage, test plan). Do not present the `finishing-a-development-branch` integration menu — that interactive menu is only for when the user explicitly wants to merge locally or discard.
3. **Review the work.** Invoke `deep-review` for a pre-merge review of the branch (breaking changes, migrations, coverage, regressions).
4. **Pause here.** Report the PR link and the review findings, then STOP. Do **not** merge or land the work — the human decides final integration. If they then want to merge locally / discard / clean up, that's when `finishing-a-development-branch` runs.

This is the one intended pause after plan approval.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Keep Context Lean on Long Plans

Without subagents, every task's work accumulates directly in this session and is re-sent on every later turn — a long plan turns into an expensive marathon. If the plan was sequenced into stages (see writing-plans), execute each stage in its own session so context resets between them rather than running all stages here. When the plan calls for analysis or review, reference findings by `file:line` instead of pasting files, diffs, or command output back into the conversation.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **writing-plans** - Creates the plan this skill executes
- **creating-pull-requests** - Opens the PR automatically in hands-off completion (Step 3)
- **deep-review** - Pre-merge review run automatically before the pause (Step 3)
- **finishing-a-development-branch** - Only when the user explicitly chooses local merge / discard / cleanup after the pause

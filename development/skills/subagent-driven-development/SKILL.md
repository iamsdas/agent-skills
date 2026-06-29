---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan with subagents while paying the codebase-discovery cost **once** and keeping the working churn **off your own context**. One orientation pass up front, then a persistent implementer + reviewer pair per coherent stage, fed one task at a time.

**This is opt-in, not the default.** The default post-plan execution path is `executing-plans` (direct in-session, no subagents). Use this skill when the user explicitly asks for subagent-driven execution — typically a plan large enough that doing the work inline would bloat this session's context, yet where you still want isolation between unrelated chunks of work. If the user didn't ask for subagents, use `executing-plans`.

**Why this shape (the middleground):** Fresh-subagent-per-task wastes tokens because every implementer *and* every reviewer boots cold and re-discovers the same code; isolation also makes a stuck subagent expensive to rescue (cold re-dispatch). Doing everything inline avoids re-discovery but dumps all the churn into the session that persists, so every later turn re-sends it. This skill sits between them: a one-time **orientation pack** removes repeated discovery, and a **persistent worker per stage** (continued via `SendMessage`) keeps a warm context that lives on the *agent* side, never in yours.

**Core principle:** Orient once → persistent implementer+reviewer pair per stage, fed one task at a time → fresh pair per stage for isolation. Discovery is paid once per stage; churn never lands in your context.

**Continuous execution:** Do not pause to check in between tasks or stages. Execute the whole plan. The only reasons to stop are: a BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts waste the human's time — they asked you to execute the plan, so execute it.

**Keep your own context lean — cost compounds.** Everything that lands in *your* context is re-sent on every later turn, so a long run is where token cost balloons. Three habits keep it down: (1) The orientation doc and per-task churn live with the subagents, not in your messages — carry forward only each task's verdict, commit SHA, and the `file:line` pointers a later stage needs. (2) Never re-paste a subagent's report, diff, or file dump into your own messages. (3) Never start doing implementation work in your own coordinator context — that defeats the entire point.

**Right-size each task before you feed it — you cannot babysit a running subagent.** A `SendMessage` (or `Agent`) call blocks until it returns; there is no way to peek mid-run or course-correct. A worker handed too much grinds for a long time producing an unreviewable diff, and the only way to stop it is a manual interrupt — by which point the time is spent and you may have to discard tangled edits. So feed the worker **one task per message**, never a whole stage at once. Before each message, read the task as if it were the worker's prompt: if it bundles several concerns ("scaffold the dirs *and* retarget the model *and* fix the callers"), or you can't state its goal without "and also", split it and feed the pieces one at a time. A task whose diff would be too large to review in one pass is too large to feed in one message. Splitting up front costs minutes; recovering from a runaway costs the whole run.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Inline churn would bloat this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Inline churn would bloat this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Inline churn would bloat this session?" -> "subagent-driven-development" [label="yes, + user opted in"];
    "Inline churn would bloat this session?" -> "executing-plans" [label="no - just run it inline"];
}
```

**vs. Executing Plans:** same session, but discovery and churn stay with subagents instead of accumulating in yours. Use `executing-plans` for small plans where inline churn is cheap.

## The Process

```dot
digraph process {
    rankdir=TB;

    "Read plan: extract tasks, group into coherent stages, create TodoWrite" [shape=box];
    "Dispatch orientation explorer -> writes orientation doc to worktree" [shape=box style=filled fillcolor=lightyellow];

    subgraph cluster_per_stage {
        label="Per Stage";
        "Spawn implementer + reviewer pair (both read orientation doc)" [shape=box];
        "Feed implementer ONE task (SendMessage to same agent)" [shape=box];
        "Implementer asks questions?" [shape=diamond];
        "Answer, re-send" [shape=box];
        "Implementer implements, tests, commits one task" [shape=box];
        "Feed reviewer this task's diff (SendMessage to same agent)" [shape=box];
        "Reviewer approves?" [shape=diamond];
        "SendMessage implementer to fix" [shape=box];
        "Mark task complete; more tasks in stage?" [shape=diamond];
        "Retire the pair" [shape=box];
    }

    "More stages remain?" [shape=diamond];
    "Dispatch final code reviewer over the whole implementation" [shape=box];
    "Hands-off completion: open PR, deep-review, pause" [shape=box style=filled fillcolor=lightgreen];

    "Read plan: extract tasks, group into coherent stages, create TodoWrite" -> "Dispatch orientation explorer -> writes orientation doc to worktree";
    "Dispatch orientation explorer -> writes orientation doc to worktree" -> "Spawn implementer + reviewer pair (both read orientation doc)";
    "Spawn implementer + reviewer pair (both read orientation doc)" -> "Feed implementer ONE task (SendMessage to same agent)";
    "Feed implementer ONE task (SendMessage to same agent)" -> "Implementer asks questions?";
    "Implementer asks questions?" -> "Answer, re-send" [label="yes"];
    "Answer, re-send" -> "Feed implementer ONE task (SendMessage to same agent)";
    "Implementer asks questions?" -> "Implementer implements, tests, commits one task" [label="no"];
    "Implementer implements, tests, commits one task" -> "Feed reviewer this task's diff (SendMessage to same agent)";
    "Feed reviewer this task's diff (SendMessage to same agent)" -> "Reviewer approves?";
    "Reviewer approves?" -> "SendMessage implementer to fix" [label="no"];
    "SendMessage implementer to fix" -> "Feed reviewer this task's diff (SendMessage to same agent)" [label="re-review"];
    "Reviewer approves?" -> "Mark task complete; more tasks in stage?" [label="yes"];
    "Mark task complete; more tasks in stage?" -> "Feed implementer ONE task (SendMessage to same agent)" [label="yes"];
    "Mark task complete; more tasks in stage?" -> "Retire the pair" [label="no"];
    "Retire the pair" -> "More stages remain?";
    "More stages remain?" -> "Spawn implementer + reviewer pair (both read orientation doc)" [label="yes"];
    "More stages remain?" -> "Dispatch final code reviewer over the whole implementation" [label="no"];
    "Dispatch final code reviewer over the whole implementation" -> "Hands-off completion: open PR, deep-review, pause";
}
```

## Staging the Plan

A **stage** is a small group of tasks that share context — same subsystem, same files, or a natural build sequence (3–5 tasks is typical). Tasks within a stage are fed to one warm worker; unrelated stages get fresh pairs so a messy stage can't pollute the next. If the plan was already sequenced into stages at planning time (see `writing-plans`), use that grouping. If it's a flat task list, group adjacent tasks that touch the same area; put genuinely unrelated tasks in their own stage.

## Orientation Pass (once, up front)

**First, keep the artifacts out of git.** Before dispatching anything, add the two artifact files to the worktree-local git exclude so no implementer's `git add` ever commits them (this never touches a tracked file, so nothing about it appears in the PR):

```bash
printf '%s\n' .orientation.md .build-journal.md >> "$(git -C [WORKTREE] rev-parse --git-path info/exclude)"
```

Then dispatch **one** orientation agent (`general-purpose`) using `./orientation-prompt.md`. It must both explore *and* write files, so it can't be a read-only specialist (`code-explorer` has no `Write`) — see the prompt template for why not `focused-builder` either. It writes a compact orientation doc to the worktree (e.g. `./.orientation.md`) covering architecture, the key files and their responsibilities, conventions to follow, and `file:line` anchors for the areas the plan touches, and it initializes the empty decision journal (next section). Every implementer and reviewer is pointed at these files instead of re-discovering the codebase. You do **not** read the doc into your own context — you only pass its path. Skip this pass only for a plan small enough that a single stage covers it.

> **Note — shared memory is files, not a database.** Dispatched specialist subagents (`code-explorer`, `focused-builder`, `code-reviewer`) run with curated tool allowlists that exclude MCP, so they **cannot** reach a queryable knowledge base (e.g. context-mode `ctx_search`) — verified empirically. Cross-subagent memory here is therefore the worktree filesystem (orientation doc + decision journal), git history, and what you inject into prompts. Don't design the run around an MCP store the workers can't query.

## Decision Journal (append-only)

The orientation doc maps the code as it was *before* the run; it goes stale as soon as work starts. The journal carries forward what gets *decided* during the run so a later stage's fresh pair inherits decisions instead of re-deriving them. Keep it at `[WORKTREE]/.build-journal.md`.

- **Append-only.** Each agent *appends* a short entry; no one rewrites earlier entries, so there's no clobber (implementation subagents run one at a time — never in parallel — so appends don't race).
- **Who writes:** only the implementer — it has `Write`/`Bash`; the reviewer is read-only and *cannot* write files. The implementer appends 3–6 bullets after committing each task: decisions made, assumptions taken, gotchas discovered, and anything deferred to a later task ("left retry logic for Task 7"). If the *reviewer* surfaces a cross-cutting concern a later stage must know, it states it in its verdict and you relay it to the next implementer to record — the reviewer never edits the journal itself.
- **Who reads:** every freshly-spawned stage pair reads the journal right after the orientation doc. A warm agent already lived through its own stage's entries, so you don't re-feed them.
- **You never read it into your context** — pass the path; the journal exists for the agents, not the coordinator. Keep entries terse: a decision and its reason, not a narrative.

## Persistent Pair per Stage

For each stage, spawn the pair **once** (a fresh `Agent` call each), then continue them with `SendMessage`:

- **Spawn** an implementer (`development:focused-builder`) and a reviewer (`development:code-reviewer`), each told to read the orientation doc **and the decision journal** first. This is the only cold start per stage.
- **Feed one task at a time.** `SendMessage` the implementer a single task (templates in `./implementer-prompt.md`). It implements, tests, commits, self-reviews, returns a status. Then `SendMessage` the reviewer that task's diff range (`./task-reviewer-prompt.md`). Because both agents are continued, neither re-explores between tasks — discovery is paid once for the whole stage.
- **Fix loop stays warm.** If the reviewer finds issues, `SendMessage` the *same* implementer to fix, then `SendMessage` the *same* reviewer to re-check. No context is rebuilt.
- **Retire at stage end.** When the stage's tasks are all approved, drop the pair. The next stage spawns a fresh pair that re-reads only the orientation doc.

## Handling Implementer Status

Implementer subagents report one of four statuses:

**DONE:** Feed the reviewer this task's diff.

**DONE_WITH_CONCERNS:** Read the concerns first. If they're about correctness or scope, address them (via `SendMessage` to the same implementer) before review. If they're observations ("this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The worker needs information not provided. `SendMessage` the missing context to the same agent — its warm context is exactly why this is cheap; do not re-dispatch cold.

**BLOCKED:** Assess the blocker, then act on the *same warm agent* wherever possible:
1. Context problem → `SendMessage` more context.
2. Needs more reasoning → escalate the model (a fresh, more capable agent for this task; hand it the orientation doc).
3. Task too large → split it and feed the pieces one at a time.
4. Plan itself is wrong → escalate to the human.

**Never** ignore an escalation or feed the same task again unchanged. If the worker said it's stuck, something must change. **"Too large" is something you catch *before* feeding a task, not only on a BLOCKED report** — an over-reaching worker rarely reports BLOCKED, it just sprawls silently until interrupted. Apply the right-sizing check above before every `SendMessage`.

## Prompt Templates

| Template | Agent | Model | Lifetime | Purpose |
|----------|-------|-------|----------|---------|
| `./orientation-prompt.md` | `general-purpose` | sonnet | one-shot | Discovers the codebase once; writes the orientation doc and initializes the decision journal (needs `Write`+`Bash`, which the read-only explorers lack) |
| `./implementer-prompt.md` | `development:focused-builder` | sonnet | persistent per stage | Implements one fed task, tests, commits, self-reviews; continued via `SendMessage` for the next task |
| `./task-reviewer-prompt.md` | `development:code-reviewer` | sonnet | persistent per stage | Verifies spec compliance + code quality on each task's diff; continued via `SendMessage` across the stage |

## Example Workflow

```
[Read plan, group tasks into Stage A (tasks 1–3) and Stage B (tasks 4–5), create TodoWrite]
[Add .orientation.md + .build-journal.md to .git/info/exclude]
[Dispatch orientation agent (general-purpose) → writes ./.orientation.md + empty ./.build-journal.md]

Stage A:
  [Spawn implementer + reviewer, both read ./.orientation.md + ./.build-journal.md]
  Task 1: [SendMessage implementer → commits, appends journal entry] [SendMessage reviewer → ✅] [mark complete]
  Task 2: [SendMessage implementer → commits, appends journal entry] [SendMessage reviewer → ❌ missing progress reporting]
          [SendMessage implementer → fixes] [SendMessage reviewer → ✅] [mark complete]
  Task 3: [SendMessage implementer → commits, appends journal entry] [SendMessage reviewer → ✅] [mark complete]
  [Retire the pair]

Stage B:
  [Spawn fresh implementer + reviewer → they read ./.orientation.md + Stage A's journal entries, inheriting its decisions]
  ...

[After all stages: final code reviewer → hands-off completion → open PR → deep-review → pause]
```

## Completion (hands-off)

After the final stage's review passes, complete hands-off — same as `executing-plans` Step 3. Do not present an interactive integration menu:

1. **Verify the full suite.** Run the project's test command; fix failures or stop and report. No PR on a red suite.
2. **Confirm the artifacts never got committed.** Run `git -C [WORKTREE] log --all --name-only -- .orientation.md .build-journal.md` — it must return nothing. If either file slipped into a commit (e.g. an explicit `git add <file>` bypassed the exclude), remove it from history before the PR. The orientation doc and journal are run-scoped scaffolding, not deliverables.
3. **Open a PR, hands-off.** Invoke `creating-pull-requests` to push the branch and open the PR.
4. **Review.** Invoke `deep-review` for the pre-merge review.
5. **Pause.** Report the PR link and review findings, then STOP. The human decides final integration; `finishing-a-development-branch` runs only if they then choose local merge / discard / cleanup.

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Skip the orientation pass on a multi-stage plan (every worker then re-discovers the codebase — the exact waste this skill exists to remove)
- Skip the decision journal across stages (a fresh stage pair then re-derives or contradicts decisions earlier stages already made)
- Let an agent rewrite or edit earlier journal entries (append-only — overwriting loses the very history later stages need)
- Commit the orientation doc or journal to the branch (add them to the worktree-local git exclude before any task runs; they're run-scoped scaffolding, not deliverables)
- Ask a read-only agent (`code-explorer`, `code-reviewer`) to write a file — they have no `Write`/`Bash`; only `focused-builder` and `general-purpose` can write here
- Design the run around a queryable MCP knowledge base (e.g. context-mode `ctx_search`) for shared memory — the specialist subagents can't reach MCP tools; use worktree files instead
- Read the orientation doc, the journal, or any task's churn into your *own* context (pass the paths; carry forward only verdicts, SHAs, and `file:line`)
- Feed a worker more than one task in a single message (you can't interrupt a synchronous call; an oversized message can only be stopped by a manual interrupt after the time is wasted)
- Spawn a *fresh* agent for the next task within a stage instead of continuing the warm one via `SendMessage` (that reintroduces re-discovery)
- Cold-re-dispatch a stuck worker when `SendMessage`-ing context into its warm context would do
- Skip the per-task review (it covers both spec compliance and code quality)
- Proceed with unfixed issues, or move to the next task while the reviewer has open issues
- Make a subagent read the plan file (paste the task text instead)
- Re-paste a subagent's full report, diff, or file dump into your own messages

**If subagent asks questions:** answer clearly and completely via `SendMessage`; don't rush it into implementation.

**If reviewer finds issues:** the same warm implementer fixes; the same warm reviewer re-checks; repeat until approved.

## Integration

**Required workflow skills:**
- **using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing); the orientation doc lives here
- **writing-plans** - Creates the plan this skill executes; its stage sequencing feeds the staging step
- **requesting-code-review** - Code review template for reviewer subagents
- **creating-pull-requests** - Opens the PR automatically in hands-off completion
- **deep-review** - Pre-merge review run automatically before the pause
- **finishing-a-development-branch** - Only when the user explicitly chooses local merge / discard / cleanup after the pause

**Subagents should use:**
- **test-driven-development** - Implementer follows TDD for each task

**Alternative workflow:**
- **executing-plans** - The default; use for small plans where inline churn is cheap

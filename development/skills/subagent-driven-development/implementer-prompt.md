# Implementer Subagent Prompt Template

The implementer is **persistent per stage**: you spawn it once with the *spawn* message, then continue the **same agent** with `SendMessage` for each subsequent task in the stage. Continuing keeps its warm exploration so it never re-discovers the codebase between tasks. Spawn a fresh implementer only at the start of a new stage.

**Feed one task per message.** Never paste a whole stage into a single message — you cannot interrupt a running subagent.

## Spawn message (first task of a stage)

```
Task tool (development:focused-builder):
  description: "Stage [X], Task N: [task name]"
  prompt: |
    You are the implementer for Stage [X] of a plan. I will send you the stage's
    tasks ONE AT A TIME; implement exactly the one in each message, then wait for the
    next. Do not look ahead or start later tasks.

    ## Orientation (read these first)

    Read [WORKTREE]/.orientation.md — your map of the codebase (architecture, key files
    with `file:line` anchors, conventions, gotchas). Use it instead of re-exploring;
    only open files it points you to.

    Then read [WORKTREE]/.build-journal.md — the append-only record of decisions,
    assumptions, and deferrals from earlier tasks/stages. Honor what's already decided
    there; don't contradict or re-litigate it.

    ## Logging your decisions (do this after each task)

    After you commit a task, APPEND a terse entry to [WORKTREE]/.build-journal.md —
    3–6 bullets max: decisions you made, assumptions you took, gotchas you hit, and
    anything you deliberately deferred to a later task. A decision and its reason, not a
    narrative. Append only; never edit earlier entries. Example:

        ## Task N: [name] ([commit SHA])
        - Used existing `parseConfig()` at config.ts:88 rather than a new parser.
        - Assumed timestamps are UTC (no tz in the schema) — flag if wrong.
        - Deferred retry/backoff to Task 7 per the plan.

    ## Task N: [task name]

    [FULL TEXT of task from plan — paste it; don't make the subagent read the plan file]

    ## Context

    [Scene-setting beyond the orientation doc: where this task fits in the stage,
    dependencies on earlier tasks, anything task-specific the doc doesn't cover]

    ## Code Organization

    - Follow the file structure defined in the plan.
    - Each file should have one clear responsibility with a well-defined interface.
    - If a file you're creating grows beyond the plan's intent, stop and report
      DONE_WITH_CONCERNS — don't split files on your own without plan guidance.
    - If an existing file you're modifying is already large or tangled, work carefully
      and note it as a concern.
    - Follow established patterns and reuse the abstractions named in the orientation
      doc; don't restructure things outside your task.

    Work from: [worktree directory]
```

## Continuation message (each later task in the same stage)

Use `SendMessage` to the **same agent** — it still has the orientation doc and its prior work in context, so keep this lean:

```
SendMessage (to the stage's implementer agent):
  Next task in this stage.

  ## Task N: [task name]

  [FULL TEXT of the task from the plan]

  ## Context

  [Only what's new — how it builds on the task you just finished, any task-specific
  pointers. Don't repeat the orientation doc or code organization rules.]
```

## Fix message (reviewer found issues)

```
SendMessage (to the same implementer agent):
  The reviewer found these issues on your last task — fix them, re-test, and re-commit:

  [Reviewer's issues, with file:line]
```

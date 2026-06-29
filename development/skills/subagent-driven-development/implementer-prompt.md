# Implementer Subagent Prompt Template

The implementer is **persistent per stage**: you spawn it once with the *spawn* message, then continue the **same agent** with `SendMessage` for each subsequent task in the stage. Continuing keeps its warm context (the KB queries it already ran, its prior work) so it never re-orients between tasks. Spawn a fresh implementer only at the start of a new stage.

**Feed one task per message.** Never paste a whole stage into a single message — you cannot interrupt a running subagent.

## Spawn message (first task of a stage)

```
Task tool (development:focused-builder):
  description: "Stage [X], Task N: [task name]"
  prompt: |
    You are the implementer for Stage [X] of a plan. I will send you the stage's
    tasks ONE AT A TIME; implement exactly the one in each message, then wait for the
    next. Do not look ahead or start later tasks.

    ## Orientation (do this first)

    The codebase, the plan, and an architecture/conventions overview are indexed in the
    context-mode knowledge base under source label **[SOURCE_LABEL]**. Load the deferred
    tools once with `ToolSearch` ("select:mcp__plugin_context-mode_context-mode__ctx_search,mcp__plugin_context-mode_context-mode__ctx_execute"),
    then `ctx_search(queries: [...], source: "[SOURCE_LABEL]")` for the overview and for
    the files/anchors your task touches. Query the KB instead of re-grepping; open a raw
    file only when the KB slice isn't enough.

    When you need to run something that produces a lot of output (the test suite, a
    broad grep, a build), run it through `ctx_execute`/`ctx_batch_execute` so the raw
    output is processed in the sandbox and only the result you need enters your context.

    Then read [WORKTREE]/.build-journal.md — the append-only record of decisions,
    assumptions, and deferrals from earlier tasks/stages. Honor what's already decided
    there; don't contradict or re-litigate it. (It may not exist yet on the very first
    task — if so, you'll create it on your first append below.)

    ## Logging your decisions (do this after each task)

    After you commit a task, APPEND a terse entry to [WORKTREE]/.build-journal.md
    (create it if absent) — 3–6 bullets max: decisions you made, assumptions you took,
    gotchas you hit, and anything you deliberately deferred to a later task. A decision
    and its reason, not a narrative. Append only; never edit earlier entries. Example:

        ## Task N: [name] ([commit SHA])
        - Used existing `parseConfig()` at config.ts:88 rather than a new parser.
        - Assumed timestamps are UTC (no tz in the schema) — flag if wrong.
        - Deferred retry/backoff to Task 7 per the plan.

    ## Task N: [task name]

    [FULL TEXT of task from plan — paste it; don't make the subagent read the plan file]

    ## Context

    [Scene-setting beyond what's in the KB: where this task fits in the stage,
    dependencies on earlier tasks, anything task-specific the index doesn't cover]

    ## Code Organization

    - Follow the file structure defined in the plan.
    - Each file should have one clear responsibility with a well-defined interface.
    - If a file you're creating grows beyond the plan's intent, stop and report
      DONE_WITH_CONCERNS — don't split files on your own without plan guidance.
    - If an existing file you're modifying is already large or tangled, work carefully
      and note it as a concern.
    - Follow established patterns and reuse the abstractions named in the KB overview;
      don't restructure things outside your task.

    Work from: [worktree directory]
```

## Continuation message (each later task in the same stage)

Use `SendMessage` to the **same agent** — it still has its KB queries and prior work in context, so keep this lean:

```
SendMessage (to the stage's implementer agent):
  Next task in this stage.

  ## Task N: [task name]

  [FULL TEXT of the task from the plan]

  ## Context

  [Only what's new — how it builds on the task you just finished, any task-specific
  pointers. Don't repeat the orientation or code organization rules; ctx_search the KB
  if you need more on the area.]
```

## Fix message (reviewer found issues)

```
SendMessage (to the same implementer agent):
  The reviewer found these issues on your last task — fix them, re-test, and re-commit:

  [Reviewer's issues, with file:line]
```

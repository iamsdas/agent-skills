# Orientation Explorer Prompt Template

Dispatch this **once**, before any implementation. It pays the codebase-discovery cost a single time and writes a compact orientation doc that every implementer and reviewer reads instead of re-exploring. You pass only the doc's path to later subagents — you never read its contents into your own context.

**Agent choice:** use `general-purpose`. The orientation step must both *explore* (Read/Grep/Glob) and *write files* (the doc + the journal). The read-only specialist explorers (`code-explorer`) **cannot write files** — verified — and `focused-builder`, though write-capable, is framed for "implement one code task with TDD and commit," which fights a doc-writing job (it'll try to commit the doc and look for tests). `general-purpose` has the full toolset and no rigid frame, so it explores and emits the artifacts in one shot without the content ever entering your context.

```
Task tool (general-purpose):
  description: "Orient: write orientation doc for [feature/plan name]"
  prompt: |
    You are producing a one-time orientation document for a team of implementer and
    reviewer subagents who will execute the plan below. They will read ONLY your
    document — not the plan, not the wider codebase — so it must let them work
    without re-discovering the code themselves.

    ## Plan (the work that will be implemented)

    [FULL TEXT of the plan, or at least every task's description — paste it; do not
    make the explorer hunt for the plan file]

    ## Your Job

    Explore the codebase and write a COMPACT orientation document to:

        [WORKTREE]/.orientation.md

    Keep it tight — it is a map, not a transcript. Target well under 300 lines. Cover:

    - **Architecture:** how the relevant subsystems fit together (a few sentences, not
      a tour of the whole repo).
    - **Key files:** for each file the plan will touch or depend on, its path, its one
      responsibility, and the `file:line` anchors that matter (entry points, the
      functions/classes to extend, the seams to plug into).
    - **Conventions to follow:** naming, error handling, test layout and how tests are
      run, logging, the abstractions/utilities implementers should reuse instead of
      reinventing.
    - **Gotchas:** non-obvious coupling, invariants, or footguns in the areas being
      changed.

    Exclude anything an implementer can trivially see from the file you've already
    pointed them to. No pasted code blocks longer than a few lines. No narration of
    your search process.

    ## Initialize the decision journal

    Also create an empty decision journal at [WORKTREE]/.build-journal.md with just a
    header:

        # Build Decision Journal
        Append-only. Implementers add entries per task; later stages read this to
        inherit decisions instead of re-deriving them.

    Don't put findings in it — it's for decisions made *during* the build, which start
    empty.

    ## Report

    Write both files, then return ONLY: the orientation doc's path, its line count, and
    a 2–3 line summary of what it covers. Do not paste the document back.

    Work from: [worktree directory]
```

**Returns:** the orientation doc path + a short summary. Carry forward only the path — hand it to every implementer and reviewer.

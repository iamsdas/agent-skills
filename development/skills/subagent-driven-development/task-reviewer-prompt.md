# Task Reviewer Prompt Template

Use this template when dispatching the per-task reviewer subagent.

**Purpose:** Verify the implementation matches the spec (nothing more, nothing less) AND is well-built — one reviewer, one pass over the task's diff.

```
Task tool (development:code-reviewer):
  description: "Review Task N: [task name]"
  prompt: |
    You are reviewing a completed task for spec compliance and code quality.

    ## What Was Requested

    [FULL TEXT of task requirements from the plan]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## Git Range to Review

    Base: [BASE_SHA — commit before task]
    Head: [HEAD_SHA — current commit]

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## Verify Independently

    Read the actual code — do not take the implementer's report at face value.
    Compare the implementation to the requirements directly, and check claims of
    completeness against the diff, not the report.

    ## Spec Compliance

    - **Missing requirements:** Is everything that was requested implemented? Anything
      claimed in the report but absent from the code?
    - **Extra/unneeded work:** Features beyond the spec, over-engineering, unrequested
      "nice to haves"
    - **Misunderstandings:** Wrong problem solved, requirements interpreted differently
      than intended, right feature built the wrong way

    ## Code Quality

    You are the only reviewer for this task — no specialist agents run alongside you.
    Beyond standard code quality (bugs, conventions, clarity), briefly flag any major
    test-coverage or error-handling gaps so nothing falls through (keep it shallow).
    Also verify:
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this change create new files that are already large, or significantly grow
      existing files? (Focus on what this change contributed — don't flag pre-existing
      file sizes.)
    - Does the implementation use standard project conventions and abstractions?

    ## Report

    - **Spec:** ✅ compliant | ❌ issues found [list specifically what's missing or
      extra, with file:line references]
    - **Quality:** Strengths, Issues (Critical/Important/Minor)
    - **Verdict:** Approved | Issues Found
```

**Reviewer returns:** Spec status, Quality findings, Verdict

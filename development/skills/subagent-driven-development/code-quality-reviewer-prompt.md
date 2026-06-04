# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (development:code-reviewer):
  description: "Review code quality for Task N"
  prompt: |
    ## What Was Implemented

    [DESCRIPTION: task summary, from implementer's report]

    ## Requirements / Plan

    Task N from [plan-file]

    ## Git Range to Review

    Base: [BASE_SHA — commit before task]
    Head: [HEAD_SHA — current commit]

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## Additional Checks

    You are the only reviewer for this task — no specialist agents are running alongside you. Beyond standard code quality, briefly flag any major test-coverage or error-handling gaps so nothing falls through (keep it shallow). Also verify:
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this change create new files that are already large, or significantly grow existing files? (Focus on what this change contributed — don't flag pre-existing file sizes.)
    - Does the implementation use standard project conventions and abstraction?
```

**Reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

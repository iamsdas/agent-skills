# Code Reviewer Context Template

Use this template when dispatching a `development:code-reviewer` subagent. The agent already knows how to review — just pass the context.

```
Task tool (development:code-reviewer):
  description: "Review code changes"
  prompt: |
    ## What Was Implemented

    {DESCRIPTION}

    ## Requirements / Plan

    {PLAN_OR_REQUIREMENTS}

    ## Git Range to Review

    Base: {BASE_SHA}
    Head: {HEAD_SHA}

    ```bash
    git diff --stat {BASE_SHA}..{HEAD_SHA}
    git diff {BASE_SHA}..{HEAD_SHA}
    ```
```

**Placeholders:**
- `{DESCRIPTION}` — brief summary of what was built
- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan file path, task text, or requirements)
- `{BASE_SHA}` — starting commit
- `{HEAD_SHA}` — ending commit

**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment

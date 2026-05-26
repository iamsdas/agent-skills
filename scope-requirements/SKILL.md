---
name: scope-requirements
description: "Runs a two-phase planning flow: first summarize user requirements and current behavior from an end-user product perspective, then ask expectation-refinement questions without implementation detail. Use when the user invokes /scope-requirements or asks for structured requirement clarification before implementation planning."
disable-model-invocation: true
---

# Scope Requirements

## Purpose

Use this skill to prevent premature implementation planning. First align on product intent and expected behavior, then move to technical planning only after explicit user confirmation.

## Workflow

1. Restate the request in product terms:
   - Summarize desired outcome for end users.
   - Summarize current behavior or baseline behavior, if available using a subagent.
   - Highlight gaps between current and desired behavior.

2. Refine expectations without implementation details:
   - Ask focused clarification questions about outcomes, scope, constraints, and acceptance signals.
   - Surface hidden assumptions, identify failure modes early and validate non-functional requirements.
   - If the request involves a migration (data, API, workflow, or platform), explicitly ask whether backward compatibility is required.
   - Do not discuss architecture, code structure, libraries, or low-level technical steps.
   - Keep questions practical and decision-oriented.
   - Keep asking questions one at a time till you reach a shared understanding of the request with the user.
   - Do not ask questions that can be answered by searching the codebase.
   - Suggest a list of options for the user to choose from for each question.

3. Confirm readiness:
   - Present a concise "understanding so far" recap.
   - Ask for explicit confirmation to proceed (for example: "Should I now switch to planning mode and draft implementation steps?").
   - If user does not confirm, continue refinement.

4. Switch to implementation planning mode only after confirmation

## Guardrails

- Never jump into implementation details before user confirmation.
- Keep discovery questions user-facing and outcome-focused.
- If existing behavior is unknown, say so and ask for missing context.
- Only target backward compatibility when the user explicitly requires it; do not assume it by default.
- Treat confirmation as required, not optional.

## Response Template

Use this structure in the pre-confirmation phase:

```markdown
## Product Overview

- Desired user outcome: ...
- Current behavior: ... / Unknown
- Behavior gap: ...

## Clarifying Questions

- Q1. ...
  - A. ....
  - B. ....
  - ....

- Q2. ...
  - A. ....
  - B. ....
  - ....

- Q3. ...
  - A. ....
  - B. ....
  - ....

## Confirmation

Current understanding: ...
Should I switch to planning mode and draft implementation details?
```

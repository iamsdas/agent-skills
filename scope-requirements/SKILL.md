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
   - Use the `AskUserQuestion` tool to present each question interactively with selectable options. Do NOT list questions as plain markdown text — always invoke AskUserQuestion so the user gets a clickable UI. Include 2–4 options per question; the tool automatically adds an "Other" option for freeform input. You may batch up to 4 related questions in a single AskUserQuestion call when they are independent of each other.

3. Confirm readiness:
   - Present a concise "understanding so far" recap.
   - Use AskUserQuestion to ask if the scope is complete, with options like "Yes, scope is complete" and "No, keep refining".
   - If user does not confirm, continue refinement.

4. Handoff the PRD to another agent:
   - Once the user confirms the scope is complete, produce a final PRD document (see PRD Template below).
   - Invoke the `handoff` skill, passing the PRD as the handoff document so a separate planning/implementation agent can pick it up.
   - Do NOT switch to planning mode yourself. Do NOT write implementation steps.

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
```

Then immediately invoke AskUserQuestion with up to 4 clarifying questions (batch independent ones together):

```
AskUserQuestion(questions=[
  { question: "Q1 text?", header: "Short label", options: [{label: "A", description: "..."}, {label: "B", description: "..."}] },
  { question: "Q2 text?", header: "Short label", options: [...] },
])
```

After all questions are answered, output a "Current understanding" recap and invoke AskUserQuestion one final time to confirm:

```
AskUserQuestion(questions=[
  { question: "Is the scope complete and ready to hand off?", header: "Confirm scope", options: [
    {label: "Yes, hand it off", description: "Produce the final PRD and hand off to a planning agent"},
    {label: "No, keep refining", description: "Continue asking clarifying questions"}
  ]}
])
```

Once confirmed, write the final PRD using this template, then invoke the `handoff` skill with the PRD as context:

```markdown
# PRD: <feature name>

## Desired Outcome
...

## Current Behavior
...

## Behavior Gap
...

## Scope & Constraints
...

## Acceptance Criteria
- ...

## Out of Scope
- ...

## Open Questions / Risks
- ...
```

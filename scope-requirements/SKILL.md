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
   - Understand how the new change is meant to be used — who triggers it, in what context, and what the expected interaction flow looks like.
   - Surface hidden assumptions, identify failure modes early and validate non-functional requirements.
   - If the request involves a migration (data, API, workflow, or platform), explicitly ask whether backward compatibility is required.
   - Identify related or dependent logic that may also need to change as a consequence of this request, and ask the user whether those areas are in scope.
   - Do not discuss architecture, code structure, libraries, or low-level technical steps.
   - Keep questions practical and decision-oriented.
   - Keep asking questions one at a time till you reach a shared understanding of the request with the user.
   - Do not ask questions that can be answered by searching the codebase.
   - Use the `AskUserQuestion` tool to present each question interactively with selectable options. Do NOT list questions as plain markdown text — always invoke AskUserQuestion so the user gets a clickable UI. Include 2–4 options per question; the tool automatically adds an "Other" option for freeform input. You may batch up to 4 related questions in a single AskUserQuestion call when they are independent of each other.

3. Confirm readiness:
   - Present a concise "understanding so far" recap.
   - Before offering confirmation, review all open questions surfaced during refinement. If any remain unresolved, ask them now — do not proceed to confirmation while unknowns exist.
   - Use AskUserQuestion to ask if the scope is complete, with options like "Yes, scope is complete" and "No, keep refining".
   - If user does not confirm, continue refinement.

4. Output the final ticket:
   - Once the user confirms the scope is complete, produce the final ticket using the Notion Task Template below.
   - Output it as a clean markdown block the user can copy directly (no preamble, no trailing commentary).
   - Do NOT invoke the handoff skill. Do NOT switch to planning mode. Do NOT write implementation steps.

## Guardrails

- Never jump into implementation details before user confirmation.
- Keep discovery questions user-facing and outcome-focused.
- If existing behavior is unknown, say so and ask for missing context.
- Only target backward compatibility when the user explicitly requires it; do not assume it by default.
- Treat confirmation as required, not optional.
- Never offer the "scope is complete" confirmation while open questions remain — resolve them first.

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

Once confirmed, output ONLY the following block — no intro sentence, no "here is your ticket", nothing before or after:

```markdown
# <Title>

## What & Why

<2–4 sentences. What is this task? What is broken or missing today, and why does it matter? Give enough context that a planning agent can reason about the problem without needing to ask follow-up questions.>

## Desired Behavior

<What should be true when this is done? Describe from the user's perspective — what they can do, see, or experience that they couldn't before.>

## Constraints

- <anything that must stay the same, must not break, or limits the solution space>

## Acceptance Criteria

- [ ] <specific, testable outcome>
- [ ] <edge case or error condition that must be handled>

## Out of Scope

- <related thing explicitly excluded>
```

---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before accepting. Ask before assuming. Technical correctness over social comfort.

**This skill stops at evaluation — it does NOT implement.** Your job is to determine which findings are real and agreed, then hand the confirmed set to `writing-plans`. Writing code here is out of scope.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
   IF feedback describes a bug → use the investigate skill before evaluating
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. PLAN: Hand the confirmed, agreed-upon changes to `writing-plans` — do NOT implement here
```

**REQUIRED SUB-SKILL for bugs:** When feedback identifies a bug (incorrect behavior, crash, regression, wrong output), invoke `investigate` as part of step 3 to understand root cause, user impact, and test coverage before deciding whether the finding is valid.

**REQUIRED SUB-SKILL for implementation:** Once you know which findings are confirmed and agreed (pushback resolved, unclear items clarified), invoke `writing-plans` to turn them into a step-by-step implementation plan. Do NOT edit code, write tests, or run fixes from within this skill — that happens after a plan exists.

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (explicit CLAUDE.md violation)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (this skill plans, it never implements)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- State the verified conclusion, then route to `writing-plans` (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner
- **Trusted** - accept after understanding, then plan
- **Still ask** if scope unclear
- **No performative agreement**
- **Technical acknowledgment**, then route to `writing-plans`

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Triaging Confirmed Findings (input to the plan)

Before handing off, organize the confirmed findings — this becomes the spec `writing-plans` works from:

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST (don't hand off a partial understanding)
  2. Drop anything you pushed back on successfully or that's YAGNI
  3. Group the survivors by priority for the plan:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
```

Hand this triaged set to `writing-plans`. Sequencing, testing, and regression-checking are the plan's job — not this skill's.

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Confirmed - [specific issue] at [location]. Adding it to the plan."
✅ "Verified against [X]. Real bug. Will plan the fix."

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
❌ "Fixed it" / "Let me implement that now" (this skill doesn't implement)
```

**Why no thanks:** State the technical conclusion. The confirmed finding goes into the plan; the plan and the eventual code show you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the verified conclusion instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Adding it to the plan."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Will plan the fix."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just acknowledge |
| Implementing from this skill | STOP at evaluation — hand confirmed findings to `writing-plans` |
| Blind acceptance | Verify against codebase first |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Handing off partial understanding | Clarify all items before planning |
| Can't verify, proceed anyway | State limitation, ask for direction |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## After a Confirmed Finding

When a finding turns out to be a real bug or missing-logic gap — not just this instance, but a class that could recur — planning the one fix isn't enough.

This is a separate axis from the `writing-plans` handoff: the plan addresses *this* instance, while `preventing-recurrence` guards against the whole *class*. Do both.

**REQUIRED SUB-SKILL:** Invoke `preventing-recurrence` to route the lesson into a durable mechanism (a hook, a skill/reviewer edit, a project instruction, or memory) so the same class is caught automatically next time. Tell it the defect was caught *at review* — that biases the fix one phase upstream (build/TDD, or a `deep-review` lane).

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then plan — never implement straight from review.

No performative agreement. Technical rigor always.

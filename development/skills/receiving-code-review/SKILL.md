---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before accepting. Ask before assuming. Technical correctness over social comfort.

**This skill stops at evaluation — it does NOT implement.** Your job is to determine which findings are real and agreed, then hand the confirmed set to `building-with-subagent`. Writing code here is out of scope.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
   IF feedback describes a bug → use the investigate skill before evaluating
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. HAND OFF: Give the confirmed, agreed-upon changes to `building-with-subagent` — do NOT implement here
```

**REQUIRED SUB-SKILL for bugs:** When feedback identifies a bug (incorrect behavior, crash, regression, wrong output), invoke `investigate` as part of step 3 to understand root cause, user impact, and test coverage before deciding whether the finding is valid.

**REQUIRED SUB-SKILL for implementation:** Once you know which findings are confirmed and agreed (pushback resolved, unclear items clarified), invoke `building-with-subagent` and hand it the triaged set as the build brief. Do NOT edit code, write tests, or run fixes from within this skill — a builder does that on an isolated branch.

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (performative)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (this skill evaluates, it never implements)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- State the verified conclusion, then route to `building-with-subagent` (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
The user: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From the User
- **Trusted** - accept after understanding, then hand off
- **Still ask** if scope unclear
- **No performative agreement**
- **Technical acknowledgment**, then route to `building-with-subagent`

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

IF conflicts with the user's prior decisions:
  Stop and discuss with the user first
```

**Rule:** External feedback — be skeptical, but check carefully.

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**Rule:** You and the reviewer both answer to the user. If the feature isn't needed, don't add it.

## Triaging Confirmed Findings (the build brief)

Before handing off, organize the confirmed findings — this triaged set *is* the brief `building-with-subagent` builds from, so it has to stand on its own:

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST (don't hand off a partial understanding)
  2. Drop anything you pushed back on successfully or that's YAGNI
  3. Group the survivors by priority for the builder:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
```

Each survivor needs the file:line it lives at and what correct looks like — a builder can't be steered mid-run, so a finding that reads as a hint won't survive the handoff. Then hand the set to `building-with-subagent`. Sequencing, testing, and regression-checking are the build's job — not this skill's.

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with the user's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve the user if architectural

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Confirmed - [specific issue] at [location]. Adding it to the build brief."
✅ "Verified against [X]. Real bug. Going into the brief."

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
❌ "Fixed it" / "Let me implement that now" (this skill doesn't implement)
```

**Why no thanks:** State the technical conclusion. The confirmed finding goes into the brief; the brief and the eventual diff show you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the verified conclusion instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Adding it to the brief."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Going into the brief."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just acknowledge |
| Implementing from this skill | STOP at evaluation — hand confirmed findings to `building-with-subagent` |
| Blind acceptance | Verify against codebase first |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Handing off partial understanding | Clarify all items before handing off |
| Can't verify, proceed anyway | State limitation, ask for direction |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## After a Confirmed Finding

When a finding turns out to be a real bug or missing-logic gap — not just this instance, but a class that could recur — fixing the one instance isn't enough.

This is a separate axis from the `building-with-subagent` handoff: the build addresses *this* instance, while `preventing-recurrence` guards against the whole *class*. Do both.

**REQUIRED SUB-SKILL:** Invoke `preventing-recurrence` to route the lesson into a durable mechanism (a hook, a skill/reviewer edit, a project instruction, or memory) so the same class is caught automatically next time. Tell it the defect was caught *at review* — that biases the fix one phase upstream (build/TDD, or a `/code-review` pass).

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then hand off — never implement straight from review.

No performative agreement. Technical rigor always.

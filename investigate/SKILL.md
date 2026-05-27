---
name: investigate
description: Investigate issues from logs, error messages, or normal user bug reports by explaining end-user impact and identifying likely code-level causes. At the end, consolidate test coverage for the affected code path and state what test should have caught the issue.
---

# Investigate

## Goal

Turn logs/errors/bug reports into:

- High-level issue behavior from an end-user perspective.
- Exact code locations that most likely cause the issue.
- A testing-coverage summary for the affected code path, including the missing test that should have caught it.

## When To Use

Use this skill when:

- The user provides error text, stack traces, logs, or exceptions.
- The user reports incorrect behavior without logs (for example: "clicking save does nothing", "I get signed out randomly", "search results are wrong").
- The user asks "what is causing this?" or similar diagnosis questions.
- The user has not asked for implementation steps, fixes, or refactors yet.

Prefer this skill by default when the input is primarily diagnosis-oriented (logs/errors or behavioral bug reports) and no implementation is requested.

## When Not To Use

DO NOT USE this skill for follow-up questions by the user or general questions during a conversation.

## Output Format

Always structure the response using these sections in order:

---

**Branch context** *(omit this section entirely if on `main` or if the issue is unrelated to branch changes)*
One sentence on what changed on this branch that is relevant to the issue.

---

**What the user experiences**
Two to four sentences in plain language: what breaks, when it breaks, and how severe it is. No jargon. Write as if explaining to a product manager.

---

**Root cause**
One focused paragraph identifying the exact file, function, and condition responsible. Quote the minimal relevant snippet inline. Explain directly why those specific lines cause the observed failure — no hedging unless evidence is genuinely weak.

---

**Confidence** — `high` / `medium` / `low`
One sentence on confidence level. If medium or low, one sentence on what's missing or assumed.

---

**Test coverage**
Two to three sentences: what tests currently cover this path, what's missing, and the exact test that should have caught this. Be specific — name the test file or describe the test case precisely.

## Investigation Workflow

1. Check branch context first:
   - Determine the current git branch.
   - If branch is not `main`, ask the user whether the issue is tied to this branch's changes.
   - If user confirms yes, explicitly track this as `Branch context` and prioritize code paths changed on that branch during diagnosis.
   - If user says no, proceed as usual without branch-scoped assumptions.
   - For branch context, summarize the branch changes using a subagent as a caveman.

2. Parse available signal (logs OR user report):
   - If logs/errors exist: extract error class/type, message, stack frames, and correlated context (request IDs, endpoint, job, tenant, user action).
   - If only a bug report exists: extract user action, expected behavior, actual behavior, reproducibility hints, and impacted surface.
   - Normalize both into a "symptom -> trigger -> likely failing path" chain.

3. Build user-impact narrative:
   - Translate technical failure to user-visible behavior.
   - Identify common trigger scenarios.
   - Distinguish hard failures vs partial degradation.

4. Map signal to code using subagent:
   - Find the exact symbol/function and smallest branch/condition causing the behavior.
   - Cite only the minimal root-cause snippet.
   - Do not cite logging lines, exception construction/raising lines, or wrapper handlers unless they are the direct root cause.

5. Consolidate test coverage with a subagent:
   - Launch the `feature-test-coverage-analyst` subagent once likely affected files/symbols are identified.
   - Ask it to return:
     - Existing tests covering this behavior, grouped by test type.
     - Missing coverage tied to the diagnosed root cause.
     - The most appropriate "should-have-existed" test that would have caught this issue earlier.
   - Incorporate this output into the final `Testing coverage for this issue` section.

6. Return diagnosis:
   - Do not implement fixes.
   - If needed, suggest 1-2 next validation checks briefly.

## Quality Bar

- Be concrete; avoid generic "could be many things" phrasing.
- Anchor every claim to either a log detail or a code snippet.
- Keep user-impact language understandable to non-developers.
- If evidence is weak, say so explicitly and lower confidence.
- Ensure the final response always includes concrete testing coverage status and the missing preventative test.

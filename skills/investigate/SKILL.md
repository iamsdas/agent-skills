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

Go deep: don't stop at "X is out of sync" or "Y is missing." Explain the chain — what triggered the state, why the system enforces it this way, and what invariant was violated. For example: not just "uv.lock is out of sync" but *why* it got out of sync (e.g. pyproject.toml was modified without re-running `uv lock`, and CI passes `--locked` which hard-fails on drift). The root cause is the action or omission that created the bad state, not the symptom that surfaced it.

---

**Relevant commits** *(omit if no recent commits are directly related)*
Bullet list of commits that introduced or relate to the issue: `hash` — Author, Date — summary. One sentence on what each commit changed and why it's relevant.

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
   - For branch context, summarize the branch changes using a `code-explorer` subagent asked to respond as a caveman (terse summary).

2. Parse available signal (logs OR user report):
   - If logs/errors exist: extract error class/type, message, stack frames, and correlated context (request IDs, endpoint, job, tenant, user action).
   - If only a bug report exists: extract user action, expected behavior, actual behavior, reproducibility hints, and impacted surface.
   - Normalize both into a "symptom -> trigger -> likely failing path" chain.

3. Build user-impact narrative:
   - Translate technical failure to user-visible behavior.
   - Identify common trigger scenarios.
   - Distinguish hard failures vs partial degradation.

4. Map signal to code using a `code-explorer` subagent:
   - Find the exact symbol/function and smallest branch/condition causing the behavior.
   - Cite only the minimal root-cause snippet.
   - Do not cite logging lines, exception construction/raising lines, or wrapper handlers unless they are the direct root cause.

5. Check git history for relevant commits using a `code-explorer` subagent:
   - Search recent commits for changes to the files/symbols identified in the root cause.
   - Look for commits that: introduced the bug, modified the affected logic, or touched related code paths.
   - Include the commit hash, author, date, and one-line summary for each relevant commit.
   - Note if the issue was introduced in a recent commit vs. long-standing behavior.
   - Incorporate findings into the **Root cause** section or add a brief **Relevant commits** sub-section if noteworthy.

6. Consolidate test coverage with a `tests-analyzer` subagent:
   - Launch once likely affected files/symbols are identified. Pass the affected file paths and the diagnosed root cause as context.
   - Ask it to return:
     - Existing tests covering this behavior, grouped by test type.
     - The most appropriate "should-have-existed" test that would have caught this issue earlier.
   - Incorporate this output into the final `Testing coverage for this issue` section.

7. Return diagnosis:
   - Do not implement fixes.
   - If needed, suggest 1-2 next validation checks briefly.

## Quality Bar

- Be concrete; avoid generic "could be many things" phrasing.
- Anchor every claim to either a log detail or a code snippet.
- Keep user-impact language understandable to non-developers.
- If evidence is weak, say so explicitly and lower confidence.
- Ensure the final response always includes concrete testing coverage status and the missing preventative test.

---
name: writing-plans
description: Use when requirements are already settled — an agreed scope, a spec, or a clear task — and some large work needs to be broken into concrete code-change tasks before a builder starts.
---

# Writing Plans

## Overview

Turn settled requirements into a short markdown plan: file-level changes, split into committable tasks. Scoping decided *what* and *why*. This skill decides *where in the code* and *in what order*, then hands the file to `building-with-subagent`.

**Assumes scoping is done.** Open product decisions or design forks still in the requirements → route to `scope-requirements`. Planning on unsettled requirements gets thrown away.

## Planning Discipline

**Sense-check before decomposing.** Does this change belong where the requirements imply? Ask: is this the third copy of something that wants to be one thing? Does an existing module already own this responsibility? Does the requirement fight the current design — and is the real task fixing the design? Say so in **Decisions & risks**, and plan the structural fix instead of another parallel branch. Cheapest moment to catch a wrong shape is before a builder commits it.

**Right abstraction beats fewest lines.** Same concept implemented a third time → extract it, even if extraction is more code than another copy. Judge by concepts, not line count: one concept with several call sites wants one implementation; two concepts sharing a shape want to stay apart. Extract what exists now — never build a seam for a caller that doesn't exist yet.

**Plan the leanest thing that works.** Plan is where over-engineering enters; builder only builds what you specify. Every task, abstraction, dependency earns its place now, not speculatively. Prefer stdlib → native platform → installed dependency. Never a new dependency for what a few lines do. No config for a value that never changes. Not corner-cutting: never plan away input validation at trust boundaries, error handling that prevents data loss, security, or accessibility.

**Point to code, don't write it.** Exact paths, line numbers for modifications, name the pattern to follow at `file:line`. Builder reads real code. No code blocks.

**Enumerate every parallel implementation.** List every sibling call site of the changed code — sibling handlers, same operation for another entity or platform, copy-pasted branches — each with `file:line`. Change one, change all. Non-negotiable. Three or more siblings is also the abstraction signal above.

**Split into committable tasks.** One coherent slice each: passing scoped tests, one commit, reviewable as one diff. Split where guidance genuinely changes (different subsystem, different pattern) or where a task got too broad to review in one pass. Most plans: 3–7 tasks. No write-test / run-test / implement micro-steps — state TDD expectation once.

**Keep it skimmable.** Task line says *what* and *where* in a sentence or two, then stops. Rationale, rejected alternatives, caveats live once in **Decisions & risks**.

## Process

1. **Read the change site.** Files the requirements touch, patterns they follow, every parallel call site. Whole research budget — don't provision subagents to plan a localized change.
2. **Sense-check the shape.** Does the change belong here, or is the real fix structural (see **Planning Discipline**)? If structural, plan that and record why in **Decisions & risks**.
3. **Write the plan** to `<feature-name>-plan.md` (kebab-case) — project's plans directory if one exists, else scratchpad. See **Plan Contents**.
4. **State the scope read** in 3–4 lines: coverage, task count, anything deliberately deferred, any structural call from step 2. Then continue — don't stop to ask.
5. **Check for a systemic planning gap.** A *class* of case planning should have caught (e.g. "we keep missing sibling call sites") → invoke `preventing-recurrence`, tell it the gap was caught *at planning*.
6. **Hand off.** Invoke `building-with-subagent` with the plan file path. Do not build here.

**Red flag — STOP if you catch yourself** opening a file to edit, writing a test, or running a plan step once the plan is written. You skipped the handoff. Invoke `building-with-subagent`.

## Plan Contents

One markdown file, readable in a minute:

1. **Goal** — one sentence of what changes, 2–3 sentences of approach.
2. **Tasks** — files to create/modify/test, exact paths (line numbers for modifications), one or two sentences per file (test-first, pattern to follow at `file:line`, sibling sites changing in lockstep), exact verify command and expected outcome, commit message.
3. **Decisions & risks** — non-obvious choices, rejected alternatives, structural calls, risks. One line each. "None — straightforward implementation." if none.
4. **How we'll know it works** — user-visible proof.

## Red Flags in a Plan

Never write these — each is a plan failure:

| In the plan | Why it fails |
|---|---|
| "TBD", "implement later", "add appropriate error handling", "handle edge cases" | Builder can't act on it, won't ask. |
| "Write tests for the above", no file or reference pattern | Tests that match nothing in the codebase. |
| "Similar to Task N" | Tasks get read out of order. Repeat the pointer. |
| A task changing one path, siblings untouched | List every parallel site by `file:line`. |
| A fourth copy of an existing concept | Extract instead; more lines is fine. |
| What without where | Exact `file:line` required. |
| Code blocks | Describe and point. |
| Micro-step checklists | State TDD expectation once. |
| A goal only statable with "and" between distinct concerns | Too broad — split at the seam. |
| Speculative scope, or a new dependency for what a few lines do | Over-engineering enters here, not at build time. |
| A task line over ~two sentences, or carrying its own rationale | Move to **Decisions & risks**. |

## Integration

**Upstream:** `scope-requirements` (agreed scope), `writing-specs` (settled spec), or a clear task with known desired behavior. Vague or unsettled → back to `scope-requirements`.

**Downstream:** `building-with-subagent` — always. It owns worktree isolation, builder, PR, review.

**Skip this skill** for a single obvious edit at a known site, or when the upstream artifact already carries file-level tasks (spec from `writing-specs`, triaged findings from `receiving-code-review`). Those go straight to `building-with-subagent`.

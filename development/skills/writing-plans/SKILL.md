---
name: writing-plans
description: Use when you have a clear spec or requirements for a multi-step coding task, and the user wants to plan out the final implementation details before building.
---

# Writing Plans

## Overview

Produce **one self-contained HTML file** that is both the human's approval artifact and the complete spec handed to the builder. The human opens it in a browser, sees the plan laid out with clear visualizations, and approves. The builder (a single subagent, dispatched by `building-with-subagent`, which owns the model choice) reads the same file and builds everything from it. One artifact, one approval, one handoff.

This skill is deliberately lean — it is light enough to run on Fable. Plan directly: read the change site, trace the patterns, write the HTML. There is no architecture tournament, no multi-agent exploration pass, no separate markdown doc. If you catch yourself provisioning subagents to plan a localized change, stop.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Never build here.** This skill writes the plan and stops. Once the human approves, hand off to `building-with-subagent` — do not start editing files, writing tests, or running steps in this conversation.

## Planning Discipline

**Plan the leanest thing that works.** The plan is where over-engineering is *introduced* — the builder just builds what you specify. Every task, abstraction, and dependency must earn its place: does it need to exist *now*, or is it speculative? Cut speculative scope or mark it explicitly deferred. Prefer the stdlib, then native platform features, then an already-installed dependency — never plan a new dependency for what a few lines do. No abstraction with a single caller, no config for a value that never changes, fewest files that hold the responsibilities cleanly. This is design discipline, not corner-cutting — never plan away input validation at trust boundaries, error handling that prevents data loss, security, or accessibility. DRY. YAGNI. TDD. One commit per task.

**Point to code, don't write it.** The plan gives exact file paths and line numbers and names the pattern to follow — the builder reads the actual code. No code blocks in the plan.

**Keep it skimmable — concision is a requirement, not a nicety.** The human approving this reads it in a browser; a wall of dense prose defeats the artifact. Each task line states *what* and *where* in a sentence or two, then stops. The *why* — rationale, rejected alternatives, caveats, trade-offs — lives once in **Key decisions & risks**, never woven inline into every file line. The builder reads the real code; trust the pointer instead of narrating around it. No parenthetical asides stacked three deep, no restating a decision inside the task that the decisions section already carries. If a task line runs longer than about two sentences, you're writing prose the reviewer has to wade through — cut it or move the reasoning down.

**Enumerate every parallel implementation.** As you map files, list every duplicate/sibling call site of the code being changed — sibling handlers, the same operation for another entity or platform, copy-pasted branches (file:line each). A change that touches one must touch all of them. This completeness check is non-negotiable.

**Split into committable tasks.** Each task is one coherent slice that ends in a passing test suite and a commit, and stays reviewable as a single diff. Split where the guidance genuinely changes (different subsystem, different pattern, a checkpoint worth reviewing) or where one task has grown too broad to review in one pass. Most plans land at 3–7 tasks; a broad feature needs more. Don't split into write-test / run-test / implement micro-steps — state the TDD expectation once.

## Process

1. **Scope read.** Determine whether the spec covers multiple independent subsystems or is large enough to sequence into separately-shippable stages; propose a split if so. Read the change site and its patterns, and enumerate parallel implementations. State the scope read to the user in 2–3 lines, then proceed — don't stop to ask.
2. **Write the HTML plan** to `<feature-name>-plan.html` (kebab-case). Default location: the project's plans directory if one exists, else the scratchpad directory. See **HTML Plan** for its contents.
3. **Get approval.** Present the file path and open/point the user to it. Ask for approval using the `AskUserQuestion` widget — always the widget, never a plain-text question the user has to notice and reply to. One question ("Approve plan?") with options like "Approve — proceed to build" and "Request changes" (they can pick "Other" to type specifics). If they request changes, revise the HTML and ask again. Do not hand off until approved via the widget.
4. **Check for a systemic planning gap.** If refinement exposed a *class* of case the plan dropped that planning should have caught (e.g. "we keep missing concurrency"), invoke the `preventing-recurrence` sub-skill and tell it the gap was caught *at planning*, so the fix lands in the planning machinery.
5. **Hand off.** Invoke the `building-with-subagent` skill, passing the plan file path. Do not build here.

**Red flag — STOP if you catch yourself:** opening a file to edit, writing a test, or running a plan step right after the plan is approved. That means you skipped the handoff. Invoke `building-with-subagent` instead.

## HTML Plan

One self-contained `.html` file — inline all CSS; no external fonts, scripts, or network requests. It must read cleanly for a human skimming in a browser **and** point the builder to everything it needs. Lean toward the shortest version that still lands every pointer; when in doubt, cut. Structure it top-to-bottom:

1. **Header** — feature name, one-sentence goal, 2–3 sentence approach.
2. **Visual overview** — the plan's payoff over a markdown doc. Show *structure* the builder can't infer cheaply from prose, drawn as inline HTML/CSS/SVG (self-contained, no mermaid, no MCP, no external service):
   - **Control flow / sequencing** when non-obvious (multiple actors, async, retries).
   - **Architecture / module boundaries** — boxes showing how the touched pieces connect.
   - **Data model / schema** changes — entity boxes with fields and relationships.
   - **State machines** — states as nodes with labeled transitions.

   Draw only what carries structure prose can't — skip diagrams for a two-step linear flow or a single-file change.
3. **Task breakdown** — the builder-facing substance, kept tight. For each task: the files to create/modify/test (exact paths, with line numbers for modifications), what to do in a sentence or two per file (test-first, referencing the pattern to follow at file:line and the sibling call sites that must change in lockstep), the exact verify command with its expected outcome, and the commit message. No code blocks — describe and point. Push rationale, alternatives, and caveats down into **Key decisions & risks**; a task line is an instruction, not an essay.
4. **Key decisions & risks** — non-obvious choices, rejected alternatives, risks worth flagging. One line each. "None — straightforward implementation." if there are none.
5. **How we'll know it works** — the overall user-visible proof.

**Task-content rules** — these are plan failures, never write them:
- "TBD" / "implement later" / "add appropriate error handling" / "handle edge cases"
- "Write tests for the above" without a specific file and reference pattern
- "Similar to Task N" — repeat the pointer; tasks may be read out of order
- A task that changes one path while leaving its siblings untouched — list all parallel sites by file:line
- A task that says what without where — exact file:line required
- Code blocks — describe what to build and where to look, not what to write
- Micro-step checklists — state the TDD expectation once, let the builder sequence it
- Over-broad tasks — a goal you can only state with "and" between distinct concerns; split at the seam
- Speculative scope, or a new dependency for what the stdlib / a native feature / a few lines already do
- A task line longer than ~two sentences, or one carrying its own rationale/rejected-alternatives/caveats — that reasoning belongs in **Key decisions & risks**; the task line just says what and where
- Stacked parentheticals and inline asides — one clause deep, then stop

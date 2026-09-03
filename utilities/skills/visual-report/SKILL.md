---
name: visual-report
description: Use when someone outside the codebase needs to understand what was done or how something works - a report for a manager, client, stakeholder, or non-engineer teammate, or any request for a summary, recap, or explainer that gets shared rather than read in the terminal.
argument-hint: 'What should the report cover, and who is it for?'
---

# Visual Report

## Overview

Produce **one published Claude Artifact** that explains a body of work to someone who will never open the code. The reader wants to know what is true now, what it means for them, and roughly how it works. They do not want the build log.

**Announce at start:** "I'm using the visual-report skill to build the report."

**Required sub-skills:** load `artifact-design` before writing the file (the Artifact tool requires it), `artifact-diagramming` if the report carries diagrams, and run `unslop` over the finished prose.

**This skill only reports.** It does not fix, refactor, or extend the thing it describes. If gathering turns up a real problem, note it in one line and keep writing.

## Write for Someone Who Isn't an Engineer

Assume a smart reader with no context on the repo, the stack, or the team's vocabulary. Say what a thing does in the words the reader already owns.

Cut on sight:

- File paths, function and class names, config keys, error strings, branch names
- Numbers only an engineer reads: line counts, test counts, coverage, bundle size, latency in ms
- Anything the reader cannot act on or repeat to a colleague

Two checks before a sentence ships. Would a smart outsider understand every word? And does the sentence say something about *this* work, or would it fit unchanged in any other report? If it is generic, cut it.

## Ignore the Order Things Happened In

The reader does not care about the path, only the destination. No commits, no PRs, no ticket or task numbers, no phases, no "first we, then we, finally we". A report organised as a timeline is the default failure of this skill.

Group by outcome instead: one section per capability, per area of the product, or per question the reader would actually ask. Something that took three weeks across nine commits gets one section if it is one idea. Something built in ten minutes gets its own section if the reader cares about it.

Structure, top to bottom:

1. **Headline.** One sentence naming what is true now that wasn't before.
2. **At a glance.** Three to five tiles carrying the facts that hold the story. Plain-language facts, not engineering metrics.
3. **The substance.** One section per outcome: what it is, what changes for the reader, and a visual.
4. **Worth knowing.** Limits, open questions, what comes next. One line each, and only if real.

## Make the Visuals Do the Explaining

This is the whole point of the artifact. A reader skimming the page should get the story from the visuals alone, with the prose as backup. Every section in **The substance** earns one.

Draw everything as inline HTML, CSS, and SVG in the artifact itself. Self-contained: no external images, no charting library, no service round-trip.

What tends to work:

- **Before and after,** side by side. The strongest visual in most reports, because it is the reader's actual question.
- **A journey,** drawn as the steps a person moves through, with the changed step marked.
- **A comparison,** where a number only means something next to another number.
- **A labelled picture of the thing itself,** a mock of the screen or the document, with callouts.

What to refuse:

- A visual that restates its own heading in a box
- A chart of a single number. That is a tile.
- Architecture diagrams, module boundaries, schemas, sequence diagrams. Those are engineering pictures for an engineering audience, and this reader is not it.
- Decoration with no information in it

## Process

1. **Establish what is actually true.** Read the diff, the docs, the running product, this conversation. Get the facts first; the report is worthless if it flatters.
2. **Fix the audience.** If the user hasn't said who reads this and what they want out of it, ask once with `AskUserQuestion`, then proceed. Everything downstream depends on the answer, so it is worth one question.
3. **Translate.** For each finding, write the one line a non-engineer would repeat to a colleague. If you can't write that line, the finding probably doesn't belong in the report.
4. **Load `artifact-design`,** then write the HTML to the scratchpad directory as `<subject>-report.html`.
5. **Run `unslop`** over every sentence in the file before publishing.
6. **Publish** with the Artifact tool and hand the user the link, plus a two-line summary of what the report says.

## Red Flags

| If you catch yourself writing… | Do this instead |
|---|---|
| "First, we… Then… Finally…" | Regroup by outcome. Delete the sequence. |
| A commit, PR, ticket, or task number | Cut it. Name the outcome it produced. |
| A file path or function name | Say what that code does for the reader. |
| A box-and-arrow architecture diagram | Draw before/after, or the user's journey. |
| "This is a comprehensive overhaul of the platform" | Say the one concrete thing that changed. |
| A section with prose and no visual | Draw the visual, or fold the section into another. |
| A paragraph that would fit any project's report | Delete it. It carries nothing. |

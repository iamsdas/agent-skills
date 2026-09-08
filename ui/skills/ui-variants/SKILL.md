---
name: ui-variants
description: Use when someone wants to see options for a piece of UI before committing - "show me a few versions of this", "what are some ways to lay this out", "I want to explore designs for X", or when a UI decision is being argued in the abstract and pixels would settle it.
---

# UI Variants

## Overview

One self-contained HTML file, written to disk and opened in the browser, showing
several genuinely different takes on one piece of UI, so a decision gets made by
looking instead of imagining.

**Generating variants is easy; making them decidable is the job.** A strong
model already produces different layouts. What it skips is everything that turns
a gallery into a decision.

## When Not to Use

- The answer is known — build it.
- The question is about behavior, not appearance — prototype the interaction.
- Only one option is viable — say so, don't manufacture three.
- They said it looks wrong — that's `diagnosing-ui`. Variants come after the
  cause is named, if at all.

## What Counts as a Variant

**Vary the concept, not the paint.** Different accent color, radius, or copy is
one variant rendered twice. A real variant changes at least one of:

- **Layout** — centered vs. split vs. inline vs. full-bleed
- **Hierarchy** — what's largest, what's first, what's hidden
- **How much the UI decides for the user** — defer, suggest, or choose
- **How much is on screen** — minimal prompt vs. the whole catalog

Name the axis they span in one sentence before building. If you can't, they
aren't different enough.

**Three to five.** Fewer doesn't span the space; more stops being comparable.

## Required Elements

Each came from a version that felt complete and wasn't.

**A recommendation**, at the top. Burying your opinion makes the reader redo
work you already did.

**A tradeoff line under every card** — build cost, what it assumes, when it
stops working. Not one paragraph at the bottom.

**Part labels.** A toggle outlining each swappable block with an id
(`v2.header`, `v3.picks`), so "variant 4's layout with variant 3's cards" is
sayable instead of gestural.

**Real context.** Render each inside the chrome it will really sit in. A
component judged floating on a blank page is judged wrong.

**Adjacent states.** Loading, error, one item, fifty, filtered-to-nothing, a
long string. The variant that wins on the happy path often loses here — the
finding worth having before you build.

**Real copy.** Filler hides the decision; headlines often *are* the decision.

**Both themes**, switched the way the repo switches them. With no repo: tokens
on bare `:root`, overridden under `prefers-color-scheme: dark` guarded with
`:not([data-theme="light"])`, and again under `[data-theme="dark"]`.

## Comparison Controls

A small fixed toolbar:

| Control | Why |
|---|---|
| Side-by-side ↔ one-at-a-time | Grid for the first pass, full width for the second — a split layout misleads in a half column |
| **Pick any two, full width** | The comparison you want by round two; a grid can't do it |
| Light / dark | |
| Part labels on/off | |

## In an Existing Codebase

Copy the repo's real token block, fonts, and control metrics into the page. A
variant styled with generic defaults isn't evaluable — you'll pick one, build
it, and find it looks nothing like the mockup.

If a repo convention rules a variant out, say so on the card rather than
silently not building it.

## Before You Finish

| Mistake | Fix |
|---|---|
| Variants differ by color, radius, or copy | Change layout or hierarchy, or drop it |
| Can't state the axis they span | Redesign the set, not the cards |
| No recommendation | Say which and why, at the top |
| Tradeoffs in one block at the bottom | Move them under each card |
| Happy path only | Add loading, error, empty, overflow |
| Floating on a blank page | Wrap in the real surrounding chrome |
| Grid only | Add pick-any-two at full width |
| Generic tokens inside a real repo | Copy the repo's token block |
| Lorem or plausible filler | Write the copy you'd ship |

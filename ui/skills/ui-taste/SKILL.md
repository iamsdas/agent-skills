---
name: ui-taste
description: Use when building, redesigning, or composing a screen, page, panel, card, dashboard, or component - deciding what goes on it, what leads, and how much - rather than a one-line style tweak. Also the standard that diagnosing-ui and ui-variants judge against.
---

# UI Taste

## Overview

UI an agent builds usually works and still looks generated. The cause is rarely
a wrong value; it's a missing decision about what the screen is for.

**The one idea: it reads as a real product made by someone who cares, the eye
lands in one place, and every element is there for a reason.**

This skill is composition, not code. Values, classes and tokens belong to
`ui-conventions`. When the two disagree, the repo's conventions win on values;
this skill wins on what is on the screen and how much weight it gets.

## Four Ways It Fails

- **Too much.** Detail in every row, numbers everywhere, a border and a badge on
  everything. The more there is, the more it looks generated.
- **Flat.** Every object the same weight in the same bordered card. The eye has
  nowhere to land.
- **Generic.** What any model would make: sparkles and purple for anything AI, a
  letter in a colored square as a logo, emoji or hand-drawn icons, an accent
  ring with a glow to mean "important."
- **Filled.** Rows spread to fill a pane, an empty band mid-screen, a card
  floating in a void. Space used up, not used.

## Principles

1. **One thing leads.** Decide what the screen is about before building. It gets
   the weight, the room, and the one big number; everything else steps back.
2. **Say it once.** A signal lives in one place, not in the header, a badge and
   every row.
3. **Decoration is earned.** Fewest surfaces first. A border, badge, gradient or
   shadow stays only if it separates, shows state, or the product already does it.
4. **Space groups.** Related things sit close, unrelated things far. Empty space
   is hierarchy; don't fill it.
5. **Simplify the words, not the context.** Cut repetition and noise, keep what
   makes the product recognizable: its imagery, its icons, its real content.
6. **Show what it does.** An AI feature shows its output, not a sparkle. A status
   shows the state, not a decorative dot.
7. **Start from the nearest good reference.** The closest existing surface in the
   repo, or a real product that does this well. Build beside it, then compare. If
   yours is emptier, flatter or busier, that's the first fix.
8. **Silhouette before details.** At thumbnail size, the subject, its support and
   the empty space should make one picture before any detail matters.

## Before You Finish

Look at the result the way the most exacting designer you know would: the one
who screenshots the single wrong thing and sends it back with "what is this?"
If you can picture that screenshot, you've found the next fix. Fix the largest
first: what leads, then grouping, then decoration, then polish.

| You see | Do |
|---|---|
| Can't say in one sentence what the screen is about | Decide before touching layout |
| Everything in a card | Remove cards until grouping comes from space |
| Same fact shown twice | Keep the clearest one |
| Sparkle, wand, or purple meaning "AI" | Show the AI's result instead |
| Glow ring around the important thing | Lift it with size, surface or position |
| Stretched rows or a void | Size to the content; let the space be space |

Adapted from the principles in Benji Taylor's Stageshow (MIT).

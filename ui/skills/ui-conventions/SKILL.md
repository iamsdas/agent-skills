---
name: ui-conventions
description: Use when about to write or edit any styling in an existing codebase - CSS, a stylesheet, utility classes in markup, or a styled component - for a page, a component, a button, a form field, a modal, a hover state, or a transition.
---

# UI Conventions

## Overview

A mature codebase has already extracted a vocabulary — a button class, a field
wrapper, a token file. Generic CSS written next to it looks wrong, duplicates
what exists, and sometimes silently breaks.

**The failure is always the same shape: reaching for a generic default instead
of reading what the repo already extracted.** The generic default is genuinely
what comes to mind first; this skill puts a read in between.

**Before writing CSS, find what already does this job.** Cheapest first — a
change made at step 5 when step 3 was available is itself a defect:

**Delete → Use the platform → Reuse the project's vocabulary → Correct a value →
Add**

Step 3 is where almost every miss happens.

## Before You Write

If the repo's `CLAUDE.md`, its own skills, or stylesheet headers already answer
these, read those instead. Otherwise, five greps, ~90 seconds. Swap the
extensions for the stack's. **Quote every glob** — in zsh an unquoted
`--include=*.css` dies with `no matches found` before grep runs, which reads as
"no token file exists" and is the most expensive possible wrong answer.

| Question | How |
|---|---|
| **Does this already exist?** | `grep -rni '<feature noun>' --include='*.css' --include='*.tsx'` — best outcome is learning you needn't write most of it |
| Token file? | `grep -rl -- '--[a-z-]*:' --include='*.css'`, read it whole. Often more than one — motion tokens live apart from color |
| What owns buttons? | `grep -rn '\.btn\b\|<Button' --include='*.css' --include='*.tsx' \| head` |
| What owns fields? | A `field`/`input`/`form` stylesheet **and** its React wrapper |
| **Is my prefix taken?** | `ls styles/` then `grep -rn '\.myprefix-'` — collide and you restyle a live surface |

Then read the header comments of the files you found and the one you're editing.
They usually name the rule, the rejected alternative, and the test enforcing it.

**Look outside stylesheets.** The vocabulary worth reusing is often a shared
data registry, a typed React wrapper handling `id` association, or a test suite
defining what correct means here.

## Hard Rules

**Never invent a value that exists as a token.** A literal is a defect even when
it renders identically today — it diverges the moment a theme changes. The
enforced rule usually targets literal *arguments*: `rgba(var(--tint), .06)`
passes, `rgba(0, 0, 0, .5)` fails. Paired-theme checks run both directions.

**Never invent a class when a vocabulary class exists.** Existing ones are often
deliberately over-specified to win a cascade fight. Yours loses it and renders
as something you didn't design.

**Never assume your transition is needed.** Many codebases transition common
properties globally via one grouped selector list you should join, not bypass.

**Match the comment density of the file you're editing**, and check both themes.

## Project Specifics

Repo vocabulary belongs in that repo, not here. Two things enforced silently in many repos: a test banning color literals
outside a token file, and a stylesheet import list where **order is the
cascade**. That list may also be exhaustively tested — a new file that isn't
imported is a red build, not a style nit.

## Before You Finish

| Mistake | Fix |
|---|---|
| Hardcoded color, duration, easing | Use the token; add to *every* theme block if missing |
| New button/field class | Use the existing one — yours loses the specificity fight |
| Stylesheet appended to the end of an import list | Position it for the cascade; say why. Check it isn't also a tested set |
| Prefix collides with an existing file | Grep first, pick another |
| Added a transition | Confirm one isn't already global |
| Uncommented rules in a commented codebase | Explain the choice and the rejected alternative |
| Invented a container the repo doesn't use | Copy the nearest existing surface |
| New file in a directory that doesn't exist | Put it where its siblings live |

---
name: diagnosing-ui
description: Use when someone says a piece of UI looks bad, feels off, looks cheap, looks unfinished, doesn't look right, asks why something looks worse than it should, or asks to polish, clean up, or make something look better without saying what's wrong - a perceptual complaint about appearance rather than a bug report or a request to build something new.
---

# Diagnosing UI

## Overview

Turn "this feels off" into a named problem, the mechanism, and a fix in the
codebase's own vocabulary.

**The complaint is the specification.** Anything that doesn't explain what they
reacted to is noise, however true. Thirteen findings where two are relevant
hands back the triage they asked you to do.

Not a review. No severity ladder, no coverage table, no verdict — nobody who
says "I don't like how this looks" is helped by a report ending in **Approve**.

Two reflexes to resist: enumerating everything checkable and hoping the cause is
in there, and reporting what grep can count. "The icon is too quiet to find" is
invisible to grep and is more often the answer.

## Step 1: Look First

Diagnosing a perceptual complaint from source alone is a guess. If there's a
screenshot, study it before anything else. If the app is running and you can
capture one, do that.

**The screenshot usually contains the answer.** Vagueness in the prompt is not
vagueness in the image — "feels off" plus a picture of a row whose controls are
visibly different heights is a specific complaint. Don't ask about what you can
see.

### Reading a Screenshot

Work through these against the image, not the code:

- **Squint.** Blur out detail and look at the blocks that remain. Groups that
  shouldn't be groups, and a page with no obvious entry point, show up here and
  nowhere else.
- **What does your eye hit first?** Compare it to what *should* be first. A
  mismatch is the finding.
- **Trace the alignment edges.** Pick a vertical and follow it down; pick the
  top edge of a control row and follow it across. Breaks are what "sloppy" means.
- **Measure the gaps** — within groups versus between them. The between must be
  larger. This is the single most common cause.
- **Find every control** and ask whether it looks like one. Anything that takes
  a second to locate has failed.
- **Compare against its neighbors** in the same app. "Doesn't match" is only
  visible in context.

Then read the code behind what you found, so the fix names a line.

A described rendering ("the top edges look ragged") counts as seeing it.

## Step 2: Ask What You Can't See

Two cases end in a question:

- **No screenshot, no described rendering, and can't capture one.** Ask for
  one. Don't dive into the code instead — source is where the fix lives, not
  where the complaint does.
- **The image doesn't disambiguate** — several plausible targets, or several
  plausible problems in the one they named.

**Then stop.** No findings under the question; they anchor the answer. A
candidate names a place and a possible reading, a finding asserts a cause. Offer
the first, never the second.

**Ask well** — not "tell me more," but two or three concrete readings, named as
the person sees them. With an image, draw them from it. Without one, borrow the
vocabulary of the checklist above:

> Which is it — the buttons in that row at different heights, the panel edge not
> lining up with the tabs, or the whole strip too tight?

Close with the fallback: if they can't produce a screenshot, you'll diagnose
from source, leading with that limitation and a confidence number.

## Step 3: Name It

Three parts per hypothesis. The middle one makes it worth reading.

1. **Canonical name** — not "spacing is inconsistent" but "the gap inside this
   group exceeds the gap between groups."
2. **Mechanism** — why the eye reads it as wrong.
3. **Fix in the repo's vocabulary** — the existing token, class, or value.

Cheapest first: Delete → Use the platform → **Reuse what the project has** →
Correct a value → Add.

`references/symptoms.md` maps what people say to the canonical causes. Read the
entry for what they said — it may hold several — then stop. Reading on is the
audit getting back in.

## Output

One sentence naming the likeliest cause, then each hypothesis: name, mechanism,
fix with file and line. Usually two or three.

Rank by how much of the complaint each explains, not severity. When two are
disjoint, keep the order they said them.

Bugs found in passing get **one line at the end**, unexpanded. Never end with a
verdict.

## Before You Finish

| Mistake | Fix |
|---|---|
| Asked about something the screenshot shows | Look before asking |
| Went to the code with a screenshot unread | Study the image first — it usually has the answer |
| Asked and answered in one message | Ask and stop |
| "Can you tell me more?" | Two or three concrete readings |
| Diagnosed from source without asking for a screenshot | Ask first; source-only is the fallback, led by a confidence number |
| Findings that don't explain the complaint | Cut, or one line at the end |
| Ranked by severity | Rank by how much each explains |
| "Spacing is inconsistent" | Name the problem and the mechanism |
| Fix invents a value | Use the existing token or class |
| Ends in Approve / Block / coverage table | Delete it |
| Only what grep could count | Ask what's wrong that isn't a number |

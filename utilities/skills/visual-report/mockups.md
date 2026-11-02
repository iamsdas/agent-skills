# Mockups in a Report

Rules for "a labelled picture of the thing itself": a mock of a screen, document
or flow, drawn in inline HTML/CSS/SVG. The reader should recognize the product
and see the one thing that changed.

**The one idea: a real-looking product, simplified to what the reader needs,
cropped to where the story is.**

## Content

- **Real words only on the subject.** The title, the thing that changed, its
  result: usually 3 to 7 strings. Everything else is quiet placeholder bars, and
  their widths vary row to row.
- **Bars belong at the edges, not where the eye lands.** If the focal spot is a
  gray bar, the mock reads unfinished.
- **Keep what makes it recognizable:** the product's layout, its icons, its
  imagery. Cut the words, not the context.
- **One number gets to be big.** The rest are plain lines.

## Framing

- **Crop to the panel the story happens in.** Don't shrink a whole window into
  a box with even margins on all four sides; that's a pasted screenshot, not a
  picture. Let the window run off one edge, and let only filler get cut.
- **No plate.** No tinted backdrop behind a window floating on the page.
- **What opens stays in.** A menu, popover or toast the story is about sits
  fully inside the crop.

## Before and After

- **Two crops of the same frame,** same size and position, so the changed
  element sits in the same place in both and the eye jumps straight to it.
- **Only the change differs.** If the surrounding mock also changes, the reader
  can't tell what's new.

## Callouts

- **One per change,** a short label with a thin leader to the exact element.
- Callouts sit in the margin, never on top of the thing they explain.

## Avoid

- Sparkles, wands, or purple to mean "AI"; show what the AI produced instead.
- Invented logos (a letter in a colored square). Use a plain text wordmark.
- Emoji or hand-drawn icons standing in for real ones.
- An accent ring with a glow to point at something; use a callout.
- Different shadows, radii or backgrounds from mock to mock. One figure
  language across the whole report.

If the user asks for an animated product demo rather than a report figure, that
is the `stageshow` skill's job, not this one.

Adapted from Benji Taylor's Stageshow (MIT).

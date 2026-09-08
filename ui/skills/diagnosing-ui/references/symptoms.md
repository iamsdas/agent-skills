# Symptom Catalog

What people say → the canonical cause → the mechanism → what to change.

Check grouping first — it's the most common cause and hides behind several of
the words below. Then read the entry for what they said, and stop. Working down
the rest is the audit reflex this skill exists to prevent.

---

## Check First: Grouping

The gap between groups must exceed the gap within a group. A common ratio is 2:1
— 8px within, 16px or more between.

Violated, the eye parses boundaries the design didn't intend, and the person
says cramped, cluttered, or hard to scan without being able to say why. Two
attach buttons and a Run button at one uniform gap read as three peers rather
than a pair plus the primary action.

**Change:** measure the two gaps. Make the between-group gap larger. Usually the
within-group value is already right and only the boundary needs to grow.

---

## "cramped", "too tight", "suffocating"

**Padding smaller than the gap between children.** A container whose inner
padding is less than the space between the things inside it reads as though the
content is escaping the box. The eye takes the smallest gap as the unit of
rhythm, so a 16px gap inside 8px padding makes the padding look like an error.

Also: text touching a boundary. Any glyph within a few px of a border or edge
reads as clipped even when it isn't.

**Change:** padding ≥ the largest internal gap. For text, no less than the
line's own descender space between the baseline and any edge.

---

## "cluttered", "noisy", "busy"

Usually one of three, in this order of likelihood:

**Everything at full strength.** Every element at maximum contrast, weight, or
saturation means nothing recedes. A dense interface reads calm only when most of
it is quiet.

**Borders doing whitespace's job.** Boxing each group draws N rectangles the eye
must parse before reading anything. Space groups as well and costs no ink.

**Too many competing weights.** Three or more type weights, or three or more
surface elevations, in one view leaves no clear rank.

**Change:** demote everything not primary — one step down in contrast or weight.
Replace at least one border with space.

---

## "doesn't look clickable" / "I didn't see the button"

**The control is indistinguishable from content.** Usually a transparent
background plus muted text plus a low-contrast border — the border is the only
thing carrying "this is a control," and if it's below roughly 1.4:1 against its
own surface, it stops registering as an edge.

Watch for a border token tuned for one surface being used on another. A hairline
correct over the page background can vanish on a raised panel.

**Change:** a control-chrome border token if the project has one, or a fill. Give
it a hover state — a control that never changes under the cursor reads as text.

---

## "sloppy", "unpolished", "amateur"

**Misalignment the eye catches before it can name.** Three flavors:

**Ragged edges from mismatched heights.** Controls on one row at different
heights, aligned on one edge, disagree on the other. The eye locks onto the
strongest horizontal available; when the tops disagree by more than a couple of
px, bottom-alignment isn't strong enough to carry it.

**Radii that don't nest.** A rounded box inside a rounded box needs
`outer = inner + padding`. Get it wrong and the gap between the two curves
varies around the corner, which reads as a wobble. Past ~24px of padding, treat
them as separate surfaces instead.

**Optical vs. geometric centering.** Triangles, and most icons with visual mass
off-center, need a nudge to look centered. A play triangle centered
mathematically looks left-heavy.

**Change:** one height for all controls on a row. Concentric radii. Nudge
optically, trust the eye over the number.

---

## "cheap", "generic", "looks like a template"

**Uniform treatment applied without discrimination.** One radius on everything
regardless of hierarchy, one shadow under every surface, one weight for every
heading. Uniformity reads as a default rather than a decision, because it is one.

Common tells: identical rounded cards chopping up unrelated content; a soft grey
shadow on everything; tracked-out all-caps eyebrow labels; a `→` appended to
button text; gradient washes as decoration.

**Change:** vary by hierarchy — a page-level surface and an inline chip should
not share a radius. Pick one element to be the memorable one and quiet
everything around it.

---

## "hard to scan", "I don't know where to look"

**No clear entry point.** Every item at equal visual weight gives the eye
nowhere to start, so it starts at the top-left and reads everything, which for
a list is the wrong behavior.

**Or: grouping gaps that don't match logical grouping.** See the top entry.

**Change:** one element clearly heaviest. In a list, make the identifying field
dominant and demote the metadata.

---

## "doesn't match the rest of the app"

**The design system was bypassed.** A new class where a vocabulary class exists,
a literal where a token exists, a component hand-rolled where the library has one.

Frequently invisible in isolation and obvious in context — the screen looks fine
alone and wrong next to its neighbors.

**Change:** find what the neighbouring surface uses and use that. See the
`ui-conventions` skill.

---

## "wrong emphasis", "the wrong thing stands out"

**Visual weight doesn't match importance.** The primary action isn't the
heaviest element; a destructive action is as prominent as the safe one; a label
is louder than the value it labels.

**Change:** rank the elements by what the user is there to do, then make visual
weight follow that order. Labels are almost always secondary to values.

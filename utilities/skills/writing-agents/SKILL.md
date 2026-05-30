---
name: writing-agents
description: Use when creating or editing a subagent definition (an agents/*.md file), or when standardizing agent frontmatter and body structure across a plugin.
---

# Writing Agents

## Overview

A subagent definition is a single `agents/<name>.md` file: YAML frontmatter that configures the agent, followed by a system prompt that tells it how to work. This skill defines the **canonical format** so every agent in the repo reads the same way.

**Core principle:** Frontmatter configures, the body instructs. Keep the body to a fixed section vocabulary so a reader can predict where to find "how it works" and "what it returns."

## Canonical Frontmatter

Fields in this exact order. Omit optional fields rather than leaving them blank.

```yaml
---
name: kebab-case-name            # required — matches the filename
description: <one line>          # required — see rule below
tools: Glob, Grep, Read, ...     # required — comma-separated
model: haiku | sonnet | opus     # required
color: <color>                   # required
effort: low                      # optional — include only if the agent sets it
memory: project                  # optional — include only if the agent needs it
---
```

**`description` rule:** third-person, one line, capability + trigger ("Reviews X for Y. Use when Z."). **No `\n\n<example>` blocks in the description** — they bloat the system prompt and belong in the body. Move any usage examples into a `## When to Use` section.

**Don't churn behavioral knobs:** when standardizing an existing agent, never add or remove `effort` / `memory` / `model` to make files "look" uniform — those change behavior. Normalize order and wording only.

## Canonical Body

A 1–2 sentence role statement (no header), then these sections. Only `## Process` and `## Output Format` are required; include the rest when the agent needs them, in this order:

| Section | Required | Purpose |
|---|---|---|
| (role line) | ✓ | "You are …" — one or two sentences |
| `## When to Use` | — | Triggering conditions; houses `<example>` blocks moved out of frontmatter |
| `## Process` | ✓ | How the agent works — numbered steps or grouped responsibilities |
| `## <Domain sections>` | — | Cross-cutting specifics: `## Confidence Scoring`, `## Rating Guidelines`, `## When to Escalate`, `## Special Considerations`, `## Anti-Patterns` |
| `## Output Format` | ✓* | The exact structure the agent returns |

\* `## Output Format` is required for agents that return a report/analysis. Editing agents (those with `Write`/`Edit` that change code in place) may omit it and instead end with a short note on what they leave behind.

## Naming Rules

- Use **Title Case** for headers: `## When to Use`, not `## when to use`.
- **No possessives** in headers: `## Process`, not `## Your Review Process`; `## Output Format`, not `## Your Output Format`.
- Use the canonical names above instead of synonyms: `## Process` (not `Core Process` / `Core Mission` / `Analysis Approach` / `Analysis Framework`), `## Output Format` (not `Output Guidance` / `Report Format`).
- **Real headers, not bold pseudo-headers.** Use `## Process`, never `**Process:**` followed by a list.

## Common Mistakes

- `<example>` blocks left in the `description` frontmatter → move to `## When to Use`.
- Bold pseudo-headers (`**Output Format:**`) instead of `##` headers → reader and tooling can't navigate them.
- Inventing an `## Output Format` for an editing agent that produces no report → omit it instead.
- Adding `effort`/`memory` to match other files → behavioral change disguised as formatting.
- Stray closing tags (e.g. a trailing `</output>`) left in the body → remove them.

## Verification

```bash
# Frontmatter present and in order; no <example> in description
head -10 agents/<name>.md
# No possessive or synonym headers slipped in
grep -nE "^## (Your |Core Mission|Core Process|Output Guidance|Report Format)" agents/<name>.md
```

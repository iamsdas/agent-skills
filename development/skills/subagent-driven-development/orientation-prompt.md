# Orientation Prompt Template

Dispatch this **once**, before any implementation. It pays the codebase-discovery cost a single time by indexing the relevant code, the plan, and a short overview into the context-mode knowledge base. Every implementer and reviewer then `ctx_search`es that KB for the slice it needs instead of re-exploring. You pass only the **source label** to later workers — never the indexed content into your own context.

**Agent:** `development:code-explorer`. It's the specialist explorer and carries `ctx_index`/`ctx_search`; it needs no `Write`, since orientation produces no file (everything goes into the KB).

**Source label:** choose a distinctive one for this run, e.g. `orient:<feature-slug>`, and reuse it everywhere.

```
Task tool (development:code-explorer):
  description: "Orient: index codebase + plan into KB for [feature/plan name]"
  prompt: |
    You are producing a one-time orientation for a team of implementer and reviewer
    subagents who will execute the plan below. They will NOT re-explore the codebase —
    they will `ctx_search` the knowledge base you build. So index everything they need
    to work without rediscovering the code.

    ## Loading context-mode (do this first)

    The context-mode MCP tools are deferred. Call `ToolSearch` with
    "select:mcp__plugin_context-mode_context-mode__ctx_index,mcp__plugin_context-mode_context-mode__ctx_search"
    once to load their schemas, then use them.

    ## Source label (use for EVERY ctx_index call)

    [SOURCE_LABEL, e.g. orient:my-feature]

    ## Plan (the work that will be implemented)

    [FULL TEXT of the plan, or every task's description — paste it]

    ## Your Job

    1. Explore the areas of the codebase the plan touches.
    2. `ctx_index` the relevant code into the KB under the source label
       (`ctx_index(path: "<dir-or-file>", source: "[SOURCE_LABEL]")` — prefer the
       specific dirs/files the plan touches over the whole repo).
    3. `ctx_index` the full plan text under the same label
       (`ctx_index(content: "<plan text>", source: "[SOURCE_LABEL]")`).
    4. `ctx_index` a CONCISE architecture + conventions overview you write
       (`ctx_index(content: "<overview>", source: "[SOURCE_LABEL]")`) covering:
       - how the relevant subsystems fit together (a few sentences)
       - the key files and their one-line responsibilities, with `file:line` anchors
         for entry points / the seams to extend
       - conventions to follow (naming, error handling, test layout + how tests run,
         the abstractions/utilities to reuse instead of reinventing)
       - non-obvious coupling, invariants, or footguns in the areas being changed

    Keep the overview tight — it's a map, not a transcript.

    ## Report

    Return ONLY: the source label, a count of what you indexed (files / chunks), and a
    2–3 line summary of the overview. Do NOT paste the indexed content back.
```

**Returns:** the source label + index counts + a short summary. Carry forward only the **label** — hand it to every implementer and reviewer.

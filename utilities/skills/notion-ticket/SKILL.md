---
name: notion-ticket
description: Work with Notion Engineering Tasks tickets by their item ID (e.g. ITEM-11153) — fetch a ticket's content or update its body via the Notion MCP. Triggers on /notion-ticket <ID>, or any request to look up, read, view, or update a Notion ticket by its item ID.
---

# Notion Tickets

Fetch or update Notion Engineering Tasks tickets by their item ID (e.g. `ITEM-11153`).

## Resolving a ticket ID → page (do this first, for any operation)

`ITEM-<n>` tickets are rows in the **Engineering Tasks** database (data source `collection://f23dba4b-107c-4b12-ae4e-4274fd87a243`). The `ITEM-<n>` identifier is the row's `userDefined:ID` property — **not** the page title or body — so `mcp__claude_ai_Notion__notion-search` will **not** find it by ID.

1. Query the **Table** view with `mcp__claude_ai_Notion__notion-query-database-view` and match the row whose `userDefined:ID` equals the requested ID. The output is large — process it rather than reading raw, and paginate with `next_cursor` if the ID isn't on the first page.
2. From the matched row take its `url` (and page UUID `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
3. No match → tell the user and stop.

If the user provides a Notion page URL or UUID directly instead of an `ITEM-<n>` ID, skip the lookup and use it as-is.

## Fetch a ticket

1. Resolve the ID → page (above).
2. `mcp__claude_ai_Notion__notion-fetch` the row's `url` for the full ticket body.
3. Present the content to the user.

## Update a ticket

1. Resolve the ID → page (above).
2. **Fetch current content** with `mcp__claude_ai_Notion__notion-fetch` so nothing is lost unintentionally.
3. **Get the new body** — if the user hasn't provided it, ask now, showing the current body for reference.
4. **Preserve existing content** — before writing, inspect the current body for media (inline images, file attachments, video/audio embeds, bookmarks, blocks with external URLs) or rich context blocks. If found, keep them in a clearly marked section (e.g. `## Attachments & Prior Context`) at the bottom of the updated page. Never discard existing media or context. If the body already has such a section, merge into it rather than duplicating.
5. **Update** with `mcp__claude_ai_Notion__notion-update-page` (pageId + merged content): new body first, preserved media/context section last. `notion-update-page` replaces the page body.

## Tool Reference

```
# Resolve ID: query the Engineering Tasks Table view,
# match the row whose userDefined:ID == the requested ID
mcp__claude_ai_Notion__notion-query-database-view
  # data source: collection://f23dba4b-107c-4b12-ae4e-4274fd87a243

# Fetch a page (use the URL from the matched row)
mcp__claude_ai_Notion__notion-fetch  url="<notion_page_url>"

# Update a page body
mcp__claude_ai_Notion__notion-update-page
  pageId: "<uuid>"
  content: "<new markdown body>"
```

## Common Mistakes

- **Searching by ID instead of querying the database** — `ITEM-<n>` is the `userDefined:ID` property, not title/body text; `notion-search` won't find it. Query the Engineering Tasks Table view and match `userDefined:ID`.
- **Updating without fetching first** — `notion-update-page` replaces the body; fetch first or media/context is lost.
- **Discarding media** — always preserve images/attachments/embeds in the `## Attachments & Prior Context` section.

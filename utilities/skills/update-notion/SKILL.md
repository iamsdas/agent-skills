---
name: update-notion
description: Use when the user provides a Notion ticket ID (e.g. ITEM-11153) and wants to update its body/content via the Notion MCP. Triggers on /update-notion <ID> or any request to update a Notion ticket by its item ID.
---

# Update Notion Ticket

Update a Notion ticket's body content by its item ID (e.g. `ITEM-11153`).

## Workflow

1. **Find the ticket in the Engineering Tasks database.**
   - All `ITEM-<n>` tickets are rows in the **Engineering Tasks** database (data source `collection://f23dba4b-107c-4b12-ae4e-4274fd87a243`). The `ITEM-<n>` identifier is the row's `userDefined:ID` property — **not** the page title or body — so `notion-search` won't find it by ID.
   - Query the **Table** view with `mcp__claude_ai_Notion__notion-query-database-view` and match the row whose `userDefined:ID` equals the requested ID. The output is large — process it rather than reading raw, and paginate with `next_cursor` if the ID isn't on the first page.
   - No match → tell the user and stop.

2. **Confirm the match** — extract the matched row's `url` (and Notion page UUID) for the next steps.

3. **Fetch current content** using `mcp__claude_ai_Notion__notion-fetch` with the page URL or UUID so the user can see what's there.

4. **Ask the user what to update** — if they haven't already provided the new body content, ask now. Show the current body for reference.

5. **Preserve existing content** — before writing, inspect the current body for any media (images, files, embeds) or rich context blocks. If found, keep them in a clearly marked section (e.g. `## Attachments & Prior Context`) at the bottom of the updated page. Never discard existing media or context.

6. **Update the page** using `mcp__claude_ai_Notion__notion-update-page` with the merged content: new body first, preserved media/context section last.

## Tool Reference

```
# Find the ticket by ID: query the Engineering Tasks Table view,
# match the row whose userDefined:ID == the requested ID
mcp__claude_ai_Notion__notion-query-database-view
  # data source: collection://f23dba4b-107c-4b12-ae4e-4274fd87a243

# Fetch current page (use the URL from the matched row)
mcp__claude_ai_Notion__notion-fetch  url="<notion_page_url>"

# Update page body
mcp__claude_ai_Notion__notion-update-page
  pageId: "<uuid>"
  content: "<new markdown body>"
```

## Notes

- `ITEM-<n>` IDs are the `userDefined:ID` property of rows in the Engineering Tasks database — query the Table view and match that property; `notion-search` won't find them by ID.
- The page UUID looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`; extract it from the matched row's `id` or `url` field.
- `notion-update-page` replaces the page body — fetch first so nothing is lost unintentionally.
- Media includes: inline images, file attachments, video/audio embeds, bookmarks, and any blocks with URLs pointing to external resources. Detect these in the fetched content before writing.
- If the existing body has a prior "Attachments & Prior Context" section, merge its contents into the new one rather than duplicating it.

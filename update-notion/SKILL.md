---
name: update-notion
description: Use when the user provides a Notion ticket ID (e.g. ITEM-11153) and wants to update its body/content via the Notion MCP. Triggers on /update-notion <ID> or any request to update a Notion ticket by its item ID.
---

# Update Notion Ticket

Update a Notion ticket's body content by its item ID (e.g. `ITEM-11153`).

## Workflow

1. **Search for the ticket** using `mcp__claude_ai_Notion__notion-search` with the ticket ID as the query.

2. **Confirm the match** — pick the result whose title contains the ticket ID. Extract the Notion page UUID from the result.

3. **Fetch current content** using `mcp__claude_ai_Notion__notion-fetch` with the page URL or UUID so the user can see what's there.

4. **Ask the user what to update** — if they haven't already provided the new body content, ask now. Show the current body for reference.

5. **Preserve existing content** — before writing, inspect the current body for any media (images, files, embeds) or rich context blocks. If found, keep them in a clearly marked section (e.g. `## Attachments & Prior Context`) at the bottom of the updated page. Never discard existing media or context.

6. **Update the page** using `mcp__claude_ai_Notion__notion-update-page` with the merged content: new body first, preserved media/context section last.

## Tool Reference

```
# Search by ticket ID
mcp__claude_ai_Notion__notion-search  query="ITEM-11153"

# Fetch current page (use the URL from search result)
mcp__claude_ai_Notion__notion-fetch  url="<notion_page_url>"

# Update page body
mcp__claude_ai_Notion__notion-update-page
  pageId: "<uuid>"
  content: "<new markdown body>"
```

## Notes

- `ITEM-11153` style IDs come from Notion databases with an auto-incrementing ID property — search returns the matching page.
- The page UUID looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`; extract it from the search result's `id` or `url` field.
- `notion-update-page` replaces the page body — fetch first so nothing is lost unintentionally.
- Media includes: inline images, file attachments, video/audio embeds, bookmarks, and any blocks with URLs pointing to external resources. Detect these in the fetched content before writing.
- If the existing body has a prior "Attachments & Prior Context" section, merge its contents into the new one rather than duplicating it.

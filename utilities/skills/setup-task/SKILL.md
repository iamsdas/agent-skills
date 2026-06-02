---
name: setup-task
description: Use when the user provides a Notion task ID (e.g. ITEM-11153) and wants to start working on it — sets up the workspace for the ticket. Triggers on /setup-task <ID> or any request to "set up", "start", or "pick up" a Notion task by its item ID.
---

# Setup Task

Bootstrap work on a Notion ticket: fetch the ticket, create an isolated worktree on a fresh branch off latest main, scope the requirements, and sync any new findings back to the ticket — then hand off to implementation planning.

## Input

A Notion task ID passed as the argument (e.g. `ITEM-11153`). If missing, ask for it before doing anything else.

## Workflow

1. **Fetch the ticket from Notion**
   - Search with `mcp__claude_ai_Notion__notion-search` using the task ID as the query.
   - Pick the result whose title contains the task ID, then `mcp__claude_ai_Notion__notion-fetch` the page.
   - No match → tell the user and stop. Multiple matches → show the candidates and ask which one.
   - Keep the full ticket body — it is the input to scoping in step 4 and the comparison baseline in step 5.

2. **Update main**
   - `git fetch origin main` from the repo root.
   - Do NOT check out main in the current workspace — the worktree in step 3 is created from `origin/main` directly.

3. **Create a worktree** — **REQUIRED SUB-SKILL:** use `development:using-git-worktrees`.
   - Branch name format: `<user_name>/<task_summary_snake_case>`
     - `<user_name>`: local part of `git config user.email` (e.g. `surya@fused.io` → `surya`); fall back to `whoami`.
     - `<task_summary_snake_case>`: ticket title lowercased, articles/prepositions/filler dropped, first ≤3 remaining words joined with `_` (e.g. "Fix login redirect loop on Safari" → `fix_login_redirect`, "Add rate limiting to the export API" → `add_rate_limiting`).
   - Worktree directory name: the task ID as-is (e.g. `ITEM-11153`).
   - Base the branch on `origin/main`, not the current branch.

4. **Scope the requirements** — **REQUIRED SUB-SKILL:** use `development:scope-requirements`, working inside the new worktree.
   - Feed it the ticket title and body as the feature request.

5. **Sync findings back to Notion**
   - Compare the scoped output against the original ticket body from step 1.
   - Update only if scoping added substance the ticket lacks — new requirements, decisions, edge cases, or out-of-scope items. Rewording or restructuring existing content does not count.
   - If it does, update the ticket — **REQUIRED SUB-SKILL:** use `utilities:update-notion` with the merged content.
   - If the ticket already covered everything, skip the update and say so.

6. **Report and hand off** — print the worktree path, branch name, and a one-line note on whether the ticket was updated. Then invoke `development:writing-plans` with the scoped requirements from step 4 as the spec — setup is done; planning is the next phase and runs inside the worktree.

## Common Mistakes

- **Checking out main locally before branching** — pollutes the current workspace; branch the worktree from `origin/main` instead.
- **Skipping the fetch** — a stale local `origin/main` means the worktree starts behind.
- **Always updating the ticket** — only update when scoping added material new information; trivial rewording is noise for the ticket's watchers.
- **Replacing the ticket body wholesale** — `update-notion` already handles preserving media/context; still, merge new info into the existing structure rather than overwriting it.
- **Stopping after the ticket sync** — always end by handing off to `development:writing-plans`; the Notion update is a side effect, not the goal.

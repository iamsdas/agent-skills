---
name: setup-task
description: Use when the user provides a Notion task ID (e.g. ITEM-11153) and wants to start working on it — sets up the workspace for the ticket. Triggers on /setup-task <ID> or any request to "set up", "start", or "pick up" a Notion task by its item ID.
---

# Setup Task

Bootstrap work on a Notion ticket: fetch the ticket, create an isolated worktree on a fresh branch off latest main, scope the requirements, and sync any new findings back to the ticket — then end with the scoped requirements.

## Input

A Notion task ID passed as the argument (e.g. `ITEM-11153`). If missing, ask for it before doing anything else.

## Workflow

1. **Fetch the ticket from Notion**
   - All `ITEM-<n>` tickets are rows in the **Engineering Tasks** database (data source `collection://f23dba4b-107c-4b12-ae4e-4274fd87a243`). The `ITEM-<n>` identifier is the row's `userDefined:ID` property — **not** the page title or body — so `notion-search` won't find it by ID.
   - Query the **Table** view with `mcp__claude_ai_Notion__notion-query-database-view` and match the row whose `userDefined:ID` equals the requested ID. The output is large — process it rather than reading raw, and paginate with `next_cursor` if the ID isn't on the first page.
   - Then `mcp__claude_ai_Notion__notion-fetch` the matched row's `url` for the full ticket.
   - No match → tell the user and stop.
   - Keep the full ticket body — it is the input to scoping in step 3 and the comparison baseline in step 4.

2. **Set up the workspace** — one script call, no sub-skill needed.
   - Compose the branch name: `<user_name>/<task_summary_snake_case>`
     - `<user_name>`: local part of `git config user.email` (e.g. `surya@fused.io` → `surya`); fall back to `whoami`.
     - `<task_summary_snake_case>`: a 3-word snake_case summary that captures the essence of the ticket — pick the most meaningful words from the title, not necessarily in order (e.g. "Fix login redirect loop on Safari" → `fix_safari_redirect`, "Add rate limiting to the export API" → `rate_limit_export`).
   - Run (from anywhere inside the repo, using this skill's base directory announced when it loaded):
     ```bash
     bash <skill_base_dir>/scripts/setup-workspace.sh <TASK_ID> <branch_name>
     ```
     The script handles everything deterministically: fetches `origin/main`, reuses a clean linked worktree in place if you're already in one, otherwise creates `.worktrees/<TASK_ID>` (gitignored) on the new branch off `origin/main`. Read the `STATUS=`/`WORKTREE=` lines it prints.
   - **Exit codes that need your judgment:**
     - `2` (`dirty-worktree`): ask the user whether to reuse anyway (stash or commit per their preference, then `git switch -c <branch_name> origin/main`) or create a fresh worktree.
     - `3` (`path-exists`): a worktree for this task already exists — `cd` into it and check its state; it's probably a previous run of this task.
     - `4` (`branch-exists`): ask whether to reuse the existing branch or pick a new name.
   - Only fall back to `development:using-git-worktrees` if the script itself fails (e.g. sandbox denies `git worktree add`).
   - This step needs only the ticket title for branch naming — it can start as soon as the matching row is found in step 1, before the full ticket fetch completes.

3. **Scope the requirements** — **REQUIRED SUB-SKILL:** use `development:scope-requirements`, working inside the new worktree.
   - Feed it the ticket title and body as the feature request.

4. **Sync findings back to Notion — in the background**
   - Compare the scoped output against the original ticket body from step 1. Do this inline — both are already in context.
   - Update only if scoping added substance the ticket lacks — new requirements, decisions, edge cases, or out-of-scope items. Rewording or restructuring existing content does not count. If the ticket already covered everything, skip the update and say so.
   - If an update is warranted, dispatch a **background agent** (Agent tool, `run_in_background: true`) to perform it — do NOT block on it; proceed straight to step 5. The agent's prompt MUST include everything it needs, since it cannot see this conversation:
     - the ticket's Notion page URL (from step 1 — saves it re-searching)
     - the full merged body content to write
     - instruction to follow `utilities:update-notion`, skipping its search step (URL provided) and its ask-the-user step (content provided), but still applying its media/context preservation rules before writing.
   - When the background agent's completion notification arrives, relay one line on whether the update succeeded.

5. **Report and end** — print the worktree path, branch name, a one-line note on the Notion sync (updating in background / skipped), and the full scoped-requirements output from step 3. Then STOP — do NOT invoke `development:writing-plans` or start implementation; the user decides the next phase.

## Common Mistakes

- **Searching by ID instead of querying the database** — `ITEM-<n>` is the `userDefined:ID` property, not title/body text; `notion-search` won't find it. Query the Engineering Tasks Table view and match `userDefined:ID`.
- **Reimplementing the workspace setup step by step in bash** — `scripts/setup-workspace.sh` already handles fetch, worktree detection/reuse, gitignore safety, and branch creation; run it once and read its output instead of reasoning through git plumbing.
- **Reusing a dirty worktree silently** — the script exits `2` for exactly this reason; ask the user before stashing/committing.
- **Checking out main locally before branching** — pollutes the current workspace; the script branches from `origin/main` directly, never check out main yourself.
- **Always updating the ticket** — only update when scoping added material new information; trivial rewording is noise for the ticket's watchers.
- **Replacing the ticket body wholesale** — `update-notion` already handles preserving media/context; still, merge new info into the existing structure rather than overwriting it.
- **Blocking on the Notion update** — the sync is a side effect; dispatch it in the background and move on to the final report. Waiting for MCP round-trips before reporting wastes the user's time.
- **Dispatching the background agent without the page URL or merged content** — it cannot see the conversation; an underspecified prompt forces it to redo the database query or, worse, guess at content.
- **Continuing into planning or implementation** — setup ends with the scoped requirements; do not invoke `development:writing-plans` or write code unless the user asks.

---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Quality scan → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 7) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Quality Scan

**Collect diff data** (BASE_BRANCH is already known from Step 3):

```bash
BASE_COMMIT=$(git merge-base HEAD ${BASE_BRANCH})
CHANGED_FILES=$(git diff --name-only ${BASE_COMMIT}..HEAD)
DIFF_CONTENT=$(git diff ${BASE_COMMIT}..HEAD)
```

**Short-circuit:** If `CHANGED_FILES` is empty, skip to Step 5 with no output.

**Triage — determine which subagents to spawn:**

Evaluate the already-collected `CHANGED_FILES` and `DIFF_CONTENT` against these rules. Build the list of subagents to spawn before dispatching anything.

| Subagent | Spawn if | Skip if |
|---|---|---|
| `tests-analyzer` | Any source code file changed (e.g., `.ts`, `.js`, `.py`, `.go`, `.rs`, `.rb`, `.java`, `.cpp`, or similar language files) | ALL changed files are config/docs/assets (e.g., only `.json`, `.yaml`, `.toml`, `.md`, `.txt`, image files) |
| `silent-failure-hunter` | DIFF_CONTENT contains error-handling patterns: `try`, `catch`, `except`, `rescue`, `.catch(`, `handleError`, `onError`, `Result<`, `Err(` | None of those patterns appear in the diff |
| `comment-analyzer` | DIFF_CONTENT has added or removed comment lines (diff lines starting with `+//`, `-//`, `+#`, `-#`, `+/*`, `-/*`, `+ *`, `- *`, `+"""`, `-"""`, `+'''`, `-'''`) | No comment lines in the diff |

**If no subagents pass triage** (e.g., a pure-docs commit), proceed directly to Step 5 with no output.

**Dispatch applicable subagents in parallel** (single message, all background). Only spawn subagents that passed triage above — omit the rest entirely:

- **`tests-analyzer`** — pass CHANGED_FILES + DIFF_CONTENT. Prompt: *"Review this diff for CRITICAL test coverage gaps only — logic branches with no test at all, untested error paths, new public functions with zero coverage. Ignore nice-to-haves and style. If no critical gaps exist, say 'No critical gaps found' and stop. Return at most 3 findings: file:line, what is untested, what failure it would miss, and a criticality rating 7-10."*

- **`silent-failure-hunter`** — pass DIFF_CONTENT. Prompt: *"Review this diff for CRITICAL and HIGH severity silent failures only — skip MEDIUM. If none exist, say 'No critical error handling issues found' and stop. Return at most 3 findings: file:line, severity, one sentence on the issue, one sentence on debugging impact."*

- **`comment-analyzer`** — pass CHANGED_FILES (read their content). Prompt: *"Review the changed files for CRITICAL comment issues only — comments that are factually wrong or actively misleading about what the code does. Ignore missing comments, style, wording preferences, and minor inaccuracies. If no critical issues exist, say 'No critical comment issues found' and stop. Return at most 3 findings: file:line, what the comment says vs what the code actually does."*

**Render findings** above the options menu once all spawned agents return:

- Intermix all findings sorted by severity: `[CRITICAL]` → `[HIGH]` → `[gap:9+]` → `[gap:7-8]` → `[comment]`
- Cap at 6 items total; if more: `(+N more — run /deep-review for full report)`
- Always close with: `These are advisory. Proceeding to options.`
- **If no findings across all spawned agents: print nothing.** Silence means clean — no false-confidence banner.

Example when findings exist:
```
Quality scan complete.

[CRITICAL] auth.ts:88 — Catch block swallows all errors without logging
[gap:9] UserService.ts:120 — createUser() has no test for the duplicate-email branch
[comment] config.ts:15 — Comment says "reads from env" but code reads from hardcoded map

These are advisory. Proceeding to options.
```

### Step 5: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 6: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 7), then delete branch
```

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 7: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

Quality scan runs before all options — always advisory, never blocking.

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

**Dispatching quality subagents sequentially**
- **Problem:** Doubles wall-clock time of the quality scan
- **Fix:** Dispatch all applicable subagents in a single message

**Blocking on quality scan findings**
- **Problem:** User cannot proceed until findings are resolved — not the intent
- **Fix:** Quality scan is always advisory; always proceed to the options menu

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree
- Block progression to the options menu based on quality scan output
- Print a "no issues found" success message from the quality scan (false confidence)
- Dispatch quality subagents sequentially — all applicable subagents must go in one message

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal

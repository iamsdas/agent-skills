#!/usr/bin/env bash
# setup-workspace.sh <TASK_ID> <BRANCH_NAME>
#
# Deterministic workspace setup for setup-task:
#   - fetch origin/main
#   - reuse a clean linked worktree in place, or
#   - create .worktrees/<TASK_ID> on a fresh branch off origin/main
#
# Exit codes:
#   0  success            (STATUS=reused | STATUS=created)
#   2  dirty worktree     (needs a user decision — do not proceed silently)
#   3  worktree path already exists
#   4  branch already exists
#   1  usage / git errors
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: setup-workspace.sh <TASK_ID> <BRANCH_NAME>" >&2
  exit 1
fi
TASK_ID="$1"
BRANCH="$2"

git fetch origin main

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "STATUS=branch-exists"
  echo "BRANCH=$BRANCH"
  exit 4
fi

GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
SUPERPROJECT=$(git rev-parse --show-superproject-working-tree)

# Already in a linked worktree (and not a submodule)? Reuse it.
if [ "$GIT_DIR" != "$GIT_COMMON" ] && [ -z "$SUPERPROJECT" ]; then
  if [ -n "$(git status --porcelain)" ]; then
    echo "STATUS=dirty-worktree"
    echo "WORKTREE=$(pwd -P)"
    exit 2
  fi
  git switch -c "$BRANCH" origin/main
  echo "STATUS=reused"
  echo "WORKTREE=$(pwd -P)"
  echo "BRANCH=$BRANCH"
  exit 0
fi

# Normal checkout: create a worktree named after the task ID.
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

WT_DIR=".worktrees"
[ ! -d .worktrees ] && [ -d worktrees ] && WT_DIR="worktrees"

# Safety: never create a tracked worktree directory.
if ! git check-ignore -q "$WT_DIR" 2>/dev/null; then
  echo "$WT_DIR/" >> .gitignore
  git add .gitignore
  git commit -m "chore: ignore $WT_DIR" --quiet
  echo "NOTE=added $WT_DIR/ to .gitignore and committed"
fi

WT_PATH="$ROOT/$WT_DIR/$TASK_ID"
if [ -e "$WT_PATH" ]; then
  echo "STATUS=path-exists"
  echo "WORKTREE=$WT_PATH"
  exit 3
fi

git worktree add "$WT_PATH" -b "$BRANCH" origin/main
echo "STATUS=created"
echo "WORKTREE=$WT_PATH"
echo "BRANCH=$BRANCH"

---
name: babysitting-pull-requests
description: Use when a pull request is open and needs watching through CI and review bots until it is ready - the user says monitor, watch, or babysit a PR, or a PR was just opened and checks or bot reviews are still pending.
---

# Babysitting Pull Requests

## Overview

Stay with an open PR until it is ready to merge: CI green, review bots finished and answered, branch current with its base. Review bots are useful but often wrong, so every finding gets checked against the code before anything changes.

**Core principle:** One watcher wakes you on real events. Act on each event, stay silent when there is nothing to do, and stop at the ready gate. Never merge unless the user explicitly asked for it.

**Announce at start:** "I'm using the babysitting-pull-requests skill to watch this PR."

## Waiting

Never write your own polling or `sleep` loop. Wait with `scripts/pr-wait` from this skill's directory, using its absolute path:

```bash
<skill-dir>/scripts/pr-wait <pr> [--repo owner/name] [--until ready|green|any-change]
```

It prints one line per real event and exits **0** when the `--until` condition is met or the PR merged, **1** when it needs you (required check failed, conflict, unresolved threads, BEHIND, PR closed), and **2** on bad input or when another watcher already holds the PR. Run `--help` for the event list.

Pick `--until` from the repo's bots. Check recent PRs (`gh pr view <n> --comments`) for which bots review:

| Repo has | Use |
|---|---|
| Greptile or Macroscope | `ready` (default): green, the bot reviewed the head, no unresolved threads |
| Neither (CodeRabbit only, or no bots) | `green`. `ready` waits for a Greptile/Macroscope review and **never exits** without one |

Run it with the **Monitor** tool so each line wakes you; give it a one-hour timeout. Without Monitor, run it as one long foreground command. It ends on its own.

- Start it again after each push, after handling an exit 1, and after a resume. It keeps state in `~/.local/state/pr-wait/`, so events that arrived in between are not lost.
- If it says another pid already watches the PR, do not start a second one. Kill the old pid only if its events are not reaching you.
- When an event needs no action, end the turn without a message. Never say "still waiting".

## Handling Events

Only act on checks and comments newer than the latest push.

- **Failed check:** read the log (`gh run view <id> --log-failed`). Tell a real failure apart from an infrastructure flake. Re-run a flake once (`gh run rerun <id> --failed`); fix a real one.
- **Bot or human finding:** follow `receiving-code-review`. Verify it against the source before changing code. If it is real, fix it. If not, reply in the thread with the reason and resolve it.
- **Macroscope finding:** if the repo has `.macroscope/check-run-agents/*.md`, read those rules first; its findings cite them.
- **CodeRabbit:** advisory. Treat its findings like any other, but never wait or hold the PR for it.
- **BEHIND, or base commits touching this PR's files:** rebase onto the base and push with `--force-with-lease`. **DIRTY:** resolve the conflicts by the PR's intent, then push.
- **An overlapping PR makes this one obsolete:** stop watching and tell the user. Do not close the PR unless the user asked you to.

**Who writes fixes.** Inside `building-with-subagent`, the orchestrator never writes code. Real findings and red checks go to a fresh fix builder, and they count toward its two-round cap. Otherwise, fix them directly. Either way, prove each fix (scoped tests, or a reproduction) before pushing.

**Keep the PR at the size the goal needs.** Review loops grow a PR one cheap-looking fix at a time. Fix real bugs in the intended case. Decline the rest with a written reason and list them as follow-ups. That covers unneeded tests, guards for edge cases that don't matter, extra compatibility, and micro-optimizations. Prefer the fix that deletes or narrows code.

## The Ready Gate

The PR is ready only when **all** of these hold on the latest head:

- Required checks are green.
- Review bots have finished, and every finding is fixed or answered with a written reason.
- No human review still requests changes.
- The branch is up to date with its base, and GitHub reports it mergeable.
- No base commits that landed after the last green run touch this PR's files.

Right before calling it ready, `git fetch` and recheck the live PR. A pr-wait exit 0 is news, not the verdict: check the gate yourself.

Then **stop and report**: PR link, head SHA, check status, each finding with its outcome (fixed or declined, and why), and any follow-ups. Merge only if the user explicitly asked. Then use the repo's merge method, never `--admin` or another bypass, and stay until GitHub reports the PR merged.

## GitHub Rate Limits

`gh pr create`, `gh pr view` and `gh pr checks` use GraphQL. If GraphQL is used up (`gh api rate_limit --jq .resources.graphql`), the REST limit is separate and usually has room:

- Read a PR: `gh api repos/<owner>/<repo>/pulls/<n>`
- Read checks: `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`

Every watcher on the account shares the limit, so run one watcher per PR. Never restart one in a tight loop.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `gh pr checks --watch` or a `sleep` loop | `pr-wait` under Monitor |
| `--until ready` on a repo with no Greptile/Macroscope | `--until green`; it hangs otherwise |
| Changing code because a bot said so | Verify against the source first; decline false positives in-thread |
| Fixing every nit a bot raises | Fix real bugs; list the rest as follow-ups |
| Posting "still waiting" or status filler | End the turn silently |
| Treating pr-wait exit 0 as permission to merge | Check the ready gate; merge only on explicit request |
| Acting on comments from before the latest push | Only newer events count |

## Integration

- **creating-pull-requests** opens the PR that this skill watches.
- **building-with-subagent** uses this skill after its draft PR goes up; fixes go to fresh builders.
- **receiving-code-review** governs how each finding is evaluated and answered.
- **modernizing-pull-requests** handles a PR that has fallen far behind its base, beyond what a routine rebase settles.

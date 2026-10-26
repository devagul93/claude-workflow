---
name: ready
description: List open GitHub issues with no open blockers — the current "wave" that can be worked in parallel. Optional milestone name narrows it.
argument-hint: "[milestone name]"
allowed-tools: Bash
---

Run from the project repo:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/ready.sh" $ARGUMENTS
```

Show the output as is (columns: issue, priority, milestone, title). Then add one line: these issues have no open "Blocked by" links, so each can start now in its own worktree with `claude --worktree N-slug` and `/workflow:start-issue N`.

If the list is empty, say so and suggest checking `gh issue list --state open` for issues whose blockers are still open.

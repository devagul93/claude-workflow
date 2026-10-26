# claude-workflow

A small, strict way of building software with Claude Code. One GitHub issue at a time. Tests first. One pull request per issue. Claude stops at a green PR; a human merges.

It is a Claude Code **plugin**: four slash commands plus the files it drops into your repo. Install once, set up each project with one command.

## The loop

```
Issue (#N) ──► worktree N-slug ──► red tests ──► green code ──► scripts/verify.sh ──► PR "Closes #N" ──► CI ✓ ──► you merge
     ▲                                                                                                          │
     └──────────────────────────── next unblocked issue ◄───────────────────────────────────────────────────────┘
```

## The six rules

1. **One issue = one unit = one PR.** A unit compiles, passes, and can be reverted alone. If the PR title needs "and" twice, split the issue.
2. **The issue body is the spec.** No separate planning docs for Claude to hunt for. Goal, acceptance, not in scope.
3. **Acceptance criteria are test names.** Each line in the issue becomes one test. No test, no acceptance.
4. **Tests first.** Red, then green, then refactor. A test that passes before any code exists tests nothing.
5. **PR under 300 lines** of real change. Generated files don't count. Bigger needs a reason in the PR.
6. **Claude stops at a green PR.** It never merges unless you say so. You review, you squash-merge.

Everything else (labels, worktrees, the verify script, CI) exists to make these six easy to keep.

## Install (once per machine)

You need [Claude Code](https://code.claude.com) and the [GitHub CLI](https://cli.github.com) (`gh auth login`).

```bash
claude plugin marketplace add devagul93/claude-workflow
claude plugin install workflow@claude-workflow
```

You now have `/workflow:init`, `/workflow:new-issue`, `/workflow:start-issue` and `/workflow:ready`.

## Set up a project (once per repo)

Inside a repo that has a GitHub remote, start Claude and run:

```
/workflow:init
```

It asks four things (project name, the command that runs all tests, the command that runs some tests, and 3 to 6 area names), then creates:

| File | What it is |
|---|---|
| `docs/WORKFLOW.md` | The one page everything points at. Read it once. |
| `CLAUDE.md` (or a section appended to yours) | Tells Claude to read WORKFLOW.md and how to run tests |
| `scripts/verify.sh` | The one check: tests + diff checks, ends in `VERDICT ✓` or `✗` |
| `.github/ISSUE_TEMPLATE/feature.md`, `bug.md` | Issue shapes with "Acceptance (each line becomes a test)" |
| `.github/pull_request_template.md` | What / Closes #N / Red → green / Verify |
| `.github/workflows/ci.yml` | Runs `scripts/verify.sh` on every PR. Add your toolchain in the marked spot. |
| `.gitignore` line | Keeps Claude's worktrees out of git |
| GitHub labels | `type:`, `area:`, `P0`–`P2`, `needs-design` |

Nothing you already have is overwritten. Run `scripts/verify.sh` once by hand to see it pass, then commit.

## A day's work

```
/workflow:new-issue add pinch zoom to the reader      # 1. write the spec as an issue
claude --worktree 12-pinch-zoom                        # 2. one worktree, one Claude session per issue
/workflow:start-issue 12                               # 3. Claude: tests → code → verify → PR, then stops
                                                       # 4. you review and merge on GitHub
/workflow:ready                                        # 5. what can start now?
```

Several issues at once? Open one terminal per issue, each with its own `claude --worktree`. They never touch each other's files.

### Issues

Every issue has a **Goal** (one sentence), **Acceptance** (test names), **Not in scope**, and for UI work a **Manual check**. Mark dependencies with GitHub's own *Blocked by* link on the issue, not in text. `/workflow:ready` reads those links and lists only the issues that can start right now. That list is the "wave".

### Labels

| Group | Labels |
|---|---|
| Type | `type: feature`, `type: bug`, `type: chore`, `type: test` |
| Area | `area: <your words>` |
| Priority | `P0` blocks the milestone, `P1`, `P2` |
| Flag | `needs-design`: Claude shows a plan and waits before coding |

### Commits

`type(area): what changed (#N)`, for example `fix(reader): keep the page after a restart (#4)`. Files are staged by name, never `git add -A`.

## FAQ

**Why doesn't Claude merge?** Because the merge is the one moment a human reads the diff. Keep it. Claude labels, pushes and opens the PR; you press the button.

**Why worktrees?** `claude --worktree N-slug` gives each issue its own checkout under `.claude/worktrees/` on branch `worktree-N-slug`. Parallel sessions can't step on each other, and a clean worktree is removed on its own when the session ends.

**No test runner yet?** Give `/workflow:init` the command `true` for now, and make issue #1 "set up the test runner". Everything else still works.

**Can I change the templates?** Yes, they are plain files in your repo. The plugin only copies them in. `docs/WORKFLOW.md` is yours to edit.

**Does it work without GitHub?** The loop does. Blocked-by links, `/workflow:ready` and labels need GitHub (they use `gh`).

## Where this came from

It was worked out on two apps: an Android launcher rebuilt in Jetpack Compose (about 230 issues, 3 parallel sessions), and an iOS manga reader for a foldable phone (about 90 issues, built mostly overnight by agents). The second project is where the lean version here settled.

Things those projects added on top, which are **not** in this plugin but are worth stealing if you hit the same walls:

- **One simulator or emulator per worktree**, named after the branch, so parallel test runs don't collide.
- **A machine-wide test lock** (two slots) so people, agents and CI queue for the test runner instead of pushing a laptop into swap.
- **A self-hosted CI runner** when only one machine has the toolchain.
- **Remembering tested trees**: a full green run on a clean checkout records the tree hash, and CI skips an identical tree. The squash merge of an up-to-date PR then gets its tick in seconds.
- **Full suite once per batch**: feature PRs run only their own tests; an integrator merges a batch and runs everything once.
- **Thoroughness tiers** (docs → tests-only → standard → UI → critical path) that decide how much checking a PR gets, plus a `verify` subagent that runs the checklist for its tier.

## Layout of this repo

```
.claude-plugin/marketplace.json      lists the plugin
plugins/workflow/
  .claude-plugin/plugin.json
  skills/{init,new-issue,start-issue,ready}/SKILL.md
  scripts/ready.sh                   the wave: open issues with no open blockers
  scripts/labels.sh                  creates the label set
  templates/                         what /workflow:init copies into your repo
```

MIT licence.

# How we build {{PROJECT}}

One page, one source of truth. `CLAUDE.md`, `/workflow:start-issue`, the issue and PR templates all point here instead of repeating it.

## The loop

```
Issue (#N) ──► worktree N-slug ──► red tests ──► green code ──► scripts/verify.sh ──► PR "Closes #N" ──► CI ✓ ──► you merge
     ▲                                                                                                          │
     └──────────────────────────── next unblocked issue ◄───────────────────────────────────────────────────────┘
```

- **One issue = one unit = one PR.** A unit compiles, passes, and can be reverted alone. If the PR title needs "and" twice, split the issue.
- **PR under 300 lines** of real change. Generated files don't count; explain anything bigger.
- **The issue body is the spec.** There are no separate guide files. Acceptance criteria are written as test names.

## Issues

Every issue has:

| Part | What goes in it |
|---|---|
| Goal | One sentence: what the user can do after this |
| Acceptance | Test names, e.g. `savedPageSurvivesRestart`. Each becomes a test. |
| Manual check | What to look at by hand, for UI changes only |
| Not in scope | What NOT to build (stops scope creep) |

**Dependencies** use GitHub's own *Blocked by* link on the issue, not text. Issues with no open blockers can be worked in parallel. That is the "wave". `/workflow:ready` lists the current wave (add a milestone name to narrow it). Start one worktree per line.

### Labels

| Group | Labels |
|---|---|
| Type | `type: feature`, `type: bug`, `type: chore`, `type: test` |
| Area | {{AREAS}} |
| Priority | `P0` (blocks the milestone), `P1`, `P2` |
| Flag | `needs-design`: stop and agree the approach with a human before coding |

### Milestones

Group issues into milestones in the order you want to ship them. The first milestone is the smallest thing that works end to end.

## Worktrees (parallel work)

Each issue runs in its own worktree and its own Claude session:

```bash
cd <repo>
claude --worktree 12-pinch-zoom     # creates .claude/worktrees/12-pinch-zoom on branch worktree-12-pinch-zoom
# inside the session:
/workflow:start-issue 12
```

- **Name worktrees `N-slug`**, where N is the issue number. `/workflow:start-issue` reads the number from the branch.
- **Never edit one worktree's files from another session.**
- **Generated files are not committed** (build output, lockfile-derived project files), so two branches can't conflict on them.
- **When the PR is merged:** leave the session. Claude removes a clean worktree itself.

## Test-driven development

1. **Red.** Write the tests from the Acceptance list first. Run only them:
   `scripts/verify.sh --only <pattern>`. They must fail. If a new test passes before any code exists, it tests nothing; fix the test. Copy the failure line into the PR.
2. **Green.** Write the least code that passes.
3. **Refactor.** Keep it green.
4. **Full run.** `scripts/verify.sh` with no arguments must end in `VERDICT ✓`.

**Bugs:** first write a test that reproduces the bug (red), then fix it.

**Failure tests check three things:** no crash, the right fallback shown, and the error logged.

## Verify and CI

- **`scripts/verify.sh`** is the one check: run every test, then check the added lines for TODOs without `#N` and secret-looking files. It also reports diff size.
- **CI** runs the same script on every PR and every push to `main` (`.github/workflows/ci.yml`).
- **Docs-only changes:** `scripts/verify.sh --docs`.

## Commits and PRs

- **Commit:** `type(area): what changed (#N)`, e.g. `fix(reader): keep the page after a restart (#4)`. Stage files by name, never `git add -A`.
- **PR:** use the template. It must include `Closes #N`, the red → green evidence and the verify verdict. UI PRs also need the manual check notes.
- **Claude stops at a green PR.** A human reviews and merges (squash). Claude merges only when told to.

---
name: new-issue
description: Write a GitHub issue in the workflow's spec shape (goal, acceptance as test names, not in scope), apply labels, link blockers. Use when asked to create, file or write up an issue.
argument-hint: "[short description of the work]"
allowed-tools: Bash, Read, Grep, Glob
---

Create one issue that `/workflow:start-issue` can work without further questions. The issue body is the spec.

1. **Gather.** From `$ARGUMENTS`, the conversation and the code, work out:
   - **Goal**: one sentence, what the user can do after this.
   - **Acceptance**: 2 to 6 test names in the project's test naming style (look at an existing test file). Each line becomes one test. Cover the happy path, an edge, and a failure where it makes sense.
   - **Manual check**: for UI changes only, what to open and look at.
   - **Not in scope**: what this issue deliberately leaves out.
   - **Labels**: one `type:` label, one `area:` label (see `gh label list`), a priority `P0`/`P1`/`P2`, and `needs-design` if the approach should be agreed first.
   - **Milestone**: pick from `gh api repos/{owner}/{repo}/milestones --jq '.[].title'` if any exist.
   - **Blockers**: issue numbers that must merge first.
   Ask only for what you cannot infer. One round of questions at most.

2. **Check the size.** If the title needs "and" twice, or acceptance runs past 6 tests, propose a split into two issues and ask which to file first.

3. **Create.** Use the body shape from `.github/ISSUE_TEMPLATE/feature.md` (or `bug.md` for bugs):

   ```bash
   gh issue create --title "<title>" --label "type: feature" --label "area: <x>" --label "P1" [--milestone "<name>"] --body-file <tmpfile>
   ```

   Keep the title short and concrete, no trailing full stop.

4. **Link blockers.** GitHub's dependency API wants the blocking issue's database id, not its number:

   ```bash
   BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/<blocker-number> --jq .id)
   gh api -X POST repos/{owner}/{repo}/issues/<new-number>/dependencies/blocked_by -f issue_id="$BLOCKER_ID"
   ```

   Repeat per blocker. Confirm with `gh api repos/{owner}/{repo}/issues/<new-number>/dependencies/blocked_by --jq '.[].number'`.

5. **Report.** The issue URL, its labels, and the two commands to start it:

   ```
   claude --worktree <N>-<slug>
   /workflow:start-issue <N>
   ```

   If it has open blockers, say so and point to `/workflow:ready` for what can start now.

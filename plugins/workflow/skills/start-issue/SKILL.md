---
name: start-issue
description: Work one GitHub issue end to end — red tests, green code, verify, PR. Use when asked to start, pick up or work an issue by number.
argument-hint: "issue number (optional when the branch or worktree is named N-slug)"
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

Follow the project's `docs/WORKFLOW.md`. Do these steps in order. If the project has no `docs/WORKFLOW.md` or `scripts/verify.sh`, stop and suggest `/workflow:init`.

1. **Find the issue.** Use `$ARGUMENTS` if given. Otherwise take the first number in `git branch --show-current` (for example `worktree-12-pinch-zoom` gives 12). If there is neither, ask.
   `gh issue view N --json title,body,labels,milestone,state`. Summarise the goal in one line.

2. **Check blockers.**
   `gh api repos/{owner}/{repo}/issues/N/dependencies/blocked_by --jq '.[] | select(.state=="open") | "#\(.number) \(.title)"'`
   If any are still open, stop and list them.

3. **Sync.** `git fetch origin`. If `git log HEAD..origin/main --oneline` shows commits, rebase onto `origin/main`. Warn if the working tree is dirty.

4. **Plan in at most 10 lines:** the tests to write (from the Acceptance list), the files to touch, and anything unclear.
   - If the issue has the `needs-design` label: show the plan and wait for approval.
   - Otherwise, carry on.
   - For any library API you're unsure of, check its current docs first (Context7 if available, else the official docs).

5. **Red.** Write the tests first. Run only them: `scripts/verify.sh --only <pattern>`. They must fail for the right reason. If a new test passes before any code exists, it tests nothing; fix the test. Keep the failing line for the PR.

6. **Green.** Write the smallest code that passes. Re-run the same tests after each file.

7. **Refactor**, then run the full `scripts/verify.sh`. It must end in `VERDICT ✓`.

8. **Manual check (UI changes only).** Run the app, open the screens the issue names, and look. Take screenshots where you can. Note what you saw. Anything that needs a real device or a human goes in the PR as a checklist.

9. **Ship.**
   - Stage files by name, never `git add -A`.
   - Commit as `type(area): what changed (#N)`.
   - `git push -u origin HEAD`.
   - `gh pr create`, filling `.github/pull_request_template.md`: `Closes #N`, red → green evidence, verify verdict, manual check notes.

10. **Stop.** Report the PR link and wait for CI. Don't merge unless told to.

Found extra work along the way? Open a new issue with `/workflow:new-issue` or `gh issue create` and keep this PR to one purpose.

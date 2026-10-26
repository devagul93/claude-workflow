# {{PROJECT}}

**How we work:** read `docs/WORKFLOW.md`. It covers issues, worktrees, TDD, verify, PRs. Start any issue with `/workflow:start-issue N`.

## Commands

| Task | Command |
|---|---|
| Run all tests + checks (must end in `VERDICT ✓` before a PR) | `scripts/verify.sh` |
| Run some tests (red/green loop) | `scripts/verify.sh --only <pattern>` |
| Docs-only change | `scripts/verify.sh --docs` |
| All tests, directly | `{{TEST_ALL}}` |
| Some tests, directly | `{{TEST_SOME}}` |

## Rules

- No TODO without an issue number (`#N`).
- Never commit secrets, keys or `.env` files.

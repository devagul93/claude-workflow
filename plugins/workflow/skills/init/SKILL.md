---
name: init
description: Set a repo up for the issue-based TDD workflow — copies docs/WORKFLOW.md, scripts/verify.sh, GitHub issue and PR templates, CI, a CLAUDE.md section, and creates the standard labels. Use when asked to set up, adopt or install the workflow in a project.
argument-hint: "(no arguments; asks a few questions)"
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Set up the current repository for the workflow. Templates live in `${CLAUDE_PLUGIN_ROOT}/templates/`.

## 1. Check the ground

- `git rev-parse --show-toplevel` must succeed. If not, stop: "Run this inside a git repo."
- `cd` to that top level for everything below.
- Note the GitHub remote, if any: `gh repo view --json nameWithOwner -q .nameWithOwner` (may fail; that is fine, labels are skipped later).
- Look at the repo for 10 seconds: `ls`, the package/build file (`package.json`, `pyproject.toml`, `build.gradle*`, `Package.swift`, `go.mod`, `Cargo.toml`, `project.yml`), and any existing test directory. Use this to **propose** the test commands below rather than asking blind.

## 2. Ask, in one round

Use one question block with these four, with your proposals filled in:

1. **Project name and one-liner** (default: the repo name).
2. **Command that runs all tests.** Proposals by stack: `npm test` · `pytest` · `./gradlew test` · `swift test` · `go test ./...` · `cargo test`. If there is no test runner yet, offer `true` as a placeholder and say the first issue should be "set up the test runner".
3. **Command that runs some tests**, with `$1` standing for the filter. Proposals: `npx vitest run $1` · `npx jest $1` · `pytest -k $1` · `./gradlew test --tests "$1"` · `swift test --filter $1` · `go test ./... -run $1` · `cargo test $1`.
4. **Area labels**, 3 to 6 short words for parts of the product (for example `reader library import sync app`). These become `area: <word>` labels.

Do not ask for the default branch; use `main` unless `git symbolic-ref refs/remotes/origin/HEAD` says otherwise, in which case set `BASE_BRANCH` in `scripts/verify.sh` to that.

## 3. Copy the templates

Walk every file under `${CLAUDE_PLUGIN_ROOT}/templates/` except `CLAUDE-section.md`, and write it to the same relative path in the repo, replacing:

| Placeholder | Value |
|---|---|
| `{{PROJECT}}` | the project name |
| `{{TEST_ALL}}` | the all-tests command |
| `{{TEST_SOME}}` | the some-tests command, `$1` kept literally |
| `{{AREAS}}` | the area labels as a backticked list, e.g. `` `area: reader`, `area: library` `` |

Rules:
- **Never overwrite an existing file.** If a target exists, skip it and list it under "Already there, left alone" at the end.
- Create parent directories as needed.
- `chmod +x scripts/verify.sh`.
- Use a small shell loop with `sed` for the substitution (`sed -e "s|{{PROJECT}}|...|g"`), or Read + Write per file. Either is fine; keep `$1` intact in `TEST_SOME`. Both commands end up inside single quotes in `verify.sh`, so if a command itself contains a single quote, write it with double quotes instead.

## 4. CLAUDE.md

- If `CLAUDE.md` does not exist: write it from `CLAUDE-section.md` with placeholders filled.
- If it exists and does not already mention `docs/WORKFLOW.md`: append a blank line and then the filled `CLAUDE-section.md` body **without its first `# ` heading line** (the file already has its own title).
- If it already mentions `docs/WORKFLOW.md`: leave it alone and say so.

## 5. .gitignore

Append `.claude/worktrees/` to `.gitignore` (create the file if missing) unless the line is already there. Add a comment line above it: `# Claude Code worktrees (one per issue)`.

## 6. Labels (GitHub only)

If there is a GitHub remote, ask once: "Create the standard labels on <owner/repo> now?" On yes:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/labels.sh" <area words>
```

On no, or with no remote, print the command so they can run it later.

## 7. Finish

Do not commit; leave that to them. Print:

- The files created, and the ones skipped.
- A reminder to fill in the toolchain step in `.github/workflows/ci.yml` (it is a comment block) and to run `scripts/verify.sh` once to confirm it ends in `VERDICT ✓`.
- The day-to-day commands:

  ```
  /workflow:new-issue <what>          write an issue in the spec shape
  claude --worktree N-slug            one worktree per issue
  /workflow:start-issue N             tests first, verify, PR
  /workflow:ready                     what can start now
  ```

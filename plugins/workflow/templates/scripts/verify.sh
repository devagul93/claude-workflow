#!/usr/bin/env bash
# The one check, run the same way by you, by Claude and by CI. Exit 0 = ready for a PR.
#
#   scripts/verify.sh                   # run every test, then the diff checks
#   scripts/verify.sh --only <pattern>  # run a subset of tests (red/green loops), then the diff checks
#   scripts/verify.sh --docs            # docs-only change: skip tests, run the diff checks
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# ── Project config (filled in by /workflow:init; edit freely) ───────────────────────────────────
TEST_ALL='{{TEST_ALL}}'     # e.g. npm test | pytest | ./gradlew test | swift test | go test ./...
TEST_SOME='{{TEST_SOME}}'   # e.g. npx vitest run $1 | pytest -k $1 | ./gradlew test --tests $1
BASE_BRANCH="${BASE_BRANCH:-main}"
MAX_LINES=300
# ────────────────────────────────────────────────────────────────────────────────────────────────

MODE=all
PATTERN=""
case "${1:-}" in
  --docs) MODE=docs ;;
  --only) MODE=some; PATTERN="${2:-}"; [ -n "$PATTERN" ] || { echo "usage: $0 --only <pattern>" >&2; exit 2; } ;;
  "") ;;
  *) echo "usage: $0 [--only <pattern> | --docs]" >&2; exit 2 ;;
esac

fail=0
say() { printf '%-9s %s\n' "$1" "$2"; }

# 1. Tests.
case "$MODE" in
  all)
    if bash -c "$TEST_ALL"; then say TESTS "✓ pass"; else say TESTS "✗ FAIL"; fail=1; fi ;;
  some)
    if bash -c "$TEST_SOME" -- "$PATTERN"; then say TESTS "✓ pass ($PATTERN)"; else say TESTS "✗ FAIL ($PATTERN)"; fail=1; fi ;;
  docs)
    say TESTS "skipped (--docs)" ;;
esac

# 2. Checks on what this branch adds compared with the base branch.
if git rev-parse --verify -q "origin/$BASE_BRANCH" >/dev/null; then BASE="origin/$BASE_BRANCH"; else BASE="$BASE_BRANCH"; fi
if ! git rev-parse --verify -q "$BASE" >/dev/null; then BASE=$(git rev-list --max-parents=0 HEAD | tail -1); fi
# Code files only: docs talk about TODOs, and this script names the patterns it looks for.
code_filter() { grep -vE '\.md$|^scripts/verify\.sh$|^docs/' || true; }
untracked=$(git ls-files --others --exclude-standard)
# Added lines in tracked changes plus the contents of new, untracked code files.
added=$( { git diff "$BASE" --unified=0 -- . ':(exclude)*.md' ':(exclude)docs/' ':(exclude)scripts/verify.sh' | grep -E '^\+[^+]' | cut -c2- || true
           echo "$untracked" | code_filter | while read -r f; do if [ -n "$f" ]; then cat "$f" 2>/dev/null || true; fi; done; } )
changed_files=$( { git diff --name-only "$BASE"; echo "$untracked"; } | grep . | sort -u || true)

if echo "$added" | grep -nE 'TODO|FIXME' | grep -vE '#[0-9]+' >/dev/null; then
  say TODO "✗ TODO/FIXME without an issue number (#N)"; fail=1
else say TODO "✓"; fi

if echo "$changed_files" | grep -E '(^|/)\.env(\..*)?$|\.(pem|p12|key|keystore|jks|mobileprovision)$|google-services\.json|GoogleService-Info|credentials\.json' >/dev/null; then
  say SECRETS "✗ secret-looking file in diff"; fail=1
else say SECRETS "✓"; fi

stat=$(git diff --shortstat "$BASE" | sed 's/^ *//')
n_untracked=$(echo "$untracked" | grep -c . || true)
[ "$n_untracked" -eq 0 ] || stat="${stat:+$stat, }$n_untracked new file(s) not yet committed"
say DIFF "${stat:-no changes}"
lines=$(git diff --numstat "$BASE" | awk '{s += $1 + $2} END {print s + 0}')
[ "$lines" -le "$MAX_LINES" ] || say SIZE "⚠ $lines lines changed — over $MAX_LINES, split it or explain why in the PR"

if [ $fail -eq 0 ]; then echo "VERDICT ✓ ready for PR"; else echo "VERDICT ✗ fix the items above"; fi
exit $fail

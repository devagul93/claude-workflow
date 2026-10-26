#!/usr/bin/env bash
# List open issues with no open blockers: the current "wave" you can start in parallel.
#   scripts/ready.sh                        # all milestones
#   scripts/ready.sh "M1 Duo reader core"   # one milestone
set -euo pipefail
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

args=(--state open --limit 200 --json number,title,milestone,labels)
[ $# -gt 0 ] && args+=(--milestone "$1")

gh issue list -R "$REPO" "${args[@]}" \
  --jq 'sort_by(.milestone.title, .number)[] | [.number, (.milestone.title // "-"), ([.labels[].name | select(test("^P[0-9]$"))] | join("")), .title] | @tsv' |
while IFS=$'\t' read -r number milestone priority title; do
  open=$(gh api "repos/$REPO/issues/$number/dependencies/blocked_by" --jq '[.[] | select(.state == "open")] | length')
  [ "$open" = 0 ] && printf '#%-4s %-4s %-22s %s\n' "$number" "$priority" "$milestone" "$title"
done

#!/usr/bin/env bash
# Create the workflow's standard GitHub labels in the current repo, plus any area labels you pass.
#   scripts/labels.sh                       # type, priority and flag labels only
#   scripts/labels.sh reader library sync   # also "area: reader", "area: library", "area: sync"
# Existing labels are updated in place (--force), never duplicated.
set -euo pipefail

label() { gh label create "$1" --description "$2" --color "$3" --force >/dev/null && echo "  $1"; }

echo "Labels:"
label "type: feature" "New behaviour"                           1D76DB
label "type: bug"     "Something behaves wrongly"               D73A4A
label "type: chore"   "Tooling, setup, cleanup"                 CCCCCC
label "type: test"    "Test infrastructure"                     0E8A16
label "P0"            "Blocks the milestone"                    B60205
label "P1"            "Important"                               D93F0B
label "P2"            "Nice to have"                            FEF2C0
label "needs-design"  "Agree the approach before coding"        F9D0C4

colors=(5319E7 FBCA04 C2E0C6 006B75 BFD4F2 0052CC E99695 1D76DB)
i=0
for area in "$@"; do
  label "area: $area" "Work on $area" "${colors[$((i % ${#colors[@]}))]}"
  i=$((i + 1))
done

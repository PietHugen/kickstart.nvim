#!/usr/bin/env bash
# gitlint caps line WIDTH (body-max-line-length) but has no built-in rule
# capping how many lines a body has, so a neatly-wrapped multi-paragraph
# rationale sails through it. This is the rule that actually targets that:
# cap the body at MAX_BODY_LINES real lines. Rationale that needs more room
# belongs in the plan/spec doc, referenced by path, not restated here.
set -euo pipefail

MAX_BODY_LINES=3
MSG_FILE="$1"

case "$(head -n1 "$MSG_FILE")" in
  "Merge "*|"Revert "*) exit 0 ;;
esac

# Drop comment lines (git's own hints) and the title line, then count what's
# left that isn't blank or a trailer (Key: value). awk's END block always
# prints a count, even zero, so this can't die via pipefail on a bodiless
# message the way a grep-with-no-matches mid-pipeline would.
body_lines=$(
  grep -v '^#' "$MSG_FILE" | tail -n +2 | awk '
    /^$/ { next }
    /^[A-Za-z][A-Za-z-]*: / { next }
    { c++ }
    END { print c+0 }
  '
) || true

if [ "$body_lines" -gt "$MAX_BODY_LINES" ]; then
  echo "commit body has $body_lines line(s), max is $MAX_BODY_LINES."
  echo "Keep the body to a short pointer; put rationale in the plan/spec doc it belongs to."
  exit 1
fi

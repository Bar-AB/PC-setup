#!/usr/bin/env bash
# Claude Code PreToolUse hook: blocks destructive SQL, AWS writes and anything touching prod.
# Exit code 2 = block (stderr is shown to Claude). Uses jq, falls back to python; fails CLOSED if neither exists.
block() { echo "BLOCKED by guard.sh: $1" >&2; exit 2; }

payload=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
else
  py=$(command -v python3 || command -v python) || block "guard.sh needs jq or python - install one"
  cmd=$(printf '%s' "$payload" | "$py" -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))')
fi
lc=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')

echo "$lc" | grep -Eq '\b(drop|truncate)[[:space:]]+(table|database|schema)\b' \
  && block "DROP/TRUNCATE not allowed"
echo "$lc" | grep -Eq '\bdelete[[:space:]]+from[[:space:]]+[a-z0-9_."]+[[:space:]]*(;|$|")' \
  && block "DELETE without WHERE"
echo "$lc" | grep -Eq '\bupdate[[:space:]]+[a-z0-9_."]+[[:space:]]+set\b' \
  && ! echo "$lc" | grep -q 'where' && block "UPDATE without WHERE"

echo "$lc" | grep -Eq '(^|[^a-z])(prod|production)([^a-z]|$)' \
  && echo "$lc" | grep -Eq '\b(psql|pg_dump|aws|kubectl)\b' && block "touching prod - run it yourself"

echo "$lc" | grep -Eq '\baws[[:space:]].*[[:space:]](delete|terminate|put-|modify-|update-)' \
  && block "AWS write operation - run it yourself"

exit 0

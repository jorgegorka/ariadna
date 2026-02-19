#!/usr/bin/env bash
# Ariadna statusline for Claude Code

input=$(cat)

# Require jq
if ! command -v jq &>/dev/null; then
  echo "ariadna: jq required for statusline"
  exit 0
fi

MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CWD=$(echo "$input" | jq -r '.cwd // ""')

# Scale to 80% effective limit (Claude Code compresses at ~80%)
SCALED=$(( PCT * 100 / 80 ))
[ "$SCALED" -gt 100 ] && SCALED=100

# Color based on scaled percentage
if [ "$SCALED" -ge 80 ]; then
  COLOR='\033[31m'    # Red
elif [ "$SCALED" -ge 60 ]; then
  COLOR='\033[33m'    # Yellow
else
  COLOR='\033[32m'    # Green
fi

# Progress bar (10 chars)
FILLED=$(( SCALED / 10 ))
EMPTY=$(( 10 - FILLED ))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# Phase info from STATE.md
PHASE=""
if [ -n "$CWD" ] && [ -f "$CWD/.ariadna_planning/STATE.md" ]; then
  PHASE=$(grep -m1 '^Phase:' "$CWD/.ariadna_planning/STATE.md" | sed 's/^Phase:[[:space:]]*//')
fi

# Build output
DIM='\033[2m'
RESET='\033[0m'
if [ -n "$PHASE" ]; then
  echo -e "${DIM}${MODEL}${RESET} │ ${PHASE} ${COLOR}${BAR}${RESET} ${PCT}%"
else
  echo -e "${DIM}${MODEL}${RESET} ${COLOR}${BAR}${RESET} ${PCT}%"
fi

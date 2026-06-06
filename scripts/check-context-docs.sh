#!/usr/bin/env bash
# Pre-commit hook: warn if .tf files changed but context docs didn't.
# Not a blocker — just a reminder. Exit 0 always.

set -euo pipefail

CONTEXT_FILES=(
  "AGENTS.md"
  "docs/STATUS.md"
  "docs/ARCHITECTURE.md"
)

# Files staged for commit
STAGED=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

# Check if any .tf files are staged
TF_CHANGED=$(echo "$STAGED" | grep -c '\.tf$' || true)

if [[ "$TF_CHANGED" -eq 0 ]]; then
  exit 0
fi

# Check if any context file was also staged
CONTEXT_UPDATED=0
for f in "${CONTEXT_FILES[@]}"; do
  if echo "$STAGED" | grep -q "^${f}$"; then
    CONTEXT_UPDATED=1
    break
  fi
done

if [[ "$CONTEXT_UPDATED" -eq 0 ]]; then
  echo ""
  echo "⚠  .tf files changed but no context docs updated."
  echo "   Review if any of these need a refresh:"
  echo "     - AGENTS.md          (module scope, conventions, dependency map)"
  echo "     - docs/STATUS.md     (project state, pending items)"
  echo "     - docs/ARCHITECTURE.md (dependency map, subnet layout)"
  echo ""
  echo "   Skip if the change doesn't affect project context."
  echo ""
fi

exit 0

#!/usr/bin/env bash
# dscli-flycheck.sh — Run Emacs flycheck on a file via emacsclient
# Usage: dscli-flycheck.sh <file-path> [timeout-seconds]
# Output: raw JSON to stdout (no outer Elisp quoting)

set -euo pipefail

FILE="$1"
TIMEOUT="${2:-30}"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULE_PATH="$PROJECT_ROOT/dscli-modules/dscli-flycheck.el"

if [ ! -f "$FILE" ]; then
    echo "{\"error\": \"file not found: $FILE\"}"
    exit 1
fi

if [ ! -f "$MODULE_PATH" ]; then
    echo "{\"error\": \"dscli-flycheck.el not found at: $MODULE_PATH\"}"
    exit 1
fi

ABS_FILE="$(realpath "$FILE")"

# emacsclient --eval returns the result via prin1 (Elisp print),
# which wraps strings in double-quotes with Elisp escaping.
# The inner Python strips this outer layer and outputs raw JSON.
emacsclient --eval "(progn (load-file \"$MODULE_PATH\") (dscli-flycheck-check-file-json \"$ABS_FILE\" $TIMEOUT))" 2>/dev/null \
    | python3 -c "
import sys, json
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
inner = json.loads(raw)
print(inner, end='')
"

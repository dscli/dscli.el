#!/bin/bash
# version-bump: bump dscli.el version, sync modules, commit & tag
set -euo pipefail

NEW_VER="${1:-}"
if [ -z "$NEW_VER" ]; then
    echo "Usage: bump.sh <version>"
    echo "Example: bump.sh 0.5.0"
    exit 1
fi

cd "$(git rev-parse --show-toplevel)"

# Safety: ensure workspace is clean
if ! git diff-index --quiet HEAD --; then
    echo "ERROR: workspace is dirty. Please commit or stash changes first."
    exit 1
fi

echo "=== Bumping version to v$NEW_VER ==="

# Capture changelog BEFORE commit (changes since last tag)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    CHANGELOG=$(git log --oneline "$LAST_TAG..HEAD" --format="- %s" | head -20)
else
    CHANGELOG=$(git log --oneline -20 --format="- %s")
fi

# Check README.md — warn if untouched this release cycle
if [ -f README.md ]; then
    if [ -n "$LAST_TAG" ]; then
        if git diff --quiet "$LAST_TAG..HEAD" -- README.md; then
            echo "⚠️  WARNING: README.md has NOT been modified since $LAST_TAG."
            echo "   Please review if feature descriptions are up to date."
            echo "   (hint: update README.md → commit → then re-run bump)"
            echo ""
        fi
    fi
fi

# 1. Update dscli.el (main version)
sed -i 's/^;; Version: .*/;; Version: '"$NEW_VER"'/' dscli.el
echo "  dscli.el → $NEW_VER"

# 2. Sync all module ;; Version: headers
for f in dscli-modules/*.el; do
    if grep -q '^;; Version:' "$f" 2>/dev/null; then
        sed -i 's/^;; Version: .*/;; Version: '"$NEW_VER"'/' "$f"
        echo "  $f → $NEW_VER"
    fi
done

# 3. Stage version changes
git add dscli.el dscli-modules/*.el

# 4. Commit
git commit -m "version: bump to v$NEW_VER"

# 5. Tag with changelog summary
TAG_MSG="v$NEW_VER
${CHANGELOG:-  (first tag)}"

git tag -a "v$NEW_VER" -m "$TAG_MSG"

echo ""
echo "=== Done ==="
echo "  Version:  v$NEW_VER"
echo "  Tag:      $(git describe --tags --abbrev=0)"
echo ""
echo "Next: git push && git push --tags"

#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "Usage: $0 TARGET_DIR [PROJECT_NAME]" >&2; exit 64; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$(realpath -m "$1")"
NAME="${2:-$(basename "$TARGET")}"
[[ ! -e "$TARGET" || -z "$(ls -A "$TARGET" 2>/dev/null)" ]] || { echo "Target is not empty: $TARGET" >&2; exit 1; }
mkdir -p "$TARGET"
cp -a "$ROOT/templates/project/." "$TARGET/"
sed -i "s/{{PROJECT_NAME}}/$NAME/g" "$TARGET/README.md" "$TARGET/PROJECT.md"
cp "$ROOT/CLAUDE.md" "$TARGET/CLAUDE.md"
cp -a "$ROOT/.claude/rules/." "$TARGET/.claude/rules/"
cp "$ROOT/.claude/settings.json" "$TARGET/.claude/settings.json"
mkdir -p "$TARGET/.claude/hooks"
cp "$ROOT/.claude/hooks/"*.sh "$TARGET/.claude/hooks/"
chmod +x "$TARGET/.claude/hooks/"*.sh
(cd "$TARGET" && git init >/dev/null && git add .)
printf 'Created governed project %s at %s\n' "$NAME" "$TARGET"

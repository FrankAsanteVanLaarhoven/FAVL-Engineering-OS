#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.claude"
if [[ -e "$HOME/.claude/CLAUDE.md" && ! -L "$HOME/.claude/CLAUDE.md" ]]; then
  cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
fi
ln -sfn "$ROOT/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude/rules"
for f in "$ROOT"/.claude/rules/*.md; do ln -sfn "$f" "$HOME/.claude/rules/$(basename "$f")"; done
printf 'Installed user-wide FAVL policy from %s\n' "$ROOT"

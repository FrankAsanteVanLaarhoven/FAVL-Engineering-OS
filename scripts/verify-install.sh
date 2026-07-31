#!/usr/bin/env bash
set -euo pipefail
[[ -r "$HOME/.claude/CLAUDE.md" ]] || { echo 'User policy missing.' >&2; exit 1; }
grep -q 'FAVL Engineering OS' "$HOME/.claude/CLAUDE.md"
printf 'User policy: PASS\n'
if [[ -r /etc/claude-code/CLAUDE.md ]]; then grep -q 'FAVL Engineering OS' /etc/claude-code/CLAUDE.md && echo 'Managed policy: PASS'; else echo 'Managed policy: not installed'; fi
command -v claude >/dev/null && claude --version || echo 'Claude Code CLI not found in PATH.'

#!/usr/bin/env bash
set -euo pipefail
payload="$(cat)"
path="$(printf '%s' "$payload" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path", ""))' 2>/dev/null || true)"
[[ -z "$path" ]] && exit 0
case "$path" in
  */constitution/*|*/standards/*|*/governance/*|*/CLAUDE.md|*/.claude/settings.json|*/.claude/hooks/*)
    printf 'BLOCKED: protected FAVL Engineering OS policy path. Make the change through the documented change-control process and a human-reviewed commit.\n' >&2
    exit 2
    ;;
esac
exit 0

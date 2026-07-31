#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
required=(README.md CLAUDE.md constitution/CONSTITUTION.md standards/ENGINEERING.md standards/SECURITY.md standards/AI_SYSTEMS.md governance/CHANGE_CONTROL.md .claude/settings.json)
for f in "${required[@]}"; do [[ -s "$f" ]] || { echo "Missing or empty: $f" >&2; exit 1; }; done
python3 -m json.tool .claude/settings.json >/dev/null
python3 - <<'PY'
from pathlib import Path
for p in Path('.').rglob('*.md'):
    s=p.read_text(encoding='utf-8')
    if '\r' in s: raise SystemExit(f'CRLF not permitted: {p}')
print('Markdown scan: PASS')
PY
bash -n scripts/*.sh .claude/hooks/*.sh
printf 'FAVL Engineering OS validation: PASS\n'

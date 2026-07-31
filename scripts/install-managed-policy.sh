#!/usr/bin/env bash
set -euo pipefail
[[ "$(id -u)" -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install -d -m 0755 /etc/claude-code
install -m 0444 "$ROOT/CLAUDE.md" /etc/claude-code/CLAUDE.md
cat > /etc/claude-code/managed-settings.json <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)"
    ]
  }
}
JSON
chmod 0444 /etc/claude-code/managed-settings.json
printf 'Installed managed FAVL policy under /etc/claude-code\n'

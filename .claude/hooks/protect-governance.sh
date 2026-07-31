#!/usr/bin/env bash
# FAVL Engineering OS -- PreToolUse governance gate.
#
# Denies agent writes to the paths listed in governance/PROTECTED_PATHS.txt.
#
# This gate FAILS CLOSED. A payload it cannot parse, a tool shape it does not
# recognise, a missing protected-paths file and a missing interpreter all
# produce a denial, because in each of those states the gate cannot prove the
# target is unprotected. The first revision failed open in all four cases.
#
# Exit codes: 0 allow, 2 deny (stderr is shown to the agent).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

payload="$(cat)"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'DENIED by the FAVL governance gate: python3 is unavailable, so this tool call cannot be inspected. Failing closed.\n' >&2
  exit 2
fi

tmp="$(mktemp)" || {
  printf 'DENIED by the FAVL governance gate: no temporary file available. Failing closed.\n' >&2
  exit 2
}
trap 'rm -f "$tmp"' EXIT
printf '%s' "$payload" >"$tmp"

python3 - "$tmp" "$ROOT" <<'PY'
import json
import os
import re
import sys

payload_path, root = sys.argv[1], sys.argv[2]
root_abs = os.path.abspath(root)


def deny(reason):
    sys.stderr.write(
        "DENIED by the FAVL Engineering OS governance gate.\n"
        "%s\n"
        "Protected policy changes go through governance/CHANGE_CONTROL.md: an ADR, "
        "owner approval, a version increment and a human-authored commit.\n" % reason
    )
    sys.exit(2)


paths_file = os.path.join(root_abs, "governance", "PROTECTED_PATHS.txt")
try:
    with open(paths_file, encoding="utf-8") as handle:
        protected = [
            line.strip()
            for line in handle
            if line.strip() and not line.lstrip().startswith("#")
        ]
except OSError as exc:
    deny("Cannot read governance/PROTECTED_PATHS.txt (%s); the protected set is unknown." % exc)

if not protected:
    deny("governance/PROTECTED_PATHS.txt is empty; the protected set is unknown.")

try:
    with open(payload_path, encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    deny("The tool payload was unreadable (%s); the target cannot be proven unprotected." % exc)

if not isinstance(data, dict):
    deny("The tool payload was not an object; the target cannot be proven unprotected.")


def is_protected(rel):
    for entry in protected:
        if entry.endswith("/"):
            if rel == entry.rstrip("/") or rel.startswith(entry):
                return entry
        elif rel == entry:
            return entry
    return None


def to_rel(raw):
    """Repository-relative POSIX path, or None when outside this repository."""
    if not raw or not isinstance(raw, str):
        return None
    candidate = os.path.expanduser(raw.strip().strip("'\""))
    if not candidate:
        return None
    if not os.path.isabs(candidate):
        candidate = os.path.join(root_abs, candidate)
    rel = os.path.relpath(os.path.abspath(candidate), root_abs)
    if rel in (os.curdir, os.pardir) or rel.startswith(os.pardir + os.sep):
        return None
    return rel.replace(os.sep, "/")


tool = data.get("tool_name") or ""
tool_input = data.get("tool_input")
if tool_input is None:
    tool_input = {}
if not isinstance(tool_input, dict):
    deny("tool_input was not an object for tool %r." % tool)

FILE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit", "Update", "Patch", "ApplyPatch"}

if tool in FILE_TOOLS:
    targets = [tool_input.get(key) for key in ("file_path", "notebook_path", "path", "target_file")]
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        targets += [e.get("file_path") for e in edits if isinstance(e, dict)]
    targets = [t for t in targets if t]
    if not targets:
        deny("%s carried no recognisable target path, so it cannot be proven unprotected." % tool)
    for target in targets:
        rel = to_rel(target)
        if rel:
            hit = is_protected(rel)
            if hit:
                deny("Blocked write to protected policy path %s (matched %r)." % (rel, hit))

elif tool == "Bash":
    command = tool_input.get("command")
    if command is None:
        deny("A Bash call carried no command string, so it cannot be inspected.")
    if not isinstance(command, str):
        deny("The Bash command was not a string.")
    # A shell-command scan is a blocklist and cannot be complete; see
    # docs/adr/0002-enforcement-hardening.md. It is defence in depth beneath
    # CODEOWNERS and branch protection, not a boundary. It errs towards denial,
    # so a read redirected out of a protected file is refused too.
    mutating = re.compile(
        r"(^|[;&|(`$]|\s)"
        r"(rm|mv|cp|ln|dd|sed|perl|awk|tee|truncate|install|chmod|chown|patch|touch|shred|sponge"
        r"|git\s+(checkout|restore|apply|rm|mv|clean|reset))\b"
        r"|>",
        re.IGNORECASE,
    )
    if mutating.search(command):
        for token in re.findall(r"[~\w./\\-]+", command):
            rel = to_rel(token)
            if rel:
                hit = is_protected(rel)
                if hit:
                    deny(
                        "Blocked a file-mutating shell command referencing protected policy "
                        "path %s (matched %r)." % (rel, hit)
                    )

sys.exit(0)
PY
exit $?

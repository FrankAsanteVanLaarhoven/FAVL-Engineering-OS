#!/usr/bin/env bash
# FAVL Engineering OS -- repository validator.
#
# This is the single validation entry point. CI runs exactly this script, so a
# local pass and a CI pass cannot mean different things.
#
# Usage:
#   ./scripts/validate-os.sh                     validate, exit non-zero on failure
#   ./scripts/validate-os.sh --update-checksums  regenerate the policy checksum manifest
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 - "$@" <<'PY'
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.getcwd()
UPDATE = "--update-checksums" in sys.argv[1:]

failures = []
skipped = []


def record(name, ok, detail=""):
    if ok:
        print("  [PASS] %s" % name)
    else:
        failures.append(name)
        print("  [FAIL] %s%s" % (name, (" -- " + detail) if detail else ""))


def section(title):
    print("\n%s" % title)


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as handle:
        return handle.read()


def read_list(path):
    return [
        line.strip()
        for line in read(path).splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def repo_files(exclude=()):
    for base, dirs, names in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != ".git"]
        for name in names:
            full = os.path.join(base, name)
            rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
            if rel in exclude:
                continue
            yield rel, full


def is_text(full):
    try:
        with open(full, "rb") as handle:
            chunk = handle.read(8192)
    except OSError:
        return False
    return b"\x00" not in chunk


# --------------------------------------------------------------- required set
section("Required files")
REQUIRED = [
    "CLAUDE.md", "README.md", "VERSION", "LICENSE", "NOTICE", ".attribution-allow",
    "constitution/CONSTITUTION.md",
    "standards/ENGINEERING.md", "standards/SECURITY.md", "standards/AI_SYSTEMS.md",
    "standards/DESIGN.md", "standards/TESTING.md", "standards/RESEARCH.md",
    "governance/CHANGE_CONTROL.md", "governance/EXCEPTIONS.md", "governance/OWNERS.yaml",
    "governance/PROTECTED_PATHS.txt",
    ".claude/settings.json",
    ".claude/hooks/protect-governance.sh", ".claude/hooks/inject-policy-context.sh",
    ".claude/rules/security.md", ".claude/rules/research.md", ".claude/rules/frontend.md",
    ".claude/skills/favl-review/SKILL.md",
    "scripts/validate-os.sh", "scripts/install-user-policy.sh",
    "scripts/install-managed-policy.sh", "scripts/verify-install.sh", "scripts/create-project.sh",
    ".github/CODEOWNERS", ".github/workflows/validate.yml",
    ".github/secret-patterns.txt", ".github/attribution-patterns.txt",
    "docs/adr/0001-policy-enforcement-model.md",
    "templates/project/PROJECT.md", "templates/project/README.md",
]
absent = [f for f in REQUIRED if not os.path.exists(os.path.join(ROOT, f))]
missing = [
    f for f in REQUIRED
    if f not in absent and os.path.getsize(os.path.join(ROOT, f)) == 0
]
record("all %d required files present and non-empty" % len(REQUIRED),
       not absent and not missing,
       "absent: %s empty: %s" % (absent, missing))

version = read("VERSION").strip()
record("VERSION is semantic (%s)" % version, bool(re.fullmatch(r"\d+\.\d+\.\d+", version)))

# ------------------------------------------------------------------- syntax
section("Shell and JSON")
shell_scripts = sorted(
    rel for rel, _ in repo_files()
    if rel.endswith(".sh") and (rel.startswith("scripts/") or rel.startswith(".claude/hooks/"))
)
for rel in shell_scripts:
    proc = subprocess.run(["bash", "-n", rel], capture_output=True, text=True)
    record("syntax %s" % rel, proc.returncode == 0, proc.stderr.strip())
    record("executable %s" % rel, os.access(os.path.join(ROOT, rel), os.X_OK))

try:
    settings = json.loads(read(".claude/settings.json"))
    record("settings.json parses", True)
except Exception as exc:
    settings = {}
    record("settings.json parses", False, str(exc))

matchers = [
    entry.get("matcher", "")
    for entry in settings.get("hooks", {}).get("PreToolUse", [])
]
covered = " ".join(matchers)
for tool in ("Edit", "Write", "MultiEdit", "NotebookEdit", "Bash"):
    record("PreToolUse gate covers %s" % tool, tool in covered)

# ------------------------------------------------- protected-path list drift
section("Protected-path consistency")
protected = read_list("governance/PROTECTED_PATHS.txt")
record("PROTECTED_PATHS.txt is non-empty", bool(protected))

for entry in protected:
    target = os.path.join(ROOT, entry.rstrip("/"))
    record("protected path exists: %s" % entry, os.path.exists(target))

owners_raw = read("governance/OWNERS.yaml")
owners_declared = re.findall(r"^\s*-\s*(\S+)\s*$", owners_raw, re.MULTILINE)
expected_owner_entries = [e + "**" if e.endswith("/") else e for e in protected]
missing_owner = [e for e in expected_owner_entries if e not in owners_declared]
extra_owner = [e for e in owners_declared if e not in expected_owner_entries]
record("OWNERS.yaml matches PROTECTED_PATHS.txt", not missing_owner and not extra_owner,
       "missing: %s unexpected: %s" % (missing_owner, extra_owner))

codeowners_raw = read(".github/CODEOWNERS")
codeowners_paths = [
    line.split()[0]
    for line in codeowners_raw.splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]
missing_co = ["/" + e for e in protected if "/" + e not in codeowners_paths]
record("CODEOWNERS covers PROTECTED_PATHS.txt", not missing_co, "missing: %s" % missing_co)

# --------------------------------------------------------- gate self-test
section("Governance gate behaviour")
HOOK = os.path.join(ROOT, ".claude/hooks/protect-governance.sh")
env = dict(os.environ, CLAUDE_PROJECT_DIR=ROOT)

CASES = [
    (2, "absolute protected path", '{"tool_name":"Edit","tool_input":{"file_path":"%s/constitution/CONSTITUTION.md"}}' % ROOT),
    (2, "relative protected path", '{"tool_name":"Edit","tool_input":{"file_path":"constitution/CONSTITUTION.md"}}'),
    (2, "MultiEdit edits[]", '{"tool_name":"MultiEdit","tool_input":{"edits":[{"file_path":"CLAUDE.md"}]}}'),
    (2, "NotebookEdit notebook_path", '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"standards/SECURITY.md"}}'),
    (2, "malformed payload fails closed", "not-json-at-all"),
    (2, "Bash sed -i", '{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ constitution/CONSTITUTION.md"}}'),
    (2, "Bash tee into rules", '{"tool_name":"Bash","tool_input":{"command":"echo x | tee .claude/rules/security.md"}}'),
    (2, "write to the validator itself", '{"tool_name":"Write","tool_input":{"file_path":"scripts/validate-os.sh"}}'),
    (2, "write to CODEOWNERS", '{"tool_name":"Write","tool_input":{"file_path":".github/CODEOWNERS"}}'),
    (0, "ordinary source write", '{"tool_name":"Write","tool_input":{"file_path":"templates/project/src/app.py"}}'),
    (0, "read-only shell", '{"tool_name":"Bash","tool_input":{"command":"ls -la standards/"}}'),
    (0, "path outside the repository", '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/unrelated.md"}}'),
]
for expected, label, payload in CASES:
    proc = subprocess.run([HOOK], input=payload, capture_output=True, text=True, env=env)
    record("gate %s -> %d" % (label, expected), proc.returncode == expected,
           "got %d" % proc.returncode)

# ------------------------------------------------------------------- content
section("Content scans")
text_files = [(rel, full) for rel, full in repo_files() if is_text(full)]

crlf = [rel for rel, full in text_files if "\r" in open(full, encoding="utf-8", errors="replace").read()]
record("no CRLF line endings", not crlf, "%s" % crlf[:5])

PATTERN_FILES = {".github/secret-patterns.txt", ".github/attribution-patterns.txt"}

attribution = re.compile("|".join(read_list(".github/attribution-patterns.txt")))
OWNER = re.compile(r"Frank Asante Van Laarhoven|FrankAsanteVanLaarhoven|frankleroyvan@gmail\.com")
CREDIT_LINE = re.compile(
    r"^\s*(Author|Authors|Contributor|Contributors|Maintainer|Maintainers|Credits|Credit"
    r"|Acknowledgements|Acknowledgments|Created by|Powered by)[\s:-]"
)
# Legal boilerplate is not attribution. Apache-2.0 contains lines opening with
# "Contributor ...", and the owner's global commit guard exempts these same
# filenames for the same reason. Secret scanning below still covers them.
LEGAL_FILES = {"LICENSE", "LICENSE.md", "LICENSE.txt", "NOTICE", "NOTICE.md", "NOTICE.txt", "COPYING"}

hits = []
for rel, full in text_files:
    if rel in PATTERN_FILES or rel in LEGAL_FILES:
        continue
    for number, line in enumerate(open(full, encoding="utf-8", errors="replace"), 1):
        if attribution.search(line) or (CREDIT_LINE.match(line) and not OWNER.search(line)):
            hits.append("%s:%d" % (rel, number))
record("no third-party attribution lines", not hits, "%s" % hits[:5])

# The pattern file cannot spell the phrases it detects, so prove each one still
# fires. Canaries are assembled here for the same reason.
attribution_canaries = [
    "Co-authored" + "-by: someone <x@y.z>",
    "Generated" + "-by: a tool",
    "AI" + "-generated content",
    "AI" + "-assisted delivery",
    "created with " + "AI",
    "powered by " + "AI",
    "b" + "ot account",
]
silent = [c for c in attribution_canaries if not attribution.search(c)]
record("attribution scanner fires on every canary", not silent, "silent: %s" % silent)

secret = re.compile("|".join(read_list(".github/secret-patterns.txt")))
canaries = [
    "AKIA" + "IOSFODNN7EXAMPLE",
    "gh" + "p_" + "A" * 36,
    "sk-" + "ant-" + "x" * 24,
    "-----BEGIN " + "PRIVATE KEY-----",
]
record("secret scanner fires on every canary",
       all(secret.search(c) for c in canaries),
       "silent canary: %s" % [c[:12] for c in canaries if not secret.search(c)])

leaks = []
for rel, full in text_files:
    if rel in PATTERN_FILES:
        continue
    for number, line in enumerate(open(full, encoding="utf-8", errors="replace"), 1):
        if secret.search(line):
            leaks.append("%s:%d" % (rel, number))
record("no secret patterns in tree", not leaks, "%s" % leaks[:5])

# ---------------------------------------------------------------- checksums
section("Policy checksum manifest")
MANIFEST = "governance/POLICY_CHECKSUMS.sha256"


def under_protection(rel):
    for entry in protected:
        if entry.endswith("/"):
            if rel.startswith(entry):
                return True
        elif rel == entry:
            return True
    return False


policy_files = sorted(
    rel for rel, _ in repo_files() if under_protection(rel) and rel != MANIFEST
)
digest = {}
for rel in policy_files:
    with open(os.path.join(ROOT, rel), "rb") as handle:
        digest[rel] = hashlib.sha256(handle.read()).hexdigest()
rendered = "".join("%s  %s\n" % (digest[rel], rel) for rel in policy_files)

if UPDATE:
    with open(os.path.join(ROOT, MANIFEST), "w", encoding="utf-8") as handle:
        handle.write(
            "# sha256 of every file under governance/PROTECTED_PATHS.txt.\n"
            "# Regenerate after an approved policy change:\n"
            "#   ./scripts/validate-os.sh --update-checksums\n"
        )
        handle.write(rendered)
    print("  [ .. ] manifest rewritten with %d entries" % len(policy_files))
elif not os.path.exists(os.path.join(ROOT, MANIFEST)):
    record("manifest present", False, "run --update-checksums")
else:
    recorded = {}
    for line in read(MANIFEST).splitlines():
        if line.strip() and not line.lstrip().startswith("#"):
            value, _, name = line.partition("  ")
            recorded[name.strip()] = value.strip()
    changed = [r for r in policy_files if recorded.get(r) != digest[r]]
    dropped = [r for r in recorded if r not in digest]
    record("policy files match the manifest", not changed and not dropped,
           "changed: %s removed: %s" % (changed[:5], dropped[:5]))

# ------------------------------------------------------------------- verdict
print("")
if failures:
    print("FAVL Engineering OS validation: FAIL (%d)" % len(failures))
    for name in failures:
        print("  - %s" % name)
    sys.exit(1)
if skipped:
    print("Skipped: %s" % ", ".join(skipped))
print("FAVL Engineering OS validation: PASS")
PY

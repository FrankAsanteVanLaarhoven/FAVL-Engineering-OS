# FAVL Engineering OS

Canonical, version-controlled engineering governance for agent-supported software delivery across FAVL projects.

This repository separates:

1. **Behavioural policy** — concise instructions loaded by Claude Code.
2. **Executable enforcement** — hooks, scripts, CI, protected-file checks, and repository controls.
3. **Reusable delivery assets** — project templates, standards, ADRs, checklists, and skills.

## Authority hierarchy

1. Managed organisation policy (`/etc/claude-code/CLAUDE.md` on Linux/WSL)
2. User-wide policy (`~/.claude/CLAUDE.md`)
3. Project policy (`./CLAUDE.md` and `.claude/rules/`)
4. Approved ADRs and project specifications
5. Current task instructions

A lower layer may specialise a higher layer but must not silently weaken security, provenance, quality gates, or authorship controls.

## Install globally on Linux/WSL

```bash
git clone https://github.com/FrankAsanteVanLaarhoven/FAVL-Engineering-OS.git ~/FAVL-Engineering-OS
cd ~/FAVL-Engineering-OS
./scripts/install-user-policy.sh
./scripts/verify-install.sh
```

For machine-enforced managed policy:

```bash
sudo ./scripts/install-managed-policy.sh
```

## Create a governed project

```bash
./scripts/create-project.sh ~/work/MyProduct MyProduct
```

## Validate this repository

```bash
./scripts/validate-os.sh
```

## What is actually enforced

Controls are labelled by what they can do, not by what they are named. A check
that reports but cannot block is not a gate.

| Control | Kind | Blocks what |
| --- | --- | --- |
| `.claude/hooks/protect-governance.sh` | technical, local | agent writes to `governance/PROTECTED_PATHS.txt` entries, via `Edit`, `Write`, `MultiEdit`, `NotebookEdit` or `Bash`. Fails closed. |
| `.claude/settings.json` deny rules | technical, local | the same paths again, one layer above the hook |
| `scripts/validate-os.sh` | technical, in CI | required files, shell syntax, executable bits, list drift, policy checksums, line endings, attribution lines, secret patterns |
| `.github/CODEOWNERS` + branch protection | technical, server-side | merges to protected paths without owner review |
| `CLAUDE.md`, `constitution/`, `standards/` | behavioural | nothing by itself; it informs the agent |

The local hook is defence in depth, not a boundary. Anyone with shell access can
edit these files directly, and the `Bash` scan is a blocklist that cannot be
complete. The enforcing boundary is the server side: CODEOWNERS plus branch
protection plus a required status check. Configure those on GitHub or the
guarantee is only as strong as the agent's cooperation.

`governance/PROTECTED_PATHS.txt` is the single source of truth for the protected
set. The hook, `OWNERS.yaml` and `CODEOWNERS` all derive from it, and
`validate-os.sh` fails if they drift apart.

`governance/POLICY_CHECKSUMS.sha256` pins the content of every protected file.
After an approved policy change, regenerate it with:

```bash
./scripts/validate-os.sh --update-checksums
```

## Non-goals

This repository does not prescribe one framework for every workload. Architecture must be selected from evidence, constraints, failure modes, operational requirements, and lifecycle cost. It forbids unjustified complexity and unjustified shortcuts equally.

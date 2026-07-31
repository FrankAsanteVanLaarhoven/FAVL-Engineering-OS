# FAVL Engineering OS

Canonical, version-controlled engineering governance for AI-assisted software delivery across FAVL projects.

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

## Non-goals

This repository does not prescribe one framework for every workload. Architecture must be selected from evidence, constraints, failure modes, operational requirements, and lifecycle cost. It forbids unjustified complexity and unjustified shortcuts equally.

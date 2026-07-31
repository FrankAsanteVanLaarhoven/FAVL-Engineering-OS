# FAVL Engineering OS

**Version-controlled engineering governance that is executed, not just documented.**

[![Validate Engineering OS](https://github.com/FrankAsanteVanLaarhoven/FAVL-Engineering-OS/actions/workflows/validate.yml/badge.svg)](https://github.com/FrankAsanteVanLaarhoven/FAVL-Engineering-OS/actions/workflows/validate.yml)
[![Version](https://img.shields.io/badge/version-0.2.0-informational)](VERSION)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![Policy gates](https://img.shields.io/badge/gate%20probes-14-success)](scripts/validate-os.sh)

FAVL Engineering OS is the canonical policy layer for every repository under
Frank Asante Van Laarhoven's ownership. It defines how software is designed,
secured, tested, evidenced and attributed, and it enforces those definitions
through mechanisms that operate whether or not any participant chooses to
cooperate.

---

## Contents

- [Overview](#overview)
- [Control model](#control-model)
- [Authority hierarchy](#authority-hierarchy)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Creating a governed project](#creating-a-governed-project)
- [Validation](#validation)
- [Change control](#change-control)
- [Security posture](#security-posture)
- [Compatibility](#compatibility)
- [Versioning](#versioning)
- [Ownership and licence](#ownership-and-licence)

---

## Overview

### The problem

Engineering standards usually live in prose: a handbook, a wiki page, a long
prompt. Prose describes intent well and constrains behaviour poorly. It cannot
stop a rushed change to a security policy, it cannot notice that a quality gate
was quietly disabled to obtain a green build, and it cannot tell you whether the
rule it states was actually applied.

The gap widens when automated coding agents participate in delivery. An agent
reads instructions and usually follows them, but "usually" is not a control, and
an instruction that is merely read can be reasoned around.

### What this provides

This repository separates three concerns that are normally conflated:

| Layer | Contents | Nature |
| --- | --- | --- |
| **Behavioural policy** | `CLAUDE.md`, `constitution/`, `standards/`, `.claude/rules/` | informs decisions |
| **Executable enforcement** | `.claude/hooks/`, `.claude/settings.json`, `scripts/validate-os.sh`, CI, CODEOWNERS | blocks actions |
| **Delivery assets** | `templates/`, `docs/adr/`, `.claude/skills/` | accelerates work |

Behavioural policy is authoritative about *what good looks like*. Executable
enforcement is authoritative about *what is permitted to happen*. The two are
kept deliberately distinct so neither is mistaken for the other.

---

## Control model

Controls are classified by what they can actually do. A check that reports but
cannot block is not a gate, and is never described as one here.

| Control | Class | Prevents |
| --- | --- | --- |
| `.claude/hooks/protect-governance.sh` | technical, local | agent writes to any protected path, through file tools or the shell. Fails closed. |
| `.claude/settings.json` deny rules | technical, local | the same paths, one layer above the hook |
| `scripts/validate-os.sh` | technical, in CI | missing files, shell syntax errors, lost executable bits, protected-list drift, policy tampering, third-party attribution, committed secrets |
| `.github/CODEOWNERS` + branch protection | technical, server-side | merges to protected paths without owner review |
| `governance/CHANGE_CONTROL.md` | procedural | undocumented policy amendment |
| `constitution/`, `standards/`, `CLAUDE.md` | behavioural | nothing on its own; it informs the agent |

### Single source of truth

`governance/PROTECTED_PATHS.txt` defines the protected set. The runtime hook
reads it, `governance/OWNERS.yaml` and `.github/CODEOWNERS` are derived from it,
and validation fails if any of the three drift apart. Before this file existed
the three lists were maintained independently and had already diverged, so a
path could appear protected in one place while remaining writable in the others.

### Tamper evidence

`governance/POLICY_CHECKSUMS.sha256` pins the content of every protected file.
An edit made outside the agent, outside review, or outside the change-control
process still fails validation on the next run.

---

## Authority hierarchy

1. Managed organisation policy — `/etc/claude-code/CLAUDE.md` on Linux and WSL
2. User-wide policy — `~/.claude/CLAUDE.md`
3. Project policy — `./CLAUDE.md` and `.claude/rules/`
4. Approved architecture decision records and project specifications
5. Current task instructions

A lower layer may make a higher layer stricter. It may not silently weaken
security, provenance, quality gates or authorship controls. Managed policy
cannot be overridden by project settings, which is why it is installed read-only
and by an explicit administrative action rather than by default.

---

## Repository layout

```text
FAVL-Engineering-OS/
├── CLAUDE.md                        canonical agent instructions (installed user-wide)
├── constitution/CONSTITUTION.md     eight articles; supersedes project convenience
├── standards/                       engineering, security, AI systems, design, testing, research
├── governance/
│   ├── PROTECTED_PATHS.txt          single source of truth for the protected set
│   ├── POLICY_CHECKSUMS.sha256      tamper evidence for every protected file
│   ├── CHANGE_CONTROL.md            how policy is amended
│   ├── EXCEPTIONS.md                time-bounded exception register
│   └── OWNERS.yaml                  ownership and review requirements
├── .claude/
│   ├── settings.json                permissions and hook wiring
│   ├── hooks/                       fail-closed governance gate, session policy context
│   ├── rules/                       path-scoped rules: security, research, frontend
│   └── skills/favl-review/          review skill
├── scripts/                         install, verify, validate, generate
├── templates/project/               governed project scaffold
├── docs/adr/                        architecture decision records
└── .github/                         CODEOWNERS, workflow, detection pattern sets
```

---

## Getting started

### Requirements

- Linux or WSL (macOS works for everything except the managed-policy path)
- `bash` 5.x, `python3` 3.9 or newer, `git` 2.30 or newer
- Administrative access, only for the optional managed-policy layer

### Install user-wide policy

```bash
git clone https://github.com/FrankAsanteVanLaarhoven/FAVL-Engineering-OS.git ~/FAVL-Engineering-OS
cd ~/FAVL-Engineering-OS
./scripts/install-user-policy.sh
./scripts/verify-install.sh
```

The installer symlinks `~/.claude/CLAUDE.md` and `~/.claude/rules/` into this
repository, so updating the repository updates active policy. An existing
user-wide policy file is copied to a timestamped backup first. Clone to a
permanent location: the symlink targets must remain valid.

### Install managed policy

```bash
sudo ./scripts/install-managed-policy.sh
```

This writes read-only policy to `/etc/claude-code/`. It applies to every session
on the machine and cannot be overridden by a project. Review the settings it
installs before running it.

### Verify

```bash
./scripts/verify-install.sh
```

---

## Creating a governed project

```bash
./scripts/create-project.sh ~/work/MyProduct MyProduct
```

The generated project receives the policy file, path-scoped rules, the
fail-closed governance gate, its own `governance/PROTECTED_PATHS.txt`, a project
charter, an ADR directory and an initialised repository with the scaffold
staged. It does not create a commit; authorship is yours to record.

---

## Validation

`scripts/validate-os.sh` is the single validation entry point. Continuous
integration runs exactly this script, so a local pass and a CI pass cannot mean
different things.

```bash
./scripts/validate-os.sh                     # validate; non-zero exit on failure
./scripts/validate-os.sh --update-checksums  # regenerate the policy manifest
```

It checks:

- **Structure** — every required file present and non-empty; semantic `VERSION`
- **Executability** — shell syntax across all scripts and hooks; executable bits intact
- **Configuration** — settings parse; the gate is wired to every file-mutating tool
- **List consistency** — `PROTECTED_PATHS.txt`, `OWNERS.yaml` and `CODEOWNERS` agree
- **Gate behaviour** — 14 probes drive the real hook: nine denials it must make, five ordinary operations it must allow, including two in a generated project's context
- **Content** — line endings, third-party attribution lines, secret patterns
- **Tamper evidence** — every protected file matches the checksum manifest

Detection patterns live in `.github/secret-patterns.txt` and
`.github/attribution-patterns.txt`, outside the code that runs them, and each
scanner proves itself against constructed canaries before reporting a pass. A
scanner that has been blunted fails validation instead of returning a quiet
green.

---

## Change control

Protected paths are closed to the agent by design, so policy amendments are
authored by the owner. The full procedure is in
[`governance/CHANGE_CONTROL.md`](governance/CHANGE_CONTROL.md):

1. Record the decision as an ADR under `docs/adr/`
2. Make the change, mirroring any protected-path edit into `OWNERS.yaml` and `CODEOWNERS`
3. Increment `VERSION`
4. Regenerate the manifest with `./scripts/validate-os.sh --update-checksums`
5. Confirm `./scripts/validate-os.sh` passes
6. Open a pull request; merge requires owner review and a green required check

Emergency deviations are time-bounded, recorded in
[`governance/EXCEPTIONS.md`](governance/EXCEPTIONS.md) with compensating
controls and an expiry date, and reviewed retrospectively.

---

## Security posture

### What is enforced

The local gate is a technical control over agent-initiated writes. It covers
file-editing tools and shell commands, resolves relative and absolute paths
against the repository root, ignores paths outside the repository, and denies
whenever it cannot prove a target is unprotected — an unparseable payload, an
unrecognised tool shape, a missing protected-path file or a missing interpreter
all result in refusal.

### What is not

The local gate is defence in depth, not a boundary:

- Anyone with shell access can edit these files directly. The gate governs the
  agent, not the operator.
- The shell-command scan is a blocklist and cannot be complete. It errs towards
  denial, so reading a protected file and redirecting the output is also refused.
- Behavioural policy remains advisory by construction.

**The enforcing boundary is server-side.** Configure the following on the
default branch, or this repository's guarantees are stronger on paper than in
practice:

- require a pull request before merging
- require review from a CODEOWNER
- require the `Validate Engineering OS` status check
- prohibit force pushes and branch deletion
- require conversation resolution

Rationale, reproduced failure modes and residual risk are recorded in
[`docs/adr/0002-enforcement-hardening.md`](docs/adr/0002-enforcement-hardening.md).

### Reporting

Report a suspected weakness privately to the owner. Do not open a public issue
containing exploit detail against a live system.

---

## Compatibility

| Component | Supported |
| --- | --- |
| Linux, WSL | full, including managed policy |
| macOS | all layers except `/etc/claude-code` |
| Windows without WSL | unsupported |
| Continuous integration | GitHub Actions, `ubuntu-latest` |

No runtime dependencies beyond `bash`, `python3` and `git`. Nothing is fetched
at validation time.

---

## Versioning

`VERSION` uses semantic versioning and applies to the policy set as a whole.

- **major** — an article is removed or materially weakened
- **minor** — an article, standard or enforcement mechanism is added or strengthened
- **patch** — clarification with no change in obligation

Every version increment is accompanied by an ADR, per Article VI.

## Non-goals

This repository does not prescribe one framework for every workload.
Architecture is selected from evidence, constraints, failure modes, operational
requirements and lifecycle cost. Unjustified complexity and unjustified
shortcuts are refused equally.

## Ownership and licence

This repository is owned by Frank Asante Van Laarhoven. All commits, metadata
and artefacts carry a single identity, as required by Article VII of the
constitution.

Licensed under the Apache Licence 2.0. See [`LICENSE`](LICENSE) and
[`NOTICE`](NOTICE).

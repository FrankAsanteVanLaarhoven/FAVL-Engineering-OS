# ADR-0002: Enforcement hardening and a single protected-path source

- Status: Accepted
- Date: 2026-07-31
- Owner: Frank Asante Van Laarhoven
- Supersedes in part: ADR-0001 (the enforcement model is unchanged; its implementation was not sound)

## Context

ADR-0001 chose a layered model: behavioural policy, local hooks and permissions, then CI and branch protection. The model is right. The first implementation of it was audited on 2026-07-31 before the repository was published, and the executable layers did not do what the documents claimed.

Reproduced findings:

1. The `PreToolUse` gate blocked one case out of six. It read only `tool_input.file_path`, so a `MultiEdit` payload passed. It matched only `Edit|Write`, so `Bash` was never dispatched to it at all and `sed -i` on the constitution was unimpeded. Its `case` patterns required a leading path segment, so a relative path passed. Its parse was wrapped in `|| true` followed by `[[ -z "$path" ]] && exit 0`, so an unreadable payload was treated as permission to proceed. `scripts/validate-os.sh` and `.github/CODEOWNERS` were not in its protected set, so the agent could rewrite the validator and the reviewer list.

2. The CI secret scan matched itself. The pattern list was inline in `.github/workflows/validate.yml` and contained the literal `sk-ant-`, which the scan then found in that file. The required status check would have failed on every commit from the first push onward.

3. The repository could be pushed but not committed to again. The owner's global `pre-commit` guard rejects external vendor names unless the path appears in a repository-root `.attribution-allow`, and this repository must contain those names because it configures that tool. The initial commit predated the guard.

4. `scripts/install-user-policy.sh` symlinks the repository `CLAUDE.md` over `~/.claude/CLAUDE.md`. That file carried neither the ownership rule nor the context-budget rule, and the constitution had no ownership article. Installing would have removed the ownership rule from the active instruction set, which is the rule the rest of this repository exists to serve.

5. `governance/OWNERS.yaml`, `.github/CODEOWNERS` and the hook's own patterns were three independently written lists of protected paths, and they had already drifted. A path could look protected in one and be writable in the others.

## Decision

- `governance/PROTECTED_PATHS.txt` becomes the single source of truth. The hook reads it at runtime; `OWNERS.yaml` and `CODEOWNERS` derive from it; `validate-os.sh` fails if any of the three drift.
- The gate fails closed. An unparseable payload, an unrecognised tool shape, a missing protected-paths file or a missing interpreter all deny. It covers `Edit`, `Write`, `MultiEdit`, `NotebookEdit` and `Bash`, resolves relative and absolute paths against the repository root, and ignores paths outside the repository.
- Detector patterns move out of the code that runs them, into `.github/secret-patterns.txt` and `.github/attribution-patterns.txt`, and the pattern files are excluded from their own scan. The secret scanner proves itself against constructed canaries and refuses to report a pass if any canary goes undetected.
- `validate-os.sh` is the only validation entry point; CI runs exactly it. It executes the gate against twelve payloads, nine expected to deny and three expected to allow, so the gate's behaviour is a tested property rather than a claim.
- `governance/POLICY_CHECKSUMS.sha256` pins the content of every protected file, so an out-of-band edit is visible even when it was made outside the agent.
- Article VII of the constitution states the ownership rule, and `CLAUDE.md` restates it alongside the context-budget rule so that installing user-wide or managed policy is not lossy.

## Consequences

The local gate is now a technical control for agent-initiated writes. It is still not a boundary: anyone with shell access edits these files directly, and the `Bash` scan is a blocklist that cannot be complete. It deliberately errs towards denial, so reading a protected file and redirecting the output elsewhere is refused too.

The enforcing boundary remains server-side, and it is not yet configured: branch protection on `main` requiring pull requests, owner review through CODEOWNERS, and `Validate Engineering OS` as a required status check. Until those are set, this repository documents its guarantees more strongly than it enforces them.

`.attribution-allow` narrows the owner's global name guard for this repository's policy paths. It does not narrow the attribution guard, which still blocks co-author trailers, origination notes and third-party credit lines on every path including the allowlisted ones.

The checksum manifest must be regenerated after each approved policy change with `./scripts/validate-os.sh --update-checksums`, and a stale manifest fails validation. That friction is the point.

# Change Control

Constitutional or cross-project standard changes require:
1. a proposed ADR;
2. motivation and evidence;
3. affected repositories and migration plan;
4. security, privacy, operational and compatibility impact;
5. owner approval;
6. updated policy version and checksum manifest;
7. successful validation.

Emergency exceptions must be time-bounded, attributable, logged in `governance/EXCEPTIONS.md`, and followed by retrospective review.

## Carrying out an approved change

The protected set lives in `governance/PROTECTED_PATHS.txt`. Editing anything it
covers is denied to the agent by `.claude/hooks/protect-governance.sh`, so a
policy change is authored by the owner, not delegated.

1. Write the ADR under `docs/adr/`.
2. Make the edit, and mirror any protected-path change into `governance/OWNERS.yaml` and `.github/CODEOWNERS`. Validation fails if those drift from `PROTECTED_PATHS.txt`.
3. Increment `VERSION`.
4. Regenerate the checksum manifest required by item 6 above:

   ```bash
   ./scripts/validate-os.sh --update-checksums
   ```

5. Run `./scripts/validate-os.sh` and confirm it passes.
6. Open a pull request. Merge requires owner review through CODEOWNERS and the `Validate Engineering OS` check, once branch protection is configured.

# Security Standard

Mandatory controls:
- threat model material trust boundaries and abuse cases;
- authenticate identities and authorise every protected operation;
- least-privilege credentials with rotation and revocation;
- encrypt sensitive data in transit and at rest where applicable;
- validate input, encode output, parameterise data access;
- rate-limit exposed operations and constrain resource consumption;
- redact secrets and sensitive data from logs and telemetry;
- pin and scan dependencies and container images;
- record security-relevant actions in tamper-evident audit trails;
- design secure failure, recovery, backup, and incident response.

Never place secrets in repositories, examples, fixtures, screenshots, prompts, generated output, or CI logs.

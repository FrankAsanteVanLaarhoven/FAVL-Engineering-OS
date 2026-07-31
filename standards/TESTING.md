# Verification and Testing Standard

Use a risk-based test strategy:
- unit tests for domain rules and edge cases;
- contract and integration tests at boundaries;
- end-to-end tests for critical user journeys;
- security tests for trust boundaries and abuse cases;
- migration and rollback tests for persistent data;
- load, soak, resilience, and recovery tests where operational risk warrants them;
- AI evaluations for accuracy, calibration, safety, refusal, injection resistance, and regression.

Tests must fail for the defect they claim to detect. Do not weaken assertions or exclude failing cases without documented justification.

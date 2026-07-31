# Engineering Standard

## Architecture
Start with the simplest architecture that satisfies the measured constraints. Establish bounded modules, explicit ownership, stable interfaces, and dependency direction. Distribution requires a documented reason such as independent scaling, isolation, release cadence, regulatory boundary, or team ownership.

## Code
Use strong typing where supported, cohesive modules, deterministic behaviour, meaningful names, explicit error handling, configuration validation, and dependency injection at external boundaries. Avoid duplication, global mutable state, magic values, speculative abstractions, and unbounded retries.

## Data
Define schemas, ownership, retention, classification, lineage, migrations, backup, restoration, deletion, and integrity controls. Production migrations require forward and rollback plans.

## Reliability
Define service objectives, health checks, timeouts, retry budgets, idempotency, circuit breaking where applicable, graceful degradation, capacity assumptions, and incident ownership.

## Definition of Done
A change is complete only when acceptance criteria are met; tests pass; security, privacy, accessibility, operational and migration implications are handled; documentation is current; observed limitations are disclosed; and rollback is understood.

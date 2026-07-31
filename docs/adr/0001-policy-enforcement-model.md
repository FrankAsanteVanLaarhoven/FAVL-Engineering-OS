# ADR-0001: Layered policy enforcement

- Status: Accepted
- Date: 2026-07-31
- Owner: Frank Asante Van Laarhoven

## Context
Language-model instructions guide behaviour but do not guarantee enforcement.

## Decision
Use managed/user/project `CLAUDE.md` for persistent behavioural context, path-scoped rules for relevance, hooks and permissions for executable constraints, and CI plus protected branches for repository enforcement.

## Consequences
The system remains portable and auditable, but machine-level installation and GitHub branch protection are still required. No prompt can make policy mathematically immutable.

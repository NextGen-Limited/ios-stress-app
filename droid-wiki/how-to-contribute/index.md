# How to contribute

This is a single-developer project with a fast-moving main branch. The conventions below keep the codebase navigable as features land quickly.

## Picking up work

- The product roadmap lives at `docs/project-roadmap.md`. Milestones and ship status are tracked there.
- `docs/KANBAN-SHIP-READINESS.md` tracks the current release candidate status (B1, B2, B3).
- Implementation phase plans live in `documentation/references/` and `docs/plans/`.

## Branch and PR cycle

1. Branch from `main` with a descriptive name (e.g., `feat/dashboard-hero`, `fix/cloudkit-sync`).
2. Keep branches short-lived; rebase onto `main` before opening a PR.
3. PRs should be focused: one feature or one fix per PR. The June 2026 UI work was split into per-screen PRs (`#37` through `#45`) which is the preferred granularity.
4. Use [conventional commit](https://www.conventionalcommits.org/) prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`. Scope with parentheses when helpful: `feat(home):`, `fix(watch):`.

## Definition of done

- The change builds cleanly for the affected target(s) with no warnings.
- Existing tests pass.
- New code follows the patterns in [Patterns and conventions](patterns-and-conventions.md).
- Stress category UI changes update color, icon, and pattern together (dual coding).
- Any new persisted field has a migration story (see [Persistence](../systems/persistence.md)).
- No secrets, API keys, or user credentials in commits.

## Code review

- Self-review the diff before requesting review.
- Verify file references in any documentation you write use full repo-root paths.
- Run `git diff --cached` before committing to catch unintended changes.

See also: [Development workflow](development-workflow.md), [Testing](testing.md), [Debugging](debugging.md), [Tooling](tooling.md).

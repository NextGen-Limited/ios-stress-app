---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Submission Readiness
status: planning
last_updated: "2026-09-03T05:00:00.000Z"
last_activity: 2026-09-03
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-03 at v1.2 start)

**Core value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Current focus:** Phase 1 — Binary & Manifest Truth (opens with the D3/D4 decision gate)

## Current Position

Phase: 1 of 4 (Binary & Manifest Truth)
Plan: — (none yet)
Status: Ready to plan
Last activity: 2026-09-03 — v1.2 roadmap created (4 phases, 19/19 requirements mapped)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 18 (v1.0 + v1.1, both closed)
- Average duration: ~22 min/plan (v1.1 sample)
- Total execution time: not tracked cumulatively

**By Phase (v1.2):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 0 | - | - |
| 2 | 0 | - | - |
| 3 | 0 | - | - |
| 4 | 0 | - | - |

Per-plan history for v1.0/v1.1 archived under `.planning/milestones/v1.0-phases/` and `.planning/milestones/v1.1-phases/`.

**Recent Trend:**

- Last 5 plans (v1.1 Phase 3): 2448s, 14min, 14min, 22min, 28min
- Trend: Stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full log in PROJECT.md Key Decisions. v1.1 per-phase decisions archived with their phase artifacts. Carried forward because they constrain v1.2 work:

- [v1.1 P01, 2026-08-16]: `xcodebuild test` works only with `-parallel-testing-enabled NO` (parallel clones fail: XCTestDevices/Mach -308) — BUILD-04 codifies this in CI + dev docs
- [v1.1 P02, DEC-1/DEC-2]: monetization = server-authoritative credits + consumable packs + premium tier; this is the payload/entitlement shape SHIP-03's privacy answers and ENV-03's WR-03/WR-04 advisories describe
- [v1.1 P03]: chat payload carries derived stress scores (not raw HealthKit) under a Bearer-authenticated session — the factual basis D3 must be decided against
- [v1.1 P03-04]: in-memory `ModelContainer` must outlive its `mainContext` in tests; return-context-only fixtures are the WINDOWS.md #8 crash lineage (ENV-01 input)
- [v1.1 P03-05, ledger #12]: `RequestCaptureURLProtocol` statics leak across suites (order-dependent pollution) — relevant when ENV-01/ENV-02 make suite ordering deterministic
- [v1.2 roadmap, 2026-09-03]: phase numbering restarts at 1 for this milestone (project convention, matching v1.0 and v1.1)

### Pending Todos

None yet.

### Blockers/Concerns

- **D3 (Privacy contract authority)** — root `CLAUDE.md`'s "HealthKit never sent" claim vs. `StressContextPayload.swift`'s actual derived-score payload. **Gates BUILD-01 (Phase 1) and SHIP-03 (Phase 4). Must be resolved at Phase 1 discuss, before any Phase 1 implementation task.**
- **D4 (Widget in v1)** — ship the widget target or exclude it. **Gates WIRE-01 and scopes BUILD-01/02/03 to two bundles or three. Must be resolved at Phase 1 discuss.**
- D2 (CloudKit encryption) resolved in practice (encryptedValues shipped v1.0 Phase 2) but never recorded as a formal decision — close opportunistically.
- `CharacterEntitlementSyncTests` quarantined (`@Suite(.disabled)`), root cause undiagnosed after 5 ruled-out hypotheses — ENV-02 (Phase 2).
- WINDOWS.md #8 host CoreSimulator cold-launch crash on DataDeletion/DataExport suites (exit 65, 0 assertion failures) — accepted lineage, ENV-01 (Phase 2).
- v1.1 Phase 2 advisory residue: WR-03 (DEBUG money path uses `MockStoreKitService`) and WR-04 (`.unverified` consumables finished) — ENV-03 (Phase 2).
- [Branch] `git.base_branch` is `main`, strategy `milestone`; the v1.2 milestone branch (`gsd/v1.2-submission-readiness`) is not yet cut. Working tree also carries an uncommitted SPM-proxy migration that cannot archive (snapshot at `.asc/backup/spm-migration/`) — resolve before Phase 1's archive-producing tasks (BUILD-01, AUTH-01).
- [Release] TestFlight 1.0.0 build 13 is BETA_APPROVED; build 12 shipped with no entitlements blob — dump entitlements per bundle before every publish (affects Phase 1 BUILD-02 verification and Phase 4).
- Pending from v1.1: Phase 03 drift re-test (5 UAT scenarios, `.planning/milestones/v1.1-phases/03-sessions-preferences-quick-actions-cleanup.1/03-UAT.md`) against build 13 — not a v1.2 requirement, but the last open v1.1 item.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260811-t0l | Fix CI failure in .github/workflows/_test.yml: resolve simulator UDID dynamically | 2026-08-11 | 7864b95 | [260811-t0l-…](./quick/260811-t0l-fix-ci-failure-in-github-workflows-test-/) |
| 260829-kby | Firebase bootstrap state + AuthServiceError taxonomy (CI provisioning deferred) | 2026-08-29 | 6227803 | [260829-kby-…](./quick/260829-kby-provision-googleservice-info-plist-in-ci/) |
| 260901-vfd | Fix `Color.stressColor(for: Double)` threshold bug | 2026-09-01 | cf2dc8c | [260901-vfd-…](./quick/260901-vfd-fix-color-stresscolor-for-double-thresho/) |
| 4 | Update Settings UI to approved redesign direction (cream canvas, plain surface cards) | 2026-09-02 | 2b84862 | — |

## Deferred Items

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| uat_gap | v1.1 Phase 03 drift re-test (5 scenarios vs TestFlight build 13) | pending | 2026-09-03 | v1.1 |
| doc_gap | DOCS-01 — Nyquist VALIDATION.md reconciliation for v1.1 phases 1-3 | v2 backlog | 2026-09-03 | v1.1 |

Earlier v1.0 deferrals (Phase 01/02 verification gaps, `MockStoreKitService` Release blocker) are all closed — see PROJECT.md Validated.

## Session Continuity

Last session: 2026-09-03 — v1.2 roadmap created
Stopped at: ROADMAP.md written (4 phases), REQUIREMENTS.md traceability filled (19/19 mapped)
Resume file: .planning/HANDOFF.json (release-session handoff, still valid for build-13 context)

## Operator Next Steps

- Cut the v1.2 milestone branch and resolve the uncommitted SPM-proxy migration in the working tree
- `/gsd-discuss-phase 1` — resolve D3 (privacy contract authority) and D4 (widget in v1) before planning Phase 1

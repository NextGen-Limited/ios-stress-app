# Roadmap: StressMonitor

## Milestones

- ✅ **v1.0 App Store Submission Remediation** — Phases 1, 1.1, 2, 3, 4, 5 (closed 2026-08-12, `override_closeout`)
- ✅ **v1.1 Backend API Migration** — Phases 1-3 (closed 2026-08-24, `verified_closeout`)

## Phases

<details>
<summary>✅ v1.0 App Store Submission Remediation (Phases 1, 1.1, 2, 3, 4, 5) — CLOSED 2026-08-12 (override_closeout)</summary>

- [~] Phase 1: Build Configuration & Widget Wiring (5/6 plans; verification `gaps_found`)
- [x] Phase 1.1: SwiftData Schema Migration Safety (1/1 plans; verification `passed`)
- [~] Phase 2: Data Integrity, Deletion & Consolidation (1/1 plans; verification `human_needed`, 3 pending UAT items)
- [~] Phase 3: Auth & Chat Availability (1/1 plans; never formally verified)
- [~] Phase 4: IAP Revenue Path (1/1 plans; never formally verified)
- [~] Phase 5: Store Readiness & Accessibility (1/1 plans; never formally verified)

Full phase detail archived at `.planning/milestones/v1.0-ROADMAP.md` and `.planning/milestones/v1.0-phases/`.

</details>

<details>
<summary>✅ v1.1 Backend API Migration (Phases 1-3) — CLOSED 2026-08-24 (verified_closeout)</summary>

- [x] Phase 1: Firebase Auth + API Client + Chat Migration (4/4 plans; verification `passed`, UAT 2/2) — completed 2026-08-16
- [x] Phase 2: Credits System + IAP Transition (8/8 plans; verification `passed` 29/29, live money-path smoke human-validated 2026-08-23) — completed 2026-08-23
- [x] Phase 3: Sessions, Preferences, Quick Actions + Cleanup (5/5 plans; verification `passed` 21/21, 5 live-backend UAT scenarios human-validated 2026-08-23) — completed 2026-08-23

Milestone audit: 21/21 requirements, 3/3 phases, 7/7 integration seams, 4/4 E2E flows, 0 gaps (status `tech_debt` — documented carryover only). SECURITY.md present for all phases, threats_open 0.

Full phase detail archived at `.planning/milestones/v1.1-ROADMAP.md` and `.planning/milestones/v1.1-phases/`.

</details>

## Next

No active milestone. Recommended (per v1.1 audit conclusion): a **v1.2 "submission readiness"** milestone closing the v1.0-carryover list — BUILD-01 (privacy manifest, gated on D3), BUILD-02/03/04-residual, DATA-01-residual/DATA-04, AUTH-01, WIRE-01 (gated on D4), SHIP-01..03, A11Y-01..05, plus environment debt (WINDOWS.md #8, CharacterEntitlementSyncTests quarantine). Start with `/gsd-new-milestone`.

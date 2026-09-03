---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Submission Readiness
current_phase: 1
current_phase_name: Binary & Manifest Truth
status: executing
stopped_at: Completed 01-03-PLAN.md (plist single-source + media-residue removal)
last_updated: "2026-09-03T08:53:44.391Z"
last_activity: 2026-09-03
last_activity_desc: Phase 1 execution started
state_head: 8557ba37de9402f47f2bfc9021212bcb96b23485
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 5
  completed_plans: 3
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-03 at v1.2 start)

**Core value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Current focus:** Phase 1 — Binary & Manifest Truth

## Current Position

Phase: 1 (Binary & Manifest Truth) — EXECUTING
Plan: 4 of 5
Status: Ready to execute
Last activity: 2026-09-03 — Phase 1 execution started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 18 (v1.0 + v1.1, both closed)
- Average duration: ~22 min/plan (v1.1 sample)
- Total execution time: not tracked cumulatively

**By Phase (v1.2):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 1 | 40 min | 40 min |
| 2 | 0 | - | - |
| 3 | 0 | - | - |
| 4 | 0 | - | - |

Per-plan history for v1.0/v1.1 archived under `.planning/milestones/v1.0-phases/` and `.planning/milestones/v1.1-phases/`.

**Recent Trend:**

- Last 5 plans (v1.1 Phase 3): 2448s, 14min, 14min, 22min, 28min
- Trend: Stable

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 1 P01 | 40 min | 3 tasks | 11 files |
| Phase 1 P2 | 8 min | 2 tasks | 4 files |
| Phase 01 P03 | 22 min | 2 tasks | 1 files |

## Accumulated Context

### Decisions

Full log in PROJECT.md Key Decisions. v1.1 per-phase decisions archived with their phase artifacts. Carried forward because they constrain v1.2 work:

- [v1.1 P01, 2026-08-16]: `xcodebuild test` works only with `-parallel-testing-enabled NO` (parallel clones fail: XCTestDevices/Mach -308) — BUILD-04 codifies this in CI + dev docs
- [v1.1 P02, DEC-1/DEC-2]: monetization = server-authoritative credits + consumable packs + premium tier; this is the payload/entitlement shape SHIP-03's privacy answers and ENV-03's WR-03/WR-04 advisories describe
- [v1.1 P03]: chat payload carries derived stress scores (not raw HealthKit) under a Bearer-authenticated session — the factual basis D3 must be decided against
- [v1.1 P03-04]: in-memory `ModelContainer` must outlive its `mainContext` in tests; return-context-only fixtures are the WINDOWS.md #8 crash lineage (ENV-01 input)
- [v1.1 P03-05, ledger #12]: `RequestCaptureURLProtocol` statics leak across suites (order-dependent pollution) — relevant when ENV-01/ENV-02 make suite ordering deterministic
- [v1.2 roadmap, 2026-09-03]: phase numbering restarts at 1 for this milestone (project convention, matching v1.0 and v1.1)
- [Phase 1]: Proxy shim products MUST use _proxied-style names distinct from upstream (Xcode PIF registers both shim and upstream products — Firebase collided exactly like GoogleSignIn; A4 remedy applied in 1afb401)
- [Phase 1]: spm-cache/ package sources stay uncommitted by repo gitignore convention ('regenerated locally'); tracked migration artifacts = pbxproj + Package.resolved; ENV-04 bar = archive-from-working-tree (proven 01-01)
- [Phase 1]: Phase 1 P02: Watch UserDefaults reason set = CA92.1 + 1C8F.1, scan-verified at execution time (4 .standard files + 3 suite files; zero delta vs research §5.3) — scan-then-declare is the standing pattern for required-reason declarations
- [Phase 1]: Phase 1 P02 (D3 applied): CLAUDE.md + EN/VI privacy policies corrected to the real contract (StressLLMService/StressAPIClient → https://stress-api.dropitx.site chat endpoint, Firebase Auth anonymous-or-Google) with zero Swift churn — docs move toward code, never the reverse
- [Phase 1]: Phase 1 P03: Xcode merges only the documented closed set of INFOPLIST_KEY_* settings — custom INFOPLIST_KEY_STOREKIT_* never contributed to any merged plist; the app Info.plist file was the sole live source, so BUILD-03 landed inverted: file kept, 12 dead build settings deleted (388efe5)
- [Phase 1]: Phase 1 P03: widget Info.plist retained as one-key NSExtension file — delete branch disproven empirically (fresh .appex product lacks NSExtensionPointIdentifier without the file; auto-injection does not happen)
- [Phase 1]: Phase 1 P03: Giphy dSYM stub script phase removed (definition + reference + section markers, 4098d8b); zero live Giphy/Kingfisher/exyte/MediaPicker references remain — unused-media removal fully landed

### Pending Todos

None yet.

### Blockers/Concerns

- **D3 (Privacy contract authority)** — root `CLAUDE.md`'s "HealthKit never sent" claim vs. `StressContextPayload.swift`'s actual derived-score payload. **Gates BUILD-01 (Phase 1) and SHIP-03 (Phase 4). Must be resolved at Phase 1 discuss, before any Phase 1 implementation task.**
- **D4 (Widget in v1)** — ship the widget target or exclude it. **Gates WIRE-01 and scopes BUILD-01/02/03 to two bundles or three. Must be resolved at Phase 1 discuss.**
- D2 (CloudKit encryption) resolved in practice (encryptedValues shipped v1.0 Phase 2) but never recorded as a formal decision — close opportunistically.
- `CharacterEntitlementSyncTests` quarantined (`@Suite(.disabled)`), root cause undiagnosed after 5 ruled-out hypotheses — ENV-02 (Phase 2).
- WINDOWS.md #8 host CoreSimulator cold-launch crash on DataDeletion/DataExport suites (exit 65, 0 assertion failures) — accepted lineage, ENV-01 (Phase 2).
- v1.1 Phase 2 advisory residue: WR-03 (DEBUG money path uses `MockStoreKitService`) and WR-04 (`.unverified` consumables finished) — ENV-03 (Phase 2).
- [Branch] `git.base_branch` is `main`, strategy `milestone`; v1.2 work rides `gsd/v1.2-submission-readiness` (cut 2026-09-03). ~~Working tree carries an uncommitted SPM-proxy migration that cannot archive~~ **ENV-04 RESOLVED (01-01)**: migration completed in place and committed (feb3bf1, 1afb401) — Firebase_proxy shims + `_proxied` renames, Package.resolved regains firebase-ios-sdk 11.15.0, Release archive producible from the working tree (`.asc/backup/spm-migration/` snapshot now historical, never restored).
- [Release] TestFlight 1.0.0 build 13 is BETA_APPROVED; build 12 shipped with no entitlements blob — dump entitlements per bundle before every publish (affects Phase 1 BUILD-02 verification and Phase 4). AUTH-01's empirical `strings` check can run against the shipped Release IPA/archive in `.asc/artifacts/` immediately — no rebuild needed (build 13 also re-proves the v1.0 Release-compile blocker stays dead).
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

Last session: 2026-09-03T08:53:36.489Z
Stopped at: Completed 01-03-PLAN.md (plist single-source + media-residue removal)
Resume file: None

## Operator Next Steps

- Resolve the uncommitted SPM-proxy migration in the working tree (Firebase proxy products + non-colliding GoogleSignIn naming) before Phase 1 archive work
- `/gsd-discuss-phase 1` — resolve D3 (privacy contract authority) and D4 (widget in v1) before planning Phase 1

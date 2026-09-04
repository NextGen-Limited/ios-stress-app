---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Submission Readiness
current_phase: 2
current_phase_name: Delete Correctness & Test-Suite Trust
status: executing
stopped_at: "Completed 02-05-PLAN.md (BUILD-04: AGENTS.md canonical CI-parity invocation + INFOPLIST_KEY doc-truth note; docs/TESTING.md replace-by-reference)"
last_updated: "2026-09-04T06:22:59.671Z"
last_activity: 2026-09-03
last_activity_desc: Phase 1 complete, transitioned to Phase 2
state_head: e3a4b873f86c09c987ab1646909709585168cbf3
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 12
  completed_plans: 11
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-03 at v1.2 start)

**Core value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Current focus:** Phase 1 — Binary & Manifest Truth

## Current Position

Phase: 2 (Delete Correctness & Test-Suite Trust) — IN EXECUTION
Plan: 6 of 6
Status: Ready to execute
Last activity: 2026-09-03 — 02-01 DATA-04 truthiness suite complete

Progress: [███░░░░░░░] 25% (1/4 phases)

## Performance Metrics

**Velocity:**

- Total plans completed: 6 (v1.0 + v1.1, both closed)
- Average duration: ~22 min/plan (v1.1 sample)
- Total execution time: not tracked cumulatively

**By Phase (v1.2):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 6 | - | - |
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
| Phase 01 P04 | 58 min | 3 tasks | 3 files |
| Phase 1 P05 | 87 min | 2 tasks | 13 files |
| Phase 1 P06 | 17 min | 2 tasks | 5 files |
| Phase 02 P01 | 10 min | 2 tasks | 2 files |
| Phase 02 P02 | 9 min | 2 tasks | 2 files |
| Phase 02 P03 | 6 min | 2 tasks | 4 files |
| Phase 02 P04 | 40min | 3 tasks | 7 files |
| Phase 02 P05 | 25min | 2 tasks | 2 files |

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
- [Phase 01]: BUILD-02/AUTH-01 evidence-complete (plan 01-04): one suite group.stress.ai.com proven across entitlements+constants+tests+golden codesign dump; phase-final archive passes the credential gate with every strings hit dispositioned benign
- [Phase 01]: WIRE-01 RESOLVED per D4 — wire branch taken (plan 01-06): guarded save inside StressViewModel.loadCurrentStress (one StressMeasurement per new underlying HRV reading → repository.save → WidgetPublisher.publish → reloadAllTimelines) gives the widget its first live write path; every live foreground refresh now publishes the six latest_* keys. RED→GREEN proof in WidgetPublisherKeyMatchingTests (3 new tests, suite 5/5; full regression 217/217); simulator same-value evidence in 01-WIRE-01-EVIDENCE.md §8 (supersedes the 01-04 §2 empty-state pair). Physical-device confirmation remains the end-of-phase human item (§6).
- [Phase 1]: Phase 1 P05: deploy.yml dispatched only after explicit user approval recorded in 01-ENV-05-CI-RECORD.md before the dispatch timestamp — the standing gate for any TestFlight-visible action
- [Phase 1]: Phase 1 P05: ENV-05 GREEN — CI match(readonly) installs all three App Store profiles + K2TYLYAWMK Distribution cert with zero regeneration; readonly reads the match repo, never the portal dual-cert profiles, so the setup_match fallback stays unused and the path is idempotently repeatable
- [Phase 1]: Phase 1 P05: BUILD-01 SC-1 GREEN — TestFlight build 1.0.0 (14) from phase-final tree cleared ASC processing (state=VALID), no ITMS-91053 and no missing-SDK-manifest error; plan 02 manifest scan missed nothing
- [Phase 2]: [Phase 2 P01, DATA-04]: Ungated truthiness suite lands as a NEW sibling file (DataDeleterCloudKitTruthinessTests.swift), not inside the GSD_CI-gated DataDeletionConsolidationTests.swift — CI must see the CR-01 regression; registered in pbxproj (A026/B026)
- [Phase 2]: [Phase 2 P01]: One SeededCloudKitResetService double (.lying/.throwing/.draining) with exact-Int remainingRecords covers all three prongs — constructor-injected only, no statics (WINDOWS #12); emptiness asserted only by querying the store, never by the success return
- [Phase 2]: [Phase 2 P01]: Mutation run is the TDD red gate for regression suites guarding already-fixed bugs — suite green on HEAD, red under reintroduced CR-01 swallow (exit 65, prong-1 double detection: no-throw + local split-brain), green after revert (exit 0)
- [Phase 02]: [Phase 2 P02, WR-04]: Unverified transactions never finished — .unverified branch extracted to internal protocol-typed handleUnverifiedTransaction(_:) (VerificationResult<Transaction> is not test-constructible), finish deleted, redelivery-as-retry pinned red-first (finishCallCount == 0 single + redelivered)
- [Phase 02]: [Phase 2 P02]: The four completePurchase finish sites are verified-only by construction (checkVerified throws on .unverified before reach; handle(transaction:) entered only from .verified) — reachability note delivered, sites byte-unchanged; no runtime checks added inside the grant choke point
- [Phase 02]: [Phase 2 P03, WR-03]: DEBUG defaults to the real StoreKit service at BOTH wiring sites (app factory + StoreKitServiceKey.defaultValue) behind one shared MockIAPMode condition — mock resolves only via the -mock-iap launch arg (DemoMode shape, injectable arguments); pinned by StoreKitServiceWiringTests (RED 2 absent-flag failures, GREEN 16/16 with CreditPurchaseFlowTests); Release #else branches byte-unchanged
- [Phase 02]: [Phase 2 P03]: Minimal testability seam for a private factory — widen makeStoreKitService to internal static + an arguments parameter instead of extracting a resolver type; the pin asserts through the real factory, never by constructing services directly (Pitfall 4)
- [Phase 02]: [Phase 2 P04, ENV-01/ENV-02] WINDOWS #8 root cause found: fixture container-lifetime bug (return-context-only fixtures let the owning ModelContainer deallocate before the next SwiftData op), not a CI-host defect — fixed by converting to (ModelContainer, ModelContext) tuple fixtures; both #8-gated suites and CharacterEntitlementSyncTests permanently restored to the default run, GSD_CI/TEST_RUNNER_GSD_CI plumbing removed
- [Phase 02]: [Phase 2 P04] StoreKitServiceTests/EntitlementForegroundCorrectionTests productNotFound reproduces on TWO local simulators (not CI-runner-specific) — StoreKitTest daemon/session-isolation bug independent of IAP-01 product-ID registration (StoreKitProductCatalogLiveTests confirmed enabled+green, WINDOWS #7 closed); both suites stay dated-dispositioned (WINDOWS #6 open unchanged, #18 new entry), not re-enabled
- [Phase 2]: [Phase 02] [Phase 2 P05, BUILD-04] AGENTS.md is now the canonical CI-parity xcodebuild test invocation (flag-for-flag mirror of _test.yml's Run Tests step); docs/TESTING.md reduced to a pointer-only cross-reference (locked replace-not-extend decision) — zero divergence risk between what CI runs and what dev docs tell a human to run
- [Phase 2]: [Phase 02] [Phase 2 P05] INFOPLIST_KEY_* doc-truth note added to AGENTS.md folding in the Phase-1 UIBackgroundModes finding: custom INFOPLIST_KEY_* settings never merge into product plists on this toolchain — the Info.plist file is the source of truth

### Pending Todos

None yet.

### Blockers/Concerns

- ~~**D3 (Privacy contract authority)**~~ **RESOLVED (v1.2 P1)**: code is the contract — docs moved toward StressContextPayload, zero payload churn; gates BUILD-01 (validated) and SHIP-03 (Phase 4, unblocked).
- ~~**D4 (Widget in v1)**~~ **RESOLVED (v1.2 P1)**: keep the widget and make it true — write path wired (01-06), device-verified; WIRE-01 validated.
- D2 (CloudKit encryption) resolved in practice (encryptedValues shipped v1.0 Phase 2) but never recorded as a formal decision — close opportunistically.
- v1.1 Phase 2 advisory residue: WR-03 (DEBUG money path uses `MockStoreKitService`) and WR-04 (`.unverified` consumables finished) — ENV-03 (Phase 2).
- [Phase 2 input] `INFOPLIST_KEY_UIBackgroundModes` never merges into product plists (absent from build-13 too — pre-existing) — folds into BUILD-04 doc-truth work.
- [Phase 1 code review] 7 Info findings carried as documented debt (01-REVIEW.md): scan-pattern gaps (AKIA/ghp_/xox-), allowlist masking removed supabase literals, stale STOREKIT comment, widget-README/CLAUDE.md staleness, pbxproj churn, transitive-pin drift (GoogleUtilities 8.1.2→8.1.3).
- [Release] TestFlight 1.0.0 build 13 is BETA_APPROVED; build 14 (v1.2 P1, VALID) predates the WIRE-01 fix — its widget shows "No Data"; the next build carries the wiring. Build 12 shipped with no entitlements blob — dump entitlements per bundle before every publish (Phase 4).
- Pending from v1.1: Phase 03 drift re-test (5 UAT scenarios, `.planning/milestones/v1.1-phases/03-sessions-preferences-quick-actions-cleanup.1/03-UAT.md`) — candidate target now build 15+ (post-wiring) — not a v1.2 requirement, but the last open v1.1 item.
- StoreKitServiceTests + EntitlementForegroundCorrectionTests remain disabled (StoreKitTest session-isolation/productNotFound bug, dated disposition 2026-09-04 in file headers, WINDOWS #6/#18) — needs a working local CoreSimulator/XCTestDevices layer to diagnose the StoreKitTest daemon interaction further

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

## Deferred Verification

| Phase | State | Resume |
|-------|-------|--------|
| 1 | ~~verification_deferred_human~~ **RESOLVED 2026-09-03** — /gsd-verify-work 1 passed 19/19 (both human items validated); phase marked complete | — |

## Session Continuity

Last session: 2026-09-04T06:22:59.490Z
Stopped at: Completed 02-05-PLAN.md (BUILD-04: AGENTS.md canonical CI-parity invocation + INFOPLIST_KEY doc-truth note; docs/TESTING.md replace-by-reference)
Resume file: None

## Operator Next Steps

- Resolve the uncommitted SPM-proxy migration in the working tree (Firebase proxy products + non-colliding GoogleSignIn naming) before Phase 1 archive work
- `/gsd-discuss-phase 1` — resolve D3 (privacy contract authority) and D4 (widget in v1) before planning Phase 1

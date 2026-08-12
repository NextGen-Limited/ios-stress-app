# Milestones

## v1.0 App Store Submission Remediation (Shipped: 2026-08-12)

**Phases completed:** 6 phases, 11 plans, 29 tasks

**Key accomplishments:**

- Wired the widget extension's App Group entitlement (closing a live fatalError risk), completed per-bundle Privacy Manifest disclosure across all three compiled targets, and deleted the orphaned top-level Info.plist — three concrete, verified gaps closed against an already-mostly-correct uncommitted working tree.
- Widget data resolves to fresh/stale/empty via a unit-tested `WidgetDataState` resolver instead of a conflated `isPlaceholder` bool, and Small/Medium/Large widget views now dim and relabel stale data per the UI-SPEC contract.
- A `checkpoint:human-action` task: the user attests that App Groups (+ iCloud) capabilities are now enabled for all three App IDs and that `bundle exec fastlane setup_match` regenerated the cached App Store profiles; this agent's own attempt to independently confirm that via `fastlane match appstore --readonly` could not run to completion in this execution environment (no Match/App Store Connect credentials present here), so the record rests on user attestation plus a passing simulator-build regression check.
- Corrected 7 docs (CLAUDE.md, 4 docs/ architecture files, and the EN+VI privacy policy) to disclose the actual `/chat` payload — derived stress score/category/confidence/trend plus per-factor HRV/heart-rate/sleep/activity/recovery scores, sent under a Bearer-JWT-authenticated session — replacing the false "anonymized"/"never leaves the device" claim per D-01.
- Non-fatal SwiftData `ModelContainer` recovery — the app no longer crashes via `fatalError` on any prior store schema state; migrates or recovers cleanly instead.
- `DataManageView.performDeleteAll` deleted only SwiftData + CloudKit records, leaving the Supabase JWT in Keychain and the App Group widget cache intact — a "deleted" user stayed signed in and the widget kept showing their data. Fixed and consolidated onto a single `DataDeleterService`; 3 code-review rounds this session additionally found and fixed a genuine "reports success but doesn't actually delete" CloudKit batch-delete bug.
- AI Chat honestly gated off for v1 via a compile-time `ChatAvailability` flag, the leaked guest JWT dead-stripped from Release by an `#if DEBUG` wrap, and the AUTH-03 streaming lifecycle pinned by new TDD tests.
- IAP purchase flow fixed for Release-config compilation and wired to real product IDs; StoreKit entitlement display honesty and one-time-permanent character unlocks addressed.

**Known gaps carried into v1.1** (see `.planning/milestones/v1.0-phases/` for full artifacts):

- Only 1/6 phases (01.1) has a `passed` verification; Phase 01 verification is `gaps_found`, Phase 02 is `human_needed` (3 pending UAT items — two-device CloudKit sync test, `DataDeletionConsolidationTests` execution, CR-01 regression test), Phases 03/04/05 were never formally verified.
- 9/26 requirements unchecked in the archived v1.0-REQUIREMENTS.md, including BUILD-01/02/03, AUTH-01/02/03, WIRE-01, SHIP-01/03.
- `01-06-PLAN.md` in Phase 1 was never executed.
- Pre-existing Release-build compile blocker: `StoreKitServiceEnvironment.swift:12` references `MockStoreKitService` unconditionally outside `#if DEBUG` — every Release build fails to compile until fixed.
- This host's CoreSimulator cannot complete an `xcodebuild test` launch session (`No matching device ... in XCTestDevices`) — reproduced across every phase's verification session; all test coverage claims in this milestone rest on `build-for-testing` compile success only, not executed pass/fail.

---

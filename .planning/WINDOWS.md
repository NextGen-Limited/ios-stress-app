---
schema_version: 1
open_count: 11
waived_count: 1
fixed_count: 6
total_count: 18
last_updated: 2026-09-04T07:12:09.996Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | unrun-verify | StressMonitor/StressMonitorTests |  | xcodebuild test -only-testing:StressMonitorTests baseline never completed in 3 attempts (CoreSimulator device-pairing/socket failures: Mach error -308, then 2x 'No matching device in XCTestDevices') - environment-level flake unrelated to Phase 1 code changes; build phases for the test target succeed every time, only runtime device install/communication fails | open |  | 2026-08-09T06:47:30.005Z |  |
| 2 | 01 | unrun-verify | fastlane/Matchfile |  | bundle exec fastlane match appstore --readonly could not be run to completion in the 01-03 executor's environment (MATCH_GIT_URL/APP_STORE_CONNECT_API_KEY_ID/APP_STORE_CONNECT_ISSUER_ID unset) — Developer Portal capability + Match profile regeneration confirmed only by user attestation, not independently verified | open |  | 2026-08-09T13:59:41.239Z |  |
| 3 | 02 | unrun-verify | .planning/phases/02-data-integrity-deletion-consolidation/02-01-PLAN.md |  | Task 4 two-device CloudKit sync verification deferred — needs real devices | open |  | 2026-08-11T05:34:27.039Z |  |
| 4 | 01 | stub | StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift | 57 | signInWithGoogle() throws not-yet-available; Google Sign-In deferred to Plan 02 (D-02) | open |  | 2026-08-13T09:37:49.691Z |  |
| 5 | 01 | unrun-verify | StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift |  | End-to-end /chat round-trip unverified: backend deployment down (404 on all endpoints) | open |  | 2026-08-13T09:37:49.786Z |  |
| 6 | 02 | skipped-test | StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift |  | Suite disabled: StoreKitTest purchase throws productNotFound (IAP-01 — no product IDs resolve); re-enable in 02-03 | waived | Dated disposition 2026-09-04 (02-04 Task 3): StoreKitTest session-isolation bug — productNotFound reproduces locally on current AND disposable fresh simulator (exit 65 both rounds, isolation-matrix evidence in 02-04-SUMMARY), ruling out CI-runner-specificity; ruled-out causes in file header EntitlementForegroundCorrectionTests.swift:6-27; residual risk: foreground entitlement-correction coverage CI-invisible; authoritative disposition lives in the file header | 2026-08-16T17:28:36.992Z | 2026-09-04T07:12:09.996Z |
| 7 | 02 | skipped-test | StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift |  | Suite disabled: custom INFOPLIST_KEY_STOREKIT_* settings never reach the generated Info.plist so live catalog resolves empty (IAP-01); re-enable in 02-03 | fixed |  | 2026-08-16T17:28:40.914Z | 2026-09-04T06:07:19.983Z |
| 8 | 02 | deviation | StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift |  | Full-suite xcodebuild exit 65 despite 84/84 tests passing: 6 cold-launch host restarts clustered on CloudKit Failure & Cancellation and Data Export Field Selection suites (pre-existing TEST-01 host flakiness) | fixed |  | 2026-08-16T17:28:41.937Z | 2026-09-04T06:07:14.237Z |
| 9 | 02 | deviation | stress-app-be/src/routes/credits.ts |  | Redeem + premium/verify endpoints and 2 migrations committed but NOT deployed; production apply deferred to 02-04 user_setup with user confirmation | fixed | resolved 2026-08-23: backend deployed + ASC consumables filed + live money-path smoke human-validated (02-VERIFICATION passed); resolution restored 2026-09-04 after accidental stale-mirror reopen | 2026-08-17T02:05:07.102Z | 2026-09-04T05:43:22.407Z |
| 10 | 02 | unmet-truth | stress-app-be/src/lib/iap.ts |  | Real-Apple success path of verifyAndDecodeTransaction untestable without an Apple-signed JWS fixture; covered only via route-seam fakes and rejection-path tests until live sandbox UAT in 02-04 | fixed | live sandbox refund UAT (CR-05 demotion + WR-10 one-pass clear) human-validated 2026-08-23; resolution restored 2026-09-04 after accidental stale-mirror reopen | 2026-08-17T02:05:07.194Z | 2026-09-04T05:44:33.032Z |
| 11 | 02 | unrun-verify | .planning/phases/02-credits-system-iap-transition/02-04-PLAN.md |  | 02-04 Task 3 live money-path smoke (provision->402->sandbox purchase->server grant->persisted balance) blocked on backend deploy + ASC consumable filing; see 02-04-SUMMARY Deferred Issues | fixed | unblocked by the deployed backend + filed ASC products; 02-VERIFICATION passed 29/29 2026-08-23; resolution restored 2026-09-04 after accidental stale-mirror reopen | 2026-08-17T04:32:14.498Z | 2026-09-04T05:44:33.254Z |
| 12 | 3 | deviation | StressMonitor/StressMonitorTests/StressAPIClientTests.swift | 80 | Order-dependent test pollution (found at 03-05 gate): ChatHistoryRestoreTests leaves static RequestCaptureURLProtocol.responseByPath['/preferences'] set; PreferencesServiceTests + StressAPIClientPreferencesTests stub via the single-response statics and receive the stale vi/direct 200 because responseByPath takes precedence (StressAPIClientTests.swift:80-81) — 10 assertion failures / exit 65 in a crash-free 10-suite targeted run; masked in full-suite runs by the #8 crash-restart boundary sitting between polluter (launch 1) and victims (later launch). Fix seam: per-test reset/clear of RequestCaptureURLProtocol statics (or teardown in ChatHistoryRestoreTests.makeStubbedClient). | open |  | 2026-08-23T11:21:42.696Z |  |
| 13 | 1 | deviation | scripts/verify-archive-tests.sh |  | Plan 01-01 Task 1 automated verify as written (append planted string past Mach-O EOF, then strings) is a no-op on macOS - cctools strings stops at the object's last section; harness plants via midpoint overwrite instead | open |  | 2026-09-03T07:48:47.465Z |  |
| 14 | 1 | deviation | StressMonitor/StressMonitor.xcodeproj/project.pbxproj |  | Plan 01-01 Task 2 kept Firebase product names un-renamed per plan letter, but Xcode PIF duplicate-registration required the A4 remedy (FirebaseAuth_proxied/FirebaseCore_proxied) - applied in fix commit 1afb401 | open |  | 2026-09-03T07:48:47.765Z |  |
| 15 | 1 | deviation | docs-site/legal/privacy.md |  | 01-02 Task 2: dropped self-contradictory 'not an anonymous one' clause alongside Supabase→Firebase Auth correction (resolved, verified, committed 4b9e4ae) | open |  | 2026-09-03T08:29:14.277Z |  |
| 16 | 2 | deviation | StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift |  | WR-04 reachability note delivered label-free in Swift (finding code kept out of code comments per user AGENTS.md); labeled audit lives in 02-02-SUMMARY | open |  | 2026-09-03T16:18:10.408Z |  |
| 17 | 02 | deviation | StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift |  | Quarantine (ENV-02, same host-crash family as WINDOWS #8) lifted and fixed 2026-09-04: container-lifetime bug in makeSeededContext (returned mainContext only, owning ModelContainer deallocated at fixture return) confirmed by .ips correlation and cleared by converting to (ModelContainer, ModelContext) tuple fixture; green on two simulator rounds (current + fresh), zero host restarts; see 02-04-SUMMARY.md | fixed |  | 2026-09-04T06:07:25.816Z | 2026-09-04T06:07:30.009Z |
| 18 | 02 | skipped-test | StressMonitor/StressMonitorTests/StoreKitServiceTests.swift |  | Suite disabled: hasIntroductoryOffer/purchase/restore/cancel/expiry all throw productNotFound (StoreKitTest session-isolation bug). 02-04 Task 3 isolation-matrix run (2026-09-04) reproduced identically on current iPhone 17 + a fresh iPhone 16 sim (exit 65, 9 issues both rounds) — not CI-runner-specific. Dated disposition meeting the bar recorded in the file header; needs a working local CoreSimulator/XCTestDevices layer to diagnose the daemon interaction further (WINDOWS #3). | open |  | 2026-09-04T06:07:36.770Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "StressMonitor/StressMonitorTests",
    "line": null,
    "description": "xcodebuild test -only-testing:StressMonitorTests baseline never completed in 3 attempts (CoreSimulator device-pairing/socket failures: Mach error -308, then 2x 'No matching device in XCTestDevices') - environment-level flake unrelated to Phase 1 code changes; build phases for the test target succeed every time, only runtime device install/communication fails",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T06:47:30.005Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "fastlane/Matchfile",
    "line": null,
    "description": "bundle exec fastlane match appstore --readonly could not be run to completion in the 01-03 executor's environment (MATCH_GIT_URL/APP_STORE_CONNECT_API_KEY_ID/APP_STORE_CONNECT_ISSUER_ID unset) — Developer Portal capability + Match profile regeneration confirmed only by user attestation, not independently verified",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T13:59:41.239Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-data-integrity-deletion-consolidation/02-01-PLAN.md",
    "line": null,
    "description": "Task 4 two-device CloudKit sync verification deferred — needs real devices",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-11T05:34:27.039Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "stub",
    "phase": "01",
    "file": "StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift",
    "line": 57,
    "description": "signInWithGoogle() throws not-yet-available; Google Sign-In deferred to Plan 02 (D-02)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T09:37:49.691Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift",
    "line": null,
    "description": "End-to-end /chat round-trip unverified: backend deployment down (404 on all endpoints)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T09:37:49.786Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "skipped-test",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift",
    "line": null,
    "description": "Suite disabled: StoreKitTest purchase throws productNotFound (IAP-01 — no product IDs resolve); re-enable in 02-03",
    "status": "waived",
    "reason": "Dated disposition 2026-09-04 (02-04 Task 3): StoreKitTest session-isolation bug — productNotFound reproduces locally on current AND disposable fresh simulator (exit 65 both rounds, isolation-matrix evidence in 02-04-SUMMARY), ruling out CI-runner-specificity; ruled-out causes in file header EntitlementForegroundCorrectionTests.swift:6-27; residual risk: foreground entitlement-correction coverage CI-invisible; authoritative disposition lives in the file header",
    "recorded_at": "2026-08-16T17:28:36.992Z",
    "resolved_at": "2026-09-04T07:12:09.996Z"
  },
  {
    "id": 7,
    "kind": "skipped-test",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift",
    "line": null,
    "description": "Suite disabled: custom INFOPLIST_KEY_STOREKIT_* settings never reach the generated Info.plist so live catalog resolves empty (IAP-01); re-enable in 02-03",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-16T17:28:40.914Z",
    "resolved_at": "2026-09-04T06:07:19.983Z"
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift",
    "line": null,
    "description": "Full-suite xcodebuild exit 65 despite 84/84 tests passing: 6 cold-launch host restarts clustered on CloudKit Failure & Cancellation and Data Export Field Selection suites (pre-existing TEST-01 host flakiness)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-16T17:28:41.937Z",
    "resolved_at": "2026-09-04T06:07:14.237Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "02",
    "file": "stress-app-be/src/routes/credits.ts",
    "line": null,
    "description": "Redeem + premium/verify endpoints and 2 migrations committed but NOT deployed; production apply deferred to 02-04 user_setup with user confirmation",
    "status": "fixed",
    "reason": "resolved 2026-08-23: backend deployed + ASC consumables filed + live money-path smoke human-validated (02-VERIFICATION passed); resolution restored 2026-09-04 after accidental stale-mirror reopen",
    "recorded_at": "2026-08-17T02:05:07.102Z",
    "resolved_at": "2026-09-04T05:43:22.407Z"
  },
  {
    "id": 10,
    "kind": "unmet-truth",
    "phase": "02",
    "file": "stress-app-be/src/lib/iap.ts",
    "line": null,
    "description": "Real-Apple success path of verifyAndDecodeTransaction untestable without an Apple-signed JWS fixture; covered only via route-seam fakes and rejection-path tests until live sandbox UAT in 02-04",
    "status": "fixed",
    "reason": "live sandbox refund UAT (CR-05 demotion + WR-10 one-pass clear) human-validated 2026-08-23; resolution restored 2026-09-04 after accidental stale-mirror reopen",
    "recorded_at": "2026-08-17T02:05:07.194Z",
    "resolved_at": "2026-09-04T05:44:33.032Z"
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-credits-system-iap-transition/02-04-PLAN.md",
    "line": null,
    "description": "02-04 Task 3 live money-path smoke (provision->402->sandbox purchase->server grant->persisted balance) blocked on backend deploy + ASC consumable filing; see 02-04-SUMMARY Deferred Issues",
    "status": "fixed",
    "reason": "unblocked by the deployed backend + filed ASC products; 02-VERIFICATION passed 29/29 2026-08-23; resolution restored 2026-09-04 after accidental stale-mirror reopen",
    "recorded_at": "2026-08-17T04:32:14.498Z",
    "resolved_at": "2026-09-04T05:44:33.254Z"
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "3",
    "file": "StressMonitor/StressMonitorTests/StressAPIClientTests.swift",
    "line": 80,
    "description": "Order-dependent test pollution (found at 03-05 gate): ChatHistoryRestoreTests leaves static RequestCaptureURLProtocol.responseByPath['/preferences'] set; PreferencesServiceTests + StressAPIClientPreferencesTests stub via the single-response statics and receive the stale vi/direct 200 because responseByPath takes precedence (StressAPIClientTests.swift:80-81) — 10 assertion failures / exit 65 in a crash-free 10-suite targeted run; masked in full-suite runs by the #8 crash-restart boundary sitting between polluter (launch 1) and victims (later launch). Fix seam: per-test reset/clear of RequestCaptureURLProtocol statics (or teardown in ChatHistoryRestoreTests.makeStubbedClient).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-23T11:21:42.696Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "1",
    "file": "scripts/verify-archive-tests.sh",
    "line": null,
    "description": "Plan 01-01 Task 1 automated verify as written (append planted string past Mach-O EOF, then strings) is a no-op on macOS - cctools strings stops at the object's last section; harness plants via midpoint overwrite instead",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-03T07:48:47.465Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "1",
    "file": "StressMonitor/StressMonitor.xcodeproj/project.pbxproj",
    "line": null,
    "description": "Plan 01-01 Task 2 kept Firebase product names un-renamed per plan letter, but Xcode PIF duplicate-registration required the A4 remedy (FirebaseAuth_proxied/FirebaseCore_proxied) - applied in fix commit 1afb401",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-03T07:48:47.765Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "1",
    "file": "docs-site/legal/privacy.md",
    "line": null,
    "description": "01-02 Task 2: dropped self-contradictory 'not an anonymous one' clause alongside Supabase→Firebase Auth correction (resolved, verified, committed 4b9e4ae)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-03T08:29:14.277Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "2",
    "file": "StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift",
    "line": null,
    "description": "WR-04 reachability note delivered label-free in Swift (finding code kept out of code comments per user AGENTS.md); labeled audit lives in 02-02-SUMMARY",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-03T16:18:10.408Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift",
    "line": null,
    "description": "Quarantine (ENV-02, same host-crash family as WINDOWS #8) lifted and fixed 2026-09-04: container-lifetime bug in makeSeededContext (returned mainContext only, owning ModelContainer deallocated at fixture return) confirmed by .ips correlation and cleared by converting to (ModelContainer, ModelContext) tuple fixture; green on two simulator rounds (current + fresh), zero host restarts; see 02-04-SUMMARY.md",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-04T06:07:25.816Z",
    "resolved_at": "2026-09-04T06:07:30.009Z"
  },
  {
    "id": 18,
    "kind": "skipped-test",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/StoreKitServiceTests.swift",
    "line": null,
    "description": "Suite disabled: hasIntroductoryOffer/purchase/restore/cancel/expiry all throw productNotFound (StoreKitTest session-isolation bug). 02-04 Task 3 isolation-matrix run (2026-09-04) reproduced identically on current iPhone 17 + a fresh iPhone 16 sim (exit 65, 9 issues both rounds) — not CI-runner-specific. Dated disposition meeting the bar recorded in the file header; needs a working local CoreSimulator/XCTestDevices layer to diagnose the daemon interaction further (WINDOWS #3).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-04T06:07:36.770Z",
    "resolved_at": null
  }
]
````

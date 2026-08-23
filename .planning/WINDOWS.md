---
schema_version: 1
open_count: 12
waived_count: 0
fixed_count: 0
total_count: 12
last_updated: 2026-08-23T11:21:42.696Z
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
| 6 | 02 | skipped-test | StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift |  | Suite disabled: StoreKitTest purchase throws productNotFound (IAP-01 — no product IDs resolve); re-enable in 02-03 | open |  | 2026-08-16T17:28:36.992Z |  |
| 7 | 02 | skipped-test | StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift |  | Suite disabled: custom INFOPLIST_KEY_STOREKIT_* settings never reach the generated Info.plist so live catalog resolves empty (IAP-01); re-enable in 02-03 | open |  | 2026-08-16T17:28:40.914Z |  |
| 8 | 02 | deviation | StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift |  | Full-suite xcodebuild exit 65 despite 84/84 tests passing: 6 cold-launch host restarts clustered on CloudKit Failure & Cancellation and Data Export Field Selection suites (pre-existing TEST-01 host flakiness) | open |  | 2026-08-16T17:28:41.937Z |  |
| 9 | 02 | deviation | stress-app-be/src/routes/credits.ts |  | Redeem + premium/verify endpoints and 2 migrations committed but NOT deployed; production apply deferred to 02-04 user_setup with user confirmation | closed | resolved 2026-08-23: backend deployed + ASC consumables filed + live money-path smoke human-validated (02-VERIFICATION passed) | 2026-08-17T02:05:07.102Z |  |
| 10 | 02 | unmet-truth | stress-app-be/src/lib/iap.ts |  | Real-Apple success path of verifyAndDecodeTransaction untestable without an Apple-signed JWS fixture; covered only via route-seam fakes and rejection-path tests until live sandbox UAT in 02-04 | closed | live sandbox refund UAT (CR-05 demotion + WR-10 one-pass clear) human-validated 2026-08-23 | 2026-08-17T02:05:07.194Z |  |
| 11 | 02 | unrun-verify | .planning/phases/02-credits-system-iap-transition/02-04-PLAN.md |  | 02-04 Task 3 live money-path smoke (provision->402->sandbox purchase->server grant->persisted balance) blocked on backend deploy + ASC consumable filing; see 02-04-SUMMARY Deferred Issues | closed | unblocked by the deployed backend + filed ASC products; 02-VERIFICATION passed 29/29 2026-08-23 | 2026-08-17T04:32:14.498Z |  |
| 12 | 3 | deviation | StressMonitor/StressMonitorTests/StressAPIClientTests.swift | 80 | Order-dependent test pollution (found at 03-05 gate): ChatHistoryRestoreTests leaves static RequestCaptureURLProtocol.responseByPath['/preferences'] set; PreferencesServiceTests + StressAPIClientPreferencesTests stub via the single-response statics and receive the stale vi/direct 200 because responseByPath takes precedence (StressAPIClientTests.swift:80-81) — 10 assertion failures / exit 65 in a crash-free 10-suite targeted run; masked in full-suite runs by the #8 crash-restart boundary sitting between polluter (launch 1) and victims (later launch). Fix seam: per-test reset/clear of RequestCaptureURLProtocol statics (or teardown in ChatHistoryRestoreTests.makeStubbedClient). | closed | fixed at producer+consumer seams in 03-review WR-04 (commits c2d6922, 4444e85); combined 11-suite single-process run 70/70 green — verified independently by 03-VERIFICATION | 2026-08-23T11:21:42.696Z |  |

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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T17:28:36.992Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "skipped-test",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift",
    "line": null,
    "description": "Suite disabled: custom INFOPLIST_KEY_STOREKIT_* settings never reach the generated Info.plist so live catalog resolves empty (IAP-01); re-enable in 02-03",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T17:28:40.914Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "02",
    "file": "StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift",
    "line": null,
    "description": "Full-suite xcodebuild exit 65 despite 84/84 tests passing: 6 cold-launch host restarts clustered on CloudKit Failure & Cancellation and Data Export Field Selection suites (pre-existing TEST-01 host flakiness)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-16T17:28:41.937Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "02",
    "file": "stress-app-be/src/routes/credits.ts",
    "line": null,
    "description": "Redeem + premium/verify endpoints and 2 migrations committed but NOT deployed; production apply deferred to 02-04 user_setup with user confirmation",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T02:05:07.102Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "unmet-truth",
    "phase": "02",
    "file": "stress-app-be/src/lib/iap.ts",
    "line": null,
    "description": "Real-Apple success path of verifyAndDecodeTransaction untestable without an Apple-signed JWS fixture; covered only via route-seam fakes and rejection-path tests until live sandbox UAT in 02-04",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T02:05:07.194Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-credits-system-iap-transition/02-04-PLAN.md",
    "line": null,
    "description": "02-04 Task 3 live money-path smoke (provision->402->sandbox purchase->server grant->persisted balance) blocked on backend deploy + ASC consumable filing; see 02-04-SUMMARY Deferred Issues",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T04:32:14.498Z",
    "resolved_at": null
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
  }
]
````

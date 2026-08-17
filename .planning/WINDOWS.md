---
schema_version: 1
open_count: 10
waived_count: 0
fixed_count: 0
total_count: 10
last_updated: 2026-08-17T02:05:07.194Z
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
| 9 | 02 | deviation | stress-app-be/src/routes/credits.ts |  | Redeem + premium/verify endpoints and 2 migrations committed but NOT deployed; production apply deferred to 02-04 user_setup with user confirmation | open |  | 2026-08-17T02:05:07.102Z |  |
| 10 | 02 | unmet-truth | stress-app-be/src/lib/iap.ts |  | Real-Apple success path of verifyAndDecodeTransaction untestable without an Apple-signed JWS fixture; covered only via route-seam fakes and rejection-path tests until live sandbox UAT in 02-04 | open |  | 2026-08-17T02:05:07.194Z |  |

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
  }
]
````

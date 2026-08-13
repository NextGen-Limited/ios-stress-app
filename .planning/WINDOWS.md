---
schema_version: 1
open_count: 5
waived_count: 0
fixed_count: 0
total_count: 5
last_updated: 2026-08-13T09:37:49.786Z
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
  }
]
````

# Phase 1 Deferred Items

Out-of-scope discoveries logged during execution (per executor scope boundary). Do not fix inside the discovering plan.

## [2026-09-03] Plan 01-03, Task 1 — `INFOPLIST_KEY_UIBackgroundModes` never merges into product plists

- **Found during:** merged-plist golden diff (build-13 archive vs fresh Debug build).
- **Evidence:** pbxproj sets `INFOPLIST_KEY_UIBackgroundModes = "fetch processing"` (app Debug+Release), but the key is absent from BOTH the shipped build-13 Release archive plist AND every fresh build's merged plist. Same closed-key-set mechanism as the STOREKIT keys (see 01-03-SUMMARY.md deviations): only documented INFOPLIST_KEY_* settings merge.
- **Impact:** background fetch/processing has been silently absent from every shipped binary. Not caused by 01-03 (identical before/after); no key was lost by this plan.
- **Candidate owner:** future BUILD-04/submission-hardening work — decide whether background modes are actually needed (chat/session code) and, if so, move the key into `StressMonitor/StressMonitor/Info.plist` file-side like the STOREKIT keys.

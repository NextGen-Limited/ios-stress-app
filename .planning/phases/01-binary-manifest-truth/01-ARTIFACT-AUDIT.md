# Phase 1 Artifact Audit — BUILD-02 (App Group suite) + AUTH-01 (credential scan)

**Produced by:** plan 01-04 (Binary & Manifest Truth, wave 3)
**Date:** 2026-09-03
**Scope of truth:** the phase-final archive `StressMonitor/build/Phase1-Final.xcarchive` (all Phase-1 changes from plans 01-01..01-03) plus the source tree and the signed build-13 golden archive at `.asc/artifacts/StressMonitor.xcarchive` (baseline, built from pre-Phase-1 HEAD `fed4b6b`).

---

## BUILD-02 — One App Group suite (`group.stress.ai.com`) across three targets

**Verdict: PASS.** All three per-target entitlements files declare exactly one application-group value — the identical canonical suite `group.stress.ai.com`. Every Swift suite constant quotes it verbatim. No rename was performed and none was needed (repo truth overrides the CONTEXT.md decision-text typo string `group.com.stressmonitor.app`; see Typo note below). Equality across three separate per-target files IS the pass condition — no merge into a shared file and no invented single source of truth.

### 1. Source entitlements (plutil, literal extracted values)

Method note: the plan's literal `plutil -extract com.apple.security.application-groups.0` key-path form is not accepted by this plutil build (numeric array indexing in a key path → "No value at that key path"). The equivalent `plutil -extract "com.apple.security.application-groups" json` extraction was used; it prints the whole array, proving both the value and the single-element shape (empty/missing edge covered by the same output).

| File | Extracted application-groups array | Additional capabilities |
|------|-----------------------------------|------------------------|
| `StressMonitor/StressMonitor/StressMonitor.entitlements` | `["group.stress.ai.com"]` | `healthkit=true`, `icloud-container-identifiers=[iCloud.stress.ai.com]`, `icloud-services=[CloudKit]` |
| `StressMonitor/StressMonitorWidget/StressMonitorWidget.entitlements` | `["group.stress.ai.com"]` | none — app group is the widget's **only** declared capability |
| `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements` | `["group.stress.ai.com"]` | `healthkit=true`, `icloud-container-identifiers=[iCloud.stress.ai.com]`, `icloud-services=[CloudKit]` |

No target has an empty or missing `com.apple.security.application-groups` array. The audit compares literal extracted values from single-element arrays — order-insensitive by construction, independent of plist key ordering.

Raw output (JSON extraction, one per file):

```
StressMonitor/StressMonitor/StressMonitor.entitlements
  application-groups = ["group.stress.ai.com"]
StressMonitor/StressMonitorWidget/StressMonitorWidget.entitlements
  application-groups = ["group.stress.ai.com"]
StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements
  application-groups = ["group.stress.ai.com"]
```

### 2. Swift suite constants (grep `UserDefaults(suiteName` + literal `"group.` strings)

Every `UserDefaults(suiteName:)` call site across the three real target directories resolves to the canonical suite. Six constant sites quote it verbatim:

| Site | Declaration |
|------|-------------|
| `StressMonitor/StressMonitor/Models/WidgetSharedData.swift:100` | `static let appGroupID = "group.stress.ai.com"` (enum `WidgetConstants`) |
| `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:10` | `static let appGroupID = "group.stress.ai.com"` |
| `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift:16` | `static let appGroupID = "group.stress.ai.com"` |
| `StressMonitor/StressMonitorWatch Watch App/Models/WatchFacePreferences.swift:15` | `static let suiteName = "group.stress.ai.com"` |
| `StressMonitor/StressMonitorWatch Watch App/Complications/Services/ComplicationDataProvider.swift:14` | `private let suiteName = "group.stress.ai.com"` |
| `StressMonitor/StressMonitor/ViewModels/CharacterCollectionViewModel.swift:116` | `private let suiteName = "group.stress.ai.com"` |

Call sites (all reference the constants above): `WidgetSharedData.swift:133` (`WidgetConstants.appGroupID`), `DataDeleterService.swift:560` (`WidgetConstants.appGroupID`), `WidgetDataProvider.swift:45` (`Self.appGroupID`), `ComplicationDataProvider.swift:25`, `WatchFacePreferences.swift:18`, `WatchSharedDataStore.swift:21`, `CharacterCollectionViewModel.swift:132`. Test-side pin: `StressMonitorTests/WidgetPublisherKeyMatchingTests.swift:10` — `private static let suiteName = "group.stress.ai.com"`.

Zero divergent literals: the only `"group.` strings in the real target directories are the seven canonical ones listed above (6 constants + 1 test). 

### 3. Typo note (CONTEXT.md decision-text suite string)

`grep -rn "group.com.stressmonitor" StressMonitor/` over all source file types → **0 matches in the source tree** (see Deviation 1: the research's "zero matches" claim missed `StressMonitorWidget/README.md`, a v1.0-era setup doc that carried the typo string at 3 sites and ships inside the .appex as a copied resource; the 3 README lines were corrected to `group.stress.ai.com` — a doc-only fix, docs move toward code, matching the plan-01-02 D3 precedent). No entitlements file, Swift constant, plist, pbxproj, manifest, or config file anywhere under `StressMonitor/` contains the reversed-segments string. Stale pre-existing build products under `StressMonitor/build/Debug-*` and `Phase1-Verify.xcarchive` still carry the old README copy — they are regenerated artifacts, not source; the phase-final archive (Task 2) is verified to carry the corrected copy. The CONTEXT.md decision-text string itself remains only in `.planning/` documentation where it is already labeled a typo.

### 4. Runtime proof (suite opens non-nil, keys round-trip)

- `WidgetPublisherKeyMatchingTests` — **2/2 passed, TEST SUCCEEDED** (`xcodebuild test … -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/WidgetPublisherKeyMatchingTests`): `publish` writes all six `latest_*` keys into the real suite and the values match the source measurement. `UserDefaults(suiteName:)` returned non-nil (the test force-unwraps it) — the `WidgetDataProvider` fatalError-on-nil-suite path is not triggered.
- Suite-writing parts of the DataDeletion suites — **4/4 passed, TEST SUCCEEDED** (`-only-testing:StressMonitorTests/DeleteAllCredentialClearanceTests -only-testing:StressMonitorTests/DataDeleterConsolidationTests`), including "clearCredentialsAndSharedCaches removes App Group widget cache" which writes `latest_stress_level` into the real suite then verifies deletion. These two suites are not GSD_CI-gated and ran locally for real (not skipped). The GSD_CI-gated suites in the same file (`DataDeleterFailureAndCancellationTests`, `DataExportFieldSelectionTests`) were not invoked — they are the WINDOWS.md #8 host-stall lineage, out of scope for this audit, gating untouched per plan.

### 5. Golden signed-artifact half (build-13 archive, codesign entitlements)

`bash scripts/verify-archive.sh .asc/artifacts/StressMonitor.xcarchive` → **exit 0, all 11 checks PASS**, including **ENTITLEMENTS PASS ×3** (the build-12 no-entitlements-blob regression guard). Raw per-bundle codesign dumps confirm the signed blobs carry the identical single-element array:

```
StressMonitor.app:                              application-groups = [group.stress.ai.com]
PlugIns/StressMonitorWidgetExtension.appex:     application-groups = [group.stress.ai.com]
Watch/StressMonitorWatch Watch App.app:         application-groups = [group.stress.ai.com]
```

The entitlements source files are unchanged by this phase, so golden signed dump + unchanged sources proves the chain end-to-end: source plists → signed blobs → runtime suite tests.

### 6. Standing observation — WidgetDataProvider fatalError on nil suite

`WidgetDataProvider.init` calls `fatalError` when `UserDefaults(suiteName:)` returns nil (`WidgetDataProvider.swift:44-47`): an entitlement mismatch at runtime crashes the widget process rather than degrading. The per-bundle entitlements dump (check 1 of `scripts/verify-archive.sh`) before any publish is the standing guard — the signed-artifact dump lands with the next locally-controlled signed build / the Phase 4 publish flow (STATE.md mandate: dump entitlements per bundle before every publish).

### 7. Dead keys — observed and left

`WidgetConstants` (`WidgetSharedData.swift:101-103`) declares `latestMeasurementKey = "latestMeasurement"`, `widgetHistoryKey = "widgetHistory"`, `lastUpdateKey = "lastUpdate"` — none are read or written by the live path (the live keys are the `latest_*` set written by `WidgetPublisher.publish`). Observed and left in place: cleanup is out of phase scope per the surgical-changes rule; `WidgetSharedData.swift` is unchanged by this phase.

---

## AUTH-01 — Credential scan over the phase-final archive

*(appended by plan 01-04 Task 2 — see below)*

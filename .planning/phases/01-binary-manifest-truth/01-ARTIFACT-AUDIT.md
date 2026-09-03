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

**Verdict: PASS — no usable credential is extractable from any of the three binaries or bundled resources of `StressMonitor/build/Phase1-Final.xcarchive`.**

### 1. The phase-final archive

Built fresh this session (includes every change from plans 01-02 and 01-03 — manifest reasons, plist consolidation, pbxproj cleanup, README typo fix):

```
xcodebuild archive -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -archivePath StressMonitor/build/Phase1-Final.xcarchive \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO        → ** ARCHIVE SUCCEEDED **
```

Binaries (universal simulator slices): app `StressMonitor` 12,115,776 B · widget `StressMonitorWidgetExtension` 535,792 B · watch `StressMonitorWatch Watch App` 1,727,040 B.

Gate result: `bash scripts/verify-archive.sh StressMonitor/build/Phase1-Final.xcarchive --skip-entitlements` → **exit 0** — credential scan ×3, AIza resource grep, merged plists, SDK manifests all PASS. The signing-disabled archive is a faithful proxy: credential strings are a property of the compiled Mach-O, not of the signature.

### 2. Manual triage pass (raw §7 strings pipeline, pre-allowlist — every hit dispositioned)

The script allowlists known-benign hits; this pass re-ran the raw pipeline by hand so every actual hit is on record. (Each app-binary constant appears twice — the universal binary carries one slice per architecture.)

| Binary | Hit (literal) | Disposition |
|--------|---------------|-------------|
| app ×2 | `eyJlcnJvciI6IlVOS05PV05fRVJST1IifQ==` | **Benign** — base64 `{"error":"UNKNOWN_ERROR"}`, Google App Check SDK error constant (adjacent strings: `com.google.app_check_core.token_storage`). Identical to the build-13 baseline hit. Not a credential. |
| app ×2 | `supabaseAccessToken` | **Benign** — legacy Keychain account-name literal REMOVED by `FirebaseAuthService.swift:133` deletion path. Key name, not a token. |
| app ×2 | `supabaseRefreshToken` | **Benign** — same Keychain-cleanup literal class. |
| app ×2 | `supabaseSessionExpiresAt` | **Benign** — same class. |
| app ×2 | `supabaseChatSessionId` | **Benign** — same class. |
| widget | — | zero hits across all patterns (`eyJ`, PRIVATE KEY, supabase, sk-, anon key, api secret, BEGIN RSA/EC, Bearer token) |
| watch | — | zero hits across all patterns |

Raw commands (re-runnable, read-only): `strings -a <mach-o> | grep -n "eyJ"` and `strings -a <mach-o> | grep -inE "PRIVATE KEY|supabase|sk-[A-Za-z0-9]|anon[_-]?key|api[_-]?secret|BEGIN RSA|BEGIN EC|Bearer [A-Za-z0-9._-]{20,}"`. Re-running yields the identical verdict (AUTH-01 concurrency edge: the scan is read-only against the completed artifact).

### 3. AIza containment

`strings -a <mach-o> | grep -c "AIza"` → app **0**, widget **0**, watch **0**. `grep -rl "AIza" <StressMonitor.app>` → **only** `GoogleService-Info.plist` (bundled resource). The Firebase `API_KEY`/client ID are public identifiers by Google's documented model (restrictable by bundle ID), committed to the repo by convention and shipped in build 13 — expected, not a finding.

### 4. Additional greps (new-archive checks the research flagged)

- `STRESS_API` env-style key forms over the three binaries: app = 2 × literal string `STRESS_API_BASE_URL`, widget = 0, watch = 0. The 2 app hits are the env-var/config **name** read by `StressAPIConfig.swift:10-11` for the optional non-secret base-URL override (Info.plist → env → UserDefaults → fallback `https://stress-api.dropitx.site`) — a configuration key name, not a value; no secret material. Disposition: benign.
- `sb_publishable` / `sb_secret` forms over the three binaries: **0 / 0 / 0**.

### 5. fastlane/report.xml spot-check

`fastlane/report.xml` (383 B, committed, uploaded as a CI artifact by deploy.yml) contains only two lane stubs (`default_platform`, `update_fastlane`) — grep for token-value patterns (`AIza…`, `eyJ…` 20+ chars, `sb_secret`, `sk-…`, `MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY` values) → nothing. **Clean.**

### 6. Baseline preservation

`.asc/artifacts/` (build-13 IPA + archive, the AUTH-01/BUILD-01 golden reference) untouched — mtimes still Sep 3 00:24 (pre-session); `verify-archive.sh` is read-only by design and no other command wrote there.


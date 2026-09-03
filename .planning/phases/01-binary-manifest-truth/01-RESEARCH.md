# Phase 1: Binary & Manifest Truth - Research

**Researched:** 2026-09-03
**Domain:** iOS build-system truth (privacy manifests, App Group entitlements, Info.plist consolidation, credential scanning, SPM local-proxy packaging, fastlane match signing)
**Confidence:** HIGH (repo-grounded with file:line citations; Apple reason codes verified against developer.apple.com)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D3 resolved: code is the contract.** `StressContextPayload`'s actual behavior (derived stress score/category/confidence/trend + per-factor scores under a Bearer-authenticated session; no raw HealthKit values) is the normative privacy statement. Root `CLAUDE.md` and the shipped privacy-policy wording are corrected to match — zero payload/code churn.
- Unused media dependencies (Giphy SDK, Kingfisher, exyte MediaPicker) are removed from the v1 build if grep shows no live references — closing privacy-manifest surface and App Review rejection risk.
- Required-reason API declarations (`NSPrivacyAccessedAPITypes`) are generated from a scan of APIs actually used (UserDefaults, file timestamps, etc.) and declared per target.
- Third-party SDK privacy manifests: verify each remaining SPM dependency ships its own; aggregate any gaps into the app target's manifest.
- **D4 resolved: keep the widget and make it true.** It ships in TestFlight build 13 and its entitlement was wired in v1.0; removing a shipped surface right after external beta is a user-visible regression. WIRE-01 verified on a real device.
- Canonical App Group suite stays `group.com.stressmonitor.app` — audit all 3 targets for drift, no rename.
- WIRE-01 verification: physical-device widget gallery first; simulator gallery + documented human UAT as fallback evidence.
- Stale-data presentation: keep the v1.0 `WidgetDataState` fresh/stale/empty resolver behavior as-is — no redesign this phase.
- Info.plist consolidation (BUILD-03): delete empty `Info.plist` files where the target supports generated plists; every key resolves from `INFOPLIST_KEY_*` build settings in the merged product plist.
- ENV-04: complete the user's in-flight SPM-cache proxy migration in place, preserving its direction (snapshot at `.asc/backup/spm-migration/`): add Firebase proxy products, give the GoogleSignIn proxy a non-colliding product name. Do NOT revert to HEAD package references.
- AUTH-01: run the `strings` check against the build-13 IPA in `.asc/artifacts/` as an immediate baseline, then re-run against the Phase-1-final archive as the gate.
- ENV-05: push `gsd/v1.2-submission-readiness` to origin after Phase 1 commits land to trigger the CI run that validates `fastlane match` readonly against the dual-cert profiles. Branch push only; `main` untouched.

### the agent's Discretion
Implementation details not covered above (scan tooling choice, exact plist key mapping, proxy package structure) are the executor's discretion within repo conventions.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUILD-01 | Privacy manifest passes ASC upload validation | Per-target `PrivacyInfo.xcprivacy` audit (§5.2), verified reason-code semantics (§5.3), one concrete gap found (watch missing CA92.1), SDK-manifest evidence from build-13 archive, Giphy script-phase residue (§5.4) |
| BUILD-02 | One canonical App Group suite ID across 3 targets | Entitlements + Swift source audit (§4) — suite is `group.stress.ai.com`; **CONTEXT.md's `group.com.stressmonitor.app` string is wrong** (Open Question 1) |
| BUILD-03 | Info.plist consolidated onto `INFOPLIST_KEY_*` | Per-target build-settings map + orphaned-plist inventory + archive merged-plist baseline (§6) |
| AUTH-01 | Empirical `strings` check finds no extractable credentials | Methodology validated against build-13 IPA this session — clean baseline with a documented false-positive triage list (§7) |
| WIRE-01 | Widget renders live stress data on a real device | Full write→read data flow with call site and pinned tests (§10) |
| ENV-04 | SPM-proxy migration completes; archive producible from working tree | Proxy package anatomy, exact missing pieces (Firebase shims absent), naming collision, HEAD-vs-tree diff (§8) |
| ENV-05 | CI `fastlane match` readonly accepts dual-cert profiles | Fastfile/Matchfile/workflow citation, dual-cert context, branch-push protocol, local keychain risk (§9) |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Xcode project is one level down: `StressMonitor/StressMonitor.xcodeproj` — run all xcodebuild/fastlane from repo root with `-project StressMonitor/StressMonitor.xcodeproj`.
- **Orphaned directories that never build** (edits there are no-ops): `StressMonitorTests/` (repo root), `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/` (repo root). Real targets: `StressMonitor/StressMonitor/`, `StressMonitor/StressMonitorTests/`, `StressMonitor/StressMonitorWatch Watch App/` (path contains spaces), `StressMonitor/StressMonitorWidget/`.
- Schemes: `StressMonitor`, `"StressMonitorWatch Watch App"` (shared), `StressMonitorWidgetExtension` (no shared scheme file; CI builds it by scheme name).
- Watch target **duplicates algorithm sources** — not relevant to this phase (no algorithm edits), but plist/manifest edits must be mirrored only where the file is actually in a target.
- SwiftLint opt-in `force_ununwrap` / `implicitly_unwrapped_optional` — avoid `!` in new code.
- CI parity builds use `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` with `generic/platform=iOS Simulator`.
- No git commits unless asked; commit author `Phuong Doan`, no AI attribution.
- Simulator interaction: prefer `argent` MCP over raw `xcrun simctl`.
- `.planning/config.json`: `tdd_mode: true`, `security_enforcement: true` (ASVS L1), `nyquist_validation: true`, test command pins `-parallel-testing-enabled NO` and destination `iPhone 17` (available locally, see §13).

## Summary

Phase 1 is almost entirely a **build-system archaeology and reconciliation** phase, not a feature phase. The good news embedded in the repo evidence: the shipped build-13 artifact (`.asc/artifacts/StressMonitor.xcarchive`, built from HEAD `fed4b6b`, BETA_APPROVED on TestFlight) already **passes** ASC upload privacy-manifest validation and **passes** the credential `strings` baseline — so every success criterion except ENV-04 has a proven-good reference point to converge back to. The work is: (1) fix the concrete gaps the audit found (watch manifest missing the `CA92.1` UserDefaults reason; Giphy dSYM stub script phase referencing a dependency that no longer exists; STOREKIT_* keys duplicated in both the orphaned plist file and `INFOPLIST_KEY_*` build settings), (2) finish the SPM proxy migration so the working tree archives (Firebase shims don't exist yet; GoogleSignIn proxy product name collides with upstream), (3) correct the D3 doc overshoots (root `CLAUDE.md` says "Supabase Edge Function" while code ships `StressAPIClient` → `https://stress-api.dropitx.site`; privacy policies say "Supabase Auth" while code uses Firebase Auth), and (4) evidence WIRE-01 on device/simulator.

One discrepancy must be resolved before any BUILD-02 task is planned: **CONTEXT.md names the App Group suite `group.com.stressmonitor.app`, but the repo truth — all three entitlements files, every Swift constant, and both pinning tests — is `group.stress.ai.com`.** The locked decision intent ("audit all 3 targets for drift, no rename") is satisfiable as-is against the real suite; the string in the decision text is simply wrong. See Open Question 1.

**Primary recommendation:** Treat `group.stress.ai.com` as the canonical suite (repo truth overrides the CONTEXT.md typo), sequence ENV-04 (proxy completion) before any archive-producing task, keep BUILD-03 surgical (delete duplicates, don't fight `CFBundleURLTypes` — it has no `INFOPLIST_KEY_*` equivalent), and use build-13's archive as the golden reference for every plist/manifest diff.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Privacy manifest content per bundle | Build config (Xcode target resources) | — | `PrivacyInfo.xcprivacy` is compiled into each bundle by target membership; SDK manifests ship inside SDK resource bundles automatically |
| App Group suite truth | Native entitlements (codesign) | Swift constants (runtime) | The suite ID must match across 3 `.entitlements` files (compile/sign time) and 6+ Swift string constants (runtime); no single source of truth exists today |
| Info.plist key resolution | Build settings (`INFOPLIST_KEY_*`) | Orphaned plist files | Xcode merges `GENERATE_INFOPLIST_FILE` output with `INFOPLIST_FILE` content; today both contribute |
| Credential leakage | Release binary + bundled resources | — | `strings` over Mach-O (app/widget/watch) plus bundle-resource grep; GoogleService-Info.plist values are identifiers, not secrets |
| SPM dependency resolution | Local proxy package (`spm-cache/packages/proxy`) | Umbrella cache-warmer package | pbxproj points at one local package; the proxy re-exports upstream products via `@_exported import` shims |
| Code signing / profiles | fastlane match (git storage) | CI workflow secrets | CI is the ENV-05 authority; local keychain is currently missing a team-K2TYLYAWMK distribution identity |
| Widget data flow | App target (write) → Widget extension (read) | Shared App Group UserDefaults | `WidgetPublisher.publish` in app writes; `WidgetDataProvider` in extension reads; keys duplicated by convention, pinned by test |

## Standard Stack

This phase installs **no new packages**. It repoints two already-pinned SPM dependencies through local proxy shims and uses built-in tooling.

### Core (existing, no install)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Xcode / xcodebuild | 26.3 (17C529) | Archive + `xcodebuild -showBuildSettings` for merged-plist truth | CI parity (`_test.yml`/`deploy.yml` pin `XCODE_VERSION: "26.3"`); locally installed and matching [VERIFIED: local `xcodebuild -version` output] |
| SwiftPM (local proxy pattern) | swift-tools-version 6.0 | ENV-04 proxy completion | Already the migration's chosen direction — proxy `Package.swift` uses `// swift-tools-version: 6.0` [VERIFIED: StressMonitor/spm-cache/packages/proxy/Package.swift:1] |
| fastlane (gym/match/pilot) | bundler 4.0.13 locally; `Gemfile.lock` in repo | ENV-05 match readonly + Release archive lanes | Repo's only build pipeline; `upload_beta`/`build_only` both call `match(readonly: true)` [VERIFIED: fastlane/Fastfile] |
| `strings` / `plutil` / `grep` | macOS built-ins | AUTH-01 scan + BUILD-03 plist inspection | No dependencies; validated this session against build-13 IPA |
| swiftlint | 0.63.3 (homebrew) | Lint gate | Advisory in CI but repo convention says don't regress [VERIFIED: local `swiftlint --version`] |

### SPM dependencies in play (already pinned, both pre-existing)
| Package | Pinned state | Role |
|---------|-------------|------|
| `firebase-ios-sdk` | version `11.15.0`, revision `fdc352fabaf5916e7faa1f96ad02b1957e93e5a5` (at HEAD; working tree pin currently absent because the proxy dropped it) [VERIFIED: `git show HEAD:...Package.resolved`] | `FirebaseAuth`, `FirebaseCore` products consumed by `Services/Auth/FirebaseAuthService.swift` |
| `GoogleSignIn-iOS` | revision `08d8dcecafb575f98879ffdbb8302c1b9ad65d19` (working tree + umbrella pin; version `9.2.0` at HEAD) [VERIFIED: Package.resolved + umbrella Package.swift] | `GoogleSignIn` product consumed by app |

## Package Legitimacy Audit

**No new external packages are installed by this phase.** The two SPM packages above are pre-existing repo dependencies (present in `Package.resolved` history and shipped inside the build-13 archive as `Firebase_*.bundle` / `GoogleSignIn_GoogleSignIn.bundle`), repackaged locally via shims rather than re-fetched from an unverified source. No `[SLOP]`/`[SUS]` candidates exist.

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

## Architecture Patterns

### System Architecture Diagram (what Phase 1 touches)

```
                       ┌──────────────────────────────────────────────┐
                       │ ENV-04: SPM resolution (must complete first) │
                       └──────────────────────────────────────────────┘
 pbxproj ──XCLocalSwiftPackageReference──▶ spm-cache/packages/proxy (local pkg)
                                            │ deps (path)
                                            ├─▶ .proxies/GoogleSignIn-iOS_proxy   (EXISTS — product name collides w/ upstream)
                                            └─▶ .proxies/<Firebase proxy>          (MISSING — must be created)
                                            each shim: @_exported import <UpstreamModule>
 spm-cache/packages/umbrella ──remote pins──▶ google/* clones (cache warmer; no firebase pin yet)

                       ┌──────────────────────────────────────────────┐
                       │ Archive (Release, signed via match profiles) │
                       └──────────────────────────────────────────────┘
 xcodebuild archive ─▶ StressMonitor.app
                        ├─ Info.plist           ◀── merged: GENERATE_INFOPLIST_FILE + INFOPLIST_KEY_* + INFOPLIST_FILE  (BUILD-03)
                        ├─ PrivacyInfo.xcprivacy (app scan: CA92.1+1C8F.1, C617.1)                               (BUILD-01)
                        ├─ entitlements: group.stress.ai.com + healthkit + icloud                                (BUILD-02)
                        ├─ PlugIns/StressMonitorWidgetExtension.appex (own plist/manifest/entitlements; reads suite) (WIRE-01 read side)
                        ├─ Watch/…app              (own plist/manifest/entitlements; reads suite)                 (BUILD-02)
                        └─ GoogleService-Info.plist (identifiers, non-secret — expected in bundle)                (AUTH-01 scope)

 app runtime: StressRepository.save ─▶ WidgetPublisher.publish(measurement) ─▶ UserDefaults(suite:"group.stress.ai.com")
             ─▶ WidgetCenter.reloadAllTimelines() ─▶ widget getTimeline reads same suite ─▶ WidgetDataState resolve   (WIRE-01)

 CI: push gsd/v1.2-submission-readiness ─▶ ci.yml (_test.yml) ─▶ deploy.yml ─▶ fastlane upload_beta ─▶ match(readonly) (ENV-05)
```

### Repo Truth Map — the seven research areas

#### §4 BUILD-02 — App Group suite: the canonical value is `group.stress.ai.com`

All three entitlements files declare exactly one suite [VERIFIED — files opened this session]:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.stress.ai.com</string>
</array>
```
Sources: `StressMonitor/StressMonitor/StressMonitor.entitlements`, `StressMonitor/StressMonitorWidget/StressMonitorWidget.entitlements`, `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements` (identical block in each). The app+watch entitlements additionally declare `com.apple.developer.healthkit` (true), `com.apple.developer.icloud-container-identifiers` = `iCloud.stress.ai.com`, `com.apple.developer.icloud-services` = `CloudKit`. The widget entitlements declare the App Group **only**.

Swift-side constants (all quote `group.stress.ai.com` verbatim):
- `StressMonitor/StressMonitor/Models/WidgetSharedData.swift:100` — `static let appGroupID = "group.stress.ai.com"` (enum `WidgetConstants`)
- `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:10` — `static let appGroupID = "group.stress.ai.com"`
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift:16` — `static let appGroupID = "group.stress.ai.com"`
- `StressMonitor/StressMonitorWatch Watch App/Models/WatchFacePreferences.swift:15` — `static let suiteName = "group.stress.ai.com"`
- `StressMonitor/StressMonitorWatch Watch App/Complications/Services/ComplicationDataProvider.swift:14` — `private let suiteName = "group.stress.ai.com"`
- `StressMonitor/StressMonitor/ViewModels/CharacterCollectionViewModel.swift:116` — `private let suiteName = "group.stress.ai.com"`
- Tests: `StressMonitor/StressMonitorTests/WidgetPublisherKeyMatchingTests.swift:10` and `DataDeletionConsolidationTests.swift` (via `WidgetConstants.appGroupID`)

A repo-wide grep for `group.com.stressmonitor` returns **zero** matches. **No drift exists and no placeholder suite exists** — the audit this decision asks for will confirm one suite, six-plus call sites, zero renames needed. The only wrong string is in the CONTEXT.md decision text itself (Open Question 1).

Residual BUILD-02 risk surface (not drift, but worth a verification task): `WidgetDataProvider.init` `fatalError`s if `UserDefaults(suiteName:)` returns nil (`StressMonitorWidget/Models/WidgetDataProvider.swift:44-47`) — an entitlement mismatch at runtime crashes the widget process rather than degrading. The per-bundle entitlements dump after archiving (STATE.md: "dump entitlements per bundle before every publish") is the guard.

#### §5 BUILD-01 — Privacy manifests

**§5.1 What exists** [VERIFIED — all three files opened]: one `PrivacyInfo.xcprivacy` per compiled target, already wired in v1.0:
- `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy`
- `StressMonitor/StressMonitorWidget/PrivacyInfo.xcprivacy`
- `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy`

**§5.2 Current declarations (verbatim)**

App target:
```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedType</key>… <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key> <array><string>CA92.1</string><string>1C8F.1</string></array>
    </dict>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>… <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
        <key>NSPrivacyAccessedAPITypeReasons</key> <array><string>C617.1</string></array>
    </dict>
</array>
```
(plus `NSPrivacyTracking=false`, empty tracking domains, and collected-data entries: HealthAndFitness/linked, PhotoVideo, ProductInteraction, DeviceID, OtherUserContent/linked — all purpose AppFunctionality, none tracking)

Widget and watch targets both declare only:
```xml
<string>NSPrivacyAccessedAPICategoryUserDefaults</string> … <array><string>1C8F.1</string></array>
```

**§5.3 Reason-code semantics (verified against Apple's official doc page for `NSPrivacyAccessedAPITypeReasons`)** [CITED: developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons]:
- `CA92.1` — "access user defaults to read and write information that is only accessible to the app itself"
- `1C8F.1` — "read and write information that is only accessible to the apps, app extensions, and App Clips that are members of the same App Group"
- `C617.1` — "Inspect file metadata inside the app's container, app group container, or CloudKit container" (FileTimestamp category)
- The five required-reason categories are: FileTimestamp, SystemBootTime, DiskSpace, UserDefaults, ActiveKeyboard [CITED: Apple required-reason API documentation]

**Scan results vs declarations (the "generate from scan" task, done as research):**
| Target | UserDefaults.standard files | UserDefaults(suiteName:) files | FileTimestamp / boot / disk usage | Declared | Gap |
|--------|---------------------------|-------------------------------|-----------------------------------|----------|-----|
| app | 15 | 3 | `.contentModificationDateKey` in `Views/Settings/DataManagement/DataExportView.swift:393,398` | CA92.1+1C8F.1, C617.1 | none — correct |
| widget | 0 | 1 | none | 1C8F.1 | none — correct |
| watch | **4** | 3 | none | **1C8F.1 only** | **missing `CA92.1`** |

Watch files using `UserDefaults.standard` [VERIFIED: grep, files listed]: `ViewModels/WatchMoodViewModel.swift:68,82`, `ViewModels/WatchHabitViewModel.swift:55,76`, `Models/TierNamePreferences.swift:51`, `Services/CloudKit/WatchCloudKitManager.swift:38`. → The watch manifest needs `<string>CA92.1</string>` added to the UserDefaults reasons array. This is the one concrete BUILD-01 code change. (`SystemBootTime`, `DiskSpace`, `ActiveKeyboard` categories: no usage found — correctly undeclared.)

**§5.4 Third-party SDK manifests** [VERIFIED — archive inspected]: the build-13 archive ships resource-bundle manifests for every SPM dependency: `Firebase_FirebaseCore.bundle/PrivacyInfo.xcprivacy`, `Firebase_FirebaseAuth.bundle/…`, `Firebase_FirebaseCoreInternal.bundle/…`, `GoogleSignIn_GoogleSignIn.bundle/…`, `AppAuth_*.bundle/…`, `GoogleUtilities_*.bundle/…`, `GTMAppAuth_*.bundle/…`, `GTMSessionFetcher_*.bundle/…`, `Promises_FBLPromises.bundle/…` (all under `.asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app/`). Because build 13 uploaded to ASC and cleared processing + beta review, **the SDK-manifest half of BUILD-01 is already empirically green for the HEAD dependency set** — the phase's job is to not regress it (the proxy migration must keep those bundles flowing) and re-verify after media-dep removal.

**§5.5 Unused-media evaluation (decision: remove if no live references)** [VERIFIED — greps this session]:
- Swift references to `Giphy|giphy`: **0** across app/widget/watch/tests real targets. `Kingfisher`: **0**. `MediaPicker|exyte`: **0**.
- pbxproj package references for Giphy/Kingfisher/exyte: **0** (no `XCRemoteSwiftPackageReference` matches).
- **Surviving residue:** one shell-script build phase on the **app target** — `F2A1B0012AAA000100DE6E8F /* Generate Giphy dSYM Stub */` (pbxproj lines ~406, 526-545), listed in `StressMonitor` target's `buildPhases` — it no-ops when `GiphyUISDK.framework` is absent ("Warning: GiphyUISDK.framework not found, skipping") but is dead build machinery referencing a removed dependency. Removal is safe and closes the "no dead widget/media code ships" intent.
- Also check at execution time (cheap): `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` and xcassets for orphaned Giphy/Kingfisher-adjacent resources were not in scope of grep — asset catalogs don't reference frameworks; no action expected.

**§5.6 D3 doc overshoots (exact list)** [VERIFIED — files read]:
1. Root `CLAUDE.md:494` — "…to the `/chat` Supabase Edge Function under a Bearer-JWT-authenticated session". Reality: `StressAPIClient.swift:116` posts to path `"chat"` on `https://stress-api.dropitx.site` (`StressAPIConfig.swift`). CLAUDE.md also references `SupabaseLLMService` (architecture sections) — that type no longer exists in the app target (grep: 0 hits; the LLM service is `StressLLMService` which delegates auth to `StressAPIClient`/`FirebaseAuthService` per `StressMonitor/Services/LLM/StressLLMService.swift:10,34`).
2. `docs-site/legal/privacy.md:30` (EN) — "(a Bearer JWT, established via Supabase Auth — anonymous or signed-in)". Reality: auth is Firebase (`Auth.auth().signInAnonymously()` at `StressMonitorApp.swift:190`, `FirebaseAuthService.swift:2-3` importing FirebaseAuth/FirebaseCore; GoogleSignIn for the signed-in path).
3. `docs-site/vi/legal/privacy.md:30` (VI) — same "Supabase Auth" claim, mirrored.
4. Note (not an overshoot, but a consistency check for the executor): root `CLAUDE.md:493` "No third-party analytics or tracking" — defensible (Firebase is auth-only; manifest declares no tracking), but the app manifest's `DeviceID`/`ProductInteraction` entries exist because of the Google/Firebase SDKs; keep CLAUDE.md wording aligned with the manifest when editing.

**The D3 normative payload is already correct in code** [VERIFIED: `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:126-131`]:
```swift
// Raw HealthKit-derived readings never leave the device — only the
// app's own derived stress score/category above do. See
// StressContextPayloadTests for the invariant this enforces.
hrv: nil,
heartRate: nil,
baselineHRV: nil,
baselineHR: nil,
sleepQuality: nil,  // Not directly available from StressResult
sleepHours: nil,
activeMinutes: nil,
recoveryScore: nil,
```
…with `stressLevel`, `stressCategory`, `confidence`, `stressTrend(+Delta)`, and `factorBreakdown` (per-factor `score`+`weight` only) populated. `StressContextPayloadTests.swift` pins three invariants: `testBuildDoesNotIncludeRawHealthReadings`, `testBuildStillIncludesDerivedStressScore`, `testEncodedPayloadOmitsRawHealthKeysEntirely`. **Zero payload/code churn is the right call — the docs move to the code, not vice versa.**

#### §6 BUILD-03 — Info.plist consolidation

**Per-target state** [VERIFIED: pbxproj + source tree + archive]:

| Target | GENERATE_INFOPLIST_FILE | INFOPLIST_FILE | Notes |
|--------|------------------------|----------------|-------|
| StressMonitor (app) | YES (Debug+Release) | `StressMonitor/Info.plist` (Debug+Release) | ~20 `INFOPLIST_KEY_*` per config (pbxproj lines 883-903 / 940-960) |
| StressMonitorWidgetExtension | YES (target-level + both configs) | `StressMonitorWidget/Info.plist` (lines 687-690 / 723-726) | Only `CFBundleDisplayName` + copyright keys |
| StressMonitorWatch Watch App | YES (Debug+Release) | **none** | Already fully generated (lines 998-1010 / 1036+) — model target for BUILD-03 |
| StressMonitorTests | YES | none | Generate-only |

**The two source-tree plist files and their content** [VERIFIED — plutil dump]:
- `StressMonitor/StressMonitor/Info.plist`: `CFBundleURLTypes` (GoogleSignIn reversed-URL scheme `com.googleusercontent.apps.595426793312-…`, matching `REVERSED_CLIENT_ID` in GoogleService-Info.plist) **plus all six `STOREKIT_*` keys duplicated from `INFOPLIST_KEY_STOREKIT_*` build settings** (identical values today: `com.stressmonitor.app.credits.large`, `.credits.small`, `.premium.annual`, `.premium.monthly`, `.premium.weekly`, group id `22353146` as string).
- `StressMonitor/StressMonitorWidget/Info.plist`: single key `NSExtension.NSExtensionPointIdentifier = com.apple.widgetkit-extension`.

**Merged-product baseline (empirical, build-13 archive)**: app Info.plist carries both URL types and STOREKIT keys; widget Info.plist carries the NSExtension key; watch Info.plist fully generated. Values agree everywhere — today's duplication is **drift risk, not value conflict**.

**The one structural constraint the planner must know:** `CFBundleURLTypes` has **no** `INFOPLIST_KEY_*` build-setting equivalent in Xcode — Apple's generated-plists feature covers usage strings, orientations, display name, etc., not URL schemes. So the end-state for the app target is necessarily: plist file reduced to `CFBundleURLTypes` only (or injected by script), STOREKIT keys resolved solely from build settings. "Every key resolves from INFOPLIST_KEY_*" should be scoped as: *every key that has an INFOPLIST_KEY_ equivalent lives only in build settings; the plist file keeps only keys that cannot be expressed as build settings (URL types), documented.* Deleting the app's plist file outright would break GoogleSignIn's callback.
For the widget: whether the build system auto-injects `NSExtension.NSExtensionPointIdentifier` for widgetkit extensions when no plist exists is empirically testable in one build — template-created single-target widget projects ship without an Info.plist and produce that key in the product. Verify by building after deletion (Validation Architecture §14, SC-3 check).

**Key mapping for the delete-duplicates task** (verbatim current values, so nothing gets retyped from memory):
- `INFOPLIST_KEY_STOREKIT_CREDITS_LARGE_PRODUCT_ID = "com.stressmonitor.app.credits.large"`
- `INFOPLIST_KEY_STOREKIT_CREDITS_SMALL_PRODUCT_ID = "com.stressmonitor.app.credits.small"`
- `INFOPLIST_KEY_STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID = "com.stressmonitor.app.premium.annual"`
- `INFOPLIST_KEY_STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID = "com.stressmonitor.app.premium.monthly"`
- `INFOPLIST_KEY_STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID = "com.stressmonitor.app.premium.weekly"`
- `INFOPLIST_KEY_STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID = 22353146`
[VERIFIED: StressMonitor/StressMonitor.xcodeproj/project.pbxproj:892-897 (Debug) and 949-954 (Release) — identical in both]

Also note `StressAPIClient` runtime config reads these keys via the `SupabaseConfig`-precedent pattern: Info.plist → `ProcessInfo.processInfo.environment` → UserDefaults (`StressMonitor/Services/API/StressAPIConfig.swift:11`, `Services/StoreKit/StoreKitProductCatalog.swift:73`) — the merged plist must keep resolving all six or StoreKit product resolution silently falls back.

#### §7 AUTH-01 — credential scan: methodology validated, build-13 baseline CLEAN

Ran this session against `.asc/artifacts/StressMonitor.ipa` (unzipped to temp):
```bash
TMP=$(mktemp -d …); cd "$TMP" && unzip -qo <repo>/.asc/artifacts/StressMonitor.ipa -d ipa
BIN=ipa/Payload/StressMonitor.app/StressMonitor          # repeat for PlugIns/…appex and Watch/…app binaries
strings -a "$BIN" | grep -n "eyJ"                        # JWT-shaped (base64 '{"…') — 1 hit, triaged below
strings -a "$BIN" | grep -inE "PRIVATE KEY|supabase|sk-[A-Za-z0-9]|anon[_-]?key|api[_-]?secret|BEGIN RSA|BEGIN EC|Bearer [A-Za-z0-9._-]{20,}"
strings -a "$BIN" | grep -c "AIza"                       # Firebase API-key prefix in the Mach-O
grep -rl "AIza" ipa/Payload/StressMonitor.app            # where it actually lives
```

**Baseline results (build 13):**
- App binary (5,990,752 bytes): exactly **1** `eyJ` hit = `eyJlcnJvciI6IlVOS05PV05fRVJST1IifQ==` which base64-decodes to `{"error":"UNKNOWN_ERROR"}` — a constant inside the Google App Check SDK (adjacent strings: `com.google.app_check_core.token_storage`, `GACAppCheckToken`). **Not a credential.**
- `supabaseAccessToken` / `supabaseRefreshToken` / `supabaseSessionExpiresAt` / `supabaseChatSessionId` — legacy **Keychain account-name literals** used by the deletion path (`StressMonitor/Services/Auth/FirebaseAuthService.swift:133`: `for account in ["supabaseAccessToken", "supabaseRefreshToken"] {` — it *removes* old Supabase-era tokens). Key names, not tokens. Expected strings, not findings.
- `AIza` in binary: **0**. The Firebase `API_KEY` (`AIzaSyA4ivjfMd_32LW3ntmdiQJfRjXigAAUvKA`, from `StressMonitor/StressMonitor/GoogleService-Info.plist`) appears **only in the bundled plist resource** — by design: Google documents Firebase iOS API keys / OAuth client IDs as identifiers, restrictable by bundle ID, not secrets [ASSUMED — Google's "API key security" guidance from training knowledge; consistent with the key being committed to the repo by convention].
- Widget binary: 0 `eyJ`, no secret patterns. Watch binary: 0 `eyJ`, no secret patterns.
- Expected-and-fine strings: `https://stress-api.dropitx.site`, bundle IDs, URL schemes.

**Verdict: build 13 passes AUTH-01.** The gate for Phase 1 = re-run the same pipeline against the new archive; triage list above prevents false alarms. Worth grepping the new archive additionally for `STRESS_API` env-style keys and any `sb_publishable`/`sb_secret` forms.

#### §8 ENV-04 — SPM-cache proxy migration: exact state and exact missing pieces

**Current graph (working tree, uncommitted; snapshot at `.asc/backup/spm-migration/` is byte-identical to the live pbxproj/Package.resolved — verified by diff this session):**
- pbxproj: the two HEAD remote refs (`firebase-ios-sdk` ≥11.0.0, `GoogleSignIn-iOS` ≥9.0.0) were replaced by **one** local reference:
  ```
  C3ECFE78514FF7DFB2DBDB1E /* XCLocalSwiftPackageReference "proxy" */ = {
      isa = XCLocalSwiftPackageReference;
      relativePath = "spm-cache/packages/proxy";
  ```
  with three product dependencies: `GoogleSignIn`, `FirebaseAuth`, `FirebaseCore` (pbxproj lines 1131, 1136, 1141 — all `package = C3ECFE78514FF7DFB2DBDB1E`).
- Proxy package (`StressMonitor/spm-cache/packages/proxy/Package.swift`), verbatim:
  ```swift
  // swift-tools-version: 6.0
  let package = Package(
      name: "spm_cache_proxy",
      products: [ .library(name: "spm_cache_proxy", targets: ["spm_cache_root"]) ],
      dependencies: [ .package(path: ".proxies/GoogleSignIn-iOS_proxy") ],
      targets: [ .target(name: "spm_cache_root", dependencies: [
              .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS_proxy"),
              .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS_proxy")
          ], path: "src/root") ]
  )
  ```
- The GoogleSignIn shim (`StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift`) declares products **named `GoogleSignIn` / `GoogleSignInSwift`** while depending on upstream `GoogleSignIn-iOS` (revision `08d8dcecaf…`) whose own products are also named `GoogleSignIn`/`GoogleSignInSwift`. Shim source is one line: `@_exported import GoogleSignIn` (auto-generated by the spm-cache-proxy tool).
- Umbrella cache-warmer (`spm-cache/packages/umbrella/Package.swift`) pins google-family repos by revision; **it has no firebase-ios-sdk pin**, and `clones/repositories/` contains no firebase clone.
- Working-tree `Package.resolved` pins: app-check 11.3.1, appauth-ios 2.1.0, googlesignin-ios `08d8dcec`, googleutilities 8.1.3, gtm-session-fetcher 3.5.0, gtmappauth 5.0.0, interop-ios-for-google-sdks 101.0.0, promises 2.4.1 — **no firebase-ios-sdk pin** (HEAD had firebase-ios-sdk `11.15.0` / `fdc352fabaf5916e7faa1f96ad02b1957e93e5a5`).

**Why it can't archive (HANDOFF.json blocker, verbatim):** "proxy package lacks FirebaseAuth/FirebaseCore products entirely and declares a GoogleSignIn product that collides with upstream GoogleSignIn-iOS in the PIF graph."

**What completion concretely means (executor recipe, within the locked direction):**
1. Create `StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/` (name at executor discretion) mirroring the GoogleSignIn shim pattern: `Package.swift` with `name: "Firebase_proxy"` (or similar), dependency `.package(url: "https://github.com/firebase/firebase-ios-sdk.git", revision: "fdc352fabaf5916e7faa1f96ad02b1957e93e5a5")` (the HEAD-resolved revision — keeps the shipped version identical), products `FirebaseAuth` + `FirebaseCore` backed by shim targets with `@_exported import FirebaseAuth` / `@_exported import FirebaseCore`.
2. Rename the GoogleSignIn proxy's products to non-colliding names (e.g. library `GoogleSignIn_proxied`) so the proxy package no longer re-declares a product name that also exists upstream in the same graph; update the proxy root target's `.product(name:…)` references and the pbxproj `XCSwiftPackageProductDependency` `productName = GoogleSignIn;` (line 1131) to match. FirebaseAuth/FirebaseCore product names do **not** collide this way only if the shim package is the *sole* provider of those product names in the graph — since the upstream firebase package is referenced only via the shim, the names stay unique. (The GoogleSignIn case is different: upstream GoogleSignIn-iOS entered the graph through the shim itself, creating two same-named products one hop apart.)
3. Add `.package(path: ".proxies/Firebase_proxy")` + the two products to `spm_cache_root`'s dependencies.
4. Optionally add the firebase revision pin to the umbrella package so the clone cache warms it (clones currently lack firebase).
5. Resolution check: `cd StressMonitor/spm-cache/packages/proxy && swift package resolve` (or an xcodebuild `-resolvePackageDependencies`) then confirm `Package.resolved` regains `firebase-ios-sdk` at 11.15.0/`fdc352faba…`.
6. Gate: `xcodebuild archive` from the unmodified working tree succeeds (see §14 SC-6).

**Risk note:** firebase-ios-sdk is not in the local clone cache; the resolve step will hit the network (github) unless the umbrella is warmed first. Plan for one fetch.

#### §9 ENV-05 — fastlane match readonly vs dual-cert profiles

[VERIFIED: fastlane/Fastfile, fastlane/Matchfile, .github/workflows/*]
- Lanes that gate: `upload_beta` (deploy.yml: `run: bundle exec fastlane upload_beta`) and `build_only` both call `match(type: "appstore", readonly: true, api_key: api_key)`. Expected profile names (from `update_code_signing_settings` + export_options): `match AppStore stress.ai.com`, `match AppStore stress.ai.com.watchkitapp`, `match AppStore stress.ai.com.widget` — matching the pbxproj Release `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*/watchos*]` values (pbxproj lines 737, 970, 1055).
- Matchfile: `git_url(ENV["MATCH_GIT_URL"])`, `storage_mode("git")`, `type("appstore")`, `team_id("K2TYLYAWMK")`, the three bundle IDs.
- Dual-cert story (HANDOFF.json): portal profiles were **recreated** embedding both certs (WTV47CUC2N + XPT2DHR688); "Recreated portal profiles embed XPT2DHR688 which is not in the match git repo" → next CI match-readonly run may reject; documented fallback = run `bundle exec fastlane setup_match` once (regenerates single-cert profiles; then re-swap dual-cert locally per the stored recipe). `match.yml` workflow offers a manual `regenerate` job for exactly this.
- CI triggers: `ci.yml` → `_test.yml` on PRs to main/develop; `deploy.yml` runs after CI success on `main`/`release/*` **or** `workflow_dispatch`. ⚠️ Practical note for ENV-05: pushing `gsd/v1.2-submission-readiness` alone fires **neither** ci.yml (PR-only) nor deploy.yml (main/release/workflow_dispatch) — the ENV-05 check most likely needs a PR from the milestone branch to `main` (ci path) or a manual `workflow_dispatch` of a match/deploy workflow on that branch. See Open Question 3 — the planner should confirm which CI surface the user intends, since "branch push only; main untouched" conflicts with the workflows' trigger matrix.
- Local keychain (observed this session): distribution identities present are for teams `EQ8B89SPCX` (ePost) and `4L72Q793UP` (VAN LY PHUC) — **no K2TYLYAWMK distribution identity in the login keychain**. Match readonly will attempt to install the cert from the match repo; if the match repo lacks XPT2DHR688, local + CI both fall to the documented fallback. Treat CI as the authority (that's what ENV-05 says); local archive attempts during this phase should either use match first or expect a manual profile install.

#### §10 WIRE-01 — widget data flow and verification evidence

**Write side (app target):** `StressRepository.save` → `WidgetPublisher.publish(measurement)` (single call site: `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift:57`, after `modelContext.save()`). Publish writes six keys to `UserDefaults(suiteName: "group.stress.ai.com")` (`latest_stress_level`, `latest_stress_category`, `latest_hrv`, `latest_heart_rate`, `latest_confidence`, `latest_timestamp`) then `WidgetCenter.shared.reloadAllTimelines()` [VERIFIED: StressMonitor/StressMonitor/Models/WidgetSharedData.swift:104-141].

**Read side (widget target):** `StressWidgetProvider.getTimeline` → `WidgetDataProvider.shared.getLatestStress()` (+ `getHistory`, `getBaseline`) → `WidgetDataState.resolve(latestTimestamp:now:)` → `Timeline(entries:[entry], policy: .after(now+15min))` [VERIFIED: StressMonitorWidget/Providers/StressWidgetProvider.swift:46-71]. `WidgetDataState` (fresh ≤24h / stale >24h / empty) is behavior-frozen per CONTEXT; `WidgetDataStateTests.swift` exists.

**Contract pinning across targets:** keys are private enums duplicated by convention in both targets; `WidgetPublisherKeyMatchingTests.swift` regression-proofs the literal key strings + values (writes go to the real suite, then clean up). Known non-blocking drift: `WidgetConstants` (WidgetSharedData.swift:98-103) declares `latestMeasurementKey = "latestMeasurement"`, `widgetHistoryKey`, `lastUpdateKey` — **none of which are read or written by the live path** (dead constants; the live keys are the `latest_*` set). Do not "clean up" beyond noting — out of phase scope per surgical-changes rule, but flag to the planner as an optional one-line comment fix if touched.

**Verification evidence (per D4):** real-device widget gallery is the primary; simulator gallery + documented human UAT the fallback. Concretely evidenceable as: (a) app and widget show the same score after a refresh — capture widget screenshot + in-app dashboard screenshot at same timestamp (argent `screenshot` on simulator, or device screenshots via human UAT); (b) the six suite keys non-nil in the shared container after a save (already machine-checked by WidgetPublisherKeyMatchingTests); (c) build-13 shipped the widget (archive `PlugIns/StressMonitorWidgetExtension.appex` exists) so "widget in the build" is the status quo D4 preserves.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Privacy-manifest validation | Local plist-schema validators guessing ASC rules | The real gate: archive → upload to ASC (or `xcrun altool`/Transporter) and read ITMS errors (`ITMS-91053` = missing required-reason declaration) | Apple validates at upload; build 13 already proves the current set passes — diff-based verification is enough [CITED: Apple docs + ITMS-91053 references] |
| Merged-plist inspection | Parsing pbxproj by hand to predict merges | `xcodebuild -archive … ; plutil -p <product>/Info.plist` on the built product (or `-showBuildSettings` for settings truth) | The archive is ground truth; merge precedence edge cases (file vs INFOPLIST_KEY_*) vanish empirically |
| Entitlements verification | Trusting pbxproj strings | `codesign -d --entitlements :- <bundle>` per bundle on the archive | Build 12 shipped with **no entitlements blob** — this exact check is the guard STATE.md mandates |
| SPM cache proxying | Writing a new proxy tool | Extend the existing auto-generated shim pattern (`@_exported import`, one Package.swift per proxied package) | The pattern exists and works for GoogleSignIn; the tool's output shape is already in-repo |
| Credential scanning | Buying/adding a scanner dependency | `strings -a` + targeted regexes + the triage list in §7 | Zero new deps; the threat model is "secret in shipped artifact," fully covered by strings + resource grep |

**Key insight:** every Phase-1 check has a cheap, built-in, empirical form. The plan should be built almost entirely of "build/archive, then inspect the artifact" tasks, not static-analysis tooling.

## Runtime State Inventory

> This phase includes a migration (SPM proxy) and plist consolidation — inventory included.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | App Group suite `group.stress.ai.com` UserDefaults on devices (widget keys `latest_*`, baseline keys `baseline_hrv`/`baseline_hr`, character-selection keys; watch mood/habit keys in watch's own standard defaults) | **None — suite is NOT renamed** (locked decision). Keys `latest_*` stay byte-identical; changing `WidgetConstants` dead keys would be the only risk — leave them |
| Live service config | ASC portal: 3 recreated dual-cert App Store profiles (WTV47CUC2N+XPT2DHR688) not mirrored in match git repo; ASC privacy questionnaire (Phase 4, not now) | Code edit only this phase: none. ENV-05 observes CI; fallback = one `setup_match` run (user-aware) |
| OS-registered state | Local keychain: no K2TYLYAWMK distribution identity (has EQ8B89SPCX + 4L72Q793UP) | If local signing needed mid-phase: `match appstore readonly` installs from match repo, or manual profile+cert install; CI unaffected |
| Secrets/env vars | `APP_STORE_CONNECT_API_KEY_*`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION` (CI secrets); `STRESS_API_BASE_URL` (optional env override, non-secret) | None renamed. AUTH-01 must confirm none of these **values** leaked into the archive (they don't today) |
| Build artifacts | `StressMonitor/spm-cache/**` (clone cache, proxy `.build`), `StressMonitor/build/` (run-tests output), `.asc/artifacts/` (build-13 IPA+archive — **preserve as baseline**), `.asc/backup/spm-migration/` (snapshot) | Regenerate after proxy changes (`swift package resolve`); do NOT delete `.asc/artifacts` — it is the AUTH-01/BUILD-01 golden reference |

## Common Pitfalls

### Pitfall 1: Fixing the CONTEXT.md suite name in code instead of the doc
**What goes wrong:** An executor "audits for drift" against `group.com.stressmonitor.app`, finds every file "wrong," and renames the suite.
**Why:** CONTEXT.md's locked-decision text contains the wrong string (discuss-phase slip).
**How to avoid:** The repo is internally consistent (`group.stress.ai.com` in all 3 entitlements + all Swift constants + tests). Confirm with the user (Open Question 1), then audit for *duplication/typo drift* against the real value only.
**Warning signs:** Any task whose diff touches an entitlements file's suite string.

### Pitfall 2: Deleting the app's Info.plist file entirely (BUILD-03 overreach)
**What goes wrong:** GoogleSignIn sign-in breaks — the `CFBundleURLTypes` callback scheme disappears.
**Why:** `CFBundleURLTypes` has no `INFOPLIST_KEY_*` equivalent; the plist file is its only home.
**How to avoid:** Reduce the plist to URL types only; move nothing else back in. Verify the merged product plist still contains the scheme.
**Warning signs:** A task that deletes `StressMonitor/StressMonitor/Info.plist` without leaving CFBundleURLTypes somewhere.

### Pitfall 3: Removing the widget plist and assuming NSExtension survives
**What goes wrong:** Widget extension fails to load (extension point identifier missing from merged plist).
**Why/avoid:** Whether the build system injects `NSExtension.NSExtensionPointIdentifier` for widget extensions without a plist is empirically checkable in one simulator build — do that before deleting, and diff the built plist.
**Warning signs:** Widget missing from springboard after plist deletion.

### Pitfall 4: Proxy rename without pbxproj sync
**What goes wrong:** After renaming the GoogleSignIn proxy product, Xcode can't resolve `productName = GoogleSignIn` from the proxy package → resolution failure that looks like "the migration is still broken."
**How to avoid:** Rename in three places atomically: shim `Package.swift` products, proxy root target `.product(name:)`, pbxproj `XCSwiftPackageProductDependency.productName` (line ~1131). Resolve-check after.

### Pitfall 5: Auth strings false positives derailing AUTH-01
**What goes wrong:** The executor "finds" `eyJ…`, `supabaseAccessToken`, `AIza…` and declares a leak.
**Why:** §7 triage — `eyJlcnJvciI6…` is a Google SDK error constant; supabase names are Keychain-cleanup literals; AIza lives only in GoogleService-Info.plist by design.
**How to avoid:** Ship the triage list into the task; the criterion is "no usable credential," and each known hit has a documented benign explanation.

### Pitfall 6: CI trigger mismatch for ENV-05
**What goes wrong:** Branch pushed, no CI runs, ENV-05 declared "validated."
**Why:** deploy.yml triggers on main/release/workflow_dispatch; ci.yml on PRs to main/develop. A bare branch push triggers nothing.
**How to avoid:** Open a PR (even draft) from `gsd/v1.2-submission-readiness` to `main`, or dispatch a workflow manually — confirm user preference (Open Question 3).

### Pitfall 7: Editing orphaned directories
**What goes wrong:** Changes compile nowhere. `StressMonitorTests/` and repo-root `StressMonitor/{Models,Services,Views}/` are not in any target (AGENTS.md).
**How to avoid:** All edits under `StressMonitor/StressMonitor/`, `StressMonitor/StressMonitorWidget/`, `StressMonitor/StressMonitorWatch Watch App/`, `StressMonitor/StressMonitorTests/`, `fastlane/`, `.github/workflows/`, pbxproj.

### Pitfall 8: Forgetting watch mirrors for manifest edits
**What goes wrong:** The watch CA92.1 fix or any future shared-file change misses the duplicated watch copy.
**Why:** Watch target duplicates some sources (algorithm today; manifests are per-target files so this phase's watch manifest edit is its own file — but stay alert if any shared Swift constant is touched).

## Code Examples

### Archive + artifact inspection trio (the phase's core verification loop)
```bash
# From repo root (CI parity: signing off for smoke builds)
xcodebuild build -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Per-bundle entitlements of a built/archived product (BUILD-02 + build-12 regression guard)
codesign -d --entitlements :- ".asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app"
codesign -d --entitlements :- ".asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app/PlugIns/StressMonitorWidgetExtension.appex"
codesign -d --entitlements :- ".asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app/Watch/StressMonitorWatch Watch App.app"

# Merged plist truth (BUILD-03)
plutil -p ".asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app/Info.plist"
```

### Firebase proxy shim (extends the existing auto-generated pattern)
```swift
// File: spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseAuth_shim/shim.swift
// Pattern source: existing .proxies/GoogleSignIn-iOS_proxy/Sources/…/GoogleSignIn-iOS_GoogleSignIn_shim.swift
// Auto-generated by spm-cache-proxy: re-exports the source package module(s).
@_exported import FirebaseAuth
```
```swift
// In .proxies/Firebase_proxy/Package.swift — mirror the GoogleSignIn proxy shape:
//   products: [.library(name: "FirebaseAuth", targets: ["Firebase_FirebaseAuth_shim"]), …FirebaseCore…]
//   dependencies: [.package(url: "https://github.com/firebase/firebase-ios-sdk.git",
//                          revision: "fdc352fabaf5916e7faa1f96ad02b1957e93e5a5")]
// In proxy/Package.swift: add .package(path: ".proxies/Firebase_proxy") + the two products to spm_cache_root.
// Non-colliding rename: .library(name: "GoogleSignIn_proxied", …) + pbxproj productName update.
```

### Watch manifest fix (BUILD-01, one-line addition)
```xml
<key>NSPrivacyAccessedAPITypeReasons</key>
<array>
    <string>CA92.1</string>   <!-- add: watch reads/writes UserDefaults.standard in 4 files -->
    <string>1C8F.1</string>
</array>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Privacy manifests optional | Required-reason APIs + SDK manifests enforced at ASC upload since May 1, 2024 (`ITMS-91053` rejections) | 2024 | Already absorbed — build 13 clears it; this phase defends, not introduces |
| Remote SPM refs in pbxproj | Local proxy/shim packages for cacheable, network-free resolution | This repo's in-flight migration (user-driven) | ENV-04 completes it; direction locked, no revert |
| Fastfile per-lane ad-hoc signing | `match` git-storage readonly on CI | Repo standard since v1.0 | ENV-05 validates the dual-cert wrinkle |
| `INFOPLIST_FILE`-based plists | `GENERATE_INFOPLIST_FILE` + `INFOPLIST_KEY_*` | Xcode 13+ | Watch target already there; app/widget partially |

**Deprecated/outdated:** root `CLAUDE.md`'s Supabase-era architecture prose (SupabaseLLMService, "Supabase Edge Function") — D3's doc-fix list; `WidgetConstants` dead key names; Giphy dSYM stub script phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Firebase `API_KEY`/`CLIENT_ID` in GoogleService-Info.plist are public identifiers, not secrets (Google's documented model) | §7 AUTH-01 | Medium — if the user considers these secret, AUTH-01's "no usable credential" bar changes; but they are committed to the repo by convention and shipped in build 13, so the practical bar is unchanged |
| A2 | Xcode auto-injects `NSExtension.NSExtensionPointIdentifier` for widget extensions without an INFOPLIST_FILE | §6 BUILD-03 | Low — empirically testable in one build; if false, widget keeps a 1-key plist (acceptable end-state) |
| A3 | Firebase proxy shims pinned to HEAD's resolved revision (`fdc352faba…`/11.15.0) are what "Firebase proxy products exist" should pin | §8 ENV-04 | Low — any 11.x pin works; HEAD's keeps the shipped binary equivalent |
| A4 | Proxy product-name collision is the GoogleSignIn case only (upstream enters graph via the shim, two same-named products one hop apart); Firebase product names exposed solely by the shim package won't collide | §8 ENV-04 | Medium — if SwiftPM still complains, also rename Firebase shim products; same recipe applies |
| A5 | `docs-site/.vitepress/dist/*` build outputs regenerate from `docs-site/**.md` — D3 edits target the `.md` sources only | §5.6 | None — dist is generated |

## Open Questions

1. **App Group suite string in CONTEXT.md vs repo (BLOCKER for BUILD-02 task wording)**
   - What we know: repo is 100% consistent on `group.stress.ai.com` (3 entitlements, 6+ Swift constants, 2 tests). CONTEXT.md decision text says `group.com.stressmonitor.app`. Zero occurrences of that string in-repo.
   - What's unclear: whether the discuss-session string was a typo (most likely) or the user believes a different suite exists.
   - Recommendation: planner writes BUILD-02 as "audit all targets against `group.stress.ai.com` (repo truth); CONTEXT.md's `group.com.stressmonitor.app` is a typo to note in the phase wrap-up." Ask the user only if they object. Do NOT plan any rename.
2. **ASC upload as BUILD-01 gate — which upload?**
   - What we know: SC-1 requires "a Release archive uploads to ASC and clears privacy-manifest validation." Full `upload_beta` increments the build number and pushes a TestFlight build; `release` lane is metadata-only; `build_only` doesn't upload.
   - Recommendation: validate via the ENV-05 CI run if it reaches gym+pilot, or a deliberate `upload_beta` the user opts into at phase end; treat build 13 as the standing prior that the manifest set passes. Confirm with user before creating TestFlight builds from Phase-1 code (it's user-visible to external testers).
3. **ENV-05 CI surface** (see Pitfall 6): PR vs manual dispatch vs temporarily widening a workflow trigger. User said "branch push only; main untouched" — a PR is not a merge, but check the user accepts opening one.
4. **Widget gallery verification device availability**: is a physical device connected/available for WIRE-01, or is the simulator+human-UAT fallback the plan of record from the start?

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | everything | ✓ | 26.3 (17C529) — matches CI | — |
| iPhone 17 simulator | test_command / plist-merge checks | ✓ | listed, booted-on-demand | iPhone 16 also present |
| iPhone 16 simulator | CI-parity test destination | ✓ | listed | — |
| bundler/fastlane | ENV-05, archive lanes | ✓ | bundler 4.0.13 | — |
| swiftlint | lint gate | ✓ | 0.63.3 | advisory (`|| true` in CI) |
| python3 | scripts/run-tests.py | ✓ | 3.14.3 | — |
| K2TYLYAWMK distribution identity (local keychain) | local signed Release archive | ✗ (only EQ8B89SPCX + 4L72Q793UP present) | — | match readonly installs from match repo; or CI performs the signed archive; or manual cert install |
| firebase-ios-sdk in SPM clone cache | proxy resolution without network | ✗ (not in `clones/repositories/`) | — | one network fetch during `swift package resolve` (github) |
| Physical iOS device | WIRE-01 primary verification | ? (not probeable from CLI) | — | simulator gallery + documented human UAT (CONTEXT-sanctioned fallback) |
| ASC API access (secrets) | any upload/match lane | ✓ on CI; locally via ~/.appstoreconnect/AuthKey.p8 if present | — | CI is the authoritative ENV-05 surface |

**Missing dependencies with no fallback:** none that block planning. The two gaps (local K2TYLYAWMK identity, firebase clone) both have sanctioned fallbacks documented above.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Test`/`#expect`) inside XCTest target `StressMonitorTests` |
| Config file | none — scheme-driven (`StressMonitor` scheme; `.planning/config.json` `test_command`) |
| Quick run command | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/<Class>` (or `python3 scripts/run-tests.py` for auto-simulator) |
| Full suite command | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUILD-01 (manifest truth) | Widget publisher keys + payload invariants stay green through manifest/proxy churn | unit (existing) | `… -only-testing:StressMonitorTests/StressContextPayloadTests` ; `…/WidgetPublisherKeyMatchingTests` | ✅ both exist |
| BUILD-01 (validation gate) | Archive clears ASC privacy-manifest validation | artifact/manual | `xcodebuild archive …` then upload (pilot/Transporter) — ITMS-91053 absence | ❌ external system (build 13 = standing prior) |
| BUILD-02 | 3 bundles' entitlements show one suite; suite opens | artifact check | `codesign -d --entitlements :- <bundle>` ×3 + existing suite-writing tests (`WidgetPublisherKeyMatchingTests` proves `UserDefaults(suiteName:)` non-nil) | ✅ (combo) |
| BUILD-03 | Merged plist resolves all keys; no orphaned duplicates | artifact check | `plutil -p <archive>/…Info.plist` diff vs golden (build-13 plist) | ❌ Wave 0: script the diff (`scripts/` or inline task command) |
| AUTH-01 | No credential in Release binary | artifact check | §7 pipeline re-run on new archive (strings ×3 binaries + resource grep) | ❌ Wave 0: capture as documented command in task (no test-file needed — artifact gate) |
| WIRE-01 | Widget shows app's score after refresh | manual/human UAT (device or simulator) | simulator: install, run, `WidgetPublisher` fires on save; gallery screenshot; human UAT doc | ❌ human-UAT doc (phase `human_verify_mode: end-of-phase`) |
| ENV-04 | Archive from unmodified tree | artifact check | `xcodebuild archive -project … -scheme StressMonitor -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` (smoke) + signed archive at phase end | ❌ Wave 0 gate task |
| ENV-05 | CI match readonly green | CI observation | push branch → PR/dispatch → watch `deploy.yml`/`match` job logs | ❌ external system |

### Sampling Rate
- **Per task commit:** narrowest relevant: `-only-testing:StressMonitorTests/StressContextPayloadTests` (or touched-behavior class) + `swiftlint lint` on edited files.
- **Per wave merge:** full suite command above (`-parallel-testing-enabled NO` mandatory).
- **Phase gate:** full suite green + archive artifact checks (SC-1..6 below) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `scripts/verify-archive.sh` (or inline task commands) — entitlements dump ×3, plist diff vs build-13 golden, strings pipeline; covers BUILD-02/03 + AUTH-01 artifact halves
- [ ] Human-UAT note file for WIRE-01 (device or simulator fallback evidence template)
- [ ] No new fixtures needed — `StressContextPayloadTests`, `WidgetDataStateTests`, `WidgetPublisherKeyMatchingTests`, `DataDeletionConsolidationTests` already pin the frozen behavior

### Success-criteria → command map (for VALIDATION.md)
| SC | Criterion | Verification |
|----|-----------|--------------|
| 1 | ASC accepts manifest | Upload new archive (user-approved surface); no ITMS-91053/SDK-manifest error; build 13 as prior |
| 2 | One App Group suite | `codesign -d --entitlements :-` ×3 → identical `group.stress.ai.com`; `grep -rn "UserDefaults(suiteName" StressMonitor/{app,widget,watch}` → all constants equal; suite tests green |
| 3 | Plist single-source | `plutil -p` merged plists — all six STOREKIT keys + usage strings present; source tree has ≤1 non-generated plist (app, URL-types only); widget plist deleted-or-verified; diff vs build-13 golden shows no lost keys |
| 4 | No credential | §7 strings pipeline on new archive; triage list empty beyond documented benigns |
| 5 | Widget true (D4) | Device: widget score == app score post-refresh (screenshots); fallback: simulator gallery + documented UAT; widget present in archive `PlugIns/` |
| 6 | Archive from clean tree + CI match ok | `git status` clean (post-commit) → `xcodebuild archive` succeeds; Package.resolved contains firebase-ios-sdk 11.15.0 pin; CI match-readonly run green (or documented fallback executed with user awareness) |

## Security Domain

`security_enforcement: true`, ASVS level 1, block-on high. This phase touches config/build artifacts, not request handling.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | indirectly | No auth-code changes (D3 is docs-only). Firebase Auth + Bearer JWT to stress-api unchanged; AUTH-01 confirms no credential in binary |
| V3 Session Management | no | No session changes |
| V4 Access Control | no | — |
| V5 Input Validation | no | No new input paths; plist values are compile-time constants |
| V6 Cryptography | no | No crypto changes; keys live in Keychain/secure enclave paths untouched |
| V14 Config (build-relevant) | yes | Hardened by this phase: single plist source (no orphaned-file key injection), manifest truth, no secrets in artifact |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation (this phase) |
|---------|--------|----------------------------------|
| Secret leakage into shipped binary | Information Disclosure | AUTH-01 strings gate (§7) — the phase's core security deliverable |
| Entitlement confusion (extension w/o matching suite) | Elevation/DoS | BUILD-02 per-bundle `codesign -d --entitlements` verification (build-12 regression class) |
| Supply-chain via dependency resolution | Tampering | ENV-04 pins revisions (`fdc352faba…`, `08d8dcec…`) in proxy/umbrella — verify pins survive completion; no floating requirements |
| Privacy-manifest misdeclaration | Repudiation/Compliance | BUILD-01 scan-then-declare (§5.3 table) closes the watch CA92.1 gap; over-declaration is permitted by Apple, under-declaration is not |
| CI secrets exposure | Information Disclosure | Workflows already use GitHub secrets; this phase adds none; fastlane report.xml exists in-repo (`fastlane/report.xml`) — confirm it contains no token material when archiving (spot-check task) |

## Sources

### Primary (HIGH confidence)
- Repo files (all opened this session): the 3 `.entitlements`; 3 `PrivacyInfo.xcprivacy`; `project.pbxproj` (+ HEAD version via `git show`); `Package.resolved` (+HEAD); `spm-cache/packages/{proxy,umbrella}/Package.swift` + shim sources; `fastlane/{Fastfile,Matchfile,Appfile}`; `.github/workflows/{ci,deploy,_test,match}.yml`; `StressContextPayload.swift` + its tests; `WidgetSharedData.swift`; `WidgetDataProvider.swift`; `StressWidgetProvider.swift`; `StressRepository.swift`; `FirebaseAuthService.swift`; `StressAPIClient.swift`/`StressAPIConfig.swift`; `GoogleService-Info.plist`; `CLAUDE.md`; `docs-site/{legal,vi/legal}/privacy.md`; `.planning/HANDOFF.json`; build-13 archive (`Info.plist`s, entitlements-relevant bundles, SDK manifests, binaries — strings executed)
- Apple developer documentation (via search-result citations of the official pages): `NSPrivacyAccessedAPITypeReasons` reason-code semantics (CA92.1/1C8F.1/C617.1/3D61.1/85F4.1); required-reason API categories; ITMS-91053 behavior [CITED: developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons]

### Secondary (MEDIUM confidence)
- Community corroboration of reason-code tables and manifest-merge behavior (Singular SDK FAQ, PTKD journal table, RN discussion #776) — consistent with Apple docs but not authoritative alone

### Tertiary (LOW confidence)
- A1 (Firebase API key non-secrecy) — training knowledge of Google's documented model; consistent with in-repo convention (key committed, shipped in build 13)

## Metadata

**Confidence breakdown:**
- Standard stack / tooling: HIGH — everything exists in-repo, versions verified locally (Xcode 26.3, bundler 4.0.13, swiftlint 0.63.3)
- Architecture (proxy, plist merge, widget flow): HIGH — file:line citations throughout; archive empirics
- Pitfalls: HIGH — most derived from observed repo state (dead Giphy script phase, duplicated STOREKIT keys, watch CA92.1 gap, CI trigger matrix), not speculation
- Apple reason-code semantics: MEDIUM-HIGH — official-doc citations retrieved via web search snippets this session (developer.apple.com pages); direct page fetch returned 404 to the fetch tool (bot-block), so quotes come from search-indexed official content

**Deviations from tool_strategy seam:** `gsd-tools` research-plan/cache seam was not invoked — `.planning/config.json` has all search providers disabled (`brave_search/exa_search/tavily_search/…: false`); built-in WebSearch/WebFetch used directly for the two external verifications required (Apple reason codes). All other findings are repo-grounded, which the provenance tags reflect.

**Research date:** 2026-09-03
**Valid until:** 2026-10-03 (repo facts are commit-pinned; Apple manifest rules stable since 2024; the working tree is expected to change during ENV-04 execution — re-verify pbxproj/Package.resolved state at execution start)

# Phase 1: Binary & Manifest Truth - Pattern Map

**Mapped:** 2026-09-03
**Files analyzed:** 15 (new/modified; 2 observe-only)
**Analogs found:** 14 / 15 (1 new doc with no codebase analog)

> This phase is build-system archaeology, not feature code. Roles below use iOS-appropriate
> labels (config/build-config, manifest, shim, utility-script, docs). Every "closest analog" is
> a real compiled/wired file — orphaned directories (repo-root `StressMonitorTests/`,
> `StressMonitor/{Models,Services,Views}/`) are excluded per AGENTS.md.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` | config (build) | build-time transform | its own current sections + `.asc/backup/spm-migration/project.pbxproj` (anti-pattern snapshot) | exact (in-place edit) |
| `StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/` (NEW: `Package.swift` + 2 shim sources) | config (SPM manifest + shim) | dependency-graph transform | `.proxies/GoogleSignIn-iOS_proxy/` (complete package) | exact (clone-the-pattern) |
| `StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift` | config (SPM manifest) | dependency-graph transform | itself (rename-only edit) | exact |
| `StressMonitor/spm-cache/packages/proxy/Package.swift` | config (SPM manifest) | dependency-graph transform | itself (extend with Firebase entries) | exact |
| `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (regenerated) | config (lockfile, generated) | dependency resolution | existing `Package.resolved` (HEAD pin `firebase-ios-sdk 11.15.0` via `git show`) | exact |
| `StressMonitor/spm-cache/packages/umbrella/Package.swift` | config (SPM cache-warmer) | dependency pinning | existing google-family pins (lines 8-15) | exact |
| `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy` | manifest (privacy) | declarative | `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` (multi-reason array, lines 72-91) | exact |
| `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` | manifest (privacy) | declarative | itself (SDK-gap aggregation only) | exact |
| `StressMonitor/StressMonitor/Info.plist` | config (bundle plist) | build-time merge | itself (reduce to `CFBundleURLTypes`); watch target's generate-only config as end-state model | exact |
| `StressMonitor/StressMonitorWidget/Info.plist` | config (bundle plist) | build-time merge | itself (1-key plist; delete-or-verify decision) | exact |
| 3 × `.entitlements` files | config (codesign entitlements) | declarative | each other (identical app-group block) — **audit only, no edits expected** | exact |
| root `CLAUDE.md` (§ Privacy & Security) | docs | n/a | `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:126-143` (normative code) + existing section structure | role-match |
| `docs-site/legal/privacy.md` + `docs-site/vi/legal/privacy.md` | docs | n/a | each other (EN/VI mirrored § AI Coaching Chat) | exact (pair) |
| `scripts/verify-archive.sh` (NEW, Wave 0) | utility (verification script) | batch artifact inspection | `scripts/run-tests.py` | role-match |
| WIRE-01 human-UAT evidence note (NEW) | docs (evidence record) | n/a | none in codebase | **no analog** |
| `.github/workflows/*`, `fastlane/Fastfile`, `fastlane/Matchfile` | config (CI/release) | pipeline | observe-only for ENV-05 — **no edits planned** | reference |

## Pattern Assignments

### `StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/` (NEW — SPM proxy shim package)

**Analog:** `StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/` — clone this shape exactly.

**Package.swift pattern** (analog: `.proxies/GoogleSignIn-iOS_proxy/Package.swift`, lines 1-21, read in full):
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GoogleSignIn-iOS_proxy",
    products: [
        .library(name: "GoogleSignIn", targets: ["GoogleSignIn-iOS_GoogleSignIn_shim"]),
        .library(name: "GoogleSignInSwift", targets: ["GoogleSignIn-iOS_GoogleSignInSwift_shim"])
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", revision: "08d8dcecafb575f98879ffdbb8302c1b9ad65d19")
    ],
    targets: [
        .target(name: "GoogleSignIn-iOS_GoogleSignIn_shim", dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ], path: "Sources/GoogleSignIn-iOS_GoogleSignIn_shim"),
        .target(name: "GoogleSignIn-iOS_GoogleSignInSwift_shim", dependencies: [
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ], path: "Sources/GoogleSignIn-iOS_GoogleSignInSwift_shim")
    ]
)
```
New Firebase package mirrors this with:
`name: "Firebase_proxy"` (name at executor discretion), one `.package(url: "https://github.com/firebase/firebase-ios-sdk.git", revision: "fdc352fabaf5916e7faa1f96ad02b1957e93e5a5")` dependency (HEAD-resolved revision per RESEARCH §8), products `FirebaseAuth` + `FirebaseCore` (these do NOT collide — upstream firebase enters the graph only through this shim, unlike the GoogleSignIn case), targets `Firebase_FirebaseAuth_shim` / `Firebase_FirebaseCore_shim`.

**Shim source pattern** (analog: `.proxies/GoogleSignIn-iOS_proxy/Sources/GoogleSignIn-iOS_GoogleSignIn_shim/GoogleSignIn-iOS_GoogleSignIn_shim.swift`, entire file):
```swift
// Auto-generated by spm-cache-proxy: re-exports the source package module(s).
@_exported import GoogleSignIn
```
New shims: `@_exported import FirebaseAuth` and `@_exported import FirebaseCore`, same header comment, one file per target under `Sources/<TargetName>/<TargetName>.swift`.

**Root-target swallow pattern** (analog: `StressMonitor/spm-cache/packages/proxy/src/root/spm_cache_root.swift` — verified **0 bytes**, keep the placeholder file).

---

### `StressMonitor/spm-cache/packages/proxy/Package.swift` (modified — add Firebase)

**Analog:** itself; the existing GoogleSignIn wiring is the exact insertion shape.

Current file (lines 1-18, read in full):
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "spm_cache_proxy",
    products: [
        .library(name: "spm_cache_proxy", targets: ["spm_cache_root"])
    ],
    dependencies: [
        .package(path: ".proxies/GoogleSignIn-iOS_proxy")
    ],
    targets: [
        .target(name: "spm_cache_root", dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS_proxy"),
                    .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS_proxy")
            ], path: "src/root")
    ]
)
```
Add: `.package(path: ".proxies/Firebase_proxy")` to `dependencies`; `.product(name: "FirebaseAuth", package: "Firebase_proxy")` + `.product(name: "FirebaseCore", package: "Firebase_proxy")` to the `spm_cache_root` target deps. If the GoogleSignIn proxy products are renamed (below), update the two `.product(name:)` lines here in the same edit.

---

### `.proxies/GoogleSignIn-iOS_proxy/Package.swift` + pbxproj (modified — collision rename, 3 places atomically)

**Rename pattern** (RESEARCH Pitfall 4 — must land in one atomic change):
1. Shim package products: `.library(name: "GoogleSignIn", …)` / `GoogleSignInSwift` → non-colliding names (e.g. `GoogleSignIn_proxied`) in `.proxies/GoogleSignIn-iOS_proxy/Package.swift` lines 7-8. The **target names** (`GoogleSignIn-iOS_GoogleSignIn_shim` etc.) and the inner `.product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")` dependency refs (lines 15, 18) stay as-is — they point upstream.
2. Proxy root: `.product(name:…)` refs in `spm-cache/packages/proxy/Package.swift` lines 14-15.
3. pbxproj `XCSwiftPackageProductDependency` (lines 1128-1132):
```
7B5DBEA14CEB67077FD66BBE /* GoogleSignIn */ = {
    isa = XCSwiftPackageProductDependency;
    package = C3ECFE78514FF7DFB2DBDB1E /* XCLocalSwiftPackageReference "proxy" */;
    productName = GoogleSignIn;
};
```
→ `productName = GoogleSignIn_proxied;` (update the `/* comment */` label too). Firebase deps (lines 1133-1142, `productName = FirebaseAuth;` / `FirebaseCore;`) stay unchanged — no collision.
Then: `cd StressMonitor/spm-cache/packages/proxy && swift package resolve`; confirm project `Package.resolved` regains `firebase-ios-sdk` 11.15.0 / `fdc352faba…`.

**Local package reference** (pbxproj lines 1120-1125, unchanged this phase):
```
/* Begin XCLocalSwiftPackageReference section */
		C3ECFE78514FF7DFB2DBDB1E /* XCLocalSwiftPackageReference "proxy" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = "spm-cache/packages/proxy";
		};
/* End XCLocalSwiftPackageReference section */
```

---

### `StressMonitor/spm-cache/packages/umbrella/Package.swift` (modified — optional firebase pin)

**Analog:** existing google-family revision pins (lines 7-16, read in full):
```swift
dependencies: [
    .package(url: "https://github.com/google/app-check.git", revision: "3e33dd27dd4c69bd81c7c81fe61d8ccf58846902"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", revision: "a7caeda164dc5108bf4649472b28a5af65dc6f33"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS.git", revision: "08d8dcecafb575f98879ffdbb8302c1b9ad65d19"),
    …
],
targets: []
```
Add the same one-liner for `https://github.com/firebase/firebase-ios-sdk.git` at `fdc352fabaf5916e7faa1f96ad02b1957e93e5a5` so the clone cache warms it (currently absent — RESEARCH §8 risk note).

---

### `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy` (modified — add CA92.1)

**Analog:** the app target's multi-reason UserDefaults array — `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` lines 72-82:
```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
            <string>1C8F.1</string>
        </array>
    </dict>
```
Edit target (watch manifest, lines 16-19 — currently `1C8F.1` only):
```xml
<key>NSPrivacyAccessedAPITypeReasons</key>
<array>
    <string>1C8F.1</string>
</array>
```
→ insert `<string>CA92.1</string>` before `1C8F.1` (matching the app target's ordering) — watch uses `UserDefaults.standard` in 4 files (RESEARCH §5.3 table). Preserve the file's tab indentation and full plist wrapper (watch manifest is 23 lines total; `NSPrivacyCollectedDataTypes` stays an empty array — the watch collects nothing).

**Formatting convention** (all three manifests): tab-indented XML, key order `NSPrivacyTracking` → `NSPrivacyTrackingDomains` → `NSPrivacyCollectedDataTypes` → `NSPrivacyAccessedAPITypes`.

---

### `StressMonitor/StressMonitor/Info.plist` (modified — BUILD-03 reduction)

**Analog:** itself. Keep lines 5-17 verbatim (the only block with no `INFOPLIST_KEY_*` equivalent):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.googleusercontent.apps.595426793312-45qv7fttusn55km8l5m60lln0amfi5rf</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.595426793312-45qv7fttusn55km8l5m60lln0amfi5rf</string>
        </array>
    </dict>
</array>
```
Delete the six `STOREKIT_*` keys (current lines 18-29) — each is duplicated byte-identically from `INFOPLIST_KEY_STOREKIT_*` build settings (pbxproj lines 892-897 Debug, 949-954 Release):
```
"INFOPLIST_KEY_STOREKIT_CREDITS_LARGE_PRODUCT_ID" = "com.stressmonitor.app.credits.large";
"INFOPLIST_KEY_STOREKIT_CREDITS_SMALL_PRODUCT_ID" = "com.stressmonitor.app.credits.small";
"INFOPLIST_KEY_STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID" = "com.stressmonitor.app.premium.annual";
"INFOPLIST_KEY_STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID" = "com.stressmonitor.app.premium.monthly";
"INFOPLIST_KEY_STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID" = 22353146;
"INFOPLIST_KEY_STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID" = "com.stressmonitor.app.premium.weekly";
```
Consumers of the merged keys: `Services/StoreKit/StoreKitProductCatalog.swift:73` reads via the 3-tier resolution below — merged product plist must keep resolving all six or StoreKit silently falls back.

**End-state model:** the watch target's config block (pbxproj lines 998-1004) — `GENERATE_INFOPLIST_FILE = YES;` with **no** `INFOPLIST_FILE` and all keys as `INFOPLIST_KEY_*`. The app keeps `"INFOPLIST_FILE" = "StressMonitor/Info.plist";` (lines 884/941) pointing at the URL-types-only file.

### `StressMonitor/StressMonitorWidget/Info.plist` (delete-or-verify)

Entire current file (11 lines) is one key:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```
Widget config block (pbxproj lines 687-690, mirrored at 723-726): `"GENERATE_INFOPLIST_FILE" = YES; "INFOPLIST_FILE" = "StressMonitorWidget/Info.plist";`. Deletion requires the empirical one-build check (RESEARCH Pitfall 3 / A2): build, `plutil -p` the product plist, confirm the NSExtension key survives; if not, keep the 1-key file and drop the duplicated `CFBundleDisplayName`/copyright settings instead.

### pbxproj Giphy script-phase removal

Delete the phase **definition** (pbxproj lines 526-544, `F2A1B0012AAA000100DE6E8F /* Generate Giphy dSYM Stub */ = { … };` inside `/* Begin PBXShellScriptBuildPhase section */`) **and** the phase **reference** (line 406) inside the app target's `buildPhases` array. It is the only `PBXShellScriptBuildPhase` in the file — after removal the whole section markers can go too. Anti-reference: `.asc/backup/spm-migration/project.pbxproj` is the pre-migration snapshot — do NOT restore anything from it; it exists only to show the user's original direction.

---

### Root `CLAUDE.md` + `docs-site/{legal,vi/legal}/privacy.md` (modified — D3 doc corrections)

**Normative source (do not edit):** `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:126-143` — raw readings pinned to `nil` (`hrv/heartRate/baselineHRV/baselineHR/sleepQuality/sleepHours/activeMinutes/recoveryScore`), with comment "Raw HealthKit-derived readings never leave the device". Behavior pinned by `StressContextPayloadTests` (3 invariants). Docs move to the code, never the reverse.

**Edit site 1 — root `CLAUDE.md` line 494** (inside `## Privacy & Security`, lines 488-494):
```
- AI Coaching Chat sends derived stress-context (stress score/category, confidence, trend, and per-factor HRV/heart-rate/sleep/activity/recovery scores — never raw HealthKit readings) to the `/chat` Supabase Edge Function under a Bearer-JWT-authenticated session, not anonymously
```
→ replace "the `/chat` Supabase Edge Function" with the real endpoint shape: `StressAPIClient.swift:116` posts to path `"chat"` on `https://stress-api.dropitx.site` (`StressAPIConfig.swift:9-19`). Also purge remaining `SupabaseLLMService` references (type no longer exists; the service is `StressLLMService`). Keep line 493's "No third-party analytics or tracking" aligned with the app manifest (`NSPrivacyTracking=false`; DeviceID/ProductInteraction entries exist because of the Google/Firebase auth SDKs).

**Edit site 2 — `docs-site/legal/privacy.md` line 30:**
> "(a Bearer JWT, established via Supabase Auth — anonymous or signed-in)"
→ auth is Firebase (`Auth.auth().signInAnonymously()` at `StressMonitorApp.swift:190`; `FirebaseAuthService.swift:2-3` imports FirebaseAuth/FirebaseCore; GoogleSignIn for the signed-in path).

**Edit site 3 — `docs-site/vi/legal/privacy.md` line 30 (mirror, Vietnamese):**
> "được thiết lập qua Supabase Auth — ẩn danh hoặc đã đăng nhập"
→ same correction in Vietnamese. EN and VI sections are paragraph-for-paragraph mirrors (verified: both § AI Coaching Chat have identical structure at line 28/30) — keep them in lockstep.

Edit `.md` sources only; `docs-site/.vitepress/dist/*` is generated output (RESEARCH A5).

---

### `scripts/verify-archive.sh` (NEW — Wave 0 artifact-inspection gate)

**Analog:** `scripts/run-tests.py` — copy its conventions:
- Shebang + module docstring stating local/CI parity (lines 1-2): `#!/usr/bin/env python3` / `"""Run StressMonitor unit tests via xcodebuild. Works locally and in CI."""` → for a bash script: `#!/bin/bash` + `# Verify StressMonitor archive: entitlements, merged plists, credential scan. Works locally and in CI.`
- Path constants rooted at repo layout (lines 11-15):
```python
PROJECT_DIR = Path(__file__).resolve().parent.parent / "StressMonitor"
PROJECT = PROJECT_DIR / "StressMonitor.xcodeproj"
```
- Print-then-exit-nonzero error convention (lines 24-26).
- Note: run-tests.py shells out to raw `xcrun simctl` — acceptable for scripts/ (the argent-MCP preference applies to interactive simulator work, not CI scripts).

The script wraps the RESEARCH §7/§14 verification trio (bash, not python, is the natural fit — executor discretion):
```bash
codesign -d --entitlements :- "<archive>/Products/Applications/StressMonitor.app"                      # ×3 bundles
plutil -p "<archive>/Products/Applications/StressMonitor.app/Info.plist"                              # merged-plist diff vs build-13 golden
strings -a "<binary>" | grep -inE "PRIVATE KEY|supabase|sk-[A-Za-z0-9]|anon[_-]?key|BEGIN RSA|Bearer [A-Za-z0-9._-]{20,}"   # AUTH-01
```
Golden reference: `.asc/artifacts/StressMonitor.xcarchive` (build 13 — **preserve, never delete**). Include the §7 false-positive triage list as comments so `eyJlcnJvciI6…`, `supabaseAccessToken` (Keychain-cleanup literals, `FirebaseAuthService.swift:133`), and `AIza` in GoogleService-Info.plist don't fail the gate.

---

## Shared Patterns

### App Group suite constant (duplicated-by-convention across targets)
**Sources:** `StressMonitor/StressMonitor/Models/WidgetSharedData.swift:98-104`, `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:10`, watch `WatchSharedDataStore.swift:16`, `WatchFacePreferences.swift:15`, `ComplicationDataProvider.swift:14`, `CharacterCollectionViewModel.swift:116`
**Apply to:** BUILD-02 audit only — verify, do not edit. Canonical value (repo truth, overrides CONTEXT.md typo):
```swift
enum WidgetConstants {
    static let appGroupID = "group.stress.ai.com"
```
No shared module exists between targets — constants are duplicated by convention and pinned by `WidgetPublisherKeyMatchingTests`. Any diff touching an entitlements suite string is a red flag (RESEARCH Pitfall 1).

### Entitlements block (identical across app + watch; widget declares app-group only)
**Source:** all three `.entitlements` files (read in full this session)
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.stress.ai.com</string>
</array>
```
App + watch additionally carry `com.apple.developer.healthkit` (true), `com.apple.developer.icloud-container-identifiers` = `iCloud.stress.ai.com`, `com.apple.developer.icloud-services` = CloudKit. Tab-indented, that key order.

### Runtime config 3-tier resolution (SupabaseConfig precedent)
**Source:** `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:8-14`
```swift
enum StressAPIConfig {
    static let baseURL: URL = resolveBaseURL(
        infoPlistValue: Bundle.main.object(forInfoDictionaryKey: "STRESS_API_BASE_URL") as? String,
        environmentValue: ProcessInfo.processInfo.environment["STRESS_API_BASE_URL"],
        userDefaultsValue: UserDefaults.standard.string(forKey: "stressAPIBaseURL"),
        fallback: "https://stress-api.dropitx.site"
    )
```
**Apply to:** BUILD-03 sanity thinking — merged-plist consumers (`StressAPIConfig`, `StoreKitProductCatalog.swift:73`) read Info.plist first; plist consolidation must not starve tier 1.

### CI-parity build command
**Source:** AGENTS.md / `.github/workflows/_test.yml` convention
```bash
xcodebuild build -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```
**Apply to:** every smoke-build/archive gate task (ENV-04 SC-6, widget-plist empirical check). Watch scheme name contains spaces: `-scheme "StressMonitorWatch Watch App"`.

### fastlane match readonly (ENV-05 — observe, don't edit)
**Source:** `fastlane/Fastfile` lines 96-123 (`build_only`) and 127-203 (`upload_beta`):
```ruby
match(
  type: "appstore",
  readonly: true,
  api_key: api_key
)
```
Profile names `match AppStore stress.ai.com{,.watchkitapp,.widget}` (lines 140-142, 186-190). Triggers: `deploy.yml` on `workflow_run: branches [main, release/*]` + `workflow_dispatch`; `match.yml` manual `regenerate` job (`workflow_dispatch` only) is the documented fallback surface. A bare branch push fires neither (RESEARCH Open Question 3 — planner must pick PR vs dispatch with user).

### Auto-generated shim header convention
**Source:** both existing shim files: `// Auto-generated by spm-cache-proxy: re-exports the source package module(s.)` — keep the comment in new Firebase shims so tool-regeneration stays identifiable. `proxy/graph.json` tracks module status (`"missed"` entries today); extend alongside if the tool expects it.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| WIRE-01 human-UAT evidence note | docs | n/a | No UAT/evidence-record templates exist in the repo; planner should use RESEARCH §10's evidence spec (same-timestamp widget + app screenshots, six suite keys non-nil, widget present in archive `PlugIns/`) as the structure |

## Do-Not-Map Zones (orphaned, never builds)

`StressMonitorTests/` (repo root), `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/` (repo root). Real targets: `StressMonitor/StressMonitor/`, `StressMonitor/StressMonitorTests/`, `StressMonitor/StressMonitorWidget/`, `StressMonitor/StressMonitorWatch Watch App/` (path has spaces).

## Metadata

**Analog search scope:** `StressMonitor/StressMonitor.xcodeproj/`, `StressMonitor/spm-cache/packages/**`, `StressMonitor/{StressMonitor,StressMonitorWidget,StressMonitorWatch Watch App}/` (manifests, entitlements, plists, key Swift sources), `scripts/`, `fastlane/`, `.github/workflows/`, `docs-site/{legal,vi/legal}/`, root `CLAUDE.md`, `.asc/backup/spm-migration/`
**Files scanned:** ~25 (read in full or targeted)
**Pattern extraction date:** 2026-09-03
**Verification note:** all excerpts re-verified against the live working tree this session (post-research); pbxproj line numbers cited for the current file state.

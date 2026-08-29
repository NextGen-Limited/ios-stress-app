# Technology Stack

**Analysis Date:** 2026-08-29

## Languages

**Primary:**
- Swift 5 (`SWIFT_VERSION = 5.0` in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`) — all app/watch/widget/test targets. UI is pure SwiftUI; concurrency is modern async/await. No third-party UI libraries remain (exyte/Chat, Kingfisher, Giphy, SwiftUICharts, MediaPicker were all removed with the v1.1 backend migration).

**Secondary:**
- Ruby — fastlane lanes (`fastlane/Fastfile`, `Gemfile`: `fastlane ~> 2.236`, `xcpretty ~> 0.4`, `Gemfile.lock` committed)
- Python 3 — dev tooling: `scripts/run-tests.py` (simulator discovery + xcodebuild test runner, writes `StressMonitor/build/`), `scripts/generate_app_icons.py`
- Bash — Xcode Cloud hooks `ci_scripts/ci_post_clone.sh`, `ci_scripts/ci_post_xcodebuild.sh`
- YAML — GitHub Actions workflows (`.github/workflows/*.yml`), SwiftLint config (`.swiftlint.yml`), SPM cache config (`StressMonitor/spm-cache.yml`)
- JavaScript/Markdown — VitePress docs site (`docs-site/package.json`, name `stressmonitor-docs`)

## Runtime

**Environment:**
- iOS 18.6 deployment target for app/test targets; project-level configs carry `IPHONEOS_DEPLOYMENT_TARGET = 26.1` (per-target overrides land at 18.6)
- watchOS 11.6 for the watch target
- CI: Xcode 26.3 on `macos-15` runner (`.github/workflows/_test.yml` `XCODE_VERSION` env); test destination `platform=iOS Simulator,name=iPhone 16,OS=latest`
- Local testing note: the `StressMonitor` scheme embeds the watch app, so `xcodebuild test` requires the watchOS simulator runtime to be installed (`xcodebuild -downloadPlatform watchOS`) — a fresh Xcode install refuses the scheme without it
- `TARGETED_DEVICE_FAMILY = "1,2"` — iPhone + iPad; watch target device family 4

**Package Manager:**
- Swift Package Manager (Xcode-native, 2 package references in the pbxproj)
  - Lockfile: `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (present, `version: 3`)
  - Local revision-pinned mirror: `StressMonitor/spm-cache/` — `spm-cache.yml` (config; `default_sdk: iphonesimulator`), `spm-cache.lock` (mirror of resolved pins), `packages/umbrella/Package.swift` (`// swift-tools-version: 6.0`, pins every dep by exact revision), `packages/proxy/`, `packages/clones/`
- Bundler for Ruby gems — `Gemfile.lock` committed at repo root
- No CocoaPods (`excluded: - Pods` in `.swiftlint.yml` is vestigial), no Carthage

## Targets

Defined in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (4 native targets):

| Target | Bundle ID | Source root |
|---|---|---|
| `StressMonitor` (iOS app) | `stress.ai.com` | `StressMonitor/StressMonitor/` |
| `StressMonitorTests` | `stress.ai.com.StressMonitorTests` | `StressMonitor/StressMonitorTests/` |
| `StressMonitorWatch Watch App` | `stress.ai.com.watchkitapp` | `StressMonitor/StressMonitorWatch Watch App/` (path contains spaces) |
| `StressMonitorWidgetExtension` | `stress.ai.com.widget` | `StressMonitor/StressMonitorWidget/` |

- SPM products `FirebaseAuth`, `FirebaseCore`, `GoogleSignIn` are linked to the **iOS app target only** (`packageProductDependencies` on `StressMonitor`); watch/widget targets carry no external packages
- Shared Xcode schemes: `StressMonitor`, `"StressMonitorWatch Watch App"` (`StressMonitor/StressMonitor.xcodeproj/xcshareddata/xcschemes/`). The widget has no shared scheme file — CI builds it via its auto-created scheme (`-scheme StressMonitorWidgetExtension` in `_test.yml`)
- Signing: team `K2TYLYAWMK` at project level for `iphoneos*`/`watchos*` SDKs; project Debug config carries `DEVELOPMENT_TEAM = EQ8B89SPCX`; `CODE_SIGN_IDENTITY` "Apple Development" with per-SDK Distribution overrides. CI builds with `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`; releases sign via Match
- Privacy manifests present in all three app targets: `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy`, `StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy`, `StressMonitor/StressMonitorWidget/PrivacyInfo.xcprivacy`

**Orphaned code — NOT in the Xcode project, edits never build:** repo-root `StressMonitorTests/` (5 legacy suites), `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, plus `StressMonitor/AGENTS.md`. Real code lives under `StressMonitor/StressMonitor/` etc.

## Frameworks

**Core (Apple, first-party — no import cost):**
- SwiftUI + `@Observable` MVVM — `StressMonitor/StressMonitor/StressMonitorApp.swift`, `ViewModels/`, `Views/`
- SwiftData — persistence via `ModelContainer` with 3-stage crash recovery (delete incompatible store → local-only container → in-memory last resort) (`StressMonitorApp.swift:92-141`), `@Model` entities in `StressMonitor/StressMonitor/Models/`
- HealthKit — read-only stress inputs, `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` (+`ActivityFetch`/`RecoveryFetch`/`SleepFetch` extensions)
- CloudKit — sync, `StressMonitor/StressMonitor/Services/CloudKit/` (`CloudKitManager.swift`, `CloudKitSyncEngine.swift`, `CloudKitSchema.swift`)
- WidgetKit + AppIntents + ActivityKit — `StressMonitor/StressMonitorWidget/` (timeline widgets, control, Live Activity)
- StoreKit 2 — subscriptions/credit packs with server-side JWS verification, `StressMonitor/StressMonitor/Services/StoreKit/`
- WatchConnectivity — phone↔watch, `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift`, `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`
- UserNotifications — local notifications only, `StressMonitor/StressMonitor/Services/Background/NotificationManager.swift`
- URLSession — plain `URLSession`/`URLSession.AsyncBytes` for REST + SSE streaming (no Alamofire); `os.Logger` for logging

**External (SPM):**
- `firebase-ios-sdk` (constraint >= 11.0.0, **resolved 11.15.0**) — products `FirebaseAuth`, `FirebaseCore`. Auth only; no Firestore/Analytics/Crashlytics products linked
- `GoogleSignIn-iOS` (constraint >= 9.0.0, **resolved 9.2.0**) — product `GoogleSignIn`
- Transitive resolved deps (from `Package.resolved`): `app-check` 11.3.1, `appauth-ios` 2.1.0, `gtmappauth` 5.0.0, `gtm-session-fetcher` 3.5.0, `google-utilities` 8.1.2, `googleappmeasurement` 11.15.0, `googledatatransport` 10.1.1, `google-ads-on-device-conversion-ios-sdk` 2.3.0, `interop-ios-for-google-sdks` 101.0.0, `grpc-binary` 1.69.1, `abseil-cpp-binary`, `leveldb` 1.22.5, `nanopb`, `promises` 2.4.1, `swift-protobuf` 1.38.1

**Testing:**
- XCTest — `StressMonitor/StressMonitorTests/` (35 `*Tests.swift` suites + `StoreKitTestSessionProvider.swift` helper + `StressMonitorProducts.storekit` fixture)
- URLProtocol-mocked HTTP tests — `StressAPIClientTests`, `StressAPIClient+{Credits,Preferences,QuickActions,Sessions}Tests`, `StressAPIConfigTests`
- StoreKit testing — `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` via `StoreKitTestSessionProvider.swift` (one shared `SKTestSession` per process; constructing a second session detaches the daemon)
- Mock services — `StressMonitor/StressMonitor/Services/MockServices.swift`, `Services/StoreKit/MockStoreKitService.swift`
- CI gating: `TEST_RUNNER_GSD_CI=1` in `_test.yml` disables the 2 host-restart-sensitive tests in `DataDeletionConsolidationTests.swift:238,375` (`.enabled(if: ProcessInfo...["GSD_CI"] == nil)`)
- Known run state (orchestrator verification 2026-08-29): 244 tests → 223 pass, 6 pre-existing failures (WINDOWS.md #8 lineage), 15 skips (`CharacterEntitlementSyncTests` + StoreKit-config-dependent suites)
- Demo mode launch arg `-demo-mode` cycles stress levels through the real pipeline (HealthKit has no simulator data)

**Build/Dev:**
- `xcodebuild` (all commands run from repo root with `-project StressMonitor/StressMonitor.xcodeproj`)
- fastlane — lanes `build_only`, `build_widget`, `dump_capabilities`, `setup_match`, `upload_beta`, `distribute_beta`, `release`, `increment_build` (`fastlane/Fastfile`)
- SwiftLint — `.swiftlint.yml` at repo root; `included: StressMonitor/`; opt-in `force_unwrapping` + `implicitly_unwrapped_optional`; line_length warn 150 / error 250. CI runs it advisory (`|| true`)
- `scripts/run-tests.py` — finds/boots simulator, writes results to `StressMonitor/build/`

## Key Dependencies

**Critical:**
- `FirebaseAuth` — sole auth provider; ID tokens are the Bearer credential for every backend call (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`, protocol `AuthServiceProtocol` in the same file)
- `GoogleSignIn` — Google sign-in credential source, linked to anonymous Firebase accounts (`FirebaseAuthService.swift`); UIKit presenter bridged from `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:436-450`
- Standalone StressMonitor backend (`https://stress-api.dropitx.site`) — chat/LLM streaming, credits, sessions, preferences, quick actions; see INTEGRATIONS.md

**Infrastructure:**
- CloudKit (private DB, container `iCloud.stress.ai.com`) — cross-device sync
- App Group `group.stress.ai.com` — widget↔app data sharing via `UserDefaults(suiteName:)` (`StressMonitor/StressMonitor/Models/WidgetSharedData.swift`)
- fastlane + Match + App Store Connect API — CI/CD

## Configuration

**Environment:**
- Backend base URL resolves 3-tier: Info.plist `STRESS_API_BASE_URL` → process env → `UserDefaults` key `stressAPIBaseURL` → fallback `https://stress-api.dropitx.site` (`StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`). Note: no `STRESS_API_BASE_URL` key is currently set in `StressMonitor/StressMonitor/Info.plist` or the pbxproj — the shipped binary always uses the fallback unless the env/UserDefaults tier is set (testable via `StressAPIConfig.resolveBaseURL(...)`)
- App `Info.plist` (`StressMonitor/StressMonitor/Info.plist`) carries: Google URL scheme (`com.googleusercontent.apps.595426793312-...`) and 6 StoreKit keys (`STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID`, `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID = SMPREMIUM01`, `STOREKIT_CREDITS_{SMALL,LARGE}_PRODUCT_ID`) — consumed by `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- `GoogleService-Info.plist` (Firebase project `stress-io`) is **gitignored** (`.gitignore:174`), expected at `StressMonitor/StressMonitor/GoogleService-Info.plist`. `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift` degrades to `.missingConfiguration` (os.Logger `.fault`, never a trap) when absent — a fresh checkout builds and launches, but auth/chat/credits/IAP-grant are inert. CI provisioning (`GOOGLE_SERVICE_INFO_PLIST_BASE64` secret + `ci_scripts/provision_firebase_config.sh`) is planned but **not yet implemented** — CI-produced builds ship without it (`.planning/quick/260829-kby-*`)
- Most Info.plist entries are generated via `INFOPLIST_KEY_*` in the pbxproj (`GENERATE_INFOPLIST_FILE = YES`), incl. HealthKit/camera usage strings, `UIBackgroundModes = "fetch processing"`, watch companion bundle ID
- Entitlements (`StressMonitor/StressMonitor/StressMonitor.entitlements`, watch + widget equivalents): HealthKit, CloudKit (`iCloud.stress.ai.com`), App Group (`group.stress.ai.com`) — widget entitlements file carries only the app group
- No `.env` files; secrets live in GitHub Actions secrets and locally in `~/.appstoreconnect/`

**Build:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — single project, 4 targets, SPM packages attached per-target; `ENABLE_USER_SCRIPT_SANDBOXING = YES`; `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 1`
- `.swiftlint.yml` — lint rules (repo root)
- `fastlane/Fastfile`, `fastlane/Matchfile`, `Gemfile` — release automation
- `.github/workflows/` — `ci.yml` (pull_request → main/develop + manual; calls `_test.yml`), `deploy.yml` (`workflow_run` on CI completion for main/release/*), `distribute.yml`, `release.yml`, `match.yml`, `droid-wiki-refresh.yml`
- SPM caching: `StressMonitor/spm-cache.yml` + `spm-cache.lock` + `StressMonitor/spm-cache/packages/` local mirror; GitHub Actions caches DerivedData + SPM checkouts keyed on pbxproj/`Package.resolved` hashes

## Platform Requirements

**Development:**
- macOS with Xcode 26.x (CI pins 26.3), iOS 26.3 + watchOS 26.2 simulator runtimes (watchOS runtime required to run the app scheme's tests)
- Ruby 3.3 + Bundler for fastlane
- SwiftLint installed (`brew install swiftlint` if missing)
- `StressMonitor/StressMonitor/GoogleService-Info.plist` restored locally (gitignored) for Firebase-backed features and `FirebaseBootstrapTests`
- No HealthKit data on simulator — use `-demo-mode` launch argument

**Production:**
- App Store / TestFlight distribution via fastlane `upload_beta`
- Apple signing team `K2TYLYAWMK`, certs via Match (`MATCH_GIT_URL` + `MATCH_PASSWORD`); CI syncs Match readonly
- Firebase project `stress-io` (Auth enabled); backend at `stress-api.dropitx.site`

---

*Stack analysis: 2026-08-29*

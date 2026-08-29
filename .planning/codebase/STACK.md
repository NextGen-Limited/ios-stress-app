# Technology Stack

**Analysis Date:** 2026-08-29

## Languages

**Primary:**
- Swift 5 (`SWIFT_VERSION = 5.0` in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`) — all app/watch/widget/test targets. UI is SwiftUI; concurrency is modern async/await.

**Secondary:**
- Ruby — fastlane lanes (`fastlane/Fastfile`, `Gemfile`: `fastlane ~> 2.236`, `xcpretty ~> 0.4`)
- Python 3 — dev tooling: `scripts/run-tests.py` (simulator boot + test runner), `scripts/generate_app_icons.py`
- Bash — Xcode Cloud hooks `ci_scripts/ci_post_clone.sh`, `ci_scripts/ci_post_xcodebuild.sh`
- YAML — GitHub Actions workflows (`.github/workflows/*.yml`), SwiftLint config (`.swiftlint.yml`)

## Runtime

**Environment:**
- iOS 18.6 deployment target for the app/test targets; project-level configs carry `IPHONEOS_DEPLOYMENT_TARGET = 26.1` (per-target overrides land at 18.6)
- watchOS 11.6 for the watch target
- CI: Xcode 26.3 on `macos-15` runner (`.github/workflows/_test.yml` `XCODE_VERSION` env)
- `TARGETED_DEVICE_FAMILY = "1,2"` — iPhone + iPad; watch target device family 4

**Package Manager:**
- Swift Package Manager (Xcode-native, packages attached in the pbxproj)
  - Lockfile: `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (present)
- Bundler for Ruby gems — `Gemfile.lock` committed at repo root
- No CocoaPods (`excluded: - Pods` in `.swiftlint.yml` is vestigial), no Carthage

## Targets

Defined in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`:

| Target | Bundle ID | Source root |
|---|---|---|
| `StressMonitor` (iOS app) | `stress.ai.com` | `StressMonitor/StressMonitor/` |
| `StressMonitorTests` | `stress.ai.com.StressMonitorTests` | `StressMonitor/StressMonitorTests/` |
| `StressMonitorWatch Watch App` | `stress.ai.com.watchkitapp` | `StressMonitor/StressMonitorWatch Watch App/` (path contains spaces) |
| `StressMonitorWidgetExtension` | `stress.ai.com.widget` | `StressMonitor/StressMonitorWidget/` |

Schemes: `StressMonitor`, `"StressMonitorWatch Watch App"` (shared); `StressMonitorWidgetExtension` has no shared scheme file (CI builds it by target).

Signing: team `K2TYLYAWMK` at target level for `iphoneos`/`watchos` SDKs; project-level Debug config carries `DEVELOPMENT_TEAM = EQ8B89SPCX`. CI builds with `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`; releases sign via Match.

**Orphaned code — NOT in the Xcode project, edits never build:** `StressMonitorTests/` (repo root), `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`. Real code lives under `StressMonitor/StressMonitor/` etc.

## Frameworks

**Core (Apple, first-party — no import cost):**
- SwiftUI + `@Observable` MVVM — `StressMonitor/StressMonitor/StressMonitorApp.swift`, `ViewModels/`, `Views/`
- SwiftData — persistence via `ModelContainer` with crash recovery (`StressMonitorApp.swift:92-141`), `@Model` entities in `StressMonitor/StressMonitor/Models/` (`StressMeasurement.swift`, `Habit.swift`, `Character/CharacterUnlock.swift`)
- HealthKit — read-only stress inputs, `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` (+`ActivityFetch`/`RecoveryFetch`/`SleepFetch` extensions)
- CloudKit — sync, `StressMonitor/StressMonitor/Services/CloudKit/` (`CloudKitManager.swift`, `CloudKitSyncEngine.swift`, `CloudKitSchema.swift`)
- WidgetKit + AppIntents + ActivityKit — `StressMonitor/StressMonitorWidget/` (`StressMonitorWidgetBundle.swift`, `AppIntent.swift`, `StressMonitorWidgetLiveActivity.swift`, `StressMonitorWidgetControl.swift`)
- StoreKit 2 — subscriptions/credit packs, `StressMonitor/StressMonitor/Services/StoreKit/`
- WatchConnectivity — phone↔watch, `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`
- UserNotifications — local notifications only, `StressMonitor/StressMonitor/Services/Background/NotificationManager.swift`
- URLSession — plain `URLSession`/`URLSession.AsyncBytes` for REST + SSE streaming (no Alamofire); `os.Logger` for logging

**External (SPM):**
- `firebase-ios-sdk` >= 11.0.0 (up-to-next-major) — products `FirebaseAuth`, `FirebaseCore`. Auth only; `GoogleService-Info.plist` (Firebase project `stress-io`) is committed at `StressMonitor/StressMonitor/GoogleService-Info.plist`
- `GoogleSignIn-iOS` >= 9.0.0 (up-to-next-major) — product `GoogleSignIn`
- Transitive resolved deps (from `Package.resolved`): `app-check` 11.3.1, `appauth-ios` 2.1.0, `abseil-cpp-binary`, `leveldb`, `nanopb`, `glog`, `Promises`, `SwiftProtobuf`, `GTMSessionFetcher`, `google-utilities`

**Testing:**
- XCTest — `StressMonitor/StressMonitorTests/` (36 test suites, e.g. `SSEParserTests`, `StressAPIClientTests`, `StoreKitServiceTests`)
- StoreKit testing — `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` config via `StoreKitTestSessionProvider.swift`
- Mock services — `StressMonitor/StressMonitor/Services/MockServices.swift`, `MockStoreKitService.swift`
- Demo mode launch arg `-demo-mode` cycles stress levels through the real pipeline (HealthKit has no simulator data)

**Build/Dev:**
- `xcodebuild` (all commands run from repo root with `-project StressMonitor/StressMonitor.xcodeproj`)
- fastlane — lanes `upload_beta`, `distribute_beta`, `release`, `build_only`, `build_widget`, `increment_build` (`fastlane/Fastfile`)
- SwiftLint — `.swiftlint.yml` at repo root; `included: StressMonitor/`; opt-in `force_unwrapping` + `implicitly_unwrapped_optional`; CI runs it advisory (`|| true`)
- `scripts/run-tests.py` — finds/boots simulator, writes results to `StressMonitor/build/`

## Key Dependencies

**Critical:**
- `FirebaseAuth` — sole auth provider; ID tokens are the Bearer credential for every backend call (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`)
- `GoogleSignIn` — Google sign-in credential source, linked to anonymous Firebase accounts (`FirebaseAuthService.swift:83-121`)
- Standalone StressMonitor backend (`https://stress-api.dropitx.site`) — chat/LLM streaming, credits, sessions, preferences; see INTEGRATIONS.md

**Infrastructure:**
- CloudKit (private DB, container `iCloud.stress.ai.com`) — cross-device sync
- App Group `group.stress.ai.com` — widget↔app data sharing via `UserDefaults(suiteName:)` (`StressMonitor/StressMonitor/Models/WidgetSharedData.swift:100,133`)
- fastlane + Match + App Store Connect API — CI/CD

## Configuration

**Environment:**
- Backend base URL resolves 3-tier: Info.plist `STRESS_API_BASE_URL` build setting → process env → `UserDefaults` key `stressAPIBaseURL` → fallback `https://stress-api.dropitx.site` (`StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`)
- App `Info.plist` (`StressMonitor/StressMonitor/Info.plist`) carries: Google URL scheme (`com.googleusercontent.apps.595426793312-...`) and 5 StoreKit product-ID keys (`STOREKIT_PREMIUM_*`, `STOREKIT_CREDITS_*`) — consumed by `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- Most Info.plist entries are generated via `INFOPLIST_KEY_*` in the pbxproj (`GENERATE_INFOPLIST_FILE = YES`), incl. HealthKit/camera usage strings, `WKBackgroundModes = fetch`, watch companion bundle ID
- Entitlements: HealthKit, CloudKit (`iCloud.stress.ai.com`), App Group (`group.stress.ai.com`) — `StressMonitor/StressMonitor/StressMonitor.entitlements`; widget shares the app group (`StressMonitor/StressMonitorWidget/StressMonitorWidget.entitlements`)
- No `.env` files; secrets live in GitHub Actions secrets and locally in `~/.appstoreconnect/`

**Build:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — single project, 4 targets, SPM packages attached per-target
- `.swiftlint.yml` — lint rules (repo root)
- `fastlane/Fastfile`, `Gemfile` — release automation
- `.github/workflows/` — `ci.yml` (calls `_test.yml`), `deploy.yml`, `distribute.yml`, `release.yml`, `match.yml`
- SPM caching: `StressMonitor/spm-cache*` (local cache helper files)

## Platform Requirements

**Development:**
- macOS with Xcode 26.x (CI pins 26.3), matching iOS/watchOS simulator runtimes (iPhone 16 / latest OS)
- Ruby 3.3 + Bundler for fastlane
- SwiftLint installed (`brew install swiftlint` if missing)
- No HealthKit data on simulator — use `-demo-mode` launch argument

**Production:**
- App Store / TestFlight distribution via fastlane `upload_beta`
- Apple signing team `K2TYLYAWMK`, certs via Match (`MATCH_GIT_URL` + `MATCH_PASSWORD`); CI syncs Match readonly
- Firebase project `stress-io` (Auth enabled); backend at `stress-api.dropitx.site`

---

*Stack analysis: 2026-08-29*

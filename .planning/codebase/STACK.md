# Technology Stack

**Analysis Date:** 2026-08-08

## Languages

**Primary:**
- Swift (`SWIFT_VERSION = 5.0` in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`) — all app, watch, widget, and test code
- Note: the SPM cache umbrella package declares `// swift-tools-version: 6.0` (`StressMonitor/spm-cache/packages/umbrella/Package.swift`), so the toolchain is Swift 6.x compiling app targets in Swift 5 language mode

**Secondary:**
- Ruby — Fastlane automation (`fastlane/Fastfile`, `Gemfile`)
- Bash — CI hooks (`ci_scripts/ci_post_clone.sh`, `ci_scripts/ci_post_xcodebuild.sh`)
- JavaScript/Markdown — VitePress docs site (`docs-site/package.json`)

## Runtime

**Environment:**
- iOS 18.6+ (`IPHONEOS_DEPLOYMENT_TARGET = 18.6` for app/widget; one config uses `26.1`)
- watchOS 11.6+ (`WATCHOS_DEPLOYMENT_TARGET = 11.6`)
- `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` for the iPhone target

**Package Manager:**
- Swift Package Manager (integrated in Xcode project)
- Lockfile: present — `StressMonitor/StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (`version: 3`)
- Ruby gems: `Gemfile` / `Gemfile.lock`
- Node (docs site only): `docs-site/package.json`
- Local SPM mirror/cache: `StressMonitor/spm-cache/packages/umbrella/Package.swift` and `StressMonitor/spm-cache/packages/proxy/`

## Frameworks

**Core (Apple system frameworks, by import frequency):**
- SwiftUI (254 imports) — entire UI layer, no UIKit-driven screens
- Foundation (152)
- SwiftData (48) — `@Model` persistence (`StressMeasurement`, `CharacterUnlock`)
- WidgetKit (22) — `StressMonitor/StressMonitorWidget/`
- Observation (20) — `@Observable` ViewModels
- HealthKit (17) — `StressMonitor/StressMonitor/Services/HealthKit/`
- CloudKit (17) — `StressMonitor/StressMonitor/Services/CloudKit/`
- Charts (10) — Swift Charts for trend views
- UIKit (9) — bridging/haptics only
- AppIntents (4) — widget/control intents (`StressMonitor/StressMonitorWidget/AppIntent.swift`)
- WatchConnectivity (2) — `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift`
- StoreKit, Security (Keychain), UserNotifications, BackgroundTasks, CoreHaptics, CoreMotion, CoreML, SafariServices, WatchKit, os.log — one to a few call sites each

**Testing:**
- XCTest and Swift Testing (`import Testing`, 4 files) — see `StressMonitor/StressMonitorTests/` and `StressMonitorTests/`

**Build/Dev:**
- Xcode project format `objectVersion = 77`
- SwiftLint — config `.swiftlint.yml` (line_length warn 150/err 250; opt-in `force_unwrapping`, `implicitly_unwrapped_optional`, `empty_count`)
- Fastlane `~> 2.236` + `xcpretty ~> 0.4` (`Gemfile`)
- `ENABLE_USER_SCRIPT_SANDBOXING = YES`

## Key Dependencies

Resolved third-party SPM packages (`Package.resolved`):

**Critical:**
- `exyte/Chat` 3.0.2 — chat UI used by the AI coaching sheet
- `willdale/SwiftUICharts` 2.10.4 — charting (linked as a project target, alongside Swift Charts)

**Infrastructure / transitive:**
- `onevcat/Kingfisher` 8.8.1 — remote image loading
- `SDWebImage/libwebp-Xcode` 1.5.0 — WebP decoding (Kingfisher dep)
- `exyte/MediaPicker` 3.3.2 — media attachment picker for Chat
- `Giphy/giphy-ios-sdk` 2.2.16 — GIF picker inside Chat
- `exyte/ActivityIndicatorView` 1.2.1, `exyte/AnchoredPopup` 1.1.3 — Chat UI support

Note: CLAUDE.md claims "Dependencies: None (system only)". That is no longer accurate — 8 external packages are pinned.

## Configuration

**Environment:**
- No `.env` files present. Runtime configuration resolves in a 3-tier order (Info.plist build setting → process environment → `UserDefaults`), implemented in `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift` and `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`
- Key config values: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_GUEST_JWT`, `STOREKIT_PREMIUM_{WEEKLY,MONTHLY,ANNUAL}_PRODUCT_ID`, `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID`
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift` is gitignored (`.gitignore:164`) and holds a local dev JWT fallback
- Launch argument `-demo-mode` enables `SimulatorHealthKitService` (see `StressMonitor/StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift`)

**Build:**
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — all build settings
- `StressMonitor/StressMonitor/Info.plist` (empty dict; usage strings live in `INFOPLIST_KEY_*` build settings)
- `StressMonitor/StressMonitor/StressMonitor.entitlements` and `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements` — both declare only `com.apple.developer.healthkit`
- `StressMonitor/StressMonitorWidget/Info.plist` — `com.apple.widgetkit-extension`
- Background modes: `INFOPLIST_KEY_UIBackgroundModes = "fetch processing"`
- Orientation: portrait on iPhone, landscape-right on iPad

**Bundle identifiers:**
- App: `stress.ai.com`
- Watch app: `stress.ai.com.watchkitapp`
- Widget: `stress.ai.com.widget`
- `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 1`

## Platform Requirements

**Development:**
- Xcode capable of `objectVersion = 77` projects, iOS 18.6/watchOS 11.6 SDKs
- Homebrew-installed Fastlane on CI (`ci_scripts/ci_post_clone.sh`)
- SwiftLint for lint gate

**Production:**
- App Store / TestFlight distribution. Two signing teams appear: `EQ8B89SPCX` and `K2TYLYAWMK` (per-SDK override for `iphoneos*`/`watchos*`)
- Xcode Cloud (`ci_scripts/`) plus GitHub Actions (`.github/workflows/ci.yml`, `_test.yml`, `deploy.yml`, `distribute.yml`, `release.yml`)
- Code signing via Fastlane Match (`fastlane/Matchfile`, readonly on CI)

---

*Stack analysis: 2026-08-08*

# Technology Stack

**Analysis Date:** 2026-09-01

## Languages

**Primary:**
- Swift 5 language mode - iOS app code in `StressMonitor/StressMonitor/`, watchOS code in `StressMonitor/StressMonitorWatch Watch App/`, widget code in `StressMonitor/StressMonitorWidget/`, and XCTest suites in `StressMonitor/StressMonitorTests/`; the project setting is `SWIFT_VERSION = 5.0` in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.

**Secondary:**
- Ruby - Fastlane delivery automation in `fastlane/Fastfile`, `fastlane/Appfile`, and `fastlane/Matchfile`; dependencies are declared in `Gemfile`.
- Python 3 - local simulator discovery and test orchestration in `scripts/run-tests.py`.
- JavaScript/JSON/Markdown - VitePress documentation site configuration and content under `docs-site/`; `docs-site/package.json` declares an ES module package.
- YAML - GitHub Actions CI/CD under `.github/workflows/`.

## Runtime

**Environment:**
- Xcode 26.3 on macOS 15 is the CI toolchain declared in `.github/workflows/_test.yml` and `.github/workflows/deploy.yml`.
- iOS Simulator/device for `StressMonitor/StressMonitor/`; the principal app and test targets use iOS 18.6, while project-level settings include iOS 26.1 entries in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- watchOS Simulator/device for `StressMonitor/StressMonitorWatch Watch App/`; deployment target is watchOS 11.6 in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- WidgetKit extension runtime for `StressMonitor/StressMonitorWidget/`, embedded in the iOS app.
- Node.js runtime for the documentation-only VitePress site under `docs-site/`; no Node version is pinned in the repository.
- Ruby 3.3 in CI for Fastlane/Bundler, configured in `.github/workflows/_test.yml`.

**Package Manager:**
- Swift Package Manager via Xcode - direct application dependencies are Firebase iOS SDK 11.15.0 and GoogleSignIn-iOS 9.2.0; resolved transitive versions are locked in `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- Bundler - Fastlane `~> 2.236` and xcpretty `~> 0.4` are declared in `Gemfile`; `Gemfile.lock` is present.
- npm - VitePress `^1.6.3` is declared in `docs-site/package.json`; lockfile is `docs-site/package-lock.json`.

## Frameworks

**Core:**
- SwiftUI - declarative UI and application entry points, including `StressMonitor/StressMonitor/StressMonitorApp.swift`, `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatchApp.swift`, and widget views under `StressMonitor/StressMonitorWidget/Views/`.
- Observation - `@Observable` state models and view models, for example `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` and `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift`.
- SwiftData - local persistence and model queries; the production `ModelContainer` is assembled in `StressMonitor/StressMonitor/StressMonitorApp.swift` and accessed through `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`.
- HealthKit - read-side health inputs for HRV, heart rate, sleep, activity, and recovery under `StressMonitor/StressMonitor/Services/HealthKit/`; the watch target has its own integration in `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift`.
- CloudKit - private iCloud record synchronization in `StressMonitor/StressMonitor/Services/CloudKit/` and duplicated watch persistence in `StressMonitor/StressMonitorWatch Watch App/Services/CloudKit/`.
- StoreKit 2 - subscriptions and consumable credit packs in `StressMonitor/StressMonitor/Services/StoreKit/`.
- WidgetKit/AppIntents - home/lock-screen widgets and watch complications under `StressMonitor/StressMonitorWidget/` and `StressMonitor/StressMonitorWatch Watch App/Complications/`.
- WatchConnectivity - phone/watch transfer in `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` and `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`.

**Testing:**
- XCTest - unit and integration-style tests under the real test target `StressMonitor/StressMonitorTests/`; StoreKit tests use `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit`.
- URLProtocol-based networking doubles and protocol-based service injection are used to test `StressMonitor/StressMonitor/Services/API/` and auth/store services.
- The repo-root `StressMonitorTests/` directory is orphaned and is not part of `StressMonitor/StressMonitor.xcodeproj`; do not add tests there.

**Build/Dev:**
- Xcode/xcodebuild - builds the `StressMonitor`, `StressMonitorWatch Watch App`, and `StressMonitorWidgetExtension` targets from `StressMonitor/StressMonitor.xcodeproj`.
- SwiftLint - style and safety checking configured in `.swiftlint.yml`; CI invokes it advisory-only in `.github/workflows/_test.yml`.
- Fastlane 2.236.x - signing, archiving, TestFlight upload/distribution, and App Store metadata in `fastlane/Fastfile`.
- xcpretty 0.4.x - xcodebuild output formatting in `Gemfile` and `.github/workflows/_test.yml`.
- VitePress 1.6.3 - product documentation site in `docs-site/`, deployed with configuration in `docs-site/vercel.json`.

## Key Dependencies

**Critical:**
- FirebaseCore 11.15.0 - application Firebase bootstrap in `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`.
- FirebaseAuth 11.15.0 - anonymous identity, Google credential exchange, and backend ID tokens in `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`.
- GoogleSignIn 9.2.0 - interactive Google authentication bridged into Firebase Auth in `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`.
- Foundation URLSession - JSON REST and server-sent event transport in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` and parsing in `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`.

**Infrastructure:**
- Apple Security framework - legacy/local Keychain operations in `StressMonitor/StressMonitor/Services/KeychainService.swift`.
- BackgroundTasks and UserNotifications - background refresh scheduling and notifications in `StressMonitor/StressMonitor/Services/Background/`.
- CoreMotion - walking activity measurement in `StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkViewModel.swift`.
- os/OSLog - structured logs and launch/calculation signposts in `StressMonitor/StressMonitor/StressMonitorApp.swift`, `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`, and `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`.

## Configuration

**Environment:**
- Backend URL precedence is Info.plist `STRESS_API_BASE_URL`, process environment `STRESS_API_BASE_URL`, UserDefaults `stressAPIBaseURL`, then `https://stress-api.dropitx.site`; preserve this resolution order in `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`.
- Firebase client configuration is supplied by the committed `StressMonitor/StressMonitor/GoogleService-Info.plist`; note its presence but do not copy credential-like values into documentation or source.
- StoreKit product identifiers and subscription group are generated Info.plist keys in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` and consumed through `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`.
- App Store Connect, Match, Slack, and identifier overrides are provided as CI environment variables to lanes in `fastlane/Fastfile` and `.github/workflows/deploy.yml`.
- App, watch, and widget share App Group `group.stress.ai.com`; app and watch use CloudKit container `iCloud.stress.ai.com`, declared in their `.entitlements` files.

**Build:**
- Xcode project: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- Swift package lock: `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- Lint: `.swiftlint.yml`.
- StoreKit test catalog: `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit`.
- CI/release: `.github/workflows/_test.yml`, `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, `.github/workflows/distribute.yml`, and `.github/workflows/release.yml`.
- Delivery: `Gemfile` and `fastlane/Fastfile`.
- Documentation build: `docs-site/package.json` and `docs-site/vercel.json`.

## Platform Requirements

**Development:**
- Use Xcode 26.3 for CI parity and run commands from the repository root with `-project StressMonitor/StressMonitor.xcodeproj`.
- Use an iOS simulator compatible with deployment target 18.6; CI tests an iPhone 16 with latest installed iOS and disables parallel testing in `.github/workflows/_test.yml`.
- Use a watchOS 11.6-or-newer runtime to build the shared `StressMonitorWatch Watch App` scheme.
- HealthKit supplies no real simulator data; use the `-demo-mode` launch argument to exercise the actual stress pipeline.
- Use Ruby 3.3 and Bundler for release lanes, Node/npm for `docs-site/`, and Python 3 for `scripts/run-tests.py`.

**Production:**
- App Store bundles are `stress.ai.com`, `stress.ai.com.watchkitapp`, and `stress.ai.com.widget`, configured in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- Release archives include the iOS app, watch app, and widget extension and are signed through Match/App Store profiles in `fastlane/Fastfile`.
- TestFlight and App Store Connect are the mobile distribution targets; Vercel hosts the static documentation site configured by `docs-site/vercel.json`.

---

*Stack analysis: 2026-09-01*

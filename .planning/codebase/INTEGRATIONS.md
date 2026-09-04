# External Integrations

**Analysis Date:** 2026-09-01

## APIs & External Services

**Stress AI Backend:**
- Standalone HTTPS backend - AI chat streaming, chat sessions/history, credit balance/redemption, premium verification, user coach preferences, quick actions, account-data deletion, and health checks.
  - SDK/Client: Foundation `URLSession` through `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` and endpoint extensions in `StressMonitor/StressMonitor/Services/API/`.
  - Base URL: `STRESS_API_BASE_URL` via Info.plist or process environment, with UserDefaults override `stressAPIBaseURL` and production fallback in `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`.
  - Auth: Firebase ID token sent as `Authorization: Bearer ...`, obtained through `StressMonitor/StressMonitor/Services/Auth/AuthServiceProtocol.swift`.
  - Streaming: `POST /chat` returns `text/event-stream`; consumption and parsing live in `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift` and `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`.
  - REST endpoints: public `GET /health`; authenticated `/chat`, `/sessions`, `/sessions/{id}/messages`, `/credits`, `/credits/redeem`, `/credits/premium/verify`, `/preferences`, `/quick-actions`, and the server-wipe path implemented by `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`.

**Apple Health:**
- HealthKit - read-oriented source for HRV, heart rate, sleep, activity, and recovery inputs in `StressMonitor/StressMonitor/Services/HealthKit/`; authorization entitlement is in `StressMonitor/StressMonitor/StressMonitor.entitlements`.
  - SDK/Client: Apple HealthKit framework via `HKHealthStore` in `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift`.
  - Auth: user-granted HealthKit authorization; usage descriptions are generated from `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- watchOS HealthKit - live watch measurements in `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift`.
  - SDK/Client: Apple HealthKit framework.
  - Auth: watch HealthKit entitlement in `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements`.

**Apple Commerce:**
- App Store / StoreKit 2 - weekly, monthly, and annual premium subscriptions plus small and large credit packs.
  - SDK/Client: StoreKit framework in `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`.
  - Configuration: product and subscription-group Info.plist keys in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`, resolved by `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`.
  - Server verification: signed transaction JWS is posted to `/credits/redeem` or `/credits/premium/verify` by `StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift`.

**Device Ecosystem:**
- WatchConnectivity - phone/watch state transfer between `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` and `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift`.
- WidgetKit/AppIntents - widgets, controls, live activity, and complication reloads under `StressMonitor/StressMonitorWidget/` and `StressMonitor/StressMonitorWatch Watch App/Complications/`.
- BackgroundTasks/UserNotifications - scheduled refresh and local notifications under `StressMonitor/StressMonitor/Services/Background/`; no third-party push provider is detected.

## Data Storage

**Databases:**
- SwiftData local persistent store - primary on-device app models are registered in the `ModelContainer` built by `StressMonitor/StressMonitor/StressMonitorApp.swift`; repository access is encapsulated by `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`.
  - Connection: application sandbox managed by SwiftData; no connection env var.
  - Client: Apple SwiftData `ModelContainer`/`ModelContext`.
- CloudKit private database - syncs stress measurements through `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift` and `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift`.
  - Connection: iCloud container `iCloud.stress.ai.com` from `StressMonitor/StressMonitor/StressMonitor.entitlements`.
  - Client: Apple CloudKit `CKContainer.default().privateCloudDatabase`.
- Watch CloudKit private database - watch-side record persistence/sync in `StressMonitor/StressMonitorWatch Watch App/Services/CloudKit/WatchCloudKitManager.swift`.
  - Connection: iCloud container `iCloud.stress.ai.com` from the watch entitlements file.
  - Client: Apple CloudKit.
- Backend-owned storage - the mobile repository contains only API contracts for sessions, messages, credits, preferences, and account deletion in `StressMonitor/StressMonitor/Services/API/`; backend database technology and connection settings are not present in this repository.

**File Storage:**
- Application sandbox only for the SwiftData store and generated/exported local artifacts; character export code is in `StressMonitor/StressMonitor/Services/CharacterIllustrationExporter.swift`.
- Shared App Group defaults use `group.stress.ai.com` for widget/complication snapshots in `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`, `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift`, and `StressMonitor/StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift`.
- No third-party object/file storage SDK is detected.

**Caching:**
- UserDefaults is used for lightweight preferences, backend URL override, and shared widget/watch snapshots; key locations include `StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift` and `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`.
- Keychain is used for legacy/local sensitive values through Apple Security APIs in `StressMonitor/StressMonitor/Services/KeychainService.swift`; Firebase SDK manages current authentication state.
- No Redis, Memcached, or third-party cache is detected.

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication with anonymous and Google sign-in flows.
  - Implementation: bootstrap Firebase once through `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`, then authenticate through `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`.
  - Firebase products linked: `FirebaseCore` and `FirebaseAuth` in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
  - Google SDK: `GoogleSignIn` 9.2.0, resolved in `StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
  - Client configuration: `StressMonitor/StressMonitor/GoogleService-Info.plist` is present; do not duplicate its credential-like contents.
  - Backend trust boundary: every endpoint except `/health` receives a Firebase ID token, and backend verification is described at the request builder in `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift`.
  - Sign-out/data cleanup: `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift` clears Firebase state and legacy Keychain tokens; consolidated deletion is coordinated by `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`.

## Monitoring & Observability

**Error Tracking:**
- No Sentry, Crashlytics, or other third-party crash/error SDK is linked in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.

**Logs:**
- Apple unified logging through `Logger`, `OSLog`, and `os_signpost` in `StressMonitor/StressMonitor/StressMonitorApp.swift`, `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`, `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`, and `StressMonitor/StressMonitor/Services/DataManagement/DataManagementUtilities.swift`.
- Fastlane reports are retained as GitHub Actions artifacts by `.github/workflows/deploy.yml`; failed test raw logs and `.xcresult` bundles are retained by `.github/workflows/_test.yml`.
- Fastlane optionally sends deployment status to Slack from `fastlane/Fastfile` using `SLACK_WEBHOOK_URL`.

## CI/CD & Deployment

**Hosting:**
- Apple App Store Connect/TestFlight - iOS, watchOS, and widget archive/upload flows in `fastlane/Fastfile`.
- Vercel - static VitePress documentation output from `docs-site/.vitepress/dist`, configured in `docs-site/vercel.json`.
- Backend hosting is external to this repository; only the fallback host `https://stress-api.dropitx.site` is defined in `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`.

**CI Pipeline:**
- GitHub Actions - `.github/workflows/ci.yml` invokes `.github/workflows/_test.yml` for SwiftLint, iOS/watchOS/widget builds, and XCTest.
- `.github/workflows/deploy.yml` runs after successful CI on `main` and `release/*` and calls `bundle exec fastlane upload_beta`.
- `.github/workflows/distribute.yml` and `.github/workflows/release.yml` provide manual TestFlight distribution and App Store release flows.
- Fastlane Match stores App Store signing material in an external Git repository configured by `MATCH_GIT_URL`; `fastlane/Matchfile` defines the three bundle identifiers and CI uses readonly synchronization.

## Environment Configuration

**Required env vars:**
- Runtime override: `STRESS_API_BASE_URL`, optional because `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift` has a production fallback.
- App Store Connect: `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and either `APP_STORE_CONNECT_API_KEY_P8` or `APP_STORE_CONNECT_API_KEY_PATH`, consumed by `fastlane/Fastfile`.
- Signing: `MATCH_PASSWORD`, `MATCH_GIT_URL`, and CI auth such as `MATCH_GIT_BASIC_AUTHORIZATION`, supplied in `.github/workflows/deploy.yml`.
- Release identity overrides: `APP_IDENTIFIER`, `WATCH_APP_IDENTIFIER`, and `WIDGET_APP_IDENTIFIER`, with defaults in `fastlane/Fastfile`.
- Optional delivery: `TESTFLIGHT_GROUPS` and `SLACK_WEBHOOK_URL`, consumed by `fastlane/Fastfile`.
- App Store account metadata used by Fastlane configuration: `APPLE_ID`, `ITC_TEAM_ID`, and `TEAM_ID` in `fastlane/Appfile`.

**Secrets location:**
- GitHub Actions environment/repository secrets are referenced by `.github/workflows/deploy.yml`; values are not stored in workflow source.
- Local Fastlane may read an App Store Connect private key path configured by `APP_STORE_CONNECT_API_KEY_PATH`; private key files must remain outside tracked source.
- Firebase client config exists at `StressMonitor/StressMonitor/GoogleService-Info.plist`; treat it as configuration and never quote values into generated documents.
- Environment files, credential files, private keys, and package registry auth files are not read or documented.

## Webhooks & Callbacks

**Incoming:**
- Google Sign-In redirects back into the iOS application through the GoogleSignIn SDK and app URL configuration associated with `StressMonitor/StressMonitor/GoogleService-Info.plist`; the flow entry is `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`.
- No server-to-app HTTP webhook endpoint is present; this is a native client and does not host an HTTP server.
- App Store server notifications are not handled in this repository; signed StoreKit transactions are sent outbound to the Stress backend by `StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift`.

**Outgoing:**
- Slack deployment notifications are posted by `slack_notify` in `fastlane/Fastfile` when `SLACK_WEBHOOK_URL` is configured.
- Firebase bearer-authenticated HTTPS requests and SSE streams are sent by `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` and its endpoint extensions.
- StoreKit signed transaction JWS payloads are sent to backend redemption/verification endpoints by `StressMonitor/StressMonitor/Services/API/StressAPIClient+Credits.swift`.
- CloudKit record operations are sent through Apple APIs from `StressMonitor/StressMonitor/Services/CloudKit/` and `StressMonitor/StressMonitorWatch Watch App/Services/CloudKit/`.
- App Store Connect/TestFlight API calls and uploads are issued by Fastlane lanes in `fastlane/Fastfile`.

---

*Integration audit: 2026-09-01*

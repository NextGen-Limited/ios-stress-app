# External Integrations

**Analysis Date:** 2026-08-29

## APIs & External Services

**Backend API (standalone StressMonitor backend):**
- `https://stress-api.dropitx.site` (fallback) — chat/LLM streaming, credits, sessions, preferences, quick actions
  - SDK/Client: hand-rolled `URLSession` client, no third-party HTTP lib — `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` + endpoint-group extensions (`+Credits.swift`, `+Preferences.swift`, `+QuickActions.swift`, `+Sessions.swift`)
  - Auth: `Authorization: Bearer <Firebase ID token>` on every endpoint except `GET /health` (token fetched per-request via `AuthServiceProtocol.getIDToken()`)
  - Base URL resolution (`StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`): Info.plist `STRESS_API_BASE_URL` → env var → `UserDefaults` key `stressAPIBaseURL` → fallback. Testable via `StressAPIConfig.resolveBaseURL(...)` seam (D-03)

**Endpoints (all relative to base URL):**

| Endpoint | Method | Purpose | File |
|---|---|---|---|
| `/health` | GET | Liveness probe, no auth | `StressAPIClient.swift:80` |
| `/chat` | POST | SSE streaming chat (OpenAI-compatible chunks) | `StressAPIClient.swift:94` |
| `/credits` | GET | Credit balance | `StressAPIClient+Credits.swift:33` |
| `/credits/redeem` | POST | Redeem credit-pack purchase (JWS body) | `StressAPIClient+Credits.swift:53` |
| `/credits/premium/verify` | POST | Verify premium subscription (JWS body) | `StressAPIClient+Credits.swift:60` |
| `/preferences` | GET / PUT | User preferences sync | `StressAPIClient+Preferences.swift:36,57` |
| `/quick-actions` | GET | Server-defined chat quick actions (query via `URLComponents`) | `StressAPIClient+QuickActions.swift:43` |
| `/sessions` | GET / POST | List (with `?limit=`) / create chat sessions | `StressAPIClient+Sessions.swift:38,85` |
| `/sessions/{uuid}` | DELETE | Delete a session | `StressAPIClient+Sessions.swift:108` |
| `/sessions/{uuid}/messages` | GET | Fetch session message history | `StressAPIClient+Sessions.swift:139` |

**SSE streaming pipeline:**
- `StressAPIClient.sendChat(...)` returns `(URLSession.AsyncBytes, HTTPURLResponse)`; line consumption lives in `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift`
- `SSEParser.parse(line:)` (`StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`) decodes OpenAI-compatible `data: {...}` lines into `.content` tokens or `.metadata(SSEMetadata)` (credits/session state) and handles the stream-end sentinel
- Chat context assembled by `ChatContextBuilder.swift` / `StressContextPayload.swift` before the request

**Firebase (Auth only):**
- Firebase project `stress-io`; config committed at `StressMonitor/StressMonitor/GoogleService-Info.plist` (analytics/GCM/ads flags off in plist, sign-in on)
- SDK: `FirebaseAuth` + `FirebaseCore` (SPM, firebase-ios-sdk >= 11.0.0)
- Bootstrap: `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift` — single `FirebaseApp.configure()` entry point, guards double-configure trap
- Client: `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift` — `signInAnonymously()`, `signInWithGoogle(presenting:)` (links Google credential to anonymous user; falls back to plain `signIn(with:)` on `credentialAlreadyInUse`)

**Google Sign-In:**
- SDK: `GoogleSignIn` (SPM, GoogleSignIn-iOS >= 9.0.0, transitive `AppAuth-iOS` 2.1.0)
- `GIDSignIn` requires a UIKit presenter — bridged in `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:436`; user-cancellation detection in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift:39` (`com.google.GIDSignIn` code -5)
- URL scheme registered in `StressMonitor/StressMonitor/Info.plist` (`com.googleusercontent.apps.595426793312-...`)

## Data Storage

**Databases:**
- SwiftData (on-device primary store)
  - Connection: `ModelContainer` with recovery path (delete incompatible store → local-only container → in-memory last resort) — `StressMonitor/StressMonitor/StressMonitorApp.swift:92-141`
  - Entities: `@Model` types in `StressMonitor/StressMonitor/Models/` (`StressMeasurement.swift`, `Habit.swift`, `Character/CharacterUnlock.swift`), repository layer at `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
- CloudKit (sync/backup)
  - Container `iCloud.stress.ai.com`, entitlement `com.apple.developer.icloud-services = CloudKit`
  - Client: `CKContainer` wrapper `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift`, sync engine `CloudKitSyncEngine.swift`, schema mirror `CloudKitSchema.swift`, conflict handling `StressMonitor/StressMonitor/Services/Sync/ConflictResolver.swift` + `SyncManager.swift`

**File Storage:**
- Local app container + asset catalogs only; no remote file storage (Firebase Storage bucket exists in config plist but is not used by app code)

**Caching:**
- App Group `group.stress.ai.com` — `UserDefaults(suiteName:)` shared app↔widget, `StressMonitor/StressMonitor/Models/WidgetSharedData.swift:100,133`
- No explicit HTTP cache service

## Authentication & Identity

**Auth Provider:**
- Firebase Auth (`stress-io` project)
  - Implementation: anonymous sign-in on first run; optional Google Sign-In upgrade that links the Google credential to the existing anonymous user so credit balance survives (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:49-121`)
  - ID tokens injected as Bearer headers by `StressAPIClient.authorizedRequest(...)` (`StressAPIClient.swift:38-65`)
  - Token/credential storage: Keychain via `StressMonitor/StressMonitor/Services/KeychainService.swift`

## Monitoring & Observability

**Error Tracking:**
- None (no Crashlytics/Sentry). Firebase plist has analytics disabled.

**Logs:**
- `os.Logger` subsystem-scoped logging (e.g. `persistenceLogger` in `StressMonitor/StressMonitor/StressMonitorApp.swift`); no remote log shipping

## CI/CD & Deployment

**Hosting:**
- App Store / TestFlight (fastlane `upload_beta`); backend hosted externally at `stress-api.dropitx.site` (not in this repo)

**CI Pipeline:**
- GitHub Actions, repo root `.github/workflows/`
  - `ci.yml` → calls `_test.yml`: SwiftLint (advisory) + iOS/watchOS/widget builds + unit tests; Xcode 26.3 on macos-15; destination `platform=iOS Simulator,name=iPhone 16,OS=latest`; `-parallel-testing-enabled NO`; sets `TEST_RUNNER_GSD_CI` to skip `DataDeletionConsolidationTests` on CI
  - `deploy.yml`: on CI success for `main`/`release/*` → fastlane `upload_beta` (TestFlight)
  - `distribute.yml`, `release.yml`: manual dispatch lanes; `match.yml`: cert management; `droid-wiki-refresh.yml`: docs tooling
- Xcode Cloud hooks present (`ci_scripts/ci_post_clone.sh`, `ci_post_xcodebuild.sh`) — not the primary CI path
- Optional Slack notify via `SLACK_WEBHOOK_URL` (`fastlane/Fastfile:301-313`)

## Environment Configuration

**Required env vars (CI/deploy, all from GitHub Actions secrets):**
- `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (or local `~/.appstoreconnect/AuthKey.p8` via `APP_STORE_CONNECT_API_KEY_PATH`)
- `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION` — code signing (CI always `readonly`)
- `SLACK_WEBHOOK_URL` (optional)
- App identifier overrides: `APP_IDENTIFIER`, `WATCH_APP_IDENTIFIER`, `WIDGET_APP_IDENTIFIER`; `TESTFLIGHT_GROUPS`

**Runtime app config:**
- `STRESS_API_BASE_URL` (optional; Info.plist build setting / env / `UserDefaults` "stressAPIBaseURL" / fallback)
- StoreKit product IDs via Info.plist keys: `com.stressmonitor.app.premium.weekly|monthly|annual`, `com.stressmonitor.app.credits.small|large`, group `SMPREMIUM01`

**Secrets location:**
- GitHub Actions secrets (CI); `~/.appstoreconnect/` (local fastlane); Match git repo (certs). No `.env` files in repo.

## Apple Ecosystem Integrations

**HealthKit (read-only):**
- Client: `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` (+ `+SleepFetch`, `+ActivityFetch`, `+RecoveryFetch`)
- Read types: HRV SDNN, heart rate, resting heart rate, step count, active energy, apple stand time, respiratory rate, oxygen saturation, sleep, workouts (`HealthKitManager.swift:9-34`)
- Simulator stand-in: `SimulatorHealthKitService.swift` + `-demo-mode` launch arg
- Watch-side reader: `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift`
- Usage strings via `INFOPLIST_KEY_NSHealth*UsageDescription` in pbxproj; entitlement `com.apple.developer.healthkit`

**StoreKit 2 (IAP):**
- Client: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`; product IDs resolved from Info.plist via `StoreKitProductCatalog.swift`
- Purchases verified server-side: JWS transaction posted to `/credits/redeem` and `/credits/premium/verify` — the backend is the source of truth for credit balance
- Test fixture: `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` + `StoreKitTestSessionProvider.swift`; `MockStoreKitService.swift` for previews

**WatchConnectivity:**
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` — phone↔watch data transfer; watch duplicates stress-algorithm sources locally (`MultiFactorStressCalculator`, `*StressFactor.swift`)

**WidgetKit / AppIntents / ActivityKit:**
- `StressMonitor/StressMonitorWidget/` — timeline widgets, controls, Live Activity; data shared through app group `group.stress.ai.com`

**UserNotifications (local only):**
- `StressMonitor/StressMonitor/Services/Background/NotificationManager.swift`; no push/APNs entitlement detected

## Webhooks & Callbacks

**Incoming:**
- None (Google Sign-In URL callback scheme only: `com.googleusercontent.apps.595426793312-...`)

**Outgoing:**
- None (optional Slack webhook is CI-side, not app-side)

---

*Integration audit: 2026-08-29*

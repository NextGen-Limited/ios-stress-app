# External Integrations

**Analysis Date:** 2026-08-29

## APIs & External Services

**Backend API (standalone StressMonitor backend):**
- `https://stress-api.dropitx.site` (fallback) — chat/LLM streaming, credits, sessions, preferences, quick actions
  - SDK/Client: hand-rolled `URLSession` client, no third-party HTTP lib — `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` + endpoint-group extensions (`+Credits.swift`, `+Preferences.swift`, `+QuickActions.swift`, `+Sessions.swift`)
  - Auth: `Authorization: Bearer <Firebase ID token>` on every endpoint except `GET /health` (token fetched per-request via `AuthServiceProtocol.getIDToken()`, force-refreshed within 60s of expiry — `FirebaseAuthService` `tokenRefreshMargin`)
  - Base URL resolution (`StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift`): Info.plist `STRESS_API_BASE_URL` → env var → `UserDefaults` key `stressAPIBaseURL` → fallback. No override key is currently shipped, so the fallback governs. Testable via `StressAPIConfig.resolveBaseURL(...)` seam (D-03)
  - Request building: `authorizedRequest(path:)` for plain paths, `authorizedRequest(url:)` for query-string URLs built with `URLComponents` (`appendingPathComponent` percent-encodes `?`)

**Endpoints (all relative to base URL):**

| Endpoint | Method | Purpose | File |
|---|---|---|---|
| `/health` | GET | Liveness probe, no auth (true only on HTTP 200) | `StressAPIClient.swift` |
| `/chat` | POST | SSE streaming chat (OpenAI-compatible chunks) | `StressAPIClient.swift` |
| `/credits` | GET | Credit balance | `StressAPIClient+Credits.swift:32` |
| `/credits/redeem` | POST | Redeem credit-pack purchase (JWS body) | `StressAPIClient+Credits.swift:52` |
| `/credits/premium/verify` | POST | Verify premium subscription (JWS body) | `StressAPIClient+Credits.swift:60` |
| `/preferences` | GET / PUT | User preferences sync (language, coaching style) | `StressAPIClient+Preferences.swift:35,55` |
| `/quick-actions` | GET | Server-defined chat quick actions (query via `URLComponents`) | `StressAPIClient+QuickActions.swift:38` |
| `/sessions` | GET / POST | List (`?limit=&offset=`) / create chat sessions | `StressAPIClient+Sessions.swift:37,70` |
| `/sessions/{uuid}` | DELETE | Delete a session | `StressAPIClient+Sessions.swift:107` |
| `/sessions/{uuid}/messages` | GET | Fetch session message history | `StressAPIClient+Sessions.swift:137` |

**SSE streaming pipeline:**
- `StressAPIClient.sendChat(...)` returns `(URLSession.AsyncBytes, HTTPURLResponse)`; line consumption lives in `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift`
- Session creation strictly precedes `/chat` — a chat without `session_id` makes the backend auto-create an untitled twin session; failed title creation fails soft with nil id (`StressLLMService.swift:65-77`)
- `SSEParser.parse(line:)` (`StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`) decodes OpenAI-compatible `data: {...}` lines into `.content` tokens, `.metadata(SSEMetadata)` (`session_id`, `credits_remaining`, `model_used`), `.done`, or `.error`
- HTTP status mapping (`StressLLMService.mapHTTPError`, D-07): 402 → `LLMServiceError.insufficientCredits`, others → error before stream consumption (`StressLLMService.swift:173-177`)
- Terminal metadata converges credit display via the `onCreditsRemainingChange` sink — the chat path updates the display-only balance cache without depending on `CreditService`
- Chat context assembled by `ChatContextBuilder.swift` / `StressContextPayload.swift` before the request

**Client-side service wrappers over the API:**
- `StressMonitor/StressMonitor/Services/Credits/CreditService.swift` — display-only balance cache; backend is the sole authority, state only converges from server responses (never client arithmetic; premium unlimited is a server sentinel)
- `StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift` — language + coaching style with seed-once hydration (`seedIfNeeded()`, silent GET failure) and optimistic revert-on-failure PUT
- `StressMonitor/StressMonitor/Services/Chat/ChatAvailability.swift` — single source of truth for AI Coaching reachability; currently `.enabled` in every config (v1.1)

**Firebase (Auth only):**
- Firebase project `stress-io`; config file `StressMonitor/StressMonitor/GoogleService-Info.plist` is **gitignored** (`.gitignore:174`) — must be restored locally; CI builds currently ship without it (provisioning script `ci_scripts/provision_firebase_config.sh` + `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret are planned, not implemented)
- SDK: `FirebaseAuth` + `FirebaseCore` (SPM, firebase-ios-sdk 11.15.0 resolved)
- Bootstrap: `StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift` — single `FirebaseApp.configure()` entry point, inspectable `State` (`.configured` / `.missingConfiguration`), guards the double-configure trap, logs `.fault` on missing config, never traps; `StressMonitorApp.init` starts anonymous sign-in only when `.configured` (`StressMonitor/StressMonitor/StressMonitorApp.swift:189`)
- Client: `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift` — `signInAnonymously()`, `signInWithGoogle(presenting:)` (links Google credential to anonymous user so credit balance survives; falls back to plain `signIn(with:)` on `credentialAlreadyInUse`); `static clearStoredCredentials()` wipes legacy Keychain accounts + UserDefaults keys from the pre-v1.1 LLM stack
- Errors: `StressMonitor/StressMonitor/Services/Auth/AuthServiceError.swift` — `notConfigured`, `notSignedIn`, `googleSignInFailed(underlying:)`; auth failures no longer masquerade as `LLMServiceError.unavailable` ("AI is not available")

**Google Sign-In:**
- SDK: `GoogleSignIn` (SPM, GoogleSignIn-iOS 9.2.0 resolved, transitive `AppAuth-iOS` 2.1.0 + `GTMAppAuth` 5.0.0)
- `GIDSignIn` requires a UIKit presenter — bridged in `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift:436-450`; user-cancellation detection in `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift:42` (`com.google.GIDSignIn` domain, code -5)
- URL scheme registered in `StressMonitor/StressMonitor/Info.plist` (`com.googleusercontent.apps.595426793312-...`)

## Data Storage

**Databases:**
- SwiftData (on-device primary store)
  - Connection: `ModelContainer` with 3-stage recovery (delete incompatible store → local-only container → in-memory last resort) — `StressMonitor/StressMonitor/StressMonitorApp.swift:92-141`
  - Entities: `@Model` types in `StressMonitor/StressMonitor/Models/` (`StressMeasurement.swift`, `Habit.swift`, `Character/CharacterUnlock.swift`), repository layer at `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
- CloudKit (sync/backup)
  - Container `iCloud.stress.ai.com`, entitlement `com.apple.developer.icloud-services = CloudKit`
  - Client: `CKContainer` wrapper `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift`, sync engine `CloudKitSyncEngine.swift`, schema mirror `CloudKitSchema.swift`, conflict handling `StressMonitor/StressMonitor/Services/Sync/ConflictResolver.swift` + `SyncManager.swift`
- Server-side (backend, not in this repo): credits ledger, chat sessions/messages, preferences — client caches never write back authoritatively

**File Storage:**
- Local app container + asset catalogs only; no remote file storage (Firebase Storage bucket exists in the config plist but is not used by app code)

**Caching:**
- App Group `group.stress.ai.com` — `UserDefaults(suiteName:)` shared app↔widget, `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`
- Chat session id persisted in `UserDefaults` key `stressChatSessionId` (`StressLLMService`); Firebase token cache owned by the Firebase SDK
- No explicit HTTP cache service

## Authentication & Identity

**Auth Provider:**
- Firebase Auth (`stress-io` project)
  - Implementation: anonymous sign-in on first run; optional Google Sign-In upgrade that links the Google credential to the existing anonymous user so credit balance survives (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`)
  - ID tokens injected as Bearer headers by `StressAPIClient.authorizedRequest(...)`; backend verifies via Firebase Admin `verifyIdToken`
  - Legacy credential storage: `StressMonitor/StressMonitor/Services/KeychainService.swift` (generic Keychain save/retrieve/delete) — now used only to wipe leftovers from the pre-migration LLM stack

## Monitoring & Observability

**Error Tracking:**
- None (no Crashlytics/Sentry). Firebase plist has analytics disabled.

**Logs:**
- `os.Logger` subsystem-scoped logging (subsystem `com.stressmonitor.app`, e.g. `FirebaseBootstrap`, `persistenceLogger` in `StressMonitorApp.swift`); missing-Firebase-config emits a `.fault` naming the missing resource; no remote log shipping

## CI/CD & Deployment

**Hosting:**
- App Store / TestFlight (fastlane `upload_beta`); backend hosted externally at `stress-api.dropitx.site` (not in this repo)

**CI Pipeline:**
- GitHub Actions, repo root `.github/workflows/`
  - `ci.yml` (pull_request → main/develop + manual) → calls `_test.yml`: SwiftLint (advisory) + iOS/watchOS/widget builds + unit tests; Xcode 26.3 on macos-15; test destination `iPhone 16,OS=latest`; `-parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1`; DerivedData + SPM caches; unsigned builds (`CODE_SIGNING_REQUIRED=NO`); sets `TEST_RUNNER_GSD_CI=1` to disable the 2 host-restart-sensitive tests in `DataDeletionConsolidationTests.swift:238,375` on CI
  - `deploy.yml`: `workflow_run` on CI completion for `main`/`release/*` → fastlane `upload_beta` (TestFlight)
  - `distribute.yml`, `release.yml`, `match.yml`: manual-dispatch lanes; `droid-wiki-refresh.yml`: docs tooling
- Xcode Cloud hooks present (`ci_scripts/ci_post_clone.sh`, `ci_post_xcodebuild.sh`) — not the primary CI path
- Optional Slack notify via `SLACK_WEBHOOK_URL` (`fastlane/Fastfile:301-307`)
- Known CI/test caveats: 6 pre-existing failures (WINDOWS.md #8 lineage: `CloudKit Failure & Cancellation Ordering`, `Data Export Field Selection` — cold-launch host restarts, tests themselves pass); 15 skips from `CharacterEntitlementSyncTests` + StoreKit-config-dependent suites; `GoogleService-Info.plist` is not provisioned in CI yet (see `.planning/quick/260829-kby-*` deferred Tasks 1-2)

## Environment Configuration

**Required env vars (CI/deploy, all from GitHub Actions secrets):**
- `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8` (or local `~/.appstoreconnect/AuthKey.p8` via `APP_STORE_CONNECT_API_KEY_PATH`)
- `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION` — code signing (CI always `readonly`)
- `SLACK_WEBHOOK_URL` (optional)
- App identifier overrides: `APP_IDENTIFIER`, `WATCH_APP_IDENTIFIER`, `WIDGET_APP_IDENTIFIER`; `TESTFLIGHT_GROUPS`
- Planned (not yet created): `GOOGLE_SERVICE_INFO_PLIST_BASE64` — would let CI restore the gitignored Firebase config

**Runtime app config:**
- `STRESS_API_BASE_URL` (optional; Info.plist / env / `UserDefaults` "stressAPIBaseURL" / fallback — no key currently shipped)
- StoreKit product IDs via Info.plist keys: `com.stressmonitor.app.premium.weekly|monthly|annual`, `com.stressmonitor.app.credits.small|large`, group `SMPREMIUM01`

**Secrets location:**
- GitHub Actions secrets (CI); `~/.appstoreconnect/` (local fastlane); Match git repo (certs); gitignored `GoogleService-Info.plist` (local Firebase config). No `.env` files in repo.

## Apple Ecosystem Integrations

**HealthKit (read-only):**
- Client: `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` (+ `+SleepFetch`, `+ActivityFetch`, `+RecoveryFetch`)
- Read types: HRV SDNN, heart rate, resting heart rate, step count, active energy, apple stand time, respiratory rate, oxygen saturation, sleep, workouts
- Simulator stand-in: `SimulatorHealthKitService.swift` + `-demo-mode` launch arg
- Watch-side reader: `StressMonitor/StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift`
- Usage strings via `INFOPLIST_KEY_NSHealth*UsageDescription` in pbxproj; entitlement `com.apple.developer.healthkit`

**StoreKit 2 (IAP):**
- Client: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift`; product IDs resolved from Info.plist via `StoreKitProductCatalog.swift`; `StoreKitServiceEnvironment.swift` gates test/preview behavior
- Purchases verified server-side: Apple-signed JWS transaction posted to `/credits/redeem` and `/credits/premium/verify` — the backend is the source of truth for credit balance and premium entitlement
- Test fixture: `StressMonitor/StressMonitorTests/StressMonitorProducts.storekit` + `StoreKitTestSessionProvider.swift` (single shared `SKTestSession`; a second session detaches the process-wide daemon); `MockStoreKitService.swift` for previews

**WatchConnectivity:**
- `StressMonitor/StressMonitorWatch Watch App/Services/WatchConnectivityManager.swift` + `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` — phone↔watch data transfer; watch duplicates stress-algorithm sources locally (`MultiFactorStressCalculator`, `*StressFactor.swift`)

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

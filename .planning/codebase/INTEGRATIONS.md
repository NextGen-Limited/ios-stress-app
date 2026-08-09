# External Integrations

**Analysis Date:** 2026-08-08

## APIs & External Services

**Supabase Edge Functions (AI coaching backend):**
- Base URL: `SupabaseConfig.url` + `functions/v1`, defined in `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift`
  - Default project URL fallback: `https://sxlaxpnyadellgyvxofm.supabase.co`
  - Overridable via Info.plist key `SUPABASE_URL`, env `SUPABASE_URL`, or `UserDefaults["supabaseURL"]`
- Declared endpoints (`SupabaseConfig`):
  | Constant | Path | Wired up in code? |
  |----------|------|-------------------|
  | `healthURL` | `functions/v1/health` | Declared only |
  | `chatURL` | `functions/v1/chat` | Yes — `SupabaseLLMService.send` |
  | `sessionsURL` | `functions/v1/sessions` | Declared only |
  | `preferencesURL` | `functions/v1/preferences` | Declared only |
  | `creditsURL` | `functions/v1/credits` | Declared only |
  | `quickActionsURL` | `functions/v1/quick-actions` | Declared only (quick actions arrive via SSE metadata) |
- SDK/Client: none — hand-rolled `URLSession.bytes(for:)` streaming in `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift`
- Auth headers per request: `apikey: <anon key>`, `Authorization: Bearer <JWT>`, `Accept: text/event-stream`, `Content-Type: application/json`, 90s timeout

**`/chat` request contract** (`SupabaseLLMService.swift:95-120`):
```json
{ "messages": [{"role": "...", "content": "..."}],
  "session_id": "<uuid, optional>",
  "stress_context": { ...snake_case payload... } }
```
`stress_context` is built by `StressMonitor/StressMonitor/Services/LLM/ChatContextBuilder.swift` into `StressContextPayload` (`StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift`), whose `CodingKeys` already emit snake_case.

**SSE streaming contract** (`StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`):
- Only lines prefixed `data: ` are parsed
- `[DONE]` sentinel ends the stream
- OpenAI-shaped tokens: `choices[0].delta.content`
- Alternate gateway shape: `{"token": "..."}`
- Error shape: `{"error": "<message>"}`
- Non-standard terminal event: `{"type":"metadata","session_id":...,"credits_remaining":...,"model_used":...}` → applied by `SupabaseLLMService.apply(metadata:)`, which persists `session_id` to `UserDefaults` and updates `creditsRemaining` / `modelUsed`

**HTTP error mapping** (`SupabaseLLMService.mapHTTPError`):
| Status | Meaning surfaced to user |
|--------|--------------------------|
| 401 | "Please sign in to use AI Chat." |
| 402 | Out of credits (monthly reset) |
| 422 | Bad request body |
| 429 | Rate limited |
| 502 | Provider failure |

**Third-party service SDKs (via SPM):**
- Giphy iOS SDK 2.2.16 — GIF picker embedded in the `exyte/Chat` UI; requires a Giphy API key at the Chat layer
- Kingfisher 8.8.1 — arbitrary remote image fetching in chat/media views

## Data Storage

**Databases:**
- On-device: SwiftData (`@Model` types such as `StressMeasurement`, `CharacterUnlock`), container configured in `StressMonitor/StressMonitor/StressMonitorApp.swift`
- Server-side: Supabase Postgres, reached only indirectly through Edge Functions. The app never opens a direct Postgres/PostgREST connection.

**File Storage:**
- Local filesystem only — exports written by `StressMonitor/StressMonitor/Services/DataManagement/DataExporter.swift`, `CSVGenerator.swift`, `JSONGenerator.swift`

**Caching:**
- `UserDefaults` for chat session id, config overrides, and appearance state
- SPM dependency mirror under `StressMonitor/spm-cache/`

## Authentication & Identity

**Auth Provider:**
- Supabase Auth (JWT), consumed as a bearer token. There is **no Apple Sign-In implementation in this repo** — no `AuthenticationServices` / `ASAuthorization` usage was found.
- Token resolution (`SupabaseLLMService.init`, `SupabaseConfig.guestJWT`):
  1. Explicitly injected `accessToken`
  2. Keychain, via `StressMonitor/StressMonitor/Services/KeychainService.swift` (`kSecClassGenericPassword`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
  3. Fallback shared **guest JWT** from Info.plist `SUPABASE_GUEST_JWT` → env → `UserDefaults["supabaseGuestJWT"]` → `SupabaseSecrets.guestJWT`
- `SupabaseConfig.swift` carries an in-source TODO: replace the guest JWT with a real `SupabaseAuthService` (Apple Sign-In) before production.
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift` is gitignored (`.gitignore:164`) but is present in the working tree and contains an embedded long-lived dev JWT. Treat as a secret; do not commit or quote.

## Monitoring & Observability

**Error Tracking:**
- None. No Sentry/Crashlytics/analytics SDK is linked.

**Logs:**
- `os.log` / `Logger` (5 files) plus plain `print` in places. No remote log sink.

## CI/CD & Deployment

**Hosting:**
- App Store / TestFlight. Signing teams `EQ8B89SPCX` (default) and `K2TYLYAWMK` (per-SDK for `iphoneos*` / `watchos*`).
- Docs site: VitePress static build from `docs-site/`

**CI Pipeline:**
- GitHub Actions: `.github/workflows/ci.yml` (lint & build, calls reusable `_test.yml`), plus `deploy.yml`, `distribute.yml`, `release.yml`, `droid-wiki-refresh.yml`
- Xcode Cloud: `ci_scripts/ci_post_clone.sh` (Homebrew Fastlane install, `fastlane match appstore --readonly`), `ci_scripts/ci_post_xcodebuild.sh`
- Fastlane Match for certificates — `fastlane/Matchfile`, `fastlane/Appfile`, `fastlane/Fastfile`

## Cloud Sync (CloudKit)

- `CKContainer.default()` is used — no explicit container identifier string and **no CloudKit entitlement** is declared in either `.entitlements` file (they contain only `com.apple.developer.healthkit`).
  - `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift:23` — `init(container: CKContainer = .default())`
  - `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift:102` — writes to `privateCloudDatabase`
  - Schema definitions in `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSchema.swift`
  - Reset path: `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift`
- Merge/conflict handling: `StressMonitor/StressMonitor/Services/Sync/SyncManager.swift`, `ConflictResolver.swift`

## In-App Purchases (StoreKit 2)

- Product IDs are **not hardcoded** — resolved at runtime by `StressMonitor/StressMonitor/Services/StoreKit/StoreKitProductCatalog.swift`:
  | Period | Info.plist / env key | UserDefaults key |
  |--------|----------------------|------------------|
  | Weekly | `STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID` | `storeKitPremiumWeeklyProductID` |
  | Monthly | `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID` | `storeKitPremiumMonthlyProductID` |
  | Annual | `STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID` | `storeKitPremiumAnnualProductID` |
  | Group | `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID` | `storeKitPremiumSubscriptionGroupID` |
  Placeholder values (`$(...)`) and empty strings resolve to nil.
- Implementations: `StoreKitService.swift` (live), `MockStoreKitService.swift` (tests/previews), gating in `StressMonitor/StressMonitor/Services/Premium/PaywallController.swift`
- Tests: `StressMonitor/StressMonitorTests/StoreKitProductCatalogTests.swift`, `PremiumViewModelTests.swift`

## HealthKit Data Types Read

Declared in `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift:9-34` (read-only authorization set):
- `.heartRateVariabilitySDNN` (HRV — SDNN, not RMSSD)
- `.heartRate`
- `.restingHeartRate`
- `.stepCount`
- `.activeEnergyBurned`
- `.appleStandTime`
- `.respiratoryRate`
- `.oxygenSaturation`
- `HKCategoryType(.sleepAnalysis)`
- `HKObjectType.workoutType()`

Fetch extensions: `HealthKitManager+ActivityFetch.swift`, `HealthKitManager+RecoveryFetch.swift`, `HealthKitManager+SleepFetch.swift`. Simulator substitute: `SimulatorHealthKitService.swift` (`-demo-mode`).

Usage descriptions live in build settings, not Info.plist: `INFOPLIST_KEY_NSHealthShareUsageDescription`, `INFOPLIST_KEY_NSHealthUpdateUsageDescription`, `INFOPLIST_KEY_NSHealthClinicalHealthRecordsShareUsageDescription`, `INFOPLIST_KEY_NSCameraUsageDescription`.

## Device-to-Device Integration

**WatchConnectivity:**
- `StressMonitor/StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift` — `WCSession.default` delegate, activation, reachability, `didReceiveUserInfo` handling. Mirror service exists in the `StressMonitorWatch Watch App` target.

**Widgets / Live Activities:**
- `StressMonitor/StressMonitorWidget/` — `StressMonitorWidgetBundle.swift`, `StressMonitorWidget.swift`, `StressMonitorWidgetLiveActivity.swift`, `StressMonitorWidgetControl.swift`, `AppIntent.swift`
- Extension point `com.apple.widgetkit-extension` (`StressMonitor/StressMonitorWidget/Info.plist`)

**Background execution:**
- `INFOPLIST_KEY_UIBackgroundModes = "fetch processing"`; scheduling in `StressMonitor/StressMonitor/Services/Background/HealthBackgroundScheduler.swift`, alerts in `NotificationManager.swift`

## Environment Configuration

**Required config values:**
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_GUEST_JWT`
- `STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID`, `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID`, `STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID`, `STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID`
- CI only: `MATCH_PASSWORD`, `MATCH_GIT_URL` (Xcode Cloud env vars)

**Secrets location:**
- Runtime user secrets → Keychain (`KeychainService`)
- Build-time secrets → Info.plist build settings injected by CI, or Xcode Cloud environment variables
- Local dev fallback → gitignored `Services/LLM/SupabaseSecrets.swift`
- No `.env` files exist in the repo

## Webhooks & Callbacks

**Incoming:**
- None. The app exposes no URL scheme handlers or push-notification server callbacks (notifications are locally scheduled via `UserNotifications`).

**Outgoing:**
- Only the `POST functions/v1/chat` SSE call described above.

---

*Integration audit: 2026-08-08*

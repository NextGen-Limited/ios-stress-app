# Security

StressMonitor handles sensitive health data. The design is local-first, read-only for HealthKit, and uses CloudKit's end-to-end encryption for sync. No third-party analytics or tracking is present.

## Health data boundaries

- **Read-only HealthKit access**: the app never requests share/write authorization. `HealthKitManager.requestAuthorization()` passes `[] as Set<HKSampleType>` for `toShare`. The app cannot modify the user's Health store.
- **Local-first storage**: all measurements are written to SwiftData (encrypted at rest by iOS) before any CloudKit mirror attempt. The app remains fully functional offline.
- **CloudKit private database**: sync uses `CKContainer.default().privateDatabase`. Records are end-to-end encrypted by CloudKit and are not visible to anyone but the account owner, including Apple.
- **No raw health samples in chat**: the AI chat payload (`StressContextPayload`) carries summarized stress metrics, not raw HealthKit samples. The backend receives a stress level, category, and trend summary; it never sees individual HRV or HR readings.

## Secrets management

- **KeychainService** at `StressMonitor/StressMonitor/Services/KeychainService.swift` stores the Supabase access token using `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. The token is inaccessible when the device is locked and never migrates to new devices via backups.
- **`SupabaseSecrets.swift`** is gitignored and holds the guest JWT fallback only. The anon key resolves from Info.plist build settings, the process environment, or UserDefaults. The masked placeholder `*****` in `SupabaseConfig.anonKey` is intentional to avoid committing a real key.
- **No secrets in commits**: the convention is to never include API keys, JWTs, or credentials in commit messages or source. The guest JWT is the one exception and is time-limited (1-week expiration) and intended for pre-production testing only.

## Privacy manifest

`StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` declares the app's data practices:

- `NSPrivacyTracking`: false.
- `NSPrivacyTrackingDomains`: empty.
- Health and fitness data, photo/video data, and product interaction data are collected for app functionality only, not linked to the user's identity, and not used for tracking.

This manifest is required by Apple for App Store submission and must be kept in sync with the actual data practices of the app.

## Authentication

- The LLM backend expects a Supabase JWT. The current guest JWT fallback is a TODO item; production should use Apple Sign-In through a `SupabaseAuthService`. The JWT is stored in the Keychain and refreshed through `SupabaseLLMService.setAccessToken(_:)`.
- The Edge Function returns 401 when the token is missing or expired, and the app surfaces a "Please sign in to use AI Chat" error.

## Data deletion

Users can delete their data through Settings > Data Management. Three scopes are supported: single record, date range, and full wipe. Full wipe clears local SwiftData, resets the baseline, and calls `CloudKitResetService` to hard-delete records from the CloudKit private database. See [Data management](../systems/data-management.md).

## What the app does not do

- No third-party analytics SDKs.
- No advertising identifiers (IDFA).
- No tracking of any kind (per the privacy manifest).
- No background location tracking.
- No writes to HealthKit.
- No raw health sample upload to any server.

## Entry points for modification

- **Rotate the Supabase anon key**: change the Info.plist build setting or the `SUPABASE_ANON_KEY` environment variable. No source change required.
- **Replace the guest JWT with Apple Sign-In**: implement `SupabaseAuthService`, call `SupabaseLLMService.setAccessToken(_:)` after sign-in, and remove the guest JWT fallback in `SupabaseConfig.guestJWT`.
- **Add a new secret**: store it in the Keychain via `KeychainService`, never in `UserDefaults` or source. Update the privacy manifest if the data practice changes.

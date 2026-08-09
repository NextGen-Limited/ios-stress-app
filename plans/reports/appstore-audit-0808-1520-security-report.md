# Security & Privacy Audit — StressMonitor (App Store publish readiness)

**Date:** 2026-08-08
**Scope:** security + privacy dimension, App Store submission readiness
**Branch:** feature/spm-cache-integration
**Auditor:** axiom security-privacy-scanner

> Persisted by the orchestrator — the audit run had no Write tool available. This is the
> agent's compact summary; all findings were verified by direct file reads, not grep alone.
> Full per-finding prose for MEDIUM/LOW was not returned and can be regenerated on request.

## Verdict

**App Store readiness: NOT READY.** The invalid Privacy Manifest category alone is a likely
upload-time blocker (fails validation before review even begins).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH | 5 |
| MEDIUM | 4 |
| LOW | 2 |
| **Total** | **13** |

## CRITICAL

### 1. Invalid Privacy Manifest category

**File:** `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy:63-69`

Declares `NSPrivacyAccessedAPICategoryHealthKit`, which is **not** one of Apple's five real
Required-Reason API categories (UserDefaults / FileTimestamp / SystemBootTime / DiskSpace /
ActiveKeyboards). This schema value will likely fail Xcode / App Store Connect manifest
validation at upload.

### 2. Hardcoded production Supabase guest JWT with no build gate

**Files:**
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift:6-8` — embeds a real signed
  Supabase Auth JWT (test account), no `#if DEBUG` / Release gate
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift:28-36` — consumed as fallback
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:39` — assigned at init

Compiles into every configuration including Release archives; extractable via `strings` from the
shipped binary. The source comment itself flags "TODO: replace before production".

**Cross-confirmed** by the networking audit, which additionally found the token is **expired**
(issued ~2026-06-28, 7-day expiry, ~2026-07-05) — so it is both a leaked credential and a
functional break for every unauthenticated user. See
`appstore-audit-0808-1520-networking-report.md`.

## HIGH

### 3. Orphaned Info.plist silently drops usage descriptions

`project.pbxproj:604,655` points `INFOPLIST_FILE` at the empty
`StressMonitor/StressMonitor/Info.plist` (`<dict/>`), while `NSMicrophoneUsageDescription`,
`NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, and the ATS
local-networking exception live unused in the sibling orphan file
`StressMonitor/Info.plist:30-49`.

Crash-on-permission-prompt landmine once the already-resolved `exyte/MediaPicker` / Giphy SPM
packages (per `Package.resolved`) get wired into chat.

### 4. Missing App Group entitlement across all targets

None of `StressMonitor.entitlements`, `StressMonitorWatch Watch App.entitlements`, or the Widget
target declare `com.apple.security.application-groups`, yet code reads/writes shared containers:

- `group.com.stressmonitor.app` — `WidgetDataProvider.swift:10`, `WidgetSharedData.swift:100`
- `group.com.stressmonitor.watch` — `ComplicationDataProvider.swift:14`,
  `WatchFacePreferences.swift:15`, `CharacterCollectionViewModel.swift:86`

Silent broken data-sharing plus entitlement inconsistency.

### 5. Privacy nutrition-label under-declaration

Chat text and the `stress_context` payload (HRV / HR / sleep / activity / recovery) POSTed to
Supabase `/chat` (`SupabaseLLMService.swift:95-120`) are not represented as a "User Content"
collected data type in `PrivacyInfo.xcprivacy`. `NSPrivacyCollectedDataTypeHealthAndFitness` is
marked `Linked: false` despite being sent alongside an identity-linking Bearer JWT.

### 6. Unverified third-party SDK privacy manifests

`Package.resolved` resolves Giphy iOS SDK, Kingfisher, exyte/Chat, exyte/MediaPicker. No evidence
any ship a bundled `PrivacyInfo.xcprivacy`, risking Apple's 2024+ SDK signature/manifest rejection
— cited against the SDK, not your code.

### 7. CloudKit health-data sync isn't E2E encrypted as documented

`CloudKitManager.swift:49-57`, `CloudKitSyncEngine.swift:78-86`, `CloudKitSchema.swift:43-50`
write `hrv` / `restingHeartRate` / `stressLevel` via plain `record[key] =`, **not**
`CKRecord.encryptedValues`. This contradicts the "end-to-end encrypted" claim made for health data
in project documentation.

## MEDIUM

- Unconditional `os_log("%{public}@", ...)` in `DataManagementUtilities.swift:25` and
  `DataManagementViewModel.swift:455` logs export/delete metadata (file paths, record counts) with
  no privacy redaction.
- `NSHealthUpdateUsageDescription` declared (`project.pbxproj:611,662`) though HealthKit is
  requested read-only everywhere (`toShare: []`) — messaging inconsistency.
- No certificate pinning on the Supabase chat endpoint carrying Bearer JWT + health context
  (`SupabaseLLMService.swift` uses `URLSession.shared`).
- Debug-only config overrides (`supabaseAnonKey` / `supabaseGuestJWT` / `supabaseURL` via
  `UserDefaults.standard`) ship in all configurations with no `#if DEBUG` gate.

## LOW

- Duplicate/orphaned legacy source tree at `StressMonitor/Views`, `/Services`, `/Models` (outside
  the actual synced target folder) — dead code, not compiled, repo hygiene only.
- Nested `StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.pbxproj` — anomalous duplicate
  project file, informational.

## Unresolved Questions

1. Is the "CloudKit sync is end-to-end encrypted" claim in project docs a requirement to
   implement (`encryptedValues`), or documentation to correct?
2. Are the Giphy / exyte / Kingfisher packages intended to ship in this release, or are they
   resolved-but-unused dependencies that should be removed before submission?
3. Which App Group identifier is canonical — `group.com.stressmonitor.app` or
   `group.com.stressmonitor.watch`? Both are referenced, neither is entitled.

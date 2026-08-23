---
phase: 01-firebase-auth-api-client-chat-migration
reviewed: 2026-08-13T14:59:51Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - .gitignore
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - StressMonitor/StressMonitor/Info.plist
  - StressMonitor/StressMonitor/Models/ChatMessage.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift
  - StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift
  - StressMonitor/StressMonitor/Services/Chat/ChatAvailability.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
  - StressMonitor/StressMonitor/Services/LLM/LLMServiceProtocol.swift
  - StressMonitor/StressMonitor/Services/LLM/SSEParser.swift
  - StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift
  - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
  - StressMonitor/StressMonitor/StressMonitorApp.swift
  - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
  - StressMonitor/StressMonitorTests/FirebaseAuthServiceTests.swift
  - StressMonitor/StressMonitorTests/LLMServiceErrorTests.swift
  - StressMonitor/StressMonitorTests/SSEParserTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
  - StressMonitor/StressMonitorTests/StressAPIConfigTests.swift
findings:
  critical: 2
  warning: 7
  info: 2
  total: 11
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-08-13T14:59:51Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

This phase migrated the iOS app from Supabase to Firebase Anonymous auth + a standalone backend (`stress-api`). The migration scope is well-bounded: `StressAPIClient` injects Bearer tokens via `AuthServiceProtocol`, `StressLLMService` replaces `SupabaseLLMService`, `SSEParser` gained `quick_actions`, and legacy credential identifiers are correctly wiped in `clearStoredCredentials`. The `GoogleService-Info.plist` is properly gitignored (not tracked) and contains only the Firebase iOS API key, which is designed for client embedding.

The migration surface itself is clean. However, two correctness issues exist: (1) `StressLLMService.currentStressContext` is a `static var` mutated on `@MainActor` and read from a nonisolated `Task`, creating a data race and a stale-context bug; (2) `StressContextPayload.build` computes its trend over history sorted newest-first, which inverts the trend direction label. Additional warnings cover `URL(string:)!` force-unwrap, silent dropping of `stress_context` on encoding failure, fire-and-forget anonymous sign-in swallowing errors, and the `getHealth`/`sendChat` URL inconsistency.

---

## Critical Issues

### CR-01: `StressLLMService.currentStressContext` is a data race and silently serves stale context

**File:** `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift:119`, `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:119`
**Issue:** `currentStressContext` is declared as `static var currentStressContext: StressContextPayload?` on a `@MainActor`-isolated type. It is written on `@MainActor` (inside `ChatViewModel.streamResponse()` at ChatViewModel.swift:119) and read inside `StressLLMService.send` from a `_Concurrency.Task` that captures `Self` nonisolated and reads `Self.currentStressContext` at StressLLMService.swift:63. Because the read happens in a detached `Task` body (not guaranteed to execute on the main actor), this is an unsynchronized cross-actor read of a mutable `@MainActor` static — a Swift 6 data race. In practice under Swift 5 strict-concurrency-lite, this compiles only because `StressLLMService` is `@unchecked Sendable`, masking the hazard.

Beyond the race, the static is set once per `send()` and never cleared. If `send()` runs while no new `streamResponse()` has overwritten the value, the previous message's stress context is reused. Because `ChatBottomSheetView` is always constructed with `stressResult: nil, baseline: nil` at both call sites (SettingsView.swift:67, ActionView.swift:59), `currentStressContext` is always built from nil inputs and the backend always receives a stress context with null `stress_level`/`stress_category`. The static's lifetime outlives a single message, so any future caller that sets real data will leak it across messages until the next overwrite.
**Fix:** Pass the stress context through the `send(messages:systemPrompt:)` call chain instead of via a static side channel. Extend `LLMServiceProtocol.send` to accept `stressContext: StressContextPayload?`, or add a dedicated parameter and have `StressLLMService.send` capture it in the `Task` closure (it already captures `currentSessionId` via the capture list). Remove the `static var currentStressContext` entirely.

### CR-02: Trend direction is inverted because `recentHistory` is newest-first

**File:** `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:88-99`
**Issue:** `build` computes the trend from `recentHistory.suffix(...)` then compares `first` to `last`:
```swift
let recent = recentHistory.suffix(min(5, max(2, recentHistory.count)))
let levels = recent.map(\.stressLevel)
let first = levels.first!
let last = levels.last!
let diff = last - first
if abs(diff) < 5 { trend = "stable" }
else if diff > 0 { trend = "increasing" }
else { trend = "decreasing" }
```
`StressRepository.fetchRecent` returns measurements sorted newest-first (`SortDescriptor(\.timestamp, order: .reverse)` — StressRepository.swift:87). With that ordering, `suffix` keeps the most recent N entries but preserves their relative order, so `first` is the newest and `last` is the oldest. Therefore `diff = last - first = oldest - newest`. When stress actually *increased* over time (newest > oldest), `diff` is negative, and the code labels it "decreasing" — the exact opposite of reality. The backend builds its coaching prompt from this label, so guidance will be backwards. This was a pre-existing bug carried unchanged through the migration, but it now directly affects the new backend's system prompt construction, which is the central contract of this phase.
**Fix:** Reverse the array so chronological order is explicit before computing the delta, or compute `diff = first - last`:
```swift
let chronological = recent.reversed()
let levels = chronological.map(\.stressLevel)
let diff = (levels.last ?? 0) - (levels.first ?? 0)
```
Guard the `levels.first!`/`levels.last!` force-unwraps with the existing `recent.count >= 2` check — they are safe today, but only if the check remains directly above them.

---

## Warnings

### WR-01: `StressAPIConfig.resolveBaseURL` force-unwraps `URL(string:)!`

**File:** `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:38`
**Issue:** `return URL(string: resolved)!`. The fallback is guaranteed valid, but the Info.plist, environment, and UserDefaults tiers are user/operator-supplied. A typo in `STRESS_API_BASE_URL` (e.g. a trailing space, a missing scheme, a copy-paste with angle brackets) crashes the app at type-load time with no diagnostic. This runs during `StressAPIConfig.baseURL` initialization, which can happen early in launch.
**Fix:** Fall back to the known-good URL when parsing fails, and optionally log the invalid value:
```swift
if let url = URL(string: resolved) { return url }
return URL(string: fallback)!
```

### WR-02: `stress_context` is silently dropped on JSON-encoding failure

**File:** `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift:82-86`
**Issue:** The context payload is double-encoded (`JSONEncoder` → `JSONSerialization.jsonObject`) and guarded with `try?`:
```swift
if let stressContext {
    let encoder = JSONEncoder()
    if let ctxData = try? encoder.encode(stressContext),
       let ctxJSON = try? JSONSerialization.jsonObject(with: ctxData) {
        body["stress_context"] = ctxJSON
    }
}
```
If either step fails (e.g. a coding-key mismatch introduced in a future field), the request still goes out with `stress_context` omitted and no error surfaces. The chat completes with a degraded system prompt and the user sees no indication their health context was lost. Given the payload is the phase's central contract, a silent failure here is hard to diagnose.
**Fix:** Either propagate the encoding error (`try` without `?`) so the request fails loudly, or log the failure via the app's logger so it is observable in diagnostics.

### WR-03: `StressContextPayload.build` retains raw-factor `score` derived from HealthKit

**File:** `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:107-112`
**Issue:** The in-code comment at line 122-123 states "Raw HealthKit-derived readings never leave the device — only the app's own derived stress score/category above do." That invariant holds for the top-level `hrv`/`heartRate`/`sleep*` fields (all nil), but `factorPayload` is populated from `factorBreakdown` (e.g. `fb.hrvComponent.map { FactorPayload(score: $0, ...) }`). Those component scores are derived from raw HealthKit readings. The privacy claim "raw HealthKit-derived readings never leave the device" is at minimum imprecise about the per-factor scores, which are HealthKit-derived and do leave the device. This is a documentation/contract accuracy issue for a privacy-sensitive data flow.
**Fix:** Clarify the comment to distinguish raw values (HRV ms, HR bpm) from the app-derived normalized scores (0-1 factor scores) that are sent, or confirm with the backend contract that the factor scores are intentionally transmitted and adjust the comment to reflect that.

### WR-04: `FirebaseApp.configure()` + fire-and-forget sign-in has no error handling

**File:** `StressMonitor/StressMonitor/StressMonitorApp.swift:170-171`
**Issue:** `init()` calls `FirebaseApp.configure()` and then `Task { try? await Auth.auth().signInAnonymously() }`. Two concerns: (1) `FirebaseApp.configure()` crashes (fatalError) if called twice or if `GoogleService-Info.plist` is missing — there is no guard for a pre-existing `FirebaseApp.app()` or a missing config file. In a test host or a pre-release build without the plist, this terminates launch. (2) The `try?` discards all anonymous sign-in failures; if the network is unavailable at first launch, the app silently runs with no Firebase user, and the first chat attempt will surface a confusing "Please sign in" error from `getIDToken()` (FirebaseAuthService.swift:44-47) rather than a retry.
**Fix:** Guard the configure call: `if FirebaseApp.app() == nil { FirebaseApp.configure() }`. For the sign-in, consider surfacing transient failures to a state the UI can retry, or at minimum log them via `os.Logger` so a no-user-at-launch condition is diagnosable.

### WR-05: `getHealth` ignores the injected `baseURL` and hits `StressAPIConfig.healthURL`

**File:** `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift:59`
**Issue:** `getHealth` constructs its request from `StressAPIConfig.healthURL` (the static singleton) rather than the instance's `self.baseURL`. The client accepts an injectable `baseURL` (used by tests and by `sendChat` via `authorizedRequest`), so `getHealth` will probe a different host than the one the client is configured to talk to when a test or a UserDefaults override changes the instance URL. Today `baseURL` defaults to `StressAPIConfig.baseURL`, so production is unaffected, but the inconsistency means a custom-URL client will health-check the wrong endpoint.
**Fix:** Use `baseURL.appendingPathComponent("health")` to stay consistent with the injected configuration:
```swift
var request = URLRequest(url: baseURL.appendingPathComponent("health"))
```

### WR-06: `signInAnonymously()` early-returns when *any* user exists, masking stale sessions

**File:** `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:34-38`
**Issue:** `if Auth.auth().currentUser != nil { return }` treats the presence of any user as "signed in." If the cached anonymous user's session has expired and the SDK has not refreshed it, `getIDToken(forcingRefresh: false)` may still return a stale token (the refresh-margin logic at line 48-49 only checks `expirationDate`, not token validity), or the user object may be in a half-restored state after an app upgrade. Because `StressMonitorApp.init` calls `Auth.auth().signInAnonymously()` directly (not through this method) this path is mainly exercised by explicit callers, but the method's contract implies it establishes a valid session when it may not.
**Fix:** Narrow the guard to anonymous users only, or document that this method assumes a present user is a valid session. For anonymous auth specifically, consider verifying `currentUser.isAnonymous` rather than just non-nil.

### WR-07: `performFactoryReset` does not catch `CancellationError` separately

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:435-441`
**Issue:** Every other delete method in this file (`deleteAllMeasurements`, `deleteMeasurements(before:)`, `deleteMeasurements(in:)`, `resetCloudKitData`) explicitly catches `CancellationError` and maps it to `DeletionError.operationCancelled`. `performFactoryReset` omits that catch arm and falls through to the generic `catch` block at line 438, which maps cancellation to `DeletionError.repositoryError`. The earlier methods have comments explicitly calling out that a mid-flight cancellation must be classified as `operationCancelled`, not a misleading cloud/repository error (e.g. DataDeleterService.swift:356-358). The factory-reset path violates that invariant inconsistently, so a cancellation during the most destructive operation surfaces a wrong error category.
**Fix:** Add the same `catch is CancellationError` arm before the generic catch:
```swift
} catch is CancellationError {
    logger.log("Factory reset cancelled")
    throw DeletionError.operationCancelled
} catch {
```

---

## Info

### IN-01: `SSEParser` rejects SSE lines with no space after `data:`

**File:** `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift:34`
**Issue:** `guard line.hasPrefix("data: ")` requires exactly one space. The SSE spec permits `data:` followed directly by the payload (zero spaces) or multiple spaces. Some SSE intermediaries/proxies normalize whitespace. A `data:[DONE]` or `data:{...}` line would be silently skipped as `nil`. This is low-risk if the backend always emits `data: ` with one space, but it is a latent parser fragility.
**Fix:** Use `line.dropFirst(while:)` or a more tolerant prefix check (e.g. `line.hasPrefix("data:")` then trim leading spaces from the remainder).

### IN-02: `sendChat` builds the request body with `[String: Any]` + `JSONSerialization`

**File:** `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift:78-90`
**Issue:** The request body is assembled as a `[String: Any]` dictionary and serialized via `JSONSerialization` rather than a `Codable` struct + `JSONEncoder`. This bypasses compile-time key/type checking for the `messages`/`session_id`/`stress_context` envelope. A typo in `"session_id"` or `"stress_context"` would not be caught at build time. The existing `StressContextPayload` is already `Codable`; the outer envelope could be a small `Codable` struct too.
**Fix:** Define a `ChatRequestBody: Codable` struct (with `messages: [[String: String]]`, `session_id: String?`, `stress_context: StressContextPayload?`) and encode it. This removes the double-encoding dance at lines 82-86 and the `WR-02` silent-drop risk.

---

_Reviewed: 2026-08-13T14:59:51Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

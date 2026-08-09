# Networking Audit — StressMonitor (App Store publish readiness)

**Date:** 2026-08-08
**Scope:** networking dimension, App Store submission readiness
**Branch:** feature/spm-cache-integration
**Auditor:** axiom networking-auditor

> Persisted by the orchestrator — the audit run had no Write tool available.

## Networking Architecture Map

- Sole HTTP client: `URLSession.shared.bytes(for:)` streaming SSE from Supabase Edge Functions (`StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:122`). No Network.framework, no NWConnection/NetworkConnection, no BSD sockets anywhere in the app.
- Zero legacy/deprecated networking APIs found repo-wide: no `SCNetworkReachability`, `CFSocket`, `NSStream`/`CFStream`, `NSNetService`, `getaddrinfo`/`gethostbyname`. The only `isReachable` hits are `WCSession.isReachable` in `PhoneConnectivityManager.swift` / `WatchConnectivityManager.swift` — legitimate WatchConnectivity usage, not an internet-reachability anti-pattern.
- Protocol: HTTPS/SSE only. `Info.plist` has no `NSAppTransportSecurity` block (empty dict) → ATS defaults apply, HTTPS enforced, no exceptions. Zero hardcoded IP literals in app code.
- Auth: JWT from `KeychainService` (Security framework, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) sent as `Authorization: Bearer` + Supabase `apikey` header — correct pattern.
- Lifecycle: request-level 90s timeout is set; no session-level `waitsForConnectivity`; SSE consumption uses `[weak self]` + cooperative cancellation correctly for same-screen resend/clear, but the dismiss path of the Chat sheet never calls `cancelResponse()`.
- CloudKit sync (`CloudKitManager.swift`, `CloudKitSyncEngine.swift`, `SyncManager.swift`) uses `CKModifyRecordsOperation`/`records(matching:)` with exponential-backoff retry and user-facing error mapping — solid pattern, one gap noted below.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH | 2 |
| MEDIUM | 4 |
| LOW | 3 |
| **Total** | **10** |

**CRITICAL**
1. Fallback "guest" JWT baked into the binary is already expired, silently breaking AI Chat (the app's core network feature) for every unauthenticated user, including App Store reviewers on a fresh install.

**HIGH**
1. Chat sheet dismissal (Close button or swipe-to-dismiss) never cancels the in-flight SSE stream — the network task and its owning objects outlive the UI ("zombie connection").
2. No reconnect/resume handling for the SSE stream on network transition or mid-stream disconnect — a dropped connection silently discards the partially-streamed AI response with no recovery, and the credit charged for that message is not restored.

## Networking Health Score

| Metric | Value |
|--------|-------|
| Deprecated API count | 0 SCNetworkReachability + 0 CFSocket + 0 NSStream + 0 NSNetService + 0 manual DNS |
| Anti-pattern count (canonical 10) | 0 reachability-before-connect + 0 hardcoded IPs + 0 missing weak self + 0 blocking sockets + 0 missing waiting state |
| Network transition coverage | 0% — the one long-lived connection (chat SSE) has no viability/reconnect handling |
| TLS coverage | 100% of non-localhost connections (HTTPS-only, no ATS exceptions) |
| Connection cleanup | ~50% — cancel() path exists for resend/clear-conversation, missing for sheet dismissal |
| **Health** | **LEGACY** — driven entirely by the 1 CRITICAL finding below; the architecture itself (URLSession + async/await, zero deprecated APIs) is otherwise modern |

## Issues by Severity

### [CRITICAL] Hardcoded/expired fallback JWT breaks AI Chat for all unauthenticated users

**Files**
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift:6-8` — literal JWT with `iat` corresponding to 2026-06-28 and a 7-day expiry (~2026-07-05); today is 2026-08-08, so the token is over a month expired.
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift:25-36` — `guestJWT` falls back to this hardcoded value when no env/Info.plist/UserDefaults override exists.
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:32-43` — `init` sets `self.accessToken = storedToken ?? SupabaseConfig.guestJWT`; `:64-66` — `isAvailable()` only checks non-empty, never validates expiry.
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:58-60` — `isAvailable` computed once at init from the above, so the UI presents Chat as available.

**Phase:** 3 (completeness) + 4 (compound with auth)

**Issue:** Every unauthenticated install uses this single shared, expired JWT. Every `/chat` POST will receive HTTP 401, mapped to "Please sign in to use AI Chat." (`SupabaseLLMService.swift:177`) — but there is no real sign-in flow wired up yet (two separate `TODO: Replace with real SupabaseAuthService` comments in the code confirm this is known-incomplete).

**Impact:** The AI Chat feature — a marketed capability — is 100% non-functional for any user who hasn't manually signed in through a flow that doesn't exist yet. App Store reviewers testing a fresh install will hit this immediately (Guideline 2.1 App Completeness risk). Also a stale, shared credential embedded in a shipped binary is a security concern independent of expiry.

**Fix:** Ship real Supabase Auth (Apple Sign-In / anonymous auth) before submission, or gate the Chat entry point behind `isAvailable` re-checked against actual auth state (not a fixed fallback string), and treat 401 as "needs sign-in" rather than presenting Chat as ready.

**Cross-Auditor Notes:** Overlaps with security auditor (embedded credential) and shipping auditor (feature completeness for review).

---

### [HIGH] SSE connection not cancelled when Chat sheet is dismissed

**Files**
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift:44-46` (Close button just calls `dismiss()`), presented via plain `.sheet(isPresented:)` in `Views/Action/ActionView.swift:43-45` and `Views/Settings/SettingsView.swift:66` — no `.onDisappear` anywhere in the file.
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:35,77-80,164-175` — `streamingTask` is a stored property; `send()` captures `[weak self]` but immediately rebinds to a strong local `self` for the duration of `streamResponse()`, so the object (and its underlying URLSession stream) stays alive until the network call naturally finishes even after the view/State is torn down.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| No cancel-on-dismiss for chat SSE stream | High — happens on every dismiss during an active response | Medium — one feature, but runs on every session with a mid-chat dismiss; wastes battery/data and continues consuming backend credits after the user has left | Low — call `cancelResponse()` in an `.onDisappear`/`.sheet(onDismiss:)` | High |

**Phase:** 3 (completeness) + 4 (compound: missing `.cancel()` + stored connection in view model)

**Issue:** `cancelResponse()` exists and correctly tears down the stream (verified: cancelling propagates, the `AsyncThrowingStream` deallocates, `onTermination` fires `task.cancel()`), but it is only invoked from `send()` (before starting a new message) and `clearConversation()` — never from the sheet's dismissal path.

**Fix:**
```swift
.sheet(isPresented: $isChatPresented, onDismiss: { viewModel.cancelResponse() }) {
    ChatBottomSheetView(...)
}
```
or add `.onDisappear { viewModel.cancelResponse() }` inside `ChatBottomSheetView.body`.

**Cross-Auditor Notes:** Overlaps with memory/performance auditor (retained objects after navigation) and energy auditor (continued background network use).

---

### [HIGH] No reconnect/resume on network transition or mid-stream disconnect; partial response silently lost

**Files**
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:122,131-152` — single `URLSession.shared.bytes(for:)` call; any read failure just `continuation.finish(throwing: LLMServiceError.unknown(error))`.
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:120-148` — on any thrown error mid-loop, `currentStreamingText` (already-received partial tokens) is discarded — only `errorMessage` is set; contrast with `cancelResponse()` at `:169-172`, which does preserve partial text as a message. The `defer` block at `:93-98` resets `currentStreamingText = ""` for the error path too.

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| Mid-stream network drop discards partial AI response, no retry | Medium-High — Wi-Fi↔cellular handoff is common during real usage of a chat feature | Medium — every chat message is exposed to this on any connectivity blip | Medium — needs partial-text preservation + optional resume/backoff | High |

**Phase:** 3 (completeness — "40% of connection failures happen during network transitions")

**Issue:** There is no `NWPathMonitor`/transition awareness, and the error path doesn't reuse the same partial-text preservation logic that cancellation already has. A user who loses Wi-Fi mid-response sees a generic error and loses the entire in-progress answer (and the credit charged for it, per the backend contract of 1 credit/message).

**Fix:** In the `catch` clauses of `streamResponse()`, append `currentStreamingText` as a partial assistant message (mirroring `cancelResponse()`), and consider a single automatic retry for `URLError.networkConnectionLost`/`.notConnectedToInternet` before surfacing the error.

---

### [MEDIUM] CloudKit retry loop retries non-retriable errors

**File:** `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift:45-70` (`uploadMeasurements`), `:113-136` (`downloadMeasurements`)

**Issue:** The exponential-backoff retry (up to 3 attempts, `1s·2^attempt`) fires for every error type, including `.quotaExceeded`/`.notAuthenticated`-class failures that cannot succeed on retry (per `CloudKitManager.adaptCloudKitError` at `:238-255`, which already knows the error category but that categorization isn't consulted by the retry loop).

**Impact:** Adds ~6s of pointless delay before surfacing an unrecoverable error to the user; wastes battery on retrying doomed operations.

**Fix:** Check `CKError.code` before retrying; skip the loop for `.quotaExceeded`, `.notAuthenticated`, `.permissionFailure`, etc.

---

### [MEDIUM] No `waitsForConnectivity` on the chat network session

**File:** `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:95-122`

**Issue:** Uses `URLSession.shared` (default config, `waitsForConnectivity = false`) with only a per-request 90s timeout. A momentary connectivity blip (e.g., toggling airplane mode, brief Wi-Fi/cellular handoff) fails the send instantly instead of waiting a few seconds for the network to come back.

**Fix:** Use a dedicated `URLSessionConfiguration` with `waitsForConnectivity = true` and a matching `URLSessionTaskDelegate` callback for "waiting for connectivity" UI feedback.

---

### [MEDIUM] Backend endpoints declared but never called from iOS

**File:** `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift:47-52` — `healthURL`, `sessionsURL`, `preferencesURL`, `creditsURL`, `quickActionsURL` are all defined; a repo-wide grep found zero call sites for any of them outside this declaration.

**Issue:** Per the workspace `CLAUDE.md` cross-repo contract, `/sessions`, `/preferences`, `/credits`, `/quick-actions` are real backend endpoints, but the iOS client never fetches them — credits balance and quick actions are only known transiently via SSE `metadata` events during an active chat (`SupabaseLLMService.apply(metadata:)` at `:157-164`), and there is no standalone "check my credit balance" or session-history sync.

**Fix:** Either wire these up or remove the unused declarations to avoid drift between backend contract and client implementation.

---

### [MEDIUM] Documentation/behavior mismatch on health-data transmission

**Files:** workspace `CLAUDE.md` ("HealthKit data... never sent to Supabase") vs. `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:8-136` and `SupabaseLLMService.swift:111-118`, which serialize stress level, HRV, heart rate, confidence, and factor breakdown into the `/chat` POST body sent to Supabase over HTTPS.

**Issue:** TLS is fine (no missing-encryption issue), but the workspace-level privacy claim is inconsistent with actual behavior. `PrivacyInfo.xcprivacy` (`StressMonitor/StressMonitor/PrivacyInfo.xcprivacy:11-22`) does already declare `NSPrivacyCollectedDataTypeHealthAndFitness` for app-functionality purposes, so the manifest itself isn't obviously non-compliant — but this should be reconciled before the App Store Connect privacy questionnaire is filled out, since reviewers cross-check stated data practices against actual network behavior.

**Cross-Auditor Notes:** Route to shipping/privacy auditor for the App Store Connect nutrition-label questionnaire.

## Low-Severity Notes

- `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift:41-44,73` — unrecognized/malformed SSE lines are silently dropped (returns `nil`), with no error signal; a backend format change or heartbeat comment would only surface as a hang bounded by the 90s inactivity timeout.
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:146-148` — the generic `catch { errorMessage = error.localizedDescription }` can surface raw system error text for non-`LLMServiceError` failures, instead of the app's own curated copy (contrast with `SupabaseLLMService.mapHTTPError` at `:174-184`).
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift:18-23,38-40` — `anonKey`'s fallback is a non-empty placeholder, so `isConfigured` can report `true` in a misconfigured build, converting a clear "not configured" message into a confusing backend-level auth failure.
- `ChatViewModel.currentStreamingText` (`:14,120-123`) has no upper bound during accumulation — not exploitable given model context limits, but worth a defensive cap.

## Recommendations

1. **Immediate:** Fix the expired/shared guest JWT (CRITICAL) before any submission — either ship real Supabase Auth or gate Chat's availability on a live auth check instead of a hardcoded fallback string. Wire `cancelResponse()` into the Chat sheet's dismissal path (HIGH).
2. **Short-term:** Preserve partial streamed text on mid-stream network errors (mirror the cancellation path); add `waitsForConnectivity`; make the CloudKit retry loop error-aware.
3. **Long-term:** Either implement the unused `/sessions`, `/preferences`, `/credits`, `/quick-actions` client calls or remove the dead declarations; reconcile the workspace privacy documentation with the actual `/chat` payload before filling out App Store Connect's privacy questionnaire.

## Files Referenced

- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift`
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift`
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift`
- `StressMonitor/StressMonitor/Services/LLM/SSEParser.swift`
- `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift`
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift`
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift`
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift`
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift`
- `StressMonitor/StressMonitor/Services/Sync/SyncManager.swift`
- `StressMonitor/StressMonitor/Info.plist`
- `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy`

## Unresolved Questions

1. Is a real Supabase Auth flow (Apple Sign-In / anonymous) planned before submission, or is the guest-JWT path intended to remain the shipping mechanism?
2. Are `/sessions`, `/preferences`, `/credits`, `/quick-actions` intended for this release, or should the declarations be removed?
3. Which is authoritative for the App Store Connect privacy questionnaire — the workspace `CLAUDE.md` claim or the actual `/chat` payload?

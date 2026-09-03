# Phase 3: Sessions, Preferences, Quick Actions + Cleanup - Research

**Researched:** 2026-08-23
**Domain:** iOS integration of the final three backend endpoint groups (sessions / preferences / quick-actions) against the Deno/Hono backend, plus Supabase-remnant cleanup and milestone-close integration testing
**Confidence:** HIGH (every API contract read from backend route files, their tests, migrations, and `lib/types.ts` this session; every iOS integration point read in source with line ranges)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sessions — History Model & Session Semantics**
- Continuous history restore: keep the single rolling session (`stressChatSessionId` in UserDefaults); on chat open, fetch `GET /sessions/{id}/messages` for the current session and render. No session-picker UI this phase.
- Server-authoritative message store: fetch on open, no local SwiftData cache of chat messages (offline chat is already impossible — SSE needs network; matches Phase 2's server-owns-truth precedent).
- Factory reset / delete-all-data wipes server chat history: DataDeleter iterates `GET /sessions` + `DELETE /sessions?id=` per session before the local wipe (DATA-01 "delete actually deletes everywhere" bar).
- Client-side session titles: `POST /sessions` with title = first user message (truncated) before the first chat of a new session, then send its id — no backend change, list-ready for a future history UI.

**Preferences Sync**
- Sync the chat-relevant pair only: `language` + `coaching_style`. The other backend fields (display_name, theme, notification_enabled, stress_alert_threshold, custom_settings) have no iOS owner mapping and stay untouched this phase.
- New "AI Coach" section in Settings (language picker + coaching-style choice among the backend's accepted values) — Settings is the established surface (Phase 1 Google row, Phase 2 credit rows). No onboarding change.
- Local-writer-wins per field: `PUT /preferences` on user change; `GET /preferences` once at first sign-in to seed. No timestamped merge (backend has none).
- `StressContextPayload.build` reads language/coachingStyle from the PreferencesService instead of hardcoded `"en"`/`"supportive"` defaults — one source of truth.

**Quick Actions Source & Behavior**
- Chips come from `GET /quick-actions` at chat open with live stress context; the existing local static set (`ChatQuickActions`) renders instantly as fallback and is swapped when the fetch lands. No loading state, no empty state.
- Chip taps send their prompt through the existing `/chat` path (`sendQuickAction` → credit-metered, session-persisted, streamed). `QuickActionChipsView` UI unchanged.
- `POST /quick-actions` is deliberately NOT wired: it returns a full 512-token completion with no credit deduction — wiring taps to it would open an unmetered chat path bypassing the Phase 2 revenue model.
- Record a note/issue for stress-app-be to meter or gate `POST /quick-actions`; no iOS change for it.

**Cleanup Scope & Final Integration Testing**
- Remove `.gitignore`'s `supabase/.temp/` line and fix `design/screens/25-about.html`'s stale "Supabase LLM 2.4" OSS row.
- KEEP `FirebaseAuthService.clearStoredCredentials()`'s Supabase keychain sweep + `DataDeletionConsolidationTests` — upgrader-protection code that runs only on factory reset, not a remnant.
- Fold in 01-REVIEW CR-02: fix the inverted trend direction in `StressContextPayload.build` (recentHistory newest-first) with a regression test — explicitly deferred to Phase 3 by 02-01's deferral note; the same builder changes for the prefs-fed fields anyway.
- Final integration testing gate: full `StressMonitorTests` suite via `xcodebuild test -parallel-testing-enabled NO`, targeted new-feature suites, `xcodebuild build -configuration Release`, backend suite still green, plus a UAT script covering history restore, prefs round-trip, and chip fetch.
- Server-session wipe tested via protocol-faked `StressAPIClient` unit tests (delete-sessions loop); live-infrastructure verification rides the UAT script like Phase 2's smoke.

### Claude's Discretion
All implementation details not listed above — file layout, type names, view decomposition, error surfaces — per codebase conventions (`Services/API/` extension pattern for StressAPIClient, ViewModels in `ViewModels/`, Settings section pattern).

### Deferred Ideas (OUT OF SCOPE)
- Multi-session UX (New chat button, browsable past-session list, per-session delete UI) — this phase restores continuous history only; the titled sessions make the list trivial later.
- Syncing the remaining preference fields (display_name, theme, notification_enabled, stress_alert_threshold, custom_settings) — no iOS owner mapping today; revisit when those settings surfaces exist.
- SSE terminal `quick_actions` metadata driving chip refresh after each response — chips refresh on chat open only this phase.
- Backend `POST /quick-actions` metering/gating — backend-repo issue, not iOS scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

No ROADMAP-mapped requirement IDs (v1.1 convention: plans declare IDs directly, derived from CONTEXT decisions). AUTH-03 (v1.0 carry-over: chat streaming lifecycle pinned by TDD tests) is addressable as a regression-surface requirement — Phase 3 edits `ChatViewModel`/`StressLLMService`, so keeping the existing lifecycle suites green IS the AUTH-03 contribution.

| ID (derived) | Description (from CONTEXT decisions) | Research Support |
|----|-------------|------------------|
| derived-SES-01 | History restore on chat open: `GET /sessions/{id}/messages` for the persisted session, rendered through the existing messages array; server-authoritative, no local cache | Sessions API contract (below), `StressLLMService.currentSessionId` persistence seam, `ChatBottomSheetView.onAppear` hook, 404-tolerance requirement (Pitfall 3) |
| derived-SES-02 | Titled session creation: `POST /sessions` with title = first user message (truncated) before the first chat of a new session, then send its id | Sessions POST contract, `StressLLMService.send` Task capture-list seam (Pitfall 5 ordering) |
| derived-SES-03 | Factory reset wipes server chat history: DataDeleter iterates `GET /sessions` + `DELETE /sessions?id=` per session before the local wipe; protocol-faked unit tests | DataDeleterService phase structure, pagination loop + safety cap (Pattern 4), test seam design |
| derived-PREF-01 | Preferences sync pair (`language` + `coaching_style`): GET once at first sign-in to seed, PUT on user change, local-writer-wins | Preferences API contract + ALLOWED_FIELDS, `PreferencesService` shape (Pattern 2), app-root environment wiring |
| derived-PREF-02 | `StressContextPayload.build` reads language/coachingStyle from PreferencesService (one source of truth) + Settings "AI Coach" section | Build signature with default params (verified), ChatViewModel injection seam, SettingsView section pattern |
| derived-QA-01 | Server-driven chips: `GET /quick-actions` at chat open with live context; local static set renders instantly, swapped when fetch lands; taps send via the existing `/chat` path; `POST /quick-actions` never wired | Quick-actions GET contract, **critical wiring correction** (the visible chips are `defaultQuickReplies`, not `QuickActionChipsView` — see Architecture Patterns), prompt map for taps |
| derived-CLEAN-01 | Remove `.gitignore:164` `supabase/.temp/` + fix `design/screens/25-about.html:207` "Supabase LLM 2.4" row; KEEP the keychain sweep + `DataDeletionConsolidationTests` | Both remnant lines verified byte-exact this session; app-source sweep confirms nothing else (see Runtime State Inventory) |
| derived-CR02 | Fix inverted trend direction in `StressContextPayload.build` (recentHistory newest-first → chronological before delta) with a regression test | Bug mechanics verified at StressContextPayload.swift:87-101 + newest-first caller at StressRepository.swift:85-96; test lands in existing `StressContextPayloadTests` |
| AUTH-03 (carried) | Chat streaming lifecycle stays pinned: send/cancel/partial-preservation/402-paywall behavior unchanged under Phase 3 edits | Existing `ChatLifecycleTests` (FakeLLMService), `SSEParserTests`, `PaywallOutOfCreditsGuardTests`, `StressAPIClientTests` — all must stay green; regression-risk map in Pitfalls |
</phase_requirements>

## Summary

Phase 3 is pure iOS-side integration against a backend that is already implemented, tested, and deployed: every route this phase consumes was read in `stress-app-be/src/routes/` this session and pinned by the backend's own Deno tests. The work decomposes into four independent seams on the iOS side — (1) three new `StressAPIClient` endpoint-group extensions (`+Sessions`, `+Preferences`, `+QuickActions`) each cloning the `+Credits` pattern (typed error enum + status-switch + Codable DTO), (2) `PreferencesService` (`@MainActor @Observable`, app-root `.environment`, CreditService analog) feeding `StressContextPayload.build` and a new Settings "AI Coach" section, (3) chat-open behavior in `ChatBottomSheetView`/`ChatViewModel`: history restore (`GET /sessions/{id}/messages`), server chips fetch with instant local fallback, and titled-session creation riding `StressLLMService.send` when `currentSessionId == nil`, plus the CR-02 trend fix in the same builder, and (4) the DataDeleter server-session wipe + two-file Supabase cleanup + the backend metering note.

Two discoveries materially change how the plan should be written. **First, the CONTEXT's "existing chips" mental model doesn't match the live view**: `QuickActionChipsView` and `ChatViewModel.quickActions`/`sendQuickAction` are currently dead code — the chat sheet actually renders a hardcoded `defaultQuickReplies: [String]` block (ChatBottomSheetView.swift:318-357) whose taps set `inputText` and call `sendMessage()`. The locked behavior (instant local fallback → server swap, taps through `/chat`) is unchanged, but the plan must wire the *actual* surface, not the orphan component. **Second, `stressChatSessionId` is never cleared on factory reset** — `StressLLMService.clearStoredCredentials()` has zero call sites (verified by grep), so a post-reset user carries a dangling session id; the wipe integration must clear it, and history restore must tolerate 404 regardless.

The regression surface from Phase 2 (402 → paywall, SSE streaming, credits convergence) is well-fenced: none of the four seams requires touching `LLMServiceProtocol.send`'s signature, `SSEParser`, `mapHTTPError`, or the paywall wiring, and the existing suites (`ChatLifecycleTests`, `SSEParserTests`, `PaywallOutOfCreditsGuardTests`, `CreditPurchaseFlowTests`) pin the contract.

**Primary recommendation:** Plan in dependency order — API extensions + DTOs first (pure additive, URLProtocol-tested like `StressAPIClientCreditsTests`), then PreferencesService + prefs-fed builder + CR-02 (one builder change covers both), then chat-open behavior (restore + chips + titled sessions) with the Phase-2 suites as regression fence, then the DataDeleter wipe + cleanup + backend note, and close with the full integration gate (full suite + Release build + backend suite + UAT script). Restart the local test postgres on 127.0.0.1:5433 before the backend-suite gate — it is down right now (verified).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Chat message persistence (source of truth) | Backend (`chat_messages` via `/chat` inserts) | iOS (in-memory `messages` array, display only) | Backend already persists user+assistant messages per send; iOS re-fetches on open — no local cache (locked) |
| Session identity continuity | iOS (`stressChatSessionId` UserDefaults, owned by `StressLLMService`) | Backend (session rows, `session_id` in `/chat` body + SSE metadata) | iOS chooses which session to continue; backend creates/validates |
| Session titles | iOS (first user message, truncated → `POST /sessions`) | Backend (stores TEXT, defaults "New Conversation") | Locked decision: client-side titles, no backend change |
| Preferences (language/coaching_style) source of truth | Backend (`user_preferences` row) | iOS cache (`PreferencesService`, seeded once, local-writer-wins per field) | Backend owns defaults + allowlist; iOS is the only writer this phase |
| Stress-context language/coachingStyle | iOS `PreferencesService` → `StressContextPayload.build` | Backend (builds system prompt from payload) | One source of truth on-device (locked); backend just consumes the payload |
| Quick-action suggestions | Backend (`GET /quick-actions`, deterministic rules) | iOS local static fallback | Server suggestions are context-aware; local set guarantees instant chips |
| Chip tap execution | iOS `/chat` path (credit-metered, streamed) | — | Locked: never `POST /quick-actions` (unmetered 512-token completion) |
| Server session wipe on factory reset | iOS `DataDeleterService` (orchestrates) | Backend (`DELETE /sessions?id=` per session) | DATA-01: deletion is an app-level promise; backend provides per-id delete only |
| Trend direction (CR-02) | iOS `StressContextPayload.build` | — | Pure client-side computation bug; backend consumes the label |

## Standard Stack

No new packages — system frameworks + already-integrated Firebase only. Locked by constraint ("zero third-party deps except firebase-ios-sdk") and unchanged by this phase.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Foundation / URLSession | iOS 18.6 SDK | `StressAPIClient` extensions, Codable DTOs | Established Phase 1/2 client; `authorizedRequest` already injects Bearer + JSON headers |
| SwiftUI / Observation | iOS 18.6 SDK | AI Coach settings section, chips swap, `@Observable` services | Project convention (`@MainActor @Observable final class`) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Firebase Auth (firebase-ios-sdk 11.x, already linked) | resolved in Package.resolved | Bearer ID token for all three new endpoint groups | Every request rides `authorizedRequest` — no new auth code |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Codable DTOs per endpoint group | Single shared `StressContextPayload`-style mega-DTO | Per-group DTOs match `CreditBalance` precedent and keep decode failures isolated; mega-DTO couples sessions to chat-context shape |
| `JSONDecoder` with String dates | `.iso8601` date strategy | `.iso8601` **fails** on Postgres fractional-second timestamps — see Pitfall 1; String (CreditBalance `freeResetAt` precedent) or custom formatter only |

**Installation:** none.

**Version verification:** no packages added; nothing to verify on a registry.

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 [Chat sheet opens: SettingsView chat row / ActionView card]
        │  ChatBottomSheetView.onAppear (fresh ChatViewModel + StressLLMService per presentation)
        ├──────────────────────────────────────────────────────────────────────────────┐
        ▼                                                                              │
 (1) HISTORY RESTORE                                                          (2) CHIPS FETCH        │
 ChatViewModel.restoreHistory()                                     QuickActions fetch (live context)  │
   │ currentSessionId (UserDefaults "stressChatSessionId")                       │     │
   │ nil ──► skip (empty chat)                                                   │     │
   │ id  ──► GET /sessions/{id}/messages  ── 404 ──► resetSession(), empty       │     │
   │                  │  200 {messages:[{id,session_id,role,                    │     │
   │                  │          content,tokens_used,created_at}]}              │     │
   │                  ▼                                                          ▼     │
   │      map → ChatMessage(remoteId, sessionId, isSynced:true)      GET /quick-actions?stress_level=&language=  │
   │      render into messages (only if still empty)                  &coaching_style= → {quick_actions:[...]}   │
   │                                                                              │     │
   └──────────────────────────────────────────────────────────────────────────────┘
        │
        │  user sends message (composer or chip tap → sendMessage()/send(text))
        ▼
 ChatViewModel.send ──► StressLLMService.send (Task captures currentSessionId)
        │                     │
        │        currentSessionId == nil ?
        │            ├── yes ──► POST /sessions {title: first message truncated,     │
        │            │              stress_context} → 201 {id,...}                    │
        │            │              persist id (currentSessionId + UserDefaults)     │
        │            │              (fail-soft: on error fall through with nil)      │
        │            └── no ──┐                                                      │
        │                     ▼                                                      │
        │            POST /chat {messages, session_id, stress_context}  ◄── StressContextPayload.build
        │                     │                                    (language/coachingStyle from
        │                     │  402 → .insufficientCredits → paywall  PreferencesService; CR-02-fixed
        │                     │  (Phase 2 path — UNCHANGED)            recentHistory ordering)
        │                     ▼
        │            SSE stream → SSEParser → tokens + terminal metadata{session_id,
        │                     credits_remaining, model_used, quick_actions}
        │                     └► apply(metadata:) persists session_id (existing)
        ▼
 [Settings → AI Coach section (new)]
        Picker/Biometric tap ──► PreferencesService.update(language:|coachingStyle:)
                                  optimistic set + PUT /preferences {language} — allowlisted
                                  seed: GET /preferences once at first sign-in/surface
        │
        ▼
 [Settings → Manage data → Factory reset]
        DataDeleterService.performFactoryReset
          Phase 0 (NEW): GET /sessions (limit 20, offset loop) → DELETE /sessions?id= per id
                         → clear stressChatSessionId → then existing CloudKit → local → baseline
```

### Recommended Project Structure

```
StressMonitor/StressMonitor/
├── Models/
│   ├── ChatSession.swift                    # DTO: id, title, createdAt/updatedAt (String dates)
│   ├── ChatSessionMessage.swift             # DTO: id, sessionId, role, content, tokensUsed, createdAt(String)
│   ├── UserPreferences.swift                # DTO: language, coachingStyle (Codable ignores rest)
│   └── ServerQuickAction.swift              # DTO: id, title, type
├── Services/
│   ├── API/
│   │   ├── StressAPIClient+Sessions.swift   # listSessions/createSession/deleteSession/fetchMessages + SessionsAPIError
│   │   ├── StressAPIClient+Preferences.swift # getPreferences/updatePreferences + PreferencesAPIError
│   │   └── StressAPIClient+QuickActions.swift # getQuickActions(...) + QuickActionsAPIError
│   ├── Preferences/
│   │   └── PreferencesService.swift         # @MainActor @Observable final (CreditService analog)
│   ├── LLM/
│   │   ├── StressLLMService.swift           # + titled-session creation in send() when sessionId nil
│   │   └── StressContextPayload.swift       # CR-02 fix + prefs-fed language/coachingStyle
│   └── DataManagement/
│       └── DataDeleterService.swift         # + server-session wipe phase (protocol seam)
├── ViewModels/
│   └── ChatViewModel.swift                  # + restoreHistory(), server chips state, prefs seam
└── Views/
    ├── Chat/ChatBottomSheetView.swift       # onAppear: restore + chips fetch; chips section swap
    └── Settings/SettingsView.swift          # + sectionLabel("AI Coach") + SettingsCard rows
StressMonitor/StressMonitorTests/
├── StressAPIClientSessionsTests.swift       # NEW (URLProtocol pattern) + pbxproj 4-line registration
├── StressAPIClientPreferencesTests.swift    # NEW
├── StressAPIClientQuickActionsTests.swift   # NEW
├── PreferencesServiceTests.swift            # NEW
├── ChatHistoryRestoreTests.swift            # NEW (ChatViewModel seam, FakeLLMService analog)
└── DataDeleterServerWipeTests.swift         # NEW (fake ServerSessionWiping seam)
stress-app-be/                                # note/issue only — NO route changes
└── (POST /quick-actions metering note — see Open Questions Q3)
```

### Pattern 1: Endpoint-group extension (`StressAPIClient+Credits` clone)
**What:** `enum XAPIError: Error, LocalizedError, Equatable, Sendable` + `extension StressAPIClient` with one func per endpoint: `authorizedRequest(path:method:body:)` → `session.data(for:)` → status switch (`200...299` decode / `401` unauthorized / default `.server(statusCode:)`).
**When to use:** all three new groups. Verbatim template [VERIFIED: StressAPIClient+Credits.swift:3-46]:
```swift
enum CreditsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case invalidTransaction
    case server(statusCode: Int)
    // errorDescription switch...
}
extension StressAPIClient {
    func getBalance() async throws -> CreditBalance {
        let request = try await authorizedRequest(path: "credits", method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw CreditsAPIError.invalidResponse }
        switch httpResponse.statusCode {
        case 200...299: return try JSONDecoder().decode(CreditBalance.self, from: data)
        case 401: throw CreditsAPIError.unauthorized
        default: throw CreditsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}
```
Notes: `path` is relative — `authorizedRequest` does `baseURL.appendingPathComponent(path)` [VERIFIED: StressAPIClient.swift:39]. Query strings must be embedded in `path` (e.g. `"sessions/\(id.uuidString)/messages"`, `"sessions?id=\(id.uuidString)"`, `"quick-actions?stress_level=\(level)&language=\(lang)"`). `StressAPIClient` is `@MainActor final class` [VERIFIED: StressAPIClient.swift:9-10] — **cannot be subclassed**; fakes are either URLProtocol-level (established `RequestCaptureURLProtocol`) or a narrow protocol (Pattern 4).

### Pattern 2: PreferencesService (CreditService analog, app-scope environment)
**What:** `@MainActor @Observable final class` owning `private(set) var language/coachingStyle`, seeded once via GET, updated optimistically then PUT. Registered once at the app root and injected with `.environment(...)` — exactly how `CreditService` is owned [VERIFIED: StressMonitorApp.swift:28, 180-181, 200 — `@State private var creditService: CreditService` / `let creditService = CreditService()` / `.environment(creditService)`].
**Shape (recommended skeleton):**
```swift
@MainActor @Observable
final class PreferencesService {
    private(set) var language: String = "en"        // backend defaults [VERIFIED: migration 20260812000003:4-5]
    private(set) var coachingStyle: String = "supportive"
    private(set) var hasSeeded = false
    private let apiClient: StressAPIClient
    init(apiClient: StressAPIClient? = nil) { self.apiClient = apiClient ?? StressAPIClient() }
    func seedIfNeeded() async { /* GET /preferences once; map language/coaching_style */ }
    func update(language: String) async { /* optimistic set + PUT {"language": ...}; revert on throw */ }
    func update(coachingStyle: String) async { /* PUT {"coaching_style": ...} */ }
}
```
Local-writer-wins per field is the locked semantics — on PUT failure the planner decides revert-vs-keep (see Open Questions Q2; recommend revert + surfaced error, matching `AccountViewModel`'s rethrow-and-alert pattern). "GET once at first sign-in": there is no clean signed-in callback (anonymous sign-in is fire-and-forget at launch), so seed from the first surface that needs prefs — chat open and Settings `onAppear` both calling `seedIfNeeded()` (guarded by `hasSeeded`) is the pragmatic equivalent.

### Pattern 3: Chat-open lifecycle (restore + chips) on the existing onAppear seam
**What:** `ChatBottomSheetView` already wires app-scope services in `onAppear` because environment is unreachable in `init` [VERIFIED: ChatBottomSheetView.swift:45-54]. Add restore + chips fetch there (or `.task`); each sheet presentation constructs a fresh `ChatViewModel` (the `.sheet` content closure re-evaluates, `_viewModel = State(initialValue: ...)` at :25-29), so fetch-on-open is naturally idempotent per presentation.
**Guards the implementation must include:**
- Restore applies only if `messages.isEmpty` at apply time (user may have typed/sent before the fetch lands — don't clobber).
- 404 from `GET /sessions/{id}/messages` → the persisted session is gone server-side → clear the local session id (resetSession-equivalent) and render empty (see Pitfall 3).
- Auth-unavailable (`getIDToken` throws, signed-out edge) → skip silently, empty chat; chips keep local fallback.
**Chips swap:** keep the current instant render; when the fetch lands, replace the chips model. Because the *live* chips are the `defaultQuickReplies` string block (see Critical Wiring Correction below), the minimal-change shape is a `@State private var quickActionPrompts: [String]`-style model (or `[ChatQuickAction]` rendered through the unchanged `QuickActionChipsView`) initialized to the local set and reassigned from server actions mapped id→prompt.

**Critical Wiring Correction (research finding — CONTEXT's mental model vs live code):** the chat sheet does **not** currently use `QuickActionChipsView`, `ChatViewModel.quickActions`, `ChatQuickActions.actions(for:)`, or `sendQuickAction` — greps for call sites return only definitions. The rendered chips are [VERIFIED: ChatBottomSheetView.swift:326-357]:
```swift
ForEach(defaultQuickReplies, id: \.self) { reply in
    Button { inputText = reply; sendMessage() } label: { Text(reply) ... }
}
/// Default quick replies matching the HTML design.
private var defaultQuickReplies: [String] {
    ["Why is my HRV low?", "Suggest a walk", "Set a 5pm check-in", "Read me a poem"]
}
```
The locked *behavior* (instant local fallback → server swap, taps through the existing `/chat` path, chips UI look unchanged) is implementable two ways: (a) keep the string-chip block and swap its data source (minimal diff; taps already ride `sendMessage()` → `viewModel.send`), or (b) render `ChatQuickAction`s through the existing `QuickActionChipsView` component with `sendQuickAction` (uses the dormant plumbing, matches CONTEXT's component references). Either satisfies the locked decision; the plan should pick one and say which. Server actions arrive as `{id, title, type}` with **no prompt field** — the tap prompt comes from a local id→prompt map mirroring the backend's own prompt table [VERIFIED: stress-app-be/src/lib/quick-actions.ts:56-67 — `breathing: "Guide me through a box breathing exercise right now."`, `grounding: "Help me with the 5-4-3-2-1 grounding technique."`, `sleep_tips: "Give me practical tips to sleep better tonight."`, `mini_walk: "Suggest a simple 5-minute movement routine I can do right now."`, `recovery: "What recovery strategies should I focus on given my current state?"`, `resilience: "How can I build long-term stress resilience?"`, `talk: "I want to talk more about how I'm feeling right now."`]; unknown ids fall back to sending the title as the prompt.

### Pattern 4: DataDeleter server-wipe with a narrow Sendable protocol seam
**What:** a small protocol so `DataDeleterService`'s wipe loop is unit-testable without a live network (locked: "Server-session wipe tested via protocol-faked StressAPIClient unit tests"):
```swift
protocol ServerSessionWiping: Sendable {
    func listSessions(limit: Int, offset: Int) async throws -> [ChatSession]   // returns .sessions
    func deleteSession(id: UUID) async throws
}
```
`StressAPIClient+Sessions` conforms; `DataDeleterService`'s injecting init gains `serverSessionWiper: ServerSessionWiping? = nil` (default: a `StressAPIClient`-backed conformer), mirroring the existing `cloudKitResetService` injection seam [VERIFIED: DataDeleterService.swift:44-57 — "Injects a ``CloudKitResetServiceProtocol`` directly — the seam tests use to substitute a failing/cancellable fake"]. The wipe runs as a new **first** phase of `performFactoryReset` (progress ~0.0-0.05, before the CloudKit reset at :408-412) — it must execute while still authenticated, since `Self.clearCredentialsAndSharedCaches()` (:428) signs the user out afterward. The loop: repeat `listSessions(limit: 20, offset)` → `deleteSession(id:)` per row → advance offset — until an empty page or a safety cap (e.g. 50 pages) — then clear `stressChatSessionId` (see Pitfall 4). Tests inject a fake recording list/delete calls (multi-page, empty-user, failure arms).
**Scope note:** "Factory reset / delete-all-data" in CONTEXT maps to `performFactoryReset` (the full wipe, `DataManageView.performFactoryReset` at :181-184). `deleteAllMeasurements` (:165-179, "All stress snapshots were deleted") is measurements-scoped and should NOT delete chat history — chat messages are not measurements. Flag for the planner to state explicitly in the plan (over-deleting chat on a snapshots-only delete would violate least-surprise).

### Pattern 5: Titled-session creation inside StressLLMService.send
**What:** `send()`'s `Task` already captures `[stressAPIClient, currentSessionId, stressContext]` [VERIFIED: StressLLMService.swift:72]. Insert, before `sendChat`: if `currentSessionId == nil`, `POST /sessions {title: lastUserMessage.content truncated, stress_context}` → persist returned id exactly like `apply(metadata:)` does (:114-118: set `currentSessionId` + `UserDefaults`). Title suggestion: ~50 chars + ellipsis (backend `title TEXT` unlimited; a future list row needs one line). Send the title source = `messages.last(where: .user)?.content`.
**Ordering is load-bearing (Pitfall 5):** creation MUST precede `sendChat` so the first `/chat` carries `session_id` — otherwise the backend auto-creates its own session (title "New Conversation") and the just-created titled session stays empty forever.
**Failure semantics (recommended):** fail-soft — if `POST /sessions` errors, proceed with `session_id: nil` (backend auto-creates; title lost, history still server-persisted). Blocking the whole chat on a title-creation failure would regress Phase 2 chat reliability for a nice-to-have. Planner ratifies.
**Interaction with `resetSession()`/`clearConversation()`:** clear resets `currentSessionId` → the next send creates a fresh titled session. Correct per locked semantics.

### Anti-Patterns to Avoid
- **Wiring `POST /quick-actions` anywhere in iOS:** unmetered 512-token completion bypassing the Phase 2 revenue model — locked out; file the backend note instead.
- **Caching chat messages in SwiftData:** locked out (server-authoritative; offline chat is impossible anyway).
- **Re-decoding dates with default/`.iso8601` strategies:** both fail on Postgres fractional seconds (Pitfall 1).
- **Touching `LLMServiceProtocol.send`'s signature:** `FakeLLMService` (ChatLifecycleTests.swift:177-217) and every Phase 2 pin depends on it; history/chips/prefs enter through init params, `onAppear` seams, or `StressLLMService` internals only.
- **Local balance/session arithmetic:** the Phase 2 convergence rules (server-authoritative credits) extend to sessions — never synthesize a session id client-side; ids come from POST response or SSE metadata only.
- **Deleting chat history in `deleteAllMeasurements`:** snapshots-only path (Pattern 4 scope note).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authenticated JSON requests | New request builders per endpoint | `StressAPIClient.authorizedRequest(path:method:body:accept:)` | Bearer injection, Content-Type, 90s timeout already uniform [VERIFIED: StressAPIClient.swift:31-51] |
| Error taxonomy per group | Shared mega-error enum | Per-group `...APIError` enums (Credits pattern) | Isolates decode/401 semantics; matches `LocalizedError` convention |
| Settings section UI | New card/row components | `sectionLabel` + `SettingsCard` + `navRow`/picker rows + `hairlineDivider` | Established surface pattern (Phase 1 Google row, Phase 2 credit rows) [VERIFIED: SettingsView.swift:34-47, 371-447] |
| Chip tap → completion | Calling `POST /quick-actions` | Existing `send(text)` → `/chat` | Locked: credit-metered, session-persisted, streamed |
| Pagination loop | Custom cursor protocol | `limit`/`offset` query params the route already implements | Backend contract: `limit` (default 20), `offset` (default 0) [VERIFIED: sessions.ts:10-11] |
| Session identity persistence | New storage keys | `stressChatSessionId` UserDefaults via `StressLLMService` | Existing seam; init restores, `apply(metadata:)` writes, `resetSession()` clears |

**Key insight:** every cross-cutting mechanism this phase needs already exists — Bearer requests, DTO+error extension shape, app-scope `@Observable` services, environment injection, `onAppear` service wiring, deletion-phase orchestration with injectable fakes. The genuinely new logic is small: one trend-direction reversal, one pagination loop, and three decoders.

## Runtime State Inventory

> This IS partly a cleanup/migration phase (Supabase remnant removal + server-wipe semantics change). All five categories answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data (client) | `UserDefaults` key `"stressChatSessionId"` (StressLLMService.swift:31) — **never cleared on factory reset**: `StressLLMService.clearStoredCredentials()` (:35-37) has zero call sites (verified by grep this session); `clearCredentialsAndSharedCaches` (DataDeleterService.swift:480-484) calls only `FirebaseAuthService.clearStoredCredentials()`, whose sweep removes legacy keys `supabaseSessionExpiresAt`/`supabaseChatSessionId` but not `stressChatSessionId` [VERIFIED: FirebaseAuthService.swift:116-125] | Code edit: the wipe step (or `clearCredentialsAndSharedCaches`) clears `stressChatSessionId`; restore tolerates 404 regardless (defense for already-dangling ids) |
| Stored data (server) | `chat_sessions` rows (id, user_id, title, stress_context, model_used, is_archived, created_at, updated_at) + `chat_messages` (id, session_id, role, content, stress_data_snapshot, tokens_used, created_at) [VERIFIED: migrations/20260812000004_chat_tables.sql:1-26]; `user_preferences` rows (defaults `language='en'`, `coaching_style='supportive'`) [VERIFIED: migrations/20260812000003_user_preferences.sql:4-5] | No migration. Factory reset deletes per-session via existing API (CASCADE removes messages [VERIFIED: chat_tables.sql:20 `ON DELETE CASCADE`]). Existing sessions created pre-Phase-3 carry title `'New Conversation'` (backend default) — restore must not assume titled rows |
| Live service config | Deployed backend at `https://stress-api.dropitx.site` — **live, verified this session** (`GET /health` → 200, curl). No per-phase backend config changes | None (UAT rides the deployment) |
| OS-registered state | None — no new launchd/Task Scheduler/pm2 registrations; Firebase SDK session lives in Keychain (untouched) | None — verified by phase scope (no new OS integrations) |
| Secrets/env vars | None new. `STRESS_API_BASE_URL` 3-tier resolution unchanged [VERIFIED: StressAPIConfig.swift:9-14, fallback `https://stress-api.dropitx.site`]; local backend tests need `DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/stress_app` exported per command | None (test-env only) |
| Build artifacts | Supabase sweep list in `.gitignore` line 164 = `supabase/.temp/` [VERIFIED: `sed -n '164p'` this session] and `design/screens/25-about.html` line 207 = `<div class="oss-row"><span class="name">Supabase LLM</span><span class="ver">2.4</span></div>` [VERIFIED: `sed -n '207p'`]. App-source sweep (grep `(?i)supabase` over `StressMonitor/`): exactly two hits — `FirebaseAuthService.swift:119-122` (keychain sweep strings) and `DataDeletionConsolidationTests.swift` (tests pinning it) — both KEEP per locked decision | Code edits: delete `.gitignore` line 164 (+ its now-orphaned blank line if one becomes adjacent); replace/remove the 25-about.html OSS row (what replaces it — e.g. "Firebase 11" reflecting the current stack — is a trivial planner pick; row removal is also acceptable). Nothing else in source/config |

## Common Pitfalls

### Pitfall 1: Postgres TIMESTAMPTZ JSON breaks naive Date decoding
**What goes wrong:** `created_at`/`updated_at` serialize as ISO-8601 **with fractional seconds** (e.g. `2026-08-23T07:39:53.953Z`). `JSONDecoder`'s default Date strategy cannot decode any ISO string, and `.iso8601` **fails on fractional seconds** — decode throws and the whole messages array fails.
**Why it happens:** postgres.js serializes timestamptz with millisecond precision; Swift's `.iso8601` strategy uses a formatter without `.withFractionalSeconds`.
**How to avoid:** decode date fields as `String` — the exact precedent is `CreditBalance.freeResetAt: String?` with doc comment "ISO-8601 timestamp string as delivered by the backend" [VERIFIED: Models/CreditBalance.swift:15-16]. `ChatMessage.timestamp` is `Date` — at restore time either use `Date()` (display ordering comes from the server's `created_at asc` order anyway) or parse with `ISO8601DateFormatter` configured `.withFractionalSeconds`. Recommend: DTO keeps String; mapping uses `Date()`; keep timestamps cosmetic (bubble `timestampText` at ChatBottomSheetView.swift:521-525).
**Warning signs:** `decodingFailure`-style errors only in live/UAT runs (URLProtocol test fixtures hand-written without fractional seconds would pass while production breaks — **write fixtures with fractional seconds**).

### Pitfall 2: Chat-open fetches must not race the user or each other
**What goes wrong:** restore lands after the user already sent a message → overwritten conversation; chips fetch lands after sheet dismissed → state written to a dead VM; both fetches firing on every re-appear duplicates work.
**Why it happens:** `onAppear` can fire more than once per presentation (navigation transitions), and network latency is unbounded.
**How to avoid:** apply restore only when `messages.isEmpty`; make both fetches idempotent per VM (guard flags); `onDisappear` already cancels streaming (:57) — cancel in-flight fetch tasks the same way or let them complete harmlessly into a dismissed VM.
**Warning signs:** UAT history-restore test flaking when the tester types immediately.

### Pitfall 3: Dangling `stressChatSessionId` → 404 on restore
**What goes wrong:** a factory reset (or server-side deletion) leaves `stressChatSessionId` pointing at a nonexistent session; `GET /sessions/{id}/messages` returns 404 `{error: "Session not found"}` [VERIFIED: sessions.ts:50-51] and restore either errors visibly or bricks chat-open.
**Why it happens:** the key is never cleared today (Runtime State Inventory); also any pre-Phase-3 install carries it.
**How to avoid:** treat 404 as "start fresh": clear the stored id and render an empty chat. This is mandatory regardless of the wipe fix, because it also covers sessions deleted server-side by other means.
**Warning signs:** UAT script's reset-then-chat step failing.

### Pitfall 4: The wipe must not make factory reset impossible offline/signed-out
**What goes wrong:** `getIDToken()` throws when no Firebase user; a network error aborts the whole reset — either makes factory reset unavailable exactly when a user wants to nuke everything.
**Why it happens:** adding an awaited network phase to `performFactoryReset` couples local deletion to server availability.
**How to avoid:** distinguish failure classes (recommended): auth-unavailable → log + skip the server wipe (local deletion still happens; matches the "reset anyway" expectation); network/server error → planner decision — the CloudKit precedent fails the whole reset on CloudKit error (:437-439 maps to `DeletionError.cloudKitError`), so failing loudly on a server error is consistent; but skipping-with-log keeps the DATA-01 bar honest for the local half. Decide once in the plan; both are defensible. Whatever is chosen, clear `stressChatSessionId` unconditionally at the end of reset.
**Warning signs:** factory reset UAT on airplane mode.

### Pitfall 5: Session-creation ordering and the empty-titled-session orphan
**What goes wrong:** if `POST /sessions` and the first `/chat` race (or creation happens after send), the backend auto-creates a *second* session (no `session_id` → INSERT with default title) and the titled session stays empty forever — future history list shows a ghost row.
**Why it happens:** backend creates a session on any `/chat` without `session_id` [VERIFIED: chat.ts:47-59].
**How to avoid:** creation strictly precedes `sendChat` inside the same `Task` in `StressLLMService.send` (Pattern 5); fail-soft falls back to auto-creation (one untitled session, no orphan).
**Warning signs:** two sessions per first message in the UAT account (check via `GET /sessions`).

### Pitfall 6: `DELETE /sessions` returns success for other users' sessions
**What goes wrong:** nothing exploitable, but tests assuming an ownership error will mis-read: DELETE is scoped `where id = ${id} and user_id = ${uid}` and returns `{success: true}` even when 0 rows matched — only `GET /:id/messages` 404s on non-ownership [VERIFIED: sessions.ts:35-43 vs :45-51, and the route test's "DELETE requires id and removes session" asserts success only for owned].
**How to avoid:** iOS treats `{success: true}` as done; no extra verification round-trip. Test fixtures should not assert 404-on-DELETE.
**Warning signs:** over-engineered delete verification calls.

### Pitfall 7: `PUT /preferences` 400 on empty payloads + silent field filtering
**What goes wrong:** sending `{}` (or only unknown fields) returns 400 `{error: "No valid fields to update"}`; sending `user_id` or arbitrary keys is silently ignored (the route test proves `user_id: "hax"` is dropped) [VERIFIED: preferences.ts:25-40 + preferences.test.ts:31-39].
**How to avoid:** iOS always PUTs exactly one known field per update (`{"language": ...}` or `{"coaching_style": ...}`) — the per-field local-writer-wins model makes this natural. Never send the full row back.
**Warning signs:** a "save all prefs" method in PreferencesService.

### Pitfall 8: Coaching-style values are a closed set; language is free TEXT
**What goes wrong:** the Settings picker offering a style the backend rejects stores fine (column is TEXT) but diverges from `StressContext.coaching_style`'s type union and the quick-actions route's expectations.
**Why:** `coaching_style` is typed `"supportive" | "direct" | "educational"` in `StressContext`/`UserPreferences` [VERIFIED: lib/types.ts:32, 58] and defaults `'supportive'` in the DB; `language` is plain TEXT default `'en'` [VERIFIED: migrations/20260812000003:4-5].
**How to avoid:** hard-code the three style cases in the picker (an enum mirroring the union); language picker offers a small fixed set of codes (which languages is a product pick — see Assumptions A3) with the current value displayed even if outside the set.
**Warning signs:** free-text coaching-style entry.

### Pitfall 9: New test files silently don't compile (pbxproj registration)
**What goes wrong:** dropping `*.swift` into `StressMonitorTests/` does nothing — the target uses an explicit PBXSourcesBuildPhase; new files need the 4-line pattern (PBXBuildFile + PBXFileReference + group membership + Sources entry, `F1A1B2C3D4E5...A00x/B00x` ID scheme) [VERIFIED: 01-03-SUMMARY.md — "New test files dropped into the folder are NOT auto-compiled"; current state: 28 files, all registered, per 02-VERIFICATION truth 5].
**How to avoid:** every new-suite task includes the pbxproj edit; the phase gate re-checks registration (orphan sweep).
**Warning signs:** suite count not increasing in `xcodebuild` output.

### Pitfall 10: Parallel testing flag
**What goes wrong:** default `xcodebuild test` fails on this host (XCTestDevices/Mach -308) [VERIFIED: STATE.md Phase 01 decision].
**How to avoid:** every test invocation carries `-parallel-testing-enabled NO` — already baked into `.planning/config.json` `test_command`.

## Code Examples

### Backend contracts (verbatim, read this session)

**GET /sessions — list with limit/offset** [VERIFIED: stress-app-be/src/routes/sessions.ts:8-19]:
```typescript
app.get("/", async (c) => {
  const uid = c.get("uid");
  const limit = parseInt(c.req.query("limit") ?? "20");
  const offset = parseInt(c.req.query("offset") ?? "0");
  const sessions = await sql`
    select * from chat_sessions
    where user_id = ${uid}
    order by updated_at desc
    limit ${limit} offset ${offset}
  `;
  return c.json({ sessions, limit, offset });
});
```
Session row shape = `select *` of [VERIFIED: migrations/20260812000004_chat_tables.sql:1-10]: `id UUID, user_id TEXT, title TEXT (NOT NULL DEFAULT 'New Conversation'), stress_context JSONB (DEFAULT '{}'), model_used TEXT, is_archived BOOLEAN, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ`. iOS DTO decodes only `id`/`title` (+ dates as String) — Codable ignores the rest.

**POST /sessions — create, returns full row with 201** [VERIFIED: sessions.ts:21-33]:
```typescript
const body = await c.req.json().catch(() => ({}));
const [session] = await sql`
  insert into chat_sessions (user_id, title, stress_context)
  values (${c.get("uid")}, ${body.title ?? "New Conversation"}, ${sql.json(body.stress_context ?? {})})
  returning *
`;
return c.json(session, 201);
```

**DELETE /sessions?id= — per-id delete** [VERIFIED: sessions.ts:35-43]:
```typescript
const id = c.req.query("id");
if (!id) return c.json({ error: "Session id is required" }, 400);
await sql`delete from chat_sessions where id = ${id} and user_id = ${c.get("uid")}`;
return c.json({ success: true });
```
Messages cascade [VERIFIED: chat_tables.sql:20 — `session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE`].

**GET /sessions/:id/messages — ordered history; 404 on not-owned** [VERIFIED: sessions.ts:45-59]:
```typescript
if (!session) return c.json({ error: "Session not found" }, 404);
const messages = await sql`
  select id, session_id, role, content, tokens_used, created_at
  from chat_messages where session_id = ${id} order by created_at asc
`;
return c.json({ messages });
```
`role` values: `('user', 'assistant', 'system')` [VERIFIED: migrations/20260812000001_enums_and_helpers.sql:1 — `CREATE TYPE message_role AS ENUM ('user', 'assistant', 'system');`] — matches iOS `ChatRole` exactly [VERIFIED: Models/ChatMessage.swift:6-10].

**GET/PUT /preferences — allowlist** [VERIFIED: preferences.ts:5-40]:
```typescript
const ALLOWED_FIELDS = ["display_name", "language", "coaching_style",
  "notification_enabled", "stress_alert_threshold", "theme", "custom_settings"] as const;
// GET → c.json(prefs) — full row; PUT → filter body to ALLOWED_FIELDS;
// if (Object.keys(updates).length === 0) return c.json({ error: "No valid fields to update" }, 400);
// update ... returning * → c.json(prefs)
```
GET always returns a row: the auth middleware provisions `user_preferences` transactionally on the first authenticated request (`insert into user_preferences (user_id) values (...) on conflict (user_id) do nothing`) [VERIFIED: middleware/auth.ts:24-46]. Defaults: `language TEXT NOT NULL DEFAULT 'en'`, `coaching_style TEXT NOT NULL DEFAULT 'supportive'`, `theme 'system'`, `notification_enabled true`, `stress_alert_threshold 75` [VERIFIED: migrations/20260812000003_user_preferences.sql:1-11].

**GET /quick-actions — deterministic suggestions** [VERIFIED: quick-actions.ts:17-42]:
```typescript
app.get("/", (c) => {
  const q = (name: string) => c.req.query(name);
  const stressLevel = parseInt(q("stress_level") ?? "50");
  const context: Partial<StressContext> = {
    stress_level: stressLevel,
    stress_category: stressLevel >= 75 ? "high" : stressLevel >= 50 ? "moderate" : stressLevel >= 25 ? "mild" : "relaxed",
    active_minutes: q("active_minutes") ? parseInt(q("active_minutes")!) : null,
    sleep_quality: q("sleep_quality") ? parseInt(q("sleep_quality")!) : null,
    hrv_trend: (q("hrv_trend") as StressContext["hrv_trend"]) ?? null,
    language: q("language") ?? "en",
    coaching_style: (q("coaching_style") as StressContext["coaching_style"]) ?? "supportive",
  };
  return c.json({ quick_actions: suggestQuickActions(context as StressContext) });
});
```
Suggestion rules [VERIFIED: lib/quick-actions.ts:16-52]: stress ≥75 → `breathing` + `grounding`; sleep_quality <50 → `sleep_tips`; active_minutes <15 → `mini_walk`; hrv_trend `declining` → `recovery`; 25≤stress<50 → `resilience`; always `talk`; `slice(0, 4)`; null context → `[talk, breathing]`. Response type: `QuickAction { id: string; title: string; type: "exercise" | "technique" | "tips" | "conversation" }` [VERIFIED: lib/types.ts:49-53]. **Note for fetch params:** iOS `StressContextPayload` sends `hrvTrend: nil`, `sleepQuality: nil`, `activeMinutes: nil` today [VERIFIED: StressContextPayload.swift:127-133] — the fetch can pass `stress_level` (from `stressResult`), `language`, `coaching_style` only; suggestion rules degrade gracefully (breathing/grounding/talk by stress level). No iOS change needed to compute hrv_trend.

**POST /quick-actions — the unmetered route (NEVER wire in iOS)** [VERIFIED: quick-actions.ts:44-61]:
```typescript
const prompt = getQuickActionPrompt(action_id);
if (!prompt) return c.json({ error: `Unknown action: ${action_id}` }, 400);
const response = await chatCompletion([{ role: "user", content: prompt }], model, systemPrompt, 512);
return c.json({ action_id, response, model_used: model });
```
No `deductCredit` call anywhere in the route (verified by reading the full file) — this is the Phase-2-revenue bypass the CONTEXT locks out; the backend note/issue covers metering or gating it.

**/chat session semantics (context for Pattern 5)** [VERIFIED: chat.ts:47-59]:
```typescript
let sessionId: string;
if (body.session_id) { sessionId = body.session_id; }
else {
  const [session] = await sql`insert into chat_sessions (user_id, stress_context) values (...) returning id`;
  sessionId = session.id as string;
}
```
Terminal SSE metadata carries `session_id` [VERIFIED: chat.ts:108-117] and `StressLLMService.apply(metadata:)` already persists it [VERIFIED: StressLLMService.swift:114-118].

### iOS seam (verbatim, read this session)

**The CR-02 bug and fix site** [VERIFIED: StressContextPayload.swift:87-101]:
```swift
let recent = recentHistory.suffix(min(5, max(2, recentHistory.count)))
if recent.count >= 2 {
    let levels = recent.map(\.stressLevel)
    let first = levels.first!
    let last = levels.last!
    let diff = last - first
    if abs(diff) < 5 { trend = "stable" } else if diff > 0 { trend = "increasing" } else { trend = "decreasing" }
```
Caller ordering [VERIFIED: StressRepository.swift:85-96 — `sortBy: [SortDescriptor(\.timestamp, order: .reverse)]` = newest-first], so `diff = last - first = oldest - newest` — inverted. Fix: reverse to chronological before the delta (`let chronological = Array(recent.reversed()); diff = newest - oldest`), keeping the `recent.count >= 2` guard (the force-unwraps are safe only under it — 01-REVIEW CR-02 fix note). Regression test: newest-first input where stress rose over time must yield `stressTrend == "increasing"` (and the mirrored decreasing case); lands in the existing `StressContextPayloadTests.swift` (XCTest file, registered).

**Prefs-fed builder call site** [VERIFIED: ChatViewModel.swift:124-128]:
```swift
let stressContext = StressContextPayload.build(
    stressResult: stressResult, baseline: baseline, recentHistory: recentHistory
)   // ← language/coachingStyle default to "en"/"supportive" today (StressContextPayload.swift:81-82)
```
Phase 3 passes the PreferencesService values. Injection seam: `ChatBottomSheetView.onAppear` already forwards environment-reachable services onto the VM (`viewModel.presentPaywall = ...`, `viewModel.setCreditsConvergenceSink(...)` at :49-54) — a `viewModel.preferences = preferencesService` (or two read-through properties) set there mirrors the established pattern; defaults keep VM behavior unchanged when unset (tests, previews).

**DataDeleter injection seam (the analog to copy)** [VERIFIED: DataDeleterService.swift:44-57]:
```swift
/// Injects a ``CloudKitResetServiceProtocol`` directly — the seam tests use to substitute
/// a failing/cancellable fake instead of a real CKContainer.
init(modelContext: ModelContext, cloudKitResetService: CloudKitResetServiceProtocol,
     repository: StressRepositoryProtocol, logger: DataManagementLogger) { ... }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Supabase Edge Functions (chat + declared-only sessions/preferences/credits/quick-actions URLs) | Standalone Deno/Hono backend, all endpoints live and consumed (Phase 3 completes the set) | v1.1 Phases 1-3 | After Phase 3, every OpenAPI endpoint is consumed or has a recorded reason (`POST /quick-actions` note) |
| In-memory-only chat (history lost per sheet dismiss) | Server-persisted rolling session, restored on open | this phase | Chat survives relaunch; DATA-01 wipe now spans server |
| Hardcoded `"en"`/`"supportive"` in the payload builder | PreferencesService-fed values, user-editable in Settings | this phase | One source of truth; backend system prompt actually follows user prefs |
| Static local chips (hardcoded strings in the sheet) | Server-suggested chips with local instant fallback | this phase | Chips react to live stress level |

**Deprecated/outdated (informational, out of locked cleanup scope):** generated planning docs still describe Supabase (`.claude/CLAUDE.md` GSD stack/conventions sections sourced from `.planning/codebase/*.md`, and `.planning/codebase/INTEGRATIONS.md`) — they are generated artifacts, not app source/config; the locked cleanup scope is exactly `.gitignore:164` + `25-about.html:207`. Planner may optionally note them for a future docs regeneration; do NOT edit them in this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `apply(metadata:)`-style persistence (set `currentSessionId` + write UserDefaults) is the correct mechanism for storing the `POST /sessions` id inside `send()` | Pattern 5 | None material — same key, same semantics; only refactor shape changes |
| A2 | Postgres timestamps over the wire carry fractional seconds in this deployment (postgres.js default) — hence String-date DTOs | Pitfall 1 | If a middleware strips them, String dates still decode fine; the cautious design is correct either way (fixtures should include fractional seconds regardless) |
| A3 | The language picker's concrete language set (e.g. en + vi) is a product decision pending user confirmation; codes are free strings backend-side | Pattern 2 / Pitfall 8 | Wrong set = cosmetic; wrong code strings would silently degrade backend prompting — keep codes ISO-like ("en", "vi") |
| A4 | Fail-soft on `POST /sessions` failure (proceed with nil session id → backend auto-creates untitled) is acceptable to the user; they locked the title *mechanism*, not failure semantics | Pattern 5 / Pitfall 5 | If strict-failure preferred, a title-creation outage blocks first chats — planner should ratify the fail-soft choice |
| A5 | Auth-unavailable during factory reset should skip (not fail) the server wipe; server/network errors follow the CloudKit fail-loudly-or-skip decision left to the planner | Pitfall 4 | Inconsistent choice could make reset impossible offline or silently skip the DATA-01 server bar |
| A6 | The 25-about.html OSS row should be replaced with a current-stack entry (or removed) rather than left as-is after de-Supabasing | Runtime State Inventory | Cosmetic design-screen drift only |
| A7 | `.sheet` content closures re-evaluate per presentation, giving a fresh `ChatViewModel`/`StressLLMService` each chat open (basis for "restore on open is naturally idempotent") | Pattern 3 | If any call site kept a persistent VM, restore would need an explicit staleness guard — the `messages.isEmpty` guard covers it regardless |

## Open Questions

1. **Which surface hosts the chips swap — string block or `QuickActionChipsView`?**
   - What we know: the live chips are `defaultQuickReplies: [String]` (ChatBottomSheetView.swift:355-357); `QuickActionChipsView`/`ChatQuickActions`/`sendQuickAction` are currently unused (verified by grep — definitions only, no call sites).
   - What's unclear: CONTEXT references `ChatQuickActions` as "the existing local static set renders instantly" and "`QuickActionChipsView` UI unchanged" — the locked *behavior* is unambiguous, the component wiring is not.
   - Recommendation: implement the swap in the existing `quickRepliesSection` block (option a — smallest diff, taps already ride `sendMessage()`), OR route through `QuickActionChipsView` + `sendQuickAction` if the planner prefers activating the designed component. Both satisfy the lock; pick one explicitly in the plan.
2. **Factory-reset failure semantics for the server wipe** (Pitfall 4 / A5) — skip-on-auth-unavailable is strongly recommended; server-error handling should match the CloudKit precedent (fail the reset) or document the skip. One plan decision.
3. **Where does the backend metering note live?**
   - What we know: backend repo has a GitHub remote (`git@github.com-phuongddx:phuongddx/stress-app-be.git`, verified) and its own `.planning/ROADMAP.md` (a separate hardening milestone, phases 1-5, none covering quick-actions metering).
   - Recommendation: a GitHub issue on phuongddx/stress-app-be ("meter or gate POST /quick-actions — 512-token completion with no deductCredit") is the cleanest cross-repo record; fallback is a short note file in the backend repo's `docs/`. The iOS phase only records it — no route changes (locked).
4. **Language picker contents** (A3) — needs the user's language list before UI finalization; `checkpoint:human-verify` candidate if not decided in planning.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Deployed backend `https://stress-api.dropitx.site` | UAT script (history restore, prefs round-trip, chip fetch) | ✓ verified live this session (`GET /health` → 200) | deployed state incl. Phase-2 migrations | local `deno task dev` |
| Xcode + simulator | builds, full suite, Release build | ✓ | 26.3 / iPhone 17 destination | any booted iPhone-family device |
| Deno | backend suite gate | ✓ | 2.7.5 (`/opt/homebrew/bin/deno`) | — |
| Local test postgres on 127.0.0.1:5433 | backend `deno test` gate | ✗ **DOWN** (verified: `pg_isready -p 5433` no response) | homebrew `postgresql@15`, datadir `/tmp/stress-pg-0206`, 8 migrations applied | restart per 02-06 deviation notes before the gate; do NOT point tests at any remote DB |
| Firebase project (GoogleService-Info.plist) | auth for all new endpoints | ✓ (Phase 1, gitignored, placed) | Firebase 11.x SDK | — |
| Git branch | phase work | ✓ `gsd/v1.1-backend-api-migration` (51 commits ahead of origin/main, not pushed — STATE.md carry-over) | — | decide push timing before milestone close (pre-existing item) |

**Missing dependencies with no fallback:** none that block coding/testing.
**Missing dependencies with fallback:** local test postgres → restart the 02-06 instance (the only supported path for the backend-suite gate).

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — section required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`) for new suites (+ legacy XCTest files kept as-is), via xcodebuild |
| Config file | none — target membership IS the config (explicit PBXSourcesBuildPhase; Pitfall 9's 4-line registration per new file) |
| Quick run command | `xcodebuild test -scheme StressMonitor -project StressMonitor/StressMonitor.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:StressMonitorTests/<Suite> -parallel-testing-enabled NO` |
| Full suite command | `xcodebuild test -scheme StressMonitor -project StressMonitor/StressMonitor.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` (baseline: 97 tests / 17 suites green at Phase-2 close; 28 registered files) |
| Release build | `xcodebuild build -scheme StressMonitor -project StressMonitor/StressMonitor.xcodeproj -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17'` (exit 0 at Phase-2 close) |
| Backend suite | `cd /Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be && DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/stress_app deno test --allow-env --allow-net --allow-read src/` (17 tests / 50 steps at Phase-2 close; requires the 5433 instance restarted) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| derived-SES-01 (client half) | `fetchMessages` decodes `{messages:[{id,session_id,role,content,tokens_used,created_at}]}` (fixture WITH fractional-second timestamps); 404 mapped to a typed case; Bearer injected | unit — URLProtocol stub (`RequestCaptureURLProtocol` pattern; `MockAuthService(token:)` + `https://api.test` base) | `... -only-testing:StressMonitorTests/StressAPIClientSessionsTests` | ❌ Wave 0 |
| derived-SES-01 (VM half) | restore-on-open populates `messages` only when empty; 404 clears the session id and leaves chat empty; send-then-restore does not clobber | unit — injected fake history provider (FakeLLMService analog) | `... -only-testing:StressMonitorTests/ChatHistoryRestoreTests` | ❌ Wave 0 |
| derived-SES-02 | `createSession(title:)` posts `{title, stress_context}` to `sessions`, decodes 201 row id; `StressLLMService.send` with nil session creates then sends with the id; creation failure falls soft to nil id | unit — URLProtocol + a StressLLMService-level test with stubbed client responses | `... -only-testing:StressMonitorTests/StressAPIClientSessionsTests` (+ service test in same file or ChatHistoryRestoreTests) | ❌ Wave 0 |
| derived-SES-03 | `performFactoryReset` wipes server first (list pages → delete each id → loop until empty/cap), clears `stressChatSessionId`, skips cleanly on auth-unavailable | unit — fake `ServerSessionWiping` recording calls; `DataDeletionConsolidationTests` extended for the defaults-key clear | `... -only-testing:StressMonitorTests/DataDeleterServerWipeTests` and `.../DataDeletionConsolidationTests` | ❌ Wave 0 / ✅ (extend existing) |
| derived-PREF-01 | `getPreferences` decodes `language`/`coaching_style` (extra keys ignored); `updatePreferences` PUTs exactly one field; 400 on empty payload mapped | unit — URLProtocol | `... -only-testing:StressMonitorTests/StressAPIClientPreferencesTests` | ❌ Wave 0 |
| derived-PREF-01/02 (service) | `PreferencesService`: seed-once GET; optimistic set + PUT per field; revert on PUT failure; builder receives current values | unit — injected fake/URLProtocol client | `... -only-testing:StressMonitorTests/PreferencesServiceTests` | ❌ Wave 0 |
| derived-QA-01 (client half) | `getQuickActions(stressLevel:language:coachingStyle:)` builds the query string, decodes `{quick_actions:[{id,title,type}]}` | unit — URLProtocol; assert request URL query + Bearer | `... -only-testing:StressMonitorTests/StressAPIClientQuickActionsTests` | ❌ Wave 0 |
| derived-QA-01 (VM half) | chips state starts at the local set; server fetch swaps content; tap sends the id-mapped prompt through `send` (credit-metered `/chat`); `POST /quick-actions` appears nowhere in iOS sources | unit — fake fetcher + FakeLLMService recording prompts; grep gate for `quick-actions` POST usage | `... -only-testing:StressMonitorTests/ChatHistoryRestoreTests` (or a dedicated quick-actions VM suite in the same file) + `grep -rn "quick-actions" StressMonitor/StressMonitor` review | ❌ Wave 0 |
| derived-CLEAN-01 | `.gitignore` has no `supabase` line; `25-about.html` has no Supabase row; app-source Supabase mentions are exactly the two KEEP sites (FirebaseAuthService sweep + DataDeletionConsolidationTests) | grep gate (observable signal, not a test file) | `grep -rni supabase StressMonitor/StressMonitor StressMonitor/StressMonitorTests .gitignore design/screens/25-about.html` → only KEEP hits | n/a (manual/grep) |
| derived-CR02 | newest-first `recentHistory` with rising stress yields `stressTrend == "increasing"` (mirror for decreasing; stable under ±5) | unit — existing XCTest file | `... -only-testing:StressMonitorTests/StressContextPayloadTests` | ✅ (add cases) |
| AUTH-03 (regression) | send/cancel/partial-preservation, 402→paywall, SSE parse, credits convergence all unchanged | existing suites stay green | `... -only-testing:StressMonitorTests/ChatLifecycleTests` etc. → then full suite at wave merge | ✅ |

### Sampling Rate
- **Per task commit:** targeted `-only-testing` suite(s) touched by the task + `StressContextPayloadTests`/`ChatLifecycleTests` when their files are edited — always with `-parallel-testing-enabled NO`
- **Per wave merge:** full iOS suite (exit 0) + Release build for waves touching app code
- **Phase gate (locked):** full `StressMonitorTests` suite via `xcodebuild test -parallel-testing-enabled NO`, targeted new-feature suites, `xcodebuild build -configuration Release`, backend suite green (after restarting the 5433 postgres), and the UAT script (history restore across relaunch, prefs round-trip via Settings → backend, chip fetch on chat open) — live checks ride the deployed backend, like Phase 2's smoke
- **Observable-signal sampling points (Nyquist):** (1) URL-level: request method/path/query/body + Bearer header per new endpoint (URLProtocol captures); (2) decode-level: DTO fields from fixtures with fractional-second dates; (3) state-level: `currentSessionId`/UserDefaults after create-then-send; `messages` content/order after restore; chips model before/after swap; PreferencesService values after seed/update/failure; (4) orchestration-level: fake-wiper call sequence (list→delete…→list-empty) + `stressChatSessionId` cleared; (5) system-level (UAT): relaunch persistence, server-side verification via `GET /sessions`/`GET /preferences`, 402 path still presenting the paywall.

### Wave 0 Gaps
- [ ] `StressMonitorTests/StressAPIClientSessionsTests.swift` — derived-SES-01/02 client half (+ 4-line pbxproj registration)
- [ ] `StressMonitorTests/StressAPIClientPreferencesTests.swift` — derived-PREF-01 client half
- [ ] `StressMonitorTests/StressAPIClientQuickActionsTests.swift` — derived-QA-01 client half
- [ ] `StressMonitorTests/PreferencesServiceTests.swift` — derived-PREF-01/02 service half
- [ ] `StressMonitorTests/ChatHistoryRestoreTests.swift` — derived-SES-01 VM half + QA VM half (+ FakeLLMService reuse or a fake history/chips provider)
- [ ] `StressMonitorTests/DataDeleterServerWipeTests.swift` — derived-SES-03
- [ ] Restart local postgres on 127.0.0.1:5433 (02-06 instance) before the backend-suite gate — environment, not a file

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high` (`.planning/config.json`).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Firebase Bearer per request via existing `AuthServiceProtocol`/`authorizedRequest`; 401 → typed `.unauthorized` (Credits pattern) on all three new groups |
| V3 Session Management | yes | Token refresh margin already in `FirebaseAuthService.getIDToken`; no new credential storage; `stressChatSessionId` is non-secret state (a server-scoped id), cleared on reset in this phase |
| V4 Access Control | yes | Server enforces per-uid scoping on every route (sessions/preferences scoped by `c.get("uid")` from the verified token — verified in route sources); iOS never sends a user id; DELETE ownership is server-enforced (Pitfall 6) |
| V5 Input Validation | yes | iOS decodes typed DTOs (Codable) and sends only allowlisted fields (`language`/`coaching_style`, one per PUT); session title is user text truncated client-side and stored as TEXT — a *future* history list must treat it as untrusted at render time (note for the deferred multi-session UX) |
| V6 Cryptography | no new surface | TLS via URLSession; no crypto added |
| V14 Config | yes | No secrets client-side; `STRESS_API_BASE_URL` 3-tier resolution unchanged |

### Known Threat Patterns for iOS + sessions/preferences endpoints

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Session IDOR (fetch/delete another user's session) | Elevation | Backend scopes every query by the token-derived uid (`where id = ... and user_id = ${uid}` — verified); messages route 404s non-owned; iOS adds nothing |
| Unmetered-completion abuse via `POST /quick-actions` | Tampering (revenue) | Route exists on the backend with no `deductCredit`; iOS never calls it (locked + grep gate); backend note/issue filed for metering/gating |
| Dangling session id after reset leaking prior identity into a fresh install | Information disclosure | Wipe clears `stressChatSessionId`; restore 404-tolerant (Pitfalls 3/4) |
| Preference poisoning via extra PUT fields | Tampering | Server-side ALLOWED_FIELDS filter (verified: `user_id: "hax"` dropped by route test); iOS sends single known fields only |
| Title injection into a future history list | Tampering (stored) | Deferred surface; title persisted server-side as TEXT — render-time escaping when the multi-session UI ships (deferred ideas list) |

## Project Constraints (from CLAUDE.md)

Extracted from repo-root `~/.claude/CLAUDE.md` + `.claude/CLAUDE.md` (loaded this session) — directives the planner must honor:

- **Think before coding / simplicity first / surgical changes / goal-driven execution** — every changed line traces to a CONTEXT decision; no speculative multi-session UI, no caching layer, no extra pref fields.
- **Conventions (from `.claude/CLAUDE.md` GSD sections):** one primary type per file, filename == type name; extensions `Type+Feature.swift`; protocols in `Services/Protocols/` (exceptions beside implementations — the API-error enums ride their extension files like `+Credits`); 4-space indent; `// MARK: -` dividers; `@Observable @MainActor final class` ViewModels; `Sendable` protocols with injected fakes; per-subsystem `LocalizedError` enums; ViewModels surface `errorMessage: String?`; `try!` forbidden (mind CR-02's existing force-unwraps — keep them guarded); DesignTokens for new UI; `HapticManager` for feedback; `#Preview` for new views.
- **Tests:** Swift Testing suites in `StressMonitorTests/`, registered in project.pbxproj (4-line pattern), `xcodebuild test -parallel-testing-enabled NO`.
- **GSD workflow enforcement:** phase work runs under `/gsd-execute-phase`; this research is the planning input, no code edits here.
- **Operational (STATE.md/config.json):** `commit_docs: true`; test/build commands as pinned in Validation Architecture; TDD mode on (RED→GREEN per task for new logic); branch `gsd/v1.1-backend-api-migration` active.

## Sources

### Primary (HIGH confidence — read in-repo this session)
- Backend `stress-app-be/src/routes/`: `sessions.ts`, `preferences.ts`, `quick-actions.ts`, `chat.ts` (+ `sessions.test.ts`, `preferences.test.ts`, `quick-actions.test.ts` pinning each contract)
- Backend `src/lib/types.ts` (StressContext, QuickAction, UserPreferences, ChatSession), `src/lib/quick-actions.ts` (suggestion rules + prompt map), `src/middleware/auth.ts` (provisioning), `src/app.ts` (route mounts), `deno.json`, `docker-compose.yml`
- Backend `migrations/`: `20260812000001_enums_and_helpers.sql` (message_role), `20260812000003_user_preferences.sql`, `20260812000004_chat_tables.sql` (CASCADE)
- iOS: `Services/API/StressAPIClient.swift`, `StressAPIClient+Credits.swift`, `StressAPIConfig.swift`; `Services/LLM/StressLLMService.swift`, `SSEParser.swift`, `LLMServiceProtocol.swift`, `StressContextPayload.swift`, `ChatContextBuilder.swift`, `ChatQuickActions.swift`; `ViewModels/ChatViewModel.swift`; `Views/Chat/ChatBottomSheetView.swift`, `QuickActionChipsView.swift`; `Views/Settings/SettingsView.swift`, `SettingsViewModel.swift`, `DataManagement/DataManageView.swift`; `Services/DataManagement/DataDeleterService.swift`; `Services/Auth/FirebaseAuthService.swift`; `Services/Credits/CreditService.swift`; `Models/ChatMessage.swift`, `CreditBalance.swift`; `Services/Repository/StressRepository.swift` (fetchRecent ordering); `StressMonitorApp.swift` (environment wiring); `Theme/AppIconSystem.swift`
- Tests: `StressAPIClientCreditsTests.swift` (URLProtocol + MockAuthService + RequestCaptureURLProtocol pattern), `ChatLifecycleTests.swift` (FakeLLMService, 402-paywall pin), `StressContextPayloadTests.swift`, `DataDeletionConsolidationTests.swift` (KEEP-list)
- `.planning/`: `STATE.md`, `config.json`, `ROADMAP.md` (v1.1 Phase 3 entry), Phase 01 `01-REVIEW.md` (CR-02 verbatim), Phase 02 `02-RESEARCH.md` (format precedent), `02-VERIFICATION.md` (baseline counts, backend test command, Release-build precedent), `02-06-SUMMARY.md`/`02-08-PLAN.md` (5433 postgres provenance)
- Environment probes this session: deployed `/health` → 200; `pg_isready -p 5433` → down; `deno 2.7.5`; branch `gsd/v1.1-backend-api-migration`; backend git remote present

### Secondary (MEDIUM confidence)
- None — no claim rests on an external web source.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; all system-framework work following in-repo patterns
- Architecture: HIGH — every contract quoted verbatim with file:line from both repos read this session; the one wiring discrepancy (chips surface) is documented with evidence rather than assumed away
- Pitfalls: HIGH — each grounded in source (fractional-second dates inferred from postgres.js serialization and defensively designed — see A2; all others verified)
- Regression surface: HIGH — Phase 2 pins enumerated (ChatLifecycleTests, SSEParserTests, PaywallOutOfCreditsGuardTests, CreditPurchaseFlowTests, StressAPIClientTests) and none require signature changes

**Research date:** 2026-08-23
**Valid until:** 2026-09-23 (stable domain; backend contract pinned by deployed code — re-verify if the backend repo's hardening milestone changes routes, esp. its Phase 2 reserve/refund rewrite touching chat.ts)

## RESEARCH COMPLETE

# Phase 3: Sessions, Preferences, Quick Actions + Cleanup - Context

**Gathered:** 2026-08-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrate the remaining three backend endpoints into the iOS app and close out the v1.1 migration: server-side chat history (`GET/POST/DELETE /sessions`, `GET /sessions/{id}/messages`), preference sync (`GET/PUT /preferences`), and server-driven quick-action suggestions (`GET /quick-actions`); remove the residual Supabase artifacts; fold in the deferred 01-REVIEW CR-02 trend-direction fix; and run final integration testing (full suite + Release build + backend suite + UAT script).

This phase completes milestone v1.1: after it, every backend endpoint in the OpenAPI spec is either consumed by the app or deliberately unused with a recorded reason (`POST /quick-actions` — unmetered completion route).

</domain>

<decisions>
## Implementation Decisions

### Sessions — History Model & Session Semantics
- Continuous history restore: keep the single rolling session (`stressChatSessionId` in UserDefaults); on chat open, fetch `GET /sessions/{id}/messages` for the current session and render. No session-picker UI this phase.
- Server-authoritative message store: fetch on open, no local SwiftData cache of chat messages (offline chat is already impossible — SSE needs network; matches Phase 2's server-owns-truth precedent).
- Factory reset / delete-all-data wipes server chat history: DataDeleter iterates `GET /sessions` + `DELETE /sessions?id=` per session before the local wipe (DATA-01 "delete actually deletes everywhere" bar).
- Client-side session titles: `POST /sessions` with title = first user message (truncated) before the first chat of a new session, then send its id — no backend change, list-ready for a future history UI.

### Preferences Sync
- Sync the chat-relevant pair only: `language` + `coaching_style`. The other backend fields (display_name, theme, notification_enabled, stress_alert_threshold, custom_settings) have no iOS owner mapping and stay untouched this phase.
- New "AI Coach" section in Settings (language picker + coaching-style choice among the backend's accepted values) — Settings is the established surface (Phase 1 Google row, Phase 2 credit rows). No onboarding change.
- Local-writer-wins per field: `PUT /preferences` on user change; `GET /preferences` once at first sign-in to seed. No timestamped merge (backend has none).
- `StressContextPayload.build` reads language/coachingStyle from the PreferencesService instead of hardcoded `"en"`/`"supportive"` defaults — one source of truth.

### Quick Actions Source & Behavior
- Chips come from `GET /quick-actions` at chat open with live stress context; the existing local static set (`ChatQuickActions`) renders instantly as fallback and is swapped when the fetch lands. No loading state, no empty state.
- Chip taps send their prompt through the existing `/chat` path (`sendQuickAction` → credit-metered, session-persisted, streamed). `QuickActionChipsView` UI unchanged.
- `POST /quick-actions` is deliberately NOT wired: it returns a full 512-token completion with no credit deduction — wiring taps to it would open an unmetered chat path bypassing the Phase 2 revenue model.
- Record a note/issue for stress-app-be to meter or gate `POST /quick-actions`; no iOS change for it.

### Cleanup Scope & Final Integration Testing
- Remove `.gitignore`'s `supabase/.temp/` line and fix `design/screens/25-about.html`'s stale "Supabase LLM 2.4" OSS row.
- KEEP `FirebaseAuthService.clearStoredCredentials()`'s Supabase keychain sweep + `DataDeletionConsolidationTests` — upgrader-protection code that runs only on factory reset, not a remnant.
- Fold in 01-REVIEW CR-02: fix the inverted trend direction in `StressContextPayload.build` (recentHistory newest-first) with a regression test — explicitly deferred to Phase 3 by 02-01's deferral note; the same builder changes for the prefs-fed fields anyway.
- Final integration testing gate: full `StressMonitorTests` suite via `xcodebuild test -parallel-testing-enabled NO`, targeted new-feature suites, `xcodebuild build -configuration Release`, backend suite still green, plus a UAT script covering history restore, prefs round-trip, and chip fetch.
- Server-session wipe tested via protocol-faked `StressAPIClient` unit tests (delete-sessions loop); live-infrastructure verification rides the UAT script like Phase 2's smoke.

### Claude's Discretion
All implementation details not listed above — file layout, type names, view decomposition, error surfaces — per codebase conventions (`Services/API/` extension pattern for StressAPIClient, ViewModels in `ViewModels/`, Settings section pattern).

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StressAPIClient` (`Services/API/StressAPIClient.swift`) — centralized Bearer-injecting HTTP client; `StressAPIClient+Credits.swift` extension is the pattern for new endpoint groups (+Sessions, +Preferences, +QuickActions).
- `SSEParser`/`SSEMetadata` — already parses terminal `session_id`, `credits_remaining`, `model_used`, `quick_actions` (D-05 contract, pinned by `SSEParserTests`).
- `StressLLMService` — owns `currentSessionId` persistence (`stressChatSessionId` UserDefaults key) and tags messages with it.
- `ChatMessage` (`Models/ChatMessage.swift`) — plain struct with `remoteId`/`sessionId`/`isSynced`/`tokensUsed` metadata fields already present.
- `ChatQuickActions` enum + `QuickActionChipsView` — the local fallback chip set and the chips UI (unchanged).
- `StressContextPayload.build` — the builder that gets prefs-fed language/coachingStyle and the CR-02 trend fix.
- `DataDeleterService` — the deletion orchestrator the server-session wipe hooks into.
- `SettingsView`/`SettingsViewModel` + `Views/Settings/Components/` — the surface for the "AI Coach" section.

### Established Patterns
- Services are `@MainActor @Observable final class` behind `Sendable` protocols with injected fakes for tests; API extensions per endpoint group (`StressAPIClient+Credits`).
- Config via 3-tier resolution (Info.plist → env → fallback) — not needed this phase; all endpoints ride the existing base URL.
- Error enums per subsystem conforming to `LocalizedError`; ViewModels surface `errorMessage: String?`.
- Tests: Swift Testing (`@Test`), suite-named files in `StressMonitorTests/`, registered in pbxproj, run with `-parallel-testing-enabled NO`.

### Integration Points
- `ChatViewModel` — gains history restore (fetch on open) and server-driven chip content; `sendQuickAction` path unchanged.
- `StressLLMService` — session creation (POST /sessions before first chat of a new session) rides the existing send flow.
- `ChatBottomSheetView` — presents restored history through the existing messages array (no structural change).
- `SettingsView` — new AI Coach section; `StressContextPayload.build` call sites in `ChatContextBuilder`/`ChatViewModel` pick up prefs-fed values.
- `DataDeleterService` — pre-wipe server-session deletion step.
- Backend repo `/Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be/` — routes already implemented and tested (`sessions.ts`, `preferences.ts`, `quick-actions.ts`); POST /quick-actions metering note to file there.

</code_context>

<specifics>
## Specific Ideas

- Session titles: first user message truncated — chosen so a future history list shows meaningful rows without backend changes.
- The `POST /quick-actions` free-completion concern came from reading `src/routes/quick-actions.ts`: `chatCompletion` is called with no `deductCredit` — flag it in the backend repo, do not work around it in iOS.

</specifics>

<deferred>
## Deferred Ideas

- Multi-session UX (New chat button, browsable past-session list, per-session delete UI) — this phase restores continuous history only; the titled sessions make the list trivial later.
- Syncing the remaining preference fields (display_name, theme, notification_enabled, stress_alert_threshold, custom_settings) — no iOS owner mapping today; revisit when those settings surfaces exist.
- SSE terminal `quick_actions` metadata driving chip refresh after each response — chips refresh on chat open only this phase.
- Backend `POST /quick-actions` metering/gating — backend-repo issue, not iOS scope.

</deferred>

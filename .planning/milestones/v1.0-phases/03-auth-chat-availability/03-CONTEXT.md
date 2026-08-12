# Phase 3: Auth & Chat Availability - Context

**Gathered:** 2026-08-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Make AI Chat honestly unavailable for v1: no credential (expired or otherwise) is extractable from the Release binary, the Chat entry point visibly reflects "unavailable" rather than opening a dead-looking chat, and the streaming lifecycle (mid-stream dismissal, network drop) is provably correct so it is ready when Chat re-enables in v1.1. This phase depends on nothing from Phases 1-2 — the code is fully parallelizable — and is gated only by the pre-resolved D1 decision (Gate Chat off for v1).

The phase covers three requirements: AUTH-01 (no credential in Release binary), AUTH-02 (entry point reflects real auth state — honestly gated off), and AUTH-03 (dismissal cancels + preserves partial text on network drop). AUTH-03's lifecycle code already exists and mostly works; this phase verifies it via TDD rather than rebuilding it.

</domain>

<decisions>
## Implementation Decisions

### Chat Auth Strategy (D1) — PRE-RESOLVED
- **D-01:** Gate Chat off for v1. The Chat UI stays in code (so it can ship in v1.1) but the entry point is visibly and honestly disabled. Concretely: (a) the gitignored `SupabaseSecrets.swift` — which holds an expired guest JWT — must not compile into the Release binary; (b) the two Chat entry points (`ActionView` RippleRecommendationCard CTA, `SettingsView` chat button) reflect a "Coming in v1.1" state rather than opening a sheet that immediately shows "needs backend auth"; (c) the mid-stream dismissal and network-drop preservation code (AUTH-03) keeps working — it is the contract for when Chat re-enables. — **Reversibility:** reversible — gating is a feature flag; removing the gate re-enables Chat.

### Credential Exclusion Mechanism (Claude's discretion, auto-resolved per --auto)
- **D-02:** Exclude the guest-JWT literal from the Release binary by wrapping the entire body of `SupabaseSecrets.swift` in `#if DEBUG ... #endif`. This matches the established pattern already used by `SimulatorHealthKitService.swift` (opens with `#if DEBUG` at line 1) and `StressMonitorApp.swift`/`StressViewModel.swift`. The `PBXFileSystemSynchronizedBuildFileExceptionSet` mechanism was considered and rejected: it is target-membership-scoped (file in target or not), NOT configuration-scoped — there is no per-configuration filter, so it cannot exclude a file from Release while keeping it in Debug. The `#if DEBUG` wrap is simpler (a two-line edit to an existing file), provably correct (the compiler dead-strips the wrapped body in Release), and carries zero build risk: grep confirms `SupabaseSecrets` has zero references in any tracked Swift file, so wrapping it cannot break a Release call site. The file stays on disk, stays gitignored, and DEBUG/local-dev keeps the `SUPABASE_GUEST_JWT` fallback; Release binaries compile the file to an empty translation unit. Verify with `strings` against a Release-built `.app` binary — grep for the JWT prefix `eyJhbGc` and assert zero hits. — **Reversibility:** reversible — removing the two `#if DEBUG`/`#endif` lines restores the old behavior.

### Entry-Point Gating UX (Claude's discretion, auto-resolved per --auto)
- **D-03:** Introduce a single source of truth for Chat availability — a `ChatAvailability` enum (`.disabled(reason)`, `.enabled`) computed at runtime from a `#if DEBUG`-aware flag. In DEBUG, Chat stays available (local dev tests it). In Release, the flag returns `.disabled(.comingSoon)`. The two entry points render the disabled state as a non-interactive card or a sheet that states "AI Coaching arrives in our next update" — not the current developer-facing "Connect Supabase Auth" message that implies a broken setup. The `ChatBottomSheetView.unavailableView` copy is rewritten to be user-facing ("Coming soon" not "needs backend auth"). — **Reversibility:** reversible — flip the flag.

### Mid-Stream Lifecycle (AUTH-03) — already implemented, verify via TDD
- **D-04:** The cancellation and partial-preservation logic already exists and is substantially correct: `ChatViewModel.cancelResponse()` preserves partial text as an assistant message and cancels the streaming `Task`; `ChatBottomSheetView.onDisappear` calls `cancelResponse()` (covers swipe-to-dismiss and Close); `SupabaseLLMService.send` sets `continuation.onTermination = { _ in task.cancel() }` which cancels the URLSession bytes task within one runloop; `ChatViewModel.preservePartialResponseIfNeeded()` covers the network-drop path. The phase's job is to pin these contracts with failing-then-passing tests (TDD) so they cannot regress before v1.1. No structural rewrite — only test coverage and any small fixes the TDD cycle surfaces. — **Reversibility:** reversible — tests are additive.

### Claude's Discretion
- Whether the Release gate uses `#if DEBUG` compile-time condition or a runtime feature flag read from `UserDefaults`/`Info.plist`. Default: compile-time `#if DEBUG` is simpler, zero runtime cost, and matches the existing DEBUG-gating pattern (`StressMonitorApp.swift`, `StressViewModel.swift`, `SimulatorHealthKitService.swift`). A runtime flag is only warranted if QA needs to toggle Chat on for a TestFlight build without recompiling — out of scope for v1.
- Whether the "disabled" entry point hides the card entirely or shows it greyed with a "Coming soon" badge. Default: show-but-disable — the card's purpose is discoverability for v1.1; hiding it entirely loses the announcement.
- Whether `SupabaseLLMService.isAvailable()` is tightened to also return `false` in Release when D-01 gates Chat off. Default: yes — the service's own availability should match the entry-point gate so any future call site is consistent; gate it behind `#if DEBUG` returning `false` in Release, so `ChatViewModel.isAvailable` and `ChatBottomSheetView.unavailableView` render the honest state even if reached.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Primary scope source
- `.planning/ROADMAP.md` lines 98-111 — Phase 3 goal, 4 success criteria, D1 framing
- `.planning/REQUIREMENTS.md` lines 24-26 — AUTH-01, AUTH-02, AUTH-03 acceptance criteria
- `plans/0808-2042-appstore-submission-remediation/plan.md` — Phase 3 section (file-level detail and acceptance criteria)

### Codebase state
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift` — the gitignored file holding the expired guest JWT (the AUTH-01 leak vector); zero references in tracked app code
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift` — 3-tier config resolution; `isConfigured` checks anonKey non-empty
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift` — `isAvailable()`, `send()` with `onTermination` cancellation, `ensureValidSession()` anonymous auth
- `StressMonitor/StressMonitor/Services/LLM/SupabaseAuthService.swift` — anonymous sign-in + refresh (already implemented, replaces the old guest JWT)
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` — `cancelResponse()`, `preservePartialResponseIfNeeded()`, `isAvailable`
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` — `unavailableView` (developer-facing copy), `onDisappear { viewModel.cancelResponse() }`
- `StressMonitor/StressMonitor/Views/Action/ActionView.swift` lines 28-44 — RippleRecommendationCard CTA opens chat sheet unconditionally
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` lines 65-67 — chat sheet opens unconditionally
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` lines 113-172 — `PBXFileSystemSynchronizedBuildFileExceptionSet` + `PBXFileSystemSynchronizedRootGroup` (the mechanism D-02 uses)
- `StressMonitor/StressMonitorTests/SupabaseAuthServiceTests.swift` — existing URLProtocol-mock pattern to reuse for AUTH-03 tests

### Project-level
- `.planning/PROJECT.md` §Context — D1 decision framing
- `.planning/REQUIREMENTS.md` — AUTH-01/02/03 acceptance criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### The AUTH-01 leak vector (the core defect)
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift` is **gitignored** (`.gitignore:164`) so it is never committed — but the StressMonitor target uses `PBXFileSystemSynchronizedRootGroup` (project.pbxproj lines 140-172), which auto-includes every `.swift` file under `StressMonitor/StressMonitor/` in the build. Because the file exists on disk locally, it compiles into every build including Release archives. The file contains a literal JWT string (`eyJhbGciOiJFUzI1NiIs...`) that `strings` extracts from the compiled binary. The JWT is expired (`exp: 1783238531` ≈ a past date) but AUTH-01's criterion is "no credential — expired or otherwise" — so this is a definite failing criterion today.
- Critically, **`SupabaseSecrets` has zero references in any tracked Swift file** (grep-confirmed). It is dead code that leaks by virtue of being compiled. The runtime auth path (`SupabaseAuthService.signInAnonymously` + `refreshSession`) replaced it — the JWT fallback in `SupabaseSecrets.guestJWT` is unreachable but still shipped.

### The AUTH-02 entry-point state
- `ChatViewModel.isAvailable` (line 17, 60) is set from `SupabaseLLMService.isAvailable()`, which returns `SupabaseConfig.isConfigured` (anonKey non-empty). The anonKey fallback is the masked string `"**********************************************"` — so `isConfigured` is currently `true` even without a real key, because the masked fallback is non-empty. This is a secondary defect: `isAvailable` returns true regardless of whether the service actually works.
- The two Chat entry points — `ActionView` (line 28-30, RippleRecommendationCard `onCTA` sets `isChatPresented = true`) and `SettingsView` (line 65, `.sheet(isPresented: $showChatSheet)`) — open the `ChatBottomSheetView` unconditionally. There is no v1 gate.
- `ChatBottomSheetView.unavailableView` (lines 370-389) shows "AI Chat needs backend auth / Connect Supabase Auth and provide SUPABASE_ANON_KEY" — developer-facing copy, not a user-honest "coming soon" message.

### The AUTH-03 lifecycle (already implemented, needs TDD verification)
- `ChatViewModel.cancelResponse()` (lines 176-187): cancels `streamingTask`, preserves `currentStreamingText` as a partial assistant message, clears state. Correct.
- `ChatBottomSheetView.onDisappear` (line 45): calls `viewModel.cancelResponse()` — covers Close button AND swipe-to-dismiss AND programmatic dismissal. Correct.
- `SupabaseLLMService.send` (line 227): `continuation.onTermination = { _ in task.cancel() }` — when the `AsyncThrowingStream` is terminated (which happens when the view model's `for try await` loop breaks on dismissal), the underlying `_Concurrency.Task` is cancelled, which propagates `CancellationError` to `URLSession.shared.bytes(for:)` and cancels the network request. Correct — this is the "within one runloop" cancellation AUTH-03 requires.
- `ChatViewModel.preservePartialResponseIfNeeded()` (lines 157-161): on a thrown error mid-stream (network drop), appends `currentStreamingText` as a partial assistant message. Correct.
- The credit-not-charged aspect of AUTH-03: the backend deducts a credit per `/chat` call. Cancellation client-side stops consuming the SSE stream, but whether the backend charges depends on when it deducts. The iOS side cannot verify the backend's credit logic from here — but the client-side contract is "the request is cancelled (not left running)", which is what the iOS code does. Backend credit behavior is out of scope for this phase (it is a `stress-app-be` concern, documented in the cross-repo contract).

### Established patterns
- `#if DEBUG` compile-time gating is used throughout: `StressMonitorApp.swift` (lines 5, 155, 172, 197, 207), `StressViewModel.swift` (4, 95, 111...), `SimulatorHealthKitService.swift` (whole file). `SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)"` is set for the Debug configuration (project.pbxproj line 693).
- `PBXFileSystemSynchronizedBuildFileExceptionSet` (project.pbxproj lines 113-138) is the established mechanism for excluding specific files from specific targets — currently used for `Info.plist` (excluded from both app + widget targets) and watch fonts (excluded from the watch target). D-02 extends this pattern to exclude `SupabaseSecrets.swift` from Release.
- URLProtocol-based mocking for network tests is established in `StressMonitorTests/SupabaseAuthServiceTests.swift` (the `MockAuthURLProtocol` class). AUTH-03 tests reuse this pattern.
- `@Observable @MainActor final class` is the ViewModel pattern; `ChatViewModel` follows it.

### Integration points
- `StressMonitor/StressMonitor/Views/Action/ActionView.swift` — RippleRecommendationCard CTA (line 28-30) and `.sheet(isPresented: $isChatPresented)` (line 43-45). Must gate on D-03's `ChatAvailability`.
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` — `.sheet(isPresented: $showChatSheet)` (lines 65-67). Same gate.
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` — `isAvailable` must reflect D-03's gate in Release.
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` — `unavailableView` copy must become user-facing per D-03.
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — Release exception set for `SupabaseSecrets.swift` per D-02.

</code_context>

<specifics>
## Specific Ideas

- The `strings` verification for AUTH-01 is automatable: build a Release `.app`, run `strings StressMonitor.app/StressMonitor | grep -c 'eyJhbGc'` and assert it returns 0. The expired JWT in `SupabaseSecrets.swift` starts with `eyJhbGc` (the base64 of `{"alg...`). This is the single most important acceptance check in the phase.
- The `isConfigured` defect (anonKey masked-fallback being non-empty) should be tightened as part of AUTH-02: `SupabaseConfig.isConfigured` should return `false` when the key is the literal masked fallback or contains only asterisks. This makes the service's own availability honest even before the D-03 gate is applied. Small fix, high value.
- The `ChatAvailability` abstraction should be a single `enum` with a static computed `current` property, so there is exactly one place to change when Chat re-enables in v1.1. Both entry points read `ChatAvailability.current`; the `ChatViewModel.isAvailable` reads it too.

</specifics>

<deferred>
## Deferred Ideas

- **Supabase Auth sign-in UI (Sign in with Apple)** — the full auth flow that would let real users chat. D1 explicitly defers this to v1.1. This phase ships the honest gate, not the working flow.
- **Backend credit-deduction verification** — whether the Supabase Edge Function refunds a credit on a client-side cancellation is a `stress-app-be` concern (the cross-repo contract). AUTH-03's iOS-side contract is "the request is cancelled" — backend behavior is out of scope here.
- **Chat content re-enablement (v1.1)** — the full un-gating, real ASC anon key in build settings, the anonymous-sign-in dashboard toggle verification. All v1.1.
- **Removing `SupabaseSecrets.swift` entirely** — the file is still useful for local DEBUG dev (the `SUPABASE_GUEST_JWT` env var fallback). Keeping it gitignored + Release-excluded (D-02) preserves the local-dev workflow. Deleting it would force local dev to always set the env var, which is friction for no Release-binary benefit once D-02 lands.

</deferred>

<verification_notes>
## Verification Constraints

- **AUTH-01 (`strings` check) requires a Release build.** A Debug build excludes nothing (D-02 only excludes from Release). The verification is: `xcodebuild archive` (Release config) → `strings` against the binary → grep for the JWT prefix → assert zero. This is automatable but requires the Release archive step, which is slower than a unit test. Plan it as the final verification gate.
- **AUTH-02 (entry-point gate) is partially automatable.** The `ChatAvailability.current` logic can be unit-tested (`#if DEBUG` returns enabled, Release returns disabled — but the test target compiles in Debug, so testing the Release path requires a build-condition check). The UI rendering of the disabled state is a manual visual check (checkpoint:human-verify).
- **AUTH-03 (cancellation + preservation) is fully automatable** via the existing URLProtocol-mock pattern. Inject a mock `LLMServiceProtocol` that yields tokens then throws/terminates; assert `cancelResponse()` preserves partial text and cancels the task; assert a thrown error mid-stream preserves partial text.
- The `PBXFileSystemSynchronizedBuildFileExceptionSet` edit (D-02) is a pbxproj text edit, not a project.pbxproj structural change — it adds a file path to an existing exception set's `membershipExceptions` array. The planner must verify the exact exception-set UUID and target reference before writing the edit instruction.

</verification_notes>

---
*Phase: 3-Auth & Chat Availability*
*Context gathered: 2026-08-11*

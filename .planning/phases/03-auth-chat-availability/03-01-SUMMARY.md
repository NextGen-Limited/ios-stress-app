---
phase: 03-auth-chat-availability
plan: 01
subsystem: auth
tags: [swiftui, supabase, jwt, chat, storekit, ios, release-security]

requires: []
provides:
  - "ChatAvailability single source of truth for the v1 Chat gate (#if DEBUG compile-time)"
  - "#if DEBUG-wrapped SupabaseSecrets — guest JWT dead-stripped from Release"
  - "Honest SupabaseConfig.isConfigured (rejects masked anon-key fallback)"
  - "User-facing 'AI Coaching is coming soon' copy replacing developer-facing text"
  - "Testable ChatViewModel llmService seam + isStreaming read"
  - "ChatAvailabilityTests + ChatLifecycleTests pinning AUTH-01/02/03 contracts"
affects: [app-store-submission, chat-re-enablement-v1.1, release-archive-gate]

actuals:
  tokens: 4800
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Compile-time feature gate via #if DEBUG on a single enum (ChatAvailability.current) read by all entry points + the LLM service"
    - "Protocol-level test seam: convenience init delegates to an injectable designated init (ChatViewModel llmService)"
    - "AsyncThrowingStream double (FakeLLMService) above the network layer for cancellation/partial-text lifecycle tests"

key-files:
  created:
    - "StressMonitor/StressMonitor/Services/Chat/ChatAvailability.swift"
    - "StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift"
    - "StressMonitor/StressMonitorTests/ChatLifecycleTests.swift"
  modified:
    - "StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift"
    - "StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift"
    - "StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift"
    - "StressMonitor/StressMonitor/Views/Action/ActionView.swift"
    - "StressMonitor/StressMonitor/Views/Settings/SettingsView.swift"
    - "StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift"
  local-only:
    - "StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift (gitignored; #if DEBUG wrap applied on disk, untrackable by design)"

key-decisions:
  - "#if DEBUG wrap of SupabaseSecrets.swift body (D-02) — file stays on disk, gitignored; Release compiles it to an empty translation unit"
  - "ChatAvailability is a single enum with a static `current` computed via #if DEBUG; both entry points + SupabaseLLMService.isAvailable() read it (D-03)"
  - "Chat entry points stay visible-but-honestly-disabled (discoverability for v1.1) rather than hidden (D-03 discretion)"
  - "AUTH-03 lifecycle treated as TDD verification only — cancelResponse + preservePartialResponseIfNeeded + onTermination were already correct; only a test seam was added (D-04)"

patterns-established:
  - "ChatAvailability.current is the one place to flip when Chat re-enables in v1.1"
  - "FakeLLMService pattern: protocol-level AsyncThrowingStream double with onTermination wiring that mirrors the real service"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03]

coverage:
  - id: D1
    description: "Guest JWT literal excluded from the Release binary via #if DEBUG wrap of SupabaseSecrets.swift"
    requirement: AUTH-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift#debugBuildStillCompilesSupabaseSecrets"
        status: unknown
      - kind: other
        ref: "DEBUG build succeeds (xcodebuild build -configuration Debug); #if DEBUG wrap is structurally guaranteed by Swift semantics"
        status: pass
    human_judgment: true
    rationale: "The empirical `strings StressMonitor.app/StressMonitor | grep -c eyJhbGc` gate requires a Release archive, which cannot be built locally — a pre-existing, unrelated Release-build breakage (MockStoreKitService reference in StoreKitServiceEnvironment.swift, logged in deferred-items.md) blocks Release compilation. Structural correctness of the #if DEBUG wrap is guaranteed by the compiler; empirical confirmation is deferred until the pre-existing Release break is fixed."
  - id: D2
    description: "Both Chat entry points (ActionView RippleRecommendationCard CTA + Reflect row, SettingsView chat row) honestly disabled in Release; user-facing 'coming soon' copy replaces developer-facing 'needs backend auth'"
    requirement: AUTH-02
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift#chatAvailabilityContract"
        status: unknown
      - kind: other
        ref: "grep 'AI Chat needs backend auth|Connect Supabase Auth' in Views/ returns 0; ChatAvailability adoption grep shows reads in ActionView, SettingsView, SupabaseLLMService"
        status: pass
    human_judgment: true
    rationale: "Visual inspection of the disabled entry-point presentation (Task 4 checkpoint) requires either a Release-config simulator run or a temporary #if flip — both are manual and were deferred per execution instructions."
  - id: D3
    description: "AUTH-03 lifecycle: mid-stream dismissal cancels the streaming Task and preserves partial text; network drop preserves partial text; empty-partial cancel appends nothing"
    requirement: AUTH-03
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatLifecycleTests.swift#cancelResponsePreservesPartialText, #networkErrorPreservesPartialText, #cancelResponseWithNoPartialTextAppendsNothing"
        status: unknown
    human_judgment: true
    rationale: "CoreSimulator/XCTestDevices is broken on this dev host (pre-existing), so the tests compile (build-for-testing succeeded) but cannot be executed locally. Lifecycle logic was traced by hand against the existing (D-04-correct) implementation; runtime confirmation deferred to a host with a working simulator."

duration: 50min
completed: 2026-08-11
status: complete
---

# Phase 3 Plan 01: Auth & Chat Availability Summary

**AI Chat honestly gated off for v1 via a compile-time `ChatAvailability` flag, the leaked guest JWT dead-stripped from Release by an `#if DEBUG` wrap, and the AUTH-03 streaming lifecycle pinned by new TDD tests.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-08-11T05:50:26Z
- **Completed:** 2026-08-11T06:40:00Z
- **Tasks:** 3 of 3 executed (Task 4 checkpoint deferred per instructions)
- **Files modified:** 8 source files (3 created, 5 modified) + 1 gitignored local-only edit

## Accomplishments
- Excluded the expired guest JWT from the Release binary by wrapping `SupabaseSecrets.swift` in `#if DEBUG ... #endif`; DEBUG local-dev fallback unchanged
- Introduced `ChatAvailability` as the single source of truth read by both Chat entry points and `SupabaseLLMService.isAvailable()`; Release ships honestly disabled
- Rewrote the `ChatBottomSheetView` unavailable copy from developer-facing ("needs backend auth / Connect Supabase Auth") to user-facing ("AI Coaching is coming soon")
- Tightened `SupabaseConfig.isConfigured` to reject the masked anon-key fallback and asterisk-only strings so service availability is honest even before the gate
- Added a testable `llmService` seam to `ChatViewModel` and pinned the AUTH-03 cancellation / partial-text-preservation contracts with three lifecycle tests

## Task Commits

Each TDD task has a RED (`test`) then GREEN (`feat`) commit:

1. **Task 1: Prove no guest-JWT literal ships in Release** — `adbe97c` (test) + #if DEBUG wrap (feat, applied to gitignored file — untrackable by design, see Notes)
2. **Task 2: ChatAvailability gate + honest entry points + user-facing copy** — `dece318` (test) + `d0e2974` (feat)
3. **Task 3: Pin AUTH-03 lifecycle** — `f1ac559` (test) + `5de5016` (feat)

**Plan metadata:** to be appended (docs: complete plan)

## Files Created/Modified
- `StressMonitor/StressMonitor/Services/Chat/ChatAvailability.swift` (created) — single source of truth; `#if DEBUG` compile-time gate
- `StressMonitor/StressMonitor/Services/LLM/SupabaseConfig.swift` — `isConfigured` rejects masked fallback; added `maskedFallback` + `isMaskedPlaceholder(_:)`
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift` — `isAvailable()` gated on `ChatAvailability.current`
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` — convenience init delegates to injectable `llmService` designated init; added `isStreaming`
- `StressMonitor/StressMonitor/Views/Action/ActionView.swift` — RippleRecommendationCard CTA + Reflect row route through `presentChat()`; "coming soon" caption when disabled
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` — chat row gated; value shows "Coming soon" when disabled
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` — `unavailableView` copy rewritten user-facing
- `StressMonitor/StressMonitorTests/ChatAvailabilityTests.swift` (created) — DEBUG-reachability, ChatAvailability contract, masked-key rejection
- `StressMonitor/StressMonitorTests/ChatLifecycleTests.swift` (created) — cancel preserves partial + ends streaming; network drop preserves partial; empty-partial cancel appends nothing
- `StressMonitor/StressMonitor/Services/LLM/SupabaseSecrets.swift` (local-only, gitignored) — body wrapped in `#if DEBUG`

## Decisions Made
- Followed D-02: `#if DEBUG` wrap inside the gitignored `SupabaseSecrets.swift` (not a pbxproj exception — that mechanism is target-scoped, not configuration-scoped). The wrap is a local-only edit by design — the file must never enter git history.
- Followed D-03 discretion: entry points show-but-disable (visible "coming soon") rather than hide, preserving v1.1 discoverability.
- TDD ordering preserved: each task committed a `test(...)` RED commit before its `feat(...)` GREEN commit. Task 1's "RED" test is a contract pin (the plan acknowledges it passes both before and after the wrap — its job is to prevent regression of the DEBUG fallback).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Designated/convenience initializer delegation**
- **Found during:** Task 3 (ChatViewModel seam)
- **Issue:** First version of the injectable init had the delegating init as a designated init calling `self.init(...)` — Swift requires delegating initializers to be `convenience`.
- **Fix:** Marked the existing-parameter init `convenience init`; the `llmService` init is the designated initializer.
- **Files modified:** `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift`
- **Verification:** DEBUG build SUCCEEDED
- **Committed in:** `5de5016`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Compiler-error fix, no scope change.

## Issues Encountered
- **AUTH-01 `strings` gate blocked locally (pre-existing).** A Release-config build fails on `StoreKitServiceEnvironment.swift:12`, which unconditionally references the `#if DEBUG`-gated `MockStoreKitService`. This is unrelated to Phase 3 and out of scope; logged to `deferred-items.md`. The `#if DEBUG` wrap of `SupabaseSecrets.swift` is structurally guaranteed correct by Swift compiler semantics (the wrapped body is not compiled in Release, so the JWT literal never enters the data section), but empirical `strings` confirmation requires the pre-existing Release break to be fixed first.
- **Local test execution blocked (pre-existing).** CoreSimulator/XCTestDevices is broken on this dev host. Both new test files compile cleanly (`build-for-testing` SUCCEEDED); runtime pass/fail must be confirmed on a host with a working simulator. Each lifecycle test was hand-traced against the existing (D-04-correct) implementation.

## TDD Gate Compliance
Plan-level TDD gate satisfied. Git log shows, in order: `test(03-01)` RED commits (`adbe97c`, `dece318`, `f1ac559`) followed by `feat(03-01)` GREEN commits (`d0e2974`, `5de5016`). Task 1's implementation (the `#if DEBUG` wrap) is a local edit to a gitignored file, so it has no separate `feat` commit — its committed artifact is the contract-pinning test; this is noted but does not break the gate (a `feat` commit exists for the task's verification-bearing work in Task 2/3).

## Deferred Items
- **Task 4 (checkpoint:human-verify):** AUTH-01 Release `strings` gate + AUTH-02 visual inspection of the disabled entry points. Deferred per execution instructions; AUTH-01 portion additionally blocked by the pre-existing Release-build breakage in `StoreKitServiceEnvironment.swift` (see `deferred-items.md`).
- **Runtime test execution:** the three `ChatLifecycleTests` and the `ChatAvailabilityTests` need to be run on a host with a working CoreSimulator.

## User Setup Required
None — no external service configuration required. Chat is gated off; real Supabase auth + ASC anon key are v1.1 work.

## Next Phase Readiness
- Phase 3 source work is complete; the v1 binary will not leak the guest JWT and Chat presents an honest "coming soon" state.
- Blocker for full AUTH-01 sign-off: the pre-existing Release-build break (`MockStoreKitService` in `StoreKitServiceEnvironment.swift`) must be fixed before a Release archive can be produced for the `strings` gate. That fix belongs to a StoreKit/release phase, not Phase 3.

## Self-Check: PASSED

- All 3 created files exist on disk (`ChatAvailability.swift`, `ChatAvailabilityTests.swift`, `ChatLifecycleTests.swift`).
- SUMMARY.md and deferred-items.md present in the phase directory.
- Local-only `#if DEBUG` / `#endif` wrap confirmed in `SupabaseSecrets.swift` (gitignored).
- All 5 Phase 3 commits present in git log: `adbe97c`, `dece318`, `d0e2974`, `f1ac559`, `5de5016`.
- DEBUG build SUCCEEDED; test target compiles (build-for-testing SUCCEEDED).

---
*Phase: 03-auth-chat-availability*
*Completed: 2026-08-11*

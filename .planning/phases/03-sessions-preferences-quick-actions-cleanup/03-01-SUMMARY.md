---
phase: 03-sessions-preferences-quick-actions-cleanup
plan: 01
subsystem: api
tags: [sessions, rest, urlprotocol, swift-testing, sse, urlcomponents, userdefaults]

# Dependency graph
requires:
  - phase: 02-credits-system-iap-transition
    provides: StressAPIClient + authorizedRequest Bearer plumbing, StressLLMService /chat streaming, RequestCaptureURLProtocol test double
provides:
  - ChatSession / ChatSessionMessage Codable DTOs (String dates)
  - StressAPIClient+Sessions (listSessions / createSession / deleteSession / fetchMessages) + SessionsAPIError
  - authorizedRequest(url:) overload for query-safe URL building
  - Titled-session creation inside StressLLMService.send + adopt(sessionId:) write-through
  - ChatViewModel.restoreHistory() + apiClient injection seam; ChatBottomSheetView restore wiring
  - RequestCaptureURLProtocol.responseByPath + capturedRequests (ordered multi-request stubbing)
affects: [03-02, 03-03, 03-04, 03-05]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 31000
  tasks: 2
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "authorizedRequest(url:) overload — query-carrying endpoints build URLs with URLComponents because appendingPathComponent percent-encodes '?'"
    - "adopt(sessionId:) single write-through for session persistence (creation + SSE metadata share it)"
    - "path-keyed URLProtocol stubbing (responseByPath) for ordered multi-request flow tests"

key-files:
  created:
    - StressMonitor/StressMonitor/Models/ChatSession.swift
    - StressMonitor/StressMonitor/Models/ChatSessionMessage.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift
    - StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift
    - StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
    - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
    - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
    - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
    - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "Query URLs must go through URLComponents + authorizedRequest(url:) — appendingPathComponent percent-encodes '?' (plan-time discovery, verified by exact-URL test assertions)"
  - "baseURL made internal (matching session) so endpoint-group extensions can build full URLs"
  - "Session creation is fail-soft inside the send Task: try? createSession, fall through with nil id so a title failure never blocks chat"
  - "404 restore maps to resetSession() (clears stressChatSessionId) — dangling ids degrade to a fresh empty chat, never a visible error"

patterns-established:
  - "Pattern: authorizedRequest(url:) for any endpoint with query params; exact-URL assertions forbid %3F"
  - "Pattern: one fetch per presentation via a private guard flag + messages.isEmpty re-check after the await"
  - "Pattern: String-typed date fields on DTOs (Postgres fractional-second timestamptz breaks .iso8601)"

requirements-completed: [derived-SES-01, derived-SES-02]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Sessions API client extension: fetchMessages/createSession/listSessions/deleteSession with exact-URL, Bearer, 404/401 error mapping"
    requirement: derived-SES-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift (6 @Test functions, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Titled-session creation ordering: POST /sessions strictly before /chat carries its id; fail-soft on 500; id survives service reconstruction"
    requirement: derived-SES-02
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift#firstSendCreatesTitledSessionBeforeChat (capturedRequests ordering pinned)"
        status: pass
    human_judgment: false
  - id: D3
    description: "History restore on chat open: server order, isSynced mapping, system rows filtered, 404 dangling-id recovery, no-clobber of live messages"
    requirement: derived-SES-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift#restoreHistoryRendersServerHistory (+ 404 and no-clobber tests, exit 0)"
        status: pass
    human_judgment: false

# Metrics
duration: 44min
completed: 2026-08-23
status: complete
---

# Phase 3 Plan 1: Sessions Tracer Summary

**Server-authoritative chat sessions: titled POST /sessions creation riding the first /chat, GET /sessions/{id}/messages restore on sheet open, 404-tolerant dangling-id recovery — all URLProtocol-pinned with the Phase-2 chat fence green**

## Performance

- **Duration:** ~44 min
- **Started:** 2026-08-23T09:13:06Z
- **Completed:** 2026-08-23T09:57:00Z
- **Tasks:** 2 (both TDD: RED → GREEN → REFACTOR where applicable)
- **Files modified:** 11

## Accomplishments
- Sessions API layer: `StressAPIClient+Sessions` with four endpoints and a typed `SessionsAPIError` (.notFound for dangling sessions), cloned from the +Credits pattern, pinned by `StressAPIClientSessionsTests` (6 tests, exact absolute-URL assertions)
- Tracer path end-to-end: first message of a new conversation creates a titled session BEFORE /chat carries its id (order-pinned via capturedRequests[0]/[1]); id persists through service reconstruction; reopening the sheet restores the server history; a 404 clears the stored id and renders an empty chat; a restore landing after a live message never clobbers it
- Test-double upgrade: `RequestCaptureURLProtocol` gained `responseByPath` (path-keyed multi-endpoint stubbing) and `capturedRequests` (ordered accumulator) — additive, existing suites green

## Task Commits

Each task was committed atomically (TDD gates honored):

1. **Task 1: Sessions DTOs + StressAPIClient+Sessions (RED → GREEN)** - `4681792` (test) → `2c64e3d` (feat); no refactor commit — the GREEN implementation already matched the Credits template shape, nothing to clean
2. **Task 2: Tracer — titled session → chat → relaunch → restored history (RED → GREEN → REFACTOR)** - `8ac817c` (test) → `4797b5f` (feat) → `3276401` (refactor: extracted `restoredMessage(from:)` mapping, single `service` binding replacing duplicated casts)

**Plan metadata:** (this commit)

## Files Created/Modified
- `StressMonitor/StressMonitor/Models/ChatSession.swift` - Session DTO; dates stay String (fractional-second timestamptz)
- `StressMonitor/StressMonitor/Models/ChatSessionMessage.swift` - Message DTO; reuses ChatRole
- `StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift` - Four endpoints + SessionsAPIError + private envelope structs
- `StressMonitor/StressMonitor/Services/API/StressAPIClient.swift` - authorizedRequest(path:) now delegates to new authorizedRequest(url:) overload; baseURL internal
- `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift` - Titled-session creation before sendChat (fail-soft), adopt(sessionId:) write-through, sessionTitle(for:) builder
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` - apiClient seam, restoredHistory flag, restoreHistory() with 404 recovery and post-await no-clobber guard
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` - onAppear wires apiClient + restoreHistory (paywall/credits wiring untouched)
- `StressMonitor/StressMonitorTests/StressAPIClientTests.swift` - RequestCaptureURLProtocol additive extension
- `StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift` - Registered at pbxproj IDs A018/B018
- `StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift` - Registered at pbxproj IDs A019/B019; includes DelayedResponseURLProtocol for the no-clobber test
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` - Both suites registered (4-line pattern each)

## Decisions Made
- **The appendingPathComponent `?`-encoding pitfall, resolved via the URL overload:** `baseURL.appendingPathComponent("sessions?limit=20")` produces `https://api.test/sessions%3Flimit=20` — Foundation percent-encodes the question mark, so the backend would see a literal path segment. Resolved by refactoring `authorizedRequest(path:)` to delegate to a new `authorizedRequest(url:)` overload holding the unchanged token/header/timeout logic; listSessions/deleteSession build their URLs with `URLComponents` queryItems and call the overload. The PATTERNS.md claim that appendingPathComponent handles `?` fine was wrong; the plan's load-bearing discovery overrode it and the exact-URL assertions now pin it forever (no `%3F` in any asserted URL).
- `baseURL` made internal (it was `private`): the +Sessions extension needs it to build query URLs; `session` was already internal for the same reason.
- Fixture formats reused: SSEParserTests event shapes for the /chat stub bodies (content token event → terminal metadata event with session_id → `data: [DONE]`); CreditBalance's `freeResetAt: String?` precedent for all DTO date fields; StressAPIClientCreditsTests' `makeClient` + `body(of:)` stream-reading helper.
- **Confirmation the 402 paywall path was not touched:** `git diff 3e62129..HEAD` over SSEParser.swift and LLMServiceProtocol.swift is empty; mapHTTPError body unchanged; ChatViewModel's 402 branch and PaywallView wiring untouched; PaywallOutOfCreditsGuardTests + CreditPurchaseFlowTests green in the final fence run.
- deleteSession treats 2xx as terminal with no verification round-trip (Pitfall 6) — pinned by `capturedRequests.count == 1`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] watchOS 26.2 simulator runtime missing — scheme refused to test**
- **Found during:** Task 1 RED run
- **Issue:** `xcodebuild test` failed with "This scheme builds an embedded Apple Watch app. watchOS 26.2 must be installed in order to test the scheme" — the runtime had been removed from the host since Phase 2 close (only the iOS 26.3 runtime was present)
- **Fix:** `xcodebuild -downloadPlatform watchOS` (3.89 GB, ~2.5 min); also recreated the missing "iPhone 17" simulator device the plan's destination names (`xcrun simctl create`, iOS 26.3 runtime, iPhone 17 device type)
- **Files modified:** none (host environment only)
- **Verification:** subsequent test runs proceed past destination resolution
- **Committed in:** n/a (environment, no repo change)

**2. [Rule 1 - Bug] Test-double access level — +Sessions could not read baseURL**
- **Found during:** Task 1 GREEN run
- **Issue:** `baseURL` was `private`; the extension file could not build query URLs around it (compile error at all four call sites)
- **Fix:** Made `baseURL` internal with a doc comment (mirrors `session`, already internal for extensions)
- **Files modified:** StressAPIClient.swift
- **Verification:** build + sessions suite green
- **Committed in:** `2c64e3d` (Task 1 GREEN commit)

---

**Total deviations:** 2 auto-fixed (1 blocking-environment, 1 bug)
**Impact on plan:** Both required for the plan's own verify commands to run at all. No scope creep; the regression fence is untouched.

## Issues Encountered
- **Full-suite exit 65 despite 127/127 tests passing** — identical to the documented WINDOWS.md entry #8 (TEST-01 CoreSimulator cold-launch lineage, open since 02-01; 02-03 D5 and 02-04 recorded the same signature and treated "all distinct suites passed, 0 test failures; targeted runs exit 0" as the pass bar). My full-suite runs: `Test run with 103 tests in 18 suites passed` + `Executed 24 tests, with 0 failures`, zero ✘ marks; the 6 restarts cluster on the same pre-existing DataDeletionConsolidationTests suites (crash reports show a SwiftData trap inside DataExportFieldSelectionTests / DataDeleterFailureAndCancellationTests — files this plan never touched). The final targeted run of all 8 fence + new suites exits 0. No new ledger entry needed — entry #8 covers this signature.
- Swift Testing string interpolation gotcha: `\#(expr)` is raw-string-only syntax; multiline fixtures needed `\()` (fixed before the RED commit).

## TDD Gate Compliance
- Task 1: RED `4681792` (test) → GREEN `2c64e3d` (feat). REFACTOR omitted — GREEN landed as the clean Credits-template shape; nothing to clean, no commit needed.
- Task 2: RED `8ac817c` (test) → GREEN `4797b5f` (feat) → REFACTOR `3276401` (mapping extraction + guard naming; suite re-run green).
- Tracer feedback gate: both `<verify>` commands re-run end-to-end after the tracer commit — targeted suites exit 0; full suite passes all tests (environmental exit-65 signature above).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The +Sessions extension and the URLComponents URL pattern are ready for 03-02 (preferences) and 03-03 (quick-actions GET) — both carry query strings and must reuse `authorizedRequest(url:)`
- listSessions/deleteSession are implemented and pinned; 03-04 (factory-reset wipe) only needs the DataDeleter loop + ServerSessionWiping seam
- Restore tolerates dangling ids, but `stressChatSessionId` is still not cleared on factory reset — 03-04 closes that (T-3-03)
- The watchOS 26.2 simulator runtime is now installed on this host — later plans' full-suite gates can run again without re-downloading

---
*Phase: 03-sessions-preferences-quick-actions-cleanup*
*Completed: 2026-08-23*


## Self-Check: PASSED

- All 5 created files exist on disk
- All 5 task commits (4681792, 2c64e3d, 8ac817c, 4797b5f, 3276401) present in git log
- Acceptance-criteria greps re-verified post-refactor: `func restoreHistory` = 1, `adopt(sessionId` = 3, `func authorizedRequest` = 2, @Test functions = 6 + 6
---
phase: 03-sessions-preferences-quick-actions-cleanup
plan: 03
subsystem: api
tags: [quick-actions, api, urlprotocol, swift-testing, chat, preferences, dead-code-removal]

# Dependency graph
requires:
  - phase: 03-sessions-preferences-quick-actions-cleanup (plan 01)
    provides: apiClient injection seam on ChatViewModel, authorizedRequest(url:) URLComponents overload, ChatHistoryRestoreTests suite + RequestCaptureURLProtocol.responseByPath
  - phase: 03-sessions-preferences-quick-actions-cleanup (plan 02)
    provides: PreferencesService (app-scope environment) with language/coachingStyle reads, StressContextPayload.build(language:coachingStyle:) params
provides:
  - ServerQuickAction Codable DTO (id/title/type, type kept String)
  - StressAPIClient+QuickActions — QuickActionsAPIError + getQuickActions(stressLevel:language:coachingStyle:), the ONLY quick-actions request (GET)
  - ChatQuickActions.prompt(forServerActionId:) — verbatim mirror of the backend prompt table (7 ids)
  - ChatViewModel.quickReplies (instant local fallback → server swap) + fetchQuickActions() one-per-presentation guard + preferencesService seam
  - Prefs-fed StressContextPayload.build call site (derived-PREF-02 call-site half complete)
  - Live chips wiring on ChatBottomSheetView (quickRepliesSection reads viewModel.quickReplies; taps send the resolved prompt through /chat)
  - Dead plumbing deleted: QuickActionChipsView.swift, ChatViewModel.quickActions/sendQuickAction, sheet defaultQuickReplies
affects: [03-04, 03-05]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 8000
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server chip ids resolve prompts on-device via a local verbatim mirror of the backend table — server chooses among known prompts, never injects prompt text (T-3-10)"
    - "Chips swap pattern: instant local fallback at init, one guarded fetch per presentation, failure keeps fallback — no loading/empty state (T-3-11)"
    - "A one-method GET-only extension file doubles as the structural revenue-bypass guard (grep gates: authorizedRequest==1, \"POST\"==0)"

key-files:
  created:
    - StressMonitor/StressMonitor/Models/ServerQuickAction.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+QuickActions.swift
    - StressMonitor/StressMonitorTests/StressAPIClientQuickActionsTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/LLM/ChatQuickActions.swift
    - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
    - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
    - StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift
  deleted:
    - StressMonitor/StressMonitor/Views/Chat/QuickActionChipsView.swift

key-decisions:
  - "Server chips map to ChatQuickAction with icon \"sparkles\" — the live chip surface renders the title only, so no per-id icon mapping was added (no speculative branches)"
  - "fetchQuickActions sets fetchedQuickActions before the apiClient guard exactly as planned: the sheet assigns apiClient before kicking the fetch, and one-shot semantics survive re-appear"
  - "PreferencesService is injected into the VM as a concrete type (no protocol) — same-module consumer, mirroring the 03-02 decision; tests seed it through the stubbed /preferences GET (real request path)"

patterns-established:
  - "Pattern: server-driven UI swap keeps a guaranteed local render first (never a loading state) — fetch failure is a no-op"
  - "Pattern: id→prompt resolution table mirrored from backend with a lockstep doc note (ChatQuickActions.prompt(forServerActionId:))"

requirements-completed: [derived-PREF-02, derived-QA-01, AUTH-03]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Quick-actions API client extension: GET with exact three-param context query (no %3F), Bearer pin, typed decode tolerating unknown type strings, 401 -> unauthorized"
    requirement: derived-QA-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StressAPIClientQuickActionsTests.swift (4 @Test functions, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Local prompt-table mirror: all 7 backend ids resolve to the exact verbatim prompt, unknown id -> nil (chip taps never need the POST completion route)"
    requirement: derived-QA-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StressAPIClientQuickActionsTests.swift#promptMapMirrorsBackendTable"
        status: pass
    human_judgment: false
  - id: D3
    description: "Chips lifecycle: instant local fallback at init, server swap with unknown-id drop, one GET per presentation, failure keeps fallback (no loading/empty state)"
    requirement: derived-QA-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift (freshViewModelRendersLocalFallbackChips, fetchQuickActionsSwapsChipsForServerSuggestions, failedChipsFetchKeepsFallbackSet — suite 11/11 exit 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Prefs-fed send path: chip tap sends its resolved prompt through send() -> /chat with the seeded PreferencesService values (vi/direct) in BOTH the chips query and the stress-context payload; unset seam falls back to en/supportive"
    requirement: derived-PREF-02
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift (chipTapSendsPromptWithPrefsFedPayload, unsetPreferencesFallBackToPayloadDefaults)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Live chips swap on the deployed backend + Settings-driven language/style visible in chip suggestions; dead-cutover cutover (QuickActionChipsView gone)"
    requirement: derived-QA-01
    verification:
      - kind: manual_procedural
        ref: "03-05 UAT script (chat open: instant chips then server-suggested swap; tap routes through credit-metered chat)"
        status: unknown
    human_judgment: true
    rationale: "Live-backend chip behavior and visual chip appearance need a human against the deployed API; unit tests pin the contract via URLProtocol stubs"

# Metrics
duration: 14min
completed: 2026-08-23
status: complete
---

# Phase 3 Plan 3: Quick-Action Chips + Prefs-Fed Payload Summary

**Server-driven quick-action chips on the live chat surface: instant local fallback swapped by GET /quick-actions (context-query-pinned), taps resolving prompts through a verbatim backend-table mirror into the credit-metered /chat path, the payload now speaking PreferencesService's language/style, and the dead chips plumbing fully cut over — Phase-2 fence green**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-08-23T10:17:04Z
- **Completed:** 2026-08-23T10:31:00Z
- **Tasks:** 2 (both TDD: RED → GREEN; REFACTOR omitted — GREEN landed in the clean template shape, nothing to clean)
- **Files:** 9 (3 created, 5 modified, 1 deleted)

## Accomplishments
- Suggestions API layer: `ServerQuickAction` DTO (type kept a plain String so unknown server values decode without throwing) + `StressAPIClient+QuickActions` with `QuickActionsAPIError` and a single `getQuickActions(stressLevel:language:coachingStyle:)` GET built through `URLComponents` — pinned by exact absolute-URL assertions (`https://api.test/quick-actions?stress_level=65&language=vi&coaching_style=direct`, no `%3F`).
- Prompt-table mirror: `ChatQuickActions.prompt(forServerActionId:)` returns the backend's seven prompts verbatim (lockstep doc note pointing at `stress-app-be/src/lib/quick-actions.ts`), nil for unknown ids — table-driven test over all seven + one unknown.
- Live chips wiring (Q1 resolution): `ChatBottomSheetView.quickRepliesSection` now iterates `viewModel.quickReplies` (identical capsule styling); taps call `viewModel.send(reply.prompt)` directly so the long prompt never echoes into the composer; `onAppear` injects the environment `PreferencesService` and kicks `fetchQuickActions()`.
- Chips lifecycle in `ChatViewModel`: `quickReplies` initializes from `ChatQuickActions.actions(for:)` (instant, zero network), `fetchQuickActions()` swaps server titles whose ids resolve (unknown ids dropped), one fetch per presentation, failure keeps the fallback set — swap touches chip data only, never messages or inputText.
- Prefs-fed payload (derived-PREF-02 call-site half): `streamResponse` builds `StressContextPayload` with `preferencesService?.language ?? "en"` / `?.coachingStyle ?? "supportive"` — defaults survive only on the unset seam (tests, previews).
- Dead-code cutover: `QuickActionChipsView.swift` deleted, `ChatViewModel.quickActions` computed property and `sendQuickAction` removed, sheet `defaultQuickReplies` removed. `ChatQuickActions`/`ChatQuickAction` STAY — they are the reused fallback source and chip model.

## Task Commits

1. **Task 1: ServerQuickAction DTO + GET extension + prompt map (RED → GREEN)** - `55073b9` (test: compile-failing suite; pbxproj A022/B022) → `432a008` (feat: three implementation files). REFACTOR omitted — GREEN already matched the Credits/Sessions template shape.
2. **Task 2: Chips swap + prefs-fed payload + dead-code cutover (RED → GREEN)** - `865a3f9` (test: 5 failing cases in ChatHistoryRestoreTests, compile-failing on the missing members) → `7987f39` (feat: VM chips state + fetch, sheet wiring, payload call site, 3 deletions). REFACTOR omitted — suite diff stayed minimal by construction; all chat suites re-run green in the same run.

**Plan metadata:** (this commit)

## Q1 Cutover Outcome (recorded per plan output)
- **Wired (live surface):** `ChatBottomSheetView.quickRepliesSection` — the block whose taps already rode `sendMessage()`; its data source swapped from the hardcoded `defaultQuickReplies` strings to `viewModel.quickReplies`.
- **Reused (NOT dead):** `ChatQuickActions.actions(for:)` + `ChatQuickAction` — they ARE the instant local fallback and the chip model; extended with `prompt(forServerActionId:)`.
- **Deleted:** `QuickActionChipsView.swift` (zero call sites, filesystem-synced group — no pbxproj edit needed), `ChatViewModel.quickActions` (computed dead member), `ChatViewModel.sendQuickAction`, sheet `defaultQuickReplies`.
- **Kept deliberately:** SSEParser/StressLLMService terminal `quick_actions` metadata plumbing (live SSE contract, pinned by SSEParserTests; SSE-metadata-driven chip refresh is a deferred idea).

## One-GET Confirmation (recorded per plan output)
`StressAPIClient+QuickActions.swift` holds exactly ONE request method and it is a GET: `grep -c 'authorizedRequest'` = 1 (that call site passes `method: "GET"`), `grep -c '"POST"'` = 0, `grep -c 'func '` = 1. `POST /quick-actions` is never called anywhere in app sources (the only mentions are doc comments explaining the prohibition, plus `QuickActionGrid.swift`'s unrelated CSS-class design reference). Pinned by the one-request assertion in the suite.

## ChatLifecycleTests Changes
None — exactly as the plan expected. The AUTH-03 fence (ChatLifecycleTests, SSEParserTests, PaywallOutOfCreditsGuardTests) ran unmodified and green after all edits.

## Files Created/Modified
- `StressMonitor/StressMonitor/Models/ServerQuickAction.swift` - Codable/Sendable/Identifiable/Equatable DTO; doc comment explains why `type` stays String
- `StressMonitor/StressMonitor/Services/API/StressAPIClient+QuickActions.swift` - QuickActionsAPIError (.unauthorized/.invalidResponse/.server) + the single GET with URLComponents query + private `{quick_actions}` envelope
- `StressMonitor/StressMonitor/Services/LLM/ChatQuickActions.swift` - + `prompt(forServerActionId:)` seven-entry verbatim mirror with lockstep doc note
- `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` - quickReplies/fetchedQuickActions state, preferencesService seam, fetchQuickActions(), prefs-fed build call; quickActions/sendQuickAction removed
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` - @Environment(PreferencesService.self), onAppear prefs+fetch wiring, chips ForEach over quickReplies, defaultQuickReplies removed
- `StressMonitor/StressMonitor/Views/Chat/QuickActionChipsView.swift` - DELETED (zero references verified before deletion)
- `StressMonitor/StressMonitorTests/StressAPIClientQuickActionsTests.swift` - 4 tests; registered at pbxproj IDs A022/B022 (4-line pattern; plutil lint OK)
- `StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift` - +5 chips/prefs cases + waitFor helper (chips belong to the chat-open lifecycle; same suite, no new registration)
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` - A022/B022 registration

## Decisions Made
- **Server chip icon:** mapped to the constant `"sparkles"` rather than a per-id SF Symbol table — the live chip surface renders `reply.title` only (identical styling preserved per CONTEXT); a per-id icon map would be speculative dead data.
- **Fetch-guard ordering:** `fetchedQuickActions = true` precedes the `apiClient` guard (plan-specified): the sheet assigns `apiClient` in the same `onAppear` before kicking the fetch, and one-shot semantics must survive re-appear regardless.
- **PreferencesService injection as the concrete type** (no protocol): same-module consumer; tests exercise the real request path by seeding the service through a stubbed `/preferences` GET — consistent with the 03-02 no-protocol decision.
- **Test seam for the swap:** `RequestCaptureURLProtocol.responseByPath` keys on `request.url?.path`, so `/quick-actions` stubs work for query-carrying URLs without changes to the double.

## Verification Results
- `StressAPIClientQuickActionsTests` — 4/4, exit 0 (exact query URL + Bearer + one-request, unknown-type decode, 401, prompt table 7+1)
- Targeted fence run (ChatHistoryRestoreTests incl. 5 new cases, ChatLifecycleTests, SSEParserTests, PaywallOutOfCreditsGuardTests, StressAPIClientQuickActionsTests) — `Test run with 24 tests in 5 suites passed`, TEST SUCCEEDED, exit 0
- Full `StressMonitorTests` suite with `-parallel-testing-enabled NO` — xcresult: 203 passed / 6 failed / 15 skipped; ALL 6 failures are crashes in `DataDeleterFailureAndCancellationTests` and `DataExportFieldSelectionTests` — the pre-existing WINDOWS.md entry #8 TEST-01 host-restart lineage (files untouched by this plan; same signature 03-01 recorded, no new ledger entry needed). Zero assertion failures; every suite this plan touched passed. Pass bar per the documented convention: all distinct suites green, targeted runs exit 0.
- Acceptance greps: `authorizedRequest`=1 / `method: "GET"`=1 / `"POST"`=0 in +QuickActions; cutover grep (`QuickActionChipsView|sendQuickAction` in app sources) = 0; `defaultQuickReplies` = 0; `enum ChatQuickActions` = 1
- Fence diff: `git diff c8ca46b..HEAD` (incl. working tree) over LLMServiceProtocol.swift / SSEParser.swift / StressLLMService.swift / Premium paths — empty; mapHTTPError untouched

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Three Edit-tool misalignments while inserting into ChatViewModel/ChatQuickActions (block-boundary landing) produced transient broken syntax; each was caught by the tool's syntax probe and repaired with a follow-up anchored edit before any build/test/commit ran. No commit contains a broken state.
- Full-suite environmental exit (see Verification Results) — documented WINDOWS.md #8 lineage, not re-recorded.

## TDD Gate Compliance
- Task 1: RED `55073b9` (compile failure on missing types = failing state) → GREEN `432a008`. REFACTOR omitted — nothing to clean.
- Task 2: RED `865a3f9` (compile failure on missing members) → GREEN `7987f39`. REFACTOR omitted — chat suites re-run green in the targeted run; sheet diff minimal by construction.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 03-04 (factory-reset server wipe + cleanup): `listSessions`/`deleteSession` are already pinned; the DataDeleter loop + ServerSessionWiping seam remain. `ChatViewModel` edits are done — 03-04 should not need to touch chat surfaces.
- Live chips behavior (server suggestions reacting to stress level through the deployed backend) rides the 03-05 UAT script, as does the Settings visual confirmation deferred from 03-02.
- derived-PREF-02 is now fully complete (Settings half from 03-02 + call-site half from this plan).

---
*Phase: 03-sessions-preferences-quick-actions-cleanup*
*Completed: 2026-08-23*

## Self-Check: PASSED

- All 3 created files exist on disk; QuickActionChipsView.swift confirmed deleted
- All 4 task commits (55073b9, 432a008, 865a3f9, 7987f39) present in git log
- Acceptance greps re-verified post-commit: authorizedRequest=1, POST=0, cutover=0, defaultQuickReplies=0, enum ChatQuickActions=1, prompt map=1

---
phase: 03-sessions-preferences-quick-actions-cleanup
fixed_at: 2026-08-23T19:05:00Z
review_path: .planning/phases/03-sessions-preferences-quick-actions-cleanup/03-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 3: Code Review Fix Report

**Fixed at:** 2026-08-23T19:05:00Z
**Source review:** 03-REVIEW.md
**Iteration:** 1
**Branch:** `gsd/v1.1-backend-api-migration`

**Summary:**
- Findings in scope: 6 (1 critical, 4 warnings, 1 info)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: Factory-reset server wipe advances the offset past surviving sessions

**Files modified:** `DataDeleterService.swift`, `DataDeleterServerWipeTests.swift`
**Commit:** e374f3a
**Applied fix:** `wipeServerSessions()` now re-queries page 1 (`offset: 0`) every
iteration — the backend paginates `order by updated_at desc limit/offset` over live
rows, so every fetched row is deleted before the next read and the window must stay
pinned. Page cap (50), skip-vs-fail semantics, and ordering before CloudKit/local
wipe are unchanged. The test fake gained a `.store` behavior that mirrors live-row
pagination (`dropFirst(offset).prefix(limit)` over a store that `deleteSession`
removes from), and a 42-session regression test asserts the store is empty, all
lists use `offset:0` (4 calls: 20/20/2/empty), all 42 deletes issue, and the reset
still completes. The scripted-pages test's expected call sequence was updated to
offset 0. Under the old loop this regression test fails with 20 survivors — it no
longer masks the bug.

### WR-01: Trend window selects the oldest 5 measurements

**Files modified:** `StressContextPayload.swift`, `StressContextPayloadTests.swift`
**Commit:** adc05fa
**Applied fix:** `recentHistory.suffix(...)` → `recentHistory.prefix(...)` — on the
documented newest-first delivery order, `prefix` is the newest-5 window (then
`.reversed()` restores chronological order for the delta, per the CR-02 fix). Two
>5-element regression tests added: newest-first `[80,20,20,20,20,20]` →
`increasing`/`+60%` (old code: `stable`), and `[20,20,20,20,20,80]` → `stable`
(old code: `decreasing`).

### WR-02: Preferences never seed at chat open

**Files modified:** `ChatViewModel.swift`, `ChatBottomSheetView.swift`, `ChatHistoryRestoreTests.swift`
**Commit:** 90e3c2e
**Applied fix:** New `ChatViewModel.hydratePreferencesAndFetchQuickActions()`
(seed-once, best-effort → then the one-shot chips fetch) called from
`ChatBottomSheetView.onAppear` as a fire-and-forget Task, replacing the bare
`fetchQuickActions` Task. Seed-once semantics unchanged (never writes). New test
pins the ordering: GET `/preferences` strictly precedes GET `/quick-actions`, and
the chips query carries the seeded pair (`language=vi&coaching_style=direct`),
matching COVERAGE row 14.

### WR-03: Chips swap can render an empty row under full backend drift

**Files modified:** `ChatViewModel.swift`, `ChatHistoryRestoreTests.swift`
**Commit:** 6d0fdd8
**Applied fix:** `fetchQuickActions()` resolves the server ids into
`resolved: [ChatQuickAction]` and only replaces `quickReplies` when non-empty —
if every id is unknown to the local mirror (or the page is empty), the local
fallback set stays and the row never goes blank. New test with an all-unknown-ids
page asserts the fallback titles/prompts survive.

### WR-04: Overlapping preference updates can interleave stale reverts

**Files modified:** `PreferencesService.swift`, `PreferencesServiceTests.swift`, `StressAPIClientTests.swift`, `StressAPIClientPreferencesTests.swift`
**Commit:** c2d6922
**Applied fix:** Updates are serialized through an in-flight task chain
(`updateChain`): each `update(...)` enqueues after the previous one fully settled
(PUT resolved, revert applied, error surfaced), and the revert value is read
*inside* the serialized section — so a failure always reverts to the value the
user actually saw, never past a newer optimistic value (all four completion orders
converge). The shared `RequestCaptureURLProtocol` test double gained a
`statusCodeSequence` (per-request statuses in dispatch order, mirroring the
existing `responseByPath` additive pattern) for the new overlapping-updates test:
PUT #1 (`vi`) fails 500, PUT #2 (`fr`) succeeds 200 → final local state `fr`
matches the server, `errorMessage == nil`, both PUT bodies pinned. The
preferences-suite helpers also reset `responseByPath`/`statusCodeSequence`
(mirroring `StressAPIClientQuickActionsTests.makeClient`), closing the
order-dependent static pollution (WINDOWS.md #12) that the new `/preferences`
stubs in `ChatHistoryRestoreTests` exposed; the two new ChatHistoryRestoreTests
tests clear `responseByPath` via `defer` as producer-side hygiene.

### IN-01: Superfluous `await` on same-actor `adopt(sessionId:)`

**Files modified:** `StressLLMService.swift`
**Commit:** ac54f3d
**Applied fix:** Dropped the `await` on `self.adopt(sessionId: created.id)` — the
`Task {}` inherits main-actor isolation and `adopt` is synchronous `@MainActor`,
confirmed trivially safe by a full app+test-target build.

## Verification

**Where gates ran:** main checkout on `gsd/v1.1-backend-api-migration` (per
orchestrator instruction — `03-REVIEW.md` is untracked and only exists here; no
review worktree was created). Numbers are reproducible from this tree.

1. `xcodebuild build-for-testing -scheme StressMonitor -project
   StressMonitor/StressMonitor.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
   -parallel-testing-enabled NO` → **TEST BUILD SUCCEEDED** (all 6 fixes compile;
   one intermediate closure-inference error fixed by an explicit
   `[ChatQuickAction]` annotation before any commit).
2. Targeted suites (`xcodebuild test … -parallel-testing-enabled NO` with 8
   `-only-testing` filters): first run **failed 10 issues** — cross-suite
   `responseByPath` static pollution (known WINDOWS.md #12 class) newly exposed
   because the new tests stub `/preferences`; fixed at both seams (see WR-04
   above). Re-run: **51 tests in 7 suites PASSED, exit 0** —
   DataDeleterServerWipeTests, StressContextPayloadTests, ChatHistoryRestoreTests,
   PreferencesServiceTests, StressAPIClientPreferencesTests, StressAPIClientTests,
   StressAPIClientQuickActionsTests, ChatLifecycleTests. **0 assertion failures,
   0 crashes** (no #8-lineage restarts in the targeted set).
3. Adjacent consolidation suites (`DataDeleterConsolidationTests`,
   `DeleteAllCredentialClearanceTests`, `ExportProtectionTests`,
   `DataDeleterScopedDeletionTests`): **9 tests in 4 suites PASSED, exit 0**.

**Fence check:** no SSEParser / LLMServiceProtocol / Premium-path changes;
`mapHTTPError` untouched; no `POST /quick-actions` introduced (chips tests GET
only); data-deletion ordering (wipe → CloudKit → credentials) and skip-vs-fail
semantics unchanged.

---

_Fixed: 2026-08-23T19:05:00Z_
_Fixer: Claude (gsd-code-fixer / Phase3CodeFixer)_
_Iteration: 1_

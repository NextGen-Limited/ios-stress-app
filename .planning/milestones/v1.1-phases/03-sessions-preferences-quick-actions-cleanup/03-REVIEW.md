---
phase: 03-sessions-preferences-quick-actions-cleanup
reviewed: 2026-08-23T12:30:00Z
fixed_at: 2026-08-23T19:05:00Z
depth: deep
status: fixed
reviewed_commits: 4681792..5681d6f (pre-phase base 02b6de4)
files_reviewed: 29
files_reviewed_list:
  - StressMonitor/StressMonitor/Models/ChatSession.swift
  - StressMonitor/StressMonitor/Models/ChatSessionMessage.swift
  - StressMonitor/StressMonitor/Models/ServerQuickAction.swift
  - StressMonitor/StressMonitor/Models/UserPreferences.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient+Sessions.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient+Preferences.swift
  - StressMonitor/StressMonitor/Services/API/StressAPIClient+QuickActions.swift
  - StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift
  - StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift
  - StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift
  - StressMonitor/StressMonitor/Services/LLM/ChatQuickActions.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleter.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
  - StressMonitor/StressMonitor/StressMonitorApp.swift
  - StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift
  - StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift
  - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
  - StressMonitor/StressMonitorTests/StressAPIClientSessionsTests.swift
  - StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientPreferencesTests.swift
  - StressMonitor/StressMonitorTests/PreferencesServiceTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientQuickActionsTests.swift
  - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
  - StressMonitor/StressMonitorTests/StressContextPayloadTests.swift
  - StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift
  - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - .gitignore / design/screens/25-about.html (cleanup edits)
findings:
  critical: 1
  warning: 4
  info: 1
  total: 6
---

# Phase 3: Code Review Report

**Reviewed:** 2026-08-23T12:30:00Z
**Depth:** deep (per-file + cross-file: backend SQL semantics, repository delivery-order contract, environment propagation through sheets, fake-vs-live divergence analysis)
**Commits:** `4681792..5681d6f` (base `02b6de4`), branch `gsd/v1.1-backend-api-migration`
**Files Reviewed:** 29 source/test/config files (all phase-touched `StressMonitor/` paths)
**Status:** all findings fixed — 6/6 applied in `e374f3a..ac54f3d` (see 03-REVIEW-FIX.md)

## Summary

The API layer is well built: DTOs decode defensively (String dates for fractional-second timestamptz, snake_case keys, unknown keys ignored), query URLs are built via `URLComponents` with exact-URL test pins, error enums are typed per endpoint group, and the Phase 2 regression fence is genuinely intact (`mapHTTPError` byte-identical, SSEParser/LLMServiceProtocol/Premium diffs empty, 402→paywall path untouched). The revenue prohibition holds — no `POST /quick-actions` anywhere in app sources (doc-comment mentions only). Test suites assert real behavior (exact URLs, body-count==1, captured-request ordering, post-await no-clobber with a delayed URLProtocol).

However, the **factory-reset server-session wipe has a critical pagination defect**: the loop advances the query offset after deleting the page it just fetched, against a live backend that paginates `order by updated_at desc limit/offset` over remaining rows. Every page after the first is skipped, so any user with more than 20 server chat sessions keeps a residue on the server while the reset reports success — a direct violation of the phase's own DATA-01 bar ("delete actually deletes everywhere"). The unit test's fake serves scripted pages by call index and never removes deleted rows, masking the bug. Proven by simulation against the backend's actual pagination semantics (42 sessions → 20 survive).

Three further warnings cover: the CR-02 trend fix selecting the wrong 5-measurement window (`suffix` on a newest-first array = the *oldest* rows), the preferences seed never running at chat open despite the documented contract (COVERAGE row 14), and two smaller robustness/concurrency gaps.

## Critical Issues

### CR-01: Factory-reset server wipe advances the offset past surviving sessions — partial deletion reported as success

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:492-507` (offset advance at `505`)
**Pattern:** delete-while-offset-paginating (window shifts after each deletion)
**Status:** ✅ fixed in `e374f3a` — offset pinned at 0; deletion-aware store fake + 42-session regression test pin the loop

**Issue:** `wipeServerSessions()` fetches `listSessions(limit: 20, offset: offset)`, deletes every row in the page, then does `offset += page.count`. The backend (`stress-app-be/src/routes/sessions.ts:10-16`) executes `select … order by updated_at desc limit ${limit} offset ${offset}` **over the live table** — deleting the first 20 rows shifts rows 21+ into positions 1-20, so the next fetch at `offset: 20` skips them entirely.

Concrete trace with 42 sessions:
- `list(offset:0)` → rows 1-20, deleted. Server now has 22 rows.
- `offset += 20` → `list(offset:20)` → skips all 22 remaining rows → **empty page** → loop returns "success".
- Result: sessions 21-40 survive; reset proceeds to CloudKit/local wipe, clears `stressChatSessionId`, and reports "Factory reset complete" — the user believes all server chat history is gone. Any user with >20 sessions hits this; 21-40 sessions leaves 1-20 behind.

This defeats `derived-SES-03` and the DATA-01 acceptance bar for exactly the users with the most chat history. The unit test does not catch it because `FakeServerSessionWiper.behavior: .pages` (`DataDeleterServerWipeTests.swift:16-49`) serves scripted pages by call index and its `deleteSession` is a no-op recorder — the fake's list never shrinks, unlike the real backend.

**Verification:** simulated the exact loop against a mutating array mirroring the backend SQL:
```
Surviving sessions after 'wipe': 20 -> [21, 22, ..., 40]   // 42 sessions, shipped loop
Surviving with offset pinned to 0: 0                       // correct loop
```

**Fix:**
```swift
private func wipeServerSessions() async throws {
    guard let serverSessionWiper else { … }
    let pageSize = 20
    let maxPages = 50
    var pagesFetched = 0
    while pagesFetched < maxPages {
        // Every fetched row is deleted before the next page is read, so the
        // window must stay pinned at 0 — advancing the offset skips rows that
        // shifted up after the previous page's deletion.
        let page = try await serverSessionWiper.listSessions(limit: pageSize, offset: 0)
        if page.isEmpty { return }
        for session in page {
            try await serverSessionWiper.deleteSession(id: session.id)
        }
        pagesFetched += 1
    }
    logger.log("Server session wipe aborted after \(maxPages) non-empty pages — server misbehaving")
    throw URLError(.badServerResponse)
}
```
Also make the fake honest: give `FakeServerSessionWiper` a mutable store that `deleteSession(id:)` removes from, and add a regression test seeding >2×pageSize sessions asserting the store is empty after `performFactoryReset()` (the scripted-pages test can keep pinning the call sequence with offset pinned at 0).

## Warnings

### WR-01: CR-02 fix selects the oldest window — `suffix(5)` on a newest-first array drops the newest measurements

**File:** `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift:87`
**Pattern:** wrong window selection under documented delivery order
**Status:** ✅ fixed in `adc05fa` — `prefix` window + two >5-element regression tests (newest-window direction, oldest-row exclusion)

**Issue:** The CR-02 fix reversed the slice to fix trend *direction*, but the slice itself is still `recentHistory.suffix(min(5, max(2, count)))`. The function's own doc comment and its new tests declare the input newest-first (`StressRepository.fetchRecent` sorts `timestamp .reverse`, confirmed at `StressRepository.swift:85-88`). On a newest-first array, `suffix(5)` returns the **oldest** 5 measurements and silently drops the newest ones. Example (newest-first `[80, 20, 20, 20, 20, 20]`): the true recent trend is `20 → 80` = increasing, but `suffix(5)` yields `[20,20,20,20,20]` → "stable" — wrong direction and wrong delta. The four new regression tests all use 2-element fixtures (`StressContextPayloadTests.swift:55-93`), where `suffix == prefix == whole array`, so the window selection is never exercised.

Currently latent: both live call sites (`ActionView.swift:59`, `SettingsView.swift:76`) pass `ChatBottomSheetView(stressResult: nil, baseline: nil)` with `recentHistory` defaulting to `[]`, so `stressTrend` is nil in production today — but the builder's documented contract makes any future caller with >5 rows wrong.

**Fix:**
```swift
// Newest-first input: prefix(5) is the most-recent window; reversed → chronological.
let recent = recentHistory.prefix(min(5, max(2, recentHistory.count)))
```
and add a regression test with >5 newest-first measurements asserting the trend uses the newest window (e.g. newest-first `[80, 20, 20, 20, 20, 20]` → "increasing", `"+60%"`).

### WR-02: Preferences never seed at chat open — doc comment, COVERAGE row 14, and the locked decision all say they should

**Pattern:** documented behavior not implemented at the consuming surface
**Status:** ✅ fixed in `90e3c2e` — `hydratePreferencesAndFetchQuickActions()` seeds then fetches at chat open; order pinned by test

**Issue:** `PreferencesService`'s doc comment states "Repeated surfaces (Settings onAppear, **chat open**) call `seedIfNeeded()`", and COVERAGE row 14 records the seed as "one-time seed at first surface (chat open / Settings onAppear)". In the code, `seedIfNeeded()` has exactly one call site: `SettingsView.swift:69`. `ChatBottomSheetView.onAppear` assigns the service and immediately fires `fetchQuickActions()` without seeding. Consequence: a user who never opens Settings chats with `language`/`coachingStyle` stuck at the hardcoded `en`/`supportive` defaults even when the server row says `vi`/`direct` (set on another device, a prior install, or a reinstall) — the chips query (`one-shot per presentation`) and every stress-context payload then carry the wrong preference pair, defeating the derived-PREF-02 "one source of truth" goal at its primary consumption surface.

**Fix:** seed (idempotently) before the one-shot chips fetch in `ChatBottomSheetView.onAppear`:
```swift
viewModel.preferencesService = preferencesService
Task {
    await preferencesService.seedIfNeeded()
    await viewModel.fetchQuickActions()
}
```

### WR-03: Chips swap can render an empty row when every server id is unknown to the local mirror

**File:** `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift:149-158`
**Pattern:** degraded fallback invariant violated under backend drift
**Status:** ✅ fixed in `6d0fdd8` — swap only on non-empty resolved list; all-unknown-ids regression test keeps the fallback row

**Issue:** `fetchQuickActions()` unconditionally replaces `quickReplies` with `serverActions.compactMap { … prompt(forServerActionId:) }`. Unknown ids are dropped by design — but if **all** returned ids are unknown (backend ships new suggestion ids before an app update catches up; the mirror table in `ChatQuickActions.prompt` is lockstep-manual), `quickReplies` becomes `[]` and the chip row disappears entirely, breaking the stated invariant "server-driven UI swap keeps a guaranteed local render first" (03-03 patterns-established). The existing test only covers a mixed page (1 unknown of 3 → 2 chips).

**Fix:** keep the fallback when nothing resolves:
```swift
let resolved = serverActions.compactMap { action in … }
if !resolved.isEmpty {
    quickReplies = resolved
}
```

### WR-04: Overlapping preference updates can interleave — a stale revert clobbers a newer optimistic value

**File:** `StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift:53-76`
**Pattern:** unsynchronized optimistic updates sharing one mutable field
**Status:** ✅ fixed in `c2d6922` — updates chained through an in-flight task; revert value read inside the serialized section; overlapping-updates test pins final state

**Issue:** `updateField` captures `revertValue` at call time, applies optimistically, then awaits the PUT. Two rapid changes to the same field interleave: update A (`en→vi`, revertValue `en`) and update B (`vi→fr`, revertValue `vi`) both in flight. If A's PUT fails after B applied `fr`, A reverts to `en` — the local value now contradicts the server (B's PUT persists `fr`), and a subsequent B-success clears `errorMessage` while the state is wrong. `@MainActor` serializes the synchronous parts but not the awaits. Requires rapid successive picker taps with a failing first PUT — an edge case, but it silently diverges local state from the server row.

**Fix:** serialize updates (chain them through a single in-flight task) or guard the revert: only `apply(revertValue)` if the current value still equals the optimistic `newValue` (generation-token pattern); likewise only set `errorMessage` if this failure is the latest operation.

## Info

### IN-01: Superfluous `await` on a synchronous, same-actor call

**File:** `StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift:87`
**Status:** ✅ fixed in `ac54f3d` — `await` dropped; full-target build confirms same-actor call needs no suspension
**Fix:** drop the `await` (`self.adopt(sessionId: created.id)`).

## Fence & Gate Verification (review priorities)

| Priority | Result |
|---|---|
| Phase 2 fence untouched | **PASS** — `git diff 02b6de4..HEAD` over `SSEParser.swift`, `LLMServiceProtocol.swift`, `Views/Premium/`, `Services/Premium/` is empty; `mapHTTPError` body byte-identical (`diff` of extracted function bodies → identical); ChatViewModel's 402 branch untouched |
| Revenue prohibition (no `POST /quick-actions`) | **PASS** — app-source grep: only doc-comment mentions + the single GET path construction (`StressAPIClient+QuickActions.swift:44`); no POST to the route anywhere; `+QuickActions` holds exactly one request method, `method: "GET"` |
| Data-deletion ordering | **PARTIAL** — wipe is Phase 0 (before CloudKit, before `clearCredentialsAndSharedCaches`/sign-out ✓); skip-vs-fail classification matches the locked Q2 decision and the real signed-out error shape (`FirebaseAuthService.getIDToken` throws `LLMServiceError.unavailable`, verified at `FirebaseAuthService.swift:47-50`) ✓; `stressChatSessionId` cleared unconditionally on both paths ✓ — but the wipe itself is incomplete past page 1 (**CR-01**) |
| Session lifecycle | **PASS** — titled-create-before-send order-pinned (`capturedRequests[0]==POST /sessions` before `[1]==POST /chat`); fail-soft on 500; id survives reconstruction (UserDefaults write-through); 404 → `resetSession()`; no clobber via post-await `messages.isEmpty` re-check with `DelayedResponseURLProtocol`; fresh VM per presentation prevents reopen duplication |
| Preferences | **PASS with WR-02/WR-04** — single-field PUTs (body-count==1 asserted), seed-once never writes (no defaults-overwrite), optimistic revert-on-failure pinned; chat-open seeding missing (WR-02), update interleaving (WR-04) |
| DTO decoding | **PASS** — dates as String with fractional-second fixtures; snake_case CodingKeys throughout; unknown keys and unknown `type` strings tolerated |
| Concurrency | **PASS** — `@MainActor` on `StressAPIClient`/`PreferencesService`/`ChatViewModel`/`DataDeleterService`; `ServerSessionWiping: Sendable`; DTOs `Sendable`; `nonisolated(unsafe)` statics confined to test doubles |
| Test quality | **PASS with caveats** — suites assert real contracts (exact URLs, Bearer headers, body counts, ordering, post-await guards); pbxproj registrations complete and purely additive (A018-A023/B018-B023); **caveat**: the wipe fake is deletion-blind and masks CR-01; trend tests use 2-element fixtures and miss WR-01 |
| Supabase cleanup | **PASS** — `.gitignore` line and `25-about.html` row removed; KEEP sites (`FirebaseAuthService.swift`, `DataDeletionConsolidationTests.swift`) byte-identical; prompt mirror verified verbatim against `stress-app-be/src/lib/quick-actions.ts:56-67` |

## Known Accepted Issues (referenced, not re-reported)

- **WINDOWS.md #8** — pre-existing DataDeletion-family host-crash restarts in full-suite runs (crash lineage; not introduced by this phase).
- **WINDOWS.md #12 / GAP-1** — order-dependent `RequestCaptureURLProtocol.responseByPath` static pollution from `ChatHistoryRestoreTests` (already ledgered with a candidate fix at the owning seam; not re-counted here).

## Verify

Commands run during this review (all from repo root unless noted):

```bash
git log --oneline 02b6de4..HEAD -- StressMonitor/                 # 17 phase commits confirmed
git diff --stat 02b6de4..HEAD -- StressMonitor/                   # 29 files, +2281/-79
git diff 02b6de4..HEAD -- .../SSEParser.swift .../LLMServiceProtocol.swift .../Views/Premium/ .../Services/Premium/   # empty → fence intact
git show 02b6de4:.../StressLLMService.swift | sed -n '/static func mapHTTPError/,/^    }$/p' > before; sed -n (same) > after; diff  # IDENTICAL
grep -rn "quick-actions" StressMonitor/StressMonitor --include='*.swift'  # GET-only; POST only in doc comments
git diff 02b6de4..HEAD -- StressMonitor/StressMonitor.xcodeproj/project.pbxproj  # 6 suites registered, purely additive
# CR-01 proof — simulation of the shipped loop vs backend SQL semantics
# (stress-app-be sessions.ts: `order by updated_at desc limit ${limit} offset ${offset}`):
swift /tmp/wipe_sim.swift
#   Surviving sessions after 'wipe': 20 -> [21...40]   (42 seeded, shipped loop)
#   Surviving with offset pinned to 0: 0               (corrected loop)
grep -n "order by\|offset\|limit" ../stress-app-be/src/routes/sessions.ts       # live-table pagination confirmed
grep -n "SortDescriptor" StressMonitor/StressMonitor/Services/Repository/StressRepository.swift  # newest-first contract
grep -rn "seedIfNeeded" StressMonitor/StressMonitor/                              # single call site (SettingsView:69)
grep -rn "ChatBottomSheetView(" StressMonitor --include='*.swift'                # 2 sites, both recentHistory-free
grep -n "getQuickActionPrompt" -A12 ../stress-app-be/src/lib/quick-actions.ts   # mirror verified verbatim (7/7)
grep -n "throw LLMServiceError.unavailable" .../FirebaseAuthService.swift:47-50 # signed-out skip shape confirmed
git diff 02b6de4..HEAD -- StressMonitor/ | grep "^+" | grep -E "print\(|TODO|FIXME|secret|password"  # empty
```

Note on scope: this is a read-only review; no targeted `xcodebuild test` re-run was performed here (per task constraints), so test-execution evidence relies on the 03-05 gate record plus the static analysis above. The two defects that tests mask (CR-01, WR-01) are proven by direct simulation of the shipped logic against the verified backend semantics.

---

_Reviewed: 2026-08-23T12:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_

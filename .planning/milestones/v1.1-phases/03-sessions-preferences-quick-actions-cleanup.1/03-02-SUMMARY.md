---
phase: 03-sessions-preferences-quick-actions-cleanup
plan: 02
subsystem: preferences
tags: [preferences, api, urlprotocol, swift-testing, settings, trend-fix, cr02]

# Dependency graph
requires:
  - phase: 03-sessions-preferences-quick-actions-cleanup (plan 01)
    provides: StressAPIClient extension pattern + authorizedRequest(path:), RequestCaptureURLProtocol test double, CreditService service shape precedent
provides:
  - UserPreferences Codable DTO (language + coachingStyle two-field decode of the backend row)
  - StressAPIClient+Preferences (getPreferences / updatePreferences single-field PUT) + PreferencesAPIError
  - PreferencesService (@MainActor @Observable: seed-once GET, optimistic update, revert-on-failure, errorMessage)
  - CR-02 fix: StressContextPayload.build trend computed in chronological order regardless of newest-first input
  - SettingsView "AI Coach" section (closed en/vi + supportive/direct/educational pickers) + app-scope PreferencesService environment injection
affects: [03-03, 03-05]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 8900
  tasks: 3
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "updateField(_ field:newValue:revertValue:apply:) shared optimistic/revert skeleton — one place owns set-PUT-keep/revert semantics"
    - "Picker rows whose value text is labeled from service state (not the option list) so out-of-set server values still display"
    - "Seed-once guard (hasSeeded) as the pragmatic GET-at-first-surface equivalent — no signed-in callback exists"

key-files:
  created:
    - StressMonitor/StressMonitor/Models/UserPreferences.swift
    - StressMonitor/StressMonitor/Services/API/StressAPIClient+Preferences.swift
    - StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift
    - StressMonitor/StressMonitorTests/StressAPIClientPreferencesTests.swift
    - StressMonitor/StressMonitorTests/PreferencesServiceTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift
    - StressMonitor/StressMonitorTests/StressContextPayloadTests.swift
    - StressMonitor/StressMonitor/StressMonitorApp.swift
    - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "PreferencesServiceProtocol NOT needed this phase: same-module consumers (SettingsView now, ChatViewModel in 03-03) and tests inject the concrete StressAPIClient through URLProtocol stubbing, exercising the real request path"
  - "On update success the optimistic value stands (the server persisted exactly it); the decoded response row is deliberately not re-mapped — revert happens only on throw"
  - "Seed failures stay silent by design (best-effort background hydration); hasSeeded stays false so a later surface retries"
  - "Picker value text is labeled from PreferencesService state, so a server value outside the closed option set (e.g. language 'fr') still displays instead of hiding"

patterns-established:
  - "Pattern: single-field PUT dictionary param ([String: String]) with body-count == 1 asserted in tests — structurally prevents a save-all"
  - "Pattern: XCTest and Swift Testing suites coexist in the same target; new suites follow the Swift Testing struct shape"

requirements-completed: [derived-PREF-01, derived-CR02]

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Preferences API client extension: GET decode of the chat pair from a full backend row, single-field PUT (body count == 1), 400 -> noValidFields, 401 -> unauthorized"
    requirement: derived-PREF-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StressAPIClientPreferencesTests.swift (6 @Test functions, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "PreferencesService semantics: migration defaults, seed-once GET guard with pair mapping, silent failed seed + retry, optimistic update with revert-on-500 and surfaced errorMessage"
    requirement: derived-PREF-01
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/PreferencesServiceTests.swift (5 @Test functions, exit 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "CR-02 closure: trend direction computed chronologically from newest-first history (rising -> increasing, falling -> decreasing, +/-5 -> stable, single -> nil)"
    requirement: derived-CR02
    verification:
      - kind: unit
        ref: "StressMonitor/StressMonitorTests/StressContextPayloadTests.swift (4 new test funcs; suite 7/7 exit 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "AI Coach Settings section + app-scope PreferencesService wiring: closed pickers, seeding onAppear, error footnote; visual confirmation rides the 03-05 UAT script"
    requirement: derived-PREF-02
    verification:
      - kind: build
        ref: "xcodebuild build ... BUILD SUCCEEDED; both Task 2 suites re-run green after wiring"
        status: pass
    human_judgment: true

# Metrics
duration: 14min
completed: 2026-08-23
status: complete
---

# Phase 3 Plan 2: Preferences Sync + CR-02 Summary

**UserPreferences DTO + StressAPIClient+Preferences + PreferencesService (seed-once, optimistic, revert-on-failure) + the Settings AI Coach section, with the deferred CR-02 trend inversion fixed in the same builder — all URLProtocol-pinned and the Phase-2 chat fence green**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-08-23T09:58:50Z
- **Completed:** 2026-08-23T10:12:20Z
- **Tasks:** 3 (Tasks 1-2 TDD: RED → GREEN; Task 3 auto)
- **Files:** 10 (5 created, 5 modified)

## Accomplishments
- **CR-02 closed:** `StressContextPayload.build` now reverses the newest-first `recentHistory` slice to chronological order before the delta, so the trend label and the sign of `stressTrendDelta` match what the user experienced. Pinned by four new cases in the existing XCTest suite (`testTrendIncreasingWhenStressRoseOverTime`, `testTrendDecreasingWhenStressFellOverTime`, `testTrendStableWhenFluctuationWithinThreshold`, `testTrendNilForSingleMeasurement`); the three privacy tests stay green untouched.
- **Preferences API layer:** `StressAPIClient+Preferences` on the Credits template — `getPreferences()` (GET, full-row decode into the two-field DTO, five other allowlisted fields silently ignored) and `updatePreferences(fields:)` (PUT with exactly one JSON key; 400 → `.noValidFields`, 401 → `.unauthorized`). Pinned by `StressAPIClientPreferencesTests` (6 tests, exact-URL + Bearer + body-count == 1 assertions).
- **PreferencesService** (`@MainActor @Observable`): migration defaults `en`/`supportive`, seed-once `seedIfNeeded()` (silent on failure, retried by later surfaces, never writes — T-3-06), and optimistic single-field updates through one shared `updateField` skeleton that reverts and surfaces `errorMessage` on throw (T-3-08). Pinned by `PreferencesServiceTests` (5 tests).
- **Settings AI Coach section + app wiring:** one app-scope `PreferencesService` injected beside `creditService`; the section offers the closed language picker (English/Tiếng Việt) and coaching-style picker (Supportive/Direct/Educational) mirroring the backend vocabulary, seeds in the existing `onAppear`, and shows the service's `errorMessage` as a footnote under the card. Value text is labeled from state, so an out-of-set server value still displays.

## Task Commits

1. **Task 1: CR-02 trend fix (RED → GREEN)** - `4cb99fa` (test: 4 failing trend cases; rising/falling failed against the inverted delta exactly as diagnosed) → `56bdedc` (feat: `Array(recent.reversed())` chronological restore). No REFACTOR — pure computation fix, nothing to clean.
2. **Task 2: DTO + API extension + service (RED → GREEN)** - `3f9a4c9` (test: both suites, compile-failing on the missing types; pbxproj A020/B020 + A021/B021) → `8044cda` (feat: three implementation files). REFACTOR born-in: the two update methods share the `updateField` optimistic/revert skeleton from the first GREEN write, so no separate refactor commit.
3. **Task 3: App-root wiring + AI Coach section (auto)** - `9410ad5` (feat: StressMonitorApp environment injection + SettingsView section).

**Plan metadata:** (this commit)

## CR-02 Closure Confirmation
- RED evidence: `testTrendIncreasingWhenStressRoseOverTime` failed with `("decreasing")` ≠ `("increasing")` and `("-30%")` ≠ `("+30%")` — the exact inversion 01-REVIEW CR-02 described; mirror failure on the falling case.
- GREEN evidence: `Executed 7 tests, with 0 failures` — all four new trend cases plus the three privacy invariants.
- Scope guard: the diff touches only the trend block (`recent.reversed()` added, threshold/format/force-unwraps identical); wire keys unchanged.

## Language-Picker Resolution (recorded per plan output)
- Backend passes any non-"en" language straight into the system prompt (`Respond in ${language}.` — stress-app-be openrouter.ts:65) and its own suite pins `language: "vi"` (openrouter.test.ts:111-118) — so the picker ships exactly **English ("en") and Tiếng Việt ("vi")**, no checkpoint needed.
- Coaching style is a closed server-side union (supportive/direct/educational; unknown values silently fall back to supportive), so the picker offers exactly those three; a current value outside either set still displays because the row text is labeled from service state, not the option list (Pitfall 8).

## PreferencesServiceProtocol: Not Needed
No protocol was created. Consumers are same-module (SettingsView now; ChatViewModel's call-site read lands in 03-03), and both test suites inject the **concrete** `StressAPIClient` built on the `RequestCaptureURLProtocol` stub — exercising the real request-building path end-to-end. If 03-03's ChatViewModel test seam ends up needing protocol injection, add `PreferencesServiceProtocol` beside the implementation then (LLMServiceProtocol precedent); do not pre-build it.

## Files Created/Modified
- `StressMonitor/StressMonitor/Models/UserPreferences.swift` - two-field Codable DTO; doc comment records the five deliberately-ignored allowlisted fields
- `StressMonitor/StressMonitor/Services/API/StressAPIClient+Preferences.swift` - `PreferencesAPIError` + getPreferences/updatePreferences on the Credits template
- `StressMonitor/StressMonitor/Services/Preferences/PreferencesService.swift` - seed-once / optimistic / revert service with shared `updateField` skeleton
- `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift` - CR-02 chronological reversal (6 insertions)
- `StressMonitor/StressMonitorTests/StressContextPayloadTests.swift` - 4 new trend regression cases + measurement helper
- `StressMonitor/StressMonitorTests/StressAPIClientPreferencesTests.swift` - Registered at pbxproj IDs A020/B020
- `StressMonitor/StressMonitorTests/PreferencesServiceTests.swift` - Registered at pbxproj IDs A021/B021
- `StressMonitor/StressMonitor/StressMonitorApp.swift` - app-scope `@State preferencesService` + `.environment(preferencesService)` beside creditService
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` - AI Coach section (picker row builder + error footnote), `@Environment(PreferencesService.self)`, seedIfNeeded in onAppear, preview environment injection
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` - both suites registered (4-line pattern each); `plutil -lint` OK

## Decisions Made
- **Response row not re-mapped on update success:** the optimistic value already equals what the server persisted (it echoes the PUT field), so `updateField` keeps it and only clears `errorMessage`; mapping the decoded row back would add a failure mode (decode error → phantom revert) with no state benefit.
- **Seed stays silent on failure:** seeding is background hydration feeding pickers and the chat payload; a transient 500 must never block or alarm the user. `hasSeeded` remains false so the next surface retries — pinned by the retry test.
- **Picker interaction detail:** the menu `Picker`'s binding `get` returns service state, so the visual selection follows the service (settles on the new value after the PUT resolves; snaps back on revert). This guarantees the UI never diverges from the reverted state, at the cost of a brief menu lag during the await.
- **Tuple options + `ForEach(options, id: \.raw)`** in `aiCoachPickerRow` keeps the closed vocabularies inline and greppable (acceptance-criterion friendly) without a new type.

## Verification Results
- `StressContextPayloadTests` — 7/7, exit 0 (4 new trend cases + 3 privacy invariants)
- `StressAPIClientPreferencesTests` + `PreferencesServiceTests` — 11 tests, 2 suites, exit 0; re-run green again after Task 3 wiring
- `xcodebuild build` (iPhone 17 simulator) — BUILD SUCCEEDED
- Regression fence run (ChatLifecycleTests, SSEParserTests, PaywallOutOfCreditsGuardTests, CreditPurchaseFlowTests + both new suites) — `Test run with 31 tests in 6 suites passed` + StressContextPayloadTests 7/7, TEST SUCCEEDED
- `git diff c9df7b5..HEAD` over LLMServiceProtocol.swift / SSEParser.swift / StressLLMService.swift / ChatViewModel.swift / Premium views / Chat views — **empty** (fence untouched)

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance
- Task 1: RED `4cb99fa` → GREEN `56bdedc`. REFACTOR omitted — the fix is a two-line computation change; nothing to clean.
- Task 2: RED `3f9a4c9` (compile failure on missing types = failing state) → GREEN `8044cda`. REFACTOR born-in (`updateField` skeleton written once in GREEN, not extracted afterward).
- Task 3 (type=auto): build + both suites re-run green; acceptance greps verified (`updatePreferences` count 1, 'AI Coach' count 4, env injection 1 via fixed-string grep, no TextField, seedIfNeeded 1).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 03-03 consumes `PreferencesService` at the `StressContextPayload.build` call site (drop the `"en"`/`"supportive"` default args in ChatViewModel's payload construction) and the quick-actions fetch can reuse the closed vocabularies for query params.
- `derived-PREF-02` remains intentionally half-complete until 03-03 lands that call-site read — do not mark it closed before then.
- Settings visual confirmation (pickers render, revert footnote) rides the 03-05 UAT script as the plan scheduled.

---
*Phase: 03-sessions-preferences-quick-actions-cleanup*
*Completed: 2026-08-23*

## Self-Check: PASSED

- All 5 created files exist on disk
- All 5 task commits (4cb99fa, 56bdedc, 3f9a4c9, 8044cda, 9410ad5) present in git log
- Acceptance-criteria greps re-verified: recent.reversed()=1, func updatePreferences=1, AI Coach=4, environment(preferencesService)=1 (fixed-string), seedIfNeeded=1, TextField=0, option vocabularies exact

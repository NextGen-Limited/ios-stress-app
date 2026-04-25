# Code Review: Dashboard Content-Only Rendering

**Date:** 2026-04-25
**Reviewer:** code-reviewer
**Scope:** DashboardView.swift, StressViewModel.swift
**Files:** 2 | LOC reviewed: ~550

---

## Overall Assessment

Clean, focused refactor. The 4-branch `switch renderState` is correctly collapsed into a single `dashboardContent(viewModel.currentStress?)` call. Nil handling is delegated to child components (StressCharacterCard, TripleMetricRow) as designed. Dead code fully removed with no stale references. Permission flow preserved. One medium-severity SwiftUI anti-pattern and one informational finding.

---

## Critical Issues

None.

---

## High Priority

None.

---

## Medium Priority

### M1. `.constant()` alert binding is a SwiftUI anti-pattern

**File:** `DashboardView.swift:44`

```swift
.alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
    Button("OK") { viewModel.clearError() }
}
```

`.constant()` creates a one-way binding. SwiftUI internally reads `isPresented` to decide whether to show the alert, but since the binding is constant, the framework cannot write back to dismiss it. This *appears* to work because SwiftUI has historically tolerated this pattern in practice (the alert dismisses by button action, and the recomputation on `clearError()` triggers re-evaluation). However:

- It relies on undocumented SwiftUI internals
- Apple's documentation says `isPresented` must be a mutable binding
- Future SwiftUI versions could break this silently
- Xcode 16+ may emit runtime warnings

**Fix:** Use a dedicated `@State` or compute from the view model properly:

```swift
.alert("Error", isPresented: Binding(
    get: { viewModel.errorMessage != nil },
    set: { if !$0 { viewModel.clearError() } }
)) {
    Button("OK") { viewModel.clearError() }
}
```

Or simpler — add a `Bool` computed property to the view model:
```swift
var hasError: Bool { errorMessage != nil }
```
And bind with `Binding(get:set:)` in the view.

**Impact:** No user-facing breakage today, but a latent correctness issue.

---

## Low Priority

### L1. Hardcoded respiratory rate "14" when stress is nil

**File:** `DashboardView.swift:101`

```swift
rrValue: stress != nil ? "14" : "--"
```

When `stress` is non-nil, RR is always "14" (a hardcoded constant), not derived from any real data source. This was likely pre-existing behavior, not introduced by this refactor, but worth noting — the metric is misleading when `stress` is present. When `stress` is nil, the "--" placeholder is correct per plan decision.

**Impact:** Cosmetic only — no data source for RR currently exists.

### L2. `DashboardViewModel` in `Views/Dashboard/` appears to be a dead duplicate

**File:** `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift`

This is a separate ViewModel class with overlapping concerns (currentStress, baseline, aiInsight, repository, healthKit). It is **not** used by `DashboardView.swift` (which uses `StressViewModel`). Grep shows no imports of it from any view file. It may be pre-existing dead code from a prior iteration.

**Impact:** Codebase clutter. Not introduced by this PR, but surfaced during review.

---

## Edge Cases Found by Scout

| # | Edge Case | Status | Notes |
|---|-----------|--------|-------|
| 1 | `DashboardRenderState` references left behind | **Clear** | Zero grep hits across codebase |
| 2 | `docsURL` removal in DashboardView | **Clear** | `SettingsView.swift` has its own independent `docsURL` — not affected |
| 3 | Permission flow preserved | **Verified** | `isPermissionRequired` drives `onChange(scenePhase)` retry. `isRequestingAccess` guard retained in ViewModel. `onGrantAccess` callback flows through StressCharacterCard to `PermissionCardView` |
| 4 | `MainTabView` callers unaffected | **Clear** | All 3 instantiation paths (demo, debug, release) pass `repository:` or `viewModel:` — neither uses removed symbols |
| 5 | `mood` computed with `level ?? 0` when nil | **Acceptable** | StressCharacterCard never reaches character view when `result == nil` (guarded at line 47) |
| 6 | `StressBuddyMood.from(stressLevel: 0)` called in nil path | **Harmless** | `mood` is computed but never rendered because the `if result != nil` branch is skipped. Could be cleaned up but no bug |

---

## Positive Observations

- Red team review findings all addressed correctly in implementation
- Clean nil delegation pattern — DashboardView passes nil, children handle it
- `isRequestingAccess` re-entry guard correctly preserved (red team finding #6)
- No stale imports or orphaned symbols
- `onChange(scenePhase)` correctly retained for permission retry on foreground
- `dashboardContent` parameter change from `StressResult` to `StressResult?` is minimal and surgical
- `TripleMetricRow` placeholder values match plan decision (show "--", don't hide)

---

## Recommended Actions

1. **(Medium)** Fix `.constant()` alert binding — use `Binding(get:set:)` pattern
2. **(Low)** Note hardcoded RR "14" as a future improvement item (not blocking)
3. **(Low)** Consider deleting `DashboardViewModel.swift` if confirmed dead code (separate cleanup)

---

## Metrics

- Build status: Assumed passing (no compile errors visible)
- Dead code removed: ~4 state views, 1 enum, 1 computed property, 2 methods, 1 sheet modifier, 1 @State var
- Regression risk: Low — nil delegation is straightforward, child components already handle nil
- Test coverage: Not verified (no test changes in scope)

---

## Unresolved Questions

1. Is `DashboardViewModel.swift` (in `Views/Dashboard/`) intentionally kept, or is it dead code from a prior refactor?
2. Was the build actually verified passing after these changes (Xcode build command output not provided)?

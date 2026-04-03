# Code Review: Scroll-Hide Tab Bar

**Date**: 2026-03-21
**Reviewer**: code-reviewer
**Scope**: Tab bar hide/show on scroll implementation

---

## Scope

- **Files**: 5 files reviewed
- **LOC**: ~450 lines total
- **Focus**: Scroll tracking, animation, edge cases
- **Plan deviation**: Implementation differs from plan (PreferenceKey vs onScrollGeometryChange)

### Files Reviewed

| File | Lines | Purpose |
|------|-------|---------|
| `TabBarScrollState.swift` | 69 | Core state + PreferenceKey + view extension |
| `MainTabView.swift` | 105 | Tab bar animation with spring |
| `TrendsView.swift` | 189 | Scroll tracking integration |
| `ActionView.swift` | 443 | Scroll tracking integration |
| `HomeDashboardView.swift` | 231 | Scroll tracking integration |

---

## Overall Assessment

**Functional but plan deviation detected.** Implementation works correctly for scroll-hide behavior but uses `PreferenceKey` + `GeometryReader` + `coordinateSpace` pattern instead of the simpler iOS 17 `onScrollGeometryChange` approach specified in the plan. The current implementation is valid but adds unnecessary complexity.

---

## Critical Issues

### None - Code is functional

---

## High Priority

### 1. Plan Deviation: Wrong API Used

**Location**: All 3 scroll views + `TabBarScrollState.swift`

**Problem**: Plan specified `onScrollGeometryChange` (iOS 17+ native API), but implementation uses `PreferenceKey` + `GeometryReader` + `coordinateSpace`.

**Plan stated**:
> No `Color.clear` anchors. No `.coordinateSpace`. No GeometryReader.

**Actual implementation**:
```swift
// TabBarScrollState.swift - Lines 54-68
extension View {
    func trackScrollOffsetForTabBar(state: TabBarScrollState) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear.preference(...)
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { ... }
    }
}
```

```swift
// All 3 views use coordinateSpace
.coordinateSpace(.named("scrollView"))
```

**Impact**: Extra boilerplate, potential performance overhead from preference propagation, deviates from validated design decision.

**Recommendation**: Consider refactoring to `onScrollGeometryChange` per original plan, or document why PreferenceKey was chosen.

---

### 2. Shared CoordinateSpace Name Across Views

**Location**: All 3 views use `.coordinateSpace(.named("scrollView"))`

**Files affected**:
- `TrendsView.swift:82`
- `ActionView.swift:51`
- `HomeDashboardView.swift:109`

**Problem**: All views share the same coordinate space name "scrollView". This works because only one view is visible at a time, but violates the validation decision:

> **Question 1**: Use unique names per view
> **Answer:** Use unique names per view

**Impact**: Low - no runtime issue since views don't coexist. Code smell for maintainability.

**Recommendation**: If keeping PreferenceKey approach, use unique names (e.g., "trendsScroll", "actionScroll", "dashboardScroll").

---

## Medium Priority

### 3. Missing Top-Edge Reset Logic

**Location**: `TabBarScrollState.swift:23-44`

**Problem**: Plan specified `contentOffsetY <= 5` check to force tab bar visible at top. Current implementation only checks scroll direction:

```swift
func handleScrollOffset(_ newOffset: CGFloat) {
    let delta = newOffset - lastScrollOffset

    if abs(delta) < threshold {
        lastScrollOffset = newOffset
        return
    }

    if delta > 0 {
        // Scrolling down - hide tab bar
        if isVisible && newOffset > 0 {  // Has newOffset > 0 check
            isVisible = false
        }
    } else {
        // Scrolling up - show tab bar
        if !isVisible {
            isVisible = true
        }
    }
    ...
}
```

**Analysis**: The `newOffset > 0` check partially addresses this (hides only when scrolled past top), but doesn't force-show on bounce at top.

**Edge case**: If user scrolls down past threshold, then scrolls back to very top (offset near 0), tab bar may remain hidden.

**Recommendation**: Add explicit top-edge reset:
```swift
if newOffset <= 5 {
    isVisible = true
}
```

---

### 4. Height Capture Race Condition

**Location**: `MainTabView.swift:88-94`

```swift
.background(
    GeometryReader { proxy in
        Color.clear.onAppear {
            tabBarScrollState.tabBarHeight = proxy.size.height
        }
    }
)
```

**Problem**: `onAppear` fires asynchronously. If user scrolls immediately after app launch, `tabBarHeight` may still be default 83pt.

**Mitigation**: Default value of 83pt is reasonable fallback (validated in plan).

**Impact**: Minor - animation offset may be slightly off for first few seconds.

---

### 5. Threshold Logic Inconsistency

**Location**: `TabBarScrollState.swift:26-29`

```swift
if abs(delta) < threshold {
    lastScrollOffset = newOffset  // Updates offset even when skipped
    return
}
```

**Problem**: Updates `lastScrollOffset` on small scrolls but doesn't process them. This is correct behavior to prevent jitter, but the pattern differs from what the plan suggested (not updating on skip).

**Analysis**: Current approach is actually better - tracks all movement but only triggers show/hide on meaningful deltas.

---

## Low Priority

### 6. TabBarScrollState Not Thread-Safe

**Location**: `TabBarScrollState.swift:15-50`

**Problem**: `@Observable` class with mutable state accessed from SwiftUI view updates. No explicit `@MainActor` isolation.

**Analysis**: SwiftUI view updates run on main thread, so this is implicitly safe. However, explicit `@MainActor` would make intent clear.

**Recommendation**: Consider adding `@MainActor` to `TabBarScrollState` class for explicit thread safety documentation.

---

### 7. Negative Offset Conversion

**Location**: `TabBarScrollState.swift:66`

```swift
state.handleScrollOffset(-value)
```

**Problem**: GeometryReader frame origin is negative when scrolling down, requiring negation. This is correct but could be documented.

---

### 8. Animation Hardcoded Values

**Location**: `MainTabView.swift:96`

```swift
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarScrollState.isVisible)
```

**Status**: Good - follows plan specification exactly.

---

## Edge Cases Analysis

| Scenario | Current Behavior | Expected | Status |
|----------|------------------|----------|--------|
| Scroll down | Hide tab bar | Hide | PASS |
| Scroll up | Show tab bar | Show | PASS |
| Tab switch | Reset to visible via `resetToVisible()` | Reset | PASS |
| At top (offset <= 0) | Tab bar visible (via `newOffset > 0` check) | Visible | PASS |
| Bounce scroll at top | May stay hidden if bounced down then up quickly | Should show | PARTIAL |
| Very fast fling | Threshold prevents jitter | Smooth | PASS |
| Content shorter than screen | No scroll event, stays visible | Visible | PASS |
| Rapid tab switching | Each switch resets state | Correct | PASS |

---

## Positive Observations

1. **Clean separation**: `TabBarScrollState` is well-isolated as an `@Observable` class
2. **Environment injection**: Proper use of `@Environment` for dependency injection
3. **View extension**: Nice abstraction via `trackScrollOffsetForTabBar(state:)` modifier
4. **Spring animation**: Smooth, natural animation with well-tuned parameters
5. **Tab switch reset**: Correctly resets visibility on tab change
6. **Default height fallback**: Prevents first-frame layout issues
7. **Threshold filtering**: Prevents micro-scroll jitter effectively

---

## Recommended Actions

### Priority 1 (Should Do)
1. **Refactor to `onScrollGeometryChange`** - Simpler API, no PreferenceKey boilerplate, matches plan
2. **Add top-edge reset** - Force `isVisible = true` when `offset <= 5`

### Priority 2 (Nice to Have)
3. **Add `@MainActor`** to `TabBarScrollState` for explicit thread safety
4. **Unique coordinateSpace names** if keeping PreferenceKey approach
5. **Document offset negation** in view extension

---

## Metrics

| Metric | Value |
|--------|-------|
| Type Coverage | 100% (SwiftUI types) |
| Test Coverage | Unknown (no test files reviewed) |
| Linting Issues | None visible |
| Compilation | Expected to compile |
| Plan Compliance | ~60% (wrong API used) |

---

## Unresolved Questions

1. **Why was `onScrollGeometryChange` not used?** - Plan explicitly chose this API. Was there a technical limitation discovered during implementation?

2. **Is `onScrollGeometryChange` available in minimum iOS version?** - Check if project targets iOS 17+ (required for this API)

3. **Should `TabBarScrollState` be `Sendable`?** - For strict concurrency checking in Swift 6 mode

---

## Conclusion

The scroll-hide tab bar implementation is **functional and well-structured** but deviates from the validated plan by using PreferenceKey instead of `onScrollGeometryChange`. The current approach works correctly for the core use case with minor edge case handling gaps.

**Recommendation**: If iOS 17+ is the minimum target, refactor to `onScrollGeometryChange` for cleaner code and plan compliance. If iOS 16 support is required, the current implementation is acceptable with minor improvements (top-edge reset, `@MainActor`).

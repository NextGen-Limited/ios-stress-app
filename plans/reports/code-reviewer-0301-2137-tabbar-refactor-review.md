# Code Review: TabBar Refactor (Selected/Unselected Images)

**Date**: 2026-03-01
**Reviewer**: code-reviewer
**Commit**: a8d53ca - refactor(tabbar): use separate images for selected/unselected states
**Previous**: e4fe74a - refactor(ui): simplify TabBar with template rendering

---

## Scope

- **Files Changed**:
  - `StressMonitor/Views/Components/TabBar/StressTabBarView.swift`
  - `StressMonitor/Views/Components/TabBar/TabItem.swift`
- **LOC**: ~120 lines modified
- **Focus**: Recent refactor from template rendering to separate selected/unselected images
- **Build Status**: FAILED (compile errors)

---

## Critical Issues

### 1. TabItem.swift - Missing `iconName` Definition (BLOCKER)

**Location**: Line 15
**Error**: `cannot find 'iconName' in scope`

```swift
// BROKEN - iconName doesn't exist
var icon: String { iconName }
```

The commit removed `iconName` computed property but still references it in `icon`.

**Fix**: Either remove the deprecated `icon` property or define `iconName`:

```swift
// Option A: Remove deprecated property entirely
// (delete lines 12-15)

// Option B: If Tabbable protocol still needs icon, map to unselected
var icon: String { unselectedIconName }
```

---

### 2. TabItem.swift - Properties Outside Enum Scope (BLOCKER)

**Location**: Lines 14-93
**Error**: `cannot find 'self' in scope`

All computed properties (`title`, `selectedIconName`, `unselectedIconName`, `accessibilityLabel`, etc.) are defined **outside** the enum's scope braces. The closing brace `}` on line 10 ends the enum definition prematurely.

**Root Cause**: The enum's closing brace appears after line 10, but properties need to be inside the enum.

**Current (broken)**:
```swift
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2
}  // <-- Enum ends here

// MARK: - Tabbable Protocol
var icon: String { iconName }  // Outside enum - no self
```

**Required Fix**:
```swift
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    var id: Int { rawValue }  // Also missing!

    // MARK: - Tabbable Protocol
    var icon: String { unselectedIconName }
    var title: String { ... }
    var selectedIconName: String { ... }
    // ... all other properties inside enum
}
```

---

### 3. TabItem.swift - Missing `id` Property (BLOCKER)

**Error**: `type 'TabItem' does not conform to protocol 'Identifiable'`

The `Identifiable` protocol requires an `id` property. It was removed during the refactor.

**Fix**:
```swift
var id: Int { rawValue }
```

---

## High Priority

### 4. StressTabBarView.swift - Unused Namespace Variable

**Location**: Line 26

```swift
@Namespace private var animation  // Declared but never used
```

The sliding indicator was removed, so `@Namespace` is no longer needed.

**Fix**: Remove the unused variable.

---

### 5. TabItem.swift - Deprecated Property Still Referenced

**Location**: Line 15

The comment says "deprecated" but the property is still required by `Tabbable` protocol. Either:
- Remove from protocol (breaking change)
- Keep and properly implement

**Current code structure suggests confusion about backward compatibility.**

---

## Medium Priority

### 6. Inconsistent Title Capitalization

**Location**: TabItem.swift title property

```swift
case .trend: return "Trend"  // Was "Trends" in previous commit
```

Minor inconsistency - verify intended behavior.

---

### 7. Removed TabIndicator Asset Not Cleaned

The `TabIndicator.imageset` was deleted but there's no verification that:
- No other code references it
- Asset catalog is properly updated

---

## Low Priority

### 8. Comment Accuracy

**Location**: TabItem.swift line 5

```swift
/// Conforms to Tabbable protocol for StressTabBarView compatibility
```

The protocol conformance is broken, so this comment is inaccurate.

---

## Positive Observations

1. **Asset naming convention**: Clean lowercase-with-hyphens pattern (`home-selected`, `action-selected`)
2. **Accessibility preserved**: All accessibility labels/hints/identifiers intact
3. **Haptic feedback**: Properly maintained with `HapticManager.shared.buttonPress()`
4. **Touch targets**: 46x46pt exceeds 44x44pt minimum (WCAG compliant)
5. **Preview coverage**: Both light and dark mode previews included

---

## Edge Cases Found

1. **Build failure**: Code does not compile - blocker for all testing
2. **Protocol conformance**: `Tabbable.icon` required but implementation broken
3. **Asset existence**: Verified assets exist in correct locations

---

## Recommended Actions

1. **[CRITICAL]** Fix TabItem.swift structure - move all properties inside enum braces
2. **[CRITICAL]** Add missing `var id: Int { rawValue }` for Identifiable
3. **[CRITICAL]** Fix `icon` property to use `unselectedIconName` instead of undefined `iconName`
4. **[HIGH]** Remove unused `@Namespace` from StressTabBarView
5. **[MEDIUM]** Verify "Trend" vs "Trends" title is intentional
6. **[LOW]** Update comments to reflect actual state

---

## Metrics

- **Type Coverage**: N/A (build fails)
- **Test Coverage**: N/A (build fails)
- **Linting Issues**: 10 compile errors
- **Build Status**: FAILED

---

## Unresolved Questions

1. Should `Tabbable.icon` be deprecated entirely, or should we maintain backward compatibility?
2. Is the title change from "Trends" to "Trend" intentional?

---

## Fix Suggestion

```swift
// TabItem.swift - Complete fixed version
import SwiftUI
import SwiftData

enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Tabbable Protocol
    var icon: String { unselectedIconName }
    var title: String {
        switch self {
        case .home:   return "Home"
        case .action: return "Action"
        case .trend:  return "Trend"
        }
    }

    // MARK: - Icon Names
    var selectedIconName: String {
        switch self {
        case .home:   return "home-selected"
        case .action: return "action-selected"
        case .trend:  return "trend-selected"
        }
    }

    var unselectedIconName: String {
        switch self {
        case .home:   return "home"
        case .action: return "action"
        case .trend:  return "trend"
        }
    }

    // MARK: - Accessibility
    var accessibilityLabel: String {
        switch self {
        case .home:   return "Home tab, current stress level"
        case .action: return "Action tab, quick actions and exercises"
        case .trend:  return "Trend tab, trends and insights"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:   return "Double tap to view current stress measurement"
        case .action: return "Double tap to access quick actions and exercises"
        case .trend:  return "Double tap to view stress trends and history"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:   return "HomeTab"
        case .action: return "ActionTab"
        case .trend:  return "TrendTab"
        }
    }

    // MARK: - View Builder
    @ViewBuilder
    func destinationView(modelContext: ModelContext, useMockData: Bool) -> some View {
        switch self {
        case .home:
            if useMockData {
                DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
            } else {
                DashboardView(repository: StressRepository(modelContext: modelContext))
            }
        case .action:
            ActionView()
        case .trend:
            TrendsView()
        }
    }
}
```

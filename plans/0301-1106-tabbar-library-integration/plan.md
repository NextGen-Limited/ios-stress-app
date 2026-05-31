---
title: "TabBar Library Integration Plan"
description: "Integrate phuongddx/TabBar SwiftUI library to replace custom TabBar implementation"
status: pending
priority: P2
effort: 3h
branch: main
tags: [tabbar, swiftui, library, refactor]
created: 2026-03-01
---

## Overview

Replace the existing custom TabBar implementation with the [phuongddx/TabBar](https://github.com/phuongddx/TabBar) SwiftUI library for a more maintainable and flexible tab bar component.

## Goals

1. Add TabBar library as Swift Package dependency
2. Create custom styles matching Figma design (440x100px, white bg, shadow)
3. Update `TabItem` to conform to `Tabbable` protocol
4. Update `MainTabView` to use library's `TabBar` component
5. Preserve all existing accessibility features

## Library Info

- **Repository**: https://github.com/phuongddx/TabBar.git
- **License**: MIT
- **Requirements**: iOS 13.0+
- **Key Protocols**: `Tabbable`, `TabBarStyle`, `TabItemStyle`
- **Key Types**: `TabBar`, `TabBarVisibility`

## Current State

| Component | File | Purpose |
|-----------|------|---------|
| TabItem | `Views/Components/TabBar/TabItem.swift` | Enum defining 3 tabs (home, action, trend) |
| CustomTabBar | `Views/Components/TabBar/CustomTabBar.swift` | Container view with HStack |
| CustomTabBarItem | `Views/Components/TabBar/CustomTabBarItem.swift` | Individual tab button |
| CustomTabBarIndicator | `Views/Components/TabBar/CustomTabBarIndicator.swift` | Selection indicator ellipse |
| MainTabView | `Views/MainTabView.swift` | Root view using CustomTabBar |

## Figma Design Specs

- **Container**: 440px wide x 100px tall
- **Background**: White with shadow
- **Shadow**: 0px 4.683px 14.048px rgba(0,0,0,0.11)
- **Tab Spacing**: 80px gap between items
- **Icon Opacity**: 30% unselected, 100% selected
- **Icons**: TabHome, TabAction, TabTrend (SVG in Asset Catalog)

## Files to Modify

### Modify
- `StressMonitor/StressMonitor/Views/Components/TabBar/TabItem.swift`
- `StressMonitor/StressMonitor/Views/MainTabView.swift`

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarStyle.swift`
- `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabItemStyle.swift`

### Delete (after integration complete)
- `StressMonitor/StressMonitor/Views/Components/TabBar/CustomTabBar.swift`
- `StressMonitor/StressMonitor/Views/Components/TabBar/CustomTabBarItem.swift`
- `StressMonitor/StressMonitor/Views/Components/TabBar/CustomTabBarIndicator.swift`

---

## Phase 1: Add Swift Package Dependency (15 min)

**Status: Pending**

### Steps

1. In Xcode: File > Add Package Dependencies...
2. Enter URL: `https://github.com/phuongddx/TabBar.git`
3. Select version rule: Up to Next Major (or specific commit)
4. Add to StressMonitor target

### Validation
- [ ] Package resolves without errors
- [ ] Project builds successfully
- [ ] `import TabBar` compiles in test file

---

## Phase 2: Create Custom Styles (45 min)

**Status: Pending**

### 2.1 StressTabBarStyle.swift

Create `StressTabBarStyle` conforming to `TabBarStyle` protocol:

```swift
import SwiftUI
import TabBar

/// Custom tab bar style matching Figma design
struct StressTabBarStyle: TabBarStyle {
    // Figma specs
    private let tabBarHeight: CGFloat = 100
    private let tabSpacing: CGFloat = 80
    private let topPadding: CGFloat = 16
    private let bottomSafeArea: CGFloat = 34

    func body(content: Content) -> some View {
        content
            .padding(.top, topPadding)
            .padding(.bottom, bottomSafeArea)
            .frame(height: tabBarHeight)
            .frame(maxWidth: .infinity)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.11), radius: 14, y: -5)
            )
    }
}
```

### 2.2 StressTabItemStyle.swift

Create `StressTabItemStyle` conforming to `TabItemStyle` protocol:

```swift
import SwiftUI
import TabBar

/// Custom tab item style matching Figma design
struct StressTabItemStyle: TabItemStyle {
    // Figma specs: 46x46px touch target, 40x40px icon
    private let touchTargetSize: CGFloat = 46
    private let iconSize: CGFloat = 40

    func body(item: TabItemData, isSelected: Bool) -> some View {
        VStack(spacing: 0) {
            Image(item.icon)
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .opacity(isSelected ? 1.0 : 0.3)

            if isSelected {
                Image("TabIndicator")
                    .resizable()
                    .frame(width: 20, height: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: touchTargetSize, height: touchTargetSize)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

### Validation
- [ ] Both style files compile
- [ ] No SwiftUI preview errors

---

## Phase 3: Update TabItem (30 min)

**Status: Pending**

Modify `TabItem.swift` to conform to `Tabbable` protocol:

### Current Code
```swift
enum TabItem: Int, CaseIterable, Identifiable { ... }
```

### New Code
```swift
import TabBar

enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    var id: Int { rawValue }

    // MARK: - Tabbable Protocol
    var icon: String { iconName }
    var title: String { accessibilityLabel }

    // MARK: - Existing Properties
    var iconName: String {
        switch self {
        case .home:   return "TabHome"
        case .action: return "TabAction"
        case .trend:  return "TabTrend"
        }
    }

    var accessibilityLabel: String { ... }
    var accessibilityHint: String { ... }
    var accessibilityIdentifier: String { ... }

    @ViewBuilder
    func destinationView(modelContext: ModelContext, useMockData: Bool) -> some View { ... }
}
```

### Key Changes
1. Add `import TabBar`
2. Add `Tabbable` to protocol conformance
3. Add computed `icon` property (alias to `iconName`)
4. Add computed `title` property (alias to `accessibilityLabel`)
5. Keep existing properties for backward compatibility

### Validation
- [ ] TabItem compiles with Tabbable conformance
- [ ] All existing code using TabItem still works

---

## Phase 4: Update MainTabView (45 min)

**Status: Pending**

### Current Code
```swift
struct MainTabView: View {
    @State private var selectedTab: TabItem = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: ...
                case .action: ...
                case .trend: ...
                }
            }
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}
```

### New Code
```swift
import SwiftUI
import SwiftData
import TabBar

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home
    @State private var tabBarVisibility: TabBarVisibility = .visible

    static var useMockData: Bool { ... }

    var body: some View {
        TabBar(selection: $selectedTab, visibility: $tabBarVisibility) {
            // Home tab
            if Self.useMockData {
                DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
            } else {
                DashboardView(repository: StressRepository(modelContext: modelContext))
            }
            .tabItem(for: TabItem.home)

            // Action tab
            ActionView()
                .tabItem(for: TabItem.action)

            // Trend tab
            TrendsView()
                .tabItem(for: TabItem.trend)
        }
        .tabBar(style: StressTabBarStyle())
        .tabItem(style: StressTabItemStyle())
        .ignoresSafeArea(.keyboard)
        .tint(.accentColor)
    }
}
```

### Key Changes
1. Add `import TabBar`
2. Replace ZStack with `TabBar` component
3. Add `tabBarVisibility` state
4. Use `.tabItem(for:)` modifier for each view
5. Apply custom styles via `.tabBar(style:)` and `.tabItem(style:)`

### Validation
- [ ] MainTabView compiles
- [ ] All 3 tabs navigate correctly
- [ ] Tab selection animation works
- [ ] Dark mode works

---

## Phase 5: Cleanup (15 min)

**Status: Pending**

After successful integration, remove obsolete files:

### Files to Delete
1. `CustomTabBar.swift` - replaced by `StressTabBarStyle`
2. `CustomTabBarItem.swift` - replaced by `StressTabItemStyle`
3. `CustomTabBarIndicator.swift` - integrated into `StressTabItemStyle`

### Steps
1. Verify all tests pass
2. Remove imports of deleted files (if any)
3. Delete the 3 obsolete files
4. Run full build

### Validation
- [ ] No build errors after deletion
- [ ] No orphaned references in codebase

---

## Phase 6: Testing & Accessibility (30 min)

**Status: Pending**

### Manual Testing Checklist
- [ ] Tab selection works (tap each tab)
- [ ] Tab bar renders at correct size (100px height)
- [ ] Shadow displays correctly (0.11 opacity)
- [ ] Icon opacity: 30% unselected, 100% selected
- [ ] Selection indicator appears on active tab
- [ ] Dark mode: background adapts correctly
- [ ] Safe area handling (iPhone vs iPad)

### Accessibility Testing
- [ ] VoiceOver reads tab labels
- [ ] VoiceOver hints work
- [ ] Accessibility identifiers work for UI testing
- [ ] Selected state announced by VoiceOver
- [ ] Haptic feedback on tab selection

### Edge Cases
- [ ] App launch with different initial tabs
- [ ] Tab visibility changes (if needed)
- [ ] Rotation (if supported)

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Library API differences | Medium | Review library source before implementation |
| Accessibility regression | High | Test VoiceOver thoroughly |
| Dark mode issues | Low | Use `.systemBackground` |
| Build errors after deletion | Medium | Verify all references removed |

---

## Success Criteria

1. [ ] TabBar library added as SPM dependency
2. [ ] Custom styles match Figma design exactly
3. [ ] TabItem conforms to Tabbable protocol
4. [ ] MainTabView uses TabBar component
5. [ ] All accessibility features preserved
6. [ ] No build errors or warnings
7. [ ] Dark mode works correctly
8. [ ] Obsolete files removed

---

## Unresolved Questions

1. **HapticManager integration**: Does the library support custom tap handlers? May need to wrap tab items.
2. **TabBarVisibility**: Do we need visibility toggling? Currently always visible.
3. **Animation customization**: Can we match existing animation timing (0.2s easeInOut)?

---

## References

- [TabBar Library README](https://github.com/phuongddx/TabBar)
- [Original TabBar Library (onl1ner)](https://github.com/onl1ner/TabBar)
- Figma Node: `14:15140` (Menu Component)
- Previous Implementation: `plans/0228-2129-figma-tabbar-replacement/`

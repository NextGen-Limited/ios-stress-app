---
title: "Custom TabBar Implementation"
description: "Replace standard SwiftUI TabView with custom Figma-matched TabBar component"
status: completed
priority: P2
effort: 6h
branch: main
tags: [ui, tabbar, figma, component]
created: 2026-02-28
completed: 2026-02-28
---

## Overview

Replace standard SwiftUI `TabView` with custom `CustomTabBar` component matching Figma design (Node 4:625). Implementation includes SVG asset integration, custom styling, haptic feedback, and full accessibility support.

**Key Changes:**
- Tab count: 4 → 3 (Home, Flash, Growth)
- Standard TabView → Custom ZStack-based component
- SF Symbols → Custom SVG icons from Figma
- Default styling → Figma design (white bg, opacity states, ellipse indicator)

---

## Architecture Decisions

### 1. Component Structure

```
Views/Components/TabBar/
├── CustomTabBar.swift           # Main container + selection state
├── CustomTabBarItem.swift       # Individual tab button
├── CustomTabBarIndicator.swift  # Active indicator ellipse
└── TabItem.swift                # Tab model enum
```

**Rationale:** Separation of concerns allows each piece to be testable and reusable. Follows existing pattern in `Views/DesignSystem/Components/`.

### 2. Selection State Management

Use `@Binding<SelectedTab>` for parent-child communication:

```swift
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    // ...
}

// In MainTabView
@State private var selectedTab: TabItem = .home
```

**Rationale:** Standard SwiftUI pattern, allows parent to control navigation.

### 3. Asset Integration

Follow existing `StressBuddyIllustration` pattern - use SVG assets in Asset Catalog:

```swift
// Assets.xcassets/TabBar/
├── TabHome.imageset/
│   └── TabHome.svg
├── TabFlash.imageset/
│   └── TabFlash.svg
├── TabGrowth.imageset/
│   └── TabGrowth.svg
└── TabIndicator.imageset/
    └── TabIndicator.svg
```

### 4. Layout Approach

Use `GeometryReader` + `ZStack` for pixel-perfect Figma matching:

```swift
ZStack(alignment: .bottom) {
    // Content area (switch based on selectedTab)
    contentFor(selectedTab)

    // Tab bar fixed at bottom
    CustomTabBar(selectedTab: $selectedTab)
}
.ignoresSafeArea(.keyboard)
```

---

## Phase Breakdown

### Phase 1: Asset Preparation (30 min)

**Files:**
- `StressMonitor/Assets.xcassets/TabBar/` (new directory)

**Tasks:**
1. [ ] Download SVG assets from Figma (localhost:3845):
   - `imgFrame1000003718` → `TabHome.svg`
   - `imgFlash1` → `TabFlash.svg`
   - `imgLayer2` → `TabGrowth.svg`
   - `imgEllipse3` → `TabIndicator.svg`

2. [ ] Create Asset Catalog structure:
```json
// TabBar/TabHome.imageset/Contents.json
{
  "images" : [{ "filename" : "TabHome.svg", "idiom" : "universal" }],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true }
}
```

3. [ ] Verify SVG rendering in Asset Catalog preview

**Success Criteria:**
- All 4 assets visible in Xcode Asset Catalog
- Vector representation preserved

---

### Phase 2: Tab Model & Enum (30 min)

**Files:**
- `StressMonitor/Views/Components/TabBar/TabItem.swift` (new)

**Implementation:**

```swift
import SwiftUI

/// Tab bar items matching Figma design
enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case flash = 1
    case growth = 2

    var id: Int { rawValue }

    /// Asset name in Asset Catalog
    var iconName: String {
        switch self {
        case .home:    return "TabHome"
        case .flash:   return "TabFlash"
        case .growth:  return "TabGrowth"
        }
    }

    /// Accessibility label (WCAG AA)
    var accessibilityLabel: String {
        switch self {
        case .home:    return "Home tab, current stress level"
        case .flash:   return "Flash tab, quick actions"
        case .growth:  return "Growth tab, trends and insights"
        }
    }

    /// Hint for VoiceOver
    var accessibilityHint: String {
        "Double tap to switch to \(accessibilityLabel.components(separatedBy: ",").first ?? "")"
    }

    /// View to display when tab is selected
    @ViewBuilder
    func destinationView(modelContext: ModelContext, useMockData: Bool) -> some View {
        switch self {
        case .home:
            if useMockData {
                DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
            } else {
                DashboardView(repository: StressRepository(modelContext: modelContext))
            }
        case .flash:
            // TODO: Implement FlashView (placeholder for now)
            Text("Flash - Coming Soon")
        case .growth:
            TrendsView()
        }
    }
}
```

**Success Criteria:**
- Enum compiles without errors
- All cases have valid asset references

---

### Phase 3: Custom TabBar Component (2h)

**Files:**
- `StressMonitor/Views/Components/TabBar/CustomTabBarItem.swift` (new)
- `StressMonitor/Views/Components/TabBar/CustomTabBarIndicator.swift` (new)
- `StressMonitor/Views/Components/TabBar/CustomTabBar.swift` (new)

#### 3.1 TabBarItem

```swift
import SwiftUI

struct CustomTabBarItem: View {
    let item: TabItem
    let isSelected: Bool
    let action: () -> Void

    // Figma specs
    private let touchTargetSize: CGFloat = 46
    private let iconSize: CGFloat = 24

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonPress()
            action()
        }) {
            VStack(spacing: 4) {
                Image(item.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .opacity(isSelected ? 1.0 : 0.3)

                // Active indicator
                if isSelected {
                    CustomTabBarIndicator()
                        .frame(width: 20, height: 8)
                }
            }
            .frame(width: touchTargetSize, height: touchTargetSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

#### 3.2 TabBarIndicator

```swift
import SwiftUI

/// Active tab indicator ellipse (20x8px per Figma)
struct CustomTabBarIndicator: View {
    var body: some View {
        // Use SVG asset or draw ellipse
        Image("TabIndicator")
            .resizable()
            .aspectRatio(contentMode: .fit)
        // Fallback: Ellipse().fill(Color.accentColor)
    }
}
```

#### 3.3 CustomTabBar

```swift
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem

    // Figma specs
    private let tabBarHeight: CGFloat = 119
    private let tabSpacing: CGFloat = 80
    private let horizontalPadding: CGFloat = 65

    var body: some View {
        HStack(spacing: tabSpacing) {
            ForEach(TabItem.allCases) { item in
                CustomTabBarItem(
                    item: item,
                    isSelected: selectedTab == item
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = item
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 35) // Safe area
        .frame(height: tabBarHeight)
        .frame(maxWidth: .infinity)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
}
```

**Success Criteria:**
- Component renders with correct spacing
- Haptic feedback on tap
- Selection state updates correctly

---

### Phase 4: MainTabView Integration (1.5h)

**Files:**
- `StressMonitor/StressMonitor/Views/MainTabView.swift` (modify)

**Updated Implementation:**

```swift
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .home

    static var useMockData: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
        #else
        return false
        #endif
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case .home:
                    if Self.useMockData {
                        DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
                    } else {
                        DashboardView(repository: StressRepository(modelContext: modelContext))
                    }
                case .flash:
                    FlashView() // New view
                case .growth:
                    TrendsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
    }
}
```

**Migration Notes:**
- Remove old `TabView` with `tabItem` modifiers
- History and Settings tabs removed (4 → 3)
- Accessibility identifiers updated for new structure

**Success Criteria:**
- Navigation works correctly
- Mock data mode functional
- No compile errors

---

### Phase 5: Accessibility & Polish (1h)

**Tasks:**
1. [ ] Add accessibility identifiers for UI testing:
```swift
CustomTabBar(selectedTab: $selectedTab)
    .accessibilityIdentifier("MainTabBar")
```

2. [ ] Implement Dynamic Type support:
```swift
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24
```

3. [ ] Add transition animations:
```swift
switch selectedTab {
case .home:
    DashboardView(...)
        .transition(.opacity)
case .flash:
    FlashView()
        .transition(.opacity.combined(with: .move(edge: .trailing)))
case .growth:
    TrendsView()
        .transition(.opacity.combined(with: .move(edge: .trailing)))
}
```

4. [ ] Test VoiceOver navigation
5. [ ] Verify 44pt minimum touch targets

**Success Criteria:**
- VoiceOver navigates logically
- Dynamic Type scales icons properly
- All touch targets >= 44pt

---

### Phase 6: Testing (30 min)

**Files:**
- `StressMonitorTests/Components/TabBar/CustomTabBarTests.swift` (new)

**Test Cases:**

```swift
final class CustomTabBarTests: XCTestCase {
    func testTabItem_InitialState() {
        let item = CustomTabBarItem(
            item: .home,
            isSelected: false,
            action: {}
        )
        // Verify opacity 0.3
    }

    func testTabItem_SelectedState() {
        let item = CustomTabBarItem(
            item: .home,
            isSelected: true,
            action: {}
        )
        // Verify opacity 1.0, indicator visible
    }

    func testSelection_HapticFeedback() {
        // Verify HapticManager.buttonPress called
    }

    func testAccessibility() {
        // Verify labels and hints present
    }
}
```

**Success Criteria:**
- All tests pass
- Code coverage > 80%

---

## File Structure

```
StressMonitor/
├── Assets.xcassets/
│   └── TabBar/
│       ├── TabHome.imageset/
│       │   ├── Contents.json
│       │   └── TabHome.svg
│       ├── TabFlash.imageset/
│       │   ├── Contents.json
│       │   └── TabFlash.svg
│       ├── TabGrowth.imageset/
│       │   ├── Contents.json
│       │   └── TabGrowth.svg
│       └── TabIndicator.imageset/
│           ├── Contents.json
│           └── TabIndicator.svg
├── Views/
│   ├── Components/
│   │   └── TabBar/
│   │       ├── CustomTabBar.swift
│   │       ├── CustomTabBarItem.swift
│   │       ├── CustomTabBarIndicator.swift
│   │       └── TabItem.swift
│   └── MainTabView.swift (modified)
└── Views/Flash/
    └── FlashView.swift (new placeholder)
```

---

## Success Criteria

| Criterion | Verification |
|-----------|--------------|
| Visual match to Figma | Side-by-side comparison |
| Tab switching works | Manual testing |
| Haptic feedback | Device testing |
| VoiceOver navigation | Accessibility Inspector |
| Touch targets >= 44pt | Layout inspector |
| No compile errors | Build succeeds |
| Tests pass | `xcode_test` |
| Dynamic Type support | Settings test |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| SVG assets don't render | High | Test assets early in Phase 1 |
| Tab count mismatch (4→3) | Medium | Document removed tabs, plan Flash view |
| Safe area handling | Medium | Use `.ignoresSafeArea(.keyboard)` |
| Animation jank | Low | Use `.animation(.easeInOut)` modifier |
| VoiceOver order | Medium | Use `accessibilitySortPriority` if needed |

---

## Design Decisions (Resolved 2026-02-28)

1. **Flash View → Action Screen:** Quick actions, breathing exercises, stress relief tools
2. **Settings Tab → Removed:** Follow Figma exactly, no settings in main nav
3. **History Tab → Merged into Growth:** Growth tab = Trends + History combined

## Remaining Questions

1. **Dark Mode:** Figma design shows white background. Dark mode support needed? If yes, what are the dark mode specs?

2. **Asset Source:** SVGs served from `localhost:3845`. Need production URL or should assets be bundled?

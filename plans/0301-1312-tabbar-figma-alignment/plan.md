# TabBar Figma Alignment Plan

## Overview

Correct `StressTabBarView.swift` to match Figma design (Node 4:5990).

**Status:** COMPLETE
**Priority:** High
**Effort:** Small (30 min)
**Completion Date:** 2026-03-01

## Implementation Summary

Successfully implemented Figma-aligned TabBar with sliding indicator and conditional icon assets.

### What Was Built
- 6 TabBar icon assets (Selected/Unselected variants) in `Assets.xcassets/TabBar/`
- `iconName(isSelected:)` method in `TabItem.swift` for conditional icon loading
- Updated `StressTabBarView.swift` with:
  - Top padding: 21px (was 16px)
  - Sliding indicator at bottom of bar using `ZStack` + `matchedGeometryEffect`
  - Unselected icons at 30% opacity
  - Smooth animation on tab switch

### Test Results
- **Build:** SUCCEEDED
- **Tests:** 477/478 passed (1 unrelated failure in HistoryView)
- **Code Review:** 8.5/10, 0 critical issues

## Figma Specs

| Property | Figma Value | Current | Fix |
|----------|-------------|---------|-----|
| Top padding | 21px | 16px | ✏️ |
| Indicator position | Bottom of bar | Above icon | ✏️ |
| Inactive opacity | 30% (or black) | Full color | ✏️ |
| Selected color | `#85C9C9` (teal) | Original | ✏️ |
| Unselected color | `#000000` (black) | Original | ✏️ |
| Tab spacing | 80px | 80px | ✅ |
| Touch target | 46px | 46px | ✅ |
| Icon size | 40px | 40px | ✅ |

## Colors

```swift
// Selected: rgba(133, 201, 201, 1) = #85C9C9
// Unselected: rgba(0, 0, 0, 1) = #000000

static let tabSelected = Color(red: 133/255, green: 201/255, blue: 201/255)
static let tabUnselected = Color.black
```

## Implementation Steps

### Phase 1: Create Icon Assets
**Status:** COMPLETE

**File:** `StressMonitor/StressMonitor/Assets.xcassets/TabBar/`

Create separate selected/unselected icon variants:

| Current Asset | New Selected Asset | New Unselected Asset |
|---------------|-------------------|----------------------|
| TabHome | TabHome-Selected (teal) | TabHome-Unselected (gray) |
| TabAction | TabAction-Selected (teal) | TabAction-Unselected (gray) |
| TabTrend | TabTrend-Selected (teal) | TabTrend-Unselected (gray) |

Export from Figma with exact colors or create variants in SVG.

### Phase 2: Update TabItem Model
**Status:** COMPLETE

**File:** `StressMonitor/StressMonitor/Views/Components/TabBar/TabItem.swift`

```swift
enum TabItem: String, CaseIterable, Identifiable {
    case home, action, trend

    var id: String { rawValue }

    // Dynamic icon name based on selection state
    func iconName(isSelected: Bool) -> String {
        isSelected ? "Tab\(rawValue.capitalized)-Selected" : "Tab\(rawValue.capitalized)-Unselected"
    }

    // Keep original for backwards compatibility
    var iconName: String { "Tab\(rawValue.capitalized)" }
}
```

### Phase 3: Update StressTabBarView.swift
**Status:** COMPLETE

**File:** `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarView.swift`

1. **Update top padding**
   ```swift
   private let topPadding: CGFloat = 21  // Was 16
   ```

2. **Add sliding indicator with matchedGeometryEffect**
   ```swift
   @Namespace private var animation

   // In body, use ZStack for indicator overlay
   ZStack(alignment: .bottom) {
       // Tab items HStack
       HStack(spacing: tabSpacing) { ... }

       // Sliding indicator at bottom
       if let selectedTab = selectedTab {
           TabBarIndicator()
               .frame(width: 20, height: 8)
               .matchedGeometryEffect(id: "indicator", in: animation)
               .offset(x: indicatorOffset)  // Calculate based on selected tab
       }
   }
   ```

3. **Update TabBarItem to use conditional icons + opacity**
   ```swift
   Image(item.iconName(isSelected: isSelected))
       .resizable()
       .renderingMode(.original)
       .aspectRatio(contentMode: .fit)
       .frame(width: iconSize, height: iconSize)
       .opacity(isSelected ? 1.0 : 0.3)  // 30% opacity for unselected
   ```

4. **Remove indicator from VStack inside TabBarItem**
   - Indicator moves to parent ZStack
   - Simplified VStack with just icon

### Phase 4: Validate & Test

**Status:** COMPLETE

- [x] Build succeeds
- [x] Visual match with Figma screenshot
- [x] Indicator slides smoothly on tab switch
- [x] Selected icons show teal colors
- [x] Unselected icons show gray at 30% opacity
- [x] Dark mode: opacity approach handles automatically

## Files to Modify

| File | Action |
|------|--------|
| `Assets.xcassets/TabBar/` | Add 6 new icon assets (Selected/Unselected variants) |
| `Views/Components/TabBar/TabItem.swift` | Add conditional iconName method |
| `Views/Components/TabBar/StressTabBarView.swift` | Update layout, sliding indicator, opacity |

## Success Criteria

1. Indicator slides smoothly between tabs (matchedGeometryEffect)
2. Indicator positioned at bottom of TabBar
3. Selected icons: teal variant at 100% opacity
4. Unselected icons: gray variant at 30% opacity
5. Top padding: 21px
6. Maintains 80px spacing, 46px touch target, 40px icons
7. Dark mode compatible via opacity approach

## Risks

- Dark mode: Black unselected may not work on dark backgrounds
  - Mitigation: Use adaptive color or keep `.original` rendering for dark mode

---

## Validation Log

### Session 1 — 2026-03-01
**Trigger:** Pre-implementation validation via `/ck:plan validate`
**Questions asked:** 3

#### Questions & Answers

1. **[Architecture]** How should the tab indicator animate when switching tabs?
   - Options: Slide smoothly between tabs | Fade out/in per tab | Scale + slide combined
   - **Answer:** Slide smoothly between tabs
   - **Rationale:** More polished UX, matches Figma motion design expectations

2. **[Tradeoff]** How should unselected tabs appear? Plan mentions both 'black' and '30% opacity' options.
   - Options: Black at 30% opacity | Solid black (#000000) | Adaptive color system
   - **Answer:** Black at 30% opacity
   - **Rationale:** Works in both light and dark mode automatically

3. **[Architecture]** How should we handle tab icon coloring? Current icons are multi-color SVGs (gray + teal).
   - Options: Separate selected/unselected assets | Convert icons to template format | Keep current icons + opacity only
   - **Answer:** Separate selected/unselected assets
   - **Rationale:** Preserves original multi-color design, matches Figma exactly

#### Confirmed Decisions
- Animation: Sliding indicator with matched geometry transition
- Unselected state: 30% opacity (no color change, adaptive)
- Icon strategy: Keep `.original` rendering, create 6 new assets (TabHome-Selected, TabHome-Unselected, etc.)

#### Action Items
- [x] Export selected/unselected icon variants from Figma
- [x] Update TabItem to provide selected/unselected icon names
- [x] Implement sliding indicator using `matchedGeometryEffect`

#### Impact on Phases
- Phase 1: Replace template rendering approach with conditional asset loading
- Phase 2: Remove color extension (not needed with separate assets)
- Add new Phase 1.5: Create icon assets in Assets.xcassets

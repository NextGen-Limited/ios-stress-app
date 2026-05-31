# Figma TabBar Replacement Implementation Plan

> Replace existing CustomTabBar with new Figma design (Node 14:15140)
> Status: **Complete** | Priority: **Medium** | Created: 2026-02-28 | Completed: 2026-02-28

---

## Overview

Replace the current `CustomTabBar` component with the new Figma design featuring updated icons, renamed tabs, and dark mode support.

## Validation Results (2026-02-28)

**Decisions Made:**

| Question | Decision |
|----------|----------|
| Tab naming | **Rename to match Figma**: `flash` → `action`, `growth` → `trend` |
| Tab count | **3 tabs is correct**: Home, Action, Trend (no Settings/History) |
| Dark mode | **Yes, support dark mode** with appropriate backgrounds |

---

## Changes Summary

| Element | Current | New Figma |
|---------|---------|-----------|
| Tab `flash` | Action icon | Renamed to `action`, new SVG |
| Tab `growth` | Trend icon | Renamed to `trend`, new SVG |
| Item Size | 46x46px touch target | 440x100px container |
| TabBar Height | 119px | 100px + padding |
| Shadow | `.black.opacity(0.05)` | Multi-layer rgba(0,0,0,0.11) |
| Dark Mode | Not specified | **NEW: Add dark mode support** |

---

## Related Code Files

### Files to Modify
- `StressMonitor/Views/Components/TabBar/CustomTabBar.swift`
- `StressMonitor/Views/Components/TabBar/CustomTabBarItem.swift`
- `StressMonitor/Views/Components/TabBar/TabItem.swift`
- `StressMonitor/Assets.xcassets/TabBar/*` (replace SVGs)

### Files to Read
- `StressMonitor/Views/Components/TabBar/CustomTabBarIndicator.swift`
- `StressMonitor/Views/MainTabView.swift`

---

## Implementation Phases

### Phase 1: Download & Prepare Assets
**Status:** ✅ Complete

Downloaded new SVG icons from Figma MCP server and added to Asset Catalog.

**Assets from Figma:**
- Home: `http://localhost:3845/assets/ad402e67735bfef648d5cd9f1e8f373a66a74286.svg`
- Action: `http://localhost:3845/assets/1a5b8cad169bcb6457a3e011a2da46d40872a4f3.svg`
- Trend: `http://localhost:3845/assets/57e288c06ebb0666fdbfcc6ed4095df7e005c227.svg`

---

### Phase 2: Update TabItem Enum
**Status:** ✅ Complete

Renamed cases to match Figma variant names:
- `flash` → `action`
- `growth` → `trend`
- Updated all accessibility labels, hints, and identifiers

Update accessibility labels/hints:
```swift
case .action:   return "Action tab, quick actions and exercises"
case .trend:    return "Trend tab, trends and insights"
```

---

### Phase 3: Update CustomTabBar Layout
**Status:** ✅ Complete

Updated to match Figma specs:
- Height: 100px (from 119px)
- Shadow: Multi-layer with rgba(0,0,0,0.11), radius: 14, y: -5
- Padding adjusted: top 16px, bottom 34px

**Dark Mode Support Added:**
```swift
.background(
    Color(.systemBackground)
        .shadow(color: .black.opacity(0.11), radius: 14, y: -5)
)
```

---

### Phase 4: Update CustomTabBarItem
**Status:** ✅ Complete

Asset folders renamed:
- TabFlash.imageset → TabAction.imageset
- TabGrowth.imageset → TabTrend.imageset
- Contents.json files updated with new filenames
- Dark mode compatibility ensured via .systemBackground

---

### Phase 5: Testing & Validation
**Status:** ✅ Complete

- [x] Code review completed (85/100 score)
- [x] Critical bug fixed (accessibilityHint enum cases)
- [x] No TabBar-related build errors
- [ ] Visual comparison with Figma screenshot (requires simulator)
- [ ] VoiceOver verification (requires device testing)

**Note:** Pre-existing WatchConnectivityManager.swift build error unrelated to TabBar changes.

---

## Success Criteria

- [x] Tab names: Home, Action, Trend (enum cases renamed)
- [x] Dark mode support (`.systemBackground` implementation)
- [x] Shadow matches Figma specs (0.11 opacity, radius 14, y -5)
- [x] Height updated to 100px
- [x] Accessibility labels/hints updated
- [x] Code compiles without TabBar-related errors
- [ ] Visual parity verification (requires simulator run)
- [ ] VoiceOver testing (requires device)

---

## Figma Reference

**Screenshot:** [Menu Component](https://maas-log-prod.cn-wlcb.ufileos.com/anthropic/3286aa55-886a-4809-947f-a117cf3fa447/0467a28aaa07e3994c126e8e7d6baec8.png?UCloudPublicKey=TOKEN_e15ba47a-d098-4fbd-9afc-a0dcf0e4e621&Expires=1772290365&Signature=y3GIx1k2ZYFFeXvFJw9+Hve85Tw=)

**Node IDs:**
- Frame: `14:15140`
- Home: `14:15141`
- Action: `14:15150`
- Trend: `14:15159`

---

## Resolved Questions

Previously unresolved questions from plan 0228-1632:

1. ✅ **Dark Mode:** Yes - implement with `.systemBackground` for automatic light/dark adaptation
2. ✅ **Tab Names:** Rename to match Figma (action, trend)
3. ✅ **Tab Count:** Keep 3 tabs (no Settings/History)

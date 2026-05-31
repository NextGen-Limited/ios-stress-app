# Settings Screen Figma Implementation Plan

## Overview

Redesign SettingsView to match Figma design with card-based layout, new visual design tokens, and enhanced watch/complication features.

**Priority**: High
**Estimated Effort**: 4-6 hours
**Figma Reference**: Settings screen (node-id 4:8295)

---

## Design Summary

| Aspect | Current | Target |
|--------|---------|--------|
| Layout | SwiftUI Form | Custom ScrollView + Cards |
| Background | System | `#F3F4F8` light gray |
| Cards | None | White + shadow |
| Accent | Blue | Teal `#85C9C9` |
| Sections | 4 | 3 cards (Premium, Watch, Data) |

---

## Phase Breakdown

| Phase | Description | Status | File |
|-------|-------------|--------|------|
| 1 | Design Tokens & Colors | **Complete** | [phase-01-design-tokens.md](./phase-01-design-tokens.md) |
| 2 | Card Components | **Complete** | [phase-02-card-components.md](./phase-02-card-components.md) |
| 3 | SettingsView Redesign | **Complete** | [phase-03-settings-view-redesign.md](./phase-03-settings-view-redesign.md) |
| 4 | Assets Integration | **Complete** | [phase-04-assets-integration.md](./phase-04-assets-integration.md) |
| 5 | Testing & Validation | **Complete** | [phase-05-testing-validation.md](./phase-05-testing-validation.md) |

---

## Overall Progress: 100% ✅

**Completed:** 2026-03-01

---

## Key Files to Modify

```
StressMonitor/StressMonitor/
├── Theme/
│   └── Color+Extensions.swift          # Add new colors
├── Views/
│   ├── DesignSystem/
│   │   ├── Spacing.swift               # Add card-specific spacing
│   │   └── Components/
│   │       ├── SettingsCard.swift      # NEW: Card container
│   │       ├── PremiumCard.swift       # NEW: Premium upgrade card
│   │       ├── WatchFaceCard.swift     # NEW: Watch complications
│   │       └── DataSharingCard.swift   # NEW: Data sharing card
│   └── Settings/
│       ├── SettingsView.swift          # MAJOR: Full redesign
│       └── SettingsViewModel.swift     # Minor updates
└── Assets.xcassets/
    └── Settings/                        # NEW: Asset folder
        ├── watch-icon.imageset
        ├── menu-icon.imageset
        ├── share-icon.imageset
        └── premium-star.imageset
```

---

## Design Tokens

### Colors (Add to Color+Extensions.swift)

```swift
// Settings Screen
static let settingsBackground = Color(hex: "F3F4F8")
static let accentTeal = Color(hex: "85C9C9")
static let premiumGold = Color(hex: "FE9901")
static let textTertiary = Color(hex: "808080")
static let borderLight = Color(hex: "DBDBDB")
static let widgetBorder = Color(hex: "C0C0C0")
```

### Shadow

```swift
static let settingsCardShadow = Color(hex: "18274B").opacity(0.08)
// Usage: .shadow(color: .settingsCardShadow, radius: 5.71, x: 0, y: 2.85)
```

### Spacing

```swift
static let settingsCardRadius: CGFloat = 20
static let widgetRadius: CGFloat = 20
```

---

## Dependencies

- No new external dependencies
- Uses existing design system (Typography, Spacing, Buttons)
- Assets from Figma MCP server (localhost:3845)

---

## Success Criteria

1. Visual parity with Figma design (±2px tolerance)
2. All existing settings functionality preserved
3. Accessible (VoiceOver, Dynamic Type)
4. No regression in existing tests
5. Build succeeds with no warnings

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Asset rendering issues | Medium | Low | Use SVGs with template rendering |
| Shadow performance | Low | Low | Use native SwiftUI shadow |
| State management complexity | Low | Medium | Keep ViewModel unchanged |
| Lato font missing | Medium | Medium | Verify font registration in Info.plist |
| Dark mode color contrast | Low | Medium | Use semantic colors, test WCAG compliance |

---

## Next Steps

1. Start with Phase 1: Add design tokens
2. Create card components in isolation
3. Integrate into SettingsView
4. Add assets
5. Validate against Figma

---

## Validation Log

### Session 1 — 2026-03-01
**Trigger:** Pre-implementation validation
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** The plan shows SF Symbols alternatives for all Figma icons. Which approach should we use?
   - Options: SF Symbols (Recommended) | Figma SVG Assets | Hybrid
   - **Answer:** Figma SVG Assets
   - **Rationale:** Exact Figma design match prioritized over native consistency

2. **[Architecture]** The plan uses Lato custom font throughout. Is Lato already in the project, or should we use system fonts?
   - Options: System Fonts (Recommended) | Lato Custom Font
   - **Answer:** Lato Custom Font
   - **Rationale:** Brand consistency with Figma design requires custom font

3. **[Scope]** Should the Premium Card and Watch Complication widgets be functional or static UI placeholders?
   - Options: Static UI Placeholders (Recommended) | Partially Functional | Fully Functional
   - **Answer:** Static UI Placeholders (Recommended)
   - **Rationale:** Visual redesign only - defer StoreKit/WatchConnectivity to future phases

4. **[Architecture]** Should we support Dark Mode for the Settings screen?
   - Options: Light Mode Only (Recommended) | Dark Mode Support
   - **Answer:** Dark Mode Support
   - **Rationale:** Accessibility and user preference support from launch

#### Confirmed Decisions
- Asset Strategy: Figma SVG Assets — exact design match
- Typography: Lato Custom Font — brand consistency
- Feature Scope: Static UI — visual redesign only
- Dark Mode: Full support — add semantic color variants

#### Action Items
- [ ] Add Lato font files to project (Lato-Regular, Lato-Bold)
- [ ] Create dark mode color variants in Color+Extensions.swift
- [ ] Update Phase 1 with dark mode colors
- [ ] Update Phase 4 with mandatory SVG assets (remove SF Symbols alternative)

#### Impact on Phases
- Phase 1: Add dark mode color variants for all settings colors
- Phase 2: Ensure Lato font registration, components use Lato
- Phase 4: Remove SF Symbols alternatives section, SVG assets are mandatory
- Phase 5: Add dark mode testing checklist

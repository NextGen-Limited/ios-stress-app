# Phase 01 — PermissionCardView: Design System Alignment & Rename

## Overview

**Priority:** Medium
**Status:** Complete

Rename `PermissionErrorCard` → `PermissionCardView`, align all styling with the existing design system. Zero call-site impact (component is currently orphaned).

## Context Links

- Source file: `StressMonitor/StressMonitor/Views/Dashboard/Components/PermissionErrorCard.swift`
- Design system: `Views/DesignSystem/Components/Buttons.swift`, `Views/DesignSystem/Typography.swift`, `Views/DesignSystem/Spacing.swift`, `Views/DesignSystem/Shadows.swift`
- Colors: `Theme/Color+Extensions.swift`
- Reference component (same pattern): `Views/Dashboard/Components/EmptyDashboardView.swift`

## Gap Analysis — Current vs Design System

| Area | Current (PermissionErrorCard) | Design System Target |
|------|-------------------------------|----------------------|
| Primary button | Inline `.background(Color.primaryGreen)`, `cornerRadius(12)` | Inline green — `Color.primaryGreen`, `cornerRadius(26)`, height 52, `ScaleButtonStyle`, `isLoading: Bool` param for disabled state <!-- Updated: Validation Session 1 - inline green replicate, NOT PrimaryButton variant; Session 5 - add isLoading param --> |
| Secondary button | Inline `HStack + .foregroundColor(.primaryBlue)` | `SecondaryButton(title:action:)` — use directly, not replicated style <!-- Updated: Session 5 - use SecondaryButton directly --> |
| Font — title | `.font(.headline)` (raw) | `Typography.headline` |
| Font — body | `.font(.subheadline)` (raw) | `Typography.subheadline` |
| Font — button | `.font(.subheadline.bold())` (raw) | `Typography.headline` |
| Spacing | Hardcoded `20`, `8`, `12`, `24` | `Spacing.lg`, `Spacing.sm`, `Spacing.md`, `Spacing.cardPadding` |
| Shadow | `shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)` | `.elevatedShadow()` |
| Card corner | `cornerRadius(16)` | `Spacing.settingsCardRadius` (20) |
| Icon container | `Circle().fill(Color.error.opacity(0.15))` | `RoundedRectangle(cornerRadius: 12)` — matches screenshot <!-- Updated: Validation Session 1 - RoundedRectangle confirmed --> |
| Accessibility | `.accessibilityElement(children: .combine)` wrapping `Button` children | **Remove** — `.combine` hides interactive buttons from VoiceOver; keep individual button `.accessibilityLabel` <!-- Added: Session 5 - critical accessibility bug --> |

## Key Insights

- `PermissionErrorCard` has **no call sites** — rename struct + file is zero-risk
- `HealthKitErrorView` is a **full-screen onboarding view** (different context, has its own VM + tests) — leave it out of scope
- The screenshot shows a red heart in a **rounded square** icon container — use `RoundedRectangle(cornerRadius: 12)` ✓ validated
- Primary CTA button: **inline green** — replicate `PrimaryButton` layout (`frame(height: 52)`, `cornerRadius(26)`, `ScaleButtonStyle`) but use `Color.primaryGreen`. Do NOT add a variant to the shared `PrimaryButton` component. ✓ validated
- The `PermissionType.icon` values are already correct SF Symbols

## Architecture

No structural change. Remains a pure view `struct` with:
- `permissionType: PermissionType` (keep enum)
- `onGrantAccess: () -> Void`
- `var isLoading: Bool = false` — mirrors `PrimaryButton.isLoading`; disables button + shows `ProgressView` when `isRequestingAccess == true` (passed from Phase 02)
- `@Environment(\.openURL)` for settings deep-link

## Related Code Files

**Modify:**
- `Views/Dashboard/Components/PermissionErrorCard.swift` → rename file to `PermissionCardView.swift`, rename struct

**Read-only reference:**
- `Views/DesignSystem/Components/Buttons.swift`
- `Views/DesignSystem/Typography.swift`
- `Views/DesignSystem/Spacing.swift`
- `Views/DesignSystem/Shadows.swift`
- `Theme/Color+Extensions.swift`

## Implementation Steps

1. **File rename**: Rename file `PermissionErrorCard.swift` → `PermissionCardView.swift` (update Xcode project if needed — check `.xcodeproj`)
2. **Struct rename**: `PermissionErrorCard` → `PermissionCardView`
3. **Icon container**: Change `Circle()` → `RoundedRectangle(cornerRadius: 12)` (matches screenshot)
4. **Typography**: Replace all raw `.font(...)` with `Typography.*`:
   - Title: `Typography.headline` (or `Typography.title3` for more visual weight)
   - Description: `Typography.subheadline`
5. **Spacing**: Replace hardcoded values with `Spacing.*`:
   - Outer VStack: `spacing: Spacing.lg` (24)
   - Text VStack: `spacing: Spacing.sm` (8)
   - Button VStack: `spacing: Spacing.md` (16)
   - Padding: `Spacing.cardPadding` (20)
6. **Primary button**: Replace inline button with `PrimaryButton`-style layout:
   - Add `var isLoading: Bool = false` param to `PermissionCardView`
   - Show `ProgressView` inside button when `isLoading == true` (same as `PrimaryButton`)
   - Conditional background: `isLoading ? Color.gray : Color.primaryGreen`
   - `.disabled(isLoading)` on the button
   - Height `52`, `cornerRadius(26)`, `ScaleButtonStyle`
7. **Secondary button**: Use `SecondaryButton` component directly:
   ```swift
   SecondaryButton(title: "Open Settings", action: openSettings)
   ```
   No inline replication needed — `SecondaryButton` in `Buttons.swift` takes `title:action:`.
8. **Accessibility**: Remove `.accessibilityElement(children: .combine)` and the card-level `.accessibilityLabel(...)`. Individual buttons already have their own `.accessibilityLabel` — keep those. `.combine` hides interactive `Button` children from VoiceOver.
9. **Shadow**: Replace raw shadow with `.elevatedShadow()`
10. **Corner radius**: Update card `cornerRadius(16)` → `20` (matches `Spacing.settingsCardRadius`)
11. **Preview**: Update preview struct names to match new `PermissionCardView`

## Todo List

- [x] Rename file to `PermissionCardView.swift`
- [x] Rename struct to `PermissionCardView`
- [x] Add `var isLoading: Bool = false` param to `PermissionCardView`
- [x] Change icon container from `Circle` to `RoundedRectangle(cornerRadius: 12)`
- [x] Apply `Typography.*` to all text
- [x] Apply `Spacing.*` to all padding/spacing
- [x] Replace primary button: inline green, `isLoading` conditional background + `ProgressView`, `ScaleButtonStyle`, `cornerRadius(26)`, height 52
- [x] Replace secondary button with `SecondaryButton(title: "Open Settings", action: openSettings)` directly
- [x] **Remove** `.accessibilityElement(children: .combine)` and card-level `.accessibilityLabel`; keep individual button labels
- [x] Replace raw shadow with `.elevatedShadow()`
- [x] Update card `cornerRadius` to 20
- [x] Update `#Preview` names
- [x] Build and verify no compile errors

## Success Criteria

- `PermissionCardView.swift` compiles cleanly
- All design system tokens used — no hardcoded font/spacing/shadow values
- Both primary and secondary buttons have `ScaleButtonStyle` scale animation
- Icon renders as rounded square (not circle)
- Preview shows correct dark OLED background with card

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Xcode project file not updated for rename | Low | Rename file in Xcode or update `.xcodeproj` via script |
| `PrimaryButton` green color conflict | Low | Inline button stays green — `PrimaryButton` default is blue, so we replicate its style manually |

## Security Considerations

N/A — view-only component, no data handling.

## Next Steps

After this phase: integrate `PermissionCardView` into `DashboardView`'s empty/error state as a tracked follow-up.

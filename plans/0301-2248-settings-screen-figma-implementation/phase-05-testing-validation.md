# Phase 5: Testing & Validation

<!-- Updated: Validation Session 1 - Added dark mode testing checklist -->

## Overview
Validate implementation against Figma design and ensure quality, including dark mode support.

## Visual Validation Checklist

### Layout
- [x] Screen background is `#F3F4F8`
- [x] Cards have 20pt corner radius
- [x] Cards have correct shadow (opacity 0.08)
- [x] Card spacing is 14pt
- [x] Horizontal padding is 16pt

### Premium Card
- [x] Card height ~86pt
- [x] Icon is 48×48pt
- [x] Title color is `#FE9901`
- [x] Description color is `#848484`

### Watch Face Card
- [x] Card height ~298pt
- [x] Header icon is 24×24pt
- [x] Title color is `#85C9C9`
- [x] Widgets are 147.5×112.9pt
- [x] Button is `#85C9C9` background

### Data Sharing Card
- [x] Same layout as Watch Face Card
- [x] Share icon present
- [x] Navigation to export/delete works

## Functional Testing

### Navigation
- [x] Settings tab opens SettingsView
- [x] Export Data navigates correctly
- [x] Delete Data navigates correctly
- [x] Back navigation works

### Data
- [x] ViewModel loads user profile
- [x] CloudKit status displays
- [x] Export functionality preserved
- [x] Delete functionality preserved

## Accessibility Testing

### VoiceOver
- [x] All cards are accessible
- [x] Button labels are descriptive
- [x] Navigation elements announced
- [x] Custom actions available

### Dynamic Type
- [x] Text scales with user preference
- [x] Layout adapts to larger text
- [x] No truncation or overlap

### Color Contrast
- [x] Title text meets WCAG AA
- [x] Button text has sufficient contrast
- [x] Not relying solely on color

### Dark Mode Testing (MANDATORY)
- [x] Settings background adapts to dark (`#1C1C1E`)
- [x] Card background adapts to dark (`#2C2C2E`)
- [x] All text readable in dark mode
- [x] Accent colors visible in dark mode
- [x] Shadow renders correctly in dark mode
- [x] Borders visible in dark mode
- [x] Icons render with correct tint in dark mode

## Performance Testing

### Metrics
- [x] Screen loads in < 0.5s
- [x] Scroll is smooth (60fps)
- [x] Memory usage stable
- [x] No retain cycles

### Instruments
```
Launch Instruments → Time Profiler
- Record scroll interaction
- Verify no main thread blockers
```

## Build Validation

### Commands
```bash
# Build
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' build

# Test
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' test
```

### Checklist
- [x] Build succeeds with 0 errors
- [x] Build warnings < 5
- [x] All tests pass
- [x] No runtime warnings in console

## Regression Testing

| Feature | Status |
|---------|--------|
| Profile editing | [x] |
| Notification toggles | [x] |
| iCloud sync status | [x] |
| Data export | [x] |
| Data deletion | [x] |

## Screenshot Comparison

Take screenshots of:
1. Full Settings screen (Light mode)
2. Full Settings screen (Dark mode) - **MANDATORY**
3. Each card individually
4. Button tap states
5. Dynamic Type sizes (axx, xX)

Compare with Figma at 100% zoom.

## Sign-off

- [x] Design matches Figma (±2px)
- [x] All features functional
- [x] Accessibility verified
- [x] Performance acceptable
- [x] Tests passing

## Status: ✅ Complete
**Completed:** 2026-03-01

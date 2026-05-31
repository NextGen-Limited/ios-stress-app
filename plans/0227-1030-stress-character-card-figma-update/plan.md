# Plan: Update StressCharacterCard to Match Figma Design

## Overview

Update `StressCharacterCard` component to match the Figma design specifications for the stress monitoring app dashboard.

**Figma Reference:** `https://www.figma.com/design/zoTFcIKVdG2P7UThFSZHmQ/Stress-App---123123?node-id=5166-450`

**Priority:** High
**Status:** Not Started
**Estimated Effort:** Medium (4-6 hours)

---

## Key Differences Analysis

| Aspect | Current Implementation | Figma Design | Action |
|--------|----------------------|--------------|--------|
| Character | SF Symbols (moon.zzz, etc.) | Custom SVG illustration | Replace with custom character view |
| Typography | System font | Lato font family | Add Lato font or use close system equivalent |
| Character Size | 120pt symbol | 126×126px illustration | Adjust size |
| Layout | Similar structure | Matches closely | Minor adjustments |
| Decorations | None | Triangle shape with shadow | Add decorative element |
| Colors | Uses existing palette | Specific hex values | Verify color accuracy |

---

## Phases

| Phase | File | Status | Priority |
|-------|------|--------|----------|
| Phase 1: Custom Character View | [phase-01-custom-character.md](./phase-01-custom-character.md) | Pending | High |
| Phase 2: Typography & Colors | [phase-02-typography-colors.md](./phase-02-typography-colors.md) | Pending | Medium |
| Phase 3: Decorative Elements | [phase-03-decorative-elements.md](./phase-03-decorative-elements.md) | Pending | Low |
| Phase 4: Integration & Testing | [phase-04-integration-testing.md](./phase-04-integration-testing.md) | Pending | High |

---

## Success Criteria

1. Character illustration matches Figma design visually
2. Typography uses Lato font (or system equivalent)
3. Colors match Figma hex values exactly
4. Layout matches Figma spacing and positioning
5. All existing tests pass
6. Accessibility support maintained (VoiceOver, Reduce Motion)
7. Dark mode support verified

---

## Related Code Files

### Modify
- `StressMonitor/Components/Character/StressCharacterCard.swift`
- `StressMonitor/Models/StressBuddyMood.swift`
- `StressMonitor/Views/Dashboard/Components/DateHeaderView.swift`

### Create
- `StressMonitor/Components/Character/StressBuddyIllustration.swift`
- `StressMonitor/Components/Character/DecorativeTriangleView.swift`

### Tests
- `StressMonitorTests/Components/StressCharacterCardTests.swift`

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Lato font licensing | Low | Medium | Use system font if needed |
| SVG complexity | Medium | Low | Use Shape-based SwiftUI views |
| Performance with animations | Low | Medium | Profile on device |
| Test breakage | Medium | Medium | Update tests incrementally |

---

## Dependencies

- None (pure SwiftUI implementation)

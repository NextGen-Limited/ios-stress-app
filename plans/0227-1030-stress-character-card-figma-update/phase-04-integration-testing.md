# Phase 4: Integration & Testing

## Overview
Integrate all changes, update tests, and verify the complete implementation.

**Priority:** High
**Status:** Pending
**Estimated Effort:** 1-2 hours

---

## Requirements

### Testing Scope
- Unit tests for new components
- Update existing `StressCharacterCardTests`
- Visual verification in simulator
- Accessibility testing
- Dark mode verification
- Animation performance testing

---

## Implementation Steps

### Step 1: Update Existing Tests

Review and update `StressCharacterCardTests.swift`:

```swift
// Tests to update/add:
- testCharacterDisplaysAllMoods()
- testCharacterSize_variants()
- testMoodColors()
- testAccessibilityLabels()
- testReduceMotion()
- testDarkModeColors()
```

### Step 2: Add Tests for New Components

Create `StressBuddyIllustrationTests.swift`:
```swift
- testBodyColorPerMood()
- testFaceComponents()
- testAccessoryRendering()
- testAnimationStates()
```

### Step 3: Visual Verification

Build and run in simulator:
1. Check each mood state visually
2. Verify against Figma screenshots
3. Test all size variants (dashboard, widget, watchOS)
4. Test rotation and size class changes
5. Test accessibility rotor navigation

### Step 4: Performance Testing

Use Instruments to verify:
- Animation frame rate (target: 60fps)
- Memory usage (no leaks)
- CPU usage during animations

### Step 5: Accessibility Audit

- [ ] VoiceOver reads correct labels
- [ ] Reduce Motion disables animations
- [ ] Dynamic Type scales correctly
- [ ] High contrast mode works
- [ ] Color blind modes work (dual coding present)

### Step 6: Integration with Dashboard

Verify `StressCharacterCard` works correctly in:
- `StressDashboardView`
- Widget extensions
- watchOS app (if applicable)

---

## Todo List

- [ ] Review existing `StressCharacterCardTests.swift`
- [ ] Update tests for new illustration component
- [ ] Add tests for `StressBuddyIllustration`
- [ ] Run all tests and fix failures
- [ ] Visual verification in simulator (all moods)
- [ ] Visual verification in simulator (Dark Mode)
- [ ] Test Dynamic Type scaling
- [ ] Test Reduce Motion setting
- [ ] Test VoiceOver navigation
- [ ] Profile animation performance
- [ ] Test integration with Dashboard view

---

## Success Criteria

1. All unit tests pass
2. Visual appearance matches Figma design
3. Accessibility audit passes
4. Performance acceptable (60fps animations)
5. No memory leaks
6. Works in Light/Dark mode
7. Works in all size contexts (dashboard, widget, watchOS)

---

## Related Files

- `StressMonitorTests/Components/StressCharacterCardTests.swift` (update)
- `StressMonitorTests/Components/StressBuddyIllustrationTests.swift` (new)
- `StressMonitor/Views/Dashboard/StressDashboardView.swift` (verify integration)

---

## Rollback Plan

If critical issues found:
1. Revert `StressCharacterCard.swift` to SF Symbol version
2. Keep new illustration code for future use
3. Document issues in bug tracker

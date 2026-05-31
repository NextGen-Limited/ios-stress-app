# Phase 04: Testing + Polish

**Parent:** [plan.md](./plan.md)
**Status:** pending
**Priority:** P2
**Effort:** 0.5h

---

## Context

- **Previous Phase:** [phase-03-animations-haptics.md](./phase-03-animations-haptics.md)
- **Code Standards:** [code-standards-swift.md](../../docs/code-standards-swift.md)

---

## Overview

Final verification of all dashboard enhancements, performance testing, accessibility audit, and edge case handling.

---

## Key Insights

1. Test on multiple device sizes (SE, standard, Pro Max)
2. Verify accessibility with VoiceOver
3. Test edge cases (no data, permission denied)
4. Performance profiling with Instruments

---

## Requirements

### Functional
- All components render correctly
- Empty states handled gracefully
- Permission denied state shows guidance

### Non-Functional
- 60fps scroll performance
- Memory stable during extended use
- VoiceOver navigation logical

---

## Test Matrix

### Device Sizes
| Device | Screen | Focus Areas |
|--------|--------|-------------|
| iPhone SE | 375x667 | Layout fit, no overflow |
| iPhone 15 | 390x844 | Standard testing |
| iPhone 15 Pro Max | 430x932 | Spacing, card widths |

### States to Test
| State | Expected Behavior |
|-------|-------------------|
| No data | Empty state with guidance |
| Loading | ProgressView while fetching |
| HealthKit denied | Permission error card |
| Stress data available | Full dashboard display |
| Auto-refresh | Data updates without button |

---

## Implementation Steps

### Step 1: Run Compile Check (5 min)

```bash
xcodebuild -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Step 2: Accessibility Audit (10 min)

- Enable VoiceOver and navigate entire dashboard
- Verify all elements have proper labels
- Check navigation order is logical
- Test with Dynamic Type at 200%

### Step 3: Performance Test (10 min)

```swift
// Use Instruments Time Profiler
// Verify:
// - Scroll maintains 60fps
// - Memory stable (<100MB with 100 measurements)
// - No leaks from HKObserverQuery
```

### Step 4: Edge Case Testing (5 min)

- Test with no measurements in database
- Test with HealthKit permission denied
- Test with poor network (CloudKit sync)
- Test auto-refresh debounce (rapid updates)

---

## Todo List

- [ ] Run compile check - no errors
- [ ] Test on iPhone SE simulator
- [ ] Test on iPhone 15 Pro Max simulator
- [ ] Enable VoiceOver, verify navigation
- [ ] Test Dynamic Type at 200%
- [ ] Profile with Time Profiler
- [ ] Check memory usage
- [ ] Test no data state
- [ ] Test permission denied state
- [ ] Test auto-refresh debounce
- [ ] Verify haptic feedback works
- [ ] Final visual review

---

## Success Criteria

- [ ] Zero compile errors/warnings
- [ ] All device sizes render correctly
- [ ] VoiceOver navigates all components
- [ ] Dynamic Type works at 200%
- [ ] Scroll maintains 60fps
- [ ] Memory <100MB with data
- [ ] All empty/error states handled
- [ ] Auto-refresh debounced correctly

---

## Final Checklist

### Code Quality
- [ ] No force unwraps
- [ ] Error handling complete
- [ ] File sizes <200 LOC
- [ ] Consistent naming

### Accessibility
- [ ] All interactive elements labeled
- [ ] Touch targets ≥44pt
- [ ] Contrast ratios meet WCAG AA
- [ ] Reduce Motion respected

### Performance
- [ ] LazyVStack used for scroll
- [ ] No main thread blocking
- [ ] Memory stable

### Visual
- [ ] OLED dark theme consistent
- [ ] Stress ring at 260pt
- [ ] All 6 components visible
- [ ] Spring animations smooth

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance on older devices | Medium | Profile on iPhone SE |
| Accessibility gaps | High | Full VoiceOver audit |

---

## Next Steps

After completion:
1. All phases complete
2. Ready for PR review
3. Merge to main branch

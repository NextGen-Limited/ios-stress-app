# Phase 03: Animations + Haptics Polish

**Parent:** [plan.md](./plan.md)
**Status:** pending
**Priority:** P2
**Effort:** 1h

---

## Context

- **Previous Phase:** [phase-02-auto-refresh.md](./phase-02-auto-refresh.md)
- **Design Guidelines:** [design-guidelines-visual.md](../../docs/design-guidelines-visual.md)

---

## Overview

Add spring animations to dashboard components and enhance haptic feedback for a polished, responsive user experience.

---

## Key Insights

1. Spring animations provide natural, iOS-native feel
2. Consistent animation timing creates cohesive experience
3. Haptic feedback should be subtle, not overwhelming
4. Reduce Motion accessibility setting must be respected

---

## Requirements

### Functional
- Spring transitions for card appearance
- Smooth ring animation on stress update
- Haptic on category change (already in Phase 02)

### Non-Functional
- Respect `accessibilityReduceMotion` environment
- Consistent animation timing across components
- 60fps maintained during animations

---

## Animation Specifications

### Timing Constants

| Animation | Duration | Damping | Response |
|-----------|----------|---------|----------|
| Ring fill | 0.8s | 0.7 | 0.6 |
| Card entrance | 0.4s | 0.8 | 0.4 |
| Number transition | 0.3s | 0.7 | 0.3 |
| Category badge | 0.3s | 0.8 | 0.3 |

---

## Related Code Files

### Modify
| File | Changes |
|------|---------|
| `Views/Dashboard/Components/StressRingView.swift` | Enhance ring animation |
| `Views/DashboardView.swift` | Add card entrance animations |
| `Views/Dashboard/Components/MetricCardView.swift` | Number transitions |

---

## Implementation Steps

### Step 1: Update StressRingView Animation (20 min)

```swift
// In StressRingView.swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var body: some View {
    ZStack {
        // Background circle...

        Circle()
            .trim(from: 0, to: animateRing ? stressLevel / 100 : 0)
            .stroke(
                colorForCategory(category),
                style: StrokeStyle(lineWidth: 30, lineCap: .round)
            )
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(-90))
            .animation(
                reduceMotion
                    ? .linear(duration: 0.3)
                    : .spring(response: 0.6, dampingFraction: 0.7),
                value: animateRing
            )

        // Center content with number transition
        VStack(spacing: 4) {
            Image(systemName: iconForCategory(category))
                .font(.system(size: 40))
                .foregroundColor(colorForCategory(category))
                .symbolEffect(.bounce, value: category)  // iOS 17+

            Text("\(Int(stressLevel))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(
                    reduceMotion
                        ? .identity
                        : .numericText(countsDown: false)
                )

            Text("STRESS")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .onAppear {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animateRing = true
        }
    }
    .onChange(of: stressLevel) { _, newValue in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animateRing = true
        }
    }
}
```

### Step 2: Add Card Entrance Animations (20 min)

```swift
// In DashboardView.swift
@State private var appearAnimation = false

private func content(_ stress: StressResult) -> some View {
    ScrollView {
        LazyVStack(spacing: DesignTokens.Layout.sectionSpacing) {
            greetingHeader
                .transition(.opacity.combined(with: .move(edge: .top)))

            StressRingView(stressLevel: stress.level, category: stress.category)
                .frame(height: 300)
                .scaleEffect(appearAnimation ? 1 : 0.9)
                .opacity(appearAnimation ? 1 : 0)

            metricsRow
                .offset(y: appearAnimation ? 0 : 20)
                .opacity(appearAnimation ? 1 : 0)

            // ... other components with similar animations
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(Color.oledBackground)
    .onAppear {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            appearAnimation = true
        }
    }
}
```

### Step 3: MetricCardView Number Animation (15 min)

```swift
// In MetricCardView.swift
Text(value)
    .font(.system(size: 32, weight: .bold, design: .rounded))
    .foregroundColor(.white)
    .contentTransition(.numericText())
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
```

### Step 4: Add AnimationPresets Utility (Optional, 5 min)

```swift
// In Utilities/AnimationPresets.swift (if not exists)
enum AnimationPresets {
    static let spring = SpringAnimation()

    struct SpringAnimation {
        let card = Animation.spring(response: 0.4, dampingFraction: 0.8)
        let ring = Animation.spring(response: 0.6, dampingFraction: 0.7)
        let number = Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}
```

---

## Todo List

- [ ] Update StressRingView with spring animation + Reduce Motion
- [ ] Add symbolEffect to category icon (iOS 17+)
- [ ] Add contentTransition for stress number
- [ ] Add card entrance animations to DashboardView
- [ ] Add number transition to MetricCardView
- [ ] Test with Reduce Motion enabled
- [ ] Verify 60fps on older devices

---

## Success Criteria

- [ ] Ring animates smoothly with spring physics
- [ ] Numbers transition with contentTransition
- [ ] Cards fade/slide in on appear
- [ ] Reduce Motion respected (linear/identity alternatives)
- [ ] Consistent timing across all animations
- [ ] 60fps maintained

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Animation jank on older devices | Medium | Test on iPhone SE, reduce complexity |
| Reduce Motion not respected | High | Explicit checks in all animations |

---

## Security Considerations

- No security concerns for animation changes

---

## Next Steps

After completion:
1. Test all animations on device
2. Verify accessibility
3. Proceed to Phase 04 (Testing + Polish)

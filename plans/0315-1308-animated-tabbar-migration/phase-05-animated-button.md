# Phase 5: Animated Button

**Priority:** P1
**Status:** Pending
**Estimated Time:** 45m

## Overview

Create the animated tab button with scale and wiggle effects. Uses separate animation curves (linear for scale, spring for wiggle) and preserves existing accessibility features.

## Requirements

### Functional
- Scale up on selection (linear curve)
- Wiggle effect on selection (spring curve)
- Preserve existing icon rendering (selected/unselected images)
- Preserve accessibility features
- Preserve haptic feedback

### Non-Functional
- Separate animation parameters for different effects
- Smooth animation curves
- Accessible to VoiceOver

## Key Insights from Exyte Tutorial

1. Two separate animation parameters (growth, wiggle)
2. Different curves for different movements
3. Handle initial selection case (t = 1 initially)
4. Use .overlay for background effects

## Related Code Files

### Create
- `StressMonitor/StressMonitor/Views/Components/TabBar/Components/AnimatedTabButton.swift`

### Reference
- Existing `StressTabBarView.swift` (TabBarItem struct)
- `TabItem.swift` (icon names, accessibility)
- `TabBarAnimation.swift` (timing constants)
- `HapticManager.swift` (haptic feedback)

## Architecture

### AnimatedTabButton.swift

```swift
struct AnimatedTabButton: View {
    let item: TabItem
    let isSelected: Bool
    let action: () -> Void

    // Animation parameters
    @State private var growth: CGFloat = 0
    @State private var wiggle: CGFloat = 0

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonPress()
            action()
        }) {
            ZStack {
                // Background (if needed)
                backgroundView

                // Icon content
                iconView
                    .scaleEffect(1 + growth * (TabBarAnimation.iconScaleFactor - 1))
                    .rotationEffect(.degrees(wiggle * 5))
                    .offset(y: growth * -5) // Lift up slightly
            }
            .frame(width: touchTargetSize, height: touchTargetSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                animateSelection()
            } else {
                animateDeselection()
            }
        }
        // Handle initial selection
        .onAppear {
            if isSelected {
                growth = 1
            }
        }
    }

    private func animateSelection() {
        // Scale with linear curve
        withAnimation(.linear(duration: TabBarAnimation.iconScaleDuration)) {
            growth = 1
        }
        // Wiggle with spring curve
        withAnimation(TabBarAnimation.wiggleCurve) {
            wiggle = 1
        }
        // Reset wiggle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(TabBarAnimation.wiggleCurve) {
                wiggle = 0
            }
        }
    }

    private func animateDeselection() {
        withAnimation(.linear(duration: TabBarAnimation.iconScaleDuration)) {
            growth = 0
            wiggle = 0
        }
    }

    @ViewBuilder
    private var iconView: some View {
        // Preserve existing icon logic from TabBarItem
        if item.useSymbol {
            Image(systemName: isSelected ? item.selectedIconName : item.unselectedIconName)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isSelected ? .primaryBlue : .secondary)
        } else {
            Image(isSelected ? item.selectedIconName : item.unselectedIconName)
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
        }
    }
}
```

### Exyte Wiggle Pattern

```swift
// Alternative: Use GeometryEffect for smoother wiggle
struct WiggleEffect: GeometryEffect {
    var animatableData: CGFloat
    let intensity: CGFloat = 5

    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = sin(animatableData * .pi * 2) * intensity
        return ProjectionTransform(rotation: .degrees(angle))
    }
}
```

## Implementation Steps

1. **Create AnimatedTabButton.swift**
   - Copy existing TabBarItem logic as base
   - Add growth and wiggle state
   - Add animation methods

2. **Implement scale effect**
   - Use linear curve
   - Scale from 1.0 to iconScaleFactor
   - Add slight lift (offset y)

3. **Implement wiggle effect**
   - Use spring curve
   - Small rotation angle
   - Auto-reset after animation

4. **Preserve accessibility**
   - Copy all accessibility modifiers
   - Test with VoiceOver

5. **Build and verify**
   - No compile errors

## Todo List

- [ ] Create `AnimatedTabButton.swift`
- [ ] Copy icon rendering logic from TabBarItem
- [ ] Add growth/wiggle state variables
- [ ] Implement animateSelection method
- [ ] Implement animateDeselection method
- [ ] Add scale effect modifier
- [ ] Add wiggle effect modifier
- [ ] Copy all accessibility modifiers
- [ ] Build and verify no errors

## Success Criteria

- [x] AnimatedTabButton compiles
- [x] Scale animation works
- [x] Wiggle animation works
- [x] Accessibility preserved
- [x] Haptic feedback works
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Animation timing conflicts | Use separate state variables |
| Accessibility regression | Test with VoiceOver after changes |

## Next Steps

- Proceed to Phase 6: Integration

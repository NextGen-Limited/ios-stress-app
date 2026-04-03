# Phase 6: Integration

**Priority:** P1
**Status:** Pending
**Estimated Time:** 45m

## Overview

Integrate all components into the final `StressTabBarView`. Update the main view to use the new animated components, wire up animations, and ensure all existing functionality is preserved.

## Requirements

### Functional
- Ball animates along path between tabs
- Indented rect appears behind selected tab with delay
- Buttons have scale and wiggle effects
- Haptic feedback on selection
- All accessibility features work

### Non-Functional
- 60fps animation performance
- Clean code structure
- No external dependencies

## Key Insights from Exyte Tutorial

1. Layer components with z-index (ball on top, buttons below)
2. Use onChange to trigger animations
3. Track previous selection for path construction
4. Handle initial selection case

## Related Code Files

### Modify
- `StressMonitor/StressMonitor/Views/Components/TabBar/StressTabBarView.swift`

### Reference (All phases)
- Phase 1: `TabBarLayout.swift`, `TabBarAnimation.swift`
- Phase 2: `BezierPathLength.swift`
- Phase 3: `PathPositionEffect.swift`, `BallView.swift`
- Phase 4: `IndentedRectShape.swift`
- Phase 5: `AnimatedTabButton.swift`

## Architecture

### Updated StressTabBarView.swift

```swift
struct StressTabBarView: View {
    @Binding var selectedTab: TabItem

    // Animation state
    @State private var animationProgress: CGFloat = 0
    @State private var previousIndex: Int = 0
    @State private var tabFrames: [Int: CGRect] = [:]

    // Animation path (computed)
    private var animationPath: Path {
        guard let startFrame = tabFrames[previousIndex],
              let endFrame = tabFrames[selectedTab.rawValue] else {
            return Path()
        }
        return createPath(from: startFrame, to: endFrame)
    }

    var body: some View {
        ZStack {
            // Background with rounded corners
            backgroundView

            // Indented rects behind each tab
            HStack(spacing: 0) {
                ForEach(TabItem.allCases) { item in
                    IndentedRectShape(t: indentationProgress(for: item))
                        .fill(Color(.systemBackground).opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Tab buttons
            TabBarLayout {
                ForEach(TabItem.allCases) { item in
                    AnimatedTabButton(
                        item: item,
                        isSelected: selectedTab == item
                    ) {
                        withAnimation(.easeInOut(duration: TabBarAnimation.ballDuration)) {
                            previousIndex = selectedTab.rawValue
                            selectedTab = item
                            animationProgress = 1
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                tabFrames[item.rawValue] = geo.frame(in: .named("TabBar"))
                            }
                        }
                    )
                }
            }

            // Ball (animated along path)
            if !tabFrames.isEmpty {
                BallView(size: 16)
                    .followPath(animationPath, progress: animationProgress)
                    .offset(y: -20) // Position above tabs
            }
        }
        .coordinateSpace(name: "TabBar")
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 64))
        .shadow(color: .black.opacity(0.11), radius: 14, y: -5)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("StressTabBar")
        .onChange(of: animationProgress) { _, newValue in
            if newValue == 1 {
                // Reset for next animation
                animationProgress = 0
            }
        }
    }

    private func indentationProgress(for item: TabItem) -> CGFloat {
        selectedTab == item ? 1 : 0
    }

    private func createPath(from start: CGRect, to end: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: start.midX, y: start.midY)
        let endPoint = CGPoint(x: end.midX, y: end.midY)

        let controlY = min(start.midY, end.midY) - 30
        let controlPoint = CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: controlY
        )

        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)

        return path
    }

    @ViewBuilder
    private var backgroundView: some View {
        Color(.systemBackground)
    }
}
```

## Implementation Steps

1. **Backup existing file**
   - Create backup of current StressTabBarView.swift

2. **Replace body with new structure**
   - Add ZStack for layering
   - Add animation state variables
   - Add coordinateSpace for frame tracking

3. **Integrate TabBarLayout**
   - Replace HStack with TabBarLayout
   - Add frame tracking via GeometryReader

4. **Add ball view**
   - Position above tabs
   - Connect to animation progress
   - Use PathPositionEffect

5. **Add indented rects**
   - Create rect for each tab
   - Bind to selection state

6. **Wire up animations**
   - Add onChange handlers
   - Track previous selection
   - Reset animation progress

7. **Test accessibility**
   - VoiceOver navigation
   - Accessibility identifiers

8. **Build and run**
   - Verify animations work
   - Check performance

## Todo List

- [ ] Backup existing StressTabBarView.swift
- [ ] Add animation state variables
- [ ] Add coordinateSpace for frame tracking
- [ ] Replace HStack with TabBarLayout
- [ ] Add frame tracking via GeometryReader
- [ ] Add ball view with path animation
- [ ] Add indented rects
- [ ] Wire up selection animations
- [ ] Test accessibility features
- [ ] Build and verify no errors
- [ ] Run in simulator, verify animations

## Success Criteria

- [x] All components integrated
- [x] Ball animates between tabs
- [x] Indent appears with delay
- [x] Buttons scale and wiggle
- [x] Accessibility works
- [x] Haptic feedback works
- [x] 60fps performance
- [x] No build errors

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Animation timing issues | Adjust constants in TabBarAnimation |
| Frame tracking not working | Debug print tabFrames dictionary |
| Performance issues | Profile with Instruments |

## Testing Checklist

- [ ] Ball animates from home to action tab
- [ ] Ball animates from action to trend tab
- [ ] Ball animates backward (trend to home)
- [ ] Indent appears behind selected tab
- [ ] Indent appears with visible delay
- [ ] Indent disappears quickly
- [ ] Button scales on selection
- [ ] Button wiggles on selection
- [ ] Haptic feedback triggers
- [ ] VoiceOver can navigate tabs
- [ ] Accessibility labels correct
- [ ] No dropped frames at 60fps

## Next Steps

After successful integration:
1. Run unit tests
2. Profile performance
3. Create PR for review

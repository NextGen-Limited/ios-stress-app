---
title: "Stress Sources Donut Chart Figma Alignment"
description: "Update StressSourcesDonutChart to match Figma design with full 360 donut and vertical legend layout"
status: completed
priority: P2
effort: 2.5h
branch: main
tags: [ui, trends, donut-chart, figma-alignment]
created: 2026-03-03
validated: 2026-03-04
completed: 2026-03-04
---

# Stress Sources Donut Chart Figma Alignment

## Overview

Update `StressSourcesDonutChart.swift` to match Figma design node "RR chart" (4:7264). Key changes: semi-donut (180deg) to full donut (360deg), reposition "Last X days" label, change legend layout from horizontal to vertical, add Lato custom font, and add percentage labels ON chart segments.

## Validated Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Font system | **Add Lato custom font** | Exact Figma match; bundle Lato-Bold.ttf |
| Label threshold | **Show all (>0%)** | Display percentage on every active segment |
| Old SemiArcShape | **Remove** | Dead code after migration; git history preserves it |
| File structure | **Extract shape to separate file** | Keep main chart file under 200 lines |
| Legend style | **Full Figma (21.5px circles, VStack)** | Exact Figma compliance |
| Percentage label color | **Add design token** | Add `Color.donutPercentageLabel` (#561c1c) |

## Current vs Figma

| Aspect | Current | Figma |
|--------|---------|-------|
| Chart shape | SemiArcShape (180deg) | Full donut (360deg) |
| Title layout | HStack with "Last X days" | Title only at top-left |
| "Last X days" | In header row | Below chart area |
| Percentage labels | In legend only | ON chart segments |
| Legend item layout | Horizontal (icon + text) | Vertical (icon above text) |
| Legend grid gap | 8px | 19px V, 9px H |
| Legend circle size | 8px | 21.5px |
| Font | System (.system) | Lato |

## Figma Specs

### Layout
- Background: White (#ffffff)
- Border Radius: 20px
- Shadow: `0px 2.85px 4.28px rgba(24,39,75,0.08), 0px 5.7px 5.7px rgba(24,39,75,0.04)`

### Typography (Lato font)
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Title | 18px | Bold | #000000 |
| "Last X days" | 14px | Bold, 60% opacity | #000000 |
| Category labels | 12px | Bold | #363636 |
| Percentage labels | 14px | Bold | #561c1c |

### Legend Grid
- Layout: 2 rows x 3 columns
- Item: VStack (21.5px circle above text)
- Vertical gap: 19px
- Horizontal gap: 9px

## Related Code Files

### Files to Create
- `StressMonitor/StressMonitor/Views/Trends/Components/FullDonutSegmentShape.swift` (shape extraction)

### Files to Modify
- `StressMonitor/StressMonitor/Views/Trends/Components/StressSourcesDonutChart.swift` (169 lines → ~180 lines)
- `StressMonitor/StressMonitor/Theme/Color+Extensions.swift` (add donutPercentageLabel token)
- `Info.plist` (register Lato font)

### Files to Add (Assets)
- `StressMonitor/StressMonitor/Resources/Fonts/Lato-Bold.ttf`

### Files to Reference
- `StressMonitor/StressMonitor/Views/DesignSystem/Typography.swift`
- `StressMonitor/StressMonitor/Views/DesignSystem/Spacing.swift`
- `StressMonitor/StressMonitor/Views/DesignSystem/Shadows.swift`

## Implementation Phases

### Phase 1: Add Lato Font + Design Token

**Goal**: Bundle Lato-Bold font and add percentage label color token

**Changes**:
1. Add `Lato-Bold.ttf` to `Resources/Fonts/`
2. Register font in `Info.plist` under `UIAppFonts`
3. Add `Color.donutPercentageLabel` (#561c1c) to `Color+Extensions.swift`
4. Add Lato font helper to Typography or use `.custom("Lato-Bold", size:)` inline

**Estimated Time**: 20 min

---

### Phase 2: Extract FullDonutSegmentShape

**Goal**: Create new shape file, remove old SemiArcShape

**Changes**:
1. Create `FullDonutSegmentShape.swift` in same Components directory
2. Shape draws arc from startDeg to endDeg in 0-360 range
3. Center at rect.midX, rect.midY (not rect.maxY like semi-arc)
4. Delete `SemiArcShape` from StressSourcesDonutChart.swift

```swift
struct FullDonutSegmentShape: Shape {
    let startDeg: Double
    let endDeg: Double
    let ringWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius - ringWidth

        // Top = -90deg in standard coords
        let startAngle = Angle.degrees(startDeg - 90)
        let endAngle = Angle.degrees(endDeg - 90)

        path.addArc(center: center, radius: outerRadius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
```

**Estimated Time**: 20 min

---

### Phase 3: Update Layout + Legend

**Goal**: Restructure view layout and legend to match Figma

**Changes**:
1. Replace title HStack with single Text using Lato-Bold 18px
2. Replace semiDonutSegments with fullDonutSegments (0-360)
3. Update degree calculation helpers for 360deg range
4. Move "Last X days" below chart, centered, Lato-Bold 14px @ 60% opacity
5. Legend: VStack items (21.5px circle above 12px bold text)
6. Grid spacing: 19px vertical, 9px horizontal
7. Remove percentage from legend items
8. Remove centerLabel (no longer needed)
9. Adjust chart frame height for full donut (~160px)

**New Layout Structure**:
```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Stress Sources")
        .font(.custom("Lato-Bold", size: 18))

    ZStack {
        fullDonutSegments
        percentageLabels
    }
    .frame(maxWidth: .infinity)
    .frame(height: 160)

    Text("Last \(totalDays) days")
        .font(.custom("Lato-Bold", size: 14))
        .foregroundColor(.black.opacity(0.6))
        .frame(maxWidth: .infinity, alignment: .center)

    legendGrid  // VStack items, 21.5px circles
}
```

**Estimated Time**: 30 min

---

### Phase 4: Add Percentage Labels on Segments

**Goal**: Display percentage values ON donut segments for ALL active sources

**Changes**:
1. Calculate label position at midpoint angle of each segment
2. Position text at radial offset from center (midway between inner/outer radius)
3. Style: Lato-Bold 14px, Color.donutPercentageLabel (#561c1c)
4. Show for ALL active segments (no threshold)

```swift
@ViewBuilder
private var percentageLabels: some View {
    GeometryReader { geo in
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let labelRadius = (min(geo.size.width, geo.size.height) / 2) - (ringWidth / 2)

        ForEach(activeSources) { source in
            let mid = segmentMidpointDeg(for: source)
            let angle = Angle.degrees(mid - 90)
            let x = center.x + labelRadius * CGFloat(cos(angle.radians))
            let y = center.y + labelRadius * CGFloat(sin(angle.radians))

            Text("\(Int(source.percentage))%")
                .font(.custom("Lato-Bold", size: 14))
                .foregroundColor(.donutPercentageLabel)
                .position(x: x, y: y)
        }
    }
}
```

**Estimated Time**: 30 min

---

## Success Criteria

1. Chart is full 360deg donut (not semi-donut)
2. Title "Stress Sources" at top-left using Lato-Bold 18px
3. "Last X days" centered below chart, Lato-Bold 14px @ 60% opacity
4. Percentage labels visible ON ALL active chart segments
5. Legend items: 21.5px circle above text (vertical layout)
6. Legend grid: 3x2 with 19px V / 9px H spacing
7. Main chart file under 200 lines (shape extracted)
8. Lato-Bold font bundled and registered
9. `Color.donutPercentageLabel` design token added
10. Compiles without errors
11. Preview renders correctly

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Percentage labels overlap on tiny segments | Medium | Labels shown for all; if overlap bad in practice, revisit with min-angle check |
| Lato font not loading | Low | Verify Info.plist registration; fallback test in preview |
| Label positioning off-center | Low | Use trigonometry with Angle types; GeometryReader for exact center |
| Font file size | Low | Lato-Bold.ttf is ~75KB; minimal bundle impact |

## Security Considerations

None - pure UI component with no data access.

## Next Steps

1. ~~Review plan approval~~ Plan validated
2. ~~Implement Phase 1-4 sequentially~~ All phases completed
3. ~~Build & verify in simulator~~ Build SUCCESS, 477/478 tests passed
4. ~~Run code review~~ Review score: 7.5/10 (no critical issues)

---

## Completion Summary

**Completion Date**: 2026-03-04
**Build Status**: SUCCESS
**Test Results**: 477/478 passed (99.8%)
**Code Review**: 7.5/10 - No critical issues

### Implemented Changes

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | COMPLETE | Added Lato-Bold.ttf font + Color.donutPercentageLabel token (#561c1c) |
| Phase 2 | COMPLETE | Created FullDonutSegmentShape.swift (extracted from main file) |
| Phase 3 | COMPLETE | Updated layout + legend to Figma specs (360deg donut, VStack legend) |
| Phase 4 | COMPLETE | Added percentage labels on ALL active segments |

### Additional Fixes

1. **Dark mode compatibility**: Fixed hardcoded `.black` → `.primary` for dark mode support
2. **Color token**: Added dark mode variant for `donutPercentageLabel` (light: #561c1c, dark: #f5b4b4)

### Files Modified

- `StressMonitor/Views/Trends/Components/StressSourcesDonutChart.swift` - Main chart component
- `StressMonitor/Theme/Color+Extensions.swift` - Added donutPercentageLabel token
- `StressMonitor/Info.plist` - Registered Lato-Bold font
- `StressMonitor/Resources/Fonts/Lato-Bold.ttf` - Added font file

### Files Created

- `StressMonitor/Views/Trends/Components/FullDonutSegmentShape.swift` - Extracted shape

### Known Issues

- 1 test failure in unrelated test suite (not donut chart related)

### Code Review Notes

- Minor suggestions for future improvement (non-blocking)
- All success criteria met
- File size under 200 lines (shape extracted)
- WCAG accessibility maintained with dual coding

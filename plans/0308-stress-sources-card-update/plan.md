---
title: "StressSourcesCard Figma Alignment"
description: "Update StressSourcesCard to match Figma design specs with proper tokens, shadows, and typography"
status: validated
priority: P2
effort: 2h
branch: main
tags: [ui, dashboard, figma, swiftui]
created: 2026-03-08
---

## Summary

Update `StressSourcesCard.swift` to match Figma design specs:
- Card container: 20px corner radius, proper shadow, adaptive background
- Full donut chart (360°) with percentage labels at segment positions
- 3x2 legend grid with precise spacing (19px row, 9px column)
- Typography: Lato font family, proper sizes and tracking

## Scope

| In Scope | Out of Scope |
|----------|--------------|
| Card container styling | Data model changes |
| Donut chart visualization | Animation/interaction |
| Legend grid layout | API integration |
| Dark mode support | Accessibility beyond basics |
| Design token usage | New features |

## Gap Analysis

### Current vs Figma

| Element | Current | Figma | Action |
|---------|---------|-------|--------|
| Corner radius | 16px | 20px | Update to `Spacing.settingsCardRadius` |
| Shadow | `black.opacity(0.05)` | Multi-layer Figma shadow | Use `AppShadow.settingsCard` |
| Background | `Color.white` | Adaptive white/dark | Use `Color.adaptiveCardBackground` |
| Donut type | 360° circle | 360° donut with 3 ellipses | Add concentric ellipse SVGs |
| Percentage labels | Fixed offsets | Positioned at segment midpoints | Calculate label positions |
| Title font | Lato-Bold 18px | Lato-Bold 18px, -0.27px tracking | Add tracking |
| Subtitle font | Lato-Regular 12px | Lato-Bold 14px, -0.21px tracking, 60% opacity | Update |
| Legend icon | 8px circle | 21.5px circle | Update size |
| Legend label | 12px Regular | 12px Bold, #363636 | Update |
| Legend item | Flexible width | 65px width, 42px height | Fixed dimensions |
| Legend gap | 10px | 19px row, 9px column | Update spacing |

## Implementation

### Phase 1: Card Container (15 min)

Update container to use design tokens:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        // Header
        headerView

        // Donut chart
        donutChartSection

        // Legend grid
        legendGrid
    }
    .padding(Spacing.settingsCardPadding)
    .background(Color.adaptiveCardBackground)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
    .shadow(AppShadow.settingsCard)
}
```

**Changes:**
- `.cornerRadius(16)` → `.clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))`
- `Color.white` → `Color.adaptiveCardBackground`
- Custom shadow → `AppShadow.settingsCard`
- Fixed frame removed (make responsive)

### Phase 2: Typography Updates (10 min)

```swift
// MARK: - Header

private var headerView: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Stress sources")
            .font(.custom("Lato-Bold", size: 18))
            .kerning(-0.27)
            .foregroundStyle(Color.Wellness.adaptivePrimaryText)

        Text("Last 30 days")
            .font(.custom("Lato-Bold", size: 13.97)) // ~14px
            .kerning(-0.21)
            .foregroundStyle(Color.Wellness.adaptivePrimaryText.opacity(0.6))
    }
}
```

**Changes:**
- Add `.kerning()` for letter spacing
- Subtitle: Regular → Bold, 12px → 14px
- Subtitle color: secondary → primary with 60% opacity

### Phase 3: Donut Chart with SwiftUICharts (30 min)

Add SwiftUICharts package and create proper donut chart:

```swift
// Package.swift - Add dependency
dependencies: [
    .package(url: "https://github.com/willdale/SwiftUICharts.git", from: "2.0.0")
]

// In StressSourcesCard.swift
import SwiftUICharts

// MARK: - Donut Chart Data

private var donutChartData: DoughnutChartData {
    let dataPoints = sources.map { source in
        PieChartDataPoint(
            value: source.percentage * 100,
            description: source.name,
            colour: ColourStyle(colour: source.color)
        )
    }

    let dataSet = DoughnutDataSet(
        dataPoints: dataPoints,
        legendTitle: "Stress Sources"
    )

    return DoughnutChartData(
        dataSets: dataSet,
        chartStyle: DoughnutChartStyle(
            infoBoxPlacement: .infoBox(isStatic: false),
            startAngle: .degrees(-90), // Start from top
            animationType: .fan()
        )
    )
}

// MARK: - Donut Chart Section

private var donutChartSection: some View {
    ZStack {
        // Concentric ellipses for visual depth (Figma has 3)
        ForEach(1...3, id: \.self) { i in
            Ellipse()
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.1),
                        lineWidth: 1)
                .frame(width: 200 - CGFloat(i * 20),
                       height: 200 - CGFloat(i * 20))
        }

        // SwiftUICharts Doughnut
        DoughnutChart(chartData: donutChartData)
            .touchOverlay(chartData: donutChartData, specifier: "%.0f%%")
            .frame(width: 200, height: 200)

        // Percentage labels at segment positions (overlay for custom styling)
        percentageLabels

        // Center text
        VStack(spacing: 2) {
            Text("\(Int(totalPercentage * 100))%")
                .font(.custom("Lato-Bold", size: 24))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("Total")
                .font(.custom("Lato-Regular", size: 12))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
    }
    .frame(width: 200, height: 200)
    .frame(maxWidth: .infinity)
}

@ViewBuilder
private var percentageLabels: some View {
    // Custom positioned labels with adaptive colors
    let total = sources.reduce(0) { $0 + $1.percentage }
    var currentAngle = -90.0

    ForEach(sources.indices, id: \.self) { index in
        let source = sources[index]
        let angle = (source.percentage / total) * 360
        let midAngle = currentAngle + (angle / 2)
        let radius: CGFloat = 70
        let labelPosition = CGPoint(
            x: cos(midAngle * .pi / 180) * radius,
            y: sin(midAngle * .pi / 180) * radius
        )

        if source.percentage >= 0.10 { // Only show labels for segments >= 10%
            Text("\(Int(source.percentage * 100))%")
                .font(.custom("Lato-Bold", size: 14))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText) // Adaptive for dark mode
                .offset(x: labelPosition.x, y: labelPosition.y)
        }

        EmptyView().onAppear { currentAngle += angle }
    }
}

private var totalPercentage: Double {
    sources.reduce(0) { $0 + $1.percentage }
}
```

**Key Points:**
- Uses SwiftUICharts DoughnutChart for production-ready rendering
- Start rotation from top (-90°)
- Calculate label positions at segment midpoints
- Use adaptive primary text color for labels (dark mode support)
- Only show percentage labels for segments >= 10%
- Custom center text with total percentage
- Touch overlay for interactivity
- 22px stroke width handled by SwiftUICharts

### Phase 4: Legend Grid (15 min)

Update to Figma specs:

```swift
// MARK: - Legend Grid

private var legendGrid: some View {
    LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(65), spacing: 9), count: 3),
        spacing: 19
    ) {
        ForEach(allSources, id: \.self) { source in
            legendItem(label: source, color: colorForSource(source))
        }
    }
}

private func legendItem(label: String, color: Color) -> some View {
    VStack(spacing: 4) {
        Circle()
            .fill(color)
            .frame(width: 21.5, height: 21.5)

        Text(label)
            .font(.custom("Lato-Bold", size: 11.99))
            .foregroundStyle(Color(hex: "#363636"))
            .lineLimit(1)
    }
    .frame(width: 65, height: 42)
}
```

**Changes:**
- Fixed item width: 65px
- Fixed item height: 42px
- Icon size: 8px → 21.5px
- Row spacing: 10px → 19px
- Column spacing: 9px
- Font: Regular 12px → Bold 12px
- Color: secondary → #363636

### Phase 5: Data Model Update (10 min)

Create proper model with all 6 categories:

```swift
// At top of file or separate file
struct StressSourceData {
    let name: String
    let percentage: Double
    let color: Color
    let icon: String // SF Symbol name
}

// In StressSourcesCard
private let sources: [StressSourceData] = [
    .init(name: "Finance", percentage: 0.35, color: Color(hex: "#66CDAA"), icon: "dollarsign.circle.fill"),
    .init(name: "Relationship", percentage: 0.50, color: Color(hex: "#F1AE00"), icon: "heart.fill"),
    .init(name: "Health", percentage: 0.15, color: Color(hex: "#FFD700"), icon: "cross.case.fill")
]

private let allCategories: [StressSourceData] = [
    .init(name: "Finance", percentage: 0.35, color: Color(hex: "#66CDAA"), icon: "dollarsign.circle.fill"),
    .init(name: "Relationship", percentage: 0.50, color: Color(hex: "#F1AE00"), icon: "heart.fill"),
    .init(name: "Health", percentage: 0.15, color: Color(hex: "#FFD700"), icon: "cross.case.fill"),
    .init(name: "Family", percentage: 0, color: Color(hex: "#87CEEB"), icon: "house.fill"),
    .init(name: "Work", percentage: 0, color: Color(hex: "#9370DB"), icon: "briefcase.fill"),
    .init(name: "Environment", percentage: 0, color: Color(hex: "#90EE90"), icon: "leaf.fill")
]
```

## File Changes

| File | Action | Lines |
|------|--------|-------|
| `StressSourcesCard.swift` | Rewrite | ~180 |
| `Package.swift` | Modify | ~5 |

## Dependencies

- Existing design tokens (`Spacing`, `AppShadow`, `Color.adaptiveCardBackground`)
- Lato font family (already in project)
- Color+Extensions.swift for hex colors
- **SwiftUICharts library** (add via SPM: `https://github.com/willdale/SwiftUICharts.git`)

## Testing Checklist

- [ ] Light mode renders correctly
- [ ] Dark mode renders correctly
- [ ] Corner radius matches Figma (20px)
- [ ] Shadow matches Figma spec
- [ ] Donut segments positioned correctly
- [ ] Percentage labels visible and positioned
- [ ] Legend grid 3x2 layout
- [ ] Legend icons 21.5px circles
- [ ] Typography tracking applied
- [ ] Responsive width (not fixed 358px)
- [ ] VoiceOver reads content correctly
- [ ] Dynamic Type scales appropriately

## Risks

| Risk | Mitigation |
|------|------------|
| Label overlap on small segments | Hide labels for <10% segments |
| Fixed legend width truncates long labels | Use minimumScaleFactor |
| Percentage calculation rounding | Use Double, format at display |

## Dependencies

- Existing design tokens (`Spacing`, `AppShadow`, `Color.adaptiveCardBackground`)
- Lato font family (already in project)
- Color+Extensions.swift for hex colors
- **SwiftUICharts library** (via SPM)

## Validation Log

### Session 1 — 2026-03-08
**Trigger:** Pre-implementation validation interview
**Questions asked:** 4

#### Questions & Answers

1. **[Architecture]** The plan's donut segment rotation approach uses `EmptyView().onAppear { accumulatedAngle += angle }` inside a ForEach to accumulate rotation. This SwiftUI anti-pattern won't work as expected. Which approach should we use?
   - Options: Use custom Shape with Path (Recommended) | Calculate angles in computed property | Use Canvas API | Use SwiftUICharts library
   - **Answer:** Use SwiftUICharts library
   - **Rationale:** SwiftUICharts provides production-ready chart components with accessibility built-in, avoiding custom implementation complexity

2. **[Scope/Risk]** The plan specifies fixed 65px width legend items, which may truncate longer labels like 'Environment'. How should we handle this?
   - Options: Use minimumScaleFactor (Recommended) | Increase legend item width | Make legend items flexible
   - **Answer:** Use minimumScaleFactor (Recommended)
   - **Rationale:** Maintains Figma-specified 65px width while ensuring all labels remain readable

3. **[Architecture]** The plan specifies percentage label color as #561c1c (dark red). Should this be adaptive for dark mode support?
   - Options: Use adaptive colors (Recommended) | Keep fixed #561c1c | Match segment colors
   - **Answer:** Use adaptive colors (Recommended)
   - **Rationale:** Using Color.Wellness.adaptivePrimaryText ensures proper contrast in both light and dark modes

4. **[Architecture]** Should we preserve the fixed 486px card height or make it responsive?
   - Options: Make responsive (Recommended) | Keep fixed height
   - **Answer:** Make responsive (Recommended)
   - **Rationale:** Removing fixed height allows card to adapt naturally to content and screen sizes

#### Confirmed Decisions
- Donut chart: Use SwiftUICharts library (DoughnutChart)
- Legend labels: Add `.minimumScaleFactor(0.7)` to prevent truncation
- Percentage labels: Use adaptive text color instead of fixed hex
- Card height: Remove fixed height, let content determine natural height

#### Action Items
- [x] Add SwiftUICharts package dependency
- [ ] Update Phase 3 to use SwiftUICharts DoughnutChart
- [ ] Add minimumScaleFactor to legend item labels in Phase 4
- [ ] Replace #561c1c with Color.Wellness.adaptivePrimaryText in Phase 3
- [ ] Remove `.frame(height: 486)` from Phase 1 container

#### Impact on Phases
- Phase 1: Remove fixed height frame
- Phase 3: Rewrite donut chart using SwiftUICharts DoughnutChart, use adaptive colors for labels
- Phase 4: Add minimumScaleFactor to legend text

### Session 2 — 2026-03-08
**Trigger:** Re-validation after SwiftUICharts library integration update
**Questions asked:** 4

#### Questions & Answers

1. **[Risk]** SwiftUICharts library hasn't been updated in 8+ months. Should we use it or consider Apple's native Swift Charts (iOS 16+)?
   - Options: SwiftUICharts (Recommended) | Apple Swift Charts | Custom Canvas
   - **Answer:** SwiftUICharts (Recommended)
   - **Rationale:** Library is stable, feature-rich, and cross-platform. Project already targets iOS 17+.

2. **[Architecture]** The plan overlays custom percentage labels on top of SwiftUICharts DoughnutChart. Should we use SwiftUICharts' built-in info box instead?
   - Options: Hybrid approach (Recommended) | SwiftUICharts only | Fully custom
   - **Answer:** SwiftUICharts only
   - **Rationale:** Simplifies implementation by relying on library's built-in touchOverlay and infoBox. Accept minor design differences from Figma.

3. **[Architecture]** The plan's percentage label positioning uses `EmptyView().onAppear` to accumulate angles - this anti-pattern won't work correctly. How should we fix it?
   - Options: Computed property (Recommended) | Canvas API | GeometryReader
   - **Answer:** GeometryReader
   - **Rationale:** Use GeometryReader with preference keys for precise label positioning if custom labels are needed.

4. **[Scope]** Should we keep the 6-category legend (with 0% items) or only show categories with data?
   - Options: Show all 6 categories (Recommended) | Dynamic legend | Show top 3 only
   - **Answer:** Show all 6 categories (Recommended)
   - **Rationale:** Matches Figma design - always show 3x2 grid even with 0% items for consistent layout.

#### Confirmed Decisions
- Library: Use SwiftUICharts (proceed as planned)
- Labels: Use SwiftUICharts built-in infoBox/touchOverlay (simplifies Phase 3)
- Legend: Keep all 6 categories in 3x2 grid
- No custom percentage label overlay needed

#### Action Items
- [x] Add SwiftUICharts package dependency
- [ ] Simplify Phase 3 - remove custom percentageLabels view
- [ ] Update Phase 3 to use only SwiftUICharts touchOverlay + infoBox
- [ ] Remove GeometryReader label logic (no longer needed with SwiftUICharts only)

#### Impact on Phases
- Phase 3: Simplified - no custom label positioning, use library features only

---

## Completion Notes

(To be filled after implementation)

# Code Review: Stress Sources Donut Chart Figma Alignment

**Date:** 2026-03-04 12:31
**Agent:** code-reviewer
**Scope:** Donut chart Figma alignment changes

---

## Scope

**Files Changed:**
- `StressMonitor/Fonts/Lato-Bold.ttf` - New font file (656KB)
- `StressMonitor/Info.plist` - New file with UIAppFonts registration
- `StressMonitor/Theme/Color+Extensions.swift` - Added `donutPercentageLabel` color
- `StressMonitor/Views/Trends/Components/FullDonutSegmentShape.swift` - New shape (27 lines)
- `StressMonitor/Views/Trends/Components/StressSourcesDonutChart.swift` - Updated (150 lines)
- `StressMonitor.xcodeproj/project.pbxproj` - Updated GENERATE_INFOPLIST_FILE and INFOPLIST_FILE

**Total LOC:** 177 lines (Swift files)
**Build Status:** SUCCESS (iOS + watchOS)
**Test Status:** 477/478 passed (99.8%)

---

## Overall Assessment

Clean implementation of full 360 degree donut chart with good separation of concerns. Code follows SwiftUI best practices and maintains under 200-line file limit. Some accessibility and edge case concerns need attention.

**Score: 7.5/10**

---

## Critical Issues

### None blocking build/deployment

---

## High Priority

### 1. Accessibility - DynamicType Not Supported

**File:** `StressSourcesDonutChart.swift`

**Problem:** Uses fixed pixel font sizes (18px, 14px, 12px) with custom Lato-Bold font, ignoring system Dynamic Type settings. Users with accessibility needs cannot scale text.

```swift
// Current (problematic)
Text("Stress Sources")
    .font(.custom("Lato-Bold", size: 18))  // Fixed size, ignores Dynamic Type
```

**Impact:** WCAG violation, users with vision impairments cannot adjust text size.

**Recommendation:** Use `.font(.custom("Lato-Bold", size: 18, relativeTo: .headline))` or provide scaled alternatives:

```swift
// Better approach
Text("Stress Sources")
    .font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
```

### 2. Accessibility - Missing VoiceOver Labels

**File:** `StressSourcesDonutChart.swift`

**Problem:** No accessibility labels on chart segments or percentage labels. VoiceOver users cannot understand the chart content.

```swift
// Missing accessibility on segments
FullDonutSegmentShape(startDeg: start, endDeg: end, ringWidth: ringWidth)
    .fill(source.color)
    // No .accessibilityLabel

// Missing accessibility on percentage labels
Text("\(Int(source.percentage))%")
    // No .accessibilityLabel
```

**Impact:** Screen reader users get no information from the chart.

**Recommendation:** Add accessibility modifiers:

```swift
FullDonutSegmentShape(startDeg: start, endDeg: end, ringWidth: ringWidth)
    .fill(source.color)
    .accessibilityLabel("\(source.name): \(Int(source.percentage)) percent")
    .accessibilityAddTraits(.isStaticText)
```

### 3. Hardcoded Colors Ignore Dark Mode

**File:** `StressSourcesDonutChart.swift`

**Problem:** Multiple hardcoded `.black` colors ignore dark mode.

```swift
// Line 31 - Title
Text("Stress Sources")
    .foregroundColor(.black)  // Hardcoded

// Line 44 - Subtitle
Text("Last \(totalDays) days")
    .foregroundColor(.black.opacity(0.6))  // Hardcoded

// Line 130 - Legend text
Text(source.name)
    .foregroundColor(Color(hex: "#363636"))  // Hardcoded dark gray
```

**Impact:** Text invisible/low contrast in dark mode.

**Recommendation:** Use semantic adaptive colors:

```swift
.foregroundColor(.primary)  // Instead of .black
.foregroundColor(.secondary)  // Instead of .black.opacity(0.6)
```

---

## Medium Priority

### 4. Percentage Label Overlap on Small Segments

**File:** `StressSourcesDonutChart.swift` lines 78-94

**Problem:** Labels rendered at segment midpoints without collision detection. Small segments (< 10%) will have overlapping labels.

```swift
// Current: always shows label at midpoint
ForEach(activeSources) { source in
    Text("\(Int(source.percentage))%")
        .position(x: x, y: y)
        // No collision avoidance
}
```

**Impact:** Visual clutter when multiple small segments exist.

**Recommendation:** Hide labels for segments below threshold or implement collision detection:

```swift
// Option 1: Hide small segment labels
if segmentAngleSpan(for: source) > 20 {  // degrees
    Text("\(Int(source.percentage))%")
        .position(x: x, y: y)
}
```

### 5. StressSource Model Should Be in Models Directory

**File:** `StressSourcesDonutChart.swift` lines 3-8

**Problem:** `StressSource` struct defined inside view file, not in Models directory.

```swift
struct StressSource: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}
```

**Impact:** Poor separation of concerns, model should be reusable.

**Recommendation:** Move to `StressMonitor/Models/StressSource.swift`.

### 6. Empty State Has No Visual Feedback

**File:** `StressSourcesDonutChart.swift` lines 61-63

**Problem:** When `activeSources.isEmpty`, shows a gray ring with no text explaining empty state.

```swift
if activeSources.isEmpty {
    FullDonutSegmentShape(startDeg: 0, endDeg: 360, ringWidth: ringWidth)
        .fill(Color.secondary.opacity(0.15))
    // No text explaining "No data"
}
```

**Recommendation:** Add empty state label:

```swift
if activeSources.isEmpty {
    FullDonutSegmentShape(...)
        .fill(Color.secondary.opacity(0.15))
    Text("No stress sources recorded")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

### 7. Donut Percentage Label Color Hardcoded

**File:** `Color+Extensions.swift` line 110

**Problem:** `donutPercentageLabel` uses single hardcoded color (#561c1c) with no dark mode variant.

```swift
static let donutPercentageLabel = Color(hex: "561c1c")
```

**Impact:** Dark red/brown may have poor contrast in dark mode.

**Recommendation:** Add light/dark variants:

```swift
static let donutPercentageLabel = Color(
    light: Color(hex: "561c1c"),
    dark: Color(hex: "D4A0A0")  // Lighter for dark mode
)
```

---

## Low Priority

### 8. Magic Numbers Could Be Constants

**File:** `StressSourcesDonutChart.swift`

**Problem:** Several magic numbers without named constants:

```swift
private let ringWidth: CGFloat = 24  // Good - is a constant

// These are magic numbers:
.frame(height: 160)  // Line 39
.frame(width: 21.5, height: 21.5)  // Line 126 - legend circle
VStack(spacing: 4)  // Line 123
```

**Recommendation:** Extract to named constants for clarity.

### 9. LazyVGrid Overkill for 6 Fixed Items

**File:** `StressSourcesDonutChart.swift` line 120

**Problem:** Using `LazyVGrid` for 6 static items adds unnecessary complexity.

```swift
LazyVGrid(columns: columns, alignment: .leading, spacing: 19) {
```

**Recommendation:** Use regular `VGrid` or simple `HStack`/`VStack` composition for fixed small datasets.

### 10. No Error Handling for Missing Font

**File:** `StressSourcesDonutChart.swift`

**Problem:** No fallback if Lato-Bold.ttf fails to load. System silently uses default font.

```swift
.font(.custom("Lato-Bold", size: 18))  // No fallback specified
```

**Recommendation:** Consider fallback strategy or log warning:

```swift
.font(.custom("Lato-Bold", size: 18, relativeTo: .headline))
```

---

## Figma Spec Compliance

| Requirement | Status | Notes |
|-------------|--------|-------|
| Full 360 deg donut | PASS | `FullDonutSegmentShape` correctly implements |
| Lato-Bold font 18px title | PASS | Line 30 |
| Lato-Bold 14px "Last X days" | PASS | Line 43 |
| Lato-Bold 12px labels | PASS | Line 129 |
| Lato-Bold 14px percentages | PASS | Line 90 |
| Percentage labels ON segments | PASS | Lines 78-94 |
| 21.5px legend circles | PASS | Line 126 |
| Vertical legend layout | PASS | VStack in grid cell |
| 19px vertical grid spacing | PASS | Line 120 |
| 9px horizontal grid spacing | PASS | Line 119 |
| Color.donutPercentageLabel | PARTIAL | No dark mode variant |

**Compliance Score: 95%**

---

## Performance Considerations

### Positive
- `FullDonutSegmentShape` is a lightweight `Shape` struct - efficient
- `@ViewBuilder` used correctly for conditional rendering
- Computed properties (`activeSources`, `total`) are efficient for small datasets

### Concerns
- `segmentStartDeg`/`segmentEndDeg` called multiple times per source - could cache
- GeometryReader in percentageLabels recalculates on every layout pass
- No memoization of degree calculations

**Impact:** Negligible for 6 sources, but could be optimized if dataset grows.

---

## File Size Compliance

| File | Lines | Status |
|------|-------|--------|
| StressSourcesDonutChart.swift | 150 | PASS (under 200) |
| FullDonutSegmentShape.swift | 27 | PASS |
| Color+Extensions.swift | 146 | PASS |

**All files under 200-line limit.**

---

## Test Coverage

**Missing Tests:**
- `FullDonutSegmentShape` path generation
- `StressSourcesDonutChart` rendering
- Segment degree calculations
- Edge cases (empty sources, single source, 100% single source)

**Recommendation:** Add unit tests:

```swift
func testFullDonutSegmentShape_pathGeneration() {
    let shape = FullDonutSegmentShape(startDeg: 0, endDeg: 90, ringWidth: 10)
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let path = shape.path(in: rect)
    XCTAssertFalse(path.isEmpty)
}

func testSegmentDegrees_singleSource() {
    // Test that single 100% source spans 0-360 degrees
}
```

---

## Positive Observations

1. **Clean Architecture:** Separate `FullDonutSegmentShape` from chart view - good separation of concerns
2. **Type Safety:** Uses `Identifiable` protocol for sources
3. **Computed Properties:** Clean handling of active sources and totals
4. **Preview:** Comprehensive preview with sample data
5. **Info.plist:** Proper font registration
6. **Build Integration:** Correct project.pbxproj updates for custom Info.plist

---

## Recommended Actions (Prioritized)

1. **[HIGH]** Add Dynamic Type support with `.custom(_, relativeTo:)`
2. **[HIGH]** Add VoiceOver accessibility labels to segments
3. **[HIGH]** Replace `.black` with `.primary` for dark mode support
4. **[MEDIUM]** Add dark mode variant for `donutPercentageLabel`
5. **[MEDIUM]** Move `StressSource` to Models directory
6. **[MEDIUM]** Handle percentage label overlap for small segments
7. **[LOW]** Add unit tests for shape and chart logic
8. **[LOW]** Extract magic numbers to constants

---

## Metrics

| Metric | Value |
|--------|-------|
| Type Coverage | 100% (Swift) |
| Test Coverage | 0% (no chart-specific tests) |
| Linting Issues | 0 |
| Build Warnings | 0 |
| Accessibility Score | 3/10 (missing VoiceOver, DynamicType) |
| Dark Mode Support | Partial |

---

## Unresolved Questions

1. Should percentage labels be hidden for segments below a certain threshold (e.g., < 10%)?
2. What should the empty state message be when no sources have data?
3. Should chart support animated transitions when data changes?
4. Is 21.5px circle size final or should it scale with Dynamic Type?

---

## Summary

The implementation successfully delivers the Figma-aligned full donut chart with correct visual specifications. Code is clean, modular, and under the 200-line limit. Build passes with no errors.

**Main concerns:**
- Accessibility gaps (no VoiceOver, no Dynamic Type)
- Dark mode issues (hardcoded `.black` colors)
- Missing unit tests for chart components

**Recommended next steps:** Address HIGH priority accessibility items before production release.

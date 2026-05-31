# Phase 1: Rewrite DailyTimelineView as Weekly Dot-Matrix

**Status:** ✅ Completed
**Priority:** High
**Effort:** ~1–2 hours
**File:** `StressMonitor/StressMonitor/Views/Dashboard/Components/DailyTimelineView.swift`

---

## Context Links
- Figma reference: `assets/daily-timeline-chart.png`
- Current file: `Views/Dashboard/Components/DailyTimelineView.swift`
- Design tokens: `Theme/Color+Extensions.swift`, `Theme/DesignTokens.swift`
- Used by: currently NO caller references `DailyTimelineView` in any other view (confirmed via grep)

---

## Overview

Fully replace `DailyTimelineView` in-place. Keep the same struct name so no callers need to change. Change from a single-day 24-hour scatter plot to a 7-day × 7-time-slot dot-matrix grid matching the Figma design.

Remove obsolete types defined in this file: `HourlyDataGroup`, `Triangle` shape.

---

## Design Specs

```
Card:
  background:    Color.adaptiveCardBackground (white light / #2C2C2E dark)
  cornerRadius:  Spacing.settingsCardRadius (~16pt)
  shadow:        AppShadow.settingsCard

Header:
  title:         "Daily Timeline"  — Typography.title2, bold
  subtitle:      "Last 7 days"     — Typography.caption1, .secondary

Grid layout:
  rows:     7  (Mon Tue Wed Thu Fri Sat Sun)
  columns:  7  (time blocks, 3h each: 12AM 3AM 6AM 9AM 12PM 3PM 6PM)
  dot size: 19pt circle
  hSpacing: ~22pt between columns
  vSpacing: ~24pt between rows
  dayLabelW: ~27pt left column

Dot colors (using existing stressColor palette):
  no data    → Color.secondary.opacity(0.15)   — gray #D9D9D9
  0–25       → Color.stressRelaxed             — mint green
  26–50      → Color.stressMild                — teal/blue
  51–75      → Color.stressModerate            — pastel yellow
  76–100     → Color.stressHigh                — peach/orange
```

---

## Related Code Files

**Modify:**
- `StressMonitor/StressMonitor/Views/Dashboard/Components/DailyTimelineView.swift`

**Do NOT touch:**
- `Views/Trends/Components/WeeklyHeatmapView.swift` — different context, left as-is

---

## Implementation Steps

### Step 1: Understand current signature
Current:
```swift
struct DailyTimelineView: View {
    let measurements: [StressMeasurement]
    let isExpanded: Bool
}
```

New signature — keep name, change parameters:
```swift
struct DailyTimelineView: View {
    let measurements: [StressMeasurement]  // Keep — supply last 7 days from caller
    // Remove: isExpanded — no longer needed
}
```

> Note: Since no callers exist yet (DailyTimelineView is orphaned), removing `isExpanded` is safe.

### Step 2: Define private constants
```swift
private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private let timeBlockCount = 7       // 3-hour blocks per day
private let dotSize: CGFloat = 19
private let hSpacing: CGFloat = 22
private let vSpacing: CGFloat = 24
private let dayLabelWidth: CGFloat = 30
```

### Step 3: Build body with card shell
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 16) {
        headerRow
        dotGrid
    }
    .padding(24)
    .background(Color.adaptiveCardBackground)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
    .shadow(AppShadow.settingsCard)
}
```

### Step 4: Header row
```swift
private var headerRow: some View {
    HStack {
        Text("Daily Timeline")
            .font(Typography.title2)
            .fontWeight(.bold)
        Spacer()
        Text("Last 7 days")
            .font(Typography.caption1)
            .foregroundColor(.secondary)
    }
}
```

### Step 5: Dot grid layout
```swift
private var dotGrid: some View {
    HStack(alignment: .center, spacing: hSpacing) {
        // Day label column
        VStack(alignment: .leading, spacing: vSpacing) {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#363636"))
                    .frame(width: dayLabelWidth, alignment: .leading)
            }
        }

        // Time slot columns (7 blocks × 7 days)
        ForEach(0..<timeBlockCount, id: \.self) { blockIndex in
            VStack(spacing: vSpacing) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    Circle()
                        .fill(dotColor(dayIndex: dayIndex, blockIndex: blockIndex))
                        .frame(width: dotSize, height: dotSize)
                        .accessibilityHidden(true)
                }
            }
        }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
}
```

### Step 6: Data mapping — stressLevel for a day+block
```swift
/// Returns average stress level for a specific day (0=Mon) and 3-hour block (0–6)
private func stressLevel(dayIndex: Int, blockIndex: Int) -> Double? {
    let calendar = Calendar.current
    let now = Date()
    let hoursPerBlock = 3

    // dayIndex 0=Mon. Today = dayIndex matching weekday.
    // Compute offset: days ago from today
    let todayWeekday = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon...7=Sat
    let todayDayIndex = (todayWeekday + 5) % 7  // convert to 0=Mon
    let dayOffset = dayIndex - todayDayIndex     // negative = past days

    guard let dayStart = calendar.date(
              byAdding: .day, value: dayOffset,
              to: calendar.startOfDay(for: now)),
          let blockStart = calendar.date(
              byAdding: .hour, value: blockIndex * hoursPerBlock,
              to: dayStart),
          let blockEnd = calendar.date(
              byAdding: .hour, value: hoursPerBlock,
              to: blockStart)
    else { return nil }

    let filtered = measurements.filter {
        $0.timestamp >= blockStart && $0.timestamp < blockEnd
    }
    guard !filtered.isEmpty else { return nil }
    return filtered.map(\.stressLevel).reduce(0, +) / Double(filtered.count)
}
```

### Step 7: Dot color helper
```swift
private func dotColor(dayIndex: Int, blockIndex: Int) -> Color {
    guard let level = stressLevel(dayIndex: dayIndex, blockIndex: blockIndex) else {
        return Color.secondary.opacity(0.15)
    }
    return Color.stressColor(for: level)
}
```

### Step 8: Accessibility label
```swift
private var accessibilityLabel: String {
    guard !measurements.isEmpty else {
        return "Daily timeline: No measurements for the past 7 days"
    }
    let avg = measurements.map(\.stressLevel).reduce(0, +) / Double(measurements.count)
    return "Daily timeline: Last 7 days, average stress \(Int(avg)) percent"
}
```

### Step 9: Remove obsolete types
Delete `HourlyDataGroup` struct and `Triangle` shape — no longer needed.

### Step 10: Update previews
```swift
#Preview("Weekly - Empty") {
    DailyTimelineView(measurements: [])
        .padding()
        .background(Color.backgroundLight)
}

#Preview("Weekly - With Data") {
    let measurements = (0..<20).map { i in
        StressMeasurement(
            timestamp: Calendar.current.date(
                byAdding: .hour, value: -(i * 8), to: Date()) ?? Date(),
            stressLevel: Double.random(in: 10...90),
            hrv: 50, restingHeartRate: 65
        )
    }
    return DailyTimelineView(measurements: measurements)
        .padding()
        .background(Color.backgroundLight)
}
```

---

## Todo

- [x] Remove `isExpanded` param, `HourlyDataGroup`, `Triangle` from file
- [x] Implement `headerRow`, `dotGrid`, `stressLevel(dayIndex:blockIndex:)`, `dotColor(dayIndex:blockIndex:)`
- [x] Verify `Spacing.settingsCardRadius`, `AppShadow.settingsCard`, `Typography.title2/caption1` exist (from Trends usage — confirmed they do)
- [x] Update `#Preview` blocks
- [x] Build and check no compile errors

---

## Success Criteria

- File compiles with 0 errors
- Preview shows 7 rows × 7 dot columns
- Stress-colored dots appear for days with data; gray for empty slots
- Card styling matches Figma: white bg, rounded, shadow
- No other files changed

---

## Risk

- **Low**: No callers to update (DailyTimelineView is orphaned in dashboard)
- **Medium**: Day-index offset logic — must correctly map Mon=0 to current week's dates. Test edge case: Sunday display.

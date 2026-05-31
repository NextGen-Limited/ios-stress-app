# Horizontal Week Calendar - Trends Integration Plan

## Overview
- **Type**: UI Component + Feature Integration
- **Priority**: Medium
- **Status**: Complete
- **Effort**: 3 phases

## Context
Add horizontal scrollable week calendar to Trends screen for date selection. Matches Figma design: 7-day horizontal strip with day abbreviations, date numbers, selection state (blue circle), "Today" label, and dot indicators.

## Dependencies
- None (new component)

---

## Phase 1: Horizontal Week Calendar Component

### Overview
- **Priority**: P0
- **Status**: Complete

### Requirements
- 7-day horizontal scroll showing Sun-Sat
- Each day shows: day abbreviation, date number
- Selected state: blue circle background (#007AFF), white bold text
- "Today" label below selected date
- Dot indicator below each date (blue on selected, gray otherwise)
- Horizontal scroll for navigating weeks
- Week offset capability (previous/next week)

### Architecture
- New file: `StressMonitor/StressMonitor/Views/Trends/Components/HorizontalWeekCalendarView.swift`
- Use `@Observable` for state management
- Accept `selectedDate` binding and `onDateSelected` callback

### Implementation Steps
1. Create `HorizontalWeekCalendarView` struct
2. Generate 7 days based on week start date
3. Implement selection state with blue circle
4. Add "Today" label logic
5. Add dot indicators
6. Add horizontal scrolling gesture support

---

## Phase 2: TrendsViewModel Integration

### Overview
- **Priority**: P0
- **Status**: Complete

### Requirements
- Add `selectedDate: Date` property to TrendsViewModel
- Add computed property for week dates
- Add navigation methods (previousWeek, nextWeek)
- Reload data when date changes

### Architecture
- Modify: `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift`

### Implementation Steps
1. Add `selectedDate` state (defaults to today)
2. Add `weekStartDate` computed property
3. Add navigation functions
4. Update data loading to filter by selected week

---

## Phase 3: TrendsView Integration

### Overview
- **Priority**: P0
- **Status**: Complete

### Requirements
- Place calendar at top of Trends scroll view
- Show "This Week" header above calendar
- Chart data reflects selected week

### Architecture
- Modify: `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift`

### Implementation Steps
1. Import HorizontalWeekCalendarView
2. Add calendar below PremiumBanner, above MascotSpeechBubble
3. Bind selectedDate to viewModel
4. Test navigation between weeks

---

## Success Criteria
- [x] Calendar displays 7 days starting from Sunday
- [x] Selection highlights with blue circle and white text
- [x] "Today" label appears on current date
- [x] Horizontal scroll works for week navigation
- [x] Charts update when different week is selected
- [x] No build errors

## Risk Assessment
- **Low**: Standard SwiftUI component, no complex dependencies

## Next Steps
None - implementation complete

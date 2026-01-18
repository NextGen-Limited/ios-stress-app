# Complete UI Implementation Plan - Master Index

> **Created by:** Phuong Doan
> **Version:** 1.0
> **Last Updated:** 2025-01-18
> **Total Screens:** 35 designs across 8 feature areas

---

## Overview

This master index organizes all UI implementation plans for the StressMonitor iOS app. Each feature is documented in its own dedicated markdown file for easier navigation and maintenance.

---

## Document Structure

```
documentation/plans/
├── README.md (this file)
├── 00-design-system-components.md
├── 01-onboarding-flow.md
├── 02-dashboard.md
├── 03-history-trends.md
├── 04-breathing-exercises.md
├── 05-settings-configuration.md
├── 06-measurement-details.md
├── 07-home-screen-widgets.md
└── 08-error-states.md
```

---

## Quick Reference

| File | Feature Area | Screens | Key Components |
|------|-------------|---------|----------------|
| [00-design-system-components.md](./00-design-system-components.md) | Foundation | - | Colors, Typography, Components |
| [01-onboarding-flow.md](./01-onboarding-flow.md) | Onboarding | 13 | Welcome, Health Sync, Baseline, Success |
| [02-dashboard.md](./02-dashboard.md) | Dashboard | 3 | Stress Ring, Metrics, Weekly Summary |
| [03-history-trends.md](./03-history-trends.md) | History | 5 | Charts, Distribution, List View |
| [04-breathing-exercises.md](./04-breathing-exercises.md) | Breathing | 4 | Animated Orb, Session Summary |
| [05-settings-configuration.md](./05-settings-configuration.md) | Settings | 3 | Toggles, Profile, Data Management |
| [06-measurement-details.md](./06-measurement-details.md) | Details | 3 | Gauge, Factors, Recommendations |
| [07-home-screen-widgets.md](./07-home-screen-widgets.md) | Widgets | 2 | Small + Medium Widgets |
| [08-error-states.md](./08-error-states.md) | Errors | 1 | Permission, Empty, Network Errors |

---

## Feature Details

### 1. Design System & Components

**File:** `00-design-system-components.md`

Defines the visual foundation used across all screens:
- **Color Palette:** Stress level colors (green → red), backgrounds, semantic colors
- **Typography:** iOS-style font scales from 11pt to 48pt
- **Spacing:** Consistent spacing scale (4, 8, 16, 24, 32, 48px)
- **Components:** Reusable views (StressRing, MetricCard, SegmentedControl, etc.)

**Key Deliverables:**
- ✅ Color extensions with hex support
- ✅ Typography enum for consistent font usage
- ✅ StressRingView - animated circular progress
- ✅ MetricCard - stat display with optional sparkline
- ✅ SegmentedControl - time/theme picker
- ✅ BreathingOrbView - animated breathing visual
- ✅ SettingsToggleRow - iOS-style toggle row

---

### 2. Onboarding Flow

**File:** `01-onboarding-flow.md`

**Screens (13 total):**
1. Welcome Step 1 - Feature highlights
2. Welcome Step 2 - Progress tracking intro
3. Health Sync Permission (2 screens) - HealthKit request
4-10. Baseline Calibration (7 screens) - Day-by-day progress
11. Success Completion - Confetti + next actions

**Key Deliverables:**
- ✅ WelcomeStep1View, WelcomeStep2View
- ✅ HealthSyncPermissionView with permission handling
- ✅ BaselineCalibrationView with 7-day timeline
- ✅ CalibrationDayView for daily check-ins
- ✅ OnboardingSuccessView with confetti animation
- ✅ ProgressDots component for step indicator

---

### 3. Dashboard

**File:** `02-dashboard.md`

**Screens (3 total):**
1. Dashboard Dark Mode - Main dashboard with stress ring
2. Stress Dashboard Today 1 - With AI insights
3. Stress Dashboard Today 2 - Alternative layout

**Key Deliverables:**
- ✅ DashboardView with live data
- ✅ DashboardViewModel for state management
- ✅ StressRingCard - hero component
- ✅ MetricCard grid for HRV/Resting HR
- ✅ WeeklySummaryCard navigation
- ✅ AIInsightCard with sparkline
- ✅ MeasureNowButton component
- ✅ DashboardStateView for loading/error states

---

### 4. History & Trends

**File:** `03-history-trends.md`

**Screens (5 total):**
1. History and Patterns 1 - Main history with charts
2. History and Patterns 2 - Alternative view
3. Trends View Dark Mode
4. Long-term Stress Trends
5. Measurement History List

**Key Deliverables:**
- ✅ HistoryView with time range selector
- ✅ HistoryViewModel for data management
- ✅ HRVLineChart - interactive chart
- ✅ StressDistributionCard - category breakdown
- ✅ MeasurementHistoryListView - grouped by date
- ✅ LongTermTrendsView - extended period analysis
- ✅ StatCard component for summary stats

---

### 5. Breathing Exercises

**File:** `04-breathing-exercises.md`

**Screens (4 total):**
1. Breathing Session Dark Mode
2. Breathing Session Light Mode
3. Breathing Summary Dark Mode
4. Breathing Summary Light Mode

**Key Deliverables:**
- ✅ BreathingSessionView with animated orb
- ✅ BreathingSessionViewModel for phase management
- ✅ BreathingOrbView - 4-4-4-4 breathing pattern
- ✅ BreathingSummaryView with HRV improvement
- ✅ BreathingDurationPicker component
- ✅ BreathingPatternSelector for pattern options

---

### 6. Settings & Configuration

**File:** `05-settings-configuration.md`

**Screens (3 total):**
1. App Settings - Main settings list
2. App Configuration Settings 1
3. App Configuration Settings 2

**Key Deliverables:**
- ✅ SettingsView with grouped sections
- ✅ AppSettings model for preferences
- ✅ ProfileSettingsView for user info
- ✅ HealthAccessSettingsView for permissions
- ✅ ReminderSettingsView with date picker
- ✅ ExportDataView for CSV export
- ✅ SettingsToggleRow, SettingsNavigationRow components

---

### 7. Measurement Details

**File:** `06-measurement-details.md`

**Screens (3 total):**
1. Measurement Details View 1 - Detail breakdown
2. Measurement Details View 2 - Comparison view
3. Single Measurement Detail

**Key Deliverables:**
- ✅ MeasurementDetailView with full analysis
- ✅ MeasurementComparisonView - before/after
- ✅ HRVRangeVisualizer - baseline comparison
- ✅ FactorRow - contributing factors
- ✅ RecommendationRow - actionable insights
- ✅ ComparisonMetric component

---

### 8. Home Screen Widgets

**File:** `07-home-screen-widgets.md`

**Screens (2 total):**
1. Home Screen Widgets Dark
2. Home Screen Widgets Light

**Key Deliverables:**
- ✅ Small widget (16x16) - stress ring + score
- ✅ Medium widget (32x16) - stress + HRV chart
- ✅ StressMonitorWidget with timeline provider
- ✅ HRVSparkline for widget charts
- ✅ App Groups configuration
- ✅ Widget deep linking

---

### 9. Error States

**File:** `08-error-states.md`

**Screens (1 total):**
1. HealthKit Access Error State

**Key Deliverables:**
- ✅ HealthKitAccessErrorView
- ✅ GenericErrorView for common errors
- ✅ EmptyStateView for no data
- ✅ LoadingStateView for loading states
- ✅ NetworkErrorView for connection issues
- ✅ ErrorViewModifier for easy integration

---

## Implementation Order

### Phase 1: Foundation (Week 1-2)
1. ✅ Design tokens and theme setup
2. ✅ Base component library
3. ✅ Data models and repositories
4. ✅ Navigation structure

### Phase 2: Core Features (Week 3-4)
1. ✅ Onboarding flow (all 13 screens)
2. ✅ Dashboard view
3. ✅ Settings screens
4. ✅ Error states

### Phase 3: Advanced Features (Week 5-6)
1. ✅ History and trends views
2. ✅ Measurement details
3. ✅ Breathing exercises
4. ✅ Home screen widgets

### Phase 4: Polish (Week 7-8)
1. ✅ Animations and transitions
2. ✅ Accessibility improvements
3. ✅ Performance optimization
4. ✅ Testing and bug fixes

---

## Design Token Reference

### Colors

| Usage | Light Mode | Dark Mode |
|-------|-----------|-----------|
| Background | `#f6f7f8` | `#000000` |
| Card | `#ffffff` | `#1C1C1E` |
| Primary | `#2b7cee` | `#2b7cee` |
| Text Main | `#111418` | `#FFFFFF` |
| Text Secondary | `#9da8b9` | `#EBEBF5` |

### Stress Level Colors

| Category | Value | Icon |
|----------|-------|------|
| Relaxed (0-25) | `#34C759` | `sparkles` |
| Mild (25-50) | `#007AFF` | `checkmark.circle` |
| Moderate (50-75) | `#FFD60A` | `exclamationmark.triangle` |
| High (75-90) | `#FF9500` | `exclamationmark.octagon.fill` |
| Severe (90-100) | `FF3B30` | `exclamationmark.octagon.fill` |

### Typography

| Usage | Font | Size | Weight |
|-------|------|------|--------|
| Large Title | System | 34pt | Bold |
| Title 1 | System | 28pt | Bold |
| Title 2 | System | 22pt | Bold |
| Body | System | 17pt | Regular |
| Caption 1 | System | 12pt | Regular |
| Caption 2 | System | 11pt | Regular |

### Spacing

| Name | Value |
|------|-------|
| XS | 4px |
| SM | 8px |
| MD | 16px |
| LG | 24px |
| XL | 32px |
| XXL | 48px |

---

## Component Library Index

| Component | Used In | File |
|-----------|---------|------|
| StressRingView | Dashboard, Widgets | 00-design-system-components.md |
| MetricCard | Dashboard, History | 00-design-system-components.md |
| SegmentedControl | History, Settings | 00-design-system-components.md |
| BreathingOrbView | Breathing | 00-design-system-components.md |
| SettingsToggleRow | Settings | 00-design-system-components.md |
| ProgressDots | Onboarding | 00-design-system-components.md |
| HRVLineChart | History | 03-history-trends.md |
| MeasurementListItem | History | 03-history-trends.md |
| BreathingDurationPicker | Breathing | 04-breathing-exercises.md |
| HRVRangeVisualizer | Details | 06-measurement-details.md |
| HRVSparkline | Widgets | 07-home-screen-widgets.md |

---

## Dependencies

### Frameworks
- **SwiftUI** - iOS 17+
- **SwiftData** - Data persistence
- **HealthKit** - Health data access
- **WidgetKit** - Home screen widgets
- **AppIntents** - Widget interactivity (iOS 16+)

### Internal Dependencies
- All views depend on `00-design-system-components.md`
- All screens use common data models (`StressMeasurement`, `StressCategory`)
- Widget sharing via App Groups

---

## File Structure Summary

```
StressMonitor/
├── Theme/
│   ├── Color+Extensions.swift
│   ├── DesignTokens.swift
│   ├── Typography.swift
│   └── Spacing.swift
├── Views/
│   ├── Components/
│   │   ├── StressRingView.swift
│   │   ├── MetricCard.swift
│   │   ├── SegmentedControl.swift
│   │   ├── BreathingOrbView.swift
│   │   ├── SettingsRow.swift
│   │   └── ProgressDots.swift
│   ├── Onboarding/
│   │   ├── WelcomeStep1View.swift
│   │   ├── WelcomeStep2View.swift
│   │   ├── HealthSyncPermissionView.swift
│   │   ├── BaselineCalibrationView.swift
│   │   ├── CalibrationDayView.swift
│   │   └── OnboardingSuccessView.swift
│   ├── DashboardView.swift
│   ├── HistoryView.swift
│   ├── BreathingSessionView.swift
│   ├── BreathingSummaryView.swift
│   ├── SettingsView.swift
│   ├── MeasurementDetailView.swift
│   └── ErrorStates/
│       ├── HealthKitAccessErrorView.swift
│       ├── EmptyStateView.swift
│       └── LoadingStateView.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── HistoryViewModel.swift
│   └── BreathingSessionViewModel.swift
└── Models/
    ├── StressMeasurement.swift
    └── StressCategory.swift
```

---

## Testing Requirements

### UI Tests
- Verify all screens render correctly in both light and dark modes
- Test navigation flows between all screens
- Validate accessibility labels and traits
- Test Dynamic Type scaling

### Component Tests
- StressRingView renders correctly with different values
- BreathingOrbView animation timing
- MetricCard with various data states
- Charts render with edge cases

### Integration Tests
- Complete onboarding flow
- Measurement creation and display
- Settings persistence
- Widget data updates

---

## WCAG Compliance

All UI implementations follow WCAG 2.1 AA standards:
- **Dual coding:** Stress levels use color + icons/text
- **Contrast ratios:** All text meets 4.5:1 minimum
- **Touch targets:** Minimum 44x44pt
- **Reduced Motion:** Respects accessibility setting
- **Dynamic Type:** Supports Extra Small to XXXL

---

## Navigation Map

```
MainTabView
├── Dashboard
│   └── MeasurementDetailView
├── History
│   └── MeasurementDetailView
├── Meditate (Breathing)
│   └── BreathingSummaryView
└── Settings
    ├── ProfileSettingsView
    ├── ReminderSettingsView
    ├── HealthAccessSettingsView
    └── ExportDataView

OnboardingFlow
├── WelcomeStep1View
├── WelcomeStep2View
├── HealthSyncPermissionView
├── BaselineCalibrationView
│   └── CalibrationDayView (x7)
└── OnboardingSuccessView
    └── MainTabView
```

---

## Notes

- All colors support WCAG AA accessibility standards
- Use SF Symbols for icons, fallback to Material Symbols when needed
- All animations should respect Reduce Motion setting
- Support Dynamic Type from Extra Small to XXXL
- Haptic feedback for key interactions (measurements, milestones)

---

**Generated:** 2025-01-18
**Author:** Phuong Doan

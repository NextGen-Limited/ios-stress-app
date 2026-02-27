---
title: "Dashboard UI/UX Enhancement"
description: "Transform DashboardView into unified scroll with all components, auto-refresh, and OLED dark theme"
status: completed
priority: P2
effort: 4h
branch: main
tags: [ios, swiftui, dashboard, ui-enhancement, auto-refresh]
created: 2026-02-23
completed: 2026-02-23
---

# Dashboard UI/UX Enhancement

## Overview

Transform current basic DashboardView into a comprehensive health dashboard with:
- Unified scroll layout with all metrics components
- Hero stress ring (260pt) with spring animations
- Auto-refresh via HealthKit observer (replaces manual Measure button)
- OLED Dark visual consistency

**Brainstorm Report:** [brainstorm-0223-2217-dashboard-ui-enhancement.md](../reports/brainstorm-0223-2217-dashboard-ui-enhancement.md)

---

## Phases

| Phase | Name | Status | Progress | Effort |
|-------|------|--------|----------|--------|
| [01](./phase-01-layout-components.md) | Layout + Component Integration | completed | 100% | 1.5h |
| [02](./phase-02-auto-refresh.md) | Auto-Refresh Implementation | completed | 100% | 1h |
| [03](./phase-03-animations-haptics.md) | Animations + Haptics | completed | 100% | 1h |
| [04](./phase-04-testing-polish.md) | Testing + Polish | completed | 100% | 0.5h |

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Layout | Unified scroll | Single column, clear hierarchy |
| Ring size | 260pt | Hero element, more visual impact |
| Auto-refresh | HKObserverQuery | System-managed, battery-efficient |
| Debounce | 60 seconds | Conservative, minimal battery impact |
| AI Insights | Local rules | No network required, privacy-first |
| Weekly view | Averages only | Simple comparison, matches existing card |
| Live HR | Latest reading | Update when HealthKit reports, not continuous |

---

## Files to Modify

| File | Changes |
|------|---------|
| `Views/DashboardView.swift` | Main restructuring, integrate all components |
| `Views/Dashboard/Components/StressRingView.swift` | Increase size 220pt → 260pt |
| `ViewModels/StressViewModel.swift` | Add auto-refresh, hrvHistory, weekly data |

## Files to Create

| File | Purpose |
|------|---------|
| `Services/InsightGeneratorService.swift` | Local rules engine for AI insights |

---

## Component Order (Ring-Focused)

1. Greeting Header (time-based)
2. **StressRingView** (260pt hero)
3. **MetricCardView** (HRV + HR side-by-side)
4. **LiveHeartRateCard** (conditional)
5. **DailyTimelineView**
6. **WeeklyInsightCard**
7. **AIInsightCard**

---

## Visual Design

### OLED Dark Palette
- Background: `#121212` (`Color.oledBackground`)
- Card: `#1E1E1E` (`Color.oledCardBackground`)
- Secondary: `#2A2A2A` (`Color.oledCardSecondary`)
- Text Secondary: `#9CA3AF` (`Color.oledTextSecondary`)

### Typography
- Hero: 72pt Bold (stress number)
- Title: 34pt Bold (greeting)
- Headline: 22pt Semibold (card titles)
- Body: 17pt Regular

---

## Success Criteria

- [x] All 6 components visible in unified scroll
- [x] Stress ring at 260pt with spring animation
- [x] Auto-refresh works via HealthKit observer
- [x] Haptic feedback on stress category change
- [x] OLED dark theme consistent
- [x] VoiceOver navigates all components
- [x] 60fps scroll performance

---

## Dependencies

- Existing components (all available in `Views/Dashboard/Components/`)
- `HapticManager` (exists at `Utilities/HapticManager.swift`)
- `Color+Extensions.swift` (OLED colors defined)
- HealthKit observer pattern (new)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Auto-refresh battery drain | 60s debounce, proper HKObserverQuery lifecycle |
| Missing data states | Each component has empty state handling |
| Scroll performance | LazyVStack, cache timeline data |

---

*Created: 2026-02-23*

# Trends View — Figma Alignment Plan

**Date:** 2026-03-02
**Status:** Completed
**Branch:** main
**Design ref:** `assets/Trend.png`

## Summary

Align the Trends view with the Figma design. The current implementation has all major sections (PremiumBanner, StressOverTime, Heatmap, HRV Trend, DonutChart, Insights) but several visual details differ from the Figma mockup.

## Gap Analysis — Figma vs Current

| Section | Figma Design | Current State | Gap |
|---------|-------------|---------------|-----|
| **Premium Banner** | Light blue gradient bg, cat mascot illustration, sparkles, subtitle "Unlimited Access to premium features", orange CTA | Flat `#5DADE2` blue bg, no mascot, crown icon, white text | Major: needs mascot image, gradient bg, layout restructure |
| **Mascot Speech Bubble** | Small cat + speech bubble with conversational text below banner | Missing entirely | New component needed |
| **Stress Over Time** | Bar chart (Mon-Sun) with rounded bars, Y-axis 0-100, dropdown "Last 7 days", color-coded legend | Only circular indicators (no bar chart), has time range picker at top | Major: need actual bar chart replacing circular indicators |
| **Daily Timeline** | Dot-based grid (rows=days, colored circles) | Square heatmap cells, horizontal scroll, hour-based grid | Minor: change squares to circles, simplify layout |
| **HRV Trend** | Line chart with data points, subtitle "Last 30 days", "Today" label | Line chart exists, similar design | Minor: add "Last 30 days" subtitle, Y-axis labels (0/50/100/150), "Today" label |
| **Stress Sources** | Semi-donut chart, percentages on chart, 6-category legend (Finance/Relationship/Health/Family/Work/Environment) | Full donut, side legend, 4 categories | Moderate: change to semi-donut, add all 6 categories, reposition legend |
| **Smart Insights** | "Coming Soon" yellow button, cat mascot peeking, "Personalized analysis based on your rhythm" | Pattern insights with emoji icons | Moderate: replace with teaser card design |
| **Header** | No standalone "Trends" header or time picker | Has "Trends" title + TimeRangePicker | Remove: Figma has no header/picker, filter is per-card dropdown |
| **Card Style** | Beige/off-white cards, rounded corners, subtle shadow | `Color.secondary.opacity(0.1)` bg, no shadow | Minor: use `adaptiveCardBackground` + shadow |

## Phases

| # | Phase | Status | Effort |
|---|-------|--------|--------|
| 1 | [Update card styling & remove header](phase-01-card-styling.md) | Completed | Small |
| 2 | [Redesign PremiumBannerView](phase-02-premium-banner.md) | Completed | Medium |
| 3 | [Add mascot speech bubble](phase-03-mascot-speech-bubble.md) | Completed | Small |
| 4 | [Replace stress indicators with bar chart](phase-04-stress-bar-chart.md) | Completed | Large |
| 5 | [Update heatmap to dot grid](phase-05-heatmap-dots.md) | Completed | Small |
| 6 | [Polish HRV trend card](phase-06-hrv-trend.md) | Completed | Small |
| 7 | [Redesign donut chart to semi-donut](phase-07-semi-donut.md) | Completed | Medium |
| 8 | [Replace insights with Smart Insights teaser](phase-08-smart-insights.md) | Completed | Small |

## Key Decisions

- **Cat mascot images**: Need asset files (premium cat, speech bubble cat, smart insights cat). Since we don't have Figma export access, use SF Symbols placeholder or existing `CharacterCalm`/`CharacterWorried` assets as stand-ins.
- **Bar chart**: Build custom SwiftUI bar chart (no Charts framework needed for this simple case, but iOS 16+ Charts would simplify). Since project targets iOS 17+, use Swift Charts.
- **Card style**: Unify all cards to use `adaptiveCardBackground` + `settingsCardRadius` + shadow, matching Settings screen pattern.
- **Time filter**: Move from global TimeRangePicker to per-card dropdown (Figma shows "Last 7 days" dropdown on individual cards).

## Risk

- Cat mascot assets not available → use existing Character* assets as placeholder
- Swift Charts import adds new framework dependency → acceptable, it's a system framework

## Dependencies

- Existing Character assets: `CharacterCalm`, `CharacterWorried`, `CharacterConcerned`, `CharacterSleeping`, `CharacterOverwhelmed`
- DesignSystem: `Typography`, `Spacing`, `SettingsCard`, `Color+Extensions`

## Validation Log

### Session 1 — 2026-03-02
**Trigger:** Pre-implementation validation
**Questions asked:** 4

#### Questions & Answers

1. **[Scope]** Remove global TimeRangePicker and header entirely?
   - Options: Remove entirely | Keep as functional dropdown | Keep hidden
   - **Answer:** Remove entirely
   - **Rationale:** Figma has no global header; each card shows static time labels

2. **[Architecture]** Swift Charts vs custom SwiftUI Shapes for bar chart?
   - Options: Swift Charts | Custom Shapes
   - **Answer:** Swift Charts
   - **Rationale:** Cleaner code, built-in animations/axes, project targets iOS 17+

3. **[Scope]** Replace dynamic insights with static "Coming Soon" teaser?
   - Options: Follow Figma strictly | Keep below teaser | Skip Phase 8
   - **Answer:** Follow Figma strictly
   - **Rationale:** Dynamic insights not polished enough for current design direction

4. **[Assets]** Mascot illustrations approach?
   - Options: Use Character* assets | Skip mascots | SF Symbols
   - **Answer:** Use Character* assets (CharacterCalm, CharacterConcerned, CharacterSleeping)

#### Confirmed Decisions
- Global header: removed — static per-card labels instead
- Bar chart: Swift Charts — system framework, iOS 17+ safe
- Insights: replaced with teaser — follow Figma strictly
- Mascots: Character* assets as placeholders

## Completion Summary

**Completed:** 2026-03-02 | All 8 phases delivered.

### Phases
All Figma alignment phases implemented. See individual phase files for details.

### Bug Fixes Applied

**Fix A — StressMonitorApp.swift entry point**
- File: `StressMonitor/StressMonitor/StressMonitorApp.swift`
- Removed invalid `NavigationStack` wrapper; changed `MainTabView(modelContext: share)` → `MainTabView()` (uses `@Environment`, no init param)

**Fix B — StressViewModel simulator crash**
- File: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`
- Added `#if targetEnvironment(simulator) return #endif` guard in `startAutoRefresh()` to prevent `HKObserverQuery` from running in simulator builds lacking HealthKit entitlement

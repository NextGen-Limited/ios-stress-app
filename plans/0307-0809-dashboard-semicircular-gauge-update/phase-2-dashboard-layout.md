# Phase 2: Update Dashboard Layout

## Overview
- **Priority:** High
- **Status:** Pending

Update StressDashboardView to use new semicircular gauge and curved bottom design.

## Requirements
- Replace current gauge with SemicircularGaugeView
- Add curved bottom black background with cutout
- Keep existing StressBuddyIllustration character

## Related Code Files
- Modify: `StressMonitor/StressMonitor/Views/Dashboard/StressDashboardView.swift`

## Implementation Steps

### 1. Update StressDashboardView
- Import SemicircularGaugeView
- Replace StressCharacterCard section with SemicircularGaugeView
- Add curved bottom background (black with circular cutout)

### 2. Layout Structure
```
ZStack
├── ScrollView (main content)
│   ├── Header (date + greeting)
│   ├── SemicircularGaugeView (with character inside)
│   ├── QuickStatsRow
│   └── DailyTimelineView
└── CurvedBottomBackground (black, z-index below)
```

### 3. Curved Bottom Design
- Solid black background
- Curved top edge matching reference image
- Creates "cutout" effect framing center content

## Success Criteria
- [ ] SemicircularGaugeView displays correctly
- [ ] Curved bottom background visible
- [ ] StressBuddyIllustration preserved
- [ ] All existing functionality works

## Next Steps
- Phase 3: Build & Verify

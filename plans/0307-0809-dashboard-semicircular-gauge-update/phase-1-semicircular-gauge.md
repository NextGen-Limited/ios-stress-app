# Phase 1: Create SemicircularGaugeView

## Overview
- **Priority:** High
- **Status:** Pending

Create a new semicircular gauge view matching the reference image design.

## Requirements
- Semicircle (180°) arc instead of full circle
- 4 color segments (grey gradient: #8E8E93 → #D1D1D6)
- Character (StressBuddyIllustration) inside the arc
- "No Data" text when empty

## Related Code Files
- Create: `StressMonitor/StressMonitor/Views/Dashboard/Components/SemicircularGaugeView.swift`

## Implementation Steps

### 1. Create SemicircularGaugeView.swift
```swift
struct SemicircularGaugeView: View {
    let stressLevel: Double
    let category: StressCategory
    let mood: StressBuddyMood

    // Semicircle arc (180°)
    // 4 segments with grey gradient
    // Character inside arc
    // "No Data" text below
}
```

### 2. Design Specs
- Arc: 180° semicircle, top half
- Segments: 4 equal parts (45° each)
- Colors: #8E8E93 (dark grey) → #D1D1D6 (light grey)
- Character position: Center inside arc
- Text: "No Data" in red (#FF3B30) when no data

## Success Criteria
- [ ] Semicircular arc renders correctly
- [ ] 4 segments visible with gradient
- [ ] StressBuddyIllustration displays inside
- [ ] "No Data" shows when stressLevel == 0

## Next Steps
- Phase 2: Integrate into StressDashboardView

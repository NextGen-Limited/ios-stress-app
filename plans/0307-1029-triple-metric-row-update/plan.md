# TripleMetricRow UI Update Plan

## Overview
Update TripleMetricRow component to match Figma design specifications.

## Target File
`StressMonitor/StressMonitor/Views/Dashboard/Components/TripleMetricRow.swift`

## Changes Required

### 1. Card Container (MetricColumn)
- Add white background: `Color.white`
- Add shadow: `shadow(color: .black.opacity(0.08), radius: 4.28/2, x: 0, y: 2.85)` + secondary shadow
- Fixed size: 105pt width × 81pt height
- Corner radius: 8.928pt
- Padding: 8.928pt

### 2. Spacing
- Change HStack spacing from 12pt to 21pt

### 3. Font Adjustments
| Element | Current | Figma |
|---------|---------|-------|
| Title | 13pt medium | 14pt bold |
| Value | 20pt semibold | 18pt extraBold |
| Unit | 12pt regular | 13pt bold, 39% opacity |

### 4. Unit Label
- RR unit: change "br/min" to "brpm"

## Implementation Steps

1. Update `MetricColumn` to have fixed frame: `frame(width: 105, height: 81)`
2. Add background + cornerRadius + shadow to MetricColumn
3. Update fonts to match Figma
4. Change spacing to 21pt
5. Update RR unit to "brpm"

## Success Criteria
- [ ] Each metric displays in separate card (105×81pt)
- [ ] White background with shadow
- [ ] 21pt spacing between cards
- [ ] Font sizes match Figma exactly
- [ ] RR shows "brpm" unit
- [ ] HRV keeps "ms" unit

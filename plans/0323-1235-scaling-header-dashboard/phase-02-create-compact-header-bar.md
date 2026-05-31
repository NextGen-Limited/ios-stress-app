# Phase 2: Create Compact Header Bar

## Overview
- **Priority:** P1
- **Status:** Pending
- **Effort:** 1h

Create `CompactStressHeaderBar` — the collapsed state showing date + stress badge.

## Key Insights

- Reuse existing `DateHeaderView` date formatting logic (don't duplicate)
- Reuse existing `StressStatusBadge` for the badge pill
- Height: ~60pt to match ScalingHeaderScrollView `min` height
- Must support dark mode via `Color.Wellness.*` tokens

## Requirements

**Functional:**
- Display current date (e.g., "Monday, Mar 23") on left
- Display stress category badge on right (colored capsule: "Relaxed 32")
- Accept `StressResult` or individual props (date, level, category)

**Non-functional:**
- Accessibility: combined element with proper label
- Dynamic Type support
- Min touch target 44x44pt for any interactive elements

## Architecture

```
CompactStressHeaderBar
├── HStack
│   ├── Text (date string)
│   ├── Spacer
│   └── Capsule badge (category + level)
```

## Related Code Files

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/StressMonitor/Views/Dashboard/Components/CompactStressHeaderBar.swift` | **Create** | New compact bar component |
| `StressMonitor/StressMonitor/Views/Dashboard/Components/DateHeaderView.swift` | Read | Reuse date formatting |
| `StressMonitor/StressMonitor/Views/Dashboard/Components/StressStatusBadge.swift` | Read | Reference for badge style |

## Implementation Steps

1. Create `CompactStressHeaderBar.swift` in `StressMonitor/StressMonitor/Views/Dashboard/Components/`
2. Props: `date: Date`, `stressLevel: Double`, `stressCategory: StressCategory`
3. Layout: HStack with date text (left) and stress badge capsule (right)
4. Badge: colored capsule background matching stress category color, white text
5. Height: fixed 60pt with vertical centering
6. Add convenience init from `StressResult`
7. Add previews for all stress categories + dark mode
8. Build and verify in Xcode previews

## Todo List

- [ ] Create CompactStressHeaderBar.swift
- [ ] Implement date + badge layout
- [ ] Add StressResult convenience init
- [ ] Add accessibility labels
- [ ] Add previews (all categories, dark mode)
- [ ] Verify build

## Success Criteria

- Renders correctly at 60pt height
- All 4 stress categories display with correct colors
- Dark mode works
- VoiceOver reads: "Monday, March 23. Relaxed, stress level 32"

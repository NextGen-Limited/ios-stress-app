# Phase 5: Cleanup and Verify

## Overview
- **Priority:** P2
- **Status:** Pending
- **Effort:** 15m

Delete unused `HomeDashboardView`, verify full integration, build check.

## Requirements

- HomeDashboardView deleted (confirmed no references outside its own previews)
- Clean build passes
- No compiler warnings from new code

## Related Code Files

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/StressMonitor/Views/Dashboard/HomeDashboardView.swift` | **Delete** | Unused Figma prototype |
| `CLAUDE.md` | **Modify** | Update dependencies section (add ScalingHeaderScrollView) |
| `docs/codebase-summary.md` | **Modify** | Add external dependency listing |
| `docs/system-architecture.md` | **Modify** | Document dashboard header architecture |

## Implementation Steps

1. Delete `StressMonitor/StressMonitor/Views/Dashboard/HomeDashboardView.swift`
2. Search codebase for any remaining `HomeDashboardView` references
3. Clean build: verify no compile errors
4. Run existing tests to check for regressions
5. Manual verification checklist (see Success Criteria)

## Todo List

- [ ] Delete HomeDashboardView.swift
- [ ] Verify no remaining references
- [ ] Clean build passes
- [ ] Run tests
- [ ] Update CLAUDE.md dependencies section
- [ ] Update docs/codebase-summary.md
- [ ] Update docs/system-architecture.md
- [ ] Manual UX verification

## Success Criteria

- [ ] Character card visible when at top, collapses smoothly on scroll
- [ ] Compact bar shows date + stress badge when collapsed
- [ ] Snaps to expanded/collapsed after scroll deceleration
- [ ] Tab bar hide-on-scroll still works
- [ ] Dark mode correct for both header states
- [ ] No visual glitches during fast scrolling
- [ ] Clean build, no warnings
- [ ] Tests pass

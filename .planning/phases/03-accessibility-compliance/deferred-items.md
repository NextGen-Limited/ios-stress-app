# Phase 3 Deferred Items (out-of-scope discoveries)

## [2026-09-05, plan 03-05] Unguarded decorative loops outside the plan's consolidation set

Discovered during the 03-05 Task-2 re-baseline. These files contain `repeatForever`
decorative loops with NO reduce-motion branch at all — they were not in the plan's
13-file enumeration (which tracked raw `accessibilityReduceMotion` reads) and are not
named by the plan's must_haves:

| File | Line | Construct |
|------|------|-----------|
| `StressMonitor/StressMonitor/Views/DesignSystem/Components/LoadingView.swift` | ~100 | shimmer-style `withAnimation(.linear.repeatForever)` |
| `StressMonitor/StressMonitor/Views/Dashboard/Components/BioAgeCardView.swift` | ~43 | pulse `withAnimation(.easeInOut(1.5).repeatForever)` |
| `StressMonitor/StressMonitor/Views/Trends/Components/SmartInsightsTeaser.swift` | ~88 | pulse `.animation(.easeInOut(1.2).repeatForever, value:)` |
| `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` | ~541 | decorative `repeatForever` |

The D-13 trust gate greps for raw reduce-motion reads, which these files do not have,
so the gate is clean — but under Reduce Motion these loops keep running until routed
through `animateIfMotionAllowed`/`startMotionIfAllowed`. Several are likely orphan
candidates deleted by plan 03-06 (which re-runs the gate against the post-deletion
tree); any survivors should adopt the helper then.

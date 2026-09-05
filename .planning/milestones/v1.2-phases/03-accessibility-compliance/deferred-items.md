# Phase 3 Deferred Items (out-of-scope discoveries)

## [2026-09-05, plan 03-05] Unguarded decorative loops outside the plan's consolidation set

Discovered during the 03-05 Task-2 re-baseline. These files contained `repeatForever`
decorative loops with NO reduce-motion branch at all — they were not in the plan's
13-file enumeration (which tracked raw `accessibilityReduceMotion` reads) and are not
named by the plan's must_haves. Three of the four were later deleted outright by the
core-tabs/Trends redesign (verified gone at v1.2 close); the one survivor is
acknowledged at v1.2 close and belongs to the motion-family follow-up recorded in
the v1.2 close-out notes (the sibling of IN-05's reverse-direction gap).

The D-13 trust gate greps for raw reduce-motion reads, which these files do not have,
so the gate is clean — but under Reduce Motion an unguarded loop keeps running until
routed through `animateIfMotionAllowed`/`startMotionIfAllowed`.

## Deferred Items

- `StressMonitor/StressMonitor/Views/DesignSystem/Components/LoadingView.swift` (~100) — shimmer-style `withAnimation(.linear.repeatForever)` — file deleted by the core-tabs redesign before v1.2 close
  status: resolved
- `StressMonitor/StressMonitor/Views/Dashboard/Components/BioAgeCardView.swift` (~43) — pulse `withAnimation(.easeInOut(1.5).repeatForever)` — file deleted by the core-tabs redesign before v1.2 close
  status: resolved
- `StressMonitor/StressMonitor/Views/Trends/Components/SmartInsightsTeaser.swift` (~88) — pulse `.animation(.easeInOut(1.2).repeatForever, value:)` — file deleted by the core-tabs redesign before v1.2 close
  status: resolved
- `StressMonitor/StressMonitor/Views/Chat/ChatBottomSheetView.swift` (~541) — decorative `repeatForever(autoreverses: true)` still live at v1.2 close; route through `animateIfMotionAllowed`/`startMotionIfAllowed` with the motion-family follow-up
  status: acknowledged

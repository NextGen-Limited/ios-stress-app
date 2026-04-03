# Validation Report: ScalingHeaderScrollView for Dashboard

**Plan:** `plans/0323-1235-scaling-header-dashboard/plan.md`
**Date:** 2026-03-23
**Status:** Validated with amendments

## Critical Issues Found & Resolved

### 1. Tab Bar Scroll Tracking Gap (CRITICAL)

**Issue:** Phase 4's Option A (collapseProgress-driven) only works during header collapse range (0.0-1.0). Once header fully collapsed, `collapseProgress` stays at 1.0 — continued content scrolling won't trigger tab bar hide/show.

**Decision:** Use Option B — GeometryReader inside content block for independent content offset tracking. This provides full scroll range coverage, not just header collapse range.

**Impact:** Phase 4 needs rewrite. Replace `onChange(of: collapseProgress)` approach with GeometryReader-based offset tracking inside ScalingHeaderScrollView's content closure.

### 2. StressCharacterCard Height Compression (HIGH)

**Issue:** Card uses `Spacer()` elements and returns `nil` for `.dashboard` cardHeight. Inside constrained header (max: 350pt), spacers compress during collapse causing layout jumpiness before crossfade.

**Decision:** Add new `CharacterContext` case (e.g., `.scalingHeader`) or modify `.dashboard` to return fixed height (~340pt) when used inside ScalingHeaderScrollView header.

**Impact:** Phase 3 needs StressCharacterCard modification — not just wrapping in ScalingHeaderScrollView.

### 3. File Paths Incorrect

**Issue:** Plan references `Views/DashboardView.swift` but actual path is `StressMonitor/StressMonitor/Views/DashboardView.swift`. All file paths truncated.

**Decision:** Fix paths in all phase files.

### 4. Zero-Dependency Rule Broken

**Issue:** CLAUDE.md and docs state "Dependencies: None - system frameworks only" but AnimatedTabBar already broke this. ScalingHeaderScrollView adds second external dep undocumented.

**Decision:** Update docs to reflect reality. Add docs update step to Phase 5.

## Minor Issues & Decisions

| Issue | Decision |
|-------|----------|
| Pull-to-refresh optional vs success criteria mismatch | Skip pull-to-refresh entirely. Keep existing refresh button. |
| SPM version not pinned | Use `branch: main`. Small project, acceptable risk. |
| Docs update scope | Add docs update task to Phase 5 (CLAUDE.md, codebase-summary, system-architecture). |

## Plan Amendments Required

### Phase 3 — Add StressCharacterCard height fix
- Add step: create `.scalingHeader` context case or set fixed height for `.dashboard`
- Remove "Optional: add pull-to-refresh" step

### Phase 4 — Rewrite tab bar tracking approach
- Replace Option A (collapseProgress-driven) with Option B (GeometryReader in content)
- Place GeometryReader inside content closure to track content scroll offset
- Feed offset to `TabBarScrollState.handleScrollOffset(_:)` (existing API)

### Phase 5 — Add docs update
- Update CLAUDE.md external dependencies section
- Update `docs/codebase-summary.md` with new dependency
- Update `docs/system-architecture.md` with dashboard header architecture

### All Phases — Fix file paths
- Prefix all file paths with `StressMonitor/StressMonitor/`

## Validation Summary

Plan is solid in structure and phasing. Three critical gaps identified and resolved through validation. Ready for implementation after amendments applied.

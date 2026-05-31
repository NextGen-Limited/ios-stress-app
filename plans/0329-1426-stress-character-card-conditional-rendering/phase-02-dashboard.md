---
title: DashboardView — Wire permissionContent to StressCharacterCard
status: todo
priority: high
effort: small
planDir: plans/0329-1426-stress-character-card-conditional-rendering
---

# Phase 02 — DashboardView permissionContent Update

## Context

- Plan: `plan.md`
- File: `StressMonitor/StressMonitor/Views/DashboardView.swift`
- Depends on: Phase 01 complete

## Requirements

`DashboardView.permissionContent` currently renders `PermissionCardView` standalone. After Phase 01, `StressCharacterCard(result: nil, ...)` owns the permission state rendering. Update `permissionContent` to use the card.

## Current State

```swift
private var permissionContent: some View {
    ScrollView {
        VStack(spacing: 24) {
            PermissionCardView(                          // standalone
                permissionType: .healthKit,
                isLoading: viewModel.isRequestingAccess,
                onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } }
            )
            .padding(.top, 32)
            SkeletonBlock(height: 80)
            SkeletonBlock(height: 60)
            SkeletonBlock(height: 120)
            SkeletonBlock(height: 200)
            Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
        }
        .padding()
    }
}
```

## Target State

```swift
private var permissionContent: some View {
    ScrollView {
        VStack(spacing: 24) {
            StressCharacterCard(                         // card owns permission view
                result: nil,
                size: .dashboard,
                isRequestingAccess: viewModel.isRequestingAccess,
                onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } },
                onSettingsTapped: onSettingsTapped
            )
            SkeletonBlock(height: 80)
            SkeletonBlock(height: 60)
            SkeletonBlock(height: 120)
            SkeletonBlock(height: 200)
            Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
        }
        .padding()
    }
    .trackScrollOffsetForTabBar(state: tabBarScrollState)
    .background(Color.Wellness.adaptiveBackground)
}
```

**Note:** `.padding(.top, 32)` on `PermissionCardView` removed — card frame handles its own spacing naturally.

## Implementation Steps

1. Replace `PermissionCardView(...)` call in `permissionContent` with `StressCharacterCard(result: nil, size: .dashboard, isRequestingAccess: ..., onGrantAccess: ..., onSettingsTapped: onSettingsTapped)`
2. Remove `.padding(.top, 32)` that was on the standalone `PermissionCardView`
3. Verify `content(stress)` call site `StressCharacterCard(result: stress, ...)` still compiles (Phase 01 init must accept non-optional path)

## Files to Modify

- `StressMonitor/StressMonitor/Views/DashboardView.swift`

## Todo

- [ ] Replace `PermissionCardView(...)` with `StressCharacterCard(result: nil, ...)` in `permissionContent`
- [ ] Remove `.padding(.top, 32)` from replaced call
- [ ] Confirm `content(stress)` — `StressCharacterCard(result: stress, ...)` call still valid
- [ ] Build — no compile errors

## Success Criteria

- `permissionContent` shows `StressCharacterCard` with `result: nil` (renders `PermissionCardView` internally)
- Skeleton blocks still present below the card
- `content(stress)` path unchanged and compiling
- No `PermissionCardView` direct usage in `DashboardView` (fully delegated to card)

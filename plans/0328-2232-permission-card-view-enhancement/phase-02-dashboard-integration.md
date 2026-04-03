# Phase 02 — DashboardView Integration

## Overview

**Priority:** Medium
**Status:** Complete
**Blocked by:** Phase 01 (PermissionCardView must exist before wiring)

Wire `PermissionCardView` into `DashboardView` at **position 1** only when `isPermissionRequired == true`. The `noData` state (permission granted, zero measurements) is handled separately by `EmptyDashboardView` — UX docs require distinct CTAs for each state. When `isPermissionRequired` is set, `currentStress` is cleared to prevent stale UI.

<!-- Updated: Findings review - state collapse fixed; EmptyDashboardView preserved; stale data cleared -->

## Context Links

- Phase 01: `phase-01-permission-card-view.md`
- Dashboard (correct path): `StressMonitor/StressMonitor/Views/DashboardView.swift`
- ViewModel: `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift`
- HealthKit manager: `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift`
- UX spec reference: `docs/design-guidelines-ux.md:297–321` (defines separate noData vs permissionDenied states)

## Key Insight: HealthKit Read Permission Detection

Apple **intentionally hides read permission denials** — `authorizationStatus(for:)` always returns `.notDetermined` or `.sharingAuthorized` for read-only types. Only reliable signal: `HKError.errorAuthorizationDenied` thrown from fetch calls.

**CRITICAL: Do not use `currentStress == nil` as a proxy for "permission denied".** These are two distinct states per UX docs:
- `permissionRequired` → `PermissionCardView` (CTA: Grant Access / Open Settings)
- `noData` → `EmptyDashboardView` (CTA: Take First Measurement / Learn How It Works)

## Architecture

### Before (current state machine)

```
isLoading && currentStress == nil  →  loadingView
currentStress != nil               →  content(stress)     [StressCharacterCard pos 1]
else                               →  emptyState          [EmptyDashboardView]
```

### After (4-state machine — corrected)

```
isLoading                →  loadingView
isPermissionRequired     →  permissionContent()           [PermissionCardView pos 1 + skeletons pos 2-N]
currentStress != nil     →  content(stress)               [StressCharacterCard pos 1 + full data]
else                     →  emptyState                    [EmptyDashboardView — preserved]
```

**`else` branch definition:** `currentStress == nil AND isPermissionRequired == false`. This covers:
- Zero HRV measurements available ("take first measurement" case)
- Non-auth fetch errors (`errorMessage` is set; `EmptyDashboardView` still renders — acceptable for this scope)

These are not separately branched — `EmptyDashboardView` serves both. A dedicated error state is out of scope (YAGNI).

**Priority order matters:** `isPermissionRequired` must be checked BEFORE `currentStress != nil` to prevent stale data showing after revoked permissions.

### StressViewModel Changes

```swift
// New properties — explicit flags, NOT proxies for currentStress == nil
var isPermissionRequired: Bool = false
private(set) var isRequestingAccess: Bool = false  // re-entry guard for requestHealthKitAccess()

// In loadCurrentStress() catch:
} catch let hkError as HKError where hkError.code == .errorAuthorizationDenied {
    isPermissionRequired = true
    currentStress = nil    // ← clear stale data to prevent stale UI after revoked permissions
} catch {
    // non-auth errors: leave isPermissionRequired unchanged; set errorMessage
    errorMessage = error.localizedDescription
}
// On successful fetch — also clear the flag (handles Settings return path)
isPermissionRequired = false

// New method — only sets isPermissionRequired for known auth failures
// isRequestingAccess guards against double-tap spawning duplicate Tasks
func requestHealthKitAccess() async {
    guard !isRequestingAccess else { return }
    isRequestingAccess = true
    defer { isRequestingAccess = false }

    do {
        try await healthKit.requestAuthorization()
        // requestAuthorization success doesn't guarantee read access — loadCurrentStress
        // will catch HKError.errorAuthorizationDenied if still denied
        isPermissionRequired = false
        await loadCurrentStress()
    } catch let hkError as HKError where hkError.code == .errorAuthorizationNotDetermined
                                      || hkError.code == .errorAuthorizationDenied {
        isPermissionRequired = true
    } catch {
        // Non-auth failure (e.g. framework error): do NOT set isPermissionRequired
        errorMessage = error.localizedDescription
    }
}
```
<!-- Updated: Validation Session 4 - isRequestingAccess guard added -->

**Settings return recovery:** `isPermissionRequired` is cleared inside `loadCurrentStress()` on any successful fetch. DashboardView must trigger a reload when the app returns from background. Add `.onChange(of: scenePhase)` to `body`:

```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active && viewModel.isPermissionRequired {
        Task { await viewModel.loadCurrentStress() }
    }
}
```

This ensures that after the user taps "Open Settings", grants permission, and returns to the app, the fetch fires automatically without requiring them to tap another CTA.

### DashboardView Changes

```swift
// @Environment(\.scenePhase) private var scenePhase  ← must be added to DashboardView
var body: some View {
    Group {
        if viewModel.isLoading && viewModel.currentStress == nil && !viewModel.isPermissionRequired {
            loadingView
        } else if viewModel.isPermissionRequired {
            permissionContent    // ← checked BEFORE currentStress to guard stale data
        } else if let stress = viewModel.currentStress {
            content(stress)      // unchanged from current implementation
        } else {
            emptyState           // unchanged — EmptyDashboardView preserved
        }
    }
    // .alert, .sheet, .task, .onDisappear — unchanged
    .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active && viewModel.isPermissionRequired {
            Task { await viewModel.loadCurrentStress() }
        }
    }
}

private var permissionContent: some View {
    ScrollView {
        VStack(spacing: 24) {  // plain VStack — 5 static items, no lazy loading benefit
            // Position 1: permission card
            PermissionCardView(
                permissionType: .healthKit,
                isLoading: viewModel.isRequestingAccess,  // drives disabled visual + ProgressView
                onGrantAccess: { Task { await viewModel.requestHealthKitAccess() } }
            )
            .padding(.top, 32)

            // Positions 2–N: skeleton placeholders (pulsing opacity)
            SkeletonBlock(height: 80)   // TripleMetricRow placeholder
            SkeletonBlock(height: 60)   // SelfNote placeholder
            SkeletonBlock(height: 120)  // HealthData placeholder
            SkeletonBlock(height: 200)  // Chart placeholder

            Spacer().frame(height: tabBarScrollState.tabBarHeight + 16)
        }
        .padding()
    }
    .trackScrollOffsetForTabBar(state: tabBarScrollState)
    .background(Color.Wellness.adaptiveBackground)
}
```

**`SkeletonBlock`** — new reusable component (created in this phase):
```swift
// StressMonitor/StressMonitor/Views/Dashboard/Components/SkeletonBlock.swift
struct SkeletonBlock: View {
    var height: CGFloat = 60
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: Spacing.settingsCardRadius)
            .fill(Color.oledCardSecondary)
            .frame(maxWidth: .infinity, height: height)
            .opacity(isAnimating ? 0.4 : 0.8)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)  // decorative placeholder; VoiceOver skips
    }
}
```
<!-- Updated: Validation Session 4 - pulsing opacity animation added (was static rect) -->

> `content(stress)` and `emptyState` remain **unchanged** — this phase only adds the new `permissionContent` branch.

## Related Code Files

**Modify:**
- `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` — add `isPermissionRequired`, `requestHealthKitAccess()`, update error catch to clear `currentStress`
- `StressMonitor/StressMonitor/Views/DashboardView.swift` — add `isPermissionRequired` branch + `permissionContent` computed property; `content(stress)` and `emptyState` unchanged

**Create:**
- `StressMonitor/StressMonitor/Views/Dashboard/Components/SkeletonBlock.swift` — new reusable grey placeholder component

**Keep (unchanged):**
- `StressMonitor/StressMonitor/Views/Dashboard/Components/EmptyDashboardView.swift` — handles `noData` state with distinct "Take First Measurement" / "Learn How It Works" CTAs per UX spec

**Read-only:**
- `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` — verify `requestAuthorization()` signature

## Implementation Steps

1. **StressViewModel**: Add `var isPermissionRequired: Bool = false` and `private(set) var isRequestingAccess: Bool = false`
2. **StressViewModel**: In `loadCurrentStress()` catch block, add `HKError.errorAuthorizationDenied` branch that sets `isPermissionRequired = true` AND clears `currentStress = nil` (prevents stale data)
3. **StressViewModel**: Add `requestHealthKitAccess()` async method with `guard !isRequestingAccess` re-entry guard (resets flag, re-runs load)
4. **DashboardView**: Add `@Environment(\.scenePhase) private var scenePhase` property (NOT currently present — confirmed via code inspection)
5. **DashboardView**: Add `permissionContent` computed property — `PermissionCardView` at pos 1 + `SkeletonBlock` placeholders at pos 2-N
6. **DashboardView**: Update `body` Group — add `isPermissionRequired` branch between loading and content, checked BEFORE `currentStress != nil`
7. **Create** `SkeletonBlock.swift` — `RoundedRectangle` with pulsing opacity animation (`.easeInOut(duration: 1).repeatForever(autoreverses: true)`)
8. Verify `#Preview("Dashboard - Permission Required")` shows card + skeletons
9. Verify `#Preview("Dashboard - Empty State")` still shows `EmptyDashboardView` (noData path unchanged)
10. Verify no compile errors

## Todo List

**StressViewModel**
- [x] Add `isPermissionRequired: Bool` to `StressViewModel`
- [x] Add `private(set) var isRequestingAccess: Bool = false` to `StressViewModel`
- [x] In `loadCurrentStress()`: add `HKError.errorAuthorizationDenied` catch — set flag AND `currentStress = nil`
- [x] In `loadCurrentStress()`: on successful fetch, set `isPermissionRequired = false` (clears flag on Settings return)
- [x] Non-auth errors in `loadCurrentStress()`: set `errorMessage` only — do NOT touch `isPermissionRequired`
- [x] Add `requestHealthKitAccess()` method with `guard !isRequestingAccess` + `defer { isRequestingAccess = false }` — only catch `HKError.errorAuthorizationDenied` / `.errorAuthorizationNotDetermined` for `isPermissionRequired = true`

**DashboardView**
- [x] Add `@Environment(\.scenePhase) private var scenePhase` to `DashboardView` (confirmed missing via code inspection)
- [x] Create `Views/Dashboard/Components/SkeletonBlock.swift` (pulsing opacity animation + `.accessibilityHidden(true)`)
- [x] Add `permissionContent` computed property — `VStack` (not `LazyVStack`), `PermissionCardView(isLoading: viewModel.isRequestingAccess, ...)` + SkeletonBlocks
- [x] Update `body` Group: insert `isPermissionRequired` branch before `currentStress != nil` check
- [x] Add `.onChange(of: scenePhase)` to `body` — re-run `loadCurrentStress()` when app becomes `.active` AND `isPermissionRequired == true`

**Previews & Verification**
- [x] Add `#Preview("Dashboard - Permission Required")` with `isPermissionRequired = true`
- [x] Verify `#Preview("Dashboard - Empty State")` still shows `EmptyDashboardView` (noData path unchanged)
- [x] **Test**: `isPermissionRequired = true` → `PermissionCardView` shown, `EmptyDashboardView` not shown
- [x] **Test**: `isPermissionRequired = false, currentStress == nil` → `EmptyDashboardView` shown, `PermissionCardView` not shown
- [x] **Test**: user taps "Grant Access" → `requestHealthKitAccess()` fires → on success, `loadCurrentStress()` runs → card disappears
- [x] **Test**: user taps "Open Settings", grants, returns to app → `.onChange(of: scenePhase)` fires → `loadCurrentStress()` runs → card disappears
- [x] **Test**: stale `currentStress` present when `HKError.errorAuthorizationDenied` fires → `currentStress` cleared, card shown
- [x] **Test**: non-auth error in `loadCurrentStress()` → `isPermissionRequired` unchanged, `errorMessage` set, `EmptyDashboardView` shown
- [x] Verify no compile errors

## Success Criteria

- `isPermissionRequired = true` → `PermissionCardView` at pos 1 + skeletons; `EmptyDashboardView` NOT shown
- `isPermissionRequired = false, currentStress == nil` → `EmptyDashboardView` shown; `PermissionCardView` NOT shown
- `isPermissionRequired = false, currentStress != nil` → `StressCharacterCard` at pos 1, all sections visible
- "Grant Access" → `requestHealthKitAccess()` → reload → card disappears if access now granted
- "Open Settings" → user grants → returns to app → scene-phase hook fires → `loadCurrentStress()` → `isPermissionRequired` cleared
- Stale `currentStress` is cleared when `HKError.errorAuthorizationDenied` caught
- Non-auth errors do NOT set `isPermissionRequired` — dashboard shows `EmptyDashboardView` not permission card

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| State collapse: `currentStress == nil` used as permission proxy | **Mitigated** | Explicit `isPermissionRequired` flag; `currentStress` cleared on denial |
| `isPermissionRequired` checked after `currentStress` in body | **Mitigated** | State machine orders: loading → permissionRequired → content → noData |
| Settings return with no auto-refresh | **Mitigated** | `.onChange(of: scenePhase)` triggers `loadCurrentStress()` when `isPermissionRequired == true` |
| `requestHealthKitAccess()` sets flag for non-auth errors | **Mitigated** | Only `HKError.errorAuthorizationDenied/NotDetermined` sets flag; other errors → `errorMessage` |
| `else` branch catches non-auth errors too | Accepted | Both "no data" and generic errors show `EmptyDashboardView` — separate error state is out of scope |
| HKError catch never fires on simulator | Medium | Forced in preview via `isPermissionRequired = true`; verify on device |
| `content(stress)` section ordering broken | Low | `content(stress)` is **not refactored** — only `permissionContent` is new |

## Security Considerations

- Never log raw HKError details in production builds
- `requestAuthorization()` is idempotent — safe to call repeatedly

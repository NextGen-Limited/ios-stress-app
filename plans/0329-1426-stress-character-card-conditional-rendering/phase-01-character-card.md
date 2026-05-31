---
title: StressCharacterCard — Conditional Body
status: todo
priority: high
effort: small
planDir: plans/0329-1426-stress-character-card-conditional-rendering
---

# Phase 01 — StressCharacterCard Conditional Body

## Context

- Plan: `plan.md`
- File: `StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift`

## Requirements

1. `StressResult?` becomes optional — `nil` means no data to show character
2. Add `isRequestingAccess: Bool = false` and `onGrantAccess: (() -> Void)?` for permission state
3. `body`: `@ViewBuilder` conditional — `characterView` when `result != nil`, `PermissionCardView(embedded: true)` when `result == nil`
4. `DateHeaderView` always shown (date + settings gear visible in all states)
5. `accessibilityLabel` handles `nil` result
6. Add `embedded: Bool = false` param to `PermissionCardView` — when `true`, strips `.background`/`.cornerRadius`/`.shadow` (avoids double-card visual)
7. Remove `init(stressLevel:size:lastUpdated:onSettingsTapped:)` — unused outside Previews (YAGNI)

## Current State

```swift
struct StressCharacterCard: View {
    let mood: StressBuddyMood       // required
    let stressLevel: Double          // required
    let hrv: Double?
    let size: StressBuddyMood.CharacterContext
    let lastUpdated: Date?
    let onSettingsTapped: (() -> Void)?

    var body: some View {
        ZStack {
            VStack {
                DateHeaderView(...)
                Spacer()
                characterView          // always shown
                PermissionCardView()   // always shown — compile error
                Spacer()
            }
        }
    }
}
```

## Target State

```swift
struct StressCharacterCard: View {
    let result: StressResult?                          // nil = permission/no-data state
    let size: StressBuddyMood.CharacterContext
    let isRequestingAccess: Bool                       // new
    let onGrantAccess: (() -> Void)?                   // new
    let onSettingsTapped: (() -> Void)?

    // Computed from result
    private var mood: StressBuddyMood { StressBuddyMood.from(stressLevel: result?.level ?? 0) }
    private var stressLevel: Double { result?.level ?? 0 }
    private var hrv: Double? { result?.hrv }
    private var lastUpdated: Date? { result?.timestamp }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Always shown — date shows current date in permission state
                DateHeaderView(date: lastUpdated ?? Date(), onSettingsTapped: onSettingsTapped)
                Spacer()
                if result != nil {
                    characterView
                } else {
                    PermissionCardView(
                        permissionType: .healthKit,
                        isLoading: isRequestingAccess,
                        onGrantAccess: onGrantAccess ?? {},
                        embedded: true  // strips inner bg/shadow — avoids double-card
                    )
                }
                Spacer()
            }
            ...
        }
    }
}
```

**`PermissionCardView` embedded param:**
```swift
struct PermissionCardView: View {
    let permissionType: PermissionType
    var isLoading: Bool = false
    var embedded: Bool = false    // new — strips card styling when inside another card
    let onGrantAccess: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // ... icon, text, buttons unchanged ...
        }
        .padding(Spacing.cardPadding)
        // Conditional card styling:
        .background(embedded ? Color.clear : Color.oledCardBackground)
        .cornerRadius(embedded ? 0 : Spacing.settingsCardRadius)
        .elevatedShadow(enabled: !embedded)   // or guard with if !embedded
    }
}
```

## Implementation Steps

1. **`PermissionCardView.swift`**: Add `var embedded: Bool = false` param. Conditionally apply `.background`, `.cornerRadius`, `.elevatedShadow` (skip all three when `embedded == true`)
2. **Replace stored properties** in `StressCharacterCard` with `result: StressResult?` + `isRequestingAccess: Bool = false` + `onGrantAccess: (() -> Void)?`
3. **Add private computed props** (`mood`, `stressLevel`, `hrv`, `lastUpdated`) derived from `result`
4. **Update `body`**: keep `DateHeaderView` unconditional; conditional between `characterView` and `PermissionCardView(embedded: true)` based on `result != nil`
5. **Update primary `init`** to take `result: StressResult?` + new params
6. **Update `init(result:size:onSettingsTapped:)` convenience init** — passes through to primary init
7. **Delete `init(stressLevel:size:lastUpdated:onSettingsTapped:)`** — remove entirely
8. **Update `accessibilityLabel`** — return `"Health access required"` when `result == nil`
9. **Update Previews** — replace any `init(stressLevel:...)` calls with `init(result:...)`

## Files to Modify

- `StressMonitor/StressMonitor/Views/Dashboard/Components/PermissionCardView.swift`
- `StressMonitor/StressMonitor/Components/Character/StressCharacterCard.swift`

## Todo

- [ ] Add `embedded: Bool = false` to `PermissionCardView`, conditional card styling
- [ ] Replace `mood`, `stressLevel`, `hrv`, `lastUpdated` stored props with `result: StressResult?`
- [ ] Add `isRequestingAccess: Bool = false`, `onGrantAccess: (() -> Void)?` stored props
- [ ] Add private computed props derived from `result`
- [ ] Update `body` — unconditional `DateHeaderView`, conditional characterView/PermissionCardView
- [ ] Update primary `init` signature
- [ ] Update `init(result:size:onSettingsTapped:)` convenience init
- [ ] Delete `init(stressLevel:size:lastUpdated:onSettingsTapped:)`
- [ ] Update `accessibilityLabel` to return "Health access required" when result == nil
- [ ] Update Previews (replace init(stressLevel:...) calls)

## Success Criteria

- `PermissionCardView()` call removed from body
- Card shows `characterView` when `result != nil`
- Card shows `PermissionCardView` when `result == nil`
- Compiles without errors
- Existing `StressCharacterCard(result: stress, size: .dashboard, ...)` call in `DashboardView.content()` still works

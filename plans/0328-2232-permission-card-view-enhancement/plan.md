---
title: PermissionCardView Enhancement
status: complete
created: 2026-03-28
blockedBy: []
blocks: []
---

# PermissionCardView Enhancement

## Overview

**Priority:** Medium
**Status:** Complete
**Scope:** Single file rename + design-system alignment + visual polish

Enhance `PermissionErrorCard` → `PermissionCardView`, fully aligning it with the existing design system (`PrimaryButton`, `SecondaryButton`, `Typography`, `Spacing`, `AppShadow`). The current component is orphaned (no call sites), so rename is zero-risk.

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Design system alignment + rename](phase-01-permission-card-view.md) | complete |
| 2 | [DashboardView integration](phase-02-dashboard-integration.md) | complete |

## Key Files

| File | Action |
|------|--------|
| `Views/Dashboard/Components/PermissionErrorCard.swift` | Rename → `PermissionCardView.swift`, align design system |
| `StressMonitor/StressMonitor/Views/DashboardView.swift` | Add permission state branch to state machine |
| `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` | Add `isPermissionRequired: Bool` + clear stale `currentStress` on denial |
| `Views/Dashboard/Components/EmptyDashboardView.swift` | **Kept** — handles `noData` state (distinct from permission denial) |
| `Views/Onboarding/HealthKitErrorView.swift` | Out of scope (full-screen onboarding, separate flow) |

## Integration Context

**DashboardView before:**
```
isLoading && no data  →  loadingView
currentStress != nil  →  content(stress)      [StressCharacterCard at pos 1]
else                  →  emptyState           [EmptyDashboardView - separate screen]
```

**DashboardView after Phase 2 (corrected — 4 distinct states):**
```
isLoading                →  loadingView
isPermissionRequired     →  scrollContent(nil)            [PermissionCardView pos 1 + skeletons pos 2-N]
currentStress != nil     →  scrollContent(stress)         [StressCharacterCard pos 1 + full data]
else (noData)            →  emptyState (EmptyDashboardView — preserved, not deleted)
```

`isPermissionRequired` is an **explicit flag** on `StressViewModel` set only on `HKError.errorAuthorizationDenied`. It is **not** a proxy for `currentStress == nil`. When set, `currentStress` is cleared to prevent stale UI. `EmptyDashboardView` is **kept** for the `noData` case (distinct CTA: "Take First Measurement").

---

## Validation Log

### Session 1 — 2026-03-28
**Trigger:** `/ck:plan --validate` before implementation
**Questions asked:** 6

#### Questions & Answers

1. **[Architecture]** The plan uses PrimaryButton (blue by default) but the CTA needs to be green. Should we replicate PrimaryButton's style manually with green color, or introduce a green variant to PrimaryButton?
   - Options: Replicate inline, green | Add green variant to PrimaryButton
   - **Answer:** Replicate inline, green
   - **Rationale:** Avoids touching the shared design system. Green CTA is specific to this component's "grant access" context.

2. **[Architecture]** The screenshot shows a red heart in a rounded-square container. The current code uses Circle(). Which shape should the icon background use?
   - Options: RoundedRectangle(cornerRadius: 12) | Keep Circle
   - **Answer:** RoundedRectangle(cornerRadius: 12)
   - **Rationale:** Matches screenshot visual; consistent with SF Symbols app icon container aesthetics.

3. **[Scope]** Phase 02 removes EmptyDashboardView from DashboardView.body. What should happen to the EmptyDashboardView component itself?
   - Options: Keep file, remove from body | Delete EmptyDashboardView.swift
   - **Answer:** Delete EmptyDashboardView.swift ~~⚠️ SUPERSEDED by Session 2 — EmptyDashboardView is kept~~
   - **Rationale (original):** PermissionCardView fully absorbs the empty/no-permission state.
   - **Reversal reason:** UX spec (`docs/design-guidelines-ux.md:297–321`) defines distinct CTAs for `noData` vs `permissionRequired`. These are separate states; one card cannot cover both.

4. **[Architecture]** When `isPermissionRequired == true`, should sections 2-N be completely hidden or show skeleton placeholders?
   - Options: Completely hidden | Show skeleton placeholders
   - **Answer:** Show skeleton placeholders (in `permissionContent` branch only)
   - **Rationale:** Better UX in permission-denied state. Skeletons do NOT appear in the `noData`/`emptyState` branch.

5. **[Scope]** Skeleton components don't exist yet. How should they be scoped?
   - Options: Simple grey shimmer boxes | Add Phase 03 | Revert to hidden
   - **Answer:** Simple grey shimmer boxes — reusable `SkeletonBlock` view built inline in Phase 02
   - **Rationale:** Keeps scope minimal while delivering the UX intent.

6. **[Risk]** EmptyDashboardView.swift has uncommitted modifications. Delete it or keep it?
   - Options: Keep file, just remove from body | Delete it anyway
   - **Answer:** ~~Delete it anyway~~ ~~⚠️ SUPERSEDED by Session 2 — kept~~
   - **Reversal reason:** Same as Q3 reversal above.

#### Confirmed Decisions (Session 1 — updated for superseded items)
- Green CTA button: inline replicate of PrimaryButton with `Color.primaryGreen` — no design system change ✓
- Icon container: `RoundedRectangle(cornerRadius: 12)` — matches screenshot ✓
- ~~EmptyDashboardView: **deleted** as part of Phase 02~~ → **REVERSED: kept** (see Session 2)
- Sections 2–N when `isPermissionRequired == true`: `SkeletonBlock` grey placeholder (in `permissionContent` branch only) ✓

#### Action Items
- [x] Update Phase 01: clarify button implementation (inline green, `ScaleButtonStyle`, `cornerRadius(26)`, height 52)
- [x] Update Phase 01: confirm `RoundedRectangle(cornerRadius: 12)` for icon container
- [x] Update Phase 02: add `SkeletonBlock` component creation + usage
- ~~[x] Update Phase 02: add EmptyDashboardView.swift deletion step~~ → reversed
- [x] Update Phase 02: update sections architecture to show skeletons

#### Impact on Phases
- Phase 01: Button implementation clarified — inline green style, not PrimaryButton variant
- Phase 02: `SkeletonBlock` must be created; `EmptyDashboardView.swift` **kept** (not deleted)

---

### Session 2 — 2026-03-28 (Findings Review)
**Trigger:** Red-team findings review — 3 High/Medium issues identified before implementation

#### Findings & Resolutions

1. **[High] State collapse** — Using `currentStress == nil` as proxy for permission denied collapses two distinct UX states (`noData` vs `permissionRequired`)
   - **Resolution:** Explicit `isPermissionRequired: Bool` flag on `StressViewModel`. State machine branches on flag first, `currentStress` second.

2. **[High] Stale data after revoked permission** — `isPermissionRequired = true` but `currentStress != nil` still shows old stress data
   - **Resolution:** `currentStress = nil` cleared in the same catch block that sets `isPermissionRequired = true`. State machine checks `isPermissionRequired` BEFORE `currentStress != nil`.

3. **[Medium] Weak verification plan** — No test cases for the 4-state machine transitions
   - **Resolution:** Added 4 explicit test cases to Phase 02 Todo List: permission denied, noData, permission restored, stale-data-after-error.

4. **[Low] Wrong DashboardView path** — Plan referenced `Views/Dashboard/DashboardView.swift`
   - **Resolution:** Corrected to `StressMonitor/StressMonitor/Views/DashboardView.swift` in all plan files.

5. **[Low] Skeleton/hidden inconsistency** — Body said "show skeletons" but success criteria said "sections hidden"
   - **Resolution:** Skeletons shown only in `permissionContent` branch. `emptyState` (`EmptyDashboardView`) shown for `noData` — no skeletons there.

#### Reversed Decisions from Session 1
- **EmptyDashboardView**: Session 1 decided delete; **reversed** — file kept. UX spec (`docs/design-guidelines-ux.md:297–321`) defines distinct CTAs for `noData` vs `permissionRequired` states. `EmptyDashboardView` handles `noData` only.

#### Updated Key Files
| File | Action |
|------|--------|
| `Views/Dashboard/Components/EmptyDashboardView.swift` | **Kept** (was: deleted) — handles `noData` state |
| `Views/DashboardView.swift` | Only `permissionContent` is new; `content(stress)` and `emptyState` unchanged |

#### Impact on Phases
- Phase 02: Architecture rewritten — 4-state machine; `content(stress)` NOT refactored; `EmptyDashboardView` NOT deleted; test cases added to todo list

---

### Session 3 — 2026-03-28 (Findings Review 2)
**Trigger:** Second findings pass — 4 issues identified (1 High, 2 Medium, 1 Low)

#### Findings & Resolutions

1. **[High] No recovery after "Open Settings" return** — `isPermissionRequired` only clears in `requestHealthKitAccess()`, not when the user returns from Settings via the deep link
   - **Resolution:** `isPermissionRequired = false` set in `loadCurrentStress()` on ANY successful fetch. DashboardView adds `.onChange(of: scenePhase)` — when `.active` AND `isPermissionRequired == true`, triggers `loadCurrentStress()` automatically.

2. **[Medium] `noData` branch not explicitly defined** — "else" clause implicitly catches both zero-measurements and non-auth errors, but plan described it as "permission granted, zero measurements" only
   - **Resolution:** Plan now explicitly states `else` covers both zero-HRV and generic fetch errors; `EmptyDashboardView` serves both. A dedicated error state is out of scope (YAGNI). Documented as an accepted trade-off in Risk Assessment.

3. **[Medium] `requestHealthKitAccess()` sets `isPermissionRequired = true` for non-auth errors** — any `requestAuthorization()` failure (e.g. framework error) pushed dashboard into permission-required state
   - **Resolution:** Only `HKError.errorAuthorizationDenied` / `.errorAuthorizationNotDetermined` sets `isPermissionRequired = true`. Other errors → `errorMessage` only.

4. **[Low] plan.md Session 1 contradicts Session 2** — old "delete EmptyDashboardView" decisions still present in confirmed-decisions block
   - **Resolution:** Session 1 Q3, Q6, and Confirmed Decisions block updated with strikethrough + superseded notes.

#### Impact on Phases
- Phase 02: `loadCurrentStress()` success path now clears `isPermissionRequired`; `.onChange(of: scenePhase)` added to DashboardView; `requestHealthKitAccess()` narrowed to auth-specific error catch; test cases for Settings-return and non-auth-error paths added to todo list

---

### Session 4 — 2026-03-29
**Trigger:** Pre-implementation validation pass — 4 issues identified from code inspection
**Questions asked:** 4

#### Questions & Answers

1. **[Risk]** Phase 01 renames the file via CLI. The `.xcodeproj` won't auto-update — `PermissionErrorCard.swift` reference must be manually updated in `.pbxproj`. What's the rename strategy?
   - Options: Rename struct only, keep filename | Rename file + update .pbxproj via sed | Rename file, trust Xcode to re-add
   - **Answer:** Rename file to `PermissionCardView.swift` — latest Xcode auto-handles `.pbxproj` updates
   - **Rationale:** Modern Xcode detects file renames and updates project references automatically. No manual `.pbxproj` surgery needed.

2. **[Architecture]** Phase 02 wires "Grant Access" as `Task { await viewModel.requestHealthKitAccess() }` with no re-entry guard. Rapid double-taps spawn duplicate Tasks. How should this be handled?
   - Options: Add `isRequestingAccess` flag (Recommended) | Reuse `isLoading` | No guard needed
   - **Answer:** Add `isRequestingAccess` flag
   - **Rationale:** Explicit flag is cleaner than repurposing `isLoading` (different semantic). Button disabled while request is in-flight.

3. **[Architecture]** Session 1 approved "grey shimmer boxes". Phase 02 code shows a static `RoundedRectangle` with no animation. Should `SkeletonBlock` animate?
   - Options: Static grey rect only | Pulsing opacity animation | Full shimmer gradient
   - **Answer:** Pulsing opacity animation
   - **Rationale:** Better loading affordance. "Shimmer" in Session 1 implied motion. Pulsing opacity is ~10 lines, not a scope creep risk.

4. **[Risk]** `DashboardView` has no `@Environment(\.scenePhase)` today — `.onChange(of: scenePhase)` in Phase 02 will fail to compile. Where should it be injected?
   - Options: Add directly to DashboardView (Recommended) | Handle in parent MainTabView | Use NotificationCenter
   - **Answer:** Add `@Environment(\.scenePhase) private var scenePhase` directly to DashboardView
   - **Rationale:** Self-contained; DashboardView owns its own recovery logic.

#### Confirmed Decisions
- File rename: rename to `PermissionCardView.swift` — Xcode auto-updates `.pbxproj` ✓
- Double-tap guard: `isRequestingAccess: Bool` flag on StressViewModel; button disabled when true ✓
- SkeletonBlock: pulsing opacity animation (`.easeInOut(duration: 1).repeatForever()`) ✓
- `scenePhase`: inject `@Environment(\.scenePhase)` directly in DashboardView ✓

#### Action Items
- [x] Phase 01: No changes (rename step already correct)
- [x] Phase 02: Add `isRequestingAccess` to StressViewModel section
- [x] Phase 02: Update `SkeletonBlock` definition to include pulsing animation
- [x] Phase 02: Add `@Environment(\.scenePhase)` to DashboardView todo list
- [x] Phase 02: Add button `.disabled(viewModel.isRequestingAccess)` to `permissionContent`

#### Impact on Phases
- Phase 01: No changes — rename step already correct
- Phase 02: `isRequestingAccess` flag added to StressViewModel; `SkeletonBlock` gains pulsing animation; `@Environment(\.scenePhase)` explicitly listed as a required addition

---

### Session 5 — 2026-03-29 (SwiftUI Expert Review)
**Trigger:** `/swiftui-expert-skill` review against plan before implementation
**Issues found:** 5 (1 Critical, 2 Medium, 2 Low)

#### Findings & Resolutions

1. **[Critical] `accessibilityElement(children: .combine)` with interactive children** — `PermissionErrorCard.swift:101` wraps two `Button` elements with `.combine`, collapsing the card into a single non-interactive VoiceOver element. Users cannot activate "Grant Access" or "Open Settings" via VoiceOver.
   - **Resolution:** Phase 01 now removes `.accessibilityElement(children: .combine)` and the card-level `.accessibilityLabel`. Individual button `.accessibilityLabel` modifiers are kept.

2. **[Medium] Disabled state has no visual feedback on inline green button** — Phase 02's `.disabled(viewModel.isRequestingAccess)` grays out system interaction but the custom `.background(Color.primaryGreen)` stays green visually.
   - **Resolution:** `PermissionCardView` gains `var isLoading: Bool = false` param. Primary button shows conditional background (`isLoading ? Color.gray : Color.primaryGreen`) + `ProgressView`, mirroring `PrimaryButton`. Phase 02 passes `isLoading: viewModel.isRequestingAccess` directly; no separate `.disabled()` needed.

3. **[Medium] `SecondaryButton` can be used directly** — Phase 01 said "SecondaryButton-style" but `SecondaryButton(title:action:)` exists in `Buttons.swift` and fits exactly.
   - **Resolution:** Phase 01 updated to use `SecondaryButton(title: "Open Settings", action: openSettings)` directly.

4. **[Low] `LazyVStack` in `permissionContent` is overkill** — 5 static children gain nothing from lazy loading; adds measurement overhead.
   - **Resolution:** Phase 02 `permissionContent` uses plain `VStack(spacing: 24)`.

5. **[Low] `SkeletonBlock` missing `.accessibilityHidden(true)`** — Decorative skeleton placeholders would appear in VoiceOver traversal.
   - **Resolution:** `.accessibilityHidden(true)` added to `SkeletonBlock.body`.

#### Action Items
- [x] Phase 01: Add accessibility fix to gap analysis + implementation steps + todo
- [x] Phase 01: Add `isLoading: Bool` param to architecture + implementation steps + todo
- [x] Phase 01: Update secondary button to use `SecondaryButton` directly
- [x] Phase 02: Replace `LazyVStack` → `VStack` in `permissionContent` code snippet
- [x] Phase 02: Update `permissionContent` to pass `isLoading: viewModel.isRequestingAccess`
- [x] Phase 02: Add `.accessibilityHidden(true)` to `SkeletonBlock` definition
- [x] Phase 02: Update DashboardView todo to reflect `VStack` + `isLoading` param changes

#### Impact on Phases
- Phase 01: 3 changes — accessibility fix (critical), `isLoading` param, `SecondaryButton` direct use
- Phase 02: 3 changes — `VStack` instead of `LazyVStack`, `isLoading` wired to `viewModel.isRequestingAccess`, `SkeletonBlock` accessibilityHidden

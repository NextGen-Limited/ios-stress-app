# Lore

The history of StressMonitor as told by its commit log. Dates are derived from commit timestamps on the default branch.

## Eras

### Foundation (Jan 2026)

The first three months laid the entire technical foundation in a sequence of phase-based commits. The initial commit `3417034` on 2026-01-18 ("feat: create project") was followed the same day by Phase 1 (project setup, protocols), Phase 2 (SwiftData repository, `StressViewModel`, dashboard, history views, HealthKitManager with background queries, stress calculation algorithms, background task scheduler), and the watchOS app skeleton. By the end of January the project had a working two-factor stress calculator (HRV + HR), SwiftData persistence, and a basic dashboard.

Key events:

- **2026-01-18**: project created, Phase 1 + Phase 2 implemented in a single day.
- **Jan-Mar 2026**: 89 commits across foundational work: HealthKit fetches, CloudKit sync, watchOS app, widget extension, onboarding.

### Multi-factor algorithm (Mar-Apr 2026)

The two-factor HRV+HR calculator was replaced by the five-factor `MultiFactorStressCalculator`. Sleep, activity, and recovery `StressFactor` implementations were added, along with the `StressContext` bundle and per-factor confidence scoring. `FactorCalibrator` and `BaselineCalculator` introduced circadian HRV baseline adjustment. This is the algorithm shape that ships today.

### UI build-out (Apr-May 2026)

Trends redesign, settings redesign, breathing exercises, character collection view, and the mini walk feature all landed in this window. The first iteration of the character system used procedural SwiftUI drawing code (the five `*CharacterView.swift` files that are now among the largest in the repo).

### Ripple redesign (Jun 2026)

June 2026 was the busiest month by far (143 commits) and reshaped the entire UI. Major events:

- **2026-06-13 to 2026-06-14**: Trends, settings, breathing, and mini walk screens redesigned around the Ripple character system. Global Roboto font and teal color cleanup applied.
-- **2026-06-15**: biological age calculator, watch face personalization, soft paywall with weekly billing.
- **2026-06-16**: Characters tab removed; collection relocated to Settings.
- **2026-06-22**: Foundation redesign: 5-tier stress scale, 4-tab navigation, unified RippleMood, SF Pro fonts. Onboarding redesigned with health-state branching.
- **2026-06-23 to 2026-06-24**: full dashboard, action, trends, history, and bio-age screens rebuilt per new HTML design specs. Icon system introduced and rolled out across 37 files.
- **2026-06-25**: character views migrated from procedural SwiftUI to exported SVG assets.
- **2026-06-27**: `AppRouter` and `PaywallController` introduced; Home tab rebuilt to match `04-home` design spec.
- **2026-06-28**: Apple Intelligence fallback removed; SupabaseLLM wired as the sole LLM backend. Settings redesigned.

### Backend wiring (ongoing)

The Supabase Edge Function backend for AI chat was wired in late June. `KeychainService` was added on 2026-06-14 to migrate the Supabase JWT out of UserDefaults. The guest JWT fallback is still in place with a TODO to replace it with Apple Sign-In before production.

## Longest-standing features

- **`MultiFactorStressCalculator`** - introduced in the algorithm era (Mar-Apr 2026), still the core domain type. Has survived the UI redesign and backend changes without architectural change.
- **`StressMeasurement` @Model** - the central persisted record since Phase 2 (Jan 2026). Gained optional multi-factor component fields through a lightweight migration.
- **`HealthKitManager`** - async wrapper over HealthKit since Phase 2. Extended with sleep, activity, and recovery fetchers but the core query pattern is unchanged.

## Deprecated features

- **Characters tab** - the Characters tab was removed in commit `60518c4` (2026-06-16) and relocated to a section inside Settings. The old top-level tab is gone.
- **Procedural character drawing** - the five `*CharacterView.swift` files in `StressMonitor/StressMonitor/Components/Character/` (Ripple, Blossom, Ember, Lumi, Zephyr) were the original rendering path. Commit `b99b1ca` (2026-06-25) migrated to exported SVG assets in the Asset Catalog. The procedural files remain in the tree but are no longer the active rendering path.
- **Apple Intelligence fallback** - the on-device LLM fallback was removed in commit `a4277ec` (2026-06-28). `SupabaseLLMService` is now the sole LLM backend.

## Major rewrites

- **Navigation (Jun 2026)**: the move from ad-hoc `@State` navigation booleans to a centralized `AppRouter` owning per-tab `NavigationPath`s, plus `PaywallController` as a single full-screen paywall surface. Commit `d361283`.
- **Dashboard (Jun 2026)**: the Home tab was rebuilt to match the `04-home.html` design spec. Commit `1880555`.
- **Icon system (Jun 2026)**: 37 files updated to use `AppIconSystem` mappings instead of hardcoded SF Symbol strings. Commit `03563bb`.

## Growth trajectory

- **Jan 2026**: iOS app + watchOS app + widget extension.
- **Mar-Apr 2026**: algorithm maturation, no new targets.
- **Jun 2026**: 143 commits in one month, the largest expansion. Fastlane release automation, ASO and community strategy docs, full UI redesign, backend wiring.

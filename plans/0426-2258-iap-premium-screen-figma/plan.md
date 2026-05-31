---
name: IAP Premium Subscription Screen
status: complete
created: 2026-04-26
author: phuongddx
figma: https://www.figma.com/design/EHvjgTBOvThoVuk0cyE6tp/Stress-App--Copy-?node-id=3365-8397
---

# IAP Premium Subscription Screen

## Overview
Implement the IAP (In-App Purchase) Premium screen matching Figma design. This is the paywall/subscription screen where users select a plan and purchase premium access.

## Context
- No StoreKit integration exists — premium tracked via `@AppStorage("isPremiumUser")`
- Existing premium UI: PremiumCard (Settings), PremiumLockOverlay, PremiumBanner
- Figma uses **Lato** font — needs adding (project has Roboto, not Lato)
- Navigation: SettingsView → PremiumCard → IAP screen (via `.navigationDestination`)

## Phases

| # | Phase | Status | Files |
|---|-------|--------|-------|
| 1 | Add Lato font + IAP design tokens | complete | [phase-01-fonts-and-tokens.md](./phase-01-fonts-and-tokens.md) |
| 2 | Create StoreKit service protocol + mock | complete | [phase-02-storekit-service.md](./phase-02-storekit-service.md) |
| 3 | Build IAP screen components | complete | [phase-03-iap-components.md](./phase-03-iap-components.md) |
| 4 | Build main IAP screen + wire navigation | complete | [phase-04-iap-screen-and-nav.md](./phase-04-iap-screen-and-nav.md) |

## Key Decisions
- **Lato font**: Download Lato family (Regular, Medium, Bold, Black) and register in Info.plist
- **Pricing**: Figma shows $14.99/mo for both plans — Monthly should be $19.99/mo, Annual $14.99/mo (saves ~25%). Will use configurable model.
- **StoreKit**: Protocol-only now, mock implementation. Real StoreKit integration deferred.
- **Dark mode**: Figma is light-only. Will add adaptive dark colors where existing patterns apply.

## File Map (new files)
```
StressMonitor/StressMonitor/
├── Fonts/
│   ├── Lato-Regular.ttf
│   ├── Lato-Medium.ttf
│   ├── Lato-Bold.ttf
│   └── Lato-Black.ttf
├── Services/StoreKit/
│   ├── StoreKitServiceProtocol.swift
│   ├── MockStoreKitService.swift
│   └── PremiumState.swift
├── Models/
│   └── SubscriptionPlan.swift
├── ViewModels/
│   └── PremiumViewModel.swift
└── Views/Premium/
    ├── IAPPremiumView.swift
    ├── Components/
    │   ├── IAPNavBar.swift
    │   ├── IAPHeroSection.swift
    │   ├── PlanSelectionCard.swift
    │   ├── IAPCTAButton.swift
    │   └── IAPUtilityRow.swift
```

## Dependencies
- None (standalone feature)

## Red Team Review

### Session — 2026-04-26
**Findings:** 8 (8 accepted, 0 rejected)
**Severity breakdown:** 3 Critical, 4 High, 1 Medium

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | PremiumLockOverlay disconnected from IAP screen | Critical | Accept | Phase 4 |
| 2 | `.constant()` alert binding is non-functional | Critical | Accept | Phase 4 |
| 3 | Split-brain premium state (`@AppStorage` scattered) | Critical | Accept | Phase 2 |
| 4 | Mock-as-default DI in release builds | High | Accept | Phase 2 |
| 5 | ViewModel `plans` property dead code | High | Accept | Phase 2 |
| 6 | Real App Store URL in mock mode | High | Accept | Phase 4 |
| 7 | Missing Terms/Privacy links (App Store req) | High | Accept | Phase 4 |
| 8 | Silent error swallowing on plan-not-found | Medium | Accept | Phase 2 |

## Validation Log

### Session 1 — 2026-04-26
**Trigger:** Post red-team review validation
**Questions asked:** 3

#### Questions & Answers

1. **[Assumptions]** Figma shows $14.99/mo for both plans. Which pricing?
   - Options: Corrected pricing | Match Figma exactly | Placeholder
   - **Answer:** Use corrected pricing (Monthly $19.99, Annual $14.99/mo)
   - **Rationale:** "Save 25%" must be mathematically accurate for App Store review

2. **[Architecture]** Premium state ownership across 5+ views
   - Options: PremiumState singleton | Keep @AppStorage | Hybrid
   - **Answer:** Centralize to PremiumState singleton
   - **Rationale:** Single source of truth eliminates stale reads. All views migrate from @AppStorage to PremiumState.shared.

3. **[Scope]** Hero illustration (complex SVG, 30+ shapes)
   - Options: Static PNG | Simplified SwiftUI | Vector SVG
   - **Answer:** Static PNG from Figma export @2x/@3x
   - **Rationale:** Simplest approach, no SVG parsing complexity. Fixed size is fine for one screen.

#### Confirmed Decisions
- Pricing: Monthly $19.99, Annual $14.99/mo (25% savings verified)
- State: New PremiumState @Observable singleton replaces scattered @AppStorage
- Asset: Export hero as PNG, not SVG conversion

#### Impact on Phases
- Phase 2: PremiumState added, all views reading @AppStorage migrate to PremiumState.shared
- Phase 3: IAPHeroSection uses static Image asset, no SVG rendering
- Phase 4: All 3 overlay files + their parent views updated to use PremiumState

## Implementation Log

### Date: 2026-04-26
- **Status**: All 4 phases implemented and verified
- **Code Review**: Passed with fixes applied
- **Build**: Successful on simulator (iPhone 15, iOS 18.0)
- **Key Fixes from Code Review**:
  - Added @MainActor annotations to PremiumState singleton methods
  - Implemented #if DEBUG factory pattern for MockStoreKitService
  - Added NumberFormatter caching for performance optimization
  - Implemented purchase success auto-dismiss behavior
  - Fixed PremiumLockOverlay connection to IAP screen
  - Corrected alert binding from .constant() to proper state management
  - Centralized premium state from scattered @AppStorage to PremiumState.shared
  - Updated real App Store URLs for mock mode
  - Added required Terms/Privacy links for App Store review
  - Implemented proper error handling for plan-not-found scenarios

# Requirements: StressMonitor — App Store Submission Remediation

**Defined:** 2026-08-08
**Core Value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile.
**Source:** `plans/0808-2042-appstore-submission-remediation/plan.md` (6 audits, 65 findings). REQ-IDs map 1:1 to that plan's phases; see it for file-level detail and full acceptance criteria.

## v1 Requirements

### Build Configuration (BUILD)

- [ ] **BUILD-01**: Release archive uploads to App Store Connect without Privacy Manifest validation failure (remove invalid `NSPrivacyAccessedAPICategoryHealthKit`; declare chat content correctly per decision D3)
- [ ] **BUILD-02**: Widget and complications read/write the same App Group suite as the app on a real device (one canonical suite ID, not the current three)
- [ ] **BUILD-03**: `xcodebuild -showBuildSettings` shows a single Info.plist source of truth (`INFOPLIST_KEY_*`); orphaned `StressMonitor/Info.plist` removed
- [ ] **BUILD-04**: `xcodebuild test` executes a real unit-test bundle (currently zero test targets exist in `project.pbxproj`)

### Data Integrity & Deletion (DATA)

- [ ] **DATA-01**: On two signed-in devices, "Delete All" removes records from local storage, CloudKit, Keychain, and App Group cache — matching what the UI promises
- [ ] **DATA-02**: Health data exports carry `.completeFileProtection`, are size-capped, and are cleaned up after share
- [ ] **DATA-03**: CloudKit-synced health fields (`hrv`, `restingHeartRate`, `stressLevel`) are encrypted via `CKRecord.encryptedValues`, or the E2E-encryption claim is corrected in docs — depends on decision D2

### Auth & Chat Availability (AUTH)

- [ ] **AUTH-01**: No credential (expired or otherwise) is extractable from the Release binary via `strings`
- [ ] **AUTH-02**: Chat's entry point reflects real authentication state end-to-end — either a working sign-in flow ships, or Chat is honestly gated off for v1 — depends on decision D1
- [ ] **AUTH-03**: Dismissing the chat sheet mid-stream cancels the SSE request within one runloop and does not charge a credit; a forced network drop preserves partial response text

### Wire-Up Gap Closure (WIRE)

- [ ] **WIRE-01**: The home screen widget reflects a measurement taken seconds earlier on a real device (wired to live data + `WidgetCenter.reloadAllTimelines()`, not permanent placeholder) — scope depends on decision D4
- [ ] **WIRE-02**: No duplicate data-management implementation remains (`DataManagementService`/`CSVGenerator`/`JSONGenerator` vs. the retargeted `DataDeleterService`/`CloudKitResetService` chain)

### IAP Revenue Path (IAP)

- [ ] **IAP-01**: StoreKit product IDs resolve in Release configuration; the paywall shows real ASC prices, not mock data
- [ ] **IAP-02**: `Transaction.updates` is owned at app scope and entitlement refreshes on `scenePhase == .active` (not bound to a view's `@State`)
- [ ] **IAP-03**: A stale-premium user is corrected on next foreground even if `PaywallController.present()` had previously no-op'd
- [ ] **IAP-04**: Premium character unlocks either re-lock correctly after cancellation, or are confirmed one-time-permanent by product decision (not a silent bug)
- [ ] **IAP-05**: Displayed price matches `product.displayPrice` exactly; savings percentage is computed, not hardcoded; the free-trial banner only shows when `isEligibleForIntroOffer` is true
- [ ] **IAP-06**: Purchase, restore, cancel, and expiry are all verified against a local `.storekit` session; CI fails a Release archive when `allProductIDs` is empty

### Store Listing & Release Mechanics (SHIP)

- [ ] **SHIP-01**: At least one iPhone screenshot set (6.9" or 6.5") exists for the App Store listing, captured with demo mode disabled
- [ ] **SHIP-02**: The Fastlane `release` lane matches actual readiness for a first submission (manual ASC submission path, not blind `deliver --submit_for_review` against empty `fastlane/metadata/`)
- [ ] **SHIP-03**: The ASC privacy questionnaire is answered consistently with decision D3's resolution

### Accessibility (A11Y)

- [ ] **A11Y-01**: All interactive touch targets meet the 44×44pt minimum (paywall nav bar, chat composer currently below it)
- [ ] **A11Y-02**: Color-contrast failures fixed (`CategoryFilterChip`, `StressHeroCard` yellow-on-white)
- [ ] **A11Y-03**: `repeatForever` animations on stress-relief screens (breathing exercise, mini walk) respect Reduce Motion
- [ ] **A11Y-04**: Dynamic Type is adopted app-wide — `Typography.swift`/`Font+WellnessType.swift` use relative sizing; existing but currently-unused helpers (`.accessibleDynamicType()`, `.stressDualCoding()`, `.minimumTouchTarget()`) are actually called from the 743+ current `.font(.system(size:))` call sites
- [ ] **A11Y-05**: Orphaned, unreachable redesign views (`WeeklyHeatmapView`, `DailyTimelineView`, `LineChartView`, `StressChart7d`, `AccessibleStressTrendChart`) are deleted rather than made accessible

## v2 Requirements

Deferred — see `docs/project-roadmap.md` Version 1.1/2.0 for detail.

### Product Features

- **FEAT-01**: Coherent breathing pattern (6 breaths/minute) and custom pattern builder
- **FEAT-02**: Stress-triggers event logging and correlation analysis
- **FEAT-03**: Weekly digest PDF reports
- **FEAT-04**: App localization (es, fr, de, pt-BR, ja)

### Platform Expansion

- **PLAT-01**: ML-based stress prediction (CoreML, on-device)
- **PLAT-02**: iPad application with adaptive layout
- **PLAT-03**: Siri Shortcuts integration

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dedicated watchOS/Widget unit-test targets | Deferred unless trivially reachable while wiring BUILD-04; separate Xcode targets with zero test bundles today |
| Multi-locale App Store listing | Remediation plan targets single-locale first submission explicitly |
| Automating Fastlane `deliver` for release submission | SHIP-02 takes the manual ASC path deliberately for this first, untested release config |
| Legacy duplicate source tree / nested duplicate `.xcodeproj` cleanup (~5k dead lines) | Real tech debt (HIGH in `.planning/codebase/CONCERNS.md`) but orthogonal to submission readiness; candidate for a later milestone |
| v1.1/v2.0 product features (see v2 Requirements above) | Not submission blockers; tracked but not in this roadmap |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUILD-01 | Phase 1 | Pending |
| BUILD-02 | Phase 1 | Pending |
| BUILD-03 | Phase 1 | Pending |
| BUILD-04 | Phase 1 | Pending |
| WIRE-01 | Phase 1 | Pending |
| DATA-01 | Phase 2 | Pending |
| DATA-02 | Phase 2 | Pending |
| DATA-03 | Phase 2 | Pending |
| WIRE-02 | Phase 2 | Pending |
| AUTH-01 | Phase 3 | Pending |
| AUTH-02 | Phase 3 | Pending |
| AUTH-03 | Phase 3 | Pending |
| IAP-01 | Phase 4 | Pending |
| IAP-02 | Phase 4 | Pending |
| IAP-03 | Phase 4 | Pending |
| IAP-04 | Phase 4 | Pending |
| IAP-05 | Phase 4 | Pending |
| IAP-06 | Phase 4 | Pending |
| SHIP-01 | Phase 5 | Pending |
| SHIP-02 | Phase 5 | Pending |
| SHIP-03 | Phase 5 | Pending |
| A11Y-01 | Phase 5 | Pending |
| A11Y-02 | Phase 5 | Pending |
| A11Y-03 | Phase 5 | Pending |
| A11Y-04 | Phase 5 | Pending |
| A11Y-05 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 26 total
- Mapped to phases: 26/26 ✓
- Unmapped: 0 ✓

**Note on consolidation:** ROADMAP.md consolidates the source plan's 7 phases into 5 per `granularity: coarse`. WIRE-01 (widget wiring) folded into Phase 1 because it depends on the same App Group entitlement fix (BUILD-02) and shares no other sequencing conflict. WIRE-02 (duplicate data-management removal) folded into Phase 2 because the source plan itself notes it's "resolved by DATA-01's retarget" — same underlying fix. The source plan's Phase 6 (Store Listing) and Phase 7 (Accessibility) merged into Phase 5 — they share no files with each other or with Phases 1-4, and are both gated on calendar time / substantial completion of prior phases rather than code sequencing with each other. Auth (Phase 3) and IAP (Phase 4) were kept standalone: merging Auth with anything would obscure decision D1 (a 3-day to 2-week scope swing on its own), and IAP's 6 requirements plus external ASC lead time justify a dedicated phase.

**Note on dependencies:** Phase 3 (AUTH-02) is blocked on decision D1; Phase 2 (DATA-03) is blocked on decision D2; Phase 1 (BUILD-01) and Phase 5 (SHIP-03) are both blocked on decision D3; Phase 1 (WIRE-01) is blocked on decision D4 (see `PROJECT.md` Context). These can be planned but not fully executed until resolved — surfaced at `/gsd-discuss-phase` time for the phases they gate, not before.

---
*Requirements defined: 2026-08-08*
*Last updated: 2026-08-08 after roadmap creation (consolidated source plan's 7 phases into 5 per coarse granularity; see Traceability notes above)*

# StressMonitor — App Store Submission Remediation

## What This Is

StressMonitor is an iOS/watchOS app that scores stress 0–100 from HealthKit biometrics (HRV, heart rate, sleep, activity, recovery) via a five-factor algorithm, paired with an AI coaching chat, CloudKit sync, a gamified character system, and a StoreKit premium subscription. The product is feature-complete by line count, but a same-day audit (6 audits, 65 findings) found it is **not submittable**: AI Chat and in-app purchase — both shipped in the binary — are non-functional in every real build.

This milestone executes the remediation plan already drafted at `plans/0808-2042-appstore-submission-remediation/plan.md`: get StressMonitor from "feature-complete" to "actually works when a real user or App Review taps it."

## Core Value

Every feature that ships in the binary must actually work end-to-end for a real user — not just compile. Chat must authenticate and respond, a purchase must actually complete, "delete all data" must actually delete, and the Privacy Manifest must pass Apple's automated validation. Feature-complete-on-paper is not the bar; submittable is.

## Business Context

- **Customer**: Individual consumers tracking personal stress/wellness via HRV.
- **Revenue model**: StoreKit 2 subscription (weekly/monthly/annual) gating premium features and characters — confirmed real intent by the remediation plan's Phase 5 ("IAP revenue path"), which supersedes `docs/project-roadmap.md`'s stale "IAP Revenue: Not planned." Currently **zero product IDs resolve in any build configuration** — every purchase attempt throws.
- **Success metric**: A release archive uploads to App Store Connect without manifest validation failure; a real purchase/restore/cancel/expiry cycle verifies against a local `.storekit` file; Chat reflects real auth state instead of a dead, expired credential.
- **Strategy notes**: `plans/0808-2042-appstore-submission-remediation/plan.md` (the authoritative scope for this milestone), `plans/reports/appstore-audit-0808-*.md` (6 source audits), `.planning/codebase/{ARCHITECTURE,STACK,TESTING,CONCERNS}.md` (codebase map, corroborates several findings), `docs/project-roadmap.md`, `docs/KANBAN-SHIP-READINESS.md` (both partially stale relative to the fresher audit).

## Requirements

### Validated

<!-- Shipped and confirmed actually working — cross-checked against the remediation plan's "What's Solid" section and .planning/codebase/ARCHITECTURE.md, not just "exists in code." -->

- ✓ Multi-factor stress scoring algorithm (HRV · HR · Sleep · Activity · Recovery, weight redistribution) — existing, not flagged by any audit
- ✓ HealthKit integration, read-only, 7 data types — existing
- ✓ SwiftData local persistence with correct versioned schema migration (V1→V2) — existing, explicitly called out as solid
- ✓ Networking layer — HTTPS-only, no ATS exceptions, correct Keychain accessibility, async/await `URLSession` — explicitly called out as solid
- ✓ StoreKit verification logic itself (`checkVerified` throws on `.unverified`, `.finish()` called on both paths) — existing, sound; the *wiring around it* is what's broken (see Active)
- ✓ Apple Watch companion app with WidgetKit complications — existing
- ✓ Character collection gamification (5 creatures, evolution) — existing
- ✓ Breathing exercises and Mini Walk wellness tools — existing
- ✓ Haptic feedback — wired once, at the correct call site

### Active

<!-- This milestone: the 7-phase remediation plan at plans/0808-2042-appstore-submission-remediation/plan.md. REQ-IDs map 1:1 to that plan's phases; consult it for full detail, file locations, and acceptance criteria. -->

**BUILD — Phase 1 (build configuration correctness, ~4h, clears 3 CRITICALs)**
- [ ] BUILD-01: `PrivacyInfo.xcprivacy` passes ASC upload validation (remove invalid `NSPrivacyAccessedAPICategoryHealthKit`; declare chat content correctly — depends on D3)
- [ ] BUILD-02: One canonical App Group suite ID adopted across all 3 targets (currently 3 different IDs in use; widget `fatalError`s without it)
- [ ] BUILD-03: Info.plist consolidated onto `INFOPLIST_KEY_*` build settings; orphaned `StressMonitor/Info.plist` deleted
- [ ] BUILD-04: A real unit-test target is wired into `StressMonitor.xcodeproj` so `xcodebuild test` executes (prerequisite gap not called out by the remediation plan itself, but required for the TDD mode already active in `.planning/config.json` to mean anything — corroborated by `.planning/codebase/CONCERNS.md`)

**DATA — Phase 2 (data integrity & deletion, 2–3d, depends on BUILD-02 + decision D2)**
- [ ] DATA-01: Every delete/reset path actually deletes — local + CloudKit + Keychain JWT + App Group cache (today several are no-ops while the UI claims "permanently delete from iCloud")
- [ ] DATA-02: Health data exports (`DataExportView`) use complete file protection, are size-capped, and are cleaned up after share
- [ ] DATA-03: CloudKit field encryption implemented for `hrv`/`restingHeartRate`/`stressLevel` (`CKRecord.encryptedValues`), or the E2E-encryption claim is corrected in docs — **blocked on decision D2**

**AUTH — Phase 3 (auth & chat availability, 3d–2wk, blocked on decision D1)**
- [ ] AUTH-01: No credential (expired or otherwise) ships hardcoded in the Release binary
- [ ] AUTH-02: Chat entry point reflects real authentication state — either a working sign-in flow ships, or Chat is honestly gated off for v1 — **blocked on decision D1**
- [ ] AUTH-03: Dismissing the chat sheet mid-stream cancels the SSE request within one runloop and does not burn a credit; a forced network drop preserves partial text

**WIRE — Phase 4 (wire-up gap closure, 2–3d)**
- [ ] WIRE-01: Widget renders live data (wired to `StressViewModel`/`SyncManager` + `WidgetCenter.reloadAllTimelines()`), not permanent placeholder — scope depends on decision D4 (ship widget in v1, or exclude the target)
- [ ] WIRE-02: Duplicate `DataManagementService`/`CSVGenerator`/`JSONGenerator` implementation consolidated (resolved by DATA-01's retarget)

**IAP — Phase 5 (IAP revenue path, 3–4d, external ASC dependency — start product creation early)**
- [ ] IAP-01: StoreKit product IDs resolve in Release configuration (ASC product creation + `INFOPLIST_KEY_STOREKIT_PREMIUM_*`)
- [ ] IAP-02: `Transaction.updates` listener owned at app scope (not a view's `@State`), refreshes entitlement on `scenePhase == .active`
- [ ] IAP-03: Stale-premium correction path is reachable (`PaywallController.present()` no longer no-ops when already premium, permanently hiding the one path that would correct it)
- [ ] IAP-04: Permanent character-unlock entitlement bypass fixed, or confirmed as intentional one-time-unlock design
- [ ] IAP-05: Pricing display is accurate — no misleading `pricePerMonth` next to `/year`, computed savings percentage, gated free-trial banner behind `isEligibleForIntroOffer`
- [ ] IAP-06: A `.storekit` local testing file exists; purchase/restore/cancel/expiry verified against it; CI fails a Release archive when `allProductIDs` is empty

**SHIP — Phase 6 (store listing & release mechanics, 4–6h + design, mostly gates on 1–5 substantially done)**
- [ ] SHIP-01: App Store screenshot set captured (min one iPhone set at 6.9" or 6.5"; demo mode disabled before capture)
- [ ] SHIP-02: Fastlane `release` lane matches actual readiness — manual ASC submission path for this first release rather than blind `deliver --submit_for_review`
- [ ] SHIP-03: ASC privacy questionnaire answered per decision D3's resolution

**A11Y — Phase 7 (accessibility, ~1d + 1–2wk, parallelizable with everything above)**
- [ ] A11Y-01: Sub-44pt touch targets fixed (paywall nav bar, chat composer)
- [ ] A11Y-02: Color-contrast fixes (`CategoryFilterChip`, `StressHeroCard`)
- [ ] A11Y-03: Reduce Motion guards added to `repeatForever` animations (breathing exercise, mini walk)
- [ ] A11Y-04: Dynamic Type adopted app-wide — `Typography.swift`/`Font+WellnessType.swift` reworked onto relative sizing; 743+ `.font(.system(size:))` call sites migrated; existing but zero-call-site helpers (`.accessibleDynamicType()`, `.stressDualCoding()`, `.minimumTouchTarget()`) actually adopted
- [ ] A11Y-05: Orphaned, unreachable redesign views (`WeeklyHeatmapView`, `DailyTimelineView`, `LineChartView`, `StressChart7d`, `AccessibleStressTrendChart`) deleted rather than fixed

### Out of Scope

- **v1.1 product features** (coherent breathing patterns, stress-triggers tracking, weekly digest, localization) — per `docs/project-roadmap.md`; not a submission blocker.
- **v2.0 concept-phase features** (ML/CoreML stress prediction, iPad app, Siri Shortcuts) — explicitly future per roadmap.
- **Dedicated watchOS/Widget unit-test targets** — deferred unless trivially reachable while wiring BUILD-04.
- **Multi-locale App Store listing** — the remediation plan explicitly targets a single-locale first submission.
- **Automating Fastlane `deliver` for release submission** — SHIP-02 takes the manual ASC path for this first release deliberately; automating it is future work once the config has been exercised once by hand.
- **Legacy duplicate source tree / nested duplicate `.xcodeproj` cleanup** (~5k dead lines, flagged HIGH in `CONCERNS.md`) — real debt, but orthogonal to submission readiness. Candidate for a later milestone.

## Context

- Brownfield, previously believed feature-complete per `docs/project-roadmap.md` (Jul 19, 2026) and `docs/KANBAN-SHIP-READINESS.md` (Jun 12, 2026), both of which named the test suite as the sole remaining blocker.
- A same-day, far more thorough source (`plans/0808-2042-appstore-submission-remediation/plan.md`, 6 audits / 65 findings, generated 2026-08-08 20:42 — ~2.5h before this milestone's initialization) found the real gap: **a systemic integration pattern, not isolated bugs** — "correct code written, then never wired up," repeated across accessibility helpers, data-deletion services, the widget data provider, the data-management stack, and the StoreKit transaction listener. This document is the authoritative scope source for this milestone, superseding the older KANBAN/roadmap framing.
- `.planning/codebase/CONCERNS.md` (generated independently, same day) corroborates the auth/privacy findings from a different angle (static codebase analysis vs. targeted audit), which is why both agree D1/D3 are real and unresolved.
- **Four blocking decisions are still open** (from the remediation plan) and gate specific phases — not resolved here, deliberately deferred to `/gsd-discuss-phase` for the phases they block:
  - **D1** (Auth strategy: ship Supabase Auth vs. gate Chat off for v1) — blocks Phase 3 (AUTH) and the submission date
  - **D2** (CloudKit encryption: implement `encryptedValues` vs. retract the E2E claim) — blocks Phase 2 (DATA); harder to change after launch
  - **D3** (Privacy contract authority: `CLAUDE.md`'s "never sent" claim vs. `StressContextPayload.swift`'s actual behavior) — blocks the ASC privacy nutrition label and BUILD-01
  - **D4** (Widget in v1: ship it — Phase 4 becomes a blocker — or exclude the target) — blocks Phase 4 (WIRE) priority
  - Two more, non-blocking but needed before Phase 6: is the "7-day free trial" real or aspirational copy; are the 3 premium characters permanent one-time unlocks by design or a bug.
- Repo is currently on `feature/spm-cache-integration` with substantial unrelated uncommitted changes (CloudKit, DataManagement refactor/deletion, chat, paywall, watch complications) — not assumed as a stable baseline for this milestone until merged.

## Constraints

- **Tech stack**: Swift 5.9+ (compiles at `SWIFT_VERSION = 5.0` under a Swift 6.x toolchain), iOS 18.6+ / watchOS 11.6+ deployment targets.
- **No shared framework**: iOS and watchOS duplicate algorithm/model code by file — a fix applied to one must be mirrored in the other where relevant.
- **External dependency with its own lead time**: ASC product/subscription-group creation for Phase 5 (IAP) should be filed the same day Phase 1 starts, independent of code sequencing.
- **No `.storekit` local testing config exists yet** — must be created before any IAP acceptance criterion can be verified even locally.
- **`git.base_branch` currently configured as `main`** for milestone branching, but active work is on `feature/spm-cache-integration` — needs resolution before a `gsd/v1.0-milestone`-style branch is cut (flagged as an unresolved question in the remediation plan itself).
- **Dependency policy**: 8 third-party SPM packages already resolved (Chat, SwiftUICharts + transitive incl. Kingfisher, GiphySDK); the remediation plan flags evaluating whether Giphy/Kingfisher/exyte media features are even shipping in v1 — removing unused ones closes a privacy-manifest rejection risk for free.
- **CI shape**: GitHub Actions on `macos-15`/Xcode 26.3 with SPM+DerivedData caching already wired; a real test job (once BUILD-04 lands) must fit inside that pipeline.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Replace the initially-scoped "test infra only" milestone with the full 7-phase App Store remediation plan | Discovered mid-setup that `plans/0808-2042-appstore-submission-remediation/plan.md` already exists — same-day, more thorough (65 findings vs. 1 KANBAN blocker), decision-gated, and ready to execute. Running a narrower parallel GSD track would duplicate/conflict on shared files (StoreKitService, SyncManager, PrivacyInfo.xcprivacy). User confirmed the replacement after reviewing the trade-off. | — Pending |
| REQ-IDs map directly to the existing plan's phases rather than re-deriving requirements independently | The plan is already audit-grounded with file-level specificity; re-deriving from scratch would be lower-fidelity and duplicate work already done today | ✓ Good |
| D1–D4 (and the 2 non-blocking product questions) are deferred to `/gsd-discuss-phase` for the phases they gate, not resolved during project init | These are product decisions with real trade-offs (e.g., D1 affects submission date directly); premature resolution during setup risks a wrong call made under time pressure | — Pending |
| Roadmap phase mode set to Horizontal Layers (`standard`), not the auto-mode default Vertical MVP | This is bug-fix/integration remediation across build config, data, auth, wiring, IAP, listing, and accessibility — not new user-facing feature slices. MVP/SPIDR framing doesn't fit; horizontal phases matching the plan's own structure do. | — Pending |
| Granularity: Coarse (3–5 phases) — set before the scope pivot, kept after | Still fits: the roadmapper may consolidate the plan's 7 phases toward the coarse end (e.g., Phase 6+7 are both explicitly parallelizable/non-blocking) without losing the plan's substance | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-08 after initialization (re-scoped after discovering the existing remediation plan)*

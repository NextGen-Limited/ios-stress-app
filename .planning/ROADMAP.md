# Roadmap: StressMonitor — App Store Submission Remediation

## Overview

This milestone takes StressMonitor from "feature-complete on paper" to submittable. Two features
that already ship in the binary — AI Chat and in-app purchase — are non-functional in every real
build, several delete/export paths lie to the user about what they do, the widget is permanently
static, and the store listing and accessibility contract are both incomplete. Five phases close
this out: fix build configuration and entitlements first (everything else needs a working App
Group and a manifest that clears ASC validation), then make data deletion and exports trustworthy,
then make Chat either genuinely work or be honestly absent, then complete the StoreKit purchase
path end-to-end, and finally close out store-listing mechanics and the accessibility gaps in
parallel. Phase structure and file-level detail are sourced from the existing audit-grounded plan
at `plans/0808-2042-appstore-submission-remediation/plan.md`; this roadmap consolidates its 7
phases into 5 per the project's coarse-granularity setting, without hiding any of the 4 blocking
product decisions (D1-D4) that still gate specific scope.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: Build Configuration & Widget Wiring** - Fix the Privacy Manifest, App Group entitlement, Info.plist, and test target; wire the widget to live data.
- [ ] **Phase 2: Data Integrity, Deletion & Consolidation** - Make "Delete All" actually delete everywhere it claims to, protect exports, and remove the duplicate data-management stack.
- [ ] **Phase 3: Auth & Chat Availability** - Make AI Chat genuinely work end-to-end or honestly gate it off — no dead credential, no silent failure.
- [ ] **Phase 4: IAP Revenue Path** - Make StoreKit purchases actually resolve and complete, and keep entitlement in sync with reality.
- [ ] **Phase 5: Store Readiness & Accessibility** - Capture screenshots, fix the release lane and privacy questionnaire, and close the accessibility gaps.

## Phase Details

### Phase 1: Build Configuration & Widget Wiring

**Goal**: The app builds and archives with a valid Privacy Manifest and correct entitlements, and the home-screen widget shows real data instead of a permanent placeholder.
**Depends on**: Nothing (first phase)
**Requirements**: BUILD-01, BUILD-02, BUILD-03, BUILD-04, WIRE-01
**Blocking Decisions**: D3 (privacy contract authority — affects BUILD-01's chat-content declaration); D4 (ship the widget in v1 or exclude the target — affects WIRE-01's scope)
**Success Criteria** (what must be TRUE):

  1. A Release archive uploads to App Store Connect without a Privacy Manifest validation error.
  2. The widget and complications read/write the same App Group suite as the app on a real device (no `fatalError`, one canonical suite ID instead of three).
  3. `xcodebuild -showBuildSettings` shows exactly one Info.plist source of truth; the orphaned `StressMonitor/Info.plist` is gone.
  4. `xcodebuild test` executes a real unit-test bundle and reports pass/fail.
  5. The home-screen widget reflects a stress measurement taken seconds earlier on a real device — or, per D4, the widget target is excluded from the build entirely.

**Plans**: 4/4 plans executed
Plans:

- [x] 01-01-PLAN.md — Wire the widget's App Group entitlement (tracer) + complete the Privacy Manifest + delete the orphaned Info.plist
- [x] 01-02-PLAN.md — Resolve widget data state as fresh/stale/empty and render it per the UI-SPEC
- [x] 01-03-PLAN.md — checkpoint: Apple Developer Portal + Fastlane Match capability registration
- [x] 01-04-PLAN.md — Correct privacy disclosure across docs and the privacy policy (D-01)

**UI hint**: yes

### Phase 01.1: SwiftData Schema Migration Safety (INSERTED)

**Goal**: The app launches without crashing for any device regardless of prior store schema state — the ModelContainer either migrates correctly from any historical schema or recovers without `fatalError`, and the SwiftData layer has no orphaned source, no entitlement/config mismatch, and no silent data-loss paths.
**Depends on**: Phase 1 (build configuration baseline — app must build/archive first)
**Requirements**: BUILD-04 (test execution — a launch-path integration test must be runnable)
**Blocking Decisions**: D5 (does the pre-V2 installed base have real user data that must be preserved? Determines "reconstruct frozen V1 snapshots + custom MigrationStage" vs "accept data loss via `eraseDatabaseOnSchemaChange`" — the largest effort swing in this phase, 0.5 day vs 2-3 days)
**Success Criteria** (what must be TRUE):

  1. An app installed over an existing store created by any prior build shape launches without `loadIssueModelContainer` — verified by integration test that creates a divergent prior store, reopens through the app's real recovery path, and asserts `Habit` is queryable on the recovered (fresh) store (per D5 = Option A, data loss on schema mismatch is accepted for pre-release).
  2. `fatalError` at `StressMonitorApp.swift:82` is replaced with a non-fatal recovery path in RELEASE (fresh container + telemetry log), so a migration defect never permanently bricks the app.
  3. The `VersionedSchema` pair declares frozen `@Model` snapshots per version (not live class reuse), so the migration diff reflects reality — OR `eraseDatabaseOnSchemaChange` is DEBUG-gated with a documented data-loss acceptance (per D5).
  4. CloudKit configuration is consistent: either the SwiftData `ModelConfiguration` binds `cloudKitContainer: .identifier("iCloud.stress.ai.com")` matching entitlements and all `@Model` types are CloudKit-conformant, OR the CloudKit entitlement is removed and the app is local-only.
  5. The orphaned root source set (`./StressMonitor/StressMonitorApp.swift`, `./StressMonitor/StressMonitorSchema.swift`, `./StressMonitor/Models/StressMeasurement.swift`) is deleted — only the active target's models remain.

**Plans**: 1/1 plans drafted
Plans:

- [ ] 01.1-01-PLAN.md — Non-fatal ModelContainer recovery (tracer integration test + fix), property-level migration defaults, CloudKit config consistency, orphaned root source deletion (D5 = Option A)

### Phase 2: Data Integrity, Deletion & Consolidation

**Goal**: "Delete" actually deletes everywhere the app claims it does, health exports are protected, and only one data-management implementation remains.
**Depends on**: Phase 1 (App Group entitlement from BUILD-02)
**Requirements**: DATA-01, DATA-02, DATA-03, WIRE-02
**Blocking Decisions**: D2 (CloudKit field encryption — implement `encryptedValues` or retract the E2E-encryption claim in docs; affects DATA-03 and is harder to change post-launch)
**Success Criteria** (what must be TRUE):

  1. On two signed-in devices, tapping "Delete All" removes the user's records from local storage, CloudKit, and the App Group cache — verified from the second device.
  2. The Keychain no longer contains the user's JWT after deletion (`SecItemCopyMatching` returns nothing).
  3. Exported health data files carry complete file protection, stay under the size cap, and are removed after the share sheet closes.
  4. CloudKit-synced health fields (`hrv`, `restingHeartRate`, `stressLevel`) are encrypted via `CKRecord.encryptedValues`, or the E2E-encryption claim in docs is corrected to match actual behavior.
  5. Only one data-management implementation remains in the codebase — the duplicate `DataManagementService`/`CSVGenerator`/`JSONGenerator` stack is gone.

**Plans**: TBD

### Phase 3: Auth & Chat Availability

**Goal**: AI Chat either genuinely works end-to-end, or is honestly unavailable — never silently dead behind a working-looking entry point.
**Depends on**: Nothing (code work parallelizable with Phases 1-2)
**Requirements**: AUTH-01, AUTH-02, AUTH-03
**Blocking Decisions**: D1 (auth strategy — ship Supabase Auth or gate Chat off for v1; blocks this phase's scope and the submission date directly — largest single swing in the milestone, 3 days to 2 weeks)
**Success Criteria** (what must be TRUE):

  1. No credential — expired or otherwise — is extractable from the Release binary via `strings`.
  2. Chat's entry point reflects real authentication state end-to-end: a working sign-in flow lets the user chat, or Chat is visibly and honestly gated off for v1.
  3. Dismissing the chat sheet mid-stream cancels the in-flight request within one runloop and does not charge a credit.
  4. A forced network drop mid-response preserves the partial text already received.

**Plans**: TBD

### Phase 4: IAP Revenue Path

**Goal**: A real user can actually pay, and their entitlement always reflects reality.
**Depends on**: Phase 1 (build configuration). External: ASC product/subscription-group creation should start immediately, independent of phase order — its lead time is the milestone's other long pole besides D1.
**Requirements**: IAP-01, IAP-02, IAP-03, IAP-04, IAP-05, IAP-06
**Blocking Decisions**: None of D1-D4 directly. Two non-blocking product questions gate acceptance: is the "7-day free trial" real (create the ASC offer) or aspirational copy (remove the claim); are the 3 premium character unlocks intentional one-time-permanent design or a bug (affects IAP-04's resolution).
**Success Criteria** (what must be TRUE):

  1. The paywall shows real ASC prices in Release configuration, and a purchase completes successfully against a local `.storekit` session.
  2. Entitlement is owned at app scope and automatically corrects itself when the app returns to foreground (`scenePhase == .active`), even after an out-of-app cancellation or a previously stale/no-op'd state.
  3. Premium character unlocks re-lock correctly after cancellation, or are confirmed as intentional one-time-permanent design rather than a silent bug.
  4. Displayed price matches `product.displayPrice` exactly, the savings percentage is computed rather than hardcoded, and the free-trial banner only appears when the user is actually eligible.
  5. Purchase, restore, cancel, and expiry are all verified against the `.storekit` session, and CI fails a Release archive when no product IDs resolve.

**Plans**: TBD

### Phase 5: Store Readiness & Accessibility

**Goal**: The submission can actually be filed, and the app meets its own stated accessibility contract.
**Depends on**: Phases 1-4 substantially done (for SHIP-01..03, which gate on the rest of the app being real). A11Y-01..05 are parallelizable from day one and share no files with Phases 1-4.
**Requirements**: SHIP-01, SHIP-02, SHIP-03, A11Y-01, A11Y-02, A11Y-03, A11Y-04, A11Y-05
**Blocking Decisions**: D3 (privacy contract authority — the ASC privacy questionnaire in SHIP-03 must be answered consistently with D3's resolution from Phase 1)
**Success Criteria** (what must be TRUE):

  1. At least one iPhone screenshot set (6.9" or 6.5") is captured with demo mode disabled and ready for the App Store listing.
  2. The Fastlane `release` lane matches actual readiness — a manual ASC submission path, not a blind `deliver --submit_for_review` against empty metadata.
  3. The ASC privacy questionnaire is answered consistently with decision D3's resolution.
  4. All interactive touch targets meet 44×44pt (paywall nav bar, chat composer), the flagged color-contrast failures are fixed (`CategoryFilterChip`, `StressHeroCard`), and Reduce Motion is respected on the breathing-exercise and mini-walk animations.
  5. Dynamic Type scales text app-wide through the existing (previously zero-call-site) helpers, and the orphaned unreachable redesign views are deleted.

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5. Phase 3 (Auth) is code-parallelizable with 1-2 but gated on decision D1 for full completion. Phase 5's A11Y half is parallelizable with everything; its SHIP half gates on 1-4 substantially done.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Build Configuration & Widget Wiring | 4/4 | In Progress|  |
| 2. Data Integrity, Deletion & Consolidation | 0/TBD | Not started | - |
| 3. Auth & Chat Availability | 0/TBD | Not started | - |
| 4. IAP Revenue Path | 0/TBD | Not started | - |
| 5. Store Readiness & Accessibility | 0/TBD | Not started | - |

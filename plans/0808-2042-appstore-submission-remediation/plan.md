# App Store Submission Remediation

**Created:** 2026-08-08
**Status:** Draft — blocked on 4 product decisions (see Blocking Decisions)
**Source:** 6 audits, 65 findings — 11 CRITICAL, 19 HIGH. Reports in `plans/reports/appstore-audit-0808-*`.
**Target:** first App Store submission of StressMonitor (iPhone + Watch companion, single locale)

## Verdict

Not submittable. Two features that ship in the binary — AI Chat and in-app purchase — are
non-functional in every real build. The store listing has no screenshots. The Privacy Manifest
fails upload validation. Estimated 3–4 weeks to a submittable build, gated by the auth decision.

## Root Cause

Five audits independently found the same defect shape: **correct code written, then never wired up.**

| Component | State | Call sites |
|---|---|---|
| `AccessibilityModifiers.swift`, `DynamicTypeScaling.swift` | Complete | 0 |
| `DataDeleterService` / `CloudKitResetService` / `LocalDataWipeService` | Complete | 0 (owning VM never instantiated) |
| `WidgetDataProvider.save*` | Complete | 0 (README only) |
| `DataManagementService` / `CSVGenerator` / `JSONGenerator` | Complete | 0 (superseded by incomplete view-layer reimpl) |
| `StoreKitService` `Transaction.updates` listener | Complete | 1, bound to a view's `@State` |
| `Product.SubscriptionInfo.status` mapping | Complete | Unreachable (nil group ID) |

Not six unrelated bugs — one systemic integration gap with no test exercising the seam. TDD Mode
was enabled in `.planning/config.json` for this reason; every phase below carries an integration
assertion, not just a unit test.

## Blocking Decisions

Phases 3 and 6 cannot be scoped until these are answered. Everything else can start now.

| # | Decision | Options | Blocks |
|---|---|---|---|
| D1 | **Auth strategy** | Ship Supabase Auth (Apple Sign-In / anonymous), or gate Chat off for v1 | Phase 3, submission date |
| D2 | **CloudKit encryption** | Implement `CKRecord.encryptedValues` for health fields, or retract the E2E claim in docs | Phase 2 (schema change; far harder post-launch) |
| D3 | **Privacy contract** | Root `CLAUDE.md` ("HealthKit never sent to Supabase") vs `StressContextPayload.swift` (sends HRV/HR/sleep/activity/recovery to `/chat`) — which is authoritative? | ASC nutrition label, Phase 1 |
| D4 | **Widget in v1** | Ship it (Phase 4 becomes a blocker) or exclude the target from the build | Phase 4 priority |

Two further product questions, non-blocking but needed before Phase 6:
- Is the "7-day free trial" real (create the ASC offer) or aspirational copy (remove the claim)?
- Are Ember/Zephyr/Lumi permanent one-time unlocks by design (then `entitlement-map.md` is wrong)
  or subscription-gated (then the code is wrong)?

## Phases

| # | Phase | Findings | Effort | Depends on |
|---|---|---|---|---|
| 1 | Build configuration correctness | 3 CRIT, 1 HIGH | ~4 h | — |
| 2 | Data integrity & deletion | 1 CRIT, 1 HIGH | 2–3 d | 1 (App Group), D2 |
| 3 | Auth & chat availability | 1 CRIT, 2 HIGH | 3 d – 2 wk | **D1** |
| 4 | Wire-up gap closure | 2 CRIT, 1 HIGH | 2–3 d | 1, D4 |
| 5 | IAP revenue path | 2 CRIT, 6 HIGH | 3–4 d | 1, ASC product creation |
| 6 | Store listing & release mechanics | 2 CRIT, 2 HIGH | 4–6 h + design | 1–5 substantially done |
| 7 | Accessibility | 1 CRIT, 4 HIGH | 1 d + 1–2 wk | — (parallelizable) |

### Phase 1 — Build configuration correctness

**Goal:** the app builds with a valid manifest, working entitlements, and a plist story that
doesn't sabotage later fixes.

- `PrivacyInfo.xcprivacy:63-69` — remove invalid `NSPrivacyAccessedAPICategoryHealthKit` (not one
  of Apple's five Required-Reason categories). **Fails upload validation; nothing ships until fixed.**
- `PrivacyInfo.xcprivacy` — declare chat text + `stress_context` as User Content; reconcile
  `HealthAndFitness` `Linked: false` against the identity-linking Bearer JWT. Depends on **D3**.
- App Group entitlement — absent from all three targets. Pick one canonical suite ID (currently
  three in use: `group.com.stressmonitor.app`, `group.com.stressmonitor.watch`,
  `group.stress.ai.com`) and add the capability. `WidgetDataProvider.swift:45-47` `fatalError`s
  without it.
- Info.plist consolidation — delete the orphaned `StressMonitor/Info.plist` and standardize on
  `INFOPLIST_KEY_*` build settings (the project's existing pattern), so the Phase 5 product-ID fix
  can't be applied to a file the build never reads.

**Acceptance:** Release archive uploads to ASC without manifest validation error; widget and
complication read/write the same suite on a real device; `xcodebuild -showBuildSettings` confirms
which plist wins, documented in the repo.

### Phase 2 — Data integrity & deletion

**Goal:** delete means delete, and health exports are protected.

- Every reachable delete/reset path is incomplete and the UI copy is false.
  `DataManageView.performFactoryReset():171-181` clears only `StressMeasurement` + `CharacterUnlock`.
  `DataDeleteViewModel.performDelete():398-451` never calls CloudKit regardless of chosen scope.
  `deleteBaseline():458-464` is a no-op stub. `SyncManager`/`CloudKitSyncEngine` pass
  `recordIDsToDelete: nil` always. Keychain JWT and App Group caches are never cleared. Meanwhile
  `DeleteConfirmationView.swift:98,253` promises "permanently delete all data from iCloud".
- Retarget the views onto the existing, correct, dead `DataDeleterService`/`CloudKitResetService`
  chain rather than patching the reimplementation.
- Health exports: `DataExportView.swift:314-348` writes plaintext HRV/HR/stress to `Caches/` with
  no `FileProtectionType`, no cap, no cleanup.
- **D2**: implement `CKRecord.encryptedValues` for `hrv`/`restingHeartRate`/`stressLevel`
  (`CloudKitSyncEngine.swift:78-86`, `CloudKitSchema.swift:43-50`) or correct the docs.

**Acceptance:** on two signed-in devices, Delete All removes records from both; Keychain token
absent per `SecItemCopyMatching`; exports carry `.completeFileProtection` and are cleaned after
share. Real device only — App Group behavior differs on simulator.

### Phase 3 — Auth & chat availability

**Goal:** AI Chat either works or is honestly absent. Currently it is present and dead.

`SupabaseSecrets.swift:6-8` embeds a signed Supabase JWT with no `#if DEBUG` gate — it compiles
into Release and is `strings`-extractable. It expired ~2026-07-05. Every `/chat` POST 401s, mapped
to "Please sign in to use AI Chat", but no sign-in flow exists (two `TODO: Replace with real
SupabaseAuthService` markers confirm). A reviewer on a fresh install hits this immediately —
Guideline 2.1.

Also in scope regardless of D1:
- `ChatBottomSheetView` dismissal never calls `cancelResponse()` — the SSE stream and its owners
  outlive the UI, burning credits after the user leaves.
- Mid-stream disconnect discards partial text (contrast `cancelResponse():169-172`, which preserves
  it) and the charged credit is not restored.

**Acceptance:** no credential in the Release binary; Chat entry point reflects real auth state;
dismissing mid-stream cancels within one runloop; a forced network drop preserves partial text.

### Phase 4 — Wire-up gap closure

**Goal:** shipped features are actually connected.

- `WidgetDataProvider.save*` is never called from the app target — `StressWidgetProvider.swift:41-56`
  always renders placeholder data. Reviewers will see a static widget. Wire it to
  `StressViewModel`/`SyncManager` plus `WidgetCenter.reloadAllTimelines()`, and add a staleness
  threshold with a "no data" fallback.
- Consolidate or delete the duplicate `DataManagementService`/`CSVGenerator`/`JSONGenerator` stack
  (resolved by Phase 2's retarget).
- **D4**: if the widget is out of v1, exclude the target rather than shipping placeholder output.

**Acceptance:** widget reflects a measurement taken seconds earlier on a real device; no duplicate
data-management implementation remains.

### Phase 5 — IAP revenue path

**Goal:** a user can actually pay, and entitlement reflects reality.

- **No product IDs resolve in any configuration.** `StoreKitProductCatalog` checks Info.plist → env
  → UserDefaults; none is populated, and no `INFOPLIST_KEY_STOREKIT_PREMIUM_*` exists. Result:
  paywall renders with mock prices, Subscribe throws `missingProductConfiguration` every time, in
  every build. Requires ASC product creation (external dependency — start early).
- **`Transaction.updates` listener is bound to the paywall's `@State`**, not the app process.
  `StressMonitorApp.swift` never constructs `StoreKitService`. `PremiumState.isPremiumUser` is a
  raw `UserDefaults` read. Worse, `PaywallController.present():58` no-ops when already premium, so
  a stale-premium user can never reach the only code path that would correct them. Move ownership
  to app scope + refresh on `scenePhase == .active`.
- **Permanent entitlement bypass:** `PurchaseSuccessView:159-181` sets `CharacterUnlock.isUnlocked`
  for three premium characters with no relock path anywhere. Subscribe → refund → keep forever.
  Pending product question above.
- **Two misrepresentation risks (Guideline 3.1.2(a)):** annual plan shows `pricePerMonth` next to
  `/year` (renders "$14.99/year" for a ~$179.88 charge), and `leftFooter` always falls back to a
  literal "Save 37%" because `savingsPercent` is never computed. Separately, the "7-day free trial"
  banner is unconditional with no `introductoryOffer` or `isEligibleForIntroOffer` check.
- No `.storekit` file exists anywhere — the purchase flow has never been exercised, even locally.
  Create it first; it unblocks all other IAP verification.

**Acceptance:** purchase, restore, cancel, and expiry all verified against a local `.storekit`
session; entitlement corrects itself on foreground after an out-of-app cancellation; displayed
price matches `product.displayPrice`; CI fails a Release archive when `allProductIDs` is empty.

### Phase 6 — Store listing & release mechanics

**Goal:** the submission can actually be filed.

- Zero App Store screenshots exist. Minimum: one iPhone set at 6.9" or 6.5" (ASC scales down).
  Watch screenshots optional; single locale. **Design/product task, does not parallelize with code.**
- `fastlane/Fastfile` `release` lane runs `deliver` with `skip_metadata: false`,
  `skip_screenshots: false`, `submit_for_review: true` against a nonexistent `fastlane/metadata/`
  and `fastlane/screenshots/`. Either populate them or flip to skip + `submit_for_review: false`
  and manage the listing in ASC by hand. **For a first submission, take the manual path** — the
  debut run of an untested `deliver` config should not be the one that submits your listing.
- No `Snapfile`/`SnapshotHelper.swift`/UI-test target; capture is manual. Add a checklist item:
  disable `-demo-mode` before capture, or the `DemoModeBannerView` pill ships in the screenshots.
- ASC privacy questionnaire — answer from the D3 resolution, not from whichever doc is opened first.

### Phase 7 — Accessibility

**Goal:** meet the project's own stated contract. Parallelizable with everything above.

Cheap first (~1 day, four HIGHs): sub-44pt targets in the paywall (`IAPNavBar.swift:14,39`, 38×38)
and chat composer (`ChatBottomSheetView.swift:328,348`, 32×32 and 36×36); yellow-on-white contrast
in `CategoryFilterChip` and the Home hero `StressHeroCard:120-123`; Reduce Motion guards on the
`repeatForever` loops in `BreathingExerciseView:107-112` and `MiniWalkView:116` — both on
stress-relief screens, where an undisableable pulse is a poor fit for vestibular sensitivity.

Then the CRITICAL: Dynamic Type is unimplemented app-wide — 743+ `.font(.system(size:))` across 155
files, zero `@ScaledMetric`, zero `relativeTo:`, and every purpose-built helper
(`.accessibleDynamicType()`, `.stressDualCoding()`, `.minimumTouchTarget()`) has **0 call sites**.
Rework `Typography.swift` and `Font+WellnessType.swift` onto relative sizing, then adopt at call
sites. 1–2 weeks.

Delete the orphaned redesign-generation views (`WeeklyHeatmapView`, `DailyTimelineView`,
`LineChartView`, `StressChart7d`, `AccessibleStressTrendChart`) rather than fixing their
accessibility — they are unreachable and only create regression risk.

**Not a finding:** dual coding is genuinely well implemented in live screens (`StressRingView`,
`StressHeroCard`, `StatusBadgeView`, `MoodCheckInView`, and ~6 others all pair color with
text/icon and carry real labels). Protect this during the Typography rework.

## What's Solid — Protect During Remediation

- Networking architecture: zero deprecated APIs, HTTPS-only, no ATS exceptions, correct Keychain
  accessibility (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), `URLSession` + async/await.
- SwiftData migration: `StressMonitorApp.swift:19-79` has a correct `VersionedSchema` /
  `SchemaMigrationPlan` (V1→V2 lightweight). No silent store-wipe risk.
- StoreKit verification: `checkVerified` throws on `.unverified`, never force-unwrapped;
  `.finish()` called on both verified and unverified paths.
- Haptics contract honored — wired once, at the right call site (`StressViewModel.swift:561`).

## Correction to the Earlier Interim Report

The security audit flagged the orphaned Info.plist as a crash-on-permission-prompt landmine. The
IAP audit disproved that: usage descriptions are duplicated as `INFOPLIST_KEY_*` build settings
(`project.pbxproj:605-617`, `656-668`) and `GENERATE_INFOPLIST_FILE=YES` merges them, so the
mismatch is **inert for standard keys**. It is not inert for StoreKit product IDs, which exist in
neither plist nor as a build setting. The item stays in Phase 1, but as trap-removal ahead of Phase
5 — not as a crash risk.

## Sequencing Notes

- Phase 1 is ~4 hours and clears three CRITICALs. Start today regardless of the decisions.
- Phase 5's ASC product creation is an external dependency with its own lead time. File it the same
  day Phase 1 starts, even though the code work comes later.
- Phase 7 shares no files with 1–5; assign it in parallel if there's a second pair of hands.
- Phase 6 is the long pole for calendar time and needs a named owner who is not an engineer.

## Unresolved Questions

1. D1–D4 above.
2. Are the ASC product IDs / subscription group already created outside this repo, or does this
   plan represent first creation? `docs/plans/B2-REAL-STOREKIT-PREMIUM-IMPLEMENTATION.md` treats it
   as an open external gate.
3. Should `git.base_branch` stay `main`? The configured Per-Milestone branching will branch from
   `main`, not from the current `feature/spm-cache-integration`.
4. Are Giphy / Kingfisher / exyte packages shipping in v1? They're resolved in `Package.resolved`
   but the media features aren't wired; removing them deletes an entire class of SDK
   privacy-manifest rejection risk for free.

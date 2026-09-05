# Roadmap: StressMonitor

## Milestones

- ✅ **v1.0 App Store Submission Remediation** — Phases 1, 1.1, 2, 3, 4, 5 (closed 2026-08-12, `override_closeout`)
- ✅ **v1.1 Backend API Migration** — Phases 1-3 (closed 2026-08-24, `verified_closeout`)
- 🚧 **v1.2 Submission Readiness** — Phases 1-4 (in progress) — close the v1.0-carryover blocker list so the binary is actually submittable

## Phases

**Phase Numbering:** This project restarts phase numbering at each milestone (v1.0 → Phases 1–5, v1.1 → Phases 1–3, v1.2 → Phases 1–4). Phase directories carry the milestone in their archive path, not in the phase ID.

<details>
<summary>✅ v1.0 App Store Submission Remediation (Phases 1, 1.1, 2, 3, 4, 5) — CLOSED 2026-08-12 (override_closeout)</summary>

- [~] Phase 1: Build Configuration & Widget Wiring (5/6 plans; verification `gaps_found`)
- [x] Phase 1.1: SwiftData Schema Migration Safety (1/1 plans; verification `passed`)
- [~] Phase 2: Data Integrity, Deletion & Consolidation (1/1 plans; verification `human_needed`, 3 pending UAT items)
- [~] Phase 3: Auth & Chat Availability (1/1 plans; never formally verified)
- [~] Phase 4: IAP Revenue Path (1/1 plans; never formally verified)
- [~] Phase 5: Store Readiness & Accessibility (1/1 plans; never formally verified)

Full phase detail archived at `.planning/milestones/v1.0-ROADMAP.md` and `.planning/milestones/v1.0-phases/`.

</details>

<details>
<summary>✅ v1.1 Backend API Migration (Phases 1-3) — CLOSED 2026-08-24 (verified_closeout)</summary>

- [x] Phase 1: Firebase Auth + API Client + Chat Migration (4/4 plans; verification `passed`, UAT 2/2) — completed 2026-08-16
- [x] Phase 2: Credits System + IAP Transition (8/8 plans; verification `passed` 29/29, live money-path smoke human-validated 2026-08-23) — completed 2026-08-23
- [x] Phase 3: Sessions, Preferences, Quick Actions + Cleanup (5/5 plans; verification `passed` 21/21, 5 live-backend UAT scenarios human-validated 2026-08-23) — completed 2026-08-23

Milestone audit: 21/21 requirements, 3/3 phases, 7/7 integration seams, 4/4 E2E flows, 0 gaps (status `tech_debt` — documented carryover only). SECURITY.md present for all phases, threats_open 0.

Full phase detail archived at `.planning/milestones/v1.1-ROADMAP.md` and `.planning/milestones/v1.1-phases/`.

</details>

### 🚧 v1.2 Submission Readiness (In Progress)

**Milestone Goal:** TestFlight build 1.0.0 (13) is live and BETA_APPROVED. This milestone closes the v1.0-carryover blocker list — privacy-manifest validation, build-config truth, delete correctness, test-suite trust, accessibility, and the store submission package — plus the two decisions (D3, D4) that gate them, so the shipped binary is submittable to App Review rather than merely installable.

- [x] **Phase 1: Binary & Manifest Truth** — Resolve D3/D4, then make everything the archive declares about itself true: privacy manifest validates at ASC, one App Group across targets, consolidated Info.plist, no credentials in the Release binary, widget either live or gone. (completed 2026-09-03)
- [ ] **Phase 2: Delete Correctness & Test-Suite Trust** — Prove "delete all data" propagates across devices, pin the CloudKit batch-delete failure path with a regression test, and make the test suite a trustworthy gate with no silent skips or unexplained failures.
- [ ] **Phase 3: Accessibility Compliance** — Touch targets, contrast, Reduce Motion, Dynamic Type, and removal of orphaned redesign views on the primary screens.
- [ ] **Phase 4: Store Submission Package** — Screenshots from a real-data build, an honest Fastlane `release` lane, and ASC privacy answers that match the actual `/chat` payload.

## Phase Details

#### Phase 1: Binary & Manifest Truth

**Goal**: Everything the shipped archive declares about itself is true — Apple's automated validation accepts the privacy manifest, all three targets agree on one App Group suite, Info.plist keys resolve from a single source, the Release binary leaks no credential, and the widget either renders real data or is not in the build at all.
**Depends on**: Nothing (first phase)
**Requirements**: BUILD-01, BUILD-02, BUILD-03, AUTH-01, WIRE-01, ENV-04, ENV-05
**Decisions to resolve first** (before any implementation task in this phase):

  - **D3 — privacy contract authority**: which document is authoritative about what leaves the device (root `CLAUDE.md`'s "HealthKit never sent" claim vs. `StressContextPayload.swift`'s actual derived-score payload). Gates BUILD-01 here and SHIP-03 in Phase 4.
  - **D4 — widget in v1**: ship the widget target or exclude it from the submitted build. Gates WIRE-01 here, and determines whether BUILD-01/BUILD-02/BUILD-03 must cover two bundles or three.

**Success Criteria** (what must be TRUE):

  1. A Release archive uploads to App Store Connect and clears privacy-manifest validation — no missing required-reason API declaration and no missing third-party SDK manifest (including any SPM dependency that survives the unused-media evaluation).
  2. App, widget, and watch targets read and write one canonical App Group suite ID; no target falls back to a placeholder suite or fails to open the shared container.
  3. Every Info.plist key the app depends on resolves from `INFOPLIST_KEY_*` build settings in the merged plist of the built product — no orphaned or duplicate plist file contributes keys.
  4. `strings` over the Release binary returns no usable credential — no JWT, API key, or secret is extractable from the shipped artifact.
  5. Per D4: the widget on a real device shows the same stress score the app shows after a refresh, or the widget target is absent from the archive's bundle list and no dead widget code ships.
  6. A Release archive is producible from the unmodified working tree — the SPM-cache proxy migration is complete (Firebase proxy products exist, GoogleSignIn proxy product naming does not collide with upstream) — and CI's `fastlane match` readonly run accepts the dual-cert App Store profiles without regenerating them.

**Plans**: 6/6 plans executed (01-06 is the WIRE-01 gap-closure plan from verification)
Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Tracer: scripts/verify-archive.sh artifact gate + ENV-04 SPM proxy completion (Firebase shims, GoogleSignIn_proxied rename, archive-from-tree)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — BUILD-01: watch privacy-manifest CA92.1 + D3 doc corrections (CLAUDE.md, EN/VI privacy policies)
- [x] 01-03-PLAN.md — BUILD-03: Info.plist consolidation (CFBundleURLTypes-only app plist, widget delete-or-verify) + dead Giphy build-phase removal

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — BUILD-02/AUTH-01/WIRE-01: phase-final archive audits (App Group suite, credential strings gate) + widget simulator evidence

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-05-PLAN.md — ENV-05: draft-PR CI run + user-approved deploy.yml dispatch (match readonly + ASC upload validation)

**Wave 5** *(gap closure — blocked on Wave 4; addresses the sole SC-5/WIRE-01 verification gap per D4)*

- [x] 01-06-PLAN.md — WIRE-01 gap closure: TDD wire the live widget write trigger (guarded save inside StressViewModel.loadCurrentStress → WidgetPublisher.publish) + re-captured widget/app same-value evidence

#### Phase 2: Delete Correctness & Test-Suite Trust

**Goal**: "Delete all data" is provably true everywhere the data lives, and the test suite is a gate that can be believed — one documented invocation, no silently disabled coverage, no unexplained failures, and no undispositioned money-path advisory.
**Depends on**: Phase 1 (the canonical App Group suite from BUILD-02 is one of the stores DATA-01's propagation check must observe as cleared)
**Requirements**: DATA-01, DATA-04, BUILD-04, ENV-01, ENV-02, ENV-03
**Success Criteria** (what must be TRUE):

  1. Deleting all data on one device signed into an iCloud account removes those records on a second device signed into the same account — verified end to end, not per-half.
  2. A regression test fails if CloudKit batch delete reports success while records survive; the v1.0 CR-01 bug cannot return unnoticed, and the seam under `CloudKitResetServiceProtocol` makes that failure injectable.
  3. One documented `xcodebuild test` invocation with `-parallel-testing-enabled NO` is what CI runs and what the dev docs tell a human to run — the two do not diverge.
  4. The full suite reports zero unexplained failures and no silently disabled suite: the WINDOWS.md #8 CoreSimulator crash lineage and the `CharacterEntitlementSyncTests` quarantine are each fixed, or each carries a written, dated disposition naming the root cause and the accepted coverage loss.
  5. The money-path advisories are dispositioned: WR-03 (DEBUG builds routing purchases through `MockStoreKitService`) and WR-04 (`.unverified` consumables being finished) are fixed or documented as an explicit accept with rationale.

**Plans**: 6/6 plans executed
Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Tracer (TDD): DATA-04 CloudKit delete-truthiness spy suite — ungated, mutation-proven red/green (the suite catches a lying delete)
- [x] 02-02-PLAN.md — ENV-03/WR-04 (TDD): never finish unverified transactions — red-first pin + five-site reachability note

**Wave 2** *(pbxproj serialized after 02-01)*

- [x] 02-03-PLAN.md — ENV-03/WR-03 (TDD): DEBUG defaults to real StoreKit at both wiring sites; mock becomes launch-arg opt-in — red-first wiring pin

**Wave 3** *(blocked on Waves 1-2)*

- [x] 02-04-PLAN.md — ENV-01/ENV-02: bounded re-diagnosis (container-lifetime hypothesis + live .ips) → fix-or-disposition for #8 lineage, CharacterEntitlementSyncTests, StoreKitServiceTests, EntitlementForegroundCorrectionTests (checkpoint-gated un-quarantine)

**Wave 4** *(blocked on 02-04 — docs follow the final gate state)*

- [x] 02-05-PLAN.md — BUILD-04: AGENTS.md canonical CI-parity invocation (env-var form), docs/TESTING.md pointer, INFOPLIST_KEY doc-truth note

**Wave 5** *(phase closer — blocked on all)*

- [x] 02-06-PLAN.md — DATA-01: Habit store-sweep fix + two-surface evidence note (device + CloudKit Console, human item) + phase trust gate record

#### Phase 3: Accessibility Compliance

**Goal**: A user relying on assistive settings can operate the primary screens — targets are reachable, text is legible, motion is optional, and no unreachable duplicate screen ships alongside the real one.
**Depends on**: Phase 1 (D4 determines whether widget surfaces are inside the contrast/Dynamic Type sweep)
**Requirements**: A11Y-01, A11Y-02, A11Y-03, A11Y-04, A11Y-05
**Success Criteria** (what must be TRUE):

  1. Every interactive control on the primary screens has a hit target of at least 44×44pt.
  2. Text and essential UI on the primary surfaces pass WCAG AA contrast in both light and dark appearance.
  3. With Reduce Motion enabled, animated views present their content without motion — no looping, scaling, or parallax animation plays.
  4. At the largest accessibility Dynamic Type size, the primary screens stay readable — no label truncates, clips, or overlaps another element.
  5. The orphaned redesign views are deleted from the source tree; no unreachable duplicate screen compiles into the binary.

**Plans**: 6 plans
**UI hint**: yes

Plans:
**Wave 1**

- [ ] 03-01-PLAN.md — Tracer (A11Y-02): contrast token retunes in place (D-04) + the D-06 token-pair unit test (usage-class matrix, both appearances, RED→GREEN + mutation red-proof) + watch mirrors + dual-coding caption fix
- [ ] 03-02-PLAN.md — A11Y-04 mechanism: rework `.accessibleDynamicType()` (no cap, no shrink; delete superseded zero-adopter variants), anchor Font.WellnessType to the system text-style ramp (byte-identical at Large), adopt on all 14 manifest surfaces (D-10 layer 1), and deliver the D-02 widget + watch half: anchor ~140 fixed-size font sites (widget Views/Live Activity/watch Views/complications) to the Dynamic Type ramp, remove the 9 text shrinks (dated exceptions only)

**Wave 2** *(surface files serialized after 03-02; chart files after 03-01)*

- [ ] 03-03-PLAN.md — A11Y-01: touch-target + icon-only-label sweep across the 14 surfaces (`.minimumTouchTarget` + token), dual-coding adoption where categories show, state-shape triage (error copy, NoDataCard empty states, locked-character dimming)
- [ ] 03-04-PLAN.md — A11Y-04/D-09: chart accessibility series (trend-summary builder unit-pinned red-first + per-point labels) + gauge/hero-numeral values + chart-file legend targets

**Wave 3** *(blocked on Waves 1-2 — shares files with both)*

- [ ] 03-05-PLAN.md — A11Y-03: one app-wide Reduce Motion helper (D-12/D-13, cross-fade fallbacks, DEBUG `-a11y-reduce-motion` seam), 13-file consolidation with re-baselined grep gate, D-11 breathing haptic+text fallback

**Wave 4** *(phase closer — deletion LAST, then gates against the final tree)*

- [ ] 03-06-PLAN.md — A11Y-05: D-14 reachability audit (BFS + extension-member screen + Periphery cross-check), blocking decision checkpoint, batched delete-compile of ~80 orphan files across 3 targets, both trust-gate records (D-10/D-13) + full suite + 03-A11Y-UAT.md apparatus

#### Phase 4: Store Submission Package

**Goal**: The App Store Connect record is submittable — screenshots show the real app, the release lane does exactly what it claims, and the privacy answers match the payload the app actually sends.
**Depends on**: Phase 1 (D3 sets the privacy contract SHIP-03 must answer to), Phase 3 (screenshots must capture the post-accessibility UI, not a version that gets re-cut)
**Requirements**: SHIP-01, SHIP-02, SHIP-03
**Success Criteria** (what must be TRUE):

  1. A complete App Store screenshot set exists for the required device sizes, captured from a build with demo mode disabled — every screenshot shows real app state, not generated demo data.
  2. Running the Fastlane `release` lane performs exactly the metadata-only upload the first submission needs, and no step in it claims work it does not perform.
  3. The ASC privacy questionnaire answers match the actual `/chat` payload field for field, consistent with the D3 privacy contract and with the shipped privacy policy text.
  4. The App Store Connect record reports no missing required item — metadata, screenshots, and privacy answers are all present and the version can be submitted for review.

**Plans**: TBD

## Progress

**Execution Order:** Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Binary & Manifest Truth | v1.2 | 6/6 | Complete    | 2026-09-03 |
| 2. Delete Correctness & Test-Suite Trust | v1.2 | 6/6 | In Progress|  |
| 3. Accessibility Compliance | v1.2 | 0/TBD | Not started | - |
| 4. Store Submission Package | v1.2 | 0/TBD | Not started | - |

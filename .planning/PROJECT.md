# StressMonitor — App Store Submission Remediation

## What This Is

StressMonitor is an iOS/watchOS app that scores stress 0–100 from HealthKit biometrics (HRV, heart rate, sleep, activity, recovery) via a five-factor algorithm, paired with an AI coaching chat, CloudKit sync, a gamified character system, and a credits-based monetization system (consumable credit packs + premium tier, server-verified against Apple JWS). The product is feature-complete by line count, but a same-day audit (6 audits, 65 findings) found it is **not submittable**: AI Chat and in-app purchase — both shipped in the binary — are non-functional in every real build.

This milestone executes the remediation plan already drafted at `plans/0808-2042-appstore-submission-remediation/plan.md`: get StressMonitor from "feature-complete" to "actually works when a real user or App Review taps it."

## Core Value

Every feature that ships in the binary must actually work end-to-end for a real user — not just compile. Chat must authenticate and respond, a purchase must actually complete, "delete all data" must actually delete, and the Privacy Manifest must pass Apple's automated validation. Feature-complete-on-paper is not the bar; submittable is.

## Business Context

- **Customer**: Individual consumers tracking personal stress/wellness via HRV.
- **Revenue model**: credits-based — server-authoritative credit balance (50 free/month, free-first consumption) spent by chat messages; consumable credit packs (`credits.small` $1.99/10, `credits.large` $19.99/150) redeem server-side against Apple-verified JWS; premium tier (subscription, `premium_until` expiry gating) = unlimited chat. Superseded the original weekly/monthly/annual subscription-only model in v1.1 Phase 2 (DEC-1/DEC-2); live money path human-verified 2026-08-23 against the deployed backend.
- **Success metric**: A release archive uploads to App Store Connect without manifest validation failure; a real purchase/restore/cancel/expiry cycle verifies against a local `.storekit` file; Chat reflects real auth state instead of a dead, expired credential.
- **Strategy notes**: `plans/0808-2042-appstore-submission-remediation/plan.md` (the authoritative scope for this milestone), `plans/reports/appstore-audit-0808-*.md` (6 source audits), `.planning/codebase/{ARCHITECTURE,STACK,TESTING,CONCERNS}.md` (codebase map, corroborates several findings), `docs/project-roadmap.md`, `docs/KANBAN-SHIP-READINESS.md` (both partially stale relative to the fresher audit).

## Requirements

### Validated

<!-- Shipped AND independently verified by a gsd-verifier pass this milestone — not just self-reported "Complete" in REQUIREMENTS.md's traceability table. See "v1.0 Verification Reality Check" in Context below for why this list is deliberately shorter than REQUIREMENTS.md's Complete count. -->

- ✓ Multi-factor stress scoring algorithm (HRV · HR · Sleep · Activity · Recovery, weight redistribution) — existing, not flagged by any audit
- ✓ HealthKit integration, read-only, 7 data types — existing
- ✓ Networking layer — HTTPS-only, no ATS exceptions, correct Keychain accessibility, async/await `URLSession` — explicitly called out as solid
- ✓ StoreKit verification logic itself (`checkVerified` throws on `.unverified`, `.finish()` called on both paths) — existing, sound
- ✓ Apple Watch companion app with WidgetKit complications — existing
- ✓ Character collection gamification (5 creatures, evolution) — existing
- ✓ Breathing exercises and Mini Walk wellness tools — existing
- ✓ Haptic feedback — wired once, at the correct call site
- ✓ Non-fatal SwiftData `ModelContainer` recovery across any prior store schema state — v1.0 Phase 1.1, verification `passed`
- ✓ DATA-02: Export protection (size cap, `.completeFileProtection`, on-dismiss cleanup) — v1.0 Phase 2, independently verified in code + tests
- ✓ DATA-03: CloudKit field encryption via `encryptedValues` for hrv/restingHeartRate/stressLevel — v1.0 Phase 2, independently verified in code + tests
- ✓ WIRE-02: Single canonical data-management implementation (`DataDeleterService`); duplicate `DataExporter`/`ExportModels` stack deleted — v1.0 Phase 2, independently verified
- ✓ v1.1 D-01/D-02: Firebase Auth — Anonymous sign-in at launch + Google Sign-In with anonymous-account linking (uid/credits/history preserved) — v1.1 Phase 01, human-verified on simulator 2026-08-16 (UAT Test 2)
- ✓ v1.1 D-03/D-07: `StressAPIClient` with Bearer Firebase ID token + backend `/chat` SSE streaming (terminal metadata event, 402 → insufficient-credits) — v1.1 Phase 01, human-verified end-to-end (UAT Test 1) + 87-test suite green
- ✓ v1.1 D-04: Supabase fully removed from source tree (services, config, Keychain tokens) — v1.1 Phase 01, verified in code + 01-REVIEW.md
- ✓ v1.1 G-01-2: Google Sign-In reachable from app UI (Settings → Sync & devices) with post-link email display — v1.1 Phase 01 Plan 01-04, human-verified 2026-08-16
- ✓ v1.1 Phase 2: Credits system — server-authoritative balance (GET /credits + SSE terminal metadata), 402 INSUFFICIENT_CREDITS → outOfCredits paywall, balance at all DEC-2 placements — verification `passed` + live smoke human-validated 2026-08-23
- ✓ v1.1 Phase 2: Backend IAP — POST /credits/redeem with Apple JWS verification (@apple/app-store-server-library 3.1.0, embedded Apple Root CA G2+G3), idempotent on transaction id, purchase ledger — backend suite 17 tests / 50 steps green
- ✓ v1.1 Phase 2: CR-01 free-first consumption + purchased_credits bucket separation (monthly reset preserves purchased) — migration applied + test-pinned
- ✓ v1.1 Phase 2: CR-02/CR-03/CR-05 revocation & expiry semantics — expired/revoked never activate premium; effective premium enforced at deductCredit + chat gate; revoked subscription JWS demotes premium (replay-safe `least()`); WR-10 refunded pack finishes without redemption on both entry points — test-pinned
- ✓ v1.1 Phase 2, IAP-01: Pack + premium product IDs resolve from Bundle.main in both configurations — StoreKitProductCatalogLiveTests 6/6 on simulator (CR-04 closed)
- ✓ v1.1 Phase 2, IAP-02: `Transaction.updates` listener owned at app scope (StoreKitService init)
- ✓ v1.1 Phase 2, IAP-03: Foreground entitlement refresh reachable at entry points
- ✓ v1.1 Phase 2, IAP-04: Premium gating semantics intentional (DEC-1)
- ✓ v1.1 Phase 2, IAP-05: Pricing display accuracy — computed per-unit pack savings
- ✓ v1.1 Phase 2, IAP-06: Live purchase/restore/refund cycle — human-validated 2026-08-23 on Release build against deployed backend (balance +10 exactly once, server-persisted across relaunch, packs-era restore copy, refund demotion CR-05, refunded-pack one-pass clear WR-10)
- ✓ v1.1 Phase 2, BUILD-05: Release-configuration build compiles (`xcodebuild build -configuration Release` exit 0, re-run at verification)
- ✓ v1.1 Phase 2, AUTH-02 residual closed: live kill-check rode the validated live smoke (see Active note removed)

### Active

<!-- Carried into v1.1. Status reflects the honest per-requirement verification state at v1.0 close, not REQUIREMENTS.md's self-reported "Complete" — see Context. -->

**BUILD — carried from v1.0 Phase 1**
- [ ] BUILD-01: `PrivacyInfo.xcprivacy` passes ASC upload validation — unchecked, still blocked on D3
- [ ] BUILD-02: One canonical App Group suite ID across all 3 targets — unchecked
- [ ] BUILD-03: Info.plist consolidated onto `INFOPLIST_KEY_*` — unchecked
- [ ] BUILD-04: `xcodebuild test` executes and reports pass/fail — **unblocked 2026-08-16**: full suite (87 tests / 14 suites) ran and passed on this host with `-parallel-testing-enabled NO`; the XCTestDevices clone failure persists only for parallel-testing clones. Pin the no-parallel flag in dev docs/CI

**DATA — carried from v1.0 Phase 2**
- [ ] DATA-01: Delete actually deletes everywhere (local + CloudKit + Keychain JWT + App Group cache) — Keychain/App-Group half verified; the requirement's own defining two-device CloudKit-propagation test (02-01-PLAN.md Task 4) was deferred, never run; a genuine "CloudKit delete silently reports success on failure" bug (CR-01) was found and fixed mid-milestone but ships with zero regression test coverage

**AUTH — carried from v1.0 Phase 3 (blocked on decision D1)**
- [ ] AUTH-01: No credential ships extractable from the Release binary via `strings` — fix applied (`#if DEBUG` wrap) but the empirical `strings` confirmation is blocked by an unrelated pre-existing Release-compile failure (see Constraints)
- [x] AUTH-02: Chat entry point reflects real auth state — v1.1 Phase 01 shipped real Firebase auth; Phase 2 credit-surface landed and the live kill-check (typed 401 / stale-session behavior) rode the human-validated live smoke of 2026-08-23. Closed via v1.1 Phase 2 verification (`passed`)
- [ ] AUTH-03: Chat dismiss-mid-stream cancels SSE within one runloop, no credit charged — TDD tests exist and compile; never executed (same CoreSimulator blocker as BUILD-04)

**WIRE — carried from v1.0 Phase 4 (WIRE-01 only; WIRE-02 validated above)**
- [ ] WIRE-01: Widget renders live data on a real device, not placeholder — depends on decision D4; no v1.0 phase VERIFICATION.md exists for this


**SHIP — carried from v1.0 Phase 5 (no phase VERIFICATION.md exists)**
- [ ] SHIP-01: App Store screenshot set captured with demo mode disabled — deferred as checkpoint:human-verify, never done
- [ ] SHIP-02: Fastlane `release` lane matches actual readiness (metadata-only upload)
- [ ] SHIP-03: ASC privacy questionnaire answered per D3 — blocked on D3, unchecked

**A11Y — carried from v1.0 Phase 5 (no phase VERIFICATION.md exists)**
- [ ] A11Y-01: Sub-44pt touch targets fixed
- [ ] A11Y-02: Color-contrast fixes
- [ ] A11Y-03: Reduce Motion guards added
- [ ] A11Y-04: Dynamic Type adopted app-wide
- [ ] A11Y-05: Orphaned redesign views deleted

**NEW — surfaced during v1.0 close, not in the original remediation plan**
- [ ] TEST-01 (new): This development host's CoreSimulator cannot complete an `xcodebuild test` launch session — reproduced across every phase's verification attempt this milestone (4+ independent occurrences). Needs a working CI runner or a different host before any of BUILD-04/AUTH-03/DATA-01's test-execution claims can be closed.
- [ ] DATA-04 (new): Add a regression test for CR-01 (CloudKit batch-delete failure propagation) — the fix is correct by code inspection but has zero automated coverage; requires a new test seam below `CloudKitResetServiceProtocol`.

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
- **v1.0 Verification Reality Check** (added at milestone close, 2026-08-12): v1.0 was closed with `override_closeout` — 5/6 phases un-verified or partially verified, 9/26 requirements still unchecked. Only Phase 1.1 (SwiftData migration safety) has a `passed` verification. Phase 1 verification is `gaps_found`; Phase 2 (this session, after 3 code-review/fix rounds that found and fixed a genuine data-integrity bug) is `human_needed` with 3 pending UAT items; Phases 3/4/5 were never formally verified at all — their REQUIREMENTS.md "Complete" marks are self-reported by SUMMARY.md, not independently confirmed. Treat every "Complete" mark in the archived `milestones/v1.0-REQUIREMENTS.md` for Phases 3-5 as **unverified until re-checked**, not as ground truth. Full detail: `.planning/v1.0-MILESTONE-AUDIT.md` (archived) and `02-VERIFICATION.md` (archived under `milestones/v1.0-phases/`).

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
| Replace the initially-scoped "test infra only" milestone with the full 7-phase App Store remediation plan | Discovered mid-setup that `plans/0808-2042-appstore-submission-remediation/plan.md` already exists — same-day, more thorough (65 findings vs. 1 KANBAN blocker), decision-gated, and ready to execute. Running a narrower parallel GSD track would duplicate/conflict on shared files (StoreKitService, SyncManager, PrivacyInfo.xcprivacy). User confirmed the replacement after reviewing the trade-off. | ✓ Good — plan executed across 6 phases |
| REQ-IDs map directly to the existing plan's phases rather than re-deriving requirements independently | The plan is already audit-grounded with file-level specificity; re-deriving from scratch would be lower-fidelity and duplicate work already done today | ✓ Good |
| D1–D4 (and the 2 non-blocking product questions) are deferred to `/gsd-discuss-phase` for the phases they gate, not resolved during project init | These are product decisions with real trade-offs (e.g., D1 affects submission date directly); premature resolution during setup risks a wrong call made under time pressure | ⚠️ Revisit — D1/D2/D3/D4 all remained open through v1.0 close; carry into v1.1 discuss-phase gates |
| Roadmap phase mode set to Horizontal Layers (`standard`), not the auto-mode default Vertical MVP | This is bug-fix/integration remediation across build config, data, auth, wiring, IAP, listing, and accessibility — not new user-facing feature slices. MVP/SPIDR framing doesn't fit; horizontal phases matching the plan's own structure do. | ✓ Good |
| Granularity: Coarse (3–5 phases) — set before the scope pivot, kept after | Still fits: the roadmapper may consolidate the plan's 7 phases toward the coarse end (e.g., Phase 6+7 are both explicitly parallelizable/non-blocking) without losing the plan's substance | ✓ Good — 7 phases consolidated to 6 (5 + a mid-milestone insert, 01.1) |
| v1.0 closed via `override_closeout` rather than blocking on full verification | 5/6 phases lacked a `passed` verification at close time; user explicitly chose to ship with gaps recorded as tech debt rather than block indefinitely on verification work (2 real devices, a CI host, test-seam design) this session couldn't perform | ⚠️ Revisit — re-verify Phases 3/4/5 and close Phase 02's 3 UAT items early in v1.1 |
| Phase 02's code review ran 3 rounds instead of 1 — each re-review found something the prior fix missed | Standard-depth review + fix is not exhaustive on data-integrity-critical code; a genuine "CloudKit delete reports success on failure" bug (CR-01) surfaced only on the 3rd pass | ✓ Good — process worked as designed (re-review after fix caught real regressions), but signals this subsystem specifically needs deeper review depth or dedicated test-seam work before being trusted |
| v1.1 Phase 01 executed directly on `main` (milestone branch `gsd/v1.1-backend-api-migration` never created) | Prior-session context exhaustion left work half-committed; adopting + committing on `main` was the pragmatic resume path; repo is now 27+ commits ahead of origin | ⚠️ Revisit — at Phase 02 start: create the milestone branch going forward or accept `main`; push before starting Phase 2 |
| D1 (ship real auth vs. stay gated off) resolved by execution — v1.1 Phase 01 shipped real Firebase auth | Gap-closure plan 01-04 made the Google flow user-reachable and UAT-verified it; staying gated off would have shipped dead code | ✓ Good |
| Test invocations pinned to `-parallel-testing-enabled NO` on this host | Parallel-testing clones fail to prepare (`No matching device ... in XCTestDevices`, Mach -308); disabling clones is the reliable workaround — suite runs green in ~60s | ✓ Good — codify in dev docs/CI |
| Plan 01-04 adopted prior-session uncommitted work instead of re-executing | Tasks 1-2 were fully implemented matching the plan; verification (build + 4/4 targeted + 87 full-suite tests) confirmed quality before committing per task | ✓ Good — safe-resume gate worked as designed |
| v1.1 Phase 2 DEC-1/DEC-2: monetization = credits (50 free/mo, free-first consumption) + consumable packs + premium tier for unlimited chat; subscriptions demoted to premium-until entitlement | Usage-based pricing fits an AI-coaching chat product better than subscription-only; server-authoritative balance removes client arithmetic entirely | ✓ Good — live money path human-validated 2026-08-23 |
| Purchased credits in a separate `purchased_credits` bucket (CHECK ≥ 0); `total_credits` stays the immutable free allotment; API contract preserved via derived-total SQL alias | Monthly reset must restore free allotment without clawing back paid credits; alias keeps iOS decode unchanged | ✓ Good — CR-01 closed, test-pinned |
| Refund policy split per route: revoked subscription JWS on /premium/verify = demotion signal (replay-safe `least(premium_until, revocationDate)`); /redeem keeps absolute revoked rejection; no clawback of granted pack credits | Refunds must demote server-side premium without double-grant risk; pack clawback would need ledger reversal complexity for marginal value | ✓ Good — 6-case demotion suite green; sandbox refund validated CR-05 |
| WR-10: refunded pack finished with zero redemption attempts on both entry points (purchase + updates listener) | A revoked pack can never grant credits; finishing it clears the queue so it isn't redelivered forever | ✓ Good — both flow tests green |

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
*Last updated: 2026-08-23 after v1.1 Phase 02 close (credits system + IAP transition; verification passed 29/29, live money-path smoke + visual inspection human-validated)*

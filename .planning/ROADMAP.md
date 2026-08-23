# Roadmap: StressMonitor

## Milestones

- ✅ **v1.0 App Store Submission Remediation** — Phases 1, 1.1, 2, 3, 4, 5 (closed 2026-08-12, `override_closeout` — see `.planning/milestones/v1.0-ROADMAP.md` and PROJECT.md's "v1.0 Verification Reality Check")
- 🔄 **v1.1 Backend API Migration** — Migrate iOS app from Supabase to standalone Deno/Hono backend (stress-api.dropitx.site). Firebase Auth + 11 endpoints + credits monetization.

## Phases

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

### v1.1 Backend API Migration

- [x] **Phase 1: Firebase Auth + API Client + Chat Migration** — Add FirebaseAuth SDK (Anonymous + Google Sign-In), build StressAPIClient, migrate /chat to new backend SSE protocol (terminal metadata event), config migration (remove Supabase, add Firebase + API base URL). Blocks Phase 2 and 3. (completed 2026-08-16)
- [x] **Phase 2: Credits System + IAP Transition** — Integrate /credits API, transition StoreKit from subscription to consumable credit packs, credits-gated chat access (402 INSUFFICIENT_CREDITS → paywall), new paywall UX with balance display. (completed 2026-08-23)
- [ ] **Phase 3: Sessions, Preferences, Quick Actions + Cleanup** — Integrate /sessions (server-side chat history), /preferences sync, /quick-actions, remove all Supabase remnants, final integration testing.

#### Phase 1: Firebase Auth + API Client + Chat Migration

**Goal:** Add FirebaseAuth SDK (Anonymous + Google Sign-In), build StressAPIClient, migrate /chat to new backend SSE protocol (terminal metadata event), config migration (remove Supabase, add Firebase + API base URL). Blocks Phase 2 and 3.
**Depends on:** Nothing (foundational)

Plans:

- [x] 01-01-PLAN.md
- [x] 01-04-PLAN.md

4/4 plans executed

- [x] 01-02-PLAN.md — Google Sign-In upgrade path + Supabase source removal (D-04) + DataDeleterService rewire
- [x] 01-03-PLAN.md — TDD test coverage for StressAPIConfig, StressAPIClient, FirebaseAuthService

#### Phase 2: Credits System + IAP Transition

**Goal:** Integrate /credits API, transition StoreKit from subscription to consumable credit packs, credits-gated chat access (402 INSUFFICIENT_CREDITS → paywall), new paywall UX with balance display.
**Depends on:** Phase 1 (auth + API client)
**Plans:** 8/8 plans complete

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Monetization decision gates (DEC-1/DEC-2) + orphaned-suite repair + CR-01 closure + credits tracer (402 → paywall → live balance)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — Backend POST /credits/redeem: Apple JWS verification, idempotent 'purchase' ledger grants (cross-repo, TDD)
- [x] 02-03-PLAN.md — StoreKit consumable packs + deferred-grant purchase flow (redeem → finish) + Release-build proof (BUILD-05)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-04-PLAN.md — Packs-era paywall UX + balance surfaces (DEC-2 placements) + live money-path verification

**Gap closure** *(from 02-VERIFICATION: 20/26, gaps CR-01..CR-04)*

- [x] 02-05-PLAN.md — CR-04 gap: pack product-ID build settings (both configurations) + verified Info.plist delivery + re-enabled live catalog suite (wave 1, iOS)
- [x] 02-06-PLAN.md — CR-01 gap: purchased_credits schema separation, free-first consumption, reset preservation (wave 1, cross-repo TDD)
- [x] 02-07-PLAN.md — CR-02+CR-03 gap: revocation/expiry rejection at verify, effective premium at live gates, iOS guard-before-sync (wave 2, after 02-06 — shared credits.ts; cross-repo TDD)
- [x] 02-08-PLAN.md — CR-05/WR-10 review gap (cycle 2): revocation as premium demotion signal on /premium/verify (replay-safe least(), plan_type flip) + iOS revoked-JWS demotion post + revoked-pack finish-without-redeem loop break (wave 1, cross-repo TDD)

**Waves:** 1: 02-01 → 2: 02-02, 02-03 (parallel, contract-pinned) → 3: 02-04 → gap closure 1: 02-05, 02-06 (parallel) → gap closure 2: 02-07 → gap closure 3: 02-08

#### Phase 3: Sessions, Preferences, Quick Actions + Cleanup

**Depends on:** Phase 1 (auth + API client)
**Plans:** 5/5 plans executed (serialized waves — every plan registers test files in project.pbxproj)

Plans:
**Wave 1**

- [x] 03-01-PLAN.md — Sessions tracer: titled session creation (POST /sessions) + history restore (GET /sessions/{id}/messages) end-to-end, 404-tolerant (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-02-PLAN.md — PreferencesService + GET/PUT /preferences pair + CR-02 trend fix + Settings AI Coach section (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-03-PLAN.md — Server-driven chips (GET /quick-actions, fallback swap on the live surface) + prefs-fed payload call site + dead-code cutover (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 03-04-PLAN.md — Factory-reset server-session wipe (ServerSessionWiping seam) + Supabase remnants + backend metering issue (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 03-05-PLAN.md — Milestone integration gate: full suite + Release build + backend deno suite (postgres 5433 restart) + 03-UAT.md (wave 5)

Waves: 1: 03-01 → 2: 03-02 → 3: 03-03 → 4: 03-04 → 5: 03-05 (pbxproj-registration serialization; source deps: 03-03 ⊂ {03-01, 03-02}, 03-04 ⊂ {03-01}, 03-05 ⊂ all)

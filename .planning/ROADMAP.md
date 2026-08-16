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
- [ ] **Phase 2: Credits System + IAP Transition** — Integrate /credits API, transition StoreKit from subscription to consumable credit packs, credits-gated chat access (402 INSUFFICIENT_CREDITS → paywall), new paywall UX with balance display.
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

#### Phase 3: Sessions, Preferences, Quick Actions + Cleanup

**Goal:** Integrate /sessions (server-side chat history), /preferences sync, /quick-actions, remove all Supabase remnants, final integration testing.
**Depends on:** Phase 1 (auth + API client)

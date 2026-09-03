# Milestones

## TestFlight Release 1.0.0 build 13 (2026-09-03) — post-v1.1 release record, not a GSD milestone

**Shipped:** app `stress.ai.com` (ASC 6778478266), version **1.0.0 build 13** (buildId `7e58956b-0f13-4dcb-beaf-f00dec3ce512`) — built from HEAD `fed4b6b`, processingState VALID, external **BETA_APPROVED**, attached to groups **Qa** (internal, all-builds) and **Release-1.0.0** (external). What-to-Test notes attached (en-US). Executed outside GSD phases (archive → export → entitlements verify → upload → groups → notes → beta review); full detail in `.planning/HANDOFF.json` and `.planning/.continue-here.md`.

- Build 12 (unsigned-archive + manual export path) shipped with **no entitlements blob** on app/watch/widget despite passing strict codesign verify and ASC processing — pulled from Release-1.0.0 and expired. Mitigation now codified: entitlements dump per bundle before every publish; signed archives from dual-cert profiles only.
- Signing state changed: the 3 match AppStore profiles recreated dual-cert (WTV47CUC2N + XPT2DHR688). CI `fastlane match` readonly validation against them still pending (run `setup_match` once if rejected).
- Working tree carries an uncommitted SPM-proxy migration that cannot archive (no Firebase proxy products; GoogleSignIn product-name collision) — build 13 was cut from HEAD around it; snapshot at `.asc/backup/spm-migration/`.
- Unblocks the pending Phase 03 post-merge drift re-test: its 5 UAT scenarios (`03-UAT.md`) now run against a live, approved TestFlight build.

---

## v1.1 Backend API Migration (Shipped: 2026-08-24)

**Phases completed:** 3 phases, 17 plans, 25 tasks · **Closeout:** `verified_closeout` (audit: 21/21 requirements, 3/3 phases, 7/7 integration, 4/4 E2E flows, 0 gaps; UAT 9/9 human-validated; SECURITY.md all phases, threats_open 0) · **Stats:** 164 commits, 197 files, +20,611/−1,160, 12 days (2026-08-12 → 2026-08-23)

**Key accomplishments:**

- Added `LLMServiceError.insufficientCredits` (D-07, HTTP 402 mapping) and `SSEMetadata.quickActions` (D-05, terminal metadata event). RED tests written first in Swift Testing (`SSEParserTests`, `LLMServiceErrorTests`), then minimal source-additive implementation.
- Added `StressAPIConfigTests` (10 tests pinning D-03: Info.plist > env > UserDefaults > fallback precedence, empty/placeholder fallthrough, endpoint URL derivation) and `StressAPIClientTests` (11 tests pinning Bearer token injection, Content-Type, body attachment, getHealth no-auth via URLProtocol capture, and the 402 -> insufficientCredits / 401 -> unavailable / 429 -> rateLimited mapping table). Includes `MockAuthService` (test-target-pinned, T-03-01 mitigation) and `RequestCaptureURLProtocol` stub. RED failed on the missing `resolveBaseURL` seam; GREEN exposed `StressAPIConfig.resolveBaseURL` (delegating from the static let) and flipped `StressLLMService.mapHTTPError` from private to internal.
- Firebase Auth (Anonymous at launch + Google Sign-In with anonymous-account linking) + `StressAPIClient` with centralized Bearer injection; chat migrated to the backend SSE protocol with terminal metadata (402 → insufficient-credits); Supabase fully removed from source and config
- Credits monetization end-to-end: `/credits` integration, StoreKit subscription → consumable credit packs, 402 INSUFFICIENT_CREDITS → outOfCredits paywall, balance surfaces (chat pill, paywall header, Settings); live money path human-validated on a Release build against the deployed backend 2026-08-23
- Revenue-path hardening: Apple JWS server verification (`@apple/app-store-server-library` 3.1.0, embedded Apple Root CAs), idempotent grants keyed on transaction id + purchase ledger, free-first consumption with `purchased_credits` bucket (monthly reset preserves paid credits — CR-01), refund demotion + WR-10 redelivery-loop break
- Credit-pack product IDs resolve from Bundle.main in both configurations (CR-04) — re-enabled live catalog suite green 6/6 as the empirical delivery proof
- Server-backed chat: titled session creation ordered before first /chat, cross-relaunch history restore (no duplication, 404-tolerant), preferences round-trip shaping the coach's system prompt (en/vi × 3 styles), server-driven quick-action chips with instant local fallback — taps credit-metered, unmetered POST route grep-gated
- Factory reset wipes every server session (paginated re-query wipe, auth-skip classification) before local deletion — "delete actually deletes everywhere" now true server-side too (live-verified with pre-reset token)
- Credit-pack product IDs now resolve in real builds — build settings in both app-target configurations, literal STOREKIT_* keys in the merged Info.plist file, and the re-enabled hosted live-catalog suite green 6/6 as the empirical Bundle.main delivery proof.
- Separated purchased pack credits into their own `purchased_credits` balance with free-first consumption and a usage-only monthly reset, preserving the GET /credits response contract byte-for-byte via a derived-total SQL projection.
- Closed the refund-abuse and expiry-drift chain in both layers: revoked/expired Apple JWS are rejected at the one verify seam both credit endpoints share (and never posted by iOS — the guard now precedes the entitlement sync), and premium expiry is enforced at the live gates (deductCredit + chat 402) instead of only the monthly cron.
- Revocation became a demotion signal instead of a rejection: /credits/premium/verify shortens premium_until to the refund date under a replay-safe guard (while /credits/redeem keeps absolute revoked rejection), iOS delivers that signal before finish, and a refunded pack now clears the StoreKit queue in one pass with zero redemption attempts.
- Server-authoritative chat sessions: titled POST /sessions creation riding the first /chat, GET /sessions/{id}/messages restore on sheet open, 404-tolerant dangling-id recovery — all URLProtocol-pinned with the Phase-2 chat fence green
- UserPreferences DTO + StressAPIClient+Preferences + PreferencesService (seed-once, optimistic, revert-on-failure) + the Settings AI Coach section, with the deferred CR-02 trend inversion fixed in the same builder — all URLProtocol-pinned and the Phase-2 chat fence green
- Server-driven quick-action chips on the live chat surface: instant local fallback swapped by GET /quick-actions (context-query-pinned), taps resolving prompts through a verbatim backend-table mirror into the credit-metered /chat path, the payload now speaking PreferencesService's language/style, and the dead chips plumbing fully cut over — Phase-2 fence green
- Factory reset now deletes every server chat session (paginated wipe with auth-skip classification) before the local wipe, clears stressChatSessionId unconditionally, and the two locked Supabase remnants are gone — with the backend metering gap filed as stress-app-be#2
- Full v1.1 integration matrix green — backend 29 tests/100 steps on a recreated 5433 postgres, iOS full suite 209 passed with only the accepted WINDOWS.md #8 crash-family failures, Release build exit 0, every grep gate clean — plus the five-scenario live-backend 03-UAT.md, and one named gap: order-dependent URLProtocol stub pollution unmasked by a crash-free suite ordering (ledger #12)

---

## v1.0 App Store Submission Remediation (Shipped: 2026-08-12)

**Phases completed:** 6 phases, 11 plans, 29 tasks

**Key accomplishments:**

- Wired the widget extension's App Group entitlement (closing a live fatalError risk), completed per-bundle Privacy Manifest disclosure across all three compiled targets, and deleted the orphaned top-level Info.plist — three concrete, verified gaps closed against an already-mostly-correct uncommitted working tree.
- Widget data resolves to fresh/stale/empty via a unit-tested `WidgetDataState` resolver instead of a conflated `isPlaceholder` bool, and Small/Medium/Large widget views now dim and relabel stale data per the UI-SPEC contract.
- A `checkpoint:human-action` task: the user attests that App Groups (+ iCloud) capabilities are now enabled for all three App IDs and that `bundle exec fastlane setup_match` regenerated the cached App Store profiles; this agent's own attempt to independently confirm that via `fastlane match appstore --readonly` could not run to completion in this execution environment (no Match/App Store Connect credentials present here), so the record rests on user attestation plus a passing simulator-build regression check.
- Corrected 7 docs (CLAUDE.md, 4 docs/ architecture files, and the EN+VI privacy policy) to disclose the actual `/chat` payload — derived stress score/category/confidence/trend plus per-factor HRV/heart-rate/sleep/activity/recovery scores, sent under a Bearer-JWT-authenticated session — replacing the false "anonymized"/"never leaves the device" claim per D-01.
- Non-fatal SwiftData `ModelContainer` recovery — the app no longer crashes via `fatalError` on any prior store schema state; migrates or recovers cleanly instead.
- `DataManageView.performDeleteAll` deleted only SwiftData + CloudKit records, leaving the Supabase JWT in Keychain and the App Group widget cache intact — a "deleted" user stayed signed in and the widget kept showing their data. Fixed and consolidated onto a single `DataDeleterService`; 3 code-review rounds this session additionally found and fixed a genuine "reports success but doesn't actually delete" CloudKit batch-delete bug.
- AI Chat honestly gated off for v1 via a compile-time `ChatAvailability` flag, the leaked guest JWT dead-stripped from Release by an `#if DEBUG` wrap, and the AUTH-03 streaming lifecycle pinned by new TDD tests.
- IAP purchase flow fixed for Release-config compilation and wired to real product IDs; StoreKit entitlement display honesty and one-time-permanent character unlocks addressed.

**Known gaps carried into v1.1** (see `.planning/milestones/v1.0-phases/` for full artifacts):

- Only 1/6 phases (01.1) has a `passed` verification; Phase 01 verification is `gaps_found`, Phase 02 is `human_needed` (3 pending UAT items — two-device CloudKit sync test, `DataDeletionConsolidationTests` execution, CR-01 regression test), Phases 03/04/05 were never formally verified.
- 9/26 requirements unchecked in the archived v1.0-REQUIREMENTS.md, including BUILD-01/02/03, AUTH-01/02/03, WIRE-01, SHIP-01/03.
- `01-06-PLAN.md` in Phase 1 was never executed.
- Pre-existing Release-build compile blocker: `StoreKitServiceEnvironment.swift:12` references `MockStoreKitService` unconditionally outside `#if DEBUG` — every Release build fails to compile until fixed.
- This host's CoreSimulator cannot complete an `xcodebuild test` launch session (`No matching device ... in XCTestDevices`) — reproduced across every phase's verification session; all test coverage claims in this milestone rest on `build-for-testing` compile success only, not executed pass/fail.

---

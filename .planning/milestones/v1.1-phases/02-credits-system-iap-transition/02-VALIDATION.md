---
phase: 2
slug: credits-system-iap-transition
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-16
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Filled at revision time from the final plan set (02-01 … 02-04). Values mirror 02-RESEARCH.md "Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|-------|-------|
| **Framework** | iOS: Swift Testing (`import Testing`) under XCTest host via `xcodebuild`. Backend (cross-repo stress-app-be): Deno built-in test runner via `deno task test` |
| **Config file** | iOS: none — target membership IS the config (explicit `PBXSourcesBuildPhase`; Pitfall 7). Backend: `stress-app-be/deno.json` tasks |
| **Quick run command** | `cd StressMonitor && xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/StressMonitor-gsfjxdxaciivyygrqgnuxctytuxw" -only-testing:StressMonitorTests/<Suite> -parallel-testing-enabled NO` |
| **Full suite command** | Same without `-only-testing` (baseline: 87 tests / 14 suites green, 2026-08-16 per 01-04-SUMMARY) |
| **Estimated runtime** | Full iOS suite ~2–4 min on booted iPhone 17; targeted suite < 60 s; backend `deno task test` < 10 s |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `-only-testing` suite(s) (or `deno task test <file>` for backend tasks), always with `-parallel-testing-enabled NO`
- **After every plan wave:** Run the full suite command (iOS) and full `deno task test` (backend) — exit 0 required
- **Before `$gsd-verify-work`:** Full suite green + Release build green + live-backend smoke (balance fetch + one 402-triggered chat + one sandbox purchase, 02-04 Task 3)
- **Max feedback latency:** one targeted-suite run (< 60 s iOS; < 10 s backend)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | DEC-1 (research Q1/Q2/Q5) | T-2-03 | Premium-guard vs out-of-credits semantics fixed before any wiring | decision checkpoint (blocking) | — (resume-signal: option + amendments recorded verbatim) | N/A | ⬜ pending |
| 2-01-02 | 01 | 1 | DEC-2 (research Q3/Q4) | — | N/A | decision checkpoint (blocking) | — (resume-signal: pack option + placement + concrete prices) | N/A | ⬜ pending |
| 2-01-03 | 01 | 1 | derived-CR-02/03 substrate | — | N/A | unit (repaired suites) | orphan-count check + `-only-testing` SSEParserTests/LLMServiceErrorTests/ChatLifecycleTests/ChatAvailabilityTests | ❌ → repaired by this task | ⬜ pending |
| 2-01-04 | 01 | 1 | derived-CR-02/03 (CR-01 closure) | — | N/A (pure refactor) | unit | `-only-testing:StressMonitorTests/ChatLifecycleTests` + side-channel grep | ✅ (orphaned → repaired in 2-01-03) | ⬜ pending |
| 2-01-05 | 01 | 1 | derived-CR-01/02/03/04, AUTH-02 | T-2-01 / T-2-02 | 401/500 → typed errors; premium sentinel never rendered raw; no client-side arithmetic | unit (tracer) | `-only-testing` CreditServiceTests + StressAPIClientCreditsTests + ChatLifecycleTests, then full suite | ❌ W0 (created here) | ⬜ pending |
| 2-02-01 | 02 | 2 | — (package gate) | T-2-SC | Apple JWS library legitimacy verified before any install | human checkpoint (blocking-human) | — (resume-signal: "verified: <pkg>@<ver>" or fallback) | N/A | ⬜ pending |
| 2-02-02 | 02 | 2 | derived-CR-07 (idempotent store) | T-2-05 | PK-conflict idempotency; single-transaction atomicity | unit (Deno) | `deno task test src/lib/credits.test.ts` + `deno task check` | ❌ W0 (created here) | ⬜ pending |
| 2-02-03 | 02 | 2 | derived-CR-07 (JWS seam) | T-2-05 / T-2-06 | No hand-rolled X.509/JWS crypto; single-module seam | unit (Deno) | `deno task test src/lib/iap.test.ts` + `deno task check` + `deno task lint` | ❌ W0 (created here) | ⬜ pending |
| 2-02-04 | 02 | 2 | derived-CR-07 (route), IAP-06 contract | T-2-05/06/07/08 | uid from auth middleware only; client-asserted amounts ignored; forged body ignored | unit (Deno) | full `deno task test` + `check` + `lint` + `fmt:check` | ❌ W0 (created here) | ⬜ pending |
| 2-03-01 | 02 | 2 | IAP-01, IAP-05 | — | N/A | unit | `-only-testing:StressMonitorTests/StoreKitProductCatalogTests` + .storekit JSON parse gate | ✅ (compiled suite extended) | ⬜ pending |
| 2-03-02 | 02 | 2 | IAP-02, IAP-03, derived-CR-05 | T-2-09 / T-2-10 / T-2-11 | `finish()` only after server ack; unverified transactions never grant; packs never flip PremiumState | unit | `-only-testing` CreditPurchaseFlowTests + StressAPIClientCreditsTests + PremiumViewModelTests + restore-copy grep | ❌ W0 (created here) | ⬜ pending |
| 2-03-03 | 02 | 2 | BUILD-05, IAP-03 | — | N/A | build proof | `xcodebuild build -configuration Release …` + full suite | N/A | ⬜ pending |
| 2-04-01 | 04 | 3 | IAP-04, IAP-05, derived-CR-06 | T-2-14 | Restore copy never implies consumables recoverable; sentinel-literal count 0 | unit | `-only-testing` CreditsViewModelTests + PremiumViewModelTests + `999999` grep | ❌ W0 (created here) | ⬜ pending |
| 2-04-02 | 04 | 3 | AUTH-02, derived-CR-06 | T-2-13 / T-2-15 | nil balance renders neutral placeholder, never authoritative zero; single shared formatter | unit + build | `-only-testing:StressMonitorTests/CreditsViewModelTests` + `xcodebuild build` | ❌ W0 (created here) | ⬜ pending |
| 2-04-03 | 04 | 3 | IAP-06 (live), AUTH-02 residual | T-2-13 / T-2-15 | Session kill → typed unavailable state, no phantom balance | integration + human | full suite + Release build + `curl /health` + human-check (5 live-smoke steps) | N/A (live) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `StressMonitorTests/CreditServiceTests.swift` — derived-CR-04 (+ 4-line pbxproj registration) — created by 02-01 Task 5
- [ ] `StressMonitorTests/StressAPIClientCreditsTests.swift` — derived-CR-01 — created by 02-01 Task 5
- [ ] `StressMonitorTests/CreditPurchaseFlowTests.swift` — derived-CR-05 — created by 02-03 Task 2
- [ ] `StressMonitorTests/CreditsViewModelTests.swift` — derived-CR-06 — created by 02-04 Tasks 1–2
- [ ] Repair orphaned `ChatLifecycleTests` / `SSEParserTests` / `LLMServiceErrorTests` (+ 4 more) into the Sources phase — 02-01 Task 3
- [ ] Consumable products in `StressMonitorTests/StressMonitorProducts.storekit` — 02-03 Task 1 (no framework install needed)
- [ ] Backend: `redeemCredits` cases in `credits.test.ts`, new `iap.test.ts`, POST-route cases in `credits.test.ts` — 02-02 Tasks 2–4

*No framework install required — existing infrastructure (Swift Testing via xcodebuild; Deno test) covers all phase requirements once the above files exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Monetization architecture choice (coexist / retire / synced premium) | DEC-1 | One-way-door ASC + security implications; human product decision | 02-01 Task 1 checkpoint: select option-a/b/c, record verbatim |
| Pack SKUs, prices, balance placement | DEC-2 | ASC filing is user-owned with review latency; pricing is a business call | 02-01 Task 2 checkpoint: select packs-2/3 + placement-a/b + concrete prices |
| Apple JWS verification library legitimacy | derived-CR-07 | Package-legitimacy gates are never auto-approvable | 02-02 Task 1: verify publisher/repo on npmjs.com, type "verified: …" |
| Live sandbox purchase → server grant → visible balance (5 smoke steps) | IAP-06 | Needs deployed backend + ASC sandbox tester + App Store UI | 02-04 Task 3 human-check: walk steps 1–5 on simulator, confirm single increment + persisted balance |
| Paywall/balance UI design-system compliance | derived-CR-06 | Visual: dual coding, dynamic type, 44pt targets | End-of-phase review (02-04 Task 3 sweep screenshots) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (set by validate-phase)

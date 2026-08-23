---
phase: 02
slug: credits-system-iap-transition
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-23
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
>
> Register source: `<threat_model>` blocks in 02-01…02-08-PLAN.md (authored at plan time).
> Closure evidence: 02-VERIFICATION.md (29/29 must-haves, status: passed), SUMMARY threat
> flags, L1 grep checks in this repo, and the human money-path smoke recorded in 02-UAT.md.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| client → backend /credits | Firebase ID token crosses; balance JSON returns | Bearer token (credential) / balance integers (low sensitivity) |
| client → POST /credits/redeem | Untrusted body (JWS string + attacker-added fields); uid from verified token only | Apple-signed JWS (integrity-critical) |
| Apple → server (via JWS) | Apple-signed transaction payload; signature chain verified before any write | Signed purchase entitlement |
| backend → client balance values | Server-authoritative numbers rendered as-is (display-only cache, never a gate) | Balance JSON (advisory display) |
| StoreKit → app | Apple-signed purchase results; only `.verified` payloads may grant | VerificationResult (integrity-critical) |
| app → backend /credits/premium/verify | Bidirectional: valid JWS activates, revoked JWS demotes premium | JWS + effective entitlement |
| Apple payment → server balance | Real money becomes an integer balance; arithmetic/resets convert to paid-value loss | Credit ledger rows |
| concurrent requests → user_credits row | Two simultaneous chats / chat + redeem racing on one row | DB row under FOR UPDATE |
| build config → app binary | Product IDs flow from build config into shipped Info.plist (CR-04 defect class) | Public product identifiers |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-2-01 | Tampering | CreditService cached balance | medium | accept | Display-only cache; server sole authority; no client decrement arithmetic (CreditServiceTests) | closed (accepted) |
| T-2-02 | Info Disclosure / Spoofing | getBalance on stale session | low | mitigate | Typed 401 error (derived-CR-01 test); foreground refresh doubles as AUTH-02 session probe | closed |
| T-2-03 | Elevation of Privilege | PaywallController guard vs out-of-credits reason | medium | mitigate | DEC-1 semantics pinned by ChatLifecycleTests — reason reaches presentation on every branch | closed |
| T-2-04 | Repudiation | Balance convergence from metadata | low | accept | Metadata advisory only; GET /credits re-syncs on foreground | closed (accepted) |
| T-2-SC | Tampering | deno.json package install | high | mitigate | npmjs legitimacy human checkpoint passed at execution; package matched Apple's official repo before use | closed |
| T-2-05 | Tampering / Repudiation | forged or replayed JWS | high | mitigate | Apple signature-chain verification + PRIMARY-KEY idempotency + one 'purchase' ledger row per grant (VERIFICATION truths 7–10, tests green) | closed |
| T-2-06 | Tampering | client-asserted grant amount | high | mitigate | Amount derives only from server-side PACK_CREDITS by verified productId; forged-amount-ignored test green | closed |
| T-2-07 | Elevation of Privilege | grant bound to wrong user | high | mitigate | uid from auth middleware only; body-uid never read; cross-user grant impossible by construction | closed |
| T-2-08 | DoS | redemption flood / junk JWS spam | medium | accept | Auth-gated; PK-conflict short-circuits replays; bounded verify cost; rate-limit hardening noted as residual | closed (accepted) |
| T-2-09 | Repudiation / loss of funds | finish() before server ack | high | mitigate | Deferred-grant ordering (redeem → ack → finish) implemented and pinned by CreditPurchaseFlowTests; Transaction.updates redelivery is the retry path | closed |
| T-2-10 | Tampering | granting on unverified transaction | high | mitigate | `checkVerified` throws on unverified; on pack path before any redeem (StoreKitService.swift:158,189,439) | closed |
| T-2-11 | Tampering | client-minted grants | high | mitigate | Client never writes balance — applies server responses only; server independently verifies JWS | closed |
| T-2-12 | DoS (user-level) | redeem failure blocks finish forever | medium | accept | Unfinished transactions retry on launch; server idempotency makes retries safe | closed (accepted) |
| T-2-13 | Spoofing | stale balance displayed as current | low | accept | Three-source convergence + foreground refresh; nil renders neutral placeholder, never authoritative zero (pinned by test) | closed (accepted) |
| T-2-14 | Tampering / deception | restore copy implying consumables recoverable | medium | mitigate | Packs-era copy; pack-mode success view omits restore; verified in live smoke step 5 (02-04 SUMMARY register check) | closed |
| T-2-15 | Info Disclosure | balance for wrong account after session change | medium | mitigate | Foreground refresh as session probe; typed 401; placeholder rendering (02-04 SUMMARY; session-kill check in smoke) | closed |
| T-2-501 | Tampering | Info.plist product-ID keys | low | mitigate | Bundle.main resolution + re-enabled StoreKitProductCatalogLiveTests fail the gate on drift (CR-04 closure) | closed |
| T-2-502 | DoS (availability) | Pack purchase path | high | mitigate | CR-04 fixed: purchase(pack:) resolves real product IDs; pinned by live suite | closed |
| T-2-601 | Tampering | deductCredit purchased-bucket arithmetic | high | mitigate | Balance check precedes mutation; decrement derived inside FOR UPDATE; DB CHECK constraint backstops | closed |
| T-2-602 | DoS / Repudiation | resetMonthlyCredits destroying purchased value (CR-01) | high | mitigate | Reset touches used_credits only; cron.test.ts pins purchased_credits byte-identical across reset | closed |
| T-2-603 | Tampering | concurrent chat + redeem on one row | medium | mitigate | Both paths serialize on FOR UPDATE row lock / single-statement atomic update; one consistent snapshot | closed |
| T-2-604 | Information disclosure | derived total in GET /credits | low | accept | No new field exposed; premium_until stays internal | closed (accepted) |
| T-2-701 | Elevation of Privilege | /credits/premium/verify + /credits/redeem (refund abuse) | high | mitigate | CR-02: revocationDate throw at verify seam protects both endpoints; expired rejected before activatePremium; route tests green | closed |
| T-2-702 | Elevation of Privilege | StoreKitService.completePurchase posting revoked JWS | high | mitigate | CR-02 iOS: revoked/expired guard hoisted before sync; never posted, never granted locally; spy-based flow tests green | closed |
| T-2-703 | Elevation of Privilege | deductCredit + chat 402 gate (CR-03) | high | mitigate | Effective premium = plan_type AND (premium_until null OR > now) under FOR UPDATE lock, mirrored in chat gate; cron demoted to janitor | closed |
| T-2-704 | Tampering | revocation race between verify and grant | low | accept | Bounded by original expiry; self-heals via foreground re-verify + cron demotion; no permanent gain | closed (accepted) |
| T-2-705 | Spoofing | JWS replay by non-purchaser (no appAccountToken binding) | medium | accept | WR-01: idempotency PK caps each transaction to one grant; flagged for future phase decision | closed (accepted) |
| T-2-706 | Repudiation | audit trail of rejected transactions | low | accept | Rejections return 400 without writes; existing observability logs request id | closed (accepted) |
| T-2-801 | Spoofing | forged/foreign revoked JWS as demotion weapon | high | mitigate | Verification policy unchanged — forged JWS fails Apple signature chain → 400 no write; uid from Bearer only → self-harm, not cross-user; invalid-jws cases stay green | closed |
| T-2-802 | Tampering | replay of old revocation to shorten a NEW term | high | mitigate | `premium_until <= revoked.expiresAt` guard; +60d-annual vs revoked-monthly and replay-no-op cases pinned | closed |
| T-2-803 | Repudiation | demotion audit trail | low | accept | Demotion observable in user_credits row (dated premium_until preserved); logs carry request id | closed (accepted) |
| T-2-804 | DoS | demotion endpoint flood / idempotency-table growth | low | accept | 401-gated surface; convergent WHERE makes replays write-free; T-2-08 rate-limit residual applies | closed (accepted) |
| T-2-805 | Service degradation (WR-10) | updates-listener queue: revoked pack → infinite silent redelivery | medium | mitigate | Pack-arm revocation guard finishes without redemption POST on both entry points; finishCallCount==1 / redeemer.callCount==0 pinned | closed |
| T-2-806 | Repudiation/DoS | one-shot demotion delivery lost on POST failure | low | accept | Best-effort POST then unconditional finish; residual bounded by original term end; strictly better than pre-fix | closed (accepted) |
| T-2-03a | (flagged surface) | verifySubscription client→backend endpoint (02-03 SUMMARY threat flag, DEC-1 amendment) | medium | mitigate | Same posture as /credits/redeem: Bearer-authenticated, server independently verifies JWS, client asserts nothing; response advisory only; StressAPIClientCreditsTests green | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-02-01 | T-2-01 | Display-only balance cache; no client-side authority to poison | plan 02-01 (disposition) | 2026-08-23 |
| AR-02-02 | T-2-04 | Terminal metadata advisory-only; foreground GET /credits re-syncs | plan 02-01 (disposition) | 2026-08-23 |
| AR-02-03 | T-2-08 | Redemption flood bounded by auth gate + PK replay short-circuit; rate-limit hardening deferred | plan 02-02 (disposition) | 2026-08-23 |
| AR-02-04 | T-2-12 | Unfinished transaction redelivery is the intended retry path; server idempotency makes it safe | plan 02-03 (disposition) | 2026-08-23 |
| AR-02-05 | T-2-13 | Transient staleness acceptable; convergence + neutral placeholder remove deception risk | plan 02-04 (disposition) | 2026-08-23 |
| AR-02-06 | T-2-604 | No new field exposed in GET /credits response shape | plan 02-06 (disposition) | 2026-08-23 |
| AR-02-07 | T-2-704 | Revocation race window self-heals; bounded by original expiry — no permanent gain | plan 02-07 (disposition) | 2026-08-23 |
| AR-02-08 | T-2-705 | WR-01: JWS replay capped at one grant by idempotency PK; appAccountToken binding deferred to future phase | plan 02-07 (disposition) | 2026-08-23 |
| AR-02-09 | T-2-706 | Rejection observability via existing logs; no new ledger surface | plan 02-07 (disposition) | 2026-08-23 |
| AR-02-10 | T-2-803 | Demotion observable in user_credits row + request-id logs | plan 02-08 (disposition) | 2026-08-23 |
| AR-02-11 | T-2-804 | Replay writes are write-free; endpoint behind the same 401 gate as all /credits routes | plan 02-08 (disposition) | 2026-08-23 |
| AR-02-12 | T-2-806 | One-shot delivery loss bounded by term end; finish-on-success-only would reintroduce the WR-10 loop | plan 02-08 (disposition) | 2026-08-23 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-23 | 35 | 35 | 0 | gsd-secure-phase (L1 grep-depth, ASVS 1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-23 (short-circuit path: threats_open 0, register authored at plan time, ASVS L1 — closure evidence from 02-VERIFICATION.md passed report, SUMMARY threat flags, and in-repo greps)

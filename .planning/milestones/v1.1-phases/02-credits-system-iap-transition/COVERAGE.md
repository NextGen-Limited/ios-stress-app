# API Coverage — /credits API + StoreKit 2

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
> Produced at plan time 2026-08-16 (api-coverage detector fired on "Integrate /credits API" in the Phase 2 ROADMAP section).
> Phase 1's COVERAGE.md deferred `GET /credits` / `POST /credits` to Phase 2 — this matrix picks them up.

## Stress API backend (`https://stress-api.dropitx.site`)

| capability | decision | reason |
|---|---|---|
| `GET /credits` (balance: `{total, used, remaining, plan_type, free_reset_at}`) | INTEGRATE | Core of the phase — `CreditService.refreshBalance()` on foreground/paywall-open |
| `GET /credits?history&limit&offset` (transaction ledger) | OPT-OUT | not needed yet — no transaction-list UI in this phase; natural follow-up once paywall ships |
| `POST /credits/redeem` (NEW — server side added by plan 02-02) | INTEGRATE | Server-authoritative purchase grant; without it, purchased credits have no destination |
| `/chat` SSE terminal `metadata.credits_remaining` convergence | INTEGRATE | Balance converges from every completed chat (research Pattern 3, source (b)) |
| `/chat` HTTP 402 `INSUFFICIENT_CREDITS` | INTEGRATE | Paywall trigger (already mapped to `LLMServiceError.insufficientCredits` in Phase 1; Phase 2 adds presentation) |

## StoreKit 2 (Apple system SDK)

| capability | decision | reason |
|---|---|---|
| `Product.products(for:)` | INTEGRATE | Pack product resolution + cache (existing pattern) |
| `Product.purchase(confirmIn:)` | INTEGRATE | Pack purchase (existing iOS 18.2 scene pattern reused) |
| `VerificationResult` / `checkVerified` | INTEGRATE | Existing on-device JWS gate; reused for packs |
| `Transaction.updates` listener | INTEGRATE | Already app-scoped (IAP-02); extended to retry unfinished pack transactions |
| `Transaction.finish()` | INTEGRATE | Deferred until backend redemption ack (research Pattern 2) |
| `Transaction.currentEntitlements` | INTEGRATE | Grandfathering semantics per decision DEC-1 (plan 02-01) |
| `AppStore.sync()` (restore) | INTEGRATE | Copy rewritten for the packs era; restores subscriptions only |
| Apple `SubscriptionStoreView` / `ProductView` | OPT-OUT | not needed — custom paywall design system retained (research Alternatives Considered) |
| Offer codes / win-back offers | OPT-OUT | not needed — no ASC infrastructure for them this phase |
| App Store Server API cross-check (server→Apple REST) | OPT-OUT | not needed yet — JWS signature-chain verification only for v1; gold-tier cross-check tracked as follow-up (research "Don't Hand-Roll" table) |

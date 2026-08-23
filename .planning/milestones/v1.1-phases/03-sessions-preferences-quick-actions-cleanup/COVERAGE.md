# API Coverage — stress-app-be full surface (v1.1 close-out)

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
> Produced at plan time 2026-08-23 (api-coverage gate; Phase 3 completes milestone v1.1).
> Route surface enumerated from `stress-app-be/src/app.ts` mounts (health, docs, preferences, credits, sessions, quick-actions, chat) and each `src/routes/*.ts` read this session.

## Stress API backend (`https://stress-api.dropitx.site`)

| # | capability | decision | reason |
|---|---|---|---|
| 1 | `GET /health` | INTEGRATE | Phase 1 — `StressAPIClient.getHealth()` (config/diagnostics; verified 200 this session) |
| 2 | `POST /chat` (SSE stream + terminal metadata) | INTEGRATE | Phase 1 — streaming chat, session-persisted, credit-metered; unchanged this phase (regression-fenced only) |
| 3 | `POST /chat` SSE terminal `metadata.session_id` | INTEGRATE | Phase 1 — `StressLLMService.apply(metadata:)` persists the rolling session id (session continuity backbone for Phase 3 restore) |
| 4 | `POST /chat` SSE terminal `metadata.credits_remaining` | INTEGRATE | Phase 2 — balance convergence sink |
| 5 | `POST /chat` SSE terminal `metadata.quick_actions` | OPT-OUT (driving UI) | Parsed and stored (`SSEParser`/`apply(metadata:)`, pinned by `SSEParserTests`) but does NOT drive chip refresh — chips refresh on chat open only this phase (CONTEXT deferred idea) |
| 6 | `GET /credits` (balance) | INTEGRATE | Phase 2 — `CreditService.refreshBalance()` |
| 7 | `GET /credits?history&limit&offset` (transaction ledger) | OPT-OUT | Carried from Phase 2 COVERAGE — no transaction-list UI; natural follow-up |
| 8 | `POST /credits/redeem` | INTEGRATE | Phase 2 — server-authoritative pack grants |
| 9 | `POST /credits/premium/verify` | INTEGRATE | Phase 2 (02-07/02-08) — JWS verification + premium demotion signal |
| 10 | `GET /sessions?limit&offset` | INTEGRATE | Phase 3 — factory-reset wipe loop pages the user's sessions (`derived-SES-03`) |
| 11 | `POST /sessions` | INTEGRATE | Phase 3 — titled session creation before first chat of a new session (`derived-SES-02`) |
| 12 | `DELETE /sessions?id=` | INTEGRATE | Phase 3 — per-session delete in the factory-reset wipe; messages cascade server-side (`derived-SES-03`) |
| 13 | `GET /sessions/:id/messages` | INTEGRATE | Phase 3 — history restore on chat open for the persisted rolling session (`derived-SES-01`) |
| 14 | `GET /preferences` | INTEGRATE | Phase 3 — one-time seed at first surface (chat open / Settings onAppear); chat-relevant pair only (`derived-PREF-01`) |
| 15 | `PUT /preferences` | INTEGRATE | Phase 3 — single-field local-writer-wins updates (`language` / `coaching_style` only) (`derived-PREF-01`) |
| 16 | `GET /quick-actions` | INTEGRATE | Phase 3 — server-suggested chips at chat open with live stress context; local static set renders instantly as fallback (`derived-QA-01`) |
| 17 | `POST /quick-actions` | OPT-OUT | **Deliberately unwired per CONTEXT lock** — returns a full 512-token completion with **no `deductCredit` anywhere in the route** (verified: `quick-actions.ts:44-61`); wiring it would open an unmetered chat path bypassing the Phase 2 revenue model. Chip taps ride the existing credit-metered `/chat` path instead. Metering/gating note filed on `phuongddx/stress-app-be` (plan 03-04) — tracked as https://github.com/phuongddx/stress-app-be/issues/2; iOS grep-gate pins that no POST to this route ever appears in app sources |
| 18 | `GET /` (OpenAPI docs HTML page) | OPT-OUT | Browser-facing documentation surface, not an app capability |

## Field-level scope note (preferences)

`PUT /preferences` allowlist (`ALLOWED_FIELDS` in `preferences.ts`): `display_name`, `language`, `coaching_style`, `notification_enabled`, `stress_alert_threshold`, `theme`, `custom_settings`. iOS reads/writes **only** `language` + `coaching_style` (the chat-relevant pair). The other five fields have no iOS owner mapping this phase (CONTEXT locked scope) — they are decoded-away by Codable (GET) and never sent (PUT).

## Verdict

After Phase 3, every HTTP capability of the backend is either consumed by the app or carries a recorded OPT-OUT reason (rows 5, 7, 17, 18). The single unmetered-route exposure (row 17) is locked out client-side and tracked server-side via the backend issue.

# API Coverage — stress-app-be full surface (v1.1 close-out)

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
> Produced at plan time 2026-08-23 (api-coverage gate; Phase 3 completes milestone v1.1).
> Route surface enumerated from `stress-app-be/src/app.ts` mounts (health, docs, preferences, credits, sessions, quick-actions, chat) and each `src/routes/*.ts` read this session.

## Stress API backend (`https://stress-api.dropitx.site`)

| capability | decision | reason |
|---|---|---|
| `GET /health` | INTEGRATE | Phase 1 — `StressAPIClient.getHealth()` (config/diagnostics; verified 200) |
| `POST /chat` (SSE stream + terminal metadata) | INTEGRATE | Phase 1 — streaming chat, session-persisted, credit-metered; regression-fenced only |
| `POST /chat` SSE terminal `metadata.session_id` | INTEGRATE | Phase 1 — `StressLLMService.apply(metadata:)` persists rolling session id (restore backbone) |
| `POST /chat` SSE terminal `metadata.credits_remaining` | INTEGRATE | Phase 2 — balance convergence sink |
| `POST /chat` SSE terminal `metadata.quick_actions` | OPT-OUT | Parsed+stored (`SSEParserTests`-pinned) but does NOT drive chip refresh — chips refresh on chat open only (CONTEXT deferral) |
| `GET /credits` (balance) | INTEGRATE | Phase 2 — `CreditService.refreshBalance()` |
| `GET /credits?history&limit&offset` (ledger) | OPT-OUT | Carried from Phase 2 — no transaction-list UI; natural follow-up |
| `POST /credits/redeem` | INTEGRATE | Phase 2 — server-authoritative pack grants |
| `POST /credits/premium/verify` | INTEGRATE | Phase 2 (02-07/02-08) — JWS verification + premium demotion signal |
| `GET /sessions?limit&offset` | INTEGRATE | Phase 3 — factory-reset wipe loop pages sessions (`derived-SES-03`) |
| `POST /sessions` | INTEGRATE | Phase 3 — titled session creation before first chat of a new session (`derived-SES-02`) |
| `DELETE /sessions?id=` | INTEGRATE | Phase 3 — per-session delete in factory-reset wipe; messages cascade server-side (`derived-SES-03`) |
| `GET /sessions/:id/messages` | INTEGRATE | Phase 3 — history restore on chat open for persisted rolling session (`derived-SES-01`) |
| `GET /preferences` | INTEGRATE | Phase 3 — one-time seed at first surface; chat-relevant pair only (`derived-PREF-01`) |
| `PUT /preferences` | INTEGRATE | Phase 3 — local-writer-wins updates (`language` / `coaching_style` only) (`derived-PREF-01`) |
| `GET /quick-actions` | INTEGRATE | Phase 3 — server chips at chat open with live stress context; static fallback renders instantly (`derived-QA-01`) |
| `POST /quick-actions` | OPT-OUT | Deliberately unwired (CONTEXT lock): route has no `deductCredit` — wiring opens unmetered chat bypassing Phase 2 revenue. Chips ride metered `/chat`. BE issue #2 tracks |
| `GET /` (OpenAPI docs HTML) | OPT-OUT | Browser-facing documentation surface, not an app capability |

## Field-level scope note (preferences)

`PUT /preferences` allowlist (`ALLOWED_FIELDS` in `preferences.ts`): `display_name`, `language`, `coaching_style`, `notification_enabled`, `stress_alert_threshold`, `theme`, `custom_settings`. iOS reads/writes **only** `language` + `coaching_style` (the chat-relevant pair). The other five fields have no iOS owner mapping this phase (CONTEXT locked scope) — they are decoded-away by Codable (GET) and never sent (PUT).

## Verdict

After Phase 3, every HTTP capability of the backend is either consumed by the app or carries a recorded OPT-OUT reason (rows 5, 7, 17, 18). The single unmetered-route exposure (row 17) is locked out client-side and tracked server-side via the backend issue.

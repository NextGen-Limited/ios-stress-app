---
status: testing
phase: 03-sessions-preferences-quick-actions-cleanup
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md, COVERAGE.md]
started: 2026-08-30T21:30:00+07:00
updated: 2026-08-30T21:30:00+07:00
round: re-test 1 (post-merge drift check, built from main @ d74d6d7; round 1 = v1.1 close-out 2026-08-23, 5/5 pass, archived in .planning/milestones/v1.1-phases/)
audit_acknowledged:
  milestone: v1.2
  at: 2026-09-05
  gap_snapshot: "testing::scenarios=5"
---

# Phase 3 UAT — Live-Backend Re-Test (post-merge drift check)

Round 1 (v1.1 close-out, 2026-08-23): 5/5 scenarios passed against the deployed backend, human-validated. This round re-executes the same five scenarios to detect drift since PR #48 squash-merged into `main` (2026-08-24).

## Precheck (run once, before any scenario)

- `GET https://stress-api.dropitx.site/health` → **HTTP 200** — ✅ confirmed 2026-08-30T14:27Z (`{"status":"ok"}`)
- Backend down/stale ⇒ stop; every scenario below is invalid (03-RESEARCH T-3-19).

**Test setup:** StressMonitor on the iPhone simulator, built from **`main`** (not the retired `gsd/v1.1-backend-api-migration` branch). DEBUG is fine for scenarios 1/2/3/5 — chat, sessions, preferences, and quick-actions all hit the real backend in DEBUG. Run scenarios **in order**; Scenario 5 is destructive (factory reset) and must be last. Use one simulator install throughout so the anonymous identity (and its session history) stays constant across scenarios 1–4.

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 1
name: History restore across relaunch
expected: |
  1. Launch app, open AI Coach chat sheet, send a message longer than ~50 chars
     (e.g. "Hello coach, this is my first message and it is deliberately long enough to be truncated in a session title").
  2. Wait for the streamed reply to finish.
  3. Force-quit (app switcher → swipe away), relaunch, reopen the chat sheet.
  4. Close and reopen the chat sheet a second time.
  PASS: prior conversation renders immediately on reopen (server restore, not lost);
        second open does NOT duplicate the message list;
        server-side `GET /sessions` lists exactly ONE session titled with the
        truncated first message (two sessions for one first message = FAIL).
awaiting: user response

## Tests

### 1. History restore across relaunch — one titled session, no duplicates
expected: Send a >50-char first message, let the reply stream finish, force-quit, relaunch, reopen chat. Prior conversation renders immediately (server restore); second open does not duplicate; server-side `GET /sessions` (Bearer token, see Appendix) shows exactly ONE session titled with the truncated first message. Two sessions for one first message = FAIL (session-creation raced `/chat`).
result: [pending]
coverage: 03-05 D2 (scenario execution)

### 2. Preferences round-trip — Settings → backend → next reply
expected: Settings → AI Coach: Language → Tiếng Việt, Coaching Style → Direct. Force-quit + relaunch → pickers still show Tiếng Việt / Direct (server-seeded). Send a chat message → reply arrives in Vietnamese, direct tone. No error footnote under the AI Coach card during switches. Server-side `GET /preferences` shows `language: "vi"`, `coaching_style: "direct"`; after switching back → `"en"` / `"supportive"`.
result: [pending]
coverage: 03-02 D4 (Settings section + wiring, visual)

### 3. Chip fetch on chat open — instant fallback, server swap, metered tap
expected: Open chat sheet → chips render instantly (local fallback, no loading state). Within 1–2 s titles swap to server suggestions for current stress context. Tap a chip → normal chat path: credit-metered streamed response, balance decreases by one. A "free" instant completion with no credit deduction = FAIL (unmetered `POST /quick-actions` must never be wired). Optional server check: `GET /quick-actions?stress_level=75&language=en&coaching_style=supportive` → includes breathing + grounding.
result: [pending]
coverage: 03-03 D5 (live chips swap on deployed backend)

### 4. 402 → paywall regression (AUTH-03)
expected: Drain the account to 0 remaining credits, then send a chat message. Paywall presents with the out-of-credits reason ("You're out of credits" + top-up options) — no crash, no dead-end raw error, spinner does not hang. Dismiss → app remains usable (dashboard, settings).
result: [pending]
coverage: 03-05 D2 (scenario execution)

### 5. Factory reset wipes server history (DATA-01) — DESTRUCTIVE, run last
expected: Save the account's Bearer token FIRST (Appendix). Confirm `GET /sessions` non-empty. Settings → Manage data → factory reset, confirm destructive prompt, let it complete on network. Re-check `GET /sessions` with the SAME pre-reset token → empty list. Let the app re-sign-in (fresh anonymous identity), open chat sheet → empty, no restored history, no error (dangling session id cleared / 404-tolerated). Pre-reset token is the only proof the OLD account's rows were deleted (new identity is trivially empty). Firebase ID tokens expire ~1 h — re-check promptly.
result: [pending]
coverage: 03-05 D2 (scenario execution)

### A1. Sessions API client extension (fetchMessages/createSession/listSessions/deleteSession)
expected: Exact-URL, Bearer, 404/401 error mapping
result: pass
source: automated
coverage_id: 03-01 D1

### A2. Titled-session creation ordering (POST /sessions strictly before /chat; fail-soft on 500)
expected: Ordering pinned by capturedRequests test
result: pass
source: automated
coverage_id: 03-01 D2

### A3. History restore semantics (server order, isSynced mapping, system rows filtered, 404 recovery, no-clobber)
expected: ChatHistoryRestoreTests suite green at v1.1 close
result: pass
source: automated
coverage_id: 03-01 D3

### A4. Preferences API client extension (GET decode, single-field PUT, 400/401 mapping)
expected: StressAPIClientPreferencesTests green at v1.1 close
result: pass
source: automated
coverage_id: 03-02 D1

### A5. PreferencesService semantics (migration defaults, seed-once, revert-on-500)
expected: PreferencesServiceTests green at v1.1 close
result: pass
source: automated
coverage_id: 03-02 D2

### A6. CR-02 closure: trend direction computed chronologically from newest-first history
expected: 4 regression cases green at v1.1 close
result: pass
source: automated
coverage_id: 03-02 D3

### A7. Quick-actions API client extension (exact 3-param query, Bearer, typed decode, 401)
expected: StressAPIClientQuickActionsTests green at v1.1 close
result: pass
source: automated
coverage_id: 03-03 D1

### A8. Local prompt-table mirror (7 backend ids verbatim; unknown id → nil)
expected: promptMapMirrorsBackendTable green at v1.1 close
result: pass
source: automated
coverage_id: 03-03 D2

### A9. Chips lifecycle (instant fallback, server swap, one GET per presentation, failure keeps fallback)
expected: ChatHistoryRestoreTests chips tests green at v1.1 close
result: pass
source: automated
coverage_id: 03-03 D3

### A10. Prefs-fed send path (chip tap → /chat with seeded vi/direct in query + payload; unset → en/supportive)
expected: chipTapSendsPromptWithPrefsFedPayload green at v1.1 close
result: pass
source: automated
coverage_id: 03-03 D4

### A11. Factory reset wipes server sessions page-by-page before local wipe (50-page cap)
expected: DataDeleterServerWipeTests green at v1.1 close
result: pass
source: automated
coverage_id: 03-04 D1

### A12. Auth-unavailable skip vs fail-loudly classification
expected: skip-with-log on signed-out/401; network error fails reset before local wipe
result: pass
source: automated
coverage_id: 03-04 D2

### A13. stressChatSessionId cleared unconditionally on delete-all and factory-reset
expected: DeleteAllCredentialClearanceTests green at v1.1 close
result: pass
source: automated
coverage_id: 03-04 D3

### A14. Supabase remnant cleanup (.gitignore, 25-about.html OSS row, KEEP sites)
expected: grep 0/0; keep sites exactly FirebaseAuthService.swift + DataDeletionConsolidationTests.swift
result: pass
source: automated
coverage_id: 03-04 D4

### A15. POST /quick-actions metering gap recorded on backend repo, cross-linked from COVERAGE row 17
expected: phuongddx/stress-app-be issue #2 open at v1.1 close
result: pass
source: automated
coverage_id: 03-04 D5

### A16. Integration gate matrix executed with recorded evidence (backend deno 29/29, iOS suite accepted-#8 signature, Release build exit 0)
expected: 03-05 gate evidence recorded at v1.1 close
result: pass
source: automated
coverage_id: 03-05 D1

## Verification Appendix — reading `/sessions`, `/preferences`, `/quick-actions` as the app's account

All server-side checks need the app account's **Firebase ID token** as a Bearer header. Extract once, reuse (tokens expire ~1 h; re-extract on a 401).

**Token extraction (pick one):**

- **A. Proxy capture (no code change — recommended).** Proxyman/Charles as macOS system proxy (simulators honor it; trust the proxy root CA on the simulator). Open the chat sheet — it fires `GET /sessions/{id}/messages`, `GET /preferences`, `GET /quick-actions?…` against `stress-api.dropitx.site`. Copy the `Authorization: Bearer …` header from any request.
- **B. Xcode debugger.** Run from Xcode, break after sign-in (e.g. `StressAPIClient.authorizedRequest(url:)`) and read the token — or temporarily `print(token)` in `FirebaseAuthService.getIDToken()` under `#if DEBUG`.

| Check | Request | Headers | Expected |
|---|---|---|---|
| Health (precheck) | `GET https://stress-api.dropitx.site/health` | none | HTTP 200 |
| Session list | `GET https://stress-api.dropitx.site/sessions` | `Authorization: Bearer <token>` | `{"sessions":[…],"limit":20,"offset":0}` |
| Preferences | `GET https://stress-api.dropitx.site/preferences` | `Authorization: Bearer <token>` | full row incl. `"language"`, `"coaching_style"` |
| Quick actions (optional) | `GET https://stress-api.dropitx.site/quick-actions?stress_level=75&language=en&coaching_style=supportive` | none (unauthenticated) | `{"quick_actions":[…breathing, grounding…]}` |

Tester notes:
- `GET /sessions` rows carry `id`, `title`, `created_at`, `updated_at` (ISO strings with fractional seconds — normal).
- Scenario 2 mutates preferences; if you bail mid-scenario, leave the account on `en`/`supportive` so later runs start from defaults.
- Every chat send (including chip taps) costs 1 credit, logged server-side — Scenario 3's tap is metered by design.

## Summary

total: 21
passed: 16
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps

None yet.

## Round 1 record (v1.1 close-out, 2026-08-23)

| # | Scenario | Result |
|---|----------|--------|
| 1 | History restore across relaunch | ✅ pass |
| 2 | Preferences round-trip | ✅ pass |
| 3 | Chip fetch on chat open | ✅ pass |
| 4 | 402 → paywall regression | ✅ pass |
| 5 | Factory reset wipes server history | ✅ pass |

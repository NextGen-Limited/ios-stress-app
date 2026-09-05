---
status: complete
phase: 03-sessions-preferences-quick-actions-cleanup
source: [03-CONTEXT.md, 03-05-PLAN.md, COVERAGE.md]
updated: 2026-08-23T23:50:43+07:00
audit_acknowledged:
  milestone: v1.2
  at: 2026-09-05
  gap_snapshot: "complete::scenarios=0"
---

# Phase 3 UAT — Live-Backend Scenario Script (v1.1 close-out)

Human-executable scenarios riding the **deployed** backend at `https://stress-api.dropitx.site`.
Authored by plan 03-05; **none of these scenarios were executed by the plan** — all are `[pending]` for the end-of-phase human verification.

## Precheck (run once, before any scenario)

Open any HTTP client (browser address bar is enough) and confirm:

- `GET https://stress-api.dropitx.site/health` → **HTTP 200**

If this is not 200, stop — the backend is down/stale and every scenario below is invalid (03-RESEARCH T-3-19).

**Test setup:** StressMonitor on the iPhone 17 simulator, built from the current branch (`gsd/v1.1-backend-api-migration`). DEBUG is fine for scenarios 1/2/3/5 — chat, sessions, preferences, and quick-actions all hit the real backend in DEBUG. Run scenarios **in order**; Scenario 5 is destructive (factory reset) and must be last. Use one simulator install throughout so the anonymous identity (and its session history) stays constant across scenarios 1–4.

## Scenario Table

| # | Scenario | Server-side check | Result |
|---|----------|-------------------|--------|
| 1 | History restore across relaunch — one titled session, no duplicates | `GET /sessions` — exactly 1 session, title = truncated first message | ✅ pass |
| 2 | Preferences round-trip — Settings → backend → next reply | `GET /preferences` — `language: "vi"`, `coaching_style: "direct"` | ✅ pass |
| 3 | Chip fetch on chat open — instant fallback, server swap, metered tap | optional `GET /quick-actions?stress_level=75&language=en&coaching_style=supportive` → breathing + grounding | ✅ pass |
| 4 | 402 → paywall regression (AUTH-03) | none (client-side) | ✅ pass |
| 5 | Factory reset wipes server history (DATA-01) | `GET /sessions` with the **pre-reset** token — empty after reset | ✅ pass |

### 1. History restore across relaunch

**Preconditions:** Fresh-ish anonymous account with credits (a new install provisions 50); backend precheck green; no prior chat this session.

**Steps:**

1. Launch the app, open the AI Coach chat sheet (Settings → AI Coach chat row, or the dashboard coach card).
2. Send a message longer than ~50 characters, e.g. `Hello coach, this is my first message and it is deliberately long enough to be truncated in a session title`.
3. Wait for the streamed reply to finish.
4. Force-quit the app (app switcher → swipe the app away).
5. Relaunch, reopen the chat sheet.

**Expected observable results:**

- Step 5: the prior conversation (your message + the coach reply) renders immediately — history is restored from the server, not lost on relaunch.
- Close and reopen the chat sheet a second time: the message list is **not duplicated** (Pitfall 2 warning sign — each open fetches once, no double-render).

**Server-side check:** `GET /sessions` (see Appendix) lists **exactly ONE session** for the account, and its `title` is the first message truncated (≈50 chars, ellipsis if cut). **Two sessions for one first message = FAIL** (Pitfall 5 — session-creation raced the first `/chat` and the backend auto-created an untitled second session).

result: pass

### 2. Preferences round-trip

**Preconditions:** Scenario 1 completed (account has a session); backend precheck green.

**Steps:**

1. Settings → **AI Coach** section: set Language → **Tiếng Việt**, Coaching Style → **Direct**.
2. Force-quit and relaunch the app; reopen Settings → AI Coach.
3. Open the chat sheet and send one message (e.g. `I feel tense right now`).
4. After Scenario 2 checks pass, switch both pickers back: Language → **English**, Coaching Style → **Supportive**.

**Expected observable results:**

- Step 2: both pickers still show Tiếng Việt / Direct after relaunch (seeded from and persisted to the server).
- Step 3: the reply arrives **in Vietnamese, in a direct tone** — the backend system prompt now says `Respond in vi.` and follows the direct coaching style.
- No error footnote appears under the AI Coach card during the switches (a transient footnote during a failed PUT is a bug to record).

**Server-side check:** `GET /preferences` shows `"language": "vi"` and `"coaching_style": "direct"` (check between steps 3 and 4). After step 4 it shows `"en"` / `"supportive"` again.

result: pass

### 3. Chip fetch on chat open

**Preconditions:** Account has credits; backend precheck green. Stress context is whatever the app currently has (default context is fine).

**Steps:**

1. Open the chat sheet and watch the quick-reply chips above the composer.
2. Wait 1–2 seconds without typing.
3. Tap any chip.

**Expected observable results:**

- Step 1: chips render **instantly** (local fallback set — no blank/loading state).
- Step 2: within a second or two the chip titles swap to the server's suggestions for the current stress context (e.g. breathing / grounding when stress is high; titles may match the local set at moderate stress — the swap itself is the signal, and with Vietnamese+direct still set from Scenario 2 the server suggestions follow that context).
- Step 3: the tap sends a prompt through the normal chat path — a **credit-metered** streamed response plays (spinner → tokens stream); the credit pill/balance decreases by one. **A "free" instant completion with no credit deduction = FAIL** (that would mean the unmetered `POST /quick-actions` got wired — it must never be).

**Server-side check (optional):** `GET /quick-actions?stress_level=75&language=en&coaching_style=supportive` returns suggestions including `breathing` and `grounding` (the ≥75 rule).

result: pass

### 4. 402 → paywall regression (AUTH-03)

**Preconditions:** Account at **zero remaining credits** (keep chatting from Scenario 3 until the balance hits 0; a fresh account's 50 free credits minus one per message — or reuse the Phase-2 smoke procedure for draining).

**Steps:**

1. With 0 credits remaining, open the chat sheet and send a message.
2. Observe the response.
3. Dismiss the paywall; verify the app is still usable (dashboard, settings).

**Expected observable results:**

- Step 2: the **paywall presents with the out-of-credits reason** ("You're out of credits" lead copy + top-up options) — **no crash, no dead-end raw error**, streaming spinner does not hang.
- Step 3: the sheet dismisses; the app remains functional.

**Server-side check:** none (client-side regression pin; the backend 402 gate is covered by the backend suite).

result: pass

### 5. Factory reset wipes server history

**Preconditions:** Scenarios 1–3 done (the account has server-side chat history); **extract and save the account's Bearer token FIRST** (Appendix) — after the reset the device identity is gone, so this token is your only handle on the wiped account.

**Steps:**

1. With the saved token, confirm server-side history exists: `GET /sessions` → non-empty list.
2. In the app: Settings → **Manage data** → **factory reset** (the full wipe), confirm the destructive prompt and let it run to completion while the device has network.
3. Immediately re-check with the **same saved token**: `GET /sessions` → **empty list** `{"sessions":[],…}`.
4. Let the app re-sign-in (it provisions a fresh anonymous identity), then open the chat sheet.

**Expected observable results:**

- Step 2: reset completes without an error alert (a network hiccup should surface `DeletionError`, not claim success — but on a healthy connection it completes).
- Step 3: server-side emptiness for the **wiped account** — this is the DATA-01 bar ("delete actually deletes everywhere"), not just local.
- Step 4: the chat sheet opens **empty** — no restored history, no error (the dangling local session id was cleared and/or 404-tolerated).

**Why the same token:** the post-reset sign-in creates a *new* anonymous uid; `GET /sessions` with the new identity is trivially empty and proves nothing. Only the pre-reset token proves the old account's rows were actually deleted. (Firebase ID tokens stay valid ~1 h after sign-out — re-run step 3 promptly after step 2.)

result: pass

## Verification Appendix — reading `/sessions`, `/preferences`, `/quick-actions` as the app's account

All server-side checks need the app account's **Firebase ID token** as a Bearer header. Extract it once, reuse for all checks (tokens expire ~1 h; re-extract on a 401).

**Token extraction (pick one):**

- **A. Proxy capture (no code change — recommended).** Run Proxyman or Charles as the macOS system proxy (simulators honor it; install + trust the proxy's root CA on the simulator when prompted). Open the chat sheet in the app — it fires `GET /sessions/{id}/messages`, `GET /preferences`, and `GET /quick-actions?…` against `stress-api.dropitx.site`. Copy the `Authorization: Bearer …` request header from any of those requests.
- **B. Xcode debugger.** Run the app from Xcode, break anywhere after the app has signed in (e.g. a breakpoint in `StressAPIClient.authorizedRequest(url:)`), and read the token from the frame — or temporarily add a `print(token)` in `FirebaseAuthService.getIDToken()` under `#if DEBUG` and remove it afterwards.

**Checks (any HTTP client — a REST GUI app, Postman, etc.):**

| Check | Request | Headers | Expected |
|---|---|---|---|
| Health (precheck) | `GET https://stress-api.dropitx.site/health` | none | HTTP 200 |
| Session list | `GET https://stress-api.dropitx.site/sessions` | `Authorization: Bearer <token>` | `{"sessions":[…],"limit":20,"offset":0}` |
| Preferences | `GET https://stress-api.dropitx.site/preferences` | `Authorization: Bearer <token>` | full row incl. `"language"`, `"coaching_style"` |
| Quick actions (optional) | `GET https://stress-api.dropitx.site/quick-actions?stress_level=75&language=en&coaching_style=supportive` | none (route is unauthenticated) | `{"quick_actions":[…breathing, grounding…]}` |

Notes for the tester:

- `GET /sessions` rows carry `id`, `title`, `created_at`, `updated_at` (dates are ISO strings with fractional seconds — normal).
- Scenario 2 mutates preferences; if you bail mid-scenario, leave the account on `en`/`supportive` (step 4) so later runs start from the defaults.
- Every chat send (including chip taps) costs 1 credit and is logged server-side — Scenario 3's tap is metered by design.

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None recorded at authoring time — scenarios pending human execution (end-of-phase verify).

---
phase: 03
slug: sessions-preferences-quick-actions-cleanup
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-23
---

# Phase 03 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
>
> Register source: `<threat_model>` blocks in 03-01…03-05-PLAN.md (authored at plan time).
> Closure evidence: 03-VERIFICATION.md (status: passed), L1 grep checks in this repo, and
> the live-backend UAT scenarios recorded in 03-UAT.md (5/5 passed 2026-08-23 — including
> the metered chip tap for T-3-09 and the factory-reset server-wipe for T-3-13/T-3-15).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| client → backend /sessions* | Firebase ID token crosses; session/message JSON returns; destructive per-id deletes issued in wipe loop | Bearer token / session JSON (low sensitivity) |
| UserDefaults → restore path | Locally persisted session id (non-secret) drives a server fetch | Session UUID |
| client → backend /preferences | Firebase ID token crosses; preferences row JSON returns | Bearer token / preference strings |
| Settings UI → PreferencesService | User intent crosses into optimistic state + server write | Picker values (en/vi, 3 coaching styles) |
| client → backend GET /quick-actions | Token + context query params cross; suggestion ids/titles return | Stress context + prefs (low sensitivity) |
| server-suggested chip content → chat send | Server-controlled titles rendered as text; taps send fixed local prompts through /chat | Prompt ids (client-keyed) |
| factory-reset flow → server availability | Local deletion couples to a server phase scoped by error classification | Delete acknowledgements |
| gate commands → local postgres (5433) | Test DB credentials cross to a loopback-only instance | Local test credentials |
| UAT tester → deployed backend | Live identity performs real metered chat sends and a real factory reset | Real account data |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-3-01 | Elevation of Privilege | fetchMessages / DELETE with another user's session id | low | accept | Server scopes every query by token-derived uid (404 non-owned); no user input reaches these paths | closed (accepted) |
| T-3-02 | Tampering (stored) | session title from user text | low | mitigate | JSON-encoded parameterized insert; truncated + whitespace-collapsed client-side; render must treat as untrusted (noted for deferred multi-session UX) | closed |
| T-3-03 | Information Disclosure | dangling stressChatSessionId leaking prior identity | medium | mitigate | Restore 404-tolerant, clears stored id on 404 (StressLLMService.swift:57); factory-reset clear in 03-04 | closed |
| T-3-04 | Tampering / DoS | late restore overwriting a live conversation | low | mitigate | messages.isEmpty guard before AND after await; restoredHistory one-shot flag (no-clobber test) | closed |
| T-3-05 | Tampering | preference poisoning via extra PUT fields | medium | mitigate | Server ALLOWED_FIELDS authoritative (user_id dropped, backend test); client sends exactly one allowlisted key per PUT (StressAPIClient+Preferences.swift:51-57) | closed |
| T-3-06 | Tampering | fresh install overwriting server prefs with defaults | medium | mitigate | GET-before-PUT: seedIfNeeded hydrates before any update; PUT only fires from explicit picker change | closed |
| T-3-07 | Spoofing/Tampering | picker values outside backend vocabulary | low | mitigate | Closed 3-case coaching set; language en/vi; unknown server values degrade gracefully | closed |
| T-3-08 | Repudiation | silent divergence of local vs server preference state | low | mitigate | Revert-on-PUT-failure + surfaced errorMessage (PreferencesServiceTests); no cached-write path | closed |
| T-3-09 | Tampering (revenue) | wiring the unmetered POST /quick-actions completion route | high | mitigate | Client structurally exposes exactly one GET (StressAPIClient+QuickActions.swift); chip taps route through send() → /chat, credit-metered — live-verified by UAT scenario 3 (balance decremented on tap) | closed |
| T-3-10 | Spoofing | server-controlled chip titles rendered as text | low | accept | SwiftUI Text renders inertly; prompts are fixed local strings keyed by id — server only chooses among 7 known prompts | closed (accepted) |
| T-3-11 | DoS / UX confusion | chip swap clobbering user state mid-interaction | low | mitigate | Swap replaces chip data only; one fetch per presentation; failure keeps fallback | closed |
| T-3-12 | Repudiation | prefs-fed payload diverging from displayed Settings | low | mitigate | Same app-scope PreferencesService instance; payload read at send time (FakeLLMService-recorded-context test) | closed |
| T-3-13 | Tampering / Repudiation | wipe silently no-ops on partial failure | high | mitigate | Explicit failure classification: skip ONLY auth-unavailability (logged); every other error throws serverSessionError and aborts before "Factory reset complete"; live-verified by UAT scenario 5 (server history empty with pre-reset token) | closed |
| T-3-14 | Elevation of Privilege | wiping another user's sessions via crafted ids | low | accept | Server scopes DELETE by token-derived uid; iOS iterates only its own authenticated list ids | closed (accepted) |
| T-3-15 | Information Disclosure | prior-identity session id surviving factory reset | medium | mitigate | clearCredentialsAndSharedCaches() → StressLLMService.clearStoredCredentials() removes stressChatSessionId (DataDeleterService.swift:552-557, :36); invoked on both delete paths (:111, :440); pinned by ConsolidationTests | closed |
| T-3-16 | DoS | wipe loop never terminating against misbehaving server | low | mitigate | 50-page safety cap throws instead of looping (DataDeleterService.swift:496, cap test) | closed |
| T-3-17 | Tampering | gate integrity (flags omitted, remote DB, partial evidence) | medium | mitigate | Canonical commands pinned in plan; raw output per leg recorded in SUMMARY; failures recorded as named gaps | closed |
| T-3-18 | Information Disclosure | backend test DB pointed at remote/hosted instance | low | mitigate | DATABASE_URL fixed to 127.0.0.1:5433 in recorded command; acceptance forbids other targets | closed |
| T-3-19 | Repudiation | UAT executed against stale/dead backend | low | mitigate | GET /health → 200 precheck inside script and re-checked before handover | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-3-01 | Server-side uid scoping is the sole and sufficient guard; no user input reaches id paths | plan 03-01 (disposition) | 2026-08-23 |
| AR-03-02 | T-3-10 | SwiftUI inert text rendering + fixed local prompt set cap server influence at chip selection | plan 03-03 (disposition) | 2026-08-23 |
| AR-03-03 | T-3-14 | Server-side uid scoping on DELETE; client loop only ever sees its own list | plan 03-04 (disposition) | 2026-08-23 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-23 | 19 | 19 | 0 | gsd-secure-phase (L1 grep-depth, ASVS 1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-23 (short-circuit path: threats_open 0, register authored at plan time, ASVS L1 — closure evidence from 03-VERIFICATION.md passed report, in-repo greps, and live-backend UAT scenarios 3/5)

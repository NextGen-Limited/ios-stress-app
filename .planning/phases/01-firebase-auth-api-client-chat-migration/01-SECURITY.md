---
phase: 01
slug: firebase-auth-api-client-chat-migration
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-08-16
---

# Phase 01 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| App → Firebase Auth | Anonymous sign-in + Google OAuth credential exchange (GIDSignIn → Auth.auth) | OAuth credentials, ID tokens |
| App → Backend API (stress-api.dropitx.site) | Bearer-token REST + SSE over HTTPS | Derived stress scores (stress_context), chat messages |
| Anonymous → Google account link | currentUser.link(with:) preserves uid/credits/history | Account credential |
| Keychain → legacy Supabase accounts | clearStoredCredentials() deletes legacy tokens | Supabase access/refresh tokens |
| SwiftUI → UIKit → Google OAuth | connectedScenes → keyWindow → rootViewController presenter bridge | OAuth presentation context |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Spoofing/Tampering | Firebase ID token in transit | high | mitigate | HTTPS-only (ATS default); backend verifies token signature via Firebase Admin verifyIdToken | closed |
| T-01-02 | Information Disclosure | stress_context payload over network | medium | mitigate | StressContextPayload sends derived scores only — no raw HealthKit samples (verified: payload fields are stress level/category/confidence + per-factor scores) | closed |
| T-01-03 | Denial of Service | /chat endpoint flooding | low | accept | Backend credit-based rate limiting (D-07) | closed |
| T-01-04 | Elevation of Privilege | Anonymous → Google upgrade | medium | mitigate | Firebase account linking via link(with:) preserves anonymous uid (implemented 01-02; human-verified 2026-08-16) | closed |
| T-01-05 | Tampering | GoogleService-Info.plist in bundle | low | accept | Firebase API keys are safe to ship; security via Auth + server verification | closed |
| T-01-SC | Tampering | firebase-ios-sdk SPM dependency | high | mitigate | Google's official SDK, verified publisher, pinned via Package.resolved | closed |
| T-02-01 | Spoofing | Google Sign-In credential exchange | medium | mitigate | GIDSignIn official OAuth flow (PKCE, system browser); Auth.auth() verifies credentials | closed |
| T-02-02 | Repudiation | Anonymous-to-Google merge | low | accept | Firebase preserves uid across link | closed |
| T-02-03 | Information Disclosure | Leftover Supabase Keychain tokens | medium | mitigate | clearStoredCredentials() deletes supabaseAccessToken/supabaseRefreshToken + UserDefaults keys (verified: FirebaseAuthService.swift:116-124) | closed |
| T-03-01 | Tampering | Test-only mock in Release build | medium | mitigate | MockAuthService lives in StressMonitorTests/ only; 0 references in app target pbxproj; no MockAuthService in app-target MockServices.swift | closed |
| T-04-01 | Tampering | UIViewController bridge | low | mitigate | foregroundActive UIWindowScene keyWindow rootViewController; nil-guarded, no force-unwrap (verified: SettingsView.swift:342-350) | closed |
| T-04-02 | Spoofing | OAuth presentation | low | mitigate | GIDSignIn official flow; server-side verification (same as T-02-01) | closed |
| T-04-03 | Repudiation | Double-link when already linked | low | mitigate | Row action inert when linkedEmail != nil (verified: SettingsView.swift:342) | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-1 | T-01-03 | /chat flooding mitigated server-side via credit limits; no client action needed | plan 01-01 (plan-time disposition) | 2026-08-12 |
| AR-01-2 | T-01-05 | GoogleService-Info.plist designed to ship in bundle per Firebase docs | plan 01-01 (plan-time disposition) | 2026-08-12 |
| AR-01-3 | T-02-02 | Firebase link() preserves uid — merge semantics are platform-guaranteed | plan 01-02 (plan-time disposition) | 2026-08-12 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-16 | 13 | 13 | 0 | gsd-secure-phase (orchestrator inline, ASVS L1) |

### Audit Method

ASVS level 1 (grep-depth) verification from plan-time threat registers (all four PLAN.md files authored with `<threat_model>` blocks). Mitigation evidence:

- T-01-02: StressContextPayload.swift field inspection — derived scores only, no raw HKQuantity/sample types
- T-02-03: FirebaseAuthService.swift:116-124 — legacy Supabase Keychain + UserDefaults deletion present
- T-03-01: MockAuthService confined to StressMonitorTests/; zero pbxproj references in app target; MockServices.swift contains no MockAuthService
- T-04-01/T-04-03: SettingsView guards verified in plan 01-04 diff (this session)
- T-01-04/T-02-01: account-link OAuth flow human-verified on simulator 2026-08-16 (01-UAT.md Test 2)
- T-01-01/T-01-SC: backend HTTPS + official SPM SDK confirmed in 01-VERIFICATION.md (build evidence)

Short-circuit applied: threats_open 0, register_authored_at_plan_time true, asvs_level 1 → no auditor dispatch required (L1 depth sufficient).

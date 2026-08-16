---
status: testing
phase: 01-firebase-auth-api-client-chat-migration
source: [01-VERIFICATION.md]
started: 2026-08-13T15:15:32Z
updated: "2026-08-16T10:15:00Z"
---

## Current Test

number: 1
name: End-to-end chat streaming via Firebase Anonymous auth + backend SSE
expected: |
  Launch app on simulator → open Chat → type "hello" → confirm a streamed response arrives within 15 seconds. The full pipeline is: ChatViewModel → StressLLMService → StressAPIClient.sendChat (Bearer token from FirebaseAuthService) → SSE stream → SSEParser → ChatViewModel display. Firebase Anonymous auth must succeed silently at launch.
awaiting: user response


## Tests

### 1. End-to-end chat streaming via Firebase Anonymous auth + backend SSE

expected: Launch app on simulator → open Chat → type "hello" → confirm a streamed response arrives within 15 seconds. The full pipeline is: ChatViewModel → StressLLMService → StressAPIClient.sendChat (Bearer token from FirebaseAuthService) → SSE stream → SSEParser → ChatViewModel display. Firebase Anonymous auth must succeed silently at launch.
result: [pending]

### 2. Google Sign-In upgrade path with anonymous-account linking

expected: Trigger the Google Sign-In OAuth flow → confirm the anonymous account is linked (not replaced). The code path is FirebaseAuthService.signInWithGoogle(presenting:) → GIDSignIn v9 OAuth → OAuthProvider "google.com" credential → currentUser.link(with:) (falls back to signIn(with:) on credentialAlreadyInUse). Entry point: Settings → Sync & devices → 'Sign in with Google' row (added by Plan 01-04).
result: pass
verified: "2026-08-16 — human-verify checkpoint on iPhone 17 simulator (iOS 26.5), plan 01-04 Task 3. User approved: OAuth sheet presents from the Settings row, flow completes, anonymous account links with the linked email displayed on the row value and MeHeroCard."
resolved: "Gap G-01-2 closed by plan 01-04 (commits 3fb0ec8, cb665cd, c548d9a)."


## Summary

total: 2
passed: 1
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

```yaml

- gap_id: G-01-2
  truth: "Google Sign-In flow is triggerable from the app UI and links the anonymous account (currentUser.uid unchanged, credits + chat history preserved)"
  status: closed
  reason: "Closed by plan 01-04: 'Sign in with Google' row added to SettingsView.syncDevicesSection, wired through AccountViewModel. Human-verified 2026-08-16 (checkpoint approval) — OAuth presents, account links, linked email displayed."
  severity: none
  test: 2
  root_cause: "(historical) UI entry point explicitly descoped in Plan 01-02 Task 1, deferred to a 'future settings-phase' that did not exist."
  resolution:

    - plan: "01-04 (gap_closure: true, commits 3fb0ec8 / cb665cd / c548d9a / b2ebc8d)"
      files:

        - "StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift"
        - "StressMonitor/StressMonitor/Views/Settings/SettingsView.swift"
        - "StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift"
        - "StressMonitor/StressMonitorTests/AccountViewModelTests.swift"
  missing:

    - "ViewModel surface (SettingsViewModel or small AccountViewModel) holding injected AuthServiceProtocol — none currently exists outside Services"
    - "UIViewController for GIDSignIn presentation, obtained from UIApplication.shared.connectedScenes → key window → rootViewController (presenting: parameter can't be satisfied from pure SwiftUI)"
    - "'Sign in with Google' navRow in SettingsView syncDevicesSection"
    - "Post-link state refresh (MeHeroCard already has an email param)"
    - "ViewModel call-through test using MockAuthService (seam exists in StressAPIClientTests)"
  debug_session: .planning/debug/google-signin-ui-entry-missing.md
```

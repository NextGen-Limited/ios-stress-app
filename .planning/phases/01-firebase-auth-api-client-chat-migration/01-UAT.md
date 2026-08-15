---
status: diagnosed
phase: 01-firebase-auth-api-client-chat-migration
source: [01-VERIFICATION.md]
started: 2026-08-13T15:15:32Z
updated: "2026-08-15T09:47:22Z"
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

expected: Trigger the Google Sign-In OAuth flow → confirm the anonymous account is linked (not replaced). The code path is FirebaseAuthService.signInWithGoogle(presenting:) → GIDSignIn v9 OAuth → OAuthProvider "google.com" credential → currentUser.link(with:) (falls back to signIn(with:) on credentialAlreadyInUse). Note: no UI entry point was wired in this phase — verify via debugger or a temporary button if needed.
result: issue
reported: "No UI entry point exists — the signInWithGoogle code path is unreachable from anywhere in the app (no button or screen triggers FirebaseAuthService.signInWithGoogle). Verified by grep: zero call sites in Views."
severity: major

## Summary

total: 2
passed: 0
issues: 1
pending: 1
skipped: 0
blocked: 0

## Gaps

```yaml

- gap_id: G-01-2
  truth: "Google Sign-In flow is triggerable from the app UI and links the anonymous account (currentUser.uid unchanged, credits + chat history preserved)"
  status: failed
  reason: "User reported: No UI entry point exists — the signInWithGoogle code path is unreachable from anywhere in the app."
  severity: major
  test: 2
  root_cause: "UI entry point explicitly descoped in Plan 01-02 Task 1 ('this task only ships the service method'), deferred to a 'future settings-phase' that does not exist — the deferral dead-ends with no owner. UAT truth #9 was authored broader ('triggerable from the app UI') than any planned deliverable."
  artifacts:

    - path: "StressMonitor/StressMonitor/Views/Settings/SettingsView.swift"
      issue: "Missing 'Sign in with Google' row; syncDevicesSection (line 146) is the natural home"

    - path: "StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift"
      issue: "Nothing wrong — signInWithGoogle(presenting:) fully implemented at line 64; simply unreachable from UI"

    - path: ".planning/phases/01-firebase-auth-api-client-chat-migration/01-02-PLAN.md"
      issue: "Deferral source — Task 1 scope note pushes UI to a nonexistent future phase"
  missing:

    - "ViewModel surface (SettingsViewModel or small AccountViewModel) holding injected AuthServiceProtocol — none currently exists outside Services"
    - "UIViewController for GIDSignIn presentation, obtained from UIApplication.shared.connectedScenes → key window → rootViewController (presenting: parameter can't be satisfied from pure SwiftUI)"
    - "'Sign in with Google' navRow in SettingsView syncDevicesSection"
    - "Post-link state refresh (MeHeroCard already has an email param)"
    - "ViewModel call-through test using MockAuthService (seam exists in StressAPIClientTests)"
  debug_session: .planning/debug/google-signin-ui-entry-missing.md
```

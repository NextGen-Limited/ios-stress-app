---
status: testing
phase: 01-firebase-auth-api-client-chat-migration
source: [01-VERIFICATION.md]
started: 2026-08-13T15:15:32Z
updated: 2026-08-13T15:15:32Z
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
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps

---
phase: 01-firebase-auth-api-client-chat-migration
plan: 04
subsystem: auth
tags: [firebase, google-signin, swiftui, viewmodel, gap-closure]
requires:
  - "Plan 01-02: FirebaseAuthService.signInWithGoogle(presenting:) implemented + GoogleSignIn SPM linked"
  - "Plan 01-03: MockAuthService test double pinned in StressAPIClientTests.swift"
provides:
  - "AccountViewModel (@MainActor @Observable, injected AuthServiceProtocol) — UI-facing Google Sign-In state machine"
  - "AuthServiceProtocol.currentAccountEmail accessor (FirebaseAuthService: Auth.auth().currentUser?.email)"
  - "'Sign in with Google' row in SettingsView.syncDevicesSection — closes gap G-01-2 (flow now reachable from UI)"
  - "UIViewController bridge (connectedScenes -> keyWindow -> rootViewController) for GIDSignIn presenting parameter"
  - "Linked-email display path: MeHeroCard falls back to accountViewModel.linkedEmail; row value shows linked email or 'Link account'"
  - "AccountViewModelTests (4 Swift Testing cases) pinning call-through with MockAuthService"
affects:
  - "SettingsView (new @State accountViewModel + sign-in error alert)"
  - "All AuthServiceProtocol conformers (protocol gained a member: FirebaseAuthService, MockAuthService)"
tech-stack:
  added: []
  patterns:
    - "ViewModel-wraps-service state machine (isSigningIn guard, defer-reset, post-success refresh)"
    - "Silent user-cancellation handling (GIDSignIn domain code -5 -> errorMessage nil, no alert)"
    - "SwiftUI->UIKit presenter discovery via connectedScenes for OAuth flows"
key-files:
  created:
    - StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift
    - StressMonitor/StressMonitorTests/AccountViewModelTests.swift
  modified:
    - StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift
    - StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
    - StressMonitor/StressMonitorTests/StressAPIClientTests.swift
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
key-decisions:
  - "AccountViewModel rethrows sign-in errors (view decides alert presentation) while owning errorMessage state — keeps cancellation-silence in one place"
  - "Row action inert when linkedEmail != nil — prevents a second OAuth presentation over an existing link (T-04-03)"
  - "nonisolated init on FirebaseAuthService so AccountViewModel default construction works from any isolation"
patterns-established:
  - "OAuth presentation bridge: connectedScenes -> foregroundActive UIWindowScene -> keyWindow -> rootViewController"
  - "User-cancellation classification via NSError domain/code check (GoogleSignInCancellation)"
requirements-completed: [D-02]
coverage:
  - id: D4-1
    description: "AccountViewModel.signInWithGoogle call-through + state transitions, pinned by MockAuthService unit tests"
    requirement: D-02
    verification:
      - kind: unit
        ref: "StressMonitorTests/AccountViewModelTests.swift#AccountViewModelTests (4 tests)"
        status: pass
  - id: D4-2
    description: "'Sign in with Google' row in Settings -> Sync & devices, wired through AccountViewModel with post-link email display and error alert"
    requirement: D-02
    verification:
      - kind: manual_procedural
        ref: "01-04-PLAN.md Task 3 human-verify checkpoint — approved 2026-08-16 on iPhone 17 simulator (OAuth presents, account links, email displayed)"
        status: pass
actuals:
  tokens: 15000
  tasks: 3
  commits: 3
---

# Plan 01-04 Summary: Google Sign-In UI Trigger (Gap Closure G-01-2)

## What Was Built

Made FirebaseAuthService.signInWithGoogle(presenting:) — implemented in Plan 01-02 but unreachable from the UI — triggerable from Settings -> Sync & devices, with post-link state refresh showing the linked email and failure surfacing.

- **AccountViewModel** (`@MainActor`, `@Observable`, constructor-injected `AuthServiceProtocol`): `linkedEmail`, `isSigningIn`, `errorMessage` state; `refreshAccountState()` reads `currentAccountEmail`; `signInWithGoogle(presenting:)` guards re-entry, resets via `defer`, refreshes after success, classifies GIDSignIn user-cancellation (domain `com.google.GIDSignIn`, code -5) as silent, rethrows real errors.
- **Protocol extension**: `AuthServiceProtocol.currentAccountEmail` — implemented on `FirebaseAuthService` (`Auth.auth().currentUser?.email`) and on `MockAuthService` (settable `email`, plus `googleSignInCallCount` / `lastPresentingViewController` recording).
- **SettingsView**: new `@State accountViewModel` refreshed `onAppear`; "Sign in with Google" `navRow` (icon `g.circle`, `.settingsRippleBlue` tint, value `linkedEmail ?? "Link account"`) after the Apple Health row; `signInWithGoogleTapped()` bridges SwiftUI -> UIKit via `connectedScenes -> keyWindow -> rootViewController`; `.alert("Sign-In Failed")` on the ScrollView; MeHeroCard email argument now `viewModel.displayEmail ?? accountViewModel.linkedEmail`; row action inert once linked.
- **AccountViewModelTests**: 4 Swift Testing cases — call-through (mock invoked once with the passed UIViewController, isSigningIn toggles), success populates linkedEmail, failure populates errorMessage + resets, refreshAccountState nil-then-populated.

## Accomplishments

1. Closed gap G-01-2: the Google Sign-In code path is user-reachable, no longer dead code from the user's perspective.
2. Zero MockAuthService/FirebaseAuthServiceTests regressions from the protocol member addition.
3. All 4 new tests pass; full suite (87 tests / 14 suites) passes.

## Self-Check: PASSED

1. `xcodebuild build -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17'` -> BUILD SUCCEEDED
2. `xcodebuild test -only-testing:StressMonitorTests/AccountViewModelTests -parallel-testing-enabled NO` -> 4/4 passed
3. `grep -c 'signInWithGoogle' SettingsView.swift` -> 3 (UI call site exists)
4. Full suite -> 87 tests / 14 suites passed

## Notes & Deviations

- **Adopted prior-session work**: Tasks 1-2 were found fully implemented but uncommitted in the working tree (prior session stopped at context exhaustion 2026-08-13). This run verified (build + targeted tests + full suite), then committed per task per user decision. No code was rewritten.
- **Simulator runner issue (host-level)**: test-runner launches failed with Mach -308 / channel-disconnected / clone-preparation errors until `-parallel-testing-enabled NO` was used. Parallel-testing clones are broken on this host; all test invocations in this session used the no-parallel flag.
- Plan destination said iPhone 16; host has no iPhone 16 runtime — iPhone 17 (iOS 26.5, booted) used instead, consistent with the 01-VERIFICATION.md build evidence.
- Human-verify checkpoint (Task 3, blocking): Google OAuth round-trip on simulator requires a real Google account — pending user verification, tracked as coverage D4-2 status unknown.

## Files Changed

- `StressMonitor/StressMonitor/ViewModels/AccountViewModel.swift` (created)
- `StressMonitor/StressMonitorTests/AccountViewModelTests.swift` (created)
- `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift`
- `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`
- `StressMonitor/StressMonitorTests/StressAPIClientTests.swift`
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`

## Open Items

- Task 3 human-verify checkpoint: APPROVED 2026-08-16 — OAuth sheet presents from the Settings row, flow completes, anonymous account links with the linked email displayed on row value and MeHeroCard. Recorded in 01-UAT.md (Test 2 → pass; gap G-01-2 → closed).

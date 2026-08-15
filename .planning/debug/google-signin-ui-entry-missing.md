---
status: diagnosed
trigger: "UAT Test 2: No UI entry point exists — signInWithGoogle code path is unreachable from anywhere in the app (no button or screen triggers FirebaseAuthService.signInWithGoogle)"
created: 2026-08-15T00:00:00Z
updated: 2026-08-15T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — The Google Sign-In UI entry point was explicitly descoped during planning: Plan 01-02 Task 1 shipped only the service method and deferred the UI button to "Plan 03 or a future settings-phase", but Plan 01-03 (a testing-only plan) also skipped it, and no later plan/phase exists. The UI button was never planned as a task in any of the three phase plans.
test: Cross-referenced the three PLAN/SUMMARY files, VERIFICATION.md, and a full-repo grep for UI call sites.
expecting: Zero Views call sites + explicit descope language in plans = scope gap, not an implementation regression.
next_action: Diagnose-only mode (goal: find_root_cause_only) — return ROOT CAUSE FOUND to caller. No fix.

bug_class: Bohrbug (deterministic absence of code — not a runtime failure; the feature is provably unreachable)

## Symptoms

expected: Google Sign-In flow is triggerable from the app UI and links the anonymous account (currentUser.uid unchanged, credits + chat history preserved)
actual: No UI entry point exists — the signInWithGoogle code path is unreachable from anywhere in the app (no button or screen triggers FirebaseAuthService.signInWithGoogle). Verified by grep: zero call sites in Views.
errors: None reported
reproduction: Test 2 in .planning/phases/01-firebase-auth-api-client-chat-migration/01-UAT.md
started: Discovered during UAT (2026-08-15); the code shipped without UI wiring in Plan 01-02 (commit a31dff7)

## Eliminated

- hypothesis: UI wiring was planned in one of the three phase tasks but the executor skipped it
  evidence: Plan 01-02 Task 1's own implementation notes state "expose a helper that the Settings/Account view can call when the user taps 'Sign in with Google' (Plan 03 or a future settings-phase adds the UI button; this task only ships the service method)". Plan 01-03's validation notes say "if no button yet, skip — the service method is shipped but UI wiring may be a future phase". No task in 01-01, 01-02, or 01-03 includes adding a button. VERIFICATION.md truth #9 records "no UI entry point is wired in this phase" as PRESENT_BEHAVIOR_UNVERIFIED. The executor delivered exactly what was planned.
  timestamp: 2026-08-15

- hypothesis: The UI existed and was removed (regression)
  evidence: Plan 01-02 SUMMARY lists changed files — FirebaseAuthService.swift, pbxproj, Supabase deletions. No View files touched. No UI ever existed to lose.
  timestamp: 2026-08-15

## Evidence

- timestamp: 2026-08-15
  checked: Full-repo grep for signInWithGoogle|GoogleSignInButton|GIDSignIn across StressMonitor/
  found: 7 matches, all in Services (FirebaseAuthService.swift protocol + impl) or Tests (StressAPIClientTests mock, FirebaseAuthServiceTests protocol-contract test). Zero matches under StressMonitor/StressMonitor/Views/. No sheet/fullScreenCover entry point triggers the flow.
  implication: The service method is implemented and unit-test-pinned but dead code from the user's perspective — unreachable via any UI surface.

- timestamp: 2026-08-15
  checked: .planning/phases/01-firebase-auth-api-client-chat-migration/01-02-PLAN.md Task 1
  found: Task 1 scope is service-only by explicit design: "this task only ships the service method". The UI button is deferred with the parenthetical "(Plan 03 or a future settings-phase adds the UI button)". Task acceptance criteria are all grep/build checks on FirebaseAuthService.swift and pbxproj — no View deliverable.
  implication: The descope is documented, deliberate, and the delivered code matches the plan.

- timestamp: 2026-08-15
  checked: 01-03-PLAN.md (testing plan) + 01-03-SUMMARY.md
  found: Plan 03 treats the missing UI as acceptable: "Optionally test Google Sign-In if a UI entry point exists (if no button yet, skip)". No UI task was added. The deferral chain ends here — the "future settings-phase" it points to does not exist in the .planning/phases tree (Phase 01 is the only phase; STATE.md shows status: executing, 3/3 plans complete).
  implication: The deferral was open-ended — the UI button escaped scope permanently because no plan ever owned it.

- timestamp: 2026-08-15
  checked: 01-VERIFICATION.md truth #9 and 01-UAT.md Test 2
  found: VERIFICATION already flagged truth #9 as PRESENT_BEHAVIOR_UNVERIFIED with "no UI entry point is wired in this phase". The UAT test's own expected text contains the same note ("verify via debugger or a temporary button if needed") — yet the observable truth it asserts is "Google Sign-In flow is triggerable from the app UI". The UAT truth is broader than the shipped scope.
  implication: Secondary cause: the UAT observable truth was authored against the full D-02 intent (CONTEXT.md D-02: "Google Sign-In as an upgrade path") rather than the actually-planned scope, guaranteeing this test could not pass against the shipped build.

- timestamp: 2026-08-15
  checked: Prerequisites for the flow once UI exists — GoogleService-Info.plist + REVERSED_CLIENT_ID URL scheme
  found: StressMonitor/StressMonitor/GoogleService-Info.plist present (1098 bytes, gitignored, BUNDLE_ID stress.ai.com). Info.plist CFBundleURLTypes registers com.googleusercontent.apps.595426793312-45qv7fttusn55km8l5m60lln0amfi5rf, exactly matching the plist's REVERSED_CLIENT_ID. GoogleSignIn SPM product resolved in the target (per VERIFICATION build check).
  implication: Once a button is wired, the OAuth callback path is ready — the only missing piece is the UI call site.

- timestamp: 2026-08-15
  checked: Natural integration point — StressMonitor/StressMonitor/Views/Settings/SettingsView.swift
  found: SettingsView has a "Sync & devices" section (syncDevicesSection, line ~146) with navRows for Apple Health / Apple Watch / Biological Age — the semantically correct home for a "Sign in with Google" account row. FirebaseAuthService is currently only referenced by StressLLMService, StressAPIClient, and DataDeleterService; no ViewModel or Environment holds an AuthServiceProtocol, so no existing UI layer can call signInWithGoogle without new wiring. signInWithGoogle(presenting:) requires a UIViewController for GIDSignIn presentation, which pure SwiftUI does not provide directly.
  implication: The fix needs (a) a new account row/button, (b) ViewModel wiring with an injected AuthServiceProtocol, and (c) a UIViewController obtained from UIApplication.shared.connectedScenes (key window rootViewController) to satisfy the presenting parameter.

## Resolution

root_cause: Explicit descope with an unowned deferral. Plan 01-02 Task 1 shipped signInWithGoogle as a service-layer-only deliverable ("this task only ships the service method") and deferred the UI button to "Plan 03 or a future settings-phase". Plan 01-03 (testing-only) chose to skip rather than add the UI, and no future settings-phase exists — Phase 01 is the only phase and it is complete. The UI entry point was therefore never planned as a task in any plan, so no executor ever built it. Contributing condition (AND-gate: yes): the UAT observable truth #9 was authored as "triggerable from the app UI" — broader than the planned scope — so the shipped build could never satisfy the test it was being judged against. This is a planning/scope gap, not a code regression: the delivered code matches every plan exactly.
fix: (diagnose-only — not applied) Gap-closure should add a "Sign in with Google" row to SettingsView's syncDevicesSection, wired through a ViewModel holding an injected AuthServiceProtocol, presenting via the key window's rootViewController; and re-scope UAT truth #9 to match the delivered increment (or deliver the UI in the same gap-closure).
verification: n/a (find_root_cause_only)
files_changed: []
oracle_type: derived (contract: AuthServiceProtocol declares signInWithGoogle; the absence is a UI-contract gap observable only by manual/UI-level inspection — no existing test could have caught it, since no View-level test harness exists)

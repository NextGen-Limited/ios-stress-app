---
phase: 01-firebase-auth-api-client-chat-migration
plan: 02
type: execute
wave: 2
status: complete
commits:
  - a31dff7: "feat(01-02): add Google Sign-In upgrade path with anonymous-account linking"
  - a830e16: "feat(01-02): remove Supabase source files and scrub all references"
---

# Plan 01-02 Summary: Google Sign-In + Supabase Removal

## What Was Built

### Task 1: Google Sign-In Upgrade Path
- Added `GoogleSignIn-iOS` v9.x SPM package (separate from firebase-ios-sdk — GoogleSignIn is not a Firebase product)
- Implemented `FirebaseAuthService.signInWithGoogle(presenting:)` — runs GIDSignIn v9 OAuth flow, builds OAuthProvider "google.com" credential, **links to current anonymous user first** (preserves credit balance + chat history), falls back to plain `signIn(with:)` on `credentialAlreadyInUse`
- Registered `REVERSED_CLIENT_ID` URL scheme in Info.plist
- Extended `clearStoredCredentials()` to wipe legacy Supabase keychain/UserDefaults entries

### Task 2: Supabase Source Removal
- Deleted all 6 Supabase files: `SupabaseLLMService`, `SupabaseConfig`, `SupabaseAuthService`, `SupabaseSession`, `SupabaseSecrets`, `SupabaseAuthServiceTests`
- Rewired `DataDeleterService` → `FirebaseAuthService.clearStoredCredentials()`
- Removed 4 `SupabaseAuthServiceTests` pbxproj references
- Scrubbed all remaining "Supabase" strings in surviving Swift sources (SSEParser, ChatAvailability, ChatViewModel, StressLLMService, StressAPIConfig, FirebaseAuthService, StressContextPayload, ChatMessage)
- Removed gitignore entry for SupabaseSecrets.swift
- `grep -rn 'Supabase' StressMonitor/StressMonitor/ --include='*.swift'` → **0 matches**

## Verification

- `xcodebuild build` → exit 0 (builds clean after both tasks)
- `grep -rn 'Supabase' StressMonitor/StressMonitor/ --include='*.swift'` → 0
- `find StressMonitor -name 'Supabase*' -type f` → nothing
- Backend `GET /health` → HTTP 200

## Deviations from Plan

1. **GoogleSignIn is not part of firebase-ios-sdk** — added separate `XCRemoteSwiftPackageReference` for `google/GoogleSignIn-iOS` v9.x
2. **Firebase Auth 11.x API**: uses `currentUser.link(with:)` not `link(to:)` as plan pseudocode stated

## Key Files

### Created
- (none — all files are modifications to existing Plan 01-01 files)

### Modified
- `Services/Auth/FirebaseAuthService.swift` — Google Sign-In + extended clearStoredCredentials
- `Services/DataManagement/DataDeleterService.swift` — rewired to FirebaseAuthService
- `Services/LLM/StressContextPayload.swift` — Supabase string scrub
- `Services/LLM/SSEParser.swift` — Supabase comment scrub
- `Services/LLM/StressLLMService.swift` — Supabase string scrub
- `Services/Chat/ChatAvailability.swift` — Supabase comment scrub
- `Services/API/StressAPIConfig.swift` — Supabase string scrub
- `Models/ChatMessage.swift` — Supabase string scrub
- `ViewModels/ChatViewModel.swift` — Supabase string scrub (line 65 doc comment)
- `StressMonitor.xcodeproj/project.pbxproj` — GoogleSignIn SPM + test file removal
- `StressMonitor/Info.plist` — REVERSED_CLIENT_ID URL scheme
- `.gitignore` — removed SupabaseSecrets entry

### Deleted
- `Services/LLM/SupabaseLLMService.swift`
- `Services/LLM/SupabaseConfig.swift`
- `Services/LLM/SupabaseAuthService.swift`
- `Services/LLM/SupabaseSession.swift`
- `Services/LLM/SupabaseSecrets.swift`
- `StressMonitorTests/SupabaseAuthServiceTests.swift`

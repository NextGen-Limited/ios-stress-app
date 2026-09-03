# Phase 1 Deferred Items

Out-of-scope discoveries logged during execution. Not fixed (scope boundary rule).

## [2026-09-03] From 01-02 (Task 2 — CLAUDE.md doc corrections)

| # | Item | Evidence | Disposition |
|---|------|----------|-------------|
| 1 | CLAUDE.md "Key Technical Decisions" table row claims `Dependencies \| None (system only)` — stale: the app links `firebase-ios-sdk` (Auth/Core) and `GoogleSignIn-iOS` via SPM (pbxproj + Package.resolved) | CLAUDE.md line 480 vs `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` XCRemoteSwiftPackageReference / local proxy package | Not Supabase-era, not payload-related → out of §5.6 scope; left unchanged. Candidate for a future docs-hygiene pass |
| 2 | CLAUDE.md persistence row claims "iOS 17+ native" — deployment targets are iOS 18.6 (some targets 26.1), watchOS 11.6 | CLAUDE.md line 476 vs AGENTS.md / pbxproj deployment targets | Known repo-wide doc staleness (AGENTS.md already flags "iOS 17+" docs as stale); left unchanged |

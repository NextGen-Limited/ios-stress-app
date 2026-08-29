# Codebase Concerns

**Analysis Date:** 2026-08-29

## Tech Debt

**Orphaned pre-MVVM code tree (5,717 lines of dead, git-tracked source):**
- Issue: Four directories from an earlier project layout are committed to git but have ZERO references in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — edits there never build, run, or test: `StressMonitor/Models/` (3 files), `StressMonitor/Services/` (7 files), `StressMonitor/Views/` (8 files), `StressMonitorTests/` (repo root, 5 files). The single largest Swift file in the repo — 840-line `StressMonitor/Views/StressHistoryView.swift` — is in this dead tree, as are 410-line `StressMonitor/Services/HRVAnalyzer.swift`, 395-line `StressMonitor/Services/CloudKitManager.swift`, and the entire `StressMonitor/Services/StressPredictor.swift`.
- Files: `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, `StressMonitorTests/` (repo root — distinct from the live `StressMonitor/StressMonitorTests/`)
- Impact: Agents and humans routinely edit these files believing they are live; greps return duplicate "hits" that mislead navigation; 31 SwiftLint violations fire in dead code; dead tests imply coverage that does not exist.
- Fix approach: `git rm -r` all four directories (verify each file is absent from the pbxproj first — confirmed for `StressHistoryView`/`StressPredictor` via `grep -c` = 0). If any historical reference is wanted, keep it in git history, not the working tree.

**Watch target algorithm duplication has already drifted (not just a risk):**
- Issue: `MultiFactorStressCalculator`, all 5 `*StressFactor.swift`, `BaselineCalculator`, `StressCalculator`, and protocols exist as separate copies in both the app and watch targets. All 8 duplicated files have diverged. The drift is behavioral, not cosmetic: the app's `StressMonitor/StressMonitor/Services/Algorithm/HeartRateStressFactor.swift` computes per-reading confidence (downgrades to as low as 0.4 when HR < 50 or > 160), while the watch copy `"StressMonitor/StressMonitorWatch Watch App/Services/HeartRateStressFactor.swift"` hardcodes `confidence: 1.0` and lacks the confidence helper entirely. Line counts: app vs watch — MultiFactorStressCalculator 104/78, HeartRateStressFactor 40/18, HRVStressFactor 71/44, SleepStressFactor 40/20, ActivityStressFactor 54/24, RecoveryStressFactor 54/29, BaselineCalculator 97/93, StressCalculator 118/99.
- Files: `StressMonitor/StressMonitor/Services/Algorithm/*.swift` vs `StressMonitor/StressMonitorWatch Watch App/Services/*.swift`
- Impact: Phone and watch produce silently different stress scores and confidence values for the same HealthKit input; every algorithm improvement lands only on the phone.
- Fix approach: Extract shared algorithm sources into a local Swift package (or a shared framework with both targets), or at minimum add a CI diff check that fails when the file pairs diverge.

**Five near-identical ~530-570-line character views:**
- Issue: `LumiCharacterView`, `EmberCharacterView`, `BlossomCharacterView`, `ZephyrCharacterView`, `RippleCharacterView` are structural clones (Lumi vs Ember after name normalization: ~367 differing lines out of ~535 — the rest is copy-paste animation/geometry). All exceed the 400-line `file_length` lint threshold.
- Files: `StressMonitor/StressMonitor/Components/Character/LumiCharacterView.swift` (533), `EmberCharacterView.swift` (539), `BlossomCharacterView.swift` (552), `ZephyrCharacterView.swift` (532), `RippleCharacterView.swift` (573)
- Impact: Any animation/bugfix must be replicated 5 times; each copy is a lint violation.
- Fix approach: Parameterize one `CharacterView` with a per-character configuration (shapes, palette, animation curves) and delete the clones.

**SwiftLint signal buried under 1.6 GB of vendored SPM checkouts:**
- Issue: `.swiftlint.yml` sets `included: [StressMonitor]` but the `excluded` list omits `StressMonitor/spm-cache/` — a gitignored 1.6 GB directory holding full checkouts of firebase-ios-sdk and swift-protobuf. Raw `swiftlint lint` reports 8,081 violations, of which ~7,398 come from vendored code; only 683 are first-party. CI runs `swiftlint lint || true` (`.github/workflows/_test.yml:54-58`), so nothing blocks regardless.
- Files: `.swiftlint.yml`, `StressMonitor/spm-cache/` (gitignored)
- Impact: Lint output is effectively unusable without manual filtering; the advisory CI gate hides even the 2,196 "error"-severity raw findings; real violations (109 `force_unwrapping`, 133 `identifier_name`, 92 `vertical_whitespace_closing_braces`, 59 `line_length` first-party) never get triaged.
- Fix approach: Add `StressMonitor/spm-cache` to `excluded` in `.swiftlint.yml`, then burn down the 683 real violations (starting with `force_unwrapping`). Only after that, consider removing `|| true` from CI.

**Stale documentation contradicting the build:**
- Issue: README package table does not match the pbxproj (per AGENTS.md); older docs claim "iOS 17+" (actual: iOS 18.6, some targets 26.1, watchOS 11.6 per pbxproj deployment targets); AGENTS.md states `GoogleService-Info.plist` is "committed" but it is gitignored (`.gitignore:174`) and untracked; WINDOWS.md ledger entry #4 still lists `signInWithGoogle` as a stub although `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:83-90` implements it via `GIDSignIn`.
- Files: `README.md`, `AGENTS.md`, `.planning/WINDOWS.md`, `docs/` (multiple)
- Impact: Agents following docs make wrong assumptions about dependencies, min deployment, and Firebase availability; stale ledger entries inflate the open-defect count that `/gsd-ship` gates on.
- Fix approach: Correct AGENTS.md's plist claim, refresh the README dependency table from `project.pbxproj`, mark WINDOWS #4 fixed (`gsd-tools windows fixed 4`) after verifying Google Sign-In.

**Test target requires manual pbxproj surgery for every new test file:**
- Issue: `StressMonitorTests` uses an explicit `PBXSourcesBuildPhase` file list (not a `PBXFileSystemSynchronizedRootGroup` like the app target). A test file created on disk but not added to the pbxproj silently never compiles or runs — while the suite stays green. This already happened: `FirebaseBootstrapTests.swift` and `AuthServiceErrorTests.swift` were committed but inert until fixed in commit `6227803`.
- Files: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (StressMonitorTests target)
- Impact: High risk of silently-invisible tests; green CI provides false assurance.
- Fix approach: Migrate the test target to a `PBXFileSystemSynchronizedRootGroup` (Xcode 16+), or add a CI check comparing `git ls-files StressMonitor/StressMonitorTests/*.swift` against the pbxproj sources list.

## Known Bugs

**Journal "Save" silently discards the user's entry:**
- Symptoms: User types a journal note, taps Save, feels the success haptic, sheet dismisses — the note is gone. Nothing is persisted.
- Files: `StressMonitor/StressMonitor/Views/Journal/NoteEntryView.swift:66-70`
- Trigger: Any use of the journal note entry flow.
- Workaround: None for the user. The bug is marked `// TODO: Implement persistence`.

**6 pre-existing unit test failures (WINDOWS.md #8, open since 2026-08-16):**
- Symptoms: Full-suite `xcodebuild test` reports 6 failures: 4 in "CloudKit Failure & Cancellation Ordering", 2 in "Data Export Field Selection" — cold-launch host restarts where the tests themselves pass; recent orchestrator run (2026-08-29): 244 total, 223 passed, 6 failed, 15 skipped.
- Files: `StressMonitor/StressMonitorTests/` (CloudKit + Data Export suites)
- Trigger: Full-suite runs; host restarts cluster on these suites.
- Workaround: Treat as known flake; signature-match against `.planning/WINDOWS.md` entry #8 before investigating.

**All Firebase-dependent features are dead in CI-produced builds (TestFlight/App Store):**
- Symptoms: `FirebaseApp.configure()` no-ops because `GoogleService-Info.plist` is gitignored (`.gitignore:174`) and CI has no provisioning step; anonymous auth, AI Chat, credits, IAP grant, and Google Sign-In all fail in distributed builds. `FirebaseBootstrap` (`StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift`) now logs an os.Logger `.fault` making it diagnosable, but the fix (CI secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` + `ci_scripts/provision_firebase_config.sh`) was deferred — Quick task 260829-kby Tasks 1-2, unchecked in `.planning/quick/260829-kby-provision-googleservice-info-plist-in-ci/260829-kby-PLAN.md`.
- Files: `.gitignore:174`, `StressMonitor/StressMonitor/GoogleService-Info.plist` (local only), `.github/workflows/*.yml`
- Trigger: Every build produced by CI (TestFlight beta, App Store release).
- Workaround: Local builds work because developers carry the plist on disk.

**Two StoreKit test suites disabled (WINDOWS.md #6, #7):**
- Symptoms: `EntitlementForegroundCorrectionTests` (StoreKitTest purchase throws `productNotFound`) and `StoreKitProductCatalogLiveTests` (custom `INFOPLIST_KEY_STOREKIT_*` settings never reach the generated Info.plist, live catalog resolves empty) are suite-disabled.
- Files: `StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift`, `StressMonitor/StressMonitorTests/StoreKitProductCatalogLiveTests.swift`
- Trigger: N/A — skipped by design (IAP-01).
- Workaround: IAP logic covered only by the `.storekit` config-backed suites that do run.

**Force-unwraps on live code paths:**
- Symptoms: `currentStress!` twice in the dashboard measurement save; `URL(string: resolved)!` in API config.
- Files: `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift:62,65`; `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:40`
- Trigger: Dashboard unwraps run immediately after a successful assignment (crash only if code is reordered); `StressAPIConfig` force-unwrap crashes at type-load time if any override tier supplies a malformed URL string ( UserDefaults key `stressAPIBaseURL` is user-writable).
- Workaround: None needed today; violates the repo's own `force_unwrapping` opt-in lint rule.

**Widget extension fatalErrors on missing App Group:**
- Symptoms: `fatalError("Unable to create UserDefaults with app group: ...")` in the widget data provider's initializer — a misconfigured App Group (e.g., entitlement change, new target) crashes the extension at launch instead of rendering a placeholder.
- Files: `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:46`
- Trigger: `group.stress.ai.com` unavailable in the extension process.
- Workaround: None.

## Security Considerations

**Firebase config provisioning gap:**
- Risk: Release builds ship without `GoogleService-Info.plist`; feature-dead builds reach testers (operational risk, not a leak). The plist itself contains an API key/IDs that are not secret by Firebase design, but keeping it out of git is the current posture — preserve that when adding CI provisioning.
- Files: `.gitignore:174`, `.github/workflows/_test.yml`, `.github/workflows/deploy.yml`
- Current mitigation: `FirebaseBootstrap` logs a `.fault` and a red unit test (`StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift`) flags a missing plist at build time.
- Recommendations: Implement 260829-kby Tasks 1-2: GitHub/Xcode Cloud secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` + `ci_scripts/provision_firebase_config.sh`, with `secrets: inherit` at call sites.

**Production base URL is UserDefaults-overridable:**
- Risk: `StressAPIConfig` resolves the backend URL from Info.plist → env → `UserDefaults.standard` key `stressAPIBaseURL` → hardcoded `https://stress-api.dropitx.site`. The UserDefaults tier means anything that can write the app's defaults can redirect every authenticated request (which carries a Firebase Bearer ID token) to an attacker-controlled host.
- Files: `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:9-14,28-41`
- Current mitigation: HTTPS-only fallback; no ATS exceptions found in `StressMonitor/StressMonitor/Info.plist`.
- Recommendations: Gate the UserDefaults override behind `#if DEBUG` (it exists as a debug seam), or constrain it to known hosts.

**Auth token handling:**
- Risk: Low. Bearer tokens are injected per-request via `AuthServiceProtocol` (`StressMonitor/StressMonitor/Services/API/StressAPIClient.swift:61-65`); no token logging found; legacy Keychain wipe on sign-out exists (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:126`, `StressMonitor/StressMonitor/Services/KeychainService.swift`).
- Current mitigation: Firebase ID tokens (short-lived), `/health` is the only unauthenticated endpoint.
- Recommendations: Keep the `StressAPIConfig` override fix in mind as the main hardening item.

**Destructive local-store recovery on migration failure:**
- Risk: When the SwiftData `ModelContainer` fails to open/migrate, `makeRecoveredContainer` deletes the store files (`-wal`/`-shm` included) and rebuilds local-only. A user's local history is wiped on a failed migration; CloudKit is the only recovery path (and the recovered container disables CloudKit for that session: `cloudKitDatabase: .none`).
- Files: `StressMonitor/StressMonitor/StressMonitorApp.swift:100-145,174-179`
- Current mitigation: Errors are logged (`persistenceLogger`); in-memory `try!` fallback at line 141 is a last resort after recovery itself failed.
- Recommendations: Consider renaming/moving the failed store aside instead of deleting it, so support can recover data.

## Performance Bottlenecks

**spm-cache inside the working tree:**
- Problem: `StressMonitor/spm-cache/` holds 1.6 GB of resolved SPM package checkouts inside the repo directory (gitignored).
- Files: `StressMonitor/spm-cache/`
- Cause: Local package cache location choice; slows any naive recursive tooling (grep/find/lint) and inflates local disk usage.
- Improvement path: Keep it (it is ignored), but exclude it from `.swiftlint.yml` and from any glob-based tooling; document it in STRUCTURE docs so agents skip it.

**Dashboard writes a measurement on every initial load:**
- Problem: `refreshStressLevel()` saves a `StressMeasurement(timestamp: Date())` each time the dashboard first appears (`DashboardViewModel.swift:60-67`); there is no dedup/minimum-interval in `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` `save(_:)`.
- Files: `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift`, `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift:47`
- Cause: App-launch writes accumulate rows in SwiftData + CloudKit.
- Improvement path: Debounce or coalesce measurements within a time window before saving.

## Fragile Areas

**App bootstrap chain (container → CloudKit → Firebase):**
- Files: `StressMonitor/StressMonitor/StressMonitorApp.swift:82-168`
- Why fragile: Three-tier fallback (primary container → store-deleting recovery → in-memory `try!`), CloudKit disabled when `XCTestConfigurationFilePath` is set, anonymous sign-in Task gated on `FirebaseBootstrap` state. Test-host behavior differs from production behavior by design (documented inline), and any change here risks CI hangs (the exact class of problem that produced the `GSD_CI` skip gate).
- Safe modification: Read the inline comments at each tier; never enable CloudKit for test hosts; keep sign-in behind `.configured`.
- Test coverage: `FirebaseBootstrapTests`, `DataDeletionConsolidationTests` (skipped on CI).

**Watch algorithm copies:**
- Files: `StressMonitor/StressMonitorWatch Watch App/Services/` (algorithm files listed above)
- Why fragile: No test target covers the watch copies; drift is invisible to CI; behavior already diverges (confidence model).
- Safe modification: Mirror any app-side algorithm change into the watch copy in the same commit, or land the shared-package extraction first.
- Test coverage: None for the watch copies.

**Test-infrastructure static stub state:**
- Files: `StressMonitor/StressMonitorTests/StressAPIClientTests.swift` (`RequestCaptureURLProtocol` response statics), `StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift`
- Why fragile: URLProtocol stub statics persist across tests in one launch; WINDOWS #12 documented order-dependent pollution (fixed at producer+consumer seams in commits `c2d6922`/`4444e85`), but the single-response statics pattern remains — a new test that stubs by path can shadow later stubs.
- Safe modification: Reset `RequestCaptureURLProtocol` statics in every test's teardown; prefer per-test stub registration.
- Test coverage: Regression covered by the combined 11-suite run documented in WINDOWS #12.

**DataDeleterService (factory-reset surface):**
- Files: `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` (563 lines), `CloudKitResetService.swift` (551), `DataExportView.swift` (614), `DataDeleteView.swift` (490)
- Why fragile: The factory-reset path orchestrates server session wipe (auth-error-type sensitive — must keep skipping on `AuthServiceError.notSignedIn`/`.notConfigured` AND legacy `LLMServiceError.unavailable`), CloudKit zone reset, and local store deletion; `file_length` lint violations; error-type taxonomy was just migrated (commits `4558c95`, `6227803`).
- Safe modification: Preserve all three skip arms in `wipeServerSessionsOrSkip`; run `DataDeleterServerWipeTests` + `DataDeletionConsolidationTests` after any change.
- Test coverage: Good locally, but the consolidation suite is skipped on CI (`GSD_CI`).

## Scaling Limits

**CI test job (host-restart flake):**
- Current capacity: Full suite ~244 tests; ~6 cold-launch host restarts per run.
- Limit: Host restarts consume the CI job's runtime and intermittently fail runs (WINDOWS #8); parallel testing is deliberately disabled.
- Scaling path: Add a test-only scheme that does not embed the watch app (also removes the watchOS-runtime prerequisite on dev hosts — `xcodebuild test` is currently impossible without the watchOS 26.2 simulator runtime installed, per 260829-kby verification notes); split flaky CloudKit suites into a separate job.

**SwiftData + CloudKit sync:**
- Current capacity: Per-user measurement history with CloudKit mirroring.
- Limit: Unbounded row growth (see dashboard write-on-load above); CloudKit disabled during test-host launches.
- Scaling path: Measurement coalescing + retention pruning.

## Dependencies at Risk

**SPM dependency set is minimal and current (firebase-ios-sdk for Auth, GoogleSignIn-iOS):**
- Risk: Low. Umbrella firebase package pulls large transitive graph (1.6 GB spm-cache) but only Auth/Firestore-adjacent pieces are linked per pbxproj.
- Impact: Build times; spm-cache disk usage.
- Migration plan: None required. If slimming is desired, switch to granular `FirebaseAuth` product-only dependency.

## Missing Critical Features

**CI provisioning of Firebase config:**
- Problem: No `ci_scripts/provision_firebase_config.sh`, no `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret — release/auth/AI-chat pipeline incomplete.
- Blocks: TestFlight testing of any authenticated flow (chat, credits, IAP grant, Google Sign-In).

**Journal persistence:**
- Problem: No storage behind the journal note UI (see Known Bugs).
- Blocks: The entire journaling feature.

## Test Coverage Gaps

**Watch target algorithm copies:**
- What's not tested: Every duplicated algorithm file under `StressMonitor/StressMonitorWatch Watch App/Services/` — no watch test target exists.
- Files: see Fragile Areas above.
- Risk: Confirmed drift persists and worsens silently; watch scores cannot be trusted to match phone scores.
- Priority: High.

**CI-skipped suites (by design, but a real gap in CI assurance):**
- What's not tested on CI: `DataDeletionConsolidationTests` (both suites skip when `GSD_CI` is set — deliberate; stalls the CI test host; do not "fix" the gating), `CharacterEntitlementSyncTests` (CloudKit quarantine), 2 StoreKit suites (IAP-01), plus StoreKit-config-dependent skips.
- Files: `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift:238,375`, `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift`
- Risk: Factory-reset/data-integrity regressions surface only on local runs.
- Priority: Medium (documented; run locally before touching data-management code).

**Orphaned root test directory masquerading as coverage:**
- What's not tested: `StressMonitorTests/` at repo root (`HRVAnalyzerTests`, `MorningReadinessServiceTests`, `StressHistoryTests`, `StressPredictorTests`, `StressReadingTests`) — never compiled or run.
- Files: `StressMonitorTests/` (repo root)
- Risk: False sense of coverage for HRV/prediction code that actually lives (if at all) only in the orphaned source tree.
- Priority: High (delete alongside the orphaned sources).

**Auth error taxonomy + Firebase bootstrap (newly added, compiled and passing as of 2026-08-29):**
- What's covered: `FirebaseBootstrapTests.swift`, `AuthServiceErrorTests.swift` (23 passed suites after the `6227803` target-membership fix).
- Risk: Adding future test files without pbxproj entries repeats the silent-inert-test failure mode (see Tech Debt).
- Priority: Low.

---

*Concerns audit: 2026-08-29*

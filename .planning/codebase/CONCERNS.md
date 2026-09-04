# Codebase Concerns

**Analysis Date:** 2026-09-01

<!-- refreshed: 2026-09-01 -->

## Tech Debt

**Deploy pipeline never auto-fires — merged code gets no CI and no TestFlight deploy:**
- Issue: `.github/workflows/deploy.yml:3-8` triggers on `workflow_run: workflows: [CI], branches: [main, release/*]`, but the workflow it watches — `.github/workflows/ci.yml:3-6` (name `CI`) — only triggers on `pull_request` (branches `main`, `develop`) and `workflow_dispatch`. There is no `push:` trigger, so a "CI" run never *completes on* `main` after a merge; the `workflow_run` condition is unreachable. Deploy is effectively manual-only (`gh workflow run deploy.yml`). Merges to `main` therefore run neither CI nor deploy, and even the manual deploy path builds from an un-CI'd commit (deploy.yml calls `_test.yml`'s build jobs itself, but the `test` job only runs via `ci.yml` on PRs).
- Files: `.github/workflows/deploy.yml`, `.github/workflows/ci.yml`, `.github/workflows/_test.yml`
- Impact: Main can silently accumulate broken builds; TestFlight releases depend on someone remembering to run the workflow manually; the apparent automation is an illusion for anyone reading deploy.yml.
- Fix approach: Add `push: branches: [main, release/*]` to `ci.yml` (which also revives the auto-deploy chain), or replace deploy.yml's `workflow_run` with a direct `push` trigger. Verify `workflow_run` actually fires for the default branch after the change.

**DEBUG builds run the entire money path through `MockStoreKitService`:**
- Issue: Two `#if DEBUG` seams swap the real purchase service for a mock: `StressMonitor/StressMonitor/StressMonitorApp.swift:246-250` (`makeStoreKitService` returns `MockStoreKitService(premiumState: .shared)`) and `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift:12-16` (the SwiftUI environment default). Every local dev/simulator session exercises the mock, never the real `StoreKitService` wiring — its init-time `Transaction.updates` listener, deferred JWS redeem, entitlement refresh, and server sync only execute in Release builds.
- Files: `StressMonitor/StressMonitor/StressMonitorApp.swift`, `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift`, `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift`
- Impact: Integration breakage in the real purchase path (init crashes, listener wiring, StoreKit environment values) surfaces only in Release/TestFlight; a "works on my simulator" pass proves nothing about IAP. The real class has unit coverage via injected seams (`StoreKitServiceTests`), but the app-side wiring does not.
- Fix approach: Gate the mock behind an explicit launch argument (e.g. `-mock-iap`) or a `#if DEBUG && MOCK_IAP` style flag so debug builds can opt into the real `.storekit`-backed flow; at minimum, add one Release-config test host smoke of `StoreKitService.init`.

**Orphaned pre-MVVM code tree (5,717 lines of dead, git-tracked source):**
- Issue: Four directories from an earlier project layout are committed to git but have ZERO references in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` — edits there never build, run, or test: `StressMonitor/Models/` (3 files), `StressMonitor/Services/` (7 files), `StressMonitor/Views/` (8 files), `StressMonitorTests/` (repo root, 5 files). The single largest Swift file in the repo — 840-line `StressMonitor/Views/StressHistoryView.swift` — is in this dead tree, as are 410-line `StressMonitor/Services/HRVAnalyzer.swift`, 395-line `StressMonitor/Services/CloudKitManager.swift`, and `StressMonitor/Services/StressPredictor.swift`.
- Files: `StressMonitor/Models/`, `StressMonitor/Services/`, `StressMonitor/Views/`, `StressMonitorTests/` (repo root — distinct from the live `StressMonitor/StressMonitorTests/`)
- Impact: Agents and humans routinely edit these files believing they are live; greps return duplicate "hits" that mislead navigation; dead tests imply coverage that does not exist.
- Fix approach: `git rm -r` all four directories (each checked file is confirmed absent from the pbxproj: `StressHistoryView`/`HRVAnalyzer`/`CloudKitManager`/`StressPredictor`/`StressReading`/`MorningReadinessService` all grep to 0 hits). Keep history in git, not the working tree.

**Watch target algorithm duplication has already drifted (not just a risk):**
- Issue: The algorithm exists as separate copies in the app and watch targets, and all duplicated pairs have diverged. The drift is behavioral, not cosmetic: the app's `StressMonitor/StressMonitor/Services/Algorithm/HeartRateStressFactor.swift:22-26` computes per-reading confidence, while the watch copy `StressMonitor/StressMonitorWatch Watch App/Services/HeartRateStressFactor.swift:16` hardcodes `confidence: 1.0` and lacks the confidence helper entirely. Line counts (app/watch): MultiFactorStressCalculator 104/78, HeartRateStressFactor 40/18, HRVStressFactor 71/44, SleepStressFactor 40/20, ActivityStressFactor 54/24, RecoveryStressFactor 54/29, StressFactor protocol 22/13, StressCalculator 118/99, BaselineCalculator 97/93. Additionally `BioAgeCalculator.swift` (181 lines) and `FactorCalibrator.swift` (56) exist ONLY in the app target — the watch has no counterpart at all.
- Files: `StressMonitor/StressMonitor/Services/Algorithm/*.swift` vs `StressMonitor/StressMonitorWatch Watch App/Services/*.swift`
- Impact: Phone and watch produce silently different stress scores and confidence values for the same HealthKit input; every algorithm improvement (bio-age, calibration, confidence) lands only on the phone.
- Fix approach: Extract shared algorithm sources into a local Swift package linked by both targets, or at minimum add a CI diff check that fails when the duplicated file pairs diverge.

**Five near-identical ~530-570-line character views:**
- Issue: `LumiCharacterView`, `EmberCharacterView`, `BlossomCharacterView`, `ZephyrCharacterView`, `RippleCharacterView` are structural clones (Lumi vs Ember after name normalization: ~367 differing lines out of ~535 — the rest is copy-paste animation/geometry). All exceed the 400-line `type_body_length` lint threshold.
- Files: `StressMonitor/StressMonitor/Components/Character/LumiCharacterView.swift` (533), `EmberCharacterView.swift` (539), `BlossomCharacterView.swift` (552), `ZephyrCharacterView.swift` (532), `RippleCharacterView.swift` (573)
- Impact: Any animation/bugfix must be replicated 5 times; each copy is a lint violation.
- Fix approach: Parameterize one `CharacterView` with a per-character configuration (shapes, palette, animation curves) and delete the clones.

**SwiftLint signal buried under 1.3 GB of vendored SPM checkouts:**
- Issue: `.swiftlint.yml` sets `included: [StressMonitor]` but the `excluded` list omits `StressMonitor/spm-cache/` — a gitignored 1.3 GB directory (measured on disk) holding full checkouts of firebase-ios-sdk and transitive packages. A raw `swiftlint lint` run last measured ~8,081 total violations, of which ~7,398 came from vendored code; ~683 were first-party. CI runs `swiftlint lint ... || true` (`.github/workflows/_test.yml:55,58`), so nothing blocks regardless.
- Files: `.swiftlint.yml`, `StressMonitor/spm-cache/` (gitignored)
- Impact: Lint output is effectively unusable without manual filtering; the advisory CI gate hides even error-severity findings; real first-party violations (force_unwrapping, identifier_name, vertical_whitespace_closing_braces, line_length) never get triaged.
- Fix approach: Add `StressMonitor/spm-cache` to `excluded` in `.swiftlint.yml`, then burn down the real first-party violations (starting with `force_unwrapping`). Only after that, consider removing `|| true` from CI.

**Stale documentation contradicting the build:**
- Issue: `AGENTS.md:56` states `GoogleService-Info.plist` is "committed" but it is gitignored (`.gitignore:174`) and untracked; older docs claim "iOS 17+" (actual: iOS 18.6+ per pbxproj deployment targets) in `docs/codebase-summary.md`, `docs/deployment-guide.md`, `docs/deployment-guide-environment.md`, `docs/ARCHITECTURE.md`, `docs/plans/AI-CHAT-COMPLETION-PLAN.md`. The WINDOWS.md ledger has drifted from reality in both directions: frontmatter says `open_count: 12 / fixed_count: 0` while three rows (#9, #10, #11) are marked `closed` with 2026-08-23 resolutions; entry #4 still lists `signInWithGoogle` as a stub although `StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:84+` implements it via `GIDSignIn`; entry #7 describes `StoreKitProductCatalogLiveTests` as suite-disabled but the file now carries no `.disabled` attribute and runs.
- Files: `AGENTS.md`, `README.md`, `.planning/WINDOWS.md`, `docs/` (multiple)
- Impact: Agents following docs make wrong assumptions about dependencies, min deployment, and Firebase availability; the stale ledger inflates the open-defect count that `/gsd-ship` gates on (with `workflow.windows_enforce`, a wrong `open_count` over-blocks shipping).
- Fix approach: Correct AGENTS.md's plist claim, refresh the README dependency table from `project.pbxproj`, reconcile WINDOWS.md counters with row statuses, and mark #4/#7 fixed (`gsd-tools windows fixed 4` / `fixed 7`) after re-confirming the live-test pass.

**Test target requires manual pbxproj surgery for every new test file:**
- Issue: The `StressMonitorTests` native target (`StressMonitor/StressMonitor.xcodeproj/project.pbxproj`, target `0685AF23B64355DB99B05140`) compiles from an explicit `PBXSourcesBuildPhase` file list, not from a `fileSystemSynchronizedGroups` entry. A `PBXFileSystemSynchronizedRootGroup` named `StressMonitorTests` (id `F2E2EBFB2F1CC556000C2B53`) does exist in the project but is referenced only from the main group (navigator display) — it is NOT wired to the test target's build. Worst of both worlds: files appear auto-synced in Xcode's UI while silently not compiling. This already bit: `FirebaseBootstrapTests.swift` and `AuthServiceErrorTests.swift` were committed but inert until fixed in commit `6227803`.
- Files: `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (StressMonitorTests target)
- Impact: High risk of silently-invisible tests; green CI provides false assurance.
- Fix approach: Attach the existing synchronized group to the test target (`fileSystemSynchronizedGroups`) and drop the explicit build-file list, or add a CI check comparing `git ls-files StressMonitor/StressMonitorTests/*.swift` against the pbxproj sources list.

## Known Bugs

**Journal "Save" silently discards the user's entry:**
- Symptoms: User types a journal note, taps Save, feels the success haptic, sheet dismisses — the note is gone. Nothing is persisted.
- Files: `StressMonitor/StressMonitor/Views/Journal/NoteEntryView.swift:66-70`
- Trigger: Any use of the journal note entry flow.
- Workaround: None for the user. The bug is marked `// TODO: Implement persistence`.

**6 pre-existing unit test failures / host-restart lineage (WINDOWS.md #8, open since 2026-08-16):**
- Symptoms: Full-suite `xcodebuild test` reports 6 failures clustered as cold-launch host restarts in "CloudKit Failure & Cancellation Ordering" and "Data Export Field Selection" — the tests themselves pass; last recorded full run (2026-08-29): 244 total, 223 passed, 6 failed, 15 skipped. Both suites are now compile-time disabled on CI via `@Suite(.enabled(if: ProcessInfo.processInfo.environment["GSD_CI"] == nil))` (`DataDeletionConsolidationTests.swift:238,375`), with `TEST_RUNNER_GSD_CI: "1"` forwarded by the test job (`.github/workflows/_test.yml:177-182`) — do not "fix" this gating until #8 is root-caused.
- Files: `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`, `.planning/WINDOWS.md` (#8)
- Trigger: Full-suite runs; host restarts cluster on these suites.
- Workaround: Treat as known flake; signature-match against WINDOWS.md entry #8 before investigating.

**Quarantined `CharacterEntitlementSyncTests` — entitlement sync has zero coverage:**
- Symptoms: The whole suite is `@Suite(.disabled("Reliable test-host hang on this toolchain — see file header"))`. The file header documents an extensive bisection (not CloudKit setup, not the app-level container, not WidgetCenter XPC, not serialization/ordering); the trigger is real SwiftData work (ModelContainer + insert + save against `CharacterUnlock`) specific to this suite on Xcode 26.3 / iOS 26.2-26.3 simulators; the mechanism remains unconfirmed. `syncPremiumCharacterEntitlement` itself has no other test coverage.
- Files: `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift`
- Trigger: Enabling the suite hangs the XCTest host with zero console diagnostics.
- Workaround: Production path partially exercised by `CharacterCollectionViewModelTests` (identical container pattern, passes).

**All Firebase-dependent features are dead in CI-produced builds (TestFlight/App Store):**
- Symptoms: `FirebaseApp.configure()` no-ops because `GoogleService-Info.plist` is gitignored (`.gitignore:174`) and CI has no provisioning step; anonymous auth, AI Chat, credits, IAP grant, and Google Sign-In all fail in distributed builds. `FirebaseBootstrap` (`StressMonitor/StressMonitor/Services/Firebase/FirebaseBootstrap.swift:36`) logs an os.Logger `.fault` making it diagnosable, but the fix (CI secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` + `ci_scripts/provision_firebase_config.sh`) was deferred — quick task 260829-kby Tasks 1-2 remain unchecked in `.planning/quick/260829-kby-provision-googleservice-info-plist-in-ci/260829-kby-PLAN.md`; no `GOOGLE_SERVICE_INFO*` reference exists anywhere in `.github/workflows/` or `ci_scripts/` (only `ci_post_clone.sh` and `ci_post_xcodebuild.sh` are present).
- Files: `.gitignore:174`, `StressMonitor/StressMonitor/GoogleService-Info.plist` (local only), `.github/workflows/*.yml`, `ci_scripts/`
- Trigger: Every build produced by CI (TestFlight beta, App Store release).
- Workaround: Local builds work because developers carry the plist on disk; fresh checkouts must obtain it out-of-band.

**`EntitlementForegroundCorrectionTests` still suite-disabled (WINDOWS.md #6):**
- Symptoms: `@Suite(.serialized, .disabled("StoreKitTest cannot resolve subscription products — see file header and IAP-01"))` — StoreKitTest purchase throws `productNotFound`. Note the sibling ledger entry #7 (`StoreKitProductCatalogLiveTests`) is stale: that suite has NO disable attribute and runs (see Tech Debt / stale docs).
- Files: `StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift`
- Trigger: N/A — skipped by design (IAP-01).
- Workaround: Entitlement-correction logic covered by the `.storekit`-config-backed suites that do run.

**Force-unwraps on live code paths:**
- Symptoms: `currentStress!` twice in the dashboard measurement save; `URL(string: resolved)!` in API config.
- Files: `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift:62-66`; `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:40`
- Trigger: Dashboard unwraps run immediately after a successful assignment (crash only if code is reordered); `StressAPIConfig` force-unwrap crashes at type-load time if any override tier supplies a malformed URL string (UserDefaults key `stressAPIBaseURL` is user-writable).
- Workaround: None needed today; violates the repo's own `force_unwrapping` opt-in lint rule.

**Widget extension fatalErrors on missing App Group:**
- Symptoms: `fatalError("Unable to create UserDefaults with app group: ...")` in the widget data provider's initializer — a misconfigured App Group (e.g. entitlement change, new target, provisioning profile without the capability) crashes the extension at launch instead of rendering a placeholder. Compounding: WINDOWS.md #2 records that the Developer Portal capability + Match profile regeneration were confirmed only by user attestation, never independently verified.
- Files: `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:46`, `.planning/WINDOWS.md` (#2)
- Trigger: `group.stress.ai.com` unavailable in the extension process.
- Workaround: None.

## Security Considerations

**Firebase config provisioning gap:**
- Risk: Release builds ship without `GoogleService-Info.plist`; feature-dead builds reach testers (operational risk, not a leak). The plist contains an API key/IDs that are not secret by Firebase design, but keeping it out of git is the current posture — preserve that when adding CI provisioning (the deferred plan's verify block already asserts `git check-ignore` keeps matching).
- Files: `.gitignore:174`, `.github/workflows/_test.yml`, `.github/workflows/deploy.yml`
- Current mitigation: `FirebaseBootstrap` logs a `.fault` and `StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift` flags a missing plist at build time.
- Recommendations: Implement 260829-kby Tasks 1-2: GitHub/Xcode Cloud secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` + `ci_scripts/provision_firebase_config.sh`, with `secrets: inherit` at call sites.

**Production base URL is UserDefaults-overridable:**
- Risk: `StressAPIConfig` resolves the backend URL from Info.plist → env → `UserDefaults.standard` key `stressAPIBaseURL` → hardcoded `https://stress-api.dropitx.site`. The UserDefaults tier means anything that can write the app's defaults can redirect every authenticated request (which carries a Firebase Bearer ID token) to an attacker-controlled host.
- Files: `StressMonitor/StressMonitor/Services/API/StressAPIConfig.swift:9-14,28-41`
- Current mitigation: HTTPS-only fallback; no ATS exceptions found in `StressMonitor/StressMonitor/Info.plist`.
- Recommendations: Gate the UserDefaults override behind `#if DEBUG` (it exists as a debug seam), or constrain it to known hosts.

**Auth token handling:**
- Risk: Low. Bearer tokens are injected per-request via `AuthServiceProtocol` (`StressMonitor/StressMonitor/Services/API/StressAPIClient.swift:57-70`, `authorizedRequest`); no token logging found; legacy Keychain wipe on sign-out exists (`StressMonitor/StressMonitor/Services/Auth/FirebaseAuthService.swift:126-134`, `StressMonitor/StressMonitor/Services/KeychainService.swift`).
- Current mitigation: Firebase ID tokens (short-lived); `/health` is the only unauthenticated endpoint.
- Recommendations: Keep the `StressAPIConfig` override fix in mind as the main hardening item.

**Destructive local-store recovery on migration failure:**
- Risk: When the SwiftData `ModelContainer` fails to open/migrate, `makeRecoveredContainer` deletes the store files (`""`, `-wal`, `-shm` via `removeStoreFiles`) and rebuilds local-only. A user's local history is wiped on a failed migration; CloudKit is the only recovery path (and the recovered container disables CloudKit for that session: `cloudKitDatabase: .none`). An in-memory `try!` fallback is the last resort if recovery itself fails.
- Files: `StressMonitor/StressMonitor/StressMonitorApp.swift:94-141` (`makeContainer`, `makeRecoveredContainer`, `removeStoreFiles`)
- Current mitigation: Errors are logged (`persistenceLogger`); the D5 decision (Option A: accept data loss) is documented inline.
- Recommendations: Consider renaming/moving the failed store aside instead of deleting it, so support can recover data.

## Performance Bottlenecks

**spm-cache inside the working tree:**
- Problem: `StressMonitor/spm-cache/` holds 1.3 GB (measured) of resolved SPM package checkouts inside the repo directory (gitignored).
- Files: `StressMonitor/spm-cache/`
- Cause: Local package cache location choice; slows any naive recursive tooling (grep/find/lint) and inflates local disk usage.
- Improvement path: Keep it (it is ignored), but exclude it from `.swiftlint.yml` and from any glob-based tooling; skip it during exploration.

**Dashboard writes a measurement on every initial load:**
- Problem: `refreshStressLevel()` saves a `StressMeasurement(timestamp: Date())` each time the dashboard first appears; there is no dedup/minimum-interval in `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` `save(_:)`.
- Files: `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift:60-67`, `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift`
- Cause: App-launch writes accumulate rows in SwiftData + CloudKit.
- Improvement path: Debounce or coalesce measurements within a time window before saving.

## Fragile Areas

**App bootstrap chain (container → CloudKit → Firebase):**
- Files: `StressMonitor/StressMonitor/StressMonitorApp.swift:82-180`
- Why fragile: Three-tier fallback (primary container → store-deleting recovery → in-memory `try!`), CloudKit disabled when `XCTestConfigurationFilePath` is set, anonymous sign-in gated on `FirebaseBootstrap` state, plus the `#if DEBUG` mock-StoreKit seam in `makeStoreKitService`. Test-host behavior deliberately differs from production, and any change here risks CI hangs (the exact class of problem that produced the `GSD_CI` skip gate).
- Safe modification: Read the inline comments at each tier; never enable CloudKit for test hosts; keep sign-in behind `.configured`.
- Test coverage: `FirebaseBootstrapTests`, `DataDeletionConsolidationTests` (skipped on CI).

**Purchase → server-JWS-verification money path:**
- Files: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` (529 lines)
- Why fragile: Correctness depends on a subtle ordering contract — packs redeem the JWS BEFORE `finish()` (a finished consumable is unrecoverable), refunded packs finish WITHOUT redemption (the server permanently rejects that JWS; retrying would wedge the queue), subscriptions keep immediate finish with best-effort server sync (DEC-1), and revocation/expiry posting policy is enumeration-sensitive. If `redeemer` throws (network drop) after Apple charged the user, the transaction stays unfinished and credits arrive only when `Transaction.updates` redelivers (typically next launch) — by design, but user-visible as "paid, no credits yet". The whole path only runs in Release (DEBUG uses `MockStoreKitService`).
- Safe modification: Preserve the grant/finish ordering in `completePurchase` and the revoked-pack early-return; run `StoreKitServiceTests` + the live `.storekit`-backed suites after any change.
- Test coverage: Ordering unit-pinned via the `PurchaseTransactionHandle`/`PurchaseRedeemer` seams; live Apple success path validated only by the 2026-08-23 sandbox UAT (WINDOWS #10, closed).

**Watch algorithm copies:**
- Files: `StressMonitor/StressMonitorWatch Watch App/Services/` (algorithm files listed under Tech Debt)
- Why fragile: No test target covers the watch copies; drift is invisible to CI; behavior already diverges (confidence model; bio-age/calibration absent).
- Safe modification: Mirror any app-side algorithm change into the watch copy in the same commit, or land the shared-package extraction first.
- Test coverage: None for the watch copies.

**Test-infrastructure static stub state:**
- Files: `StressMonitor/StressMonitorTests/StressAPIClientTests.swift` (`RequestCaptureURLProtocol` response statics), `StressMonitor/StressMonitorTests/ChatHistoryRestoreTests.swift`
- Why fragile: URLProtocol stub statics persist across tests in one launch; WINDOWS #12 documented order-dependent pollution (fixed at producer+consumer seams in commits `c2d6922`/`4444e85`), but the single-response statics pattern remains — a new test that stubs by path can shadow later stubs.
- Safe modification: Reset `RequestCaptureURLProtocol` statics in every test's teardown; prefer per-test stub registration.
- Test coverage: Regression covered by the combined 11-suite run documented in WINDOWS #12.

**DataDeleterService (factory-reset surface):**
- Files: `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` (563 lines), `CloudKitResetService.swift` (551), `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift` (614), `DataDeleteView.swift` (490)
- Why fragile: The factory-reset path orchestrates server session wipe (auth-error-type sensitive — must keep skipping on `AuthServiceError.notSignedIn`/`.notConfigured` AND legacy `LLMServiceError.unavailable`), CloudKit zone reset, and local store deletion; `file_length` lint violations; error-type taxonomy was just migrated (commits `4558c95`, `6227803`).
- Safe modification: Preserve all three skip arms in `wipeServerSessionsOrSkip`; run `DataDeleterServerWipeTests` + `DataDeletionConsolidationTests` after any change.
- Test coverage: Good locally, but the consolidation suite is skipped on CI (`GSD_CI`).

## Scaling Limits

**CI test job (host-restart flake):**
- Current capacity: Full suite ~244 tests; ~6 cold-launch host restarts per run.
- Limit: Host restarts consume the CI job's runtime and intermittently fail runs (WINDOWS #8); parallel testing is deliberately disabled (`-parallel-testing-enabled NO`, `-maximum-concurrent-test-simulator-destinations 1` in `_test.yml:192-193`).
- Scaling path: Add a test-only scheme that does not embed the watch app (also removes the watchOS-runtime prerequisite on dev hosts — `xcodebuild test` is currently impossible without the watchOS 26.2 simulator runtime installed); split flaky CloudKit suites into a separate job.

**SwiftData + CloudKit sync:**
- Current capacity: Per-user measurement history with CloudKit mirroring.
- Limit: Unbounded row growth (see dashboard write-on-load above); CloudKit disabled during test-host launches.
- Scaling path: Measurement coalescing + retention pruning.

## Dependencies at Risk

**SPM dependency set is minimal and current (firebase-ios-sdk for Auth, GoogleSignIn-iOS):**
- Risk: Low. The umbrella firebase package pulls a large transitive graph (1.3 GB spm-cache) but only Auth-adjacent pieces are linked per pbxproj.
- Impact: Build times; spm-cache disk usage.
- Migration plan: None required. If slimming is desired, switch to granular `FirebaseAuth` product-only dependency.

## Missing Critical Features

**CI provisioning of Firebase config:**
- Problem: No `ci_scripts/provision_firebase_config.sh`, no `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret — release/auth/AI-chat pipeline incomplete.
- Blocks: TestFlight testing of any authenticated flow (chat, credits, IAP grant, Google Sign-In).

**Auto-deploy on merge:**
- Problem: No `push` trigger anywhere in the CI→deploy chain (see Tech Debt).
- Blocks: Continuous TestFlight delivery from `main`; merged commits ship only when someone manually runs deploy.

**Journal persistence:**
- Problem: No storage behind the journal note UI (see Known Bugs).
- Blocks: The entire journaling feature.

## Test Coverage Gaps

**Watch target algorithm copies:**
- What's not tested: Every duplicated algorithm file under `StressMonitor/StressMonitorWatch Watch App/Services/` — no watch test target exists.
- Files: see Fragile Areas above.
- Risk: Confirmed drift persists and worsens silently; watch scores cannot be trusted to match phone scores.
- Priority: High.

**Quarantined + CI-skipped suites (by design, but a real gap in assurance):**
- What's not covered where it matters: `CharacterEntitlementSyncTests` (hard-disabled everywhere — test-host hang, unexplained), `DataDeletionConsolidationTests` both suites (skip when `GSD_CI` is set — deliberate; stalls the CI test host; do not "fix" the gating), `EntitlementForegroundCorrectionTests` (StoreKitTest product resolution, WINDOWS #6), plus StoreKit-config-dependent skips. `syncPremiumCharacterEntitlement` currently has no passing coverage at all.
- Files: `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift`, `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift:238,375`, `StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift`
- Risk: Factory-reset/data-integrity/entitlement regressions surface only on local runs; entitlement drift between StoreKit and server goes uncaught.
- Priority: High for `CharacterEntitlementSyncTests` (unexplained hang deserves a dedicated debug session), Medium for the rest (documented; run locally before touching data-management code).

**Orphaned root test directory masquerading as coverage:**
- What's not tested: `StressMonitorTests/` at repo root (`HRVAnalyzerTests`, `MorningReadinessServiceTests`, `StressHistoryTests`, `StressPredictorTests`, `StressReadingTests`) — never compiled or run.
- Files: `StressMonitorTests/` (repo root)
- Risk: False sense of coverage for HRV/prediction code that actually lives (if at all) only in the orphaned source tree.
- Priority: High (delete alongside the orphaned sources).

**Release-config StoreKit wiring:**
- What's not tested: The real `StoreKitService` as wired into the app (init, `Transaction.updates` listener, environment default) — DEBUG builds substitute `MockStoreKitService` (see Tech Debt), so no test host ever constructs the production default.
- Files: `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift`, `StressMonitor/StressMonitor/StressMonitorApp.swift:246-250`
- Risk: Release-only integration breakage in the money path.
- Priority: Medium.

**Auth error taxonomy + Firebase bootstrap:**
- What's covered: `FirebaseBootstrapTests.swift`, `AuthServiceErrorTests.swift` (passing after the `6227803` target-membership fix).
- Risk: Adding future test files without pbxproj entries repeats the silent-inert-test failure mode (see Tech Debt) — the synchronized-group decoy in the navigator makes this easier to miss, not harder.
- Priority: Low.

---

*Concerns audit: 2026-09-01*

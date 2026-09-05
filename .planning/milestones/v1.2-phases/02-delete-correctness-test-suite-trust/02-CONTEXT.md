# Phase 2: Delete Correctness & Test-Suite Trust - Context

**Gathered:** 2026-09-03
**Status:** Ready for planning

<domain>
## Phase Boundary

"Delete all data" is provably true everywhere the data lives — verified end-to-end across CloudKit propagation (not per-half), with a regression test that fails if batch-delete lies again — and the test suite becomes a gate that can be believed: one documented CI-parity invocation, zero unexplained failures, no silently disabled coverage (every skip/disabled suite carries a dated, root-cause-naming disposition), and both money-path advisories (WR-03, WR-04) dispositioned by fix. Covers DATA-01 residual, DATA-04, BUILD-04 (incl. the Phase-1 UIBackgroundModes finding), ENV-01, ENV-02, ENV-03.

</domain>

<decisions>
## Implementation Decisions

### Two-Device CloudKit Delete Verification (DATA-01)
- Apparatus: one device + the CloudKit dashboard console (developer account) as the second signed-in surface — delete on device, confirm records gone in the console; a second physical iPhone is used if available but is not required. Simulator+device is explicitly NOT acceptable evidence (CloudKit unreliable on simulator).
- Record scope: the full store set the app writes — StressMeasurement + preferences/quick-action caches in the CloudKit container — mirroring what the Delete All Data button actually claims.
- Cleared standard: query-based emptiness after a documented propagation wait (eventual consistency — record the observed delay); immediate-only checks are flaky and rejected.
- Evidence: a dated evidence note in the phase dir (01-WIRE-01-EVIDENCE.md pattern) with timestamps, surfaces checked, observed propagation delay, screenshots.

### Test-Suite Truth Dispositions (ENV-01 / ENV-02)
- WINDOWS.md #8: bounded re-diagnosis session (capture crash report, isolate suites, fresh simulator/runtime test); if root cause remains unknown, a dated disposition naming the best-known cause + accepted coverage loss — fix-or-bust is rejected (survived 5 ruled-out hypotheses).
- CharacterEntitlementSyncTests quarantine: same bounded-re-diagnosis pattern (money-path-adjacent coverage: syncPremiumCharacterEntitlement; suspected same host-crash family); re-enable blindly rejected; permanent quarantine without attempt rejected.
- Disposition bar: names the failure signature (exit 65, 0 assertion failures, affected suites), ruled-out causes, residual risk, and date — written to the WINDOWS.md ledger + phase verification report. Vague "known flaky" notes fail the bar.
- If a fix lands for either: remove the CI env gate / quarantine and restore the suite to the default run (no dead config).

### Money-Path Advisories (ENV-03 — WR-03 / WR-04)
- WR-03: fix — DEBUG defaults to the REAL StoreKit path; MockStoreKitService becomes explicit opt-in (launch arg or DEBUG toggle); tests keep the mock via DI.
- WR-04: fix — never finish unverified transactions; move .finish() behind the verified branch at all call sites (Phase-1 scout found 5 in StoreKitService).
- Verification bar: money-path suites stay green + new pinning tests (unverified transaction NOT finished; DEBUG config resolves the real service absent the override).
- Server side untouched — backend metering stays in phuongddx/stress-app-be#2.

### Regression Seam & Documented Invocation (DATA-04 / BUILD-04)
- DATA-04: a fail-lying spy conforming to CloudKitResetServiceProtocol (DI seam already exists in DataDeleterService.init) returns success while keeping rows in an in-memory store; the test pins the truthiness signal so it FAILS if the v1.0 CR-01 bug returns.
- BUILD-04: AGENTS.md stays the canonical invocation source; the _test.yml comment and a repo testing-doc one-liner cross-reference it. The documented invocation is the CI-parity form incl. TEST_RUNNER_GSD_CI=1 env-var gating (learned in Phase 1 — the env var must be exported, not passed as an xcodebuild argument).
- BUILD-04 folds in the Phase-1 UIBackgroundModes finding: one doc-truth note covering that custom INFOPLIST_KEY_* keys never merge (plist file is the source).
- Phase-end trust gate: full-suite run record with every suite enumerated, skipped suites named + dispositioned, zero failures, and a grep proving no new @Suite(.disabled)/xitest beyond the dispositioned set — count-only checks rejected (a disabled suite doesn't change counts).

### the agent's Discretion
Implementation details of the spy, the launch-arg/flag mechanism for the mock opt-in, disposition wording, and evidence-note structure are the executor's discretion within repo conventions.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- CloudKitResetServiceProtocol (CloudKitResetService.swift:9) — the DI seam for DATA-04 already exists (DataDeleterService.init injects it, line ~45)
- DataDeleterService — the consolidated delete orchestrator (v1.0 WIRE-02); server-wipe half live-verified in v1.1 Phase 3 UAT
- Deletion-aware fakes precedent — v1.1 Phase 3's 42-session wipe regression used exactly this pattern; RequestCaptureURLProtocol statics warning (STATE decisions) applies to suite ordering
- scripts/verify-archive.sh + harness (Phase 1) — pattern for red/green-gated tooling
- 01-WIRE-01-EVIDENCE.md — the dated-evidence-note pattern to reuse for DATA-01

### Established Patterns
- CI-parity test invocation: TEST_RUNNER_GSD_CI=1 (env var, NOT xcodebuild arg) + -parallel-testing-enabled NO, iPhone 16 (CI) / iPhone 17 (local)
- WINDOWS.md #8 suites gated .enabled(if: GSD_CI == nil) — local-run-by-default, CI-skipped
- StoreKitServiceEnvironment resolves Mock vs Real service (WR-03's lever)

### Integration Points
- StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift (both #8-gated suites + the suite-writing tests)
- StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift (5 .finish() sites, lines ~317-401)
- StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift + StressMonitorApp.swift (WR-03 wiring)
- .github/workflows/_test.yml (BUILD-04 cross-reference), AGENTS.md (canonical invocation)

</code_context>

<specifics>
## Specific Ideas

- The DATA-01 evidence note should disclose exactly which surfaces were checked and the observed propagation delay — no narrative claims without timestamps (Phase-1 demo-mode disclosure precedent).
- If a second physical iPhone IS available at execution time, prefer it over the console as the stronger second surface; the console remains the fallback.
- WR-04 fix must audit all five .finish() call sites — not just the one the advisory named.

</specifics>

<deferred>
## Deferred Ideas

- Backend /quick-actions metering (phuongddx/stress-app-be#2) — stays in the backend repo's scope.
- v1.1 Phase 03 drift re-test — not a v1.2 requirement; candidate target is the next TestFlight build (post-wiring), tracked in STATE.md.

</deferred>

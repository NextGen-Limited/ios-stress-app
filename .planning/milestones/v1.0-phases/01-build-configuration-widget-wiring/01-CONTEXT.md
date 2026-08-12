# Phase 1: Build Configuration & Widget Wiring - Context

**Gathered:** 2026-08-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Get the app to a state where it builds and archives correctly — valid Privacy Manifest, one canonical App Group entitlement across all 3 targets, a single Info.plist source of truth, and a real unit-test target that `xcodebuild test` can execute — and wire the home-screen widget to live data instead of permanent placeholder. This is the prerequisite phase: BUILD-02's App Group entitlement is a dependency for Phase 2 (Data Integrity), and BUILD-04's test target is what makes every subsequent phase's acceptance criteria independently verifiable.

</domain>

<decisions>
## Implementation Decisions

### Privacy Contract (D3)
- **D-01:** Backend contract is authoritative — `StressContextPayload` continues sending derived stress-context (HRV, HR, sleep, activity, recovery) to the `/chat` backend for AI coaching quality. `CLAUDE.md`, `README.md`, `docs/system-architecture*.md`, the privacy policy, and the ASC nutrition label must all be corrected to disclose exactly which health fields are transmitted — the current "never sent" claim is false and must not survive this phase. — **Reversibility:** costly — reversing later means redesigning `ChatContextBuilder` for on-device-only context *and* walking back an already-disclosed privacy policy/nutrition label, which reads as a regression to App Review and users alike.

### Widget Scope (D4)
- **D-02:** Ship the widget in v1. WIRE-01 stays in this phase's scope: wire `WidgetDataProvider.save*` to `StressViewModel`/`SyncManager`, call `WidgetCenter.reloadAllTimelines()` on update, add a staleness threshold with an explicit "no data" fallback state. — **Reversibility:** reversible — excluding the target later is a build-setting change, not a data-model change.

### Build Configuration Details (Claude's discretion, auto-resolved per --auto)
- **D-03:** Canonical App Group suite ID is `group.stress.ai.com` (matches the actual bundle ID prefix `stress.ai.com`; the other two candidates — `group.com.stressmonitor.app`, `group.com.stressmonitor.watch` — are legacy names disconnected from the real bundle ID scheme). Applied consistently across the iPhone app, watch app, and widget extension entitlements. — **Reversibility:** costly — changing the suite ID after users have data in the old suite requires a one-time migration read from both suites; get this right now rather than churn it after Phase 2 builds on it.
- **D-04:** New unit tests use Swift Testing (`@Test`/`#expect`); XCTest is kept only where `setUp`/`tearDown` lifecycle already exists (`BioAgeCalculatorTests.swift`). Not a new decision — confirms the already-established convention per `.planning/codebase/TESTING.md`.
- **D-05:** Info.plist consolidates onto `INFOPLIST_KEY_*` build settings (the project's existing live pattern); the orphaned `StressMonitor/Info.plist` is deleted outright, not merged.

### Claude's Discretion
- Exact staleness threshold for the widget's "no data" fallback (e.g. 30 min vs. 1 hour since last measurement) — a reasonable value chosen during planning, not a product decision worth surfacing.
- Whether the new unit-test target reuses the existing (orphaned) `StressMonitorTests` product-reference name already in `project.pbxproj`, or is named freshly — reuse unless it conflicts.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Primary scope source
- `plans/0808-2042-appstore-submission-remediation/plan.md` §"Phase 1 — Build configuration correctness" — file-level detail, acceptance criteria, and the D3/D4 decision framing this phase resolves
- `plans/reports/appstore-audit-0808-1520-security-report.md` — source audit for BUILD-01 (Privacy Manifest) and D3
- `plans/reports/appstore-audit-0808-1520-storage-report.md` — source audit for BUILD-02 (App Group entitlement)

### Codebase state
- `.planning/codebase/STACK.md` — current build settings, bundle IDs (`stress.ai.com` / `.watchkitapp` / `.widget`), the three existing App Group suite IDs, Info.plist/entitlement file locations
- `.planning/codebase/CONCERNS.md` §"Test Coverage Gaps" and §"Security Considerations" — corroborates BUILD-04 (no test target exists) and D3 independently of the remediation audit
- `.planning/codebase/ARCHITECTURE.md` §"Cross-process boundary" — widget/complication data flow via App Group `UserDefaults`, relevant to WIRE-01's wiring
- `.planning/codebase/TESTING.md` — Swift Testing vs. XCTest convention (D-04), test file locations, mocking approach for BUILD-04's new target

### Project-level
- `.planning/PROJECT.md` §Context — full list of D1-D4 blocking decisions and why this milestone exists
- `.planning/REQUIREMENTS.md` — BUILD-01..04, WIRE-01 acceptance criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StressMonitor/StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift` + demo mode (`-demo-mode` launch arg) — usable to manually verify the widget shows live (simulated) data without needing a real device/HealthKit data during development.
- Existing (but currently unwired) `WidgetDataProvider.save*` methods in `StressMonitorWidget/Models/WidgetDataProvider.swift` — the write side already exists; WIRE-01 is a call-site problem, not a from-scratch implementation.
- `MockServices.swift` (`MockHealthKitService`, `MockStressRepository`) and `MockStoreKitService.swift` — existing shipping mocks, reusable as test doubles once BUILD-04's target exists.

### Established Patterns
- Protocol-based DI seam (`...ServiceProtocol` + constructor injection) — the new test target should inject fakes through the same seam already used app-wide, per `.planning/codebase/TESTING.md`'s "what to mock" guidance.
- In-memory `ModelConfiguration(isStoredInMemoryOnly: true)` for SwiftData in tests — established pattern, reuse rather than inventing a new fixture approach.

### Integration Points
- `StressMonitorWidget/Providers/StressWidgetProvider.swift` — currently always renders placeholder timeline data; this is where WIRE-01's live-data read needs to land.
- `StressViewModel` / `SyncManager` — the source of truth WIRE-01 needs to write from into the App Group snapshot.
- `StressMonitor.xcodeproj/project.pbxproj` — has a stale `StressMonitorTests.xctest` product reference already (per `.planning/codebase/CONCERNS.md`) but zero `PBXNativeTarget` of type `bundle.unit-test`; BUILD-04 needs to add the actual target, not just fix a reference.

</code_context>

<specifics>
## Specific Ideas

No specific UI/UX requests — this phase is build-configuration and data-wiring, not user-facing surface changes beyond the widget rendering real numbers instead of placeholder.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. D1 (auth), D2 (CloudKit encryption), and the two non-blocking IAP product questions belong to Phases 2-4 and are intentionally not addressed here.

</deferred>

---

*Phase: 1-Build Configuration & Widget Wiring*
*Context gathered: 2026-08-08*

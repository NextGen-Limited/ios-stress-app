# Phase 2: Delete Correctness & Test-Suite Trust - Research

**Researched:** 2026-09-03
**Domain:** CloudKit/SwiftData delete propagation + regression seams (Swift Testing), StoreKit 2 money-path integrity, CI-parity test invocation documentation
**Confidence:** HIGH (in-repo claims verified by direct file reads with paths/lines; external claims tagged per source hierarchy)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Two-Device CloudKit Delete Verification (DATA-01)**
- Apparatus: one device + the CloudKit dashboard console (developer account) as the second signed-in surface — delete on device, confirm records gone in the console; a second physical iPhone is used if available but is not required. Simulator+device is explicitly NOT acceptable evidence (CloudKit unreliable on simulator).
- Record scope: the full store set the app writes — StressMeasurement + preferences/quick-action caches in the CloudKit container — mirroring what the Delete All Data button actually claims.
- Cleared standard: query-based emptiness after a documented propagation wait (eventual consistency — record the observed delay); immediate-only checks are flaky and rejected.
- Evidence: a dated evidence note in the phase dir (01-WIRE-01-EVIDENCE.md pattern) with timestamps, surfaces checked, observed propagation delay, screenshots.

**Test-Suite Truth Dispositions (ENV-01 / ENV-02)**
- WINDOWS.md #8: bounded re-diagnosis session (capture crash report, isolate suites, fresh simulator/runtime test); if root cause remains unknown, a dated disposition naming the best-known cause + accepted coverage loss — fix-or-bust is rejected (survived 5 ruled-out hypotheses).
- CharacterEntitlementSyncTests quarantine: same bounded-re-diagnosis pattern (money-path-adjacent coverage: syncPremiumCharacterEntitlement; suspected same host-crash family); re-enable blindly rejected; permanent quarantine without attempt rejected.
- Disposition bar: names the failure signature (exit 65, 0 assertion failures, affected suites), ruled-out causes, residual risk, and date — written to the WINDOWS.md ledger + phase verification report. Vague "known flaky" notes fail the bar.
- If a fix lands for either: remove the CI env gate / quarantine and restore the suite to the default run (no dead config).

**Money-Path Advisories (ENV-03 — WR-03 / WR-04)**
- WR-03: fix — DEBUG defaults to the REAL StoreKit path; MockStoreKitService becomes explicit opt-in (launch arg or DEBUG toggle); tests keep the mock via DI.
- WR-04: fix — never finish unverified transactions; move .finish() behind the verified branch at all call sites (Phase-1 scout found 5 in StoreKitService).
- Verification bar: money-path suites stay green + new pinning tests (unverified transaction NOT finished; DEBUG config resolves the real service absent the override).
- Server side untouched — backend metering stays in phuongddx/stress-app-be#2.

**Regression Seam & Documented Invocation (DATA-04 / BUILD-04)**
- DATA-04: a fail-lying spy conforming to CloudKitResetServiceProtocol (DI seam already exists in DataDeleterService.init) returns success while keeping rows in an in-memory store; the test pins the truthiness signal so it FAILS if the v1.0 CR-01 bug returns.
- BUILD-04: AGENTS.md stays the canonical invocation source; the _test.yml comment and a repo testing-doc one-liner cross-reference it. The documented invocation is the CI-parity form incl. TEST_RUNNER_GSD_CI=1 env-var gating (learned in Phase 1 — the env var must be exported, not passed as an xcodebuild argument).
- BUILD-04 folds in the Phase-1 UIBackgroundModes finding: one doc-truth note covering that custom INFOPLIST_KEY_* keys never merge (plist file is the source).
- Phase-end trust gate: full-suite run record with every suite enumerated, skipped suites named + dispositioned, zero failures, and a grep proving no new @Suite(.disabled)/xitest beyond the dispositioned set — count-only checks rejected (a disabled suite doesn't change counts).

### the agent's Discretion
Implementation details of the spy, the launch-arg/flag mechanism for the mock opt-in, disposition wording, and evidence-note structure are the executor's discretion within repo conventions.

### Deferred Ideas (OUT OF SCOPE)
- Backend /quick-actions metering (phuongddx/stress-app-be#2) — stays in the backend repo's scope.
- v1.1 Phase 03 drift re-test — not a v1.2 requirement; candidate target is the next TestFlight build (post-wiring), tracked in STATE.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Two-device CloudKit-propagation delete verified end-to-end (local, Keychain, App-Group, server-session halves already verified separately) | §Delete Pipeline Map — full store inventory incl. the Habit/CharacterUnlock coverage gaps; §CloudKit Propagation Semantics (query-vs-recordID consistency, console lag); apparatus = device + CloudKit Console for container `iCloud.stress.ai.com`; evidence-note pattern from 01-WIRE-01-EVIDENCE.md |
| DATA-04 | Regression test pins the v1.0 CR-01 CloudKit batch-delete failure propagation (seam below `CloudKitResetServiceProtocol`) | §The CR-01 Bug and the Seam — protocol shape quoted verbatim; DI injection point; the FakeServerSessionWiper deletion-aware-fake precedent (`remainingSessions`); requirement that the new suite be CI-visible (NOT inside a GSD_CI-gated suite) |
| BUILD-04 | CI and dev docs pin `-parallel-testing-enabled NO` | §Invocation Documentation State — AGENTS.md/_test.yml/docs/TESTING.md deltas; TEST_RUNNER_ env-forwarding mechanics; UIBackgroundModes doc-truth note inputs |
| ENV-01 | WINDOWS.md #8 CoreSimulator cold-launch crash lineage documented and accepted (or fixed) | §The #8 Lineage — 6 live crash .ips files already on disk (one decoded: SwiftData faulting frame via Testing frames); the container-lifetime hypothesis (v1.1 P03-04) NOT among the 5 ruled-out; bounded re-diagnosis playbook; disposition bar |
| ENV-02 | CharacterEntitlementSyncTests quarantine resolved — diagnosed + restored, or permanent skip documented with rationale | §CharacterEntitlementSyncTests — same fixture shape as #8 suites; same bounded playbook; what syncPremiumCharacterEntitlement does and where else it's covered |
| ENV-03 | WR-03 / WR-04 advisories dispositioned — fixed or documented accept | §WR-03 (two wiring sites + DemoMode launch-arg precedent) and §WR-04 (5 finish sites quoted; Apple's canonical sample ignores unverified without finishing; CreditPurchaseFlowTests as pinning home) |
</phase_requirements>

## Summary

Phase 2 is a verification-and-trust phase built almost entirely on seams that already exist in the repo: `CloudKitResetServiceProtocol` (DI-injected into `DataDeleterService.init`), the `FakePurchaseTransaction`/`PurchaseTransactionHandle` machinery in `CreditPurchaseFlowTests`, the `DemoMode` launch-arg precedent, and the 01-WIRE-01-EVIDENCE.md dated-note pattern. No new packages are needed; no production algorithm changes except the WR-03/WR-04 money-path fixes. The heavy lifting is (a) a live end-to-end delete verification across two signed-in surfaces with recorded propagation delay, (b) a regression suite that makes "batch delete lies while reporting success" detectable, (c) a bounded re-diagnosis of the host-crash lineage — for which this research found decisive new evidence: **six `StressMonitor-2026-09-03-*.ips` crash reports already sit in `~/Library/Logs/DiagnosticReports/`, one decoded live during this session showing the test host faulting inside SwiftData on a Testing-framework frame** — plus an in-repo-documented root-cause hypothesis (return-context-only fixtures, v1.1 P03-04 STATE decision) that has never been tested against the #8 suites and is *not* among their five ruled-out hypotheses, and (d) documentation truth for the one CI-parity invocation.

The delete pipeline is broader than one service: `performFactoryReset` (DataDeleterService.swift:392-456) sweeps server sessions → CloudKit (3 record types) → local SwiftData (StressMeasurement + CharacterUnlock) → baseline → credentials/App-Group, and the v1.0 halves (Keychain, App Group, server wipe) are already test-covered and live-verified. The research surfaced two genuine scope facts the plan must handle: **the `Habit` model (synced via `cloudKitDatabase: .automatic`, AppSchemaV2) is deleted by no code path at all**, and the "Delete All Data" scoped path (`deleteAllMeasurements`) does not delete `CharacterUnlock` (only factory reset does) — so the DATA-01 evidence note must name which UI surface was exercised and the propagation check must query the full record-type set to avoid certifying an incomplete sweep.

**Primary recommendation:** Plan four workstreams in dependency order — (1) DATA-04 + ENV-03 code fixes with pinning tests (pure DI, CI-green by construction, no simulator risk), (2) ENV-01/ENV-02 bounded re-diagnosis starting from the container-lifetime hypothesis and the on-disk crash reports (fix-or-disposition each), (3) BUILD-04 doc truth + the phase-end trust-gate enumeration, (4) the DATA-01 live two-surface verification last, once the suite is believed (its evidence note cites the green full-suite run).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Delete orchestration (all stores) | App / service layer (`DataDeleterService`) | CloudKit + SwiftData + Keychain + App Group + backend | One coordinator owns ordering + error classification (CR-01 split-brain rules live here) |
| CloudKit batch delete + failure truth | Service (`CloudKitResetService`) behind `CloudKitResetServiceProtocol` | Test doubles at the protocol seam | v1.0 CR-01 lived inside the service; DATA-04 pins the truthiness signal from above via DI |
| Cross-device propagation | iCloud infrastructure (eventual consistency) | Verification apparatus (console/hardware) | Not implementable in-app; only observable — hence evidence-note, not unit test |
| Suite enable/disable truth | Test targets (Swift Testing `.disabled`/`.enabled(if:)`) | CI env (`TEST_RUNNER_GSD_CI`) + WINDOWS.md ledger | Trust gate = enumeration + disposition, owned by the phase, not by runtime flags |
| Money path (purchase → redeem → finish) | App (`StoreKitService` + app factory) | Backend (untouched, out of scope) | WR-03/WR-04 are client-side wiring fixes; server metering stays in stress-app-be |
| Invocation documentation | Repo docs (AGENTS.md canonical) | `_test.yml` comment, docs/TESTING.md | Single source of truth + two cross-references (locked decision) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CloudKit (system) | iOS 18.6 SDK / Xcode 26.3 | Batch delete via `CKModifyRecordsOperation` (batch size 300 < 400 server limit) | Already the shipped implementation [VERIFIED: CloudKitResetService.swift:352-400] |
| Swift Testing (system) | Xcode 26.3 bundling | `@Suite`/`@Test`/`#expect`, `.disabled`/`.enabled(if:)` traits | All existing suites incl. the quarantined ones use it [VERIFIED: CharacterEntitlementSyncTests.swift:27, DataDeletionConsolidationTests.swift:238] |
| StoreKit 2 (system) | iOS 18.6 SDK | `Transaction.updates`, `VerificationResult`, `finish()` | Money path already on it [VERIFIED: StoreKitService.swift:1-2, 301-319] |
| xcodebuild + xcresulttool | Xcode 26.3 (17C529) | CI-parity invocation; `.xcresult` enumeration for the trust gate | CI already uploads `TestResults.xcresult` on failure [VERIFIED: _test.yml:190, 206-212] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftData in-memory containers | iOS 18.6 | Test fixtures — MUST use the `(ModelContainer, ModelContext)` tuple shape | Every suite touching SwiftData (crash-lineage rule, see Pitfall 1) |
| Argent MCP (`describe` before taps) | wired via opencode.json | DATA-01 device-side interaction evidence | Only if simulator interaction is needed; DATA-01 proper runs on hardware/console |
| `gsd-tools windows waive/fixed` | gsd-core | Recording dispositions in the WINDOWS.md ledger | ENV-01/ENV-02 disposition writes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CloudKit Console as second surface | Second physical iPhone | iPhone is stronger evidence (CONTEXT: prefer if available); console is the locked fallback |
| Swift Testing traits for gating | `XCTSkipIf` | Project is Swift Testing-first; traits match the existing GSD_CI pattern [VERIFIED: DataDeletionConsolidationTests.swift:236-238] |
| `xcresulttool` enumeration | Raw log grep | xcresulttool gives structured per-suite skip/crash data; grep is the cheap cross-check for `.disabled(` literals — use both |

**Installation:** none — zero external packages this phase.

**Version verification:** N/A (no registry packages). Toolchain verified live: Xcode 26.3 (Build 17C529), swiftlint 0.65.1, iPhone 17 simulator booted (UDID 5DD825B4-FAEC-4A27-BAD4-3EC482889F0E) plus iPhone 16/16 Pro Max/Air available. [VERIFIED: shell probe this session]

## Package Legitimacy Audit

> This phase installs no external packages (SPM deps unchanged: `firebase-ios-sdk` Auth + `GoogleSignIn-iOS` only, per AGENTS.md). No audit required. **Packages removed due to [SLOP] verdict:** none. **Packages flagged [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram — the delete pipeline and its verification surfaces

```
                    ┌─ DataManageView (Settings→Data Management)
                    │   "Factory Reset" → performFactoryReset()          [DataManageView.swift:52,181-184]
UI entry points ────┤
                    └─ DataDeleteView (scoped picker; .all scope)
                        → deleteAllMeasurements()                         [DataDeleteView.swift:421]
                        (⚠ deletes StressMeasurement ONLY — not CharacterUnlock/Habit)

performFactoryReset (DataDeleterService.swift:392-456) — ordered phases:
  Phase 0  server chat sessions: GET /sessions page-delete loop          [:418, 468-520]
             └─ auth-unavailable classes → log+skip; everything else fails loudly
  Phase 1  CloudKit: performDatabaseReset → deleteAllRecords             [:424; CloudKitResetService.swift:55-100]
             ├─ CD_StressMeasurement, CD_PersonalBaseline, CD_SyncMetadata
             └─ CKModifyRecordsOperation batches of 300, isAtomic=false  [CloudKitResetService.swift:352-382]
  Phase 2  local SwiftData: StressMeasurement + CharacterUnlock          [:430-432]
             (⚠ Habit model deleted NOWHERE — synced schema V2 includes it)
  Phase 3  baseline reset + clearCredentialsAndSharedCaches              [:438-440, 557-562]
             └─ Firebase auth session, chat session id, legacy Keychain, App Group suite
                group.stress.ai.com via removePersistentDomain            [:560-561]

Verification surfaces (DATA-01):
  Surface A (initiator): physical device, signed into iCloud
  Surface B (observer):  CloudKit Console → container iCloud.stress.ai.com → private DB
                         query each record type → emptiness AFTER documented propagation wait
  (second physical iPhone preferred if available; simulator+device NOT acceptable)

Regression seam (DATA-04):
  DataDeleterService.init(modelContext:cloudKitResetService:...)           [DataDeleterService.swift:48-61]
      ▲ protocol: CloudKitResetServiceProtocol                             [CloudKitResetService.swift:9-15]
      ├─ real: CloudKitResetService (CKModifyRecordsOperation; CR-01 fix 1761b70)
      └─ test: fail-lying spy — returns success, keeps rows in memory store,
         exposes remainingRecords (precedent: FakeServerSessionWiper.store/.remainingSessions)
```

### Recommended Project Structure

No new source directories. Touch points:
```
StressMonitor/StressMonitorTests/
├── DataDeletionConsolidationTests.swift   # DATA-04 spy suite lands here or sibling; #8-gated suites at :236-241, :373-378
├── DataDeleterServerWipeTests.swift       # pattern donor: (ModelContainer, ModelContext) fixture :111, deletion-aware fake
├── CharacterEntitlementSyncTests.swift    # ENV-02 quarantine (:27)
├── StoreKitServiceTests.swift             # 3rd disabled suite (session-isolation, :17) — disposition candidate
├── EntitlementForegroundCorrectionTests.swift  # 4th disabled suite (IAP-01, :12) — disposition candidate
├── FirebaseBootstrapTests.swift           # conditional .disabled(if:) — already dispositioned-by-design (:26-46)
├── CreditPurchaseFlowTests.swift          # WR-04 pinning home (FakePurchaseTransaction.finishCallCount)
└── (new) money-path wiring pinning test   # WR-03: DEBUG resolves real service absent override
StressMonitor/StressMonitor/
├── StressMonitorApp.swift                 # WR-03 site A: makeStoreKitService :243-253
├── Services/StoreKit/StoreKitServiceEnvironment.swift  # WR-03 site B: defaultValue :11-17
├── Services/StoreKit/StoreKitService.swift            # WR-04: 5 finish sites :317,375,379,388,401
└── Services/StoreKit/MockStoreKitService.swift        # #if DEBUG-only double :3-4
docs/TESTING.md                            # BUILD-04 cross-reference target (stale — see §Invocation)
.github/workflows/_test.yml                # BUILD-04 cross-reference comment :178-182 (already correct)
AGENTS.md                                  # BUILD-04 canonical invocation (root)
.planning/WINDOWS.md                       # disposition ledger writes
```

### Pattern 1: Deletion-aware fake (the DATA-04 spy)
**What:** A protocol-conforming test double whose "delete" methods return success while rows persist in an in-memory store, with an accessor exposing survivors.
**When to use:** Pinning "reported success ≠ data gone" — exactly the CR-01 truthiness signal.
**Example (in-repo precedent, quote):**
```swift
// Source: StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift:20-25, 51-65 (verbatim excerpts)
/// Mirrors the backend's live-row pagination: `listSessions` windows
/// the remaining rows ... so the fake shrinks as the wipe progresses —
/// exactly like `sessions.ts` (CR-01).
case store([ChatSession])
...
case .store:
    return Array(store.dropFirst(offset).prefix(limit))
...
/// Rows left in the live-store simulation — non-empty after a "successful"
/// reset means the wipe stranded sessions (CR-01).
var remainingSessions: [ChatSession] { store }
```
The DATA-04 spy mirrors this against `CloudKitResetServiceProtocol`: a `.lyingStore` behavior whose `deleteRecords`/`deleteAllRecords`/`performDatabaseReset` return without throwing while rows stay in `var store`, plus `var remainingRecords`. The existing `FakeCloudKitResetService` (DataDeletionConsolidationTests.swift:184-228, behaviors `.succeed`/`.throwError`/`.cancelCallingTask`) is the extension point. Design note: the suite must live OUTSIDE the two GSD_CI-gated suites — today the only failure-propagation test (`deleteAllMeasurementsPropagatesCloudKitFailureMessage`, :252-278) is CI-invisible behind the `.enabled(if:)` gate, so CI currently proves nothing about CR-01.

### Pattern 2: Container-outlives-context fixture
**What:** SwiftData test fixtures return `(ModelContainer, ModelContext)` and the test holds the container for its whole body.
**When to use:** EVERY SwiftData-touching suite (the #8 crash-lineage rule).
**Example (in-repo, verbatim):**
```swift
// Source: StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift:111
private func makeContextWithOneMeasurement() throws -> (ModelContainer, ModelContext) {
```
Versus the crash-lineage shape still present in the gated suites (DataDeletionConsolidationTests.swift:380-384 `return container.mainContext` with a local `container`; :243-250 same) and in `CharacterEntitlementSyncTests.makeSeededContext` (:31-45 — container local, only `ctx` returned). The v1.1 03-04-SUMMARY.md:52 states the rule verbatim: "Test fixtures return (ModelContainer, ModelContext) and hold the container for the test body — the consolidation tests' return-context-only shape is the documented crash-loop lineage; this suite must not add to it."

### Pattern 3: Launch-arg opt-in (WR-03 mechanism precedent)
**What:** `#if DEBUG` feature gated on a `ProcessInfo` launch argument instead of the build configuration alone.
**Example (in-repo, verbatim):**
```swift
// Source: StressMonitor/StressMonitor/StressMonitorApp.swift:6-10
#if DEBUG
enum DemoMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo-mode")
}
#endif
```
The mock opt-in follows this shape (e.g. `-mock-iap`); DEBUG builds then default to the real `StoreKitService` at BOTH wiring sites.

### Anti-Patterns to Avoid
- **Return-context-only fixtures** — see Pattern 2; documented crash lineage.
- **Count-only suite verification** — a disabled suite doesn't change pass counts; the trust gate must enumerate suites + dispositions, not compare totals (locked CONTEXT decision).
- **Trusting batch-delete success as truth** — the whole point of CR-01/DATA-04; emptiness is established by querying, never by the absence of an error.
- **Immediate-only propagation checks** — CloudKit queries are eventually consistent; a 0-rows-at-instant-0 check is flaky (locked: rejected).
- **Editing orphaned dirs** — `StressMonitorTests/` (repo root), `StressMonitor/Models|Services|Views` are NOT in the Xcode project; edits there never build (AGENTS.md).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI-parity suite enumeration | Custom log parsers | `xcrun xcresulttool get test-results summary\|tests\|test-details\|activities --path X.xcresult` | Structured per-suite skip/crash data; CI already produces the bundle [CITED: xcresulttool(1) man page, keith.github.io/xcode-man-pages/xcresulttool.1.html] |
| Crash-report discovery | Guesswork | `~/Library/Logs/DiagnosticReports/*.ips` (+ `Retired/`), correlate via `coalitionName: com.apple.CoreSimulator.SimDevice.<UDID>` | 6 StressMonitor .ips already there (2026-09-03); `atos` symbolicates [CITED: github.com/conorluddy/ios-simulator-skill issue #36; live probe this session] |
| Batch-delete batching math | Custom chunking | Keep `batchSize: 300` | Server rejects >400 per operation with `CKError.limitExceeded`; 300 is safely under [CITED: hackingwithswift.com/forums/18998; mackuba.eu WWDC15 notes] |
| Unverified-transaction policy | Ad-hoc finish/unwind | Apple's canonical observer shape: `guard case .verified` … else return (no finish) | Redelivery via `Transaction.updates` is the retry path; finishing destroys the only consumable proof [CITED: developer.apple.com/documentation/storekit/transaction/updates] |
| Suite gating mechanism | New env plumbing | Existing `TEST_RUNNER_GSD_CI` → `GSD_CI` forwarding + `.enabled(if:)` | Locked decision; mechanism verified at _test.yml:177-196 and DataDeletionConsolidationTests.swift:233-238 |

**Key insight:** every mechanism this phase needs (DI seam, deletion-aware fakes, launch-arg gating, env-var gating, evidence notes, ledger waivers) already exists in this repo as shipped, tested precedent — the phase is application of precedent, not invention.

## Runtime State Inventory

> Not a rename/refactor/migration phase — no stored-data/live-config/OS-registered-state renames to audit. The closest analog (test-suite enable/disable state) is fully inventoried in §Common Pitfalls (Pitfall 6: the complete disable/gate inventory, 7 entries at exact file:line).

## Common Pitfalls

### Pitfall 1: The container-lifetime crash hypothesis is NOT among the 5 ruled out
**What goes wrong:** A re-diagnosis session that re-runs the old bisection wastes its budget on already-falsified hypotheses.
**Why it happens:** The ruled-out list (file header, CharacterEntitlementSyncTests.swift:12-21) covers: CloudKit setup on the in-memory container, the real app-level CloudKit container, WidgetCenter.reloadTimelines XPC, bare `try ctx.save()` vs do/catch, `@Suite(.serialized)`, and suite/test ordering. Container lifetime is absent from that list — yet STATE.md records the v1.1 P03-04 decision: "in-memory `ModelContainer` must outlive its `mainContext` in tests; return-context-only fixtures are the WINDOWS.md #8 crash lineage", and ALL THREE problem suites (`DataDeleterFailureAndCancellationTests` :243-250, `DataExportFieldSelectionTests` :380-384, `CharacterEntitlementSyncTests` :31-45) still use the return-context-only shape. A live crash report decoded this session (StressMonitor-2026-09-03-150705.ips) shows the test host faulting in **SwiftData** on a **Testing**-framework frame — EXC_BREAKPOINT SIGTRAP, `procPath` under CoreSimulator coalition `5DD825B4…` (the booted iPhone 17). Consistency check: the bisection's "stubbing every @Test body makes it pass" is exactly what a dead-container-dereference predicts (no SwiftData work → no touch of the dead container's context).
**How to avoid:** Bounded session step 1 = convert the three fixtures to the `(ModelContainer, ModelContext)` tuple shape (Pattern 2), un-gate/un-quarantine, run. Cheap, reversible, directly tests the strongest hypothesis.
**Warning signs:** Suite passes with no-op bodies but hangs with real insert+save; crashes cluster on SwiftData-heavy suites; .ips faulting frame in SwiftData.

### Pitfall 2: `deleteAllMeasurements` ≠ "deletes all data"
**What goes wrong:** DATA-01 evidence certifies a sweep the app never performs, or the propagation check queries only `CD_StressMeasurement` while other synced record types survive.
**Why it happens:** Three distinct claims exist: `deleteAllMeasurements` (CloudKit `.stressMeasurement` + local StressMeasurement only — DataDeleterService.swift:97-111), `performFactoryReset` (adds CharacterUnlock, baseline, credentials, App Group, server sessions — :392-456), and the UI copy "All data will be permanently deleted from both this device and iCloud" (DataDeleteView.swift:347) / "Data will be removed from all devices" (:152). Meanwhile `Habit` (AppSchemaV2, synced via `cloudKitDatabase: .automatic` — StressMonitorApp.swift:52-62, 76-80) is deleted by NO path (grep-verified: no `delete(model: Habit` anywhere; `HabitViewModel.swift:65` inserts). `CharacterUnlock` survives the `deleteAllMeasurements` path.
**How to avoid:** The evidence note names the exact UI surface exercised (recommend the factory-reset surface — the broadest claim), and the console check queries every record type the schema writes: CD_StressMeasurement, CD_PersonalBaseline, CD_SyncMetadata, plus the NSPersistentCloudKitContainer-mirrored types (CD_Com.apple.CoreData… naming for StressMeasurement/CharacterUnlock/Habit — the mirroring writes its own zone records; query by type in the console). If Habit survival is confirmed, it's a finding to disposition (fix is one `modelContext.delete(model: Habit.self)` line — scope call for the planner, mirroring the factory-reset CharacterUnlock precedent at :431).
**Warning signs:** Evidence note that only mentions "measurements"; a cleared check that never names the record types queried.

### Pitfall 3: GSD_CI forwarding mechanics (the Phase-1 lesson)
**What goes wrong:** Documented invocation tells a human to pass `-GSD_CI 1` or `GSD_CI=1` as an xcodebuild argument — which does nothing; the gated suites then run and (pre-fix) stall the host.
**Why it happens:** xcodebuild forwards environment variables that carry the `TEST_RUNNER_` prefix into the test host with the prefix stripped. `_test.yml` sets `TEST_RUNNER_GSD_CI: "1"` in the step env (:177-182); the suite reads `GSD_CI` (DataDeletionConsolidationTests.swift:238).
**How to avoid:** The documented local CI-parity form is `TEST_RUNNER_GSD_CI=1 xcodebuild test …` (env var exported in the shell, not an xcodebuild flag). Locked CONTEXT decision; AGENTS.md prose already explains the split but the canonical command block should show it.
**Warning signs:** Docs showing `GSD_CI` anywhere as a CLI argument.

### Pitfall 4: WR-03 has TWO wiring sites; fixing one leaves the mock live
**What goes wrong:** The DEBUG default flips to real in `StressMonitorApp.makeStoreKitService` (:243-253) but `StoreKitServiceKey.defaultValue` (StoreKitServiceEnvironment.swift:11-17) still returns `MockStoreKitService` in DEBUG — any view reading the environment outside the app injection (previews, sheets) silently keeps the no-op mock, and the pinning test passes while production wiring is half-fixed.
**Why it happens:** The default exists as a fallback for views not under the app's `.environment(\.storeKitService, …)` injection (StressMonitorApp.swift:209); PaywallView reads it (PaywallView.swift:20).
**How to avoid:** Change both sites behind one named helper/condition; pin with a test asserting the DEBUG configuration resolves the real service absent the override (assert on the shared factory — e.g. make the factory `internal` and test `makeStoreKitService` type + the environment default type; `#if DEBUG`-gated test). Note `MockStoreKitService` is `#if DEBUG`-only (MockStoreKitService.swift:3) so the opt-in toggle is DEBUG-only by construction; Release behavior is unchanged and untestable at runtime (compile-time `#else`).
**Warning signs:** A WR-03 diff touching only one file; a pinning test that constructs the service directly instead of through the factory under test.

### Pitfall 5: WR-04 — the four `completePurchase` finish sites are verified-only by construction; only :317 is the bug
**What goes wrong:** A "fix" that wraps finish() calls in runtime verification checks inside `completePurchase`, re-architecting the grant choke point.
**Why it happens:** Misreading "all 5 call sites" as "5 unverified-reachable sites".
**How to avoid:** Trace reachability (verified this session): `purchase(_:)/purchase(pack:)` call `checkVerified` which THROWS on `.unverified` (StoreKitService.swift:158, 189, 439-446); `handle(transaction:)` (:407) is reached only from the `.verified` case (:311-312). So :375, :379, :388, :401 execute only for verified transactions — their contract (finish revoked/refunded/legacy-subscription paths to clear the queue) is intentional and test-pinned (CreditPurchaseFlowTests :181-357). The defect is exactly `.unverified` at :314-318, whose comment ("finishing is safe") is the advisory's target. Fix = delete the finish + leave unfinished (matches Apple's canonical sample: "Ignore unverified transactions." — no finish) + log. The audit deliverable is a written reachability note covering all five, not five code changes.
**Warning signs:** WR-04 diffs touching :375-401; new runtime verification inside the grant choke point.

### Pitfall 6: The trust-gate grep finds MORE than the two named suites — enumerate all 7
**What goes wrong:** Phase ends with criterion #4 "no silently disabled suite" unmet because the audit only dispositioned #8 + CharacterEntitlementSyncTests.
**Why it happens:** The phase goal names two; the repo has seven disable/gate constructs (grep `\.(disabled\(|enabled\(if:)` over StressMonitorTests — run this session):
1. `CharacterEntitlementSyncTests.swift:27` — `@Suite(.disabled("Reliable test-host hang…"))` — ENV-02, in scope
2. `DataDeletionConsolidationTests.swift:238` + `:375` — `.enabled(if: GSD_CI == nil)` — ENV-01 (#8 pair), dispositioned by this phase
3. `StoreKitServiceTests.swift:17` — `@Suite(.serialized, .disabled("StoreKitTest session-isolation bug on CI"))` — money-path-adjacent; needs a dated disposition too (or a fix if the ENV-01/02 fix lands and resolves it)
4. `EntitlementForegroundCorrectionTests.swift:12` — `@Suite(.serialized, .disabled("StoreKitTest cannot resolve subscription products — IAP-01"))` — WINDOWS #6, still disabled; needs disposition (or enablement — the v1.1 gap-closure re-enabled its sibling StoreKitProductCatalogLiveTests, not this one)
5. `FirebaseBootstrapTests.swift:28,42` — `.disabled(if: !hostCarriesPlist, "…")` — conditional, self-arming, documented reason: already dispositioned-by-design (the good pattern; cite as such, no action)
**How to avoid:** The trust gate = the grep output mapped 1:1 to {fixed-and-enabled | dated disposition | conditional-by-design}, plus `xcresulttool get test-results tests` showing zero unexpected skips, plus the full-suite run record. Note criterion 4's own wording ("each carries a written, dated disposition naming the root cause and the accepted coverage loss") applies the disposition bar to every suite the grep surfaces.
**Warning signs:** Dispositions for only 2 of the 4 unconditional disables; "no new disables" claimed without the grep artifact.

### Pitfall 7: DATA-01 evidence graded against simulator behavior
**What goes wrong:** Any part of the propagation evidence gathered on a simulator (device+simulator explicitly rejected by CONTEXT).
**Why it happens:** Convenience — simulators are booted right now.
**How to avoid:** The initiating surface is physical hardware; the observer is the console (or a second physical iPhone if available at execution time — preferred when present). Record device model/iOS build, timestamps per query round, observed propagation delay, and screenshots in the evidence note (01-WIRE-01-EVIDENCE.md structure: §data-source disclosure, §screenshots table, §machine-verified checks, §pending human items).

### Pitfall 8: `RequestCaptureURLProtocol` statics leak across suites (ledger #12)
**What goes wrong:** New money-path tests that stub via the single-response statics inherit stale `/preferences` responses from earlier suites — order-dependent failures that look like ENV-01 host flakiness.
**Why it happens:** WINDOWS #12: statics persist across suites in one host launch; the #8 crash-restart boundary previously masked polluter/victim pairs.
**How to avoid:** Prefer constructor-injected fakes (the CreditPurchaseFlowTests / FakeServerSessionWiper style — no shared statics); if URLProtocol stubbing is unavoidable, reset statics in the suite's `init`/`deinit`.

## Code Examples

### DATA-04: fail-lying spy skeleton (shape only — details executor's discretion)
```swift
// Modeled on FakeCloudKitResetService (DataDeletionConsolidationTests.swift:184-228)
// + FakeServerSessionWiper.store/remainingSessions (DataDeleterServerWipeTests.swift:20-65).
// MUST live in a suite WITHOUT .enabled(if: GSD_CI == nil) — CI must see it.
@MainActor
final class LyingCloudKitResetService: CloudKitResetServiceProtocol, @unchecked Sendable {
    private(set) var store: [CloudKitRecordType: Int]   // seeded rows per type
    // every protocol method: return normally (success) WITHOUT mutating `store`
    // → deleteAllRecords reports success while records survive = the CR-01 shape
    var remainingRecords: Int { store.values.reduce(0, +) }
}
// Green-test prongs (both required by the CONTEXT decision):
// 1) genuine-failure pin: .throwError spy → deleteAllMeasurements/performFactoryReset THROWS
//    (extends the CI-invisible test at DataDeletionConsolidationTests.swift:252-278)
// 2) truthiness pin: lying spy → pipeline returns success BUT remainingRecords > 0 is
//    detected — i.e. the suite asserts emptiness is only ever established by querying
//    the store, never by trusting the success return.
```

### WR-04: the Apple-canonical unverified branch
```swift
// Source: developer.apple.com/documentation/storekit/transaction/updates (Apple sample, verbatim guard)
guard case .verified(let transaction) = verificationResult else {
    // Ignore unverified transactions.
    return
}
```
Applied at StoreKitService.swift:309-319: the `.unverified` case drops `await transaction.finish()` (:317), leaving the transaction for redelivery (mirrors the existing leave-unfinished retry contract in `handle(transaction:)` :404-418). Pinning test drives `handle(transactionVerification: .unverified(...))` and asserts `finishCallCount == 0` — note `handle(transactionVerification:)` is currently `private` (:309); widening to `internal` for `@testable` access is the minimal seam change (FakePurchaseTransaction already models finish counts, CreditPurchaseFlowTests.swift:33-55).

### ENV-01/02: bounded re-diagnosis command kit
```bash
# 1. Crash reports (already present — 6 files from 2026-09-03)
ls -lt ~/Library/Logs/DiagnosticReports/ | grep -iE "StressMonitor|xctest" | head
# decode: head -1 = JSON header; rest = payload (termination/exception/threads/usedImages)
#   coalitionName com.apple.CoreSimulator.SimDevice.<UDID> ties a report to the simulator
# symbolicate a frame: atos -arch arm64 -o <test-host binary> -l <load addr> <frame addr>

# 2. Structured suite results incl. skips/crashes (CI uploads this same bundle)
xcrun xcresulttool get test-results summary --path StressMonitor/build/TestResults.xcresult
xcrun xcresulttool get test-results tests   --path StressMonitor/build/TestResults.xcresult

# 3. CI-parity local invocation (BUILD-04 canonical form)
TEST_RUNNER_GSD_CI=1 xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -parallel-testing-enabled NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
# (iPhone 17 locally per config.json test_command; iPhone 16 = CI parity)

# 4. Fixture-isolation experiment (Pitfall 1): tuple-shape fixtures → un-gate → targeted run
#   -only-testing:StressMonitorTests/DataDeleterFailureAndCancellationTests
#   -only-testing:StressMonitorTests/CharacterEntitlementSyncTests
# WITHOUT TEST_RUNNER_GSD_CI (gated suites only run when the env var is absent)

# 5. Fresh-simulator isolation: erase the device or create a new one (runtime isolation test)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Finish unverified transactions to "clear the queue" | Apple's canonical observer ignores them (no finish) — redelivery is the retry path | Standing StoreKit 2 guidance (sample current as of 2026) | WR-04 fix direction; a finished unverified consumable is unrecoverable |
| `xcrun xcresulttool get --format json` (legacy) | `xcresulttool get test-results summary/tests/test-details/activities` | Xcode 16+ | Trust-gate enumeration tooling |
| Assume delete success when CKModifyRecordsOperation completes | Query-based emptiness after a propagation wait | CloudKit consistency model (long-standing; still current) | DATA-01 cleared standard; record the observed delay |
| Return-context-only SwiftData fixtures | `(ModelContainer, ModelContext)` tuple fixtures | Established in-repo v1.1 Phase 3 | The #8/ENV-02 re-diagnosis first hypothesis |

**Deprecated/outdated:**
- `docs/TESTING.md` wholesale: says CI runs "build validation (not full test execution yet)" (line 152-158) while `_test.yml` runs the full test job; its command-line recipe (lines 33-39) omits `-parallel-testing-enabled NO`; its file table (lines 82-88) lists 5 files against a repo with dozens of suites. Do not extend it — cross-reference the canonical AGENTS.md block (locked BUILD-04 decision: "AGENTS.md stays the canonical invocation source; the _test.yml comment and a repo testing-doc one-liner cross-reference it").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A physical device signed into the team iCloud account and CloudKit Console access (developer account, team K2TYLYAWMK) are available at execution time | DATA-01 / Environment | Evidence blocked → falls to end-of-phase human item; planner should gate with checkpoint |
| A2 | The CloudKit Console private-DB record-type query covers NSPersistentCloudKitContainer-mirrored types (CD_StressMeasurement etc. share the type names the mirroring generates; exact mirroring zone/type naming to be confirmed live in the console during evidence collection) | Pitfall 2 / DATA-01 | Check might query a stale type list; mitigation: enumerate record types in the console's schema browser during the session and record them in the note |
| A3 | CloudKit Console propagation delay is seconds-to-minutes (forums reports "expectedly slow" console deletes; no official SLA) | Propagation semantics | Wait loop budget too small/large; mitigation: poll rounds with timestamps until stable-empty (the evidence note records the observed number) |
| A4 | Second physical iPhone is NOT available (CONTEXT treats it as optional-preferred) | DATA-01 | None — console is the locked fallback |
| A5 | The `_EXHostConfiguration`-class host/simruntime symbol-mismatch family (GitHub runner-images #12777, macOS-15 CI hosts) is a *possible* but unconfirmed relative of the LOCAL dev-host #8 crashes | ENV-01 | Low — it's one more ruled-in/out candidate for the disposition, not a fix premise; local crashes fault in SwiftData (not ExtensionFoundation), so it likely does NOT explain the local lineage |
| A6 | `Habit` records exist in real user containers (feature is reachable — HabitViewModel inserts; SettingsView renders HabitLogRow) | Pitfall 2 | If Habit is unreachable in shipped builds, the gap downgrades to dead-schema cleanup; still worth one disposition line |

**All other claims are [VERIFIED: path:lines] (in-repo, read this session) or [CITED: url] (external).**

## Open Questions

1. **Which UI surface does DATA-01 certify — factory reset or scoped Delete-All?**
   - What we know: three claims exist with different sweep breadth (Pitfall 2); UI copy promises "all data … from both this device and iCloud".
   - What's unclear: whether the user wants the narrower scoped path also certified or fixed to match its copy.
   - Recommendation: run the evidence against the factory-reset surface (broadest actual sweep, matches the strongest claim) and record the scoped path's narrower semantics as a disclosed fact in the note; escalate the Habit gap as a planner decision (1-line fix vs. documented accept).

2. **Does the container-lifetime fix actually clear #8, or is it a sixth falsified hypothesis?**
   - What we know: strongest un-tested hypothesis (STATE decision + matching live .ips faulting in SwiftData); consistent with every prior bisection observation.
   - What's unclear: whether it fully explains the CI-side (macos-15 runner) crashes or only the local dev-host lineage.
   - Recommendation: bounded session tests it FIRST (cheap, reversible); either way the disposition names the outcome with the .ips evidence attached.

3. **Is `StoreKitServiceTests`' session-isolation disable fixable by the same ENV-01 fix?**
   - What we know: its disabled reason cites CI StoreKitTest session state, not host crashes; `StoreKitTestSessionProvider` centralizes sessions already.
   - What's unclear: whether un-quarantining after the ENV-01 fix makes it green or it's an independent bug.
   - Recommendation: include it in the bounded session's isolation matrix; disposition either way (Pitfall 6 requires it).

4. **ENV-03 pinning test placement for WR-03** — the factory is `private static`; options: widen to `internal` + `#if DEBUG` test asserting resolved type (real absent `-mock-iap`-style arg, mock with it), or extract a testable `StoreKitServiceFactory.resolve()` helper. Executor's discretion per CONTEXT; flagging the access-change need so the plan doesn't discover it mid-task.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | all builds/tests | ✓ | 26.3 (17C529) | — |
| iOS simulators | ENV-01/02 re-diagnosis, suite runs | ✓ | iPhone 17 booted (5DD825B4…), iPhone 16 / 16 Pro Max / Air available | — |
| swiftlint | lint gate | ✓ | 0.65.1 | — |
| Crash reports `~/Library/Logs/DiagnosticReports/` | ENV-01 diagnosis | ✓ | 6 StressMonitor .ips (2026-09-03, one decoded: SwiftData fault via Testing frames) | — |
| Physical iPhone, signed into iCloud (team container access) | DATA-01 surface A | ✗ not probeable from session | — | end-of-phase human item; evidence note is the artifact |
| CloudKit Console access (developer account) | DATA-01 surface B | assumed (A1) | — | second physical iPhone (preferred if available) |
| `xcrun xcresulttool` | trust-gate enumeration | ✓ (ships with Xcode 26.3) | — | raw log grep (weaker) |
| Argent MCP (simulator interaction) | any simulator UI interaction | ✓ (wired via opencode.json) | — | xcrun for non-interaction diagnostics only |

**Missing dependencies with no fallback:** none blocking code/test work; DATA-01's physical-surface items are inherently human-gated (by design, not by accident).
**Missing dependencies with fallback:** DATA-01 second surface (console fallback locked in CONTEXT).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (+ XCTest host) via xcodebuild — Xcode 26.3 |
| Config file | none (scheme-driven; `.swiftlint.yml` for lint) |
| Quick run command | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:StressMonitorTests/<Suite> CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` |
| Full suite command | `TEST_RUNNER_GSD_CI=1 xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` (CI-parity; drop the env var locally to include gated suites) |
| Helper | `python3 scripts/run-tests.py` (finds/boots simulator, results in StressMonitor/build/) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Delete on device A ⇒ records absent on surface B after propagation wait | manual/evidence (hardware + console) | evidence note `02-DATA-01-EVIDENCE.md` (timestamps, record types queried, observed delay, screenshots) | ❌ created this phase |
| DATA-04 | Batch-delete failure propagates; success-while-rows-survive is detectable (CR-01) | unit (DI fakes, CI-green) | `xcodebuild test … -only-testing:StressMonitorTests/<NewSpySuite>` | ❌ Wave 0 (new suite; extend FakeCloudKitResetService) |
| BUILD-04 | One documented CI-parity invocation; docs agree; UIBackgroundModes note exists | doc verification + grep | `grep -n "parallel-testing-enabled" AGENTS.md .github/workflows/_test.yml docs/TESTING.md`; diff check vs _test.yml:185-195 | ❌ (docs edited this phase) |
| ENV-01 | #8 lineage fixed or dated disposition in WINDOWS.md | diagnostic + suite-or-disposition | targeted `-only-testing:` runs without GSD_CI; `gsd-tools windows` ledger entry | partial (gated suites exist; disposition ❌) |
| ENV-02 | CharacterEntitlementSyncTests restored or dispositioned | diagnostic + suite-or-disposition | `-only-testing:StressMonitorTests/CharacterEntitlementSyncTests` (after fixture fix) | partial (suite exists, disabled) |
| ENV-03a | Unverified transaction NOT finished | unit (fake handle) | `-only-testing:StressMonitorTests/CreditPurchaseFlowTests` (+ new test) | partial (CreditPurchaseFlowTests exists; new pin ❌) |
| ENV-03b | DEBUG resolves real StoreKit service absent override | unit (#if DEBUG) | new suite (factory/env-default type assertion) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** quick run command for the touched suite(s) + `swiftlint lint`
- **Per wave merge:** full suite command (CI-parity form)
- **Phase gate:** full-suite run record (both WITH and WITHOUT `TEST_RUNNER_GSD_CI` once suites are restored), `xcresulttool get test-results tests` enumeration, disable/gate grep mapped to dispositions, DATA-01 evidence note — before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] New DATA-04 spy suite (extends or siblings `DataDeletionConsolidationTests.swift`; NOT GSD_CI-gated)
- [ ] WR-04 pinning test in `CreditPurchaseFlowTests` (+ `handle(transactionVerification:)` access widening)
- [ ] WR-03 pinning test (#if DEBUG factory/env-default resolution)
- [ ] Fixture conversion to `(ModelContainer, ModelContext)` in the three SwiftData-heavy suites (hypothesis experiment; revert if falsified)
- [ ] `02-DATA-01-EVIDENCE.md` skeleton (structure from 01-WIRE-01-EVIDENCE.md)

*(Framework install: none needed — infrastructure exists.)*

## Security Domain

### Applicable ASVS Categories (level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth-code change; delete path already signs out via `clearCredentialsAndSharedCaches`) | existing FirebaseAuthService |
| V3 Session Management | marginal | delete path clears Firebase session + chat session id (DataDeleterService.swift:557-562) — regression suites already pin it |
| V4 Access Control | no new surfaces | server-side auth untouched (backend out of scope per CONTEXT) |
| V5 Input Validation | n/a (no new input paths; spy/test code only) | Swift Testing `#expect` |
| V6 Cryptography | no | CloudKit encryptedValues untouched (pinned by CloudKitEncryptionTests, DataDeletionConsolidationTests.swift:429+) |
| V14 Config (money path) | yes — via ENV-03 | WR-03 stops shipping a silent no-op purchase path in DEBUG; WR-04 preserves the consumable proof-of-purchase (an anti-fraud/anti-loss integrity control) |

### Known Threat Patterns for StoreKit 2 + CloudKit (Swift/iOS)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged/unverified JWS accepted client-side | Tampering | `checkVerified` throws on `.unverified` (StoreKitService.swift:439-446); WR-04 additionally stops destroying the evidence (unfinished transaction = redeliverable proof) |
| Paid consumable lost to premature `finish()` | Repudiation/Denial | WR-04 fix + pinning test (`finishCallCount == 0` for unverified) |
| DEBUG/Staging money path silently mocked (false-negative testing) | Tampering (process) | WR-03: real-default + explicit opt-in; pinned by config-resolution test |
| Delete reports success while data survives (privacy) | Information disclosure | CR-01 propagation fix (1761b70) + DATA-04 truthiness pin; DATA-01 end-to-end evidence |
| Test secrets/credentials in committed fixtures | Information disclosure | repo rule: never commit secrets; IAP tests use `.storekit` config file only |

## Sources

### Primary (HIGH confidence — in-repo, read this session)
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` (whole pipeline, :67-130, :392-456, :468-520, :557-562)
- `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift` (protocol :9-15, batch delete :352-400, error adaptation :404-421)
- `StressMonitor/StressMonitor/Services/DataManagement/LocalDataWipeService.swift` (local sweep breadth — StressMeasurement only)
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSchema.swift:5-9` (record types verbatim)
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` (:145-201 purchase entry, :301-319 listener + unverified finish, :366-402 completePurchase, :439-446 checkVerified)
- `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift:11-17`; `StressMonitor/StressMonitor/StressMonitorApp.swift:6-10, :243-253` (WR-03 sites); `MockStoreKitService.swift:3-4, 24-28`
- `StressMonitor/StressMonitorTests/`: `DataDeletionConsolidationTests.swift` (:184-228 fake, :230-241 & :371-378 gated suites, :243-250 & :380-384 fixtures), `DataDeleterServerWipeTests.swift` (:10-66 fake, :111 tuple fixture), `CharacterEntitlementSyncTests.swift` (:5-27 header, :31-45 fixture), `StoreKitServiceTests.swift:6-17`, `EntitlementForegroundCorrectionTests.swift:12`, `FirebaseBootstrapTests.swift:22-46`, `CreditPurchaseFlowTests.swift` (:33-55 fake handle, :137-357 pins)
- `.planning/WINDOWS.md` (#3, #6, #7, #8, #12 entries verbatim); `.planning/STATE.md` (decisions, Blockers/Concerns); `.planning/REQUIREMENTS.md`
- `.planning/milestones/v1.0-phases/02-data-integrity-deletion-consolidation/` — `02-REVIEW.md` (CR-01 definition), `02-REVIEW-FIX.md:26-32` (fix 1761b70 + the "legitimate follow-up" seam note), `02-VERIFICATION.md` (DATA-01 deferred, CR-01 zero-coverage)
- `.planning/milestones/v1.1-phases/02-credits-system-iap-transition/02-REVIEW.md:186-200` (WR-03/WR-04 verbatim advisories)
- `.planning/milestones/v1.1-phases/03-*/03-04-SUMMARY.md:52` (fixture-lifetime rule verbatim)
- `.github/workflows/_test.yml:177-212` (env forwarding + xcresult upload); `docs/TESTING.md` (staleness evidence); `.planning/config.json` (nyquist_validation, test_command)
- `.planning/phases/01-binary-manifest-truth/deferred-items.md` (UIBackgroundModes finding); `01-WIRE-01-EVIDENCE.md` (evidence-note pattern)
- Live probes: Xcode 26.3; simulators; swiftlint 0.65.1; `~/Library/Logs/DiagnosticReports/StressMonitor-2026-09-03-150705.ips` (decoded: SwiftData faulting frame via Testing frames, CoreSimulator coalition, EXC_BREAKPOINT)

### Secondary (MEDIUM confidence)
- [CITED: developer.apple.com/documentation/storekit/transaction/updates] — canonical observer sample: ignore unverified, no finish
- [CITED: stackoverflow.com/questions/24156392] — CloudKit strong-by-ID/eventual-by-query consistency; CKModifyRecordsOperation.h "side effects" quote
- [CITED: developer.apple.com/forums CloudKit threads] — iCloud Console delete propagation "expectedly slow" in practice
- [CITED: hackingwithswift.com/forums/18998 + mackuba.eu/notes/wwdc15/cloudkit-tips-and-tricks] — 400-record batch limit; CKError.partialFailure
- [CITED: keith.github.io/xcode-man-pages/xcresulttool.1.html] — xcresulttool get test-results commands
- [CITED: github.com/conorluddy/ios-simulator-skill issue #36] — .ips locations + coalitionName correlation
- [CITED: github.com/actions/runner-images issue #12777] — macOS-15 xctest SIGBUS class-realization family (candidate relative for CI-side #8; A5)

### Tertiary (LOW confidence)
- None used uncaveated; A1-A6 in the Assumptions Log carry the residual uncertainty.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; everything verified in-repo or live-probed
- Architecture: HIGH — delete pipeline, seams, wiring read end-to-end with line citations
- Pitfalls: HIGH — grounded in ledger entries, STATE decisions, live crash artifacts, and direct reachability traces; ENV-01 root cause remains genuinely open (that is the phase's work, dispositioned either way)

**Research date:** 2026-09-03
**Valid until:** 2026-10-03 (stable repo/domain; CloudKit console UX and Xcode point releases may shift minor details)

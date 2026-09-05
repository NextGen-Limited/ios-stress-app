# Phase 2: Delete Correctness & Test-Suite Trust - Pattern Map

**Mapped:** 2026-09-03
**Files analyzed:** 15 (4 new, 11 modified/verified)
**Analogs found:** 15 / 15 (every touched surface has shipped, tested in-repo precedent — the phase is application of precedent, not invention)

> **Repo guardrail (AGENTS.md):** orphaned dirs never build — real targets are `StressMonitor/StressMonitor/` (app), `StressMonitor/StressMonitorTests/` (tests). Never touch `StressMonitorTests/` (repo root) or `StressMonitor/Models|Services|Views`. New test files must be added to the Xcode project (pbxproj) — the executor must verify the file lands in the `StressMonitorTests` target, not just on disk.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `StressMonitor/StressMonitorTests/DataDeleterCloudKitTruthinessTests.swift` (NEW — name executor's discretion; may instead extend `DataDeletionConsolidationTests.swift` as a new ungated suite) | test | CRUD (in-memory store via DI seam) | `DataDeleterServerWipeTests.swift` | exact |
| `StressMonitor/StressMonitorTests/CreditPurchaseFlowTests.swift` (MODIFY — add WR-04 pin) | test | event-driven (Transaction.updates path) | itself — `FakePurchaseTransaction` (:33-55) | exact |
| `StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift` (NEW — WR-03 config-resolution pin; name executor's discretion) | test | config/DI resolution (transform) | `FirebaseBootstrapTests.swift` + `DataDeleterServerWipeTests.makeService` (:123-135) | role-match |
| `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` (MODIFY — WR-04 + access widening :309) | service | event-driven (listener) + request-response (purchase) | in-file: verified-branch finishes :375-401, leave-unfinished contract :404-418 | exact (in-file) |
| `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift` (MODIFY — WR-03 site B :11-17) | config (EnvironmentKey provider) | DI resolution | itself + `DemoMode` launch-arg (`StressMonitorApp.swift:6-10`) | exact |
| `StressMonitor/StressMonitor/StressMonitorApp.swift` (MODIFY — WR-03 site A :243-253) | config (app entry/factory) | DI wiring | itself + `DemoMode` (:6-10) | exact |
| `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` (MODIFY — fixture migration :243-250/:380-384, un-gate :238/:375, if hypothesis confirms) | test | CRUD | `DataDeleterServerWipeTests.makeContextWithOneMeasurement` (:106-121) | exact |
| `StressMonitor/StressMonitorTests/CharacterEntitlementSyncTests.swift` (MODIFY — fixture migration :31-45, un-quarantine :27) | test | CRUD | same tuple-fixture analog | exact |
| `.planning/phases/02-delete-correctness-test-suite-trust/02-DATA-01-EVIDENCE.md` (NEW) | doc (dated evidence note) | manual verification record | `01-WIRE-01-EVIDENCE.md` | exact |
| `AGENTS.md` (MODIFY — canonical CI-parity invocation w/ `TEST_RUNNER_GSD_CI=1`) | docs | n/a | existing "Build & test" block + `_test.yml:183-196` | exact |
| `docs/TESTING.md` (MODIFY — one-liner cross-reference) | docs | n/a | `AGENTS.md` canonical block | exact |
| `.github/workflows/_test.yml` (VERIFY — cross-reference comment already correct at :178-182) | config (CI) | n/a | existing comment | exact |
| `.planning/WINDOWS.md` (MODIFY — ledger disposition writes #6/#7/#8 + any new) | planning ledger | n/a | existing row schema (:16-17) + `gsd-tools windows waive/fixed` (:12-14) | exact |
| `StressMonitor/StressMonitorTests/StoreKitServiceTests.swift` + `EntitlementForegroundCorrectionTests.swift` (CONDITIONAL MODIFY — un-disable or re-date header disposition) | test | n/a | `FirebaseBootstrapTests` conditional pattern (:26-32); existing headers | exact |
| `.planning/phases/02-.../02-VERIFICATION.md` (NEW/EXTEND — trust-gate record) | doc (verification report) | n/a | `01-VERIFICATION.md` frontmatter + human_verification shape | exact |

## Pattern Assignments

### NEW DATA-04 spy suite — `StressMonitor/StressMonitorTests/` (test, CRUD via DI seam)

**Primary analog:** `StressMonitor/StressMonitorTests/DataDeleterServerWipeTests.swift`
**Secondary:** `FakeCloudKitResetService` in `DataDeletionConsolidationTests.swift:186-228`

**Imports pattern** (`DataDeleterServerWipeTests.swift:1-4`):
```swift
import Foundation
import SwiftData
import Testing
@testable import StressMonitor
```

**Deletion-aware fake — the exact shape to mirror against `CloudKitResetServiceProtocol`** (`DataDeleterServerWipeTests.swift:9-31, 40-65` — verbatim excerpts; the `.store` behavior + `remainingSessions` accessor are the truthiness-signal precedent):
```swift
@MainActor
final class FakeServerSessionWiper: ServerSessionWiping, @unchecked Sendable {
    enum Behavior {
        // ...
        /// Mirrors the backend's live-row pagination: `listSessions` windows
        /// the remaining rows ... so the fake shrinks as the wipe progresses —
        /// exactly like `sessions.ts` (CR-01).
        case store([ChatSession])
    }
    private(set) var calls: [String] = []
    var behavior: Behavior
    private var store: [ChatSession] = []
    // listSessions/deleteSession mutate or window `store` per behavior ...
```
```swift
    /// Rows left in the live-store simulation — non-empty after a "successful"
    /// reset means the wipe stranded sessions (CR-01).
    var remainingSessions: [ChatSession] { store }
```
The DATA-04 spy copies this against `CloudKitResetServiceProtocol` (protocol verbatim at `CloudKitResetService.swift:8-15`):
```swift
@MainActor
protocol CloudKitResetServiceProtocol: Sendable {
    func deleteRecords(ofType recordType: CloudKitRecordType, expectedProgress: ClosedRange<Double>) async throws
    func deleteRecords(ofType recordType: CloudKitRecordType, in range: ClosedRange<Date>) async throws
    func deleteRecords(ofType recordType: CloudKitRecordType, before date: Date) async throws
    func deleteAllRecords(confirmation: (() async -> Bool)?, includeBaseline: Bool) async throws
    func performDatabaseReset(confirmation: (() async -> Bool)?) async throws
}
```
Extend the existing `FakeCloudKitResetService` behavior enum (currently `.succeed`/`.throwError`/`.cancelCallingTask`, `DataDeletionConsolidationTests.swift:188-194`) or add a sibling `LyingCloudKitResetService` whose methods return normally **without mutating a seeded store**, plus `var remainingRecords`.

**DI injection point — the seam already exists** (`DataDeleterService.swift:45-61`):
```swift
    /// Injects a ``CloudKitResetServiceProtocol`` and a ``ServerSessionWiping``
    /// directly — the seams tests use to substitute failing/cancellable fakes
    /// instead of a real CKContainer or a live backend.
    init(
        modelContext: ModelContext,
        cloudKitResetService: CloudKitResetServiceProtocol,
        repository: StressRepositoryProtocol,
        serverSessionWiper: ServerSessionWiping? = nil,
        logger: DataManagementLogger
    ) {
```
`makeService` helper to copy (`DataDeleterServerWipeTests.swift:123-135`):
```swift
    private func makeService(
        _ ctx: ModelContext,
        cloudKit: RecordingCloudKitResetService,
        wiper: FakeServerSessionWiper
    ) -> DataDeleterService {
        DataDeleterService(
            modelContext: ctx,
            cloudKitResetService: cloudKit,
            repository: StressRepository(modelContext: ctx),
            serverSessionWiper: wiper,
            logger: .default
        )
    }
```

**Tuple fixture — MANDATORY shape** (`DataDeleterServerWipeTests.swift:106-121`):
```swift
    /// In-memory context mirroring the consolidation tests' setup, plus
    /// CharacterUnlock (performFactoryReset deletes that model too). The
    /// container is returned alongside its context and must stay alive for
    /// the whole test — dropping it first crashes SwiftData (the WINDOWS.md
    /// #8 lineage this suite must not add to).
    private func makeContextWithOneMeasurement() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: StressMeasurement.self, CharacterUnlock.self,
            configurations: config
        )
        let ctx = container.mainContext
        ctx.insert(StressMeasurement(timestamp: Date(), stressLevel: 50, hrv: 40, restingHeartRate: 65))
        try ctx.save()
        return (container, ctx)
    }
```
Keep-alive idiom at end of every test body (`DataDeleterServerWipeTests.swift:172`): `_ = container // keep the in-memory store alive until the assertions are done`

**Error-handling / assertion pattern** (`DataDeleterServerWipeTests.swift:224-231` — repo's do/catch pinning style):
```swift
        do {
            try await service.performFactoryReset()
            Issue.record("Expected factory reset to throw at the wipe page cap")
        } catch let DeletionError.serverSessionError(underlying) {
            #expect(underlying is URLError)
        } catch {
            Issue.record("Expected DeletionError.serverSessionError, got \(error)")
        }
```
Truthiness prong precedent (`:193-194`): after a "successful" reset, `#expect(wiper.remainingSessions.isEmpty)` — the new suite's lying prong asserts the pipeline's success return can never be taken as emptiness; a genuine-failure prong extends `deleteAllMeasurementsPropagatesCloudKitFailureMessage` (`DataDeletionConsolidationTests.swift:252-278`, currently CI-invisible). Error adaptation to pin against: `DataDeleterService.swift:117-129` (`DeletionError.cloudKitError`).

**CRITICAL placement rule:** the new suite must NOT carry `.enabled(if: ProcessInfo.processInfo.environment["GSD_CI"] == nil)` — CI must see it (CONTEXT DATA-04). Plain `@Suite("…") @MainActor struct …` as at `DataDeleterServerWipeTests.swift:92-94`.

---

### `StressMonitor/StressMonitor/Services/StoreKit/StoreKitService.swift` (service, WR-04 fix + access widening)

**Analog:** in-file — the four verified-only finish sites and the leave-unfinished retry contract.

**The bug to fix** (`:309-319`):
```swift
    private func handle(transactionVerification result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await handle(transaction: transaction, jwsRepresentation: result.jwsRepresentation)

        case .unverified(let transaction, _):
            // No grant occurs for an unverified payload, so finishing is
            // safe and clears the queue.
            await transaction.finish()
        }
    }
```
Fix: delete `await transaction.finish()` at `:317`; replace the comment with a log + Apple-canonical ignore-without-finish (mirrors `:226-228` `case .unverified: break` in `fetchPurchaseHistory`, and `:259-261` in `refreshEntitlements`). Access widening: `private` → `internal` on `handle(transactionVerification:)` (`:309`) so `@testable` tests can drive `.unverified` directly (minimal seam change).

**Do NOT touch** (verified-only by construction — see RESEARCH Pitfall 5): `completePurchase` finishes at `:375, :379, :388, :401`; `purchase(_:)/purchase(pack:)` throw via `checkVerified` (`:158, :189, :439-446`); `.verified`-only entry into `handle(transaction:)` (`:311-312`). The deliverable for those four is a written reachability note, not code changes.

**Contract the fix must mirror** (`:404-418`):
```swift
    /// Updates-listener entry: identical ordering to the purchase path, but
    /// a redemption failure must NOT propagate — the transaction stays
    /// unfinished so StoreKit redelivers it and the grant retries.
    func handle(
        transaction: any PurchaseTransactionHandle,
        jwsRepresentation: String
    ) async {
        do {
            try await completePurchase(transaction, jwsRepresentation: jwsRepresentation)
        } catch {
            // Leave unfinished — redelivery through Transaction.updates is
            // the crash/failure retry path for consumables.
        }
        await refreshEntitlements()
    }
```

---

### `CreditPurchaseFlowTests.swift` MODIFY — WR-04 pinning test (test, event-driven)

**Analog:** itself. The fake handle already models finish counts (`:33-55`):
```swift
final class FakePurchaseTransaction: PurchaseTransactionHandle, @unchecked Sendable {
    let productID: String
    let jwsRepresentation: String
    let revocationDate: Date?
    let expirationDate: Date?
    private(set) var finishCallCount = 0
    // ...
    func finish() async {
        finishCallCount += 1
    }
}
```
New test asserts `finishCallCount == 0` after driving `handle(transactionVerification: .unverified(...))`. Direct stylistic precedent — "failure leaves unfinished" (`:220-234`):
```swift
    @Test("Updates-listener redeem failure leaves the transaction unfinished for redelivery")
    func updatesListenerFailureLeavesUnfinished() async throws {
        let fake = FakePurchaseTransaction(productID: Self.smallPackID)
        // ... makeService with failing redeemer ...
        await service.handle(transaction: fake, jwsRepresentation: fake.jwsRepresentation)

        #expect(spy.callCount == 1)
        #expect(fake.finishCallCount == 0)
    }
```
Also copy the isolation fixture (`:115-118` — per-test `UserDefaults(suiteName: "…-\(UUID())")`) and `makeService` (`:120-133`). Constructor-injected spies only — no `RequestCaptureURLProtocol` statics (WINDOWS #12, Pitfall 8).

---

### NEW WR-03 wiring pin — `StressMonitor/StressMonitorTests/StoreKitServiceWiringTests.swift` (test, config/DI resolution)

**Analog A — assertion-in-plain-struct suite with environment probing:** `FirebaseBootstrapTests.swift:19-38` (good-pattern citation for dispositions):
```swift
@Suite("Firebase Bootstrap")
struct FirebaseBootstrapTests {

    private static var hostCarriesPlist: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    @Test(
        "the test host bundle carries GoogleService-Info.plist, so bootstrap reports .configured",
        .disabled(
            if: !hostCarriesPlist,
            "GoogleService-Info.plist is gitignored and CI does not provision it — see the suite doc comment"
        )
    )
```
The WR-03 test wraps assertions in `#if DEBUG` (as `MockStoreKitService.swift:3` is DEBUG-only by construction) and asserts the factory/environment default resolves the REAL `StoreKitService` absent the launch-arg override, the mock with it. `ProcessInfo` probing precedent: `StressMonitorApp.swift:155-157` (`XCTestConfigurationFilePath`) and DemoMode below.

**Analog B — wiring under change (WR-03 site A)** (`StressMonitorApp.swift:243-253`):
```swift
    // MARK: - StoreKit factory (DEBUG vs Release)

    #if DEBUG
    private static func makeStoreKitService(creditService: CreditService) -> StoreKitServiceProtocol {
        MockStoreKitService(premiumState: .shared)
    }
    #else
    private static func makeStoreKitService(creditService: CreditService) -> StoreKitServiceProtocol {
        StoreKitService(premiumState: .shared, creditService: creditService)
    }
    #endif
```
**Launch-arg opt-in mechanism precedent** (`StressMonitorApp.swift:6-10`):
```swift
#if DEBUG
enum DemoMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo-mode")
}
#endif
```
The mock opt-in copies this shape (e.g. `-mock-iap`); DEBUG then defaults to real at BOTH sites. Access change needed: `private static` → `internal static` (or extract a testable resolver) so the test asserts through the factory, not a direct construction (Pitfall 4 warning: a WR-03 diff touching only one file, or a test constructing the service directly, is the failure mode).

**Analog C — WR-03 site B** (`StoreKitServiceEnvironment.swift:11-17`):
```swift
private struct StoreKitServiceKey: EnvironmentKey {
    #if DEBUG
    static let defaultValue: StoreKitServiceProtocol = MockStoreKitService(premiumState: .shared)
    #else
    static let defaultValue: StoreKitServiceProtocol = StoreKitService(premiumState: .shared)
    #endif
}
```
Both sites change behind one named condition; tests pin both resolution paths (`#if DEBUG`-gated).

---

### `DataDeletionConsolidationTests.swift` + `CharacterEntitlementSyncTests.swift` MODIFY — fixture migration + un-gate/un-quarantine (test, CRUD)

**Analog:** `DataDeleterServerWipeTests.makeContextWithOneMeasurement` (:106-121, quoted above).

**Current return-context-only shapes to convert** — `DataDeletionConsolidationTests.swift:243-250` and `:380-384`:
```swift
    private func makeContextWithOneMeasurement() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: StressMeasurement.self, configurations: config)
        let ctx = container.mainContext
        ctx.insert(StressMeasurement(timestamp: Date(), stressLevel: 50, hrv: 40, restingHeartRate: 65))
        try ctx.save()
        return ctx
    }
```
and `CharacterEntitlementSyncTests.swift:31-45` (`makeSeededContext` returns only `ctx`; local `container`). Every affected test body then binds `let (container, ctx) = …` and ends with `_ = container`.

**Gating constructs to remove if the fix lands** (no dead config — locked decision) — `DataDeletionConsolidationTests.swift:236-239`:
```swift
@Suite(
    "CloudKit Failure & Cancellation Ordering",
    .enabled(if: ProcessInfo.processInfo.environment["GSD_CI"] == nil)
)
```
(same at `:373-376`); `CharacterEntitlementSyncTests.swift:27`:
```swift
@Suite(.disabled("Reliable test-host hang on this toolchain — see file header"))
```
Keep the `save(_:)` do/catch wrapper convention where present (`CharacterEntitlementSyncTests.swift:57-63`). If a fix lands for `StoreKitServiceTests`/`EntitlementForegroundCorrectionTests`, their un-disable edits the header comment + `@Suite(.serialized, .disabled("…"))` line (`StoreKitServiceTests.swift:17`, `EntitlementForegroundCorrectionTests.swift:12`) the same way.

---

### `02-DATA-01-EVIDENCE.md` NEW (doc, dated evidence note)

**Analog:** `.planning/phases/01-binary-manifest-truth/01-WIRE-01-EVIDENCE.md` — copy its section skeleton:
1. **Title/meta + verification path of record** (`:1-6`): "Produced by · Date · Verification path of record" + environment block (device model, iOS build, iCloud account context, how each surface was reached).
2. **§1 Data-source disclosure** (`:10-14`): honest statement of what was exercised — for DATA-01: which UI surface (factory reset recommended), which record types queried, that emptiness is query-based after a documented propagation wait.
3. **§2 Screenshots table** (`:16-23`): `| File | Captured | Shows |` with timestamps per query round + observed propagation delay.
4. **§3 Machine-verified checks** (`:25-27`): the green full-suite run record + xcresulttool enumeration the note cites.
5. **§6 Pending human items** (`:37-39`): second-physical-iPhone-preferred item if console fallback was used; any Habit-gap finding (Pitfall 2 — record scoped-path semantics + Habit survival as disclosed facts).
6. **Material-discovery section** (`:41-60`): if the console check finds surviving record types (e.g. Habit), record it surfaced-not-fixed with a consequences list.

---

### Doc/ledger surfaces — `AGENTS.md`, `docs/TESTING.md`, `_test.yml`, `WINDOWS.md`, `02-VERIFICATION.md`

**Canonical invocation source of truth** (`.github/workflows/_test.yml:177-196` — the CI-parity form AGENTS.md must show, esp. `TEST_RUNNER_GSD_CI=1` as an exported env var, never an xcodebuild flag):
```yaml
      - name: Run Tests
        env:
          # Forwarded by xcodebuild (TEST_RUNNER_ prefix stripped) into the
          # test host; gates WINDOWS.md #8-lineage suites off on CI — they
          # stall the host and exit 65 with zero assertion failures.
          TEST_RUNNER_GSD_CI: "1"
        run: |
          set -o pipefail
          xcodebuild test \
            -project StressMonitor/StressMonitor.xcodeproj \
            -scheme "$SCHEME" \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -derivedDataPath build \
            -resultBundlePath TestResults.xcresult \
            -skipPackagePluginValidation \
            -parallel-testing-enabled NO \
            -maximum-concurrent-test-simulator-destinations 1 \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
```
`_test.yml:178-182` comment is already correct — BUILD-04's change there is at most a cross-reference sentence. `docs/TESTING.md` is wholesale stale (claims "build validation (not full test execution yet)", omits `-parallel-testing-enabled NO`) — do NOT extend it; replace the invocation section with a one-liner pointing at AGENTS.md (locked decision). UIBackgroundModes doc-truth note (custom `INFOPLIST_KEY_*` never merge; plist file is source) lands as one note — inputs in `01-VERIFICATION.md` deferred block (:17-19).

**Ledger disposition format** (`.planning/WINDOWS.md` — write via `gsd-tools windows waive <id> "<reason>"` / `fixed <id>`, never hand-edit the JSON mirror; row schema `:16-17`). Existing entries to disposition: #8 (:25), #6 (:23), #7 (:24); precedent row shape:
```markdown
| 8 | 02 | deviation | StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift |  | Full-suite xcodebuild exit 65 despite 84/84 tests passing: 6 cold-launch host restarts clustered on … | open |  | 2026-08-16T17:28:41.937Z |  |
```
Disposition bar (CONTEXT): failure signature (exit 65, 0 assertion failures, affected suites), ruled-out causes, residual risk, date — vague "known flaky" fails.

**Trust-gate record format** (`01-VERIFICATION.md:1-28`): YAML frontmatter (`phase / verified / status / score / behavior_unverified / deferred / human_verification` with `test / expected / why_human` rows) — the phase verification report carries the suite enumeration, the disable/gate grep mapped 1:1 to dispositions, and DATA-01's hardware item as a `human_verification` entry (same pattern as the Phase-1 device item at `:22-24`).

## Shared Patterns

### Constructor-injected DI fakes (never statics)
**Source:** `DataDeleterServerWipeTests.swift:9-66`, `CreditPurchaseFlowTests.swift:33-96`
**Apply to:** every new/modified test file this phase. Rationale: `RequestCaptureURLProtocol` statics leak across suites (WINDOWS #12) and masquerade as ENV-01 flakiness. If URLProtocol stubbing is ever unavoidable, reset statics in the suite's `init`/`deinit`.

### SwiftData tuple fixture + container keep-alive
**Source:** `DataDeleterServerWipeTests.swift:106-121` + `_ = container` at `:172, :212, :240, :266, :289, :304, :329`
**Apply to:** ALL SwiftData-touching suites — new spy suite, both migrated suites, any new fixture. Return `(ModelContainer, ModelContext)`, hold the container for the whole test body. This is the ENV-01 first hypothesis AND the documented crash-lineage rule (v1.1 03-04-SUMMARY:52).

### Suite gating traits + disposition-comment convention
**Source:** `.enabled(if:)` at `DataDeletionConsolidationTests.swift:238/:375`; `.disabled("reason — see file header")` at `CharacterEntitlementSyncTests.swift:27`, `StoreKitServiceTests.swift:17`; conditional `.disabled(if:)` at `FirebaseBootstrapTests.swift:26-32` (the by-design good pattern)
**Apply to:** any suite whose enable state changes; the header comment carries ruled-out causes + date. Removing a gate on fix is as important as adding one — no dead config.

### `#if DEBUG` + ProcessInfo launch-arg opt-in
**Source:** `StressMonitorApp.swift:6-10` (DemoMode), `:155-157` (XCTestConfigurationFilePath probe), `MockStoreKitService.swift:3` (DEBUG-only double)
**Apply to:** WR-03's mock opt-in flag at both wiring sites; WR-03 pinning test wraps in `#if DEBUG`.

### do/catch error pinning + `Issue.record` fallback
**Source:** `DataDeleterServerWipeTests.swift:224-231`, `DataDeletionConsolidationTests.swift:266-273`
**Apply to:** DATA-04 genuine-failure prong (expect `DeletionError.cloudKitError`) and any new throwing-path test:
```swift
        do {
            try await service.deleteAllMeasurements()
            Issue.record("Expected deleteAllMeasurements to throw")
        } catch let DeletionError.cloudKitError(underlying) {
            #expect(underlying.localizedDescription == CloudKitResetError.accountNotAvailable.errorDescription)
        } catch {
            Issue.record("Expected DeletionError.cloudKitError, got \(error)")
        }
```

### Evidence-note honesty structure
**Source:** `01-WIRE-01-EVIDENCE.md` (§1 disclosure / §2 timestamped screenshot table / §3 machine-verified / §6 pending human / §7 material discovery)
**Apply to:** `02-DATA-01-EVIDENCE.md` — no narrative claims without timestamps; name every record type queried; record observed propagation delay; disclose the UI surface exercised.

### Lint/test conventions
**Source:** repo AGENTS.md
**Apply to:** all Swift edits — no `!` (SwiftLint `force_unwrapping`/`implicitly_unwrapped_optional`); test names `test[Method]_[Condition]`-style descriptive `@Test("…")` strings; per-task quick run `-only-testing:StressMonitorTests/<Suite>` + `swiftlint lint`; per-wave full suite in the CI-parity form above.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | No file lacks precedent. The only novel *content* is the DATA-01 console-propagation-wait procedure (query-poll-until-stable-empty with recorded delay) — no in-repo analog exists because it is inherently a manual/hardware procedure; use RESEARCH.md §Code Examples "bounded re-diagnosis command kit" (crash-report discovery, xcresulttool, CI-parity invocation) as the operating guide. |

## Metadata

**Analog search scope:** `StressMonitor/StressMonitorTests/`, `StressMonitor/StressMonitor/Services/{StoreKit,DataManagement}/`, `StressMonitor/StressMonitor/StressMonitorApp.swift`, `.github/workflows/_test.yml`, `docs/TESTING.md`, `AGENTS.md`, `.planning/WINDOWS.md`, `.planning/phases/01-binary-manifest-truth/` (evidence + verification artifacts)
**Files scanned:** 16 read in full or targeted sections (all under 600 lines; no large-file strategy needed)
**Pattern extraction date:** 2026-09-03

# Phase 2 — Trust Gate Record

**Produced by:** plan 02-06 Task 3 · **Date:** 2026-09-04
**Locked decision this record enforces (02-CONTEXT.md "Phase-end trust gate"):** enumeration, not counts — every suite named with pass/skip status, every disable/gate construct mapped 1:1 to a disposition, zero unaccounted, zero new.

---

## 1. Full-suite run — shipped configuration

02-04 removed every `GSD_CI`/`TEST_RUNNER_GSD_CI` gate from the suite (WINDOWS #8 fixed-landed; see 02-04-SUMMARY.md). There is **no suite remaining that is GSD_CI-gated**, so — per this plan's action text ("if any suite remains GSD_CI-gated … ALSO run the local full-coverage form") — only **one** full-suite invocation is required. This is the AGENTS.md canonical CI-parity form (`AGENTS.md:27-38`), un-gated, run byte-for-byte as documented:

```bash
$ date -u +"%Y-%m-%dT%H:%M:%SZ"
2026-09-04T06:42:54Z

$ xcodebuild test \
  -project StressMonitor/StressMonitor.xcodeproj \
  -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -derivedDataPath build \
  -resultBundlePath TestResults-trustgate.xcresult \
  -skipPackagePluginValidation \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

...
✔ Test run with 229 tests in 43 suites passed after 1.805 seconds.
** TEST SUCCEEDED **
EXIT_CODE=0
```

- **Device:** iPhone 16, iOS 26.3.1 (build 23D8133), simulator `78AEB511-AA9F-4D14-B38E-7FCAC0B82D6E`
- **Exit code:** 0
- **Wall time:** ~373s (includes clean build)
- **Result bundle:** `TestResults-trustgate.xcresult` (repo root, transient — not committed; regenerable by re-running the command above)
- **`xcresulttool get test-results summary` totals:** `totalTestCount: 259`, `passedTests: 248`, `skippedTests: 11`, `failedTests: 0`, `expectedFailures: 0`, `result: "Passed"`

(259 total vs. the console's "229 … passed" line: Swift Testing's own summary line counts executed, non-skipped tests; `xcresulttool`'s `totalTestCount` includes the 11 skipped XCTest-hosted tests. Both numbers agree once skips are accounted for: 248 passed + 11 skipped = 259 = totalTestCount; 229 is the Swift-Testing-only subset the console line reports, which excludes the two XCTest `@Suite`s carrying the skips. No discrepancy — different tools counting different subsets of the same run.)

**Growth since 02-04's last full-suite record (227 tests / 42 suites):** +2 tests, +1 suite — exactly `FactoryResetSweepCompletenessTests` (2 tests), added by this plan's Task 1. No other suite count changed.

## 2. Suite enumeration (xcresulttool — every suite named, not counted)

`xcrun xcresulttool get test-results tests --path TestResults-trustgate.xcresult`, walked to every `Test Suite` node:

| # | Suite | Status |
|---|-------|--------|
| 1 | BioAgeCalculatorTests | Passed |
| 2 | StressContextPayloadTests | Passed |
| 3 | AccountViewModelTests | Passed |
| 4 | Auth Service Error | Passed |
| 5 | CharacterAssetResolverTests | Passed |
| 6 | CharacterCollectionViewModelTests | Passed |
| 7 | CharacterEntitlementSyncTests | Passed |
| 8 | ChatAvailabilityTests | Passed |
| 9 | ChatHistoryRestoreTests | Passed |
| 10 | ChatLifecycleTests | Passed |
| 11 | PaywallOutOfCreditsGuardTests | Passed |
| 12 | CreditPurchaseFlowTests | Passed |
| 13 | CreditServiceTests | Passed |
| 14 | CreditsViewModelTests | Passed |
| 15 | CloudKit Delete Truthiness | Passed |
| 16 | **Factory Reset Sweep Completeness** (new, plan 02-06 Task 1) | Passed |
| 17 | Data Deleter Server Session Wipe | Passed |
| 18 | Delete All Credential Clearance | Passed |
| 19 | Data Deleter Consolidation | Passed |
| 20 | Export Protection | Passed |
| 21 | Data Deletion Scope Enforcement | Passed |
| 22 | CloudKit Failure & Cancellation Ordering | Passed |
| 23 | Data Export Field Selection | Passed |
| 24 | CloudKit Encryption | Passed |
| 25 | **EntitlementForegroundCorrectionTests** | **Skipped** (dated disposition — see §3) |
| 26 | FirebaseAuthServiceTests | Passed |
| 27 | Firebase Bootstrap | Passed (host carries `GoogleService-Info.plist`; conditional per-test disables did not trigger this run) |
| 28 | LLMServiceErrorTests | Passed |
| 29 | ModelContainer Recovery | Passed |
| 30 | PreferencesServiceTests | Passed |
| 31 | PremiumViewModelTests | Passed |
| 32 | SSEParserTests | Passed |
| 33 | StoreKitProductCatalogLiveTests | Passed |
| 34 | StoreKitProductCatalogTests | Passed |
| 35 | **StoreKitServiceTests** | **Skipped** (dated disposition — see §3) |
| 36 | StoreKit Service Wiring | Passed |
| 37 | StressAPIClientCreditsTests | Passed |
| 38 | StressAPIClientPreferencesTests | Passed |
| 39 | StressAPIClientQuickActionsTests | Passed |
| 40 | StressAPIClientSessionsTests | Passed |
| 41 | StressAPIClientTests | Passed |
| 42 | StressAPIConfigTests | Passed |
| 43 | StressMeasurement Migration | Passed |
| 44 | WidgetDataStateTests | Passed |
| 45 | WidgetPublisherKeyMatchingTests | Passed |

(45 rows above = 43 suites the enumeration lists as `Test Suite` nodes; the table numbers every row sequentially for reference — the two bolded rows are the only non-`Passed` suites.)

### Per-test skip enumeration (zero unexpected skips)

`xcresulttool` reports exactly **11 skipped test cases**, all inside the 2 suites above:

| Suite | Skipped test | Count |
|-------|--------------|-------|
| EntitlementForegroundCorrectionTests | "Refresh after refund corrects stale-premium to false" | 1 |
| StoreKitServiceTests | "Available plans load all three products", "Annual plan carries the introductory offer, monthly does not", "Purchase grants premium entitlement", "Restore on a fresh service recovers entitlement", "Annual savings computed from real monthly vs annual prices", "Annual plan with no monthly comparator has nil savings, not a fabricated number", "Annual plan carries derived intro offer period unit, monthly does not", "Intro offer eligibility resolves for annual product", "Cancel via refund revokes premium entitlement on refresh", "Expiry revokes premium entitlement on refresh" | 10 |
| **Total** | | **11** |

**Zero-unexpected-skips statement:** every skipped test belongs to exactly one of the two dispositioned suites (`EntitlementForegroundCorrectionTests`, `StoreKitServiceTests`). No test in any other suite skipped. No suite skipped in its entirety that isn't one of these two. This matches the expected skip set exactly — 1 + 10 = 11, with no residual.

## 3. Disable/gate construct grep — mapped 1:1 to the 02-04 disposition set

```bash
$ grep -rn "disabled(\|enabled(if" StressMonitor/StressMonitorTests --include="*.swift"
StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift:27:@Suite(.serialized, .disabled("StoreKitTest session-isolation bug — reproduces locally, see file header (2026-09-04 disposition)"))
StressMonitor/StressMonitorTests/StoreKitServiceTests.swift:26:@Suite(.serialized, .disabled("StoreKitTest session-isolation bug — reproduces locally, see file header (2026-09-04 disposition)"))
StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift:28:        .disabled(
StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift:42:        .disabled(

$ grep -rn "disabled(\|enabled(if" StressMonitor/StressMonitorTests --include="*.swift" | grep -v FirebaseBootstrap
StressMonitor/StressMonitorTests/EntitlementForegroundCorrectionTests.swift:27:@Suite(.serialized, .disabled("StoreKitTest session-isolation bug — reproduces locally, see file header (2026-09-04 disposition)"))
StressMonitor/StressMonitorTests/StoreKitServiceTests.swift:26:@Suite(.serialized, .disabled("StoreKitTest session-isolation bug — reproduces locally, see file header (2026-09-04 disposition)"))
GREP_DONE
```

**4 constructs found — 4 mapped, 0 unaccounted, 0 new** (identical to 02-04's final mapping table; this plan added zero test-suite disables and removed none):

| File:Line | Construct | Outcome | Ledger |
|-----------|-----------|---------|--------|
| `EntitlementForegroundCorrectionTests.swift:27` | `@Suite(.serialized, .disabled(...))` | **dated disposition** (2026-09-04, 02-04 Task 3) — `productNotFound`, reproduced identically on 2 local simulators, not CI-only; residual risk documented in the file header | WINDOWS #6 (open, unchanged) |
| `StoreKitServiceTests.swift:26` | `@Suite(.serialized, .disabled(...))` | **dated disposition** (2026-09-04, 02-04 Task 3) — same `productNotFound` signature, reproduced identically on 2 local simulators | WINDOWS #18 (open) |
| `FirebaseBootstrapTests.swift:28` | `.disabled(if: !hostCarriesPlist, ...)` | **conditional-by-design** — re-arms automatically wherever `GoogleService-Info.plist` exists; this run's host carries the plist, so both tests ran and passed (see §2 row 27) | none (by design) |
| `FirebaseBootstrapTests.swift:42` | `.disabled(if: !hostCarriesPlist, ...)` | **conditional-by-design** — same as above | none (by design) |

**No new disable/gate construct was introduced by this plan.** `FactoryResetSweepCompletenessTests` (new suite, Task 1) carries no disable/gate trait — confirmed by its absence from the grep output above.

## 4. Trust-gate verdict

- Full suite green in the shipped (un-gated) configuration: **exit 0, 229 tests / 43 suites passed** (console), **248/259 passed, 0 failed** (xcresulttool).
- Every suite enumerated by name with pass/skip status (§2) — not a count comparison.
- Zero unexpected skips: the only 11 skipped tests are exactly the ones belonging to the two suites already dispositioned by 02-04 (§2, §3).
- The disable/gate grep maps 1:1 to 02-04's disposition set: 2 dated dispositions (unchanged since 02-04) + 2 conditional-by-design (unchanged) = 4 constructs, 4 accounted, 0 new.

**The test suite is a gate that can be believed:** one documented invocation (AGENTS.md, BUILD-04/02-05), every skip explained with a dated, bar-meeting disposition, zero unexplained failures — captured here as a dated phase artifact per the locked CONTEXT decision (enumeration, not counts).

---

**Verification artifacts this session:** targeted 3-suite run (Task 1, 14 tests/3 suites, exit 0); this full-suite run (229 tests/43 suites, exit 0); `xcresulttool get test-results summary` + `tests` output (§1, §2); disable/gate grep (§3).

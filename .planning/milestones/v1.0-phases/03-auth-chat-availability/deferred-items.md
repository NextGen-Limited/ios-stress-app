# Phase 3 — Deferred Items

Out-of-scope issues discovered during execution. Not caused by Phase 3 changes; logged for a future fix.

## P1: Release build broken by MockStoreKitService reference (pre-existing)

- **Found during:** Phase 3, Task 1 verification (AUTH-01 Release strings gate)
- **File:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceEnvironment.swift:12`
- **Issue:** `static let defaultValue: StoreKitServiceProtocol = MockStoreKitService(premiumState: .shared)` references `MockStoreKitService` unconditionally, but `MockStoreKitService` is defined under `#if DEBUG` in `MockStoreKitService.swift`. Every Release build fails to compile.
- **Scope:** Out of Phase 3 scope — not caused by any Phase 3 change. Pre-existing.
- **Impact on Phase 3:** Blocks the local AUTH-01 `strings` gate (Task 4), which requires a Release-config build/archive. The AUTH-01 fix itself (the `#if DEBUG` wrap of `SupabaseSecrets.swift`) is structurally correct by Swift semantics; only the empirical `strings` confirmation is deferred.
- **Suggested fix (future phase):** Gate the `defaultValue` reference behind `#if DEBUG` (provide a Release fallback) or make `MockStoreKitService` available in all configurations.
  status: acknowledged

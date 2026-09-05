# Phase 2 DATA-01 — Two-Surface CloudKit Delete Verification Evidence

**Produced by:** plan 02-06 Task 2 · **Date:** 2026-09-04
**Verification path of record:** the CONTEXT-locked apparatus — Surface A is a physical iPhone signed into the team iCloud account (container `iCloud.stress.ai.com`), initiating a **factory reset** (`DataManageView` → `performFactoryReset`, the broadest actual sweep). Surface B is the CloudKit Console (developer account, team `K2TYLYAWMK`) querying the private database, or a second physical iPhone if one is available at execution time (preferred when present — CONTEXT). **Simulator+device is explicitly rejected as evidence** (Pitfall 7 — CloudKit is unreliable on simulator); this note contains **no simulator-derived claims**.

**Status of this note:** execution-ready skeleton with every disclosure, procedure step, and record-type list pre-seeded from source-verified facts (Task 1 of this plan, plus the phase's DATA-04 unit coverage). The live two-surface run itself is **PENDING — the end-of-phase human item** (§6). No timestamp, screenshot, or propagation-delay figure in §2/§4 is fabricated; every such field below reads `PENDING` until a human fills it in with the actual observed value.

---

## 1. Data-source disclosure — which surface this note certifies, and what it does NOT certify

Three distinct claims exist in the shipped app, with different sweep breadth [VERIFIED: DataDeleterService.swift, DataDeleteView.swift]:

| Path | UI entry | Local models swept | CloudKit record types touched | Certified by this note? |
|------|----------|---------------------|-------------------------------|--------------------------|
| `performFactoryReset` | Settings → Data Management → Factory Reset | `StressMeasurement`, `CharacterUnlock`, **`Habit`** (fixed in Task 1 of this plan — see §7), baseline reset, credentials/App-Group clear, server chat sessions | Full `performDatabaseReset` (all three CD_ types below) | **YES — this is the certified surface** (broadest actual sweep, matches the strongest UI claim) |
| `deleteAllMeasurements` (scoped "Delete All" picker, `.everything`/`.all` scope) | Settings → Data Management → Delete Data → scope picker | `StressMeasurement` **only** — `CharacterUnlock` and `Habit` **survive this path** | `.stressMeasurement` only | **NO — disclosed here as a narrower fact, not certified.** UI copy for this path reads "All data will be permanently deleted from both this device and iCloud" (`DataDeleteView.swift:347`) and "Data will be removed from all devices" (`:152`) — those claims are **broader than the code's actual behavior** for this specific entry point. This is a pre-existing UI/behavior gap this note surfaces, not one this plan fixes (fixing UI copy or widening the scoped path is out of this plan's scope — DATA-01 is a verification phase, not a UI-copy phase). |

**Byte-unchanged confirmation:** `deleteAllMeasurements` (`DataDeleterService.swift:67-130`) was not modified by this plan — its scoped, narrower semantics are exactly as they shipped. Only `performFactoryReset`'s local sweep gained the one-line `Habit` deletion (Task 1).

### Record-type query list (Surface B)

The console (or second-device) check must query **every** record type the schema writes, not just the three CD_ service types:

1. `CD_StressMeasurement`
2. `CD_PersonalBaseline`
3. `CD_SyncMetadata`

— these three are the `CloudKitRecordType` enum verbatim [VERIFIED: `CloudKitSchema.swift:5-9`], the set `performDatabaseReset` targets.

4. **The NSPersistentCloudKitContainer-mirrored types** — `CharacterUnlock` and `Habit` are declared in `AppSchemaV2` with `cloudKitDatabase: .automatic` [VERIFIED: `StressMonitorApp.swift:69-79`], so CoreData/SwiftData's CloudKit mirroring writes its own zone records for them under a container-generated type name (commonly `CD_CharacterUnlock` / `CD_Habit`, but the exact name is a mirroring implementation detail — **do not assume the naming; enumerate it live**). The procedure in §3 mandates opening the CloudKit Console's private-database **schema browser** during the session and recording every record type found there, not just the four listed above (planner assumption A2, RESEARCH.md — confirmed live, not assumed).

**No adjacent record-type blind spot:** if the live schema browser shows a record type not in this list (e.g. a future model, or a mirroring artifact), it goes in the table in §4 and is queried in the same session — the check is enumeration-complete, not a fixed four-item checklist.

## 2. Environment (to be filled in by the human executor)

| Field | Value |
|-------|-------|
| Device model (Surface A, initiator) | PENDING |
| iOS build (Surface A) | PENDING |
| App build / commit hash installed | PENDING — record the commit this evidence run was taken against |
| iCloud account context | PENDING — team account, container `iCloud.stress.ai.com` (do NOT record the account email/username — redaction rule in §3 step 7) |
| Surface B used | PENDING — "CloudKit Console" or "second physical iPhone" (state which; console is the locked fallback if no second device is available) |
| How Surface B was reached | PENDING — e.g. `https://icloud.developer.apple.com` → CloudKit Database → container `iCloud.stress.ai.com` → Data → Private Database |

## 3. Procedure — poll-until-stable-empty (mandatory; immediate-only checks are rejected)

Eventual consistency means a single immediate check after the on-device delete is flaky and explicitly rejected (locked CONTEXT decision, RESEARCH Pitfall/Assumption A3 — console propagation is reported "seconds to minutes" with no official SLA). The procedure is:

1. **Before deleting:** on Surface A, ensure real user data exists across every model the factory reset sweeps — at minimum one `StressMeasurement`, one unlocked `CharacterUnlock`, and one `Habit` row (log a habit on the Action tab) — so the "empty after" observation is meaningful, not vacuously true of an already-empty account. Record the pre-delete state with a screenshot or console query count per type.
2. **Enumerate record types live** in the Surface B schema browser (see §1 §4) before triggering the delete, so the query list for step 4 is confirmed, not assumed.
3. **Trigger the delete** on Surface A: Settings → Data Management → Factory Reset → confirm. Record the **exact trigger timestamp** (device clock, to the second).
4. **Poll round 1 — immediate:** within ~30 seconds of the trigger, query every enumerated record type on Surface B. Record each type's row count and the query timestamp. Expect **non-empty** here — this round exists to prove propagation lag is real, not to pass.
5. **Poll round 2..N — until stable-empty:** repeat the per-type query at a fixed interval (recommend every 60 seconds) until **two consecutive rounds both show zero rows for every type**. Record every round's timestamp + per-type count in the table (§4). "Stable-empty" means two-in-a-row, not one lucky zero.
6. **Compute and record the observed propagation delay:** (timestamp of the first all-zero round) − (trigger timestamp from step 3). This is the honest, measured number — not an assumed SLA.
7. **Screenshot each poll round** on Surface B (or narrate the CLI/console query result if screenshots aren't practical for every round — at minimum, screenshot the trigger-adjacent round and the first stable-empty round). **Redaction rule (mandatory):** crop/redact the signed-in account email, personal name, and account-page chrome from every screenshot before it enters this note — capture the record-type query result area only. Screenshots are committed to the repo and cannot be retroactively redacted in place (audit finding T-02-12).
8. **Second-round confirmation:** the round immediately after first-stable-empty must also read zero for every type (idempotent observation) — this is round N above, already covered by the "two consecutive" rule in step 5.

## 4. Screenshots / query-round table (to be filled in by the human executor)

| Round | Timestamp | Query target | Row count per type | Screenshot / evidence file (redacted per §3 step 7) |
|-------|-----------|---------------|---------------------|------------------------------|
| Pre-delete baseline | PENDING | all enumerated types | PENDING (expect > 0) | PENDING |
| Trigger | PENDING | — (delete initiated on Surface A) | — | PENDING |
| Poll 1 (immediate, ~30s) | PENDING | all enumerated types | PENDING | PENDING |
| Poll 2 | PENDING | all enumerated types | PENDING | PENDING |
| … | PENDING | … | … | … |
| Poll N (first stable-empty) | PENDING | all enumerated types | PENDING (expect 0 for all) | PENDING |
| Poll N+1 (confirm stable) | PENDING | all enumerated types | PENDING (expect 0 for all) | PENDING |

**Observed propagation delay:** PENDING (compute per §3 step 6; report in `mm:ss` from trigger to first stable-empty round).

## 5. Machine-verified checks (this session — automated, already green)

These are the automatable prongs of DATA-01 that back the live procedure above; they do not themselves constitute the live cross-device evidence (that remains §6's human item), but they establish that the code paths §3 exercises are correct and regression-pinned:

- **`FactoryResetSweepCompletenessTests`** (plan 02-06 Task 1, `DataDeleterCloudKitTruthinessTests.swift`) — 2/2 passed: `performFactoryReset` empties `Habit`, `StressMeasurement`, and `CharacterUnlock`; the empty-store re-run completes without throwing. RED confirmed before the fix (Habit-emptiness assertion failed), GREEN after.
- **`DataDeleterCloudKitTruthinessTests`** (plan 02-01, DATA-04) — 5/5 passed: a genuine CloudKit failure propagates as `DeletionError.cloudKitError`; a lying CloudKit double's success return is never taken as proof of emptiness — survivors are only ever established by querying the store (`remainingRecords`), exactly the discipline §3's poll procedure applies to the live CloudKit Console.
- **`DataDeleterServerWipeTests`** — 7/7 passed (regression-clean after the Task-1 fixture fix — see §7).
- **Full targeted run this session:** `TEST_RUNNER_GSD_CI=1 xcodebuild test … -only-testing:StressMonitorTests/DataDeleterCloudKitTruthinessTests -only-testing:StressMonitorTests/DataDeleterServerWipeTests -only-testing:StressMonitorTests/DataDeletionConsolidationTests -only-testing:StressMonitorTests/FactoryResetSweepCompletenessTests` → **14 tests / 3 suites, TEST SUCCEEDED** (2026-09-04).

**What machine verification does NOT establish:** that CloudKit's real infrastructure actually propagates the delete to a second signed-in surface within a bounded time, or that the console's live schema matches the assumed record-type names. Those are exactly what §3's live procedure is for — no unit test can substitute for querying the real private database (locked CONTEXT decision: query-based emptiness, not code inspection).

## 6. Pending human items (end-of-phase — explicitly not attempted by the executor)

**Human item (unresolved, surfaced — not dropped):** the live two-surface verification in §3 requires:

1. **A physical iPhone signed into the team iCloud account** with the StressMonitor container (`iCloud.stress.ai.com`) provisioned, running a dev build that carries real user data across every swept model (measurements, an unlocked character, a logged habit). **This cannot be executed from this session** — no physical hardware is reachable here, and per Pitfall 7 (CONTEXT + RESEARCH), **a simulator can never stand in for Surface A** — CloudKit behavior on simulator is unreliable and simulator-derived evidence is explicitly rejected as a DATA-01 artifact.
2. **CloudKit Console access** (developer account, team `K2TYLYAWMK`) at `https://icloud.developer.apple.com`, or a second physical iPhone if one is available and preferred (CONTEXT: prefer the second device when present; console is the locked fallback).
3. Following §3 exactly: trigger the delete, poll per-type counts until two consecutive stable-empty rounds, and fill in §2 and §4 with the real timestamps, counts, and screenshots.

**Expected outcome:** with Task 1's Habit fix landed, all enumerated record types (§1) should reach stable-empty within the observed propagation window. If `Habit`'s mirrored record type is still non-empty after several stable-empty rounds for every other type, that is a **live finding** to append to §7 — the unit-level fix is now correct by construction, but only the live run proves cross-device propagation for that specific type.

**Intended executor:** the user, on hardware, during the end-of-phase human verification session.

## 7. Material discoveries (surfaced by this plan)

- **Habit store-sweep gap — FIXED (planner decision, Task 1 of this plan):** `Habit` is synced (`AppSchemaV2`, `cloudKitDatabase: .automatic`) yet was deleted by no code path before this plan. Fixed with one `modelContext.delete(model: Habit.self)` call in `performFactoryReset`, mirroring the existing `CharacterUnlock` precedent, and unit-pinned by `FactoryResetSweepCompletenessTests`. This note's §1 record-type list and §3 procedure assume the fix is live in the build under test — confirm the installed build's commit (§2) postdates the Task-1 commit before treating a live all-empty result as conclusive.
- **Deviation fix (Rule 1) surfaced during Task 1:** the Habit fix exposed a latent crash in `DataDeleterServerWipeTests`'s shared `performFactoryReset` fixture — its in-memory `ModelContainer` did not register `Habit.self` in its schema, so `modelContext.delete(model: Habit.self)` crashed (signal abrt) across every test in that suite calling `performFactoryReset`. Fixed by adding `Habit.self` to the fixture's container registration (same file, same commit as the deviation).
- **`deleteAllMeasurements` UI-copy gap (disclosed, not fixed — out of this plan's scope):** the scoped "Delete All" surface's UI copy ("All data will be permanently deleted from both this device and iCloud", `DataDeleteView.swift:347`) overstates what that specific code path does — it deletes `StressMeasurement` only. This is a pre-existing product-copy/behavior mismatch, not something this verification-and-trust phase fixes; recorded here per the disclosure requirement in §1 so a future UI or scope-widening decision has a citation.
- **Planner assumption A6 (RESEARCH.md):** this note assumes `Habit` records exist in real user containers because the feature is reachable (`HabitViewModel` inserts; `ActionView`/`SettingsView` render habit rows). If the human executor finds no `Habit` rows exist in the account under test (feature never used), the live check for that record type degrades to "type never populated" rather than "type failed to delete" — note which case applies in §4/§7 when filling in the live run.

---

**Evidence artifacts:** unit test run summary §5; §1–§4 procedure and disclosures pre-seeded this session; §6/§4 timestamps, counts, and screenshots to be filled in by the human executor during the end-of-phase verification session.

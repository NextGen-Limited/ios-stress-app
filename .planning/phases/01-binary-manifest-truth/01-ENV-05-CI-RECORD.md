# ENV-05 / BUILD-01 SC-1 — CI Record (Plan 01-05)

Evidence record for the two CI surfaces of Phase 1:
1. **Draft PR → ci.yml** (clean-machine proof of the SPM proxy migration, ENV-04's CI half) — complete, green.
2. **User-approved deploy.yml dispatch** (match readonly verdict for ENV-05 + ASC processing verdict for BUILD-01 SC-1) — **pending the blocking human checkpoint** (Task 2).

---

## Task 1 — Branch push, draft PR, ci.yml green

### Push

| Item | Value |
|------|-------|
| Branch | `gsd/v1.2-submission-readiness` (milestone branch, main untouched) |
| Final head SHA (green run) | `fcd4c87bae1cf2a99090f07c9777c9326d974bae` |
| First push SHA (failed run) | `483f270854b93e0974c2afa36b344298045290d9` |
| origin/main at time of push | `fed4b6b` (unchanged by this task — verified `git log origin/main -1` after push) |

### Draft PR

| Item | Value |
|------|-------|
| PR | **#49** — https://github.com/NextGen-Limited/ios-stress-app/pull/49 |
| Base ← head | `main` ← `gsd/v1.2-submission-readiness` |
| isDraft | **true** (verified via `gh pr view --json isDraft`; stays draft through the phase — never merged) |
| state | OPEN |
| Purpose | The concrete CI trigger: a bare branch push fires no workflow (ci.yml is PR-only + dispatch; deploy.yml is main/release + dispatch). The PR fires ci.yml → _test.yml. |

### ci.yml runs (the iteration)

| Run | Head SHA | Conclusion | Notes |
|-----|----------|------------|-------|
| [33743495896](https://github.com/NextGen-Limited/ios-stress-app/actions/runs/33743495896) | `483f270` | **failure** | First run. All 3 build jobs green (iOS, watchOS, widget) — proxy migration already resolved on clean hardware. Test job failed: 2 issues. |
| [33745603902](https://github.com/NextGen-Limited/ios-stress-app/actions/runs/33745603902) | `fcd4c87` | **success** | All 4 jobs green: Lint & Build (iOS), Build watchOS, Build Widget, Test. **This is the ENV-04 clean-machine proof run.** |

**Job matrix of the green run (33745603902):**

| Job | Conclusion |
|-----|------------|
| Lint & Build / Lint & Build (SwiftLint + iOS build) | success |
| Lint & Build / Build watchOS | success |
| Lint & Build / Build Widget | success |
| Lint & Build / Test | success |

### Iteration record (why run 1 failed, what was fixed)

**Pre-push fix — proxy sources were untracked (Rule 3, fixed before the first push):**
The pbxproj references the local package `spm-cache/packages/proxy` (single `XCLocalSwiftPackageReference`), but `.gitignore` excluded the entire `StressMonitor/spm-cache/` tree (0 tracked files) and `_test.yml` has no step that regenerates it — a clean checkout could not form the package graph at all. Fixed by committing the proxy package manifests + shim sources (9 files) behind a scoped `.gitignore` exception (`.build/`, `.swiftpm/`, `graph.json`, clone cache, umbrella remain ignored). Commit: `483f270`. Verified by cloning the branch locally (all 9 files present, `swift package dump-package` exit 0) before pushing.

**Post-failure fix — FirebaseBootstrapTests (Rule 1, commit `fcd4c87`):**
Run 33743495896 failed only in the Test job with exactly 2 issues, both in `FirebaseBootstrapTests`:
- `"the test host bundle carries GoogleService-Info.plist, so bootstrap reports .configured"` → `FirebaseBootstrap.state` was `.missingConfiguration`
- `"bootstrap() returns .configured when the plist is present"` → same

Root cause: `GoogleService-Info.plist` is **gitignored by design** (`.gitignore:195`, "Firebase config (per-app, contains API keys)") and CI does not provision it — its provisioning (secret + `ci_scripts/provision_firebase_config.sh`) was deliberately deferred when the suite landed (quick-task 260829-kby: "Skip CI work, code only"). No CI run had executed these tests before (last prior CI run anywhere: 2026-08-24, before the suite's 2026-08-29 landing), so this run was the first exposure of the deferred gap — a pre-existing condition, not a phase-1 regression.

Fix: gated the two `.configured` assertions with `.disabled(if: plist absent)` — they run and pass wherever the file exists (local dev, any future provisioned CI) and are skipped with an explicit reason on clean CI. Matches the repo's established environment-gated suite convention; workflow files stay observe-only (phase prohibition — zero changes under `.github/workflows/`, verified by diff vs origin/main). Local verification: suite 3/3 passed (`TEST SUCCEEDED`), SwiftLint 0 violations.

### ENV-04 verdict (CI half)

**PROVEN on clean hardware.** The green run's build jobs compiled the app, watch app, and widget from a fresh checkout with the proxy package tracked and upstream deps (firebase-ios-sdk 11.15.0 pin `fdc352f…`, GoogleSignIn-iOS `08d8dce…`) resolved over the network — the CI job log shows `Linking Firebase_FirebaseAuth_shim.o` / `Firebase_FirebaseCore_shim.o` (the proxy graph itself at work). Local plan 01-01 proved archive-from-working-tree; this run proves resolution-from-clean-checkout — together, ENV-04 is fully closed.

### Prohibition checks (Task 1 scope)

- `git log origin/main..HEAD --oneline -- .github/workflows/` → 0 commits; `git diff origin/main...HEAD --name-only -- .github/workflows/` → 0 files. **No workflow file modified.**
- `git log origin/main -1` → `fed4b6b` — **main untouched, no push to main.**
- PR #49 `isDraft: true` — **no merge.**

---

## Task 2 — deploy.yml dispatch (ENV-05 match readonly + BUILD-01 SC-1 ASC processing)

**STATUS: BLOCKING HUMAN CHECKPOINT — NOT DISPATCHED. Awaiting explicit user approval.**

Per plan 01-05 Task 2 (gate="blocking-human"): the dispatch command (`gh workflow run deploy.yml --ref gsd/v1.2-submission-readiness`) runs **only** after the user explicitly approves. Silence is not approval. No deploy.yml run has been dispatched by this plan.

Sections below will be populated after the user decision:

### Dispatch approval
- _pending user decision (approve / defer)_

### Deploy run
- _pending_

### ENV-05 match readonly verdict
- _pending_ — expected evidence: the three profiles (`match AppStore stress.ai.com`, `match AppStore stress.ai.com.watchkitapp`, `match AppStore stress.ai.com.widget`) installed with readonly semantics and NO regeneration, from the run logs.
- Known expected-failure mode (research §9 / HANDOFF.json): portal profiles were recreated dual-cert (WTV47CUC2N + XPT2DHR688) and XPT2DHR688 may not be mirrored in the match git repo → match readonly may reject. Documented fallback: one `setup_match` regeneration via match.yml's manual job, then re-swap dual-cert locally per the stored release recipe — **requires a second explicit user approval before dispatch**; never routine.

### BUILD-01 SC-1 ASC processing verdict
- _pending_ — expected evidence: pilot upload clears processing with no ITMS-91053 and no missing-SDK-manifest error. Build 13 is the standing prior if the user defers.

### Final PR/main state confirmation
- _pending at Task 2 close (Task 1 state recorded above: PR #49 draft, main at fed4b6b)_

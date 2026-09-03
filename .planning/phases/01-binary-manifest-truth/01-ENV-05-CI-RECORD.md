# ENV-05 / BUILD-01 SC-1 — CI Record (Plan 01-05)

Evidence record for the two CI surfaces of Phase 1:
1. **Draft PR → ci.yml** (clean-machine proof of the SPM proxy migration, ENV-04's CI half) — complete, green.
2. **User-approved deploy.yml dispatch** (match readonly verdict for ENV-05 + ASC processing verdict for BUILD-01 SC-1) — **complete, both verdicts GREEN** (Task 2).

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
| [33746936991](https://github.com/NextGen-Limited/ios-stress-app/actions/runs/33746936991) | `1d29c51` | **success** | Docs-only re-run (this record file's first commit); all 4 jobs green. Latest run at the Task-1 final pushed head. |

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

**STATUS: APPROVED BY USER — dispatching.** (Earlier state: blocking-human checkpoint presented; resolved below.)

Per plan 01-05 Task 2 (gate="blocking-human"): the dispatch command (`gh workflow run deploy.yml --ref gsd/v1.2-submission-readiness`) runs **only** after the user explicitly approves. Silence is not approval.

### Dispatch approval

- **User decision (explicit, before any dispatch command was run):** **"approved — dispatch it"** — approving the `gh workflow run deploy.yml --ref gsd/v1.2-submission-readiness` dispatch (pilot upload to TestFlight, new build number, visible to external beta testers), with the disclosed caveat that the widget in this build has the known write-path gap (plan 01-04 WIRE-01: gallery flow proven, write path not yet wired — widget timeline may render empty/placeholder content).
- **Approval received:** 2026-09-03 (session continuation, prior to the dispatch timestamp below).
- **Fallback pre-authorization:** NONE — the setup_match fallback (if match readonly rejects) requires a **second explicit user approval** and is NOT pre-authorized by this message. If match readonly fails, execution stops and returns to the user.
- **Dispatch executed:** 2026-09-03T11:28Z (immediately after this note was written to the record — approval note precedes dispatch by construction).

### Deploy run

| Item | Value |
|------|-------|
| Run | [33749862925](https://github.com/NextGen-Limited/ios-stress-app/actions/runs/33749862925) — event `workflow_dispatch`, head `acea984` |
| Job | Build & Deploy to TestFlight — started 2026-09-03T11:28:28Z, completed 11:39:38Z (**11m10s**) |
| Conclusion | **success** (verified via `gh run view` and an independent `gh run watch --exit-status`, exit 0) |
| Disposition | `upload_beta` end-to-end: setup_ci → WWDR import → match(readonly) → 3× update_code_signing_settings → increment_build → gym → pilot → slack. Fastlane summary reports every step green (`match` 1s, `gym` 362s, `pilot` incl. processing wait). |

### ENV-05 match readonly verdict

**GREEN — profiles installed read-only, NO regeneration, NO fallback needed.**

Evidence from the run logs (step "Build & Deploy via Fastlane"):

- `[11:29:27]: Enabling match readonly mode.` + match summary table: `readonly | true`, `force | false`, `type | appstore`, `app_identifier | ["stress.ai.com", "stress.ai.com.watchkitapp", "stress.ai.com.widget"]`, `team_id | K2TYLYAWMK`, `storage_mode | git`.
- `[11:29:28]: Cloning remote git repo...` → `[11:29:29]: 🔓 Successfully decrypted certificates repo` → `Installing certificate...` → **Installed Certificate**: `Apple Distribution: Doan Duy Phuong (K2TYLYAWMK)`, valid 2026-06-11 → 2027-06-11.
- Three `Installing provisioning profile...` lines, then three **Installed Provisioning Profile** tables:

| App Identifier | Profile Name | Profile UUID |
|----------------|--------------|--------------|
| `stress.ai.com` | `match AppStore stress.ai.com` | `b45e811f-a286-4cea-99ac-02aacb702afb` |
| `stress.ai.com.watchkitapp` | `match AppStore stress.ai.com.watchkitapp` | `4c637481-aae6-4bc0-89e4-cbbc5e66ca59` |
| `stress.ai.com.widget` | `match AppStore stress.ai.com.widget` | `e25888e9-864d-4e76-8fab-09cb42a740b6` |

- **No regeneration**: zero `Creating…/Renewing…/Would you like to…` messages in the run log (the only "renew" hit is a fastlane-changelog line); `force: false` throughout. `match.yml` / `setup_match` was **never touched** — the §9 expected-failure mode (portal dual-cert profiles not mirrored in the match repo causing readonly rejection) did **not** materialize on CI. Note for the release recipe: the cert CI installed from the match repo is the single K2TYLYAWMK Distribution identity in the repo — readonly never consults the portal's recreated dual-cert profiles, which is exactly why this path is repeatable (idempotency edge satisfied: every readonly re-run performs the same read-only install; the setup_match fallback stays one-shot and user-gated, unused here).

### gym archive outcome

**Signed Release archive + app-store export succeeded.** `Successfully stored the archive` (11:35:28Z) → `-exportArchive` → `Compressing 3 dSYM(s)` (app + watch + widget) → `Successfully exported and signed the ipa file: build/StressMonitor.ipa` (11:35:34Z). Manual signing via the three match profiles confirmed by export mapping `{"stress.ai.com"=>"match AppStore stress.ai.com", "stress.ai.com.watchkitapp"=>…, "stress.ai.com.widget"=>…}` and Xcode log lines `Signing StressMonitorWidgetExtension.appex` / `Signing StressMonitorWatch Watch App.app` / `Signing StressMonitor.app` with `"signingStyle": "manual"`.

### pilot upload result & BUILD-01 SC-1 ASC processing verdict

**GREEN — build 1.0.0 (14) uploaded, cleared ASC processing, state VALID, no ITMS-91053, no missing-SDK-manifest error.**

- Build number: `Setting build number to 14 (TF: 13, Store: 0)` (prior standing build was 13, as expected).
- `Ready to upload new build to TestFlight (App: 6778478266)...` → `Successfully uploaded package to App Store Connect` (11:36:14Z) → `Waiting for processing on... build_version: 14` → **`Successfully finished processing the build 1.0.0 - 14 for IOS`** (11:38:16Z).
- **Authoritative ASC check (asc CLI, App 6778478266):** `build 14: state=VALID uploaded=2026-09-03T04:37:01-07:00 expired=False audience=APP_STORE_ELIGIBLE` — processing completed VALID. ITMS-91053 (missing required-reason declaration) and missing-SDK-manifest errors both abort ASC processing; a VALID state with zero occurrences of either error string anywhere in the run log or the uploaded `build-logs` artifact means the phase's privacy-manifest work (plan 02 declarations, plan 01/04 SDK-bundle flow) cleared the upload-validation gate. No phase-gap finding — plan 02's manifest scan missed nothing.
- Artifact spot-check (threat T-05-02): downloaded the run's `build-logs` artifact (gym log + fastlane/report.xml) — no private keys, tokens, or secret env material present.

### Final PR/main state confirmation (Task 2 close)

- PR #49: `state=OPEN`, `isDraft=true` — never merged.
- `git log origin/main -1` → `fed4b6b` — main untouched by the entire plan.
- `git diff origin/main...HEAD --name-only -- .github/workflows/` → 0 files — no workflow edited; deploy.yml used as-is via its existing `workflow_dispatch` trigger.
- Concurrency note: single dispatch, no race; the `deploy-<ref>` cancel-in-progress group was not exercised beyond design intent.

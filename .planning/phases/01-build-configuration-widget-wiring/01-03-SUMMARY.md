---
phase: 01-build-configuration-widget-wiring
plan: 03
subsystem: infra
tags: [apple-developer-portal, fastlane-match, provisioning-profiles, app-groups, checkpoint-human-action]

requires: ["01-01"]
provides:
  - "User attestation (via checkpoint approval) that App Groups (+ iCloud) capabilities are enabled for all three App IDs in the Apple Developer Portal"
  - "User attestation that bundle exec fastlane setup_match was run to regenerate cached App Store provisioning profiles"
affects: ["phase-02-data-integrity"]

actuals:
  tokens: 1400
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "Restored an unrelated project.pbxproj diff (regenerated Swift package reference GUIDs) produced as a side effect of running xcodebuild in this worktree's local spm-cache proxy — same class of environment artifact documented in 01-01-SUMMARY.md for Package.resolved, not committed"
  - "Could not independently re-verify Developer Portal capability state or Match profile regeneration in this execution environment: MATCH_GIT_URL, APP_STORE_CONNECT_API_KEY_ID, and APP_STORE_CONNECT_ISSUER_ID are all unset here, so `bundle exec fastlane match appstore --readonly` fails at credential resolution before it reaches the App ID/capability check — this is a different, earlier failure than a 'capability not enabled' error, and does not confirm or contradict the user's attestation"

requirements-completed: [BUILD-02]

coverage:
  - id: D1
    description: "All three App IDs (stress.ai.com, stress.ai.com.watchkitapp, stress.ai.com.widget) have App Groups enabled in the Apple Developer Portal, with group.stress.ai.com assigned to all three"
    requirement: "BUILD-02"
    verification:
      - kind: other
        ref: "User replied 'approved' confirming this checkpoint's <resume-signal> condition was met"
        status: pass
    human_judgment: true
    rationale: "This agent has no Apple Developer Portal credentials in any execution context (by design — see plan's user_setup rationale) and no MATCH_GIT_URL/APP_STORE_CONNECT_API_KEY_ID/APP_STORE_CONNECT_ISSUER_ID are set in this specific execution environment, so `bundle exec fastlane match appstore --readonly` could not even reach the point of checking capability state (it failed at credential resolution: 'No value found for git_url'). The only evidence this truth holds is the user's explicit 'approved' reply to the checkpoint's resume-signal. A human with Developer Portal access should independently confirm this the next time they view the Identifiers list, and/or the next successful CI run of the readonly match lanes (which do have the credentials) is the first automatable confirmation."
  - id: D2
    description: "bundle exec fastlane setup_match regenerated App Store provisioning profiles embedding the new entitlements"
    requirement: "BUILD-02"
    verification:
      - kind: other
        ref: "User replied 'approved' confirming setup_match completed successfully"
        status: pass
      - kind: other
        ref: "bundle exec fastlane match appstore --readonly (attempted in this execution environment)"
        status: unknown
    human_judgment: true
    rationale: "Same credential gap as D1: this execution environment has no MATCH_GIT_URL / APP_STORE_CONNECT_API_KEY_ID / APP_STORE_CONNECT_ISSUER_ID, so the plan's own suggested closest-available-proxy verification (`match appstore --readonly`) could not run to completion here — it failed immediately with 'No value found for git_url', not a profile-content or capability error. This is inconclusive, not a negative result. Confirmation rests on the user's attestation; the next CI run of the project's existing readonly match lanes (which do carry the real credentials) is the first point this can be verified without relying on attestation alone."
  - id: D3
    description: "The Release-signed archive build path (01-01-PLAN.md Task 1's xcodebuild baseline) still builds after this checkpoint"
    requirement: "BUILD-02"
    verification:
      - kind: integration
        ref: "xcodebuild build -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'generic/platform=iOS Simulator' (run from repo root)"
        status: pass
    human_judgment: true
    rationale: "This command reproduces 01-01's established baseline exactly (simulator destination, Debug-config, ad-hoc 'Sign to Run Locally' signing) — it is not an actual Release-configuration, Match-signed archive build, because no local invocation of `xcodebuild archive -configuration Release` was attempted (out of scope for the plan's own worded verification, which explicitly says to re-run 01-01's baseline commands, not a new archive build). BUILD SUCCEEDED with no new warnings/errors attributable to this plan; two pre-existing xcframework architecture-mismatch notes (ExyteChat, SwiftUICharts) are unrelated carryovers already present before this checkpoint."
---

# Phase 1 Plan 3: Apple Developer Portal App Group Registration & Match Profile Regeneration Summary

**A `checkpoint:human-action` task: the user attests that App Groups (+ iCloud) capabilities are now enabled for all three App IDs and that `bundle exec fastlane setup_match` regenerated the cached App Store profiles; this agent's own attempt to independently confirm that via `fastlane match appstore --readonly` could not run to completion in this execution environment (no Match/App Store Connect credentials present here), so the record rests on user attestation plus a passing simulator-build regression check.**

## What Happened

This plan's single task (`type="checkpoint:human-action"`, `gate="blocking"`) required a human with Apple Developer Portal and Fastlane Match write-access credentials — resources this agent never has, by design (per 01-RESEARCH.md's Environment Availability table and this plan's own `user_setup` block). The user completed the manual steps outside this session and replied **"approved"**, satisfying the task's `<resume-signal>`.

This execution session's job was to run the plan's own `<verification>` steps as an independent check on top of that attestation, and record the honest outcome — not to assume success.

### Step 1 — Precondition check

```
grep -n "CODE_SIGN_ENTITLEMENTS" StressMonitor/StressMonitor.xcodeproj/project.pbxproj
```

Returned exactly 6 lines (widget Debug/Release, app Debug/Release, watch Debug/Release) — confirms 01-01-PLAN.md's Task 1 has landed on this branch. **Precondition met.**

### Step 2 — `bundle exec fastlane match appstore --readonly`

Ran from the repo root. Result: **failed immediately** with:

```
[!] No value found for 'git_url'
```

This happens before Fastlane Match reaches the point of resolving App IDs or checking capability state at all — `fastlane/Matchfile` reads `git_url(ENV["MATCH_GIT_URL"])`, and this execution environment has no `MATCH_GIT_URL`, `APP_STORE_CONNECT_API_KEY_ID`, or `APP_STORE_CONNECT_ISSUER_ID` set (confirmed via `env | grep`, and no local `.env`/CI-secrets file exists in the repo to source them from). This is a **credential-resolution failure specific to this execution session**, not a "capability not enabled" error — it neither confirms nor contradicts the user's attestation that `setup_match` succeeded when *they* ran it (presumably in a shell session that does have those credentials configured, consistent with this project's existing CI). **Inconclusive, not negative.**

### Step 3 — Baseline build regression check

```
xcodebuild build -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'generic/platform=iOS Simulator'
```

**BUILD SUCCEEDED.** No hook blocked this invocation. Output showed the same two pre-existing, unrelated xcframework architecture-mismatch notes (`ExyteChat.xcframework`, `SwiftUICharts.xcframework` missing `x86_64`) already visible in 01-01's baseline — no new errors or warnings attributable to this checkpoint. Note this is the Debug/simulator/ad-hoc-signing baseline (matching 01-01's established command), not an actual `xcodebuild archive -configuration Release` invocation — the plan's own verification wording asks to re-run 01-01's baseline commands specifically, not a new archive build.

### Environment side effect (restored, not committed)

Running the build regenerated Swift package reference GUIDs inside `project.pbxproj` via this worktree's local `spm-cache` proxy resolution — the same class of harness artifact 01-01-SUMMARY.md documented for `Package.resolved` (item 2 in its Decisions Made). Restored via `git checkout -- StressMonitor/StressMonitor.xcodeproj/project.pbxproj` before this SUMMARY was committed; no commit in this plan carries that diff.

## Task Commits

This plan has no code-changing tasks — it is a single `checkpoint:human-action` gate. No task-level commit was made; only this SUMMARY + STATE metadata commit follows.

## Files Created/Modified

None (Apple Developer Portal + Fastlane Match git repo are external state, per this plan's own "Artifacts This Phase Produces" section: "None in-repo").

## Decisions Made

- **Did not attempt to source `MATCH_GIT_URL`/API key env vars from anywhere else in the repo.** No `.env` or CI-secrets file exists locally to source them from, and fabricating or guessing credential values is out of scope and unsafe — the correct behavior when credentials are absent is to report the gap, not work around it.
- **Restored the build's incidental `project.pbxproj` diff via `git checkout --` rather than committing it.** It is an unrelated environment artifact (package-reference GUID churn from the local spm-cache proxy), not a change this plan's task authorizes.

## Deviations from Plan

None — plan executed exactly as written. The one open item (inability to independently confirm Match state) is an inherent, previously-documented limitation of this task type (per the plan's own `user_setup` rationale: "no CLI/API credential is available to Claude for this"), not a deviation from what was asked.

## Issues Encountered

- **This execution environment lacks `MATCH_GIT_URL`/`APP_STORE_CONNECT_API_KEY_ID`/`APP_STORE_CONNECT_ISSUER_ID`**, so even the plan's suggested "closest available proxy" verification (`match appstore --readonly`) could not run to completion here. Logged to `.planning/WINDOWS.md` as an unrun-verify.

## Known Stubs

None — this plan touches no application code.

## Threat Flags

None — matches the plan's own `<threat_model>` disposition (T-01-05, `accept`): no new credential exposure was introduced; this session held zero Match/ASC credentials throughout.

## User Setup Required

Already completed by the user prior to this session (attested via "approved" reply):
1. Apple Developer Portal: App Groups capability enabled on all three App IDs (`stress.ai.com`, `stress.ai.com.watchkitapp`, `stress.ai.com.widget`), `group.stress.ai.com` assigned to all three; iCloud/CloudKit enabled on `stress.ai.com` and `stress.ai.com.watchkitapp`.
2. `bundle exec fastlane setup_match` run from the repo root to regenerate App Store provisioning profiles.

**Recommended follow-up (not blocking this plan's completion, but noted for full closure):** the next time a shell session with the project's real Match/ASC credentials is available (e.g. local dev machine already configured for this project's existing CI, or the CI pipeline itself), run `bundle exec fastlane match appstore --readonly` to get a credentialed, machine-verifiable confirmation of D1/D2 above rather than relying on attestation alone.

## Next Phase Readiness

- BUILD-02's real-device acceptance criterion is now attested-complete: entitlement wiring (01-01, code-complete) + Developer Portal capability registration + Match profile regeneration (this plan, user-attested). Independent machine verification of the Portal/Match state is still pending a credentialed session — see recommended follow-up above.
- No blockers for 01-02/01-04 or Phase 2 — this plan changed no in-repo files.

---
*Phase: 01-build-configuration-widget-wiring*
*Completed: 2026-08-09*

## Self-Check: PASSED

- No files were created or modified by this plan's task — nothing to check for existence.
- No task-level commit hash to verify (checkpoint-only plan; this SUMMARY's own commit follows in the same execution step).

---
phase: 01-binary-manifest-truth
reviewed: 2026-09-03T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .gitignore
  - CLAUDE.md
  - docs-site/legal/privacy.md
  - docs-site/vi/legal/privacy.md
  - scripts/verify-archive-tests.sh
  - scripts/verify-archive.sh
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseAuth_shim/Firebase_FirebaseAuth_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/Firebase_proxy/Sources/Firebase_FirebaseCore_shim/Firebase_FirebaseCore_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Sources/GoogleSignIn-iOS_GoogleSignIn_shim/GoogleSignIn-iOS_GoogleSignIn_shim.swift
  - StressMonitor/spm-cache/packages/proxy/.proxies/GoogleSignIn-iOS_proxy/Sources/GoogleSignIn-iOS_GoogleSignInSwift_shim/GoogleSignIn-iOS_GoogleSignInSwift_shim.swift
  - StressMonitor/spm-cache/packages/proxy/Package.resolved
  - StressMonitor/spm-cache/packages/proxy/Package.swift
  - StressMonitor/spm-cache/packages/proxy/src/root/spm_cache_root.swift
  - StressMonitor/StressMonitor.xcodeproj/project.pbxproj
  - StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift
  - "StressMonitor/StressMonitorWatch Watch App/PrivacyInfo.xcprivacy"
  - StressMonitor/StressMonitorWidget/README.md
findings:
  critical: 1
  warning: 4
  info: 7
  total: 12
status: findings
---

# Phase 1: Code Review Report — Binary & Manifest Truth

**Reviewed:** 2026-09-03
**Depth:** standard
**Files Reviewed:** 20 (diff base `3e4233b`)
**Status:** findings

## Summary

Build-configuration phase: `verify-archive.sh` artifact gate + bidirectional test harness, SPM local-proxy migration (Firebase/GoogleSignIn exact-revision pins replacing floating `upToNextMajorVersion` refs), pbxproj cleanup (Giphy script phase removal, STOREKIT build-settings → Info.plist, proxy package reference), watch privacy-manifest reason code, doc-truth corrections (CLAUDE.md, EN/VI privacy), scoped `.gitignore` exception, and plist-presence gating for `FirebaseBootstrapTests`.

**What held up under adversarial checking (verified, not assumed):**

- **Supply-chain pinning is sound.** Both proxy `Package.swift` manifests pin exact upstream revisions (`firebase-ios-sdk@fdc352f…`, `GoogleSignIn-iOS@08d8dce…`, no floating requirements); both `Package.resolved` files (proxy + workspace) carry identical pin sets; `git ls-files` confirms the `.gitignore` exception chain tracks exactly the 9 proxy source files and nothing else. Shim sources are 2-line `@_exported import` re-exports — no injected code, no secrets.
- **Doc-vs-payload truth claim is true.** `StressContextPayload.build()` (Services/LLM/StressContextPayload.swift:124-146) sets `hrv`, `heartRate`, `baselineHRV/HR`, `sleepHours`, `activeMinutes`, `recoveryScore` all to `nil`; only score/category/confidence/trends/factor-breakdown are sent. The EN/VI policy and CLAUDE.md wording matches the code.
- **STOREKIT merge keys survive.** The six `INFOPLIST_KEY_STOREKIT_*` build settings removed from the pbxproj are present in `StressMonitor/StressMonitor/Info.plist` (lines 18-28), so verify-archive.sh check 2 remains satisfiable. Golden-archive layout (`Watch/StressMonitorWatch Watch App.app`, `Firebase_FirebaseCore.bundle`, appex naming) matches every hardcoded path in the script.
- **Test gating design is correct.** `FirebaseBootstrapTests` gates on actual plist presence in the test host (not env vars), which is more robust than `GSD_CI` gating; `repeatBootstrapIsIdempotent` holds under both `.configured` and `.missingConfiguration`.

**Key concerns:** the artifact gate's CFBundleURLSchemes check is provably vacuous (CR-01); the test harness hard-depends on a gitignored local-only golden archive with no guard (WR-01); the pbxproj migration left 9 orphaned no-op build-file entries in the app's Frameworks phase (WR-02); and the public privacy policies omit collection types the app's own privacy manifest declares (WR-04).

## Critical Issues

### CR-01: CFBundleURLSchemes "has at least one entry" check is vacuous — passes on an empty array

**File:** `scripts/verify-archive.sh:200-204`
**Issue:** The check runs `grep -A2 '"CFBundleURLSchemes"' <<<"$APP_PLIST_DUMP" | grep -q '"'`. The first grep's output **always includes the matching key line itself**, and that line contains quotes around `"CFBundleURLSchemes"`. So `grep -q '"'` succeeds whenever the key merely exists — even with an empty array. Empirically confirmed during this review:

```console
$ dump='"CFBundleURLSchemes" => []'
$ grep -A2 '"CFBundleURLSchemes"' <<<"$dump" | grep -q '"' && echo PASSES
PASSES
```

The only failure mode the check can detect is the key being entirely absent. A regression that empties the URL-schemes array (breaking the GoogleSignIn callback that check's message claims to verify — `com.googleusercontent.apps.*`) sails through the gate green. This is exactly the class of silent manifest regression this phase exists to catch, so the gate delivers false assurance on one of its five checks.

**Fix:** Exclude the key line before testing for an entry, or extract the array directly:

```bash
# Option A: skip the matched key line, require a quoted element within the array
if grep -A3 '"CFBundleURLSchemes"' <<<"$APP_PLIST_DUMP" | tail -n +2 | grep -q '"[^\"]' \
    && ! grep -A2 '"CFBundleURLSchemes"' <<<"$APP_PLIST_DUMP" | grep -qE '=> *\[\]'; then
    note_pass "MERGED PLISTS" "CFBundleURLSchemes has at least one entry (GoogleSignIn callback)"
else
    note_fail "MERGED PLISTS" "CFBundleURLSchemes missing or empty in app Info.plist"
fi

# Option B (stronger): extract via plutil and require a non-empty JSON array
url_schemes=$(plutil -extract CFBundleURLSchemes json -o - -- "$APP_PLIST" 2>/dev/null || true)
if [ -n "$url_schemes" ] && [ "$url_schemes" != "[]" ] && [ "$url_schemes" != "[ ]" ]; then ...
```

Add a red-direction case to `verify-archive-tests.sh` that plants `plist` with `"CFBundleURLSchemes" => []` and asserts the check fails.

## Warnings

### WR-01: Test harness hard-depends on a gitignored, local-only golden archive with no existence guard; "Works … in CI" claim is unwired

**File:** `scripts/verify-archive-tests.sh:13-17` (paths), `:32-64` (unguarded use)
**Issue:** `GOLDEN="$REPO_ROOT/.asc/artifacts/StressMonitor.xcarchive"` is matched by `.gitignore:96/148` (`*.xcarchive`), so it exists only on machines where someone preserved it manually (present locally today; absent on any clean checkout including CI runners). The script uses `set -uo pipefail` **without** `-e` and has no existence guard: when `$GOLDEN` is missing, Test 1's `bash "$VERIFY" "$GOLDEN"` exits 2, Test 2's `cp` fails, `stat -f%z` leaves `TSIZE` empty, `dd` seek-evaluates to 0 against a nonexistent file, `grep -c` yields an empty `planted_count` making `[ "" -ge 1 ]` throw "integer expression expected" — all three tests FAIL with cascading noise instead of a clean skip. Meanwhile `.github/` contains **zero** references to `verify-archive` (neither script runs in CI), so the header claim "Works locally and in CI" (line 2) is currently false in both directions.
**Fix:** Guard at the top and exit with an explicit skip code:

```bash
if [ ! -d "$GOLDEN" ]; then
    echo "SKIP: golden archive not present ($GOLDEN) — gate tests require the preserved build-13 artifact"
    exit 0   # or 77 if the caller distinguishes skip from pass
fi
```

Either wire the harness into CI with an artifact-provisioning step or change the header to "works locally; requires the preserved golden archive (see WR-01/CR-01)".

### WR-02: pbxproj migration orphans 9 no-op PBXBuildFile entries; proxied products have no Frameworks-phase linkage

**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj:51-60` (entries), `:245-253` (app Frameworks phase)
**Issue:** The migration replaced the three `FB1A…02/03/06` product dependencies with proxied ones (`C24A…`/`F125…`/`7B5D…` in `packageProductDependencies`) but **stripped the `productRef` from `FB1A…04/05/07` and left them in the Frameworks phase**. Result: nine `PBXBuildFile` objects with neither `fileRef` nor `productRef` (six pre-existing `(null)` orphans whose comments this phase renamed to `BuildFile`, plus the three newly orphaned), and no `PBXBuildFile` anywhere carries `productRef` to the new proxied dependencies (verified by grep — zero matches). Linking now relies purely on Xcode's implicit linking of `packageProductDependencies`. It builds today, but: (a) a phase whose stated goal was removing dead build settings added/kept dead entries; (b) Xcode's next UI edit of that target will rewrite/repair these rows, generating unreviewable pbxproj churn and potentially re-materializing linkage in surprising form.
**Fix:** Delete the 9 orphan `PBXBuildFile` definitions (lines 51-60, skipping the two real entries in between if any) and their 9 references in the app Frameworks `files` list (lines 245-253), letting `packageProductDependencies` be the single source of linkage truth — or re-add proper `productRef` build files for the three proxied products to restore the explicit pattern used before the migration.

### WR-03: Test/bootstrap failure messages instruct running a script that does not exist (`ci_scripts/provision_firebase_config.sh`)

**File:** `StressMonitor/StressMonitorTests/FirebaseBootstrapTests.swift:35,49` (and mirrored log string in `Services/Firebase/FirebaseBootstrap.swift:40`)
**Issue:** Both `#expect` failure messages say "Restore it locally or run ci_scripts/provision_firebase_config.sh." That path does not exist anywhere in the repo — `ci_scripts/` contains only `ci_post_clone.sh` and `ci_post_xcodebuild.sh`, and `scripts/` has no equivalent (scoped searches returned nothing). The suite doc comment doubles down ("a future CI that runs the provisioning script"). An operator hitting this failure on a fresh checkout follows a dead pointer; the AUTH-01 remediation path is effectively undocumented.
**Fix:** Either commit the provisioning script (fetching `GoogleService-Info.plist` from a secure store keyed to `$(FIREBASE_CONFIG_*)` secrets) or change both messages to the real recovery path, e.g. "copy the per-app GoogleService-Info.plist from the secure release store into StressMonitor/StressMonitor/ (gitignored by design)". Keep test and runtime messages in sync.

### WR-04: Public privacy policies omit collection types the app's own privacy manifest declares (PhotoVideo, OtherUserContent, DeviceID, ProductInteraction)

**File:** `docs-site/legal/privacy.md:9-30` and `docs-site/vi/legal/privacy.md:9-30`
**Issue:** The phase verified the AI-chat derived-payload wording (correct — see Summary), but the surrounding "Data We Access" section lists only HRV, resting heart rate, and stress scores. The app's `PrivacyInfo.xcprivacy` declares **five** collected data types: `NSPrivacyCollectedDataTypeHealthAndFitness`, **`PhotoVideo`**, **`OtherUserContent`**, **`DeviceID`**, **`ProductInteraction`** (the latter two acknowledged in CLAUDE.md:493 as existing "solely because of the Google/Firebase auth SDKs"). The policy's blanket "No third-party analytics or advertising trackers" line plus a chat section that only names Firebase for the *chat session* leaves undisclosed: photos/videos shared in chat (the app's own `NSCameraUsageDescription` promises camera capture for chat), other user content, and device/app identifiers transmitted to Google on every Firebase Auth sign-in — independent of chat usage. For a doc-truth phase whose deliverables are these two files, the public policy and the App Store privacy manifest now disagree in both directions (policy silent on four declared types).
**Fix:** Extend "Data We Access" in both locales with: photos/videos you choose to share in AI Coaching Chat; chat message content; device/app identifiers shared with Google (Firebase Auth / Google Sign-In) strictly for authentication and app functionality, not tracking. Mirror the wording in the VI file. (App Store review cross-checks the nutrition label against the policy; the current gap is a rejection/accuracy risk.)

## Info

### IN-01: Credential-scan pattern set misses common token shapes (AWS, GitHub, Slack)

**File:** `scripts/verify-archive.sh:29`
**Issue:** AUTH-01 pattern set covers PEM/sk-/anon-key/api-secret/Bearer/Supabase/JWT but not `AKIA[0-9A-Z]{16}` (AWS access keys), `gh[pousr]_[A-Za-z0-9]{20,}` / `github_pat_` (GitHub), or `xox[baprs]-` (Slack) — all realistic accident classes for a backend-coupled app.
**Fix:** Append `|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}` to `SCAN_PATTERNS` (and corresponding name-detection branches in `scan_binary`).

### IN-02: Allowlist permanently masks the `supabase*` literals the source no longer contains

**File:** `scripts/verify-archive.sh:35-43`
**Issue:** The comment states the `supabaseAccessToken`/`RefreshToken`/`SessionExpiresAt`/`ChatSessionId` literals were "REMOVED by FirebaseAuthService.swift" — grep confirms zero `supabase` matches under current API/Firebase services. Allowlisting strings absent from current source means the scan cannot detect their reintroduction (e.g. a reverted migration re-embedding legacy keychain names would pass green).
**Fix:** Add a removal trigger to the triage comment (drop the entry when a golden archive rebuilt from current source no longer produces the hit), or scope allowlist subtraction to golden-archive baselines only.

### IN-03: Stale comment references the removed `INFOPLIST_KEY_STOREKIT_*` merge mechanism

**File:** `scripts/verify-archive.sh:15-16`
**Issue:** "Merged-plist keys that must survive the INFOPLIST_KEY_STOREKIT_* merge" — those build settings were deleted from the pbxproj in this same phase; the keys now ship via `StressMonitor/Info.plist` merged with the generated plist. The comment describes a mechanism that no longer exists, misdirecting future debugging.
**Fix:** Reword to "Merged-plist keys that must survive the generated-Info.plist merge (sourced from StressMonitor/Info.plist since the build-settings form was removed; consumed by StoreKitProductCatalog.swift's 3-tier resolution)."

### IN-04: Widget README corrections stopped at the app-group rename; remaining truth gaps contradict the phase's own gate

**File:** `StressMonitor/StressMonitorWidget/README.md:5,79-83,114-137`
**Issue:** Phase edit fixed only `group.com.stressmonitor.app` → `group.stress.ai.com`. Still stale: "Name: `StressMonitorWidget`" and binary framing (actual target/binary is `StressMonitorWidgetExtension` — the very name the new verify-archive gate hardcodes); "Set minimum deployment to iOS 17.0" / "iOS 17+" (actual `IPHONEOS_DEPLOYMENT_TARGET = 18.6`); and the `handleDeepLink(_:)` integration snippet — the iOS app target contains no `onOpenURL` handler (verified by grep; only watch complications construct `stressmonitor://` URLs).
**Fix:** Update target name and deployment target; replace the deep-link snippet with a note that watch complications open the app via `stressmonitor://` URLs and routing is not yet implemented in the host app.

### IN-05: CLAUDE.md doc-truth pass left internal contradictions

**File:** `CLAUDE.md:207,480`
**Issue:** The phase corrected the Supabase→StressAPIClient/Firebase narrative, but the same file still states "Dependencies | None (system only) | Privacy-first, no bloat" (contradicts the SPM Firebase/GoogleSignIn proxy this phase just migrated, and contradicts line 481's own AI-Chat row) and "iOS 17+ / watchOS 10+" in the architecture header (actual iOS 18.6 / watchOS 11.6 per pbxproj). Related out-of-scope note for the orchestrator: root `AGENTS.md` still claims "GoogleService-Info.plist is committed" while this phase's `.gitignore:195` ignores it.
**Fix:** Update the Dependencies row to "SPM via local proxy: firebase-ios-sdk (Auth/Core), GoogleSignIn-iOS — exact-revision pinned" and the deployment-target header; fix the AGENTS.md sentence separately.

### IN-06: Non-canonical pbxproj re-serialization invites wholesale Xcode rewrite churn; proxy root source file is 0 bytes

**File:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj:652-1001`; `StressMonitor/spm-cache/packages/proxy/src/root/spm_cache_root.swift`
**Issue:** The rewritten `XCBuildConfiguration` blocks use quoted keys, different sort order, and `isa`/`name` moved after `buildSettings`, plus empty `exceptions = ();` additions to synchronized groups — all valid OpenStep plist (parses fine; values verified equivalent apart from the intended changes), but not what Xcode emits. The next GUI edit of these targets will reformat wholesale, burying real changes in hundreds of noise lines. Separately, the tracked `spm_cache_root.swift` is an empty file (0 bytes) — legal for satisfying SPM's one-source-file minimum, but a one-line comment would prevent future "accidentally truncated?" churn.
**Fix:** Acceptable to leave; if the file is touched again, let Xcode re-emit the canonical formatting in a dedicated no-op change commit. Add `// Placeholder root target required by the spm_cache_proxy product.` to the empty file.

### IN-07: Only the two direct dependencies are revision-pinned; 15 transitive pins float on re-resolution

**File:** `StressMonitor/spm-cache/packages/proxy/Package.resolved:74-82` (GoogleUtilities moved 8.1.2 → 8.1.3 in this diff); workspace `Package.resolved` identical
**Issue:** The proxy manifests exactly pin `firebase-ios-sdk` and `googlesignin-ios`, but transitive dependencies (GoogleUtilities, GoogleDataTransport, app-check, …) resolve to version-range heads at resolve time — this diff already shows GoogleUtilities silently advancing 8.1.2→8.1.3. Committed lockfiles make drift reviewable, but nothing flags a transitive bump riding along inside a larger diff.
**Fix:** Consider a verify-archive/test check that diffs `Package.resolved` against the previous commit (`git diff --name-only` + pin comparison) and prints changed transitive pins, so supply-chain movement is impossible to miss.

---

_Reviewed: 2026-09-03_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

---
phase: 01-binary-manifest-truth
plan: 03
subsystem: infra
tags: [xcode, pbxproj, info-plist, build-settings, storekit, widgetkit, giphy]

requires:
  - phase: 01-01
    provides: SPM-proxy migration proven archive-from-working-tree; scripts/verify-archive.sh merged-plist contract (check 2)
provides:
  - Single-source resolution for the six STOREKIT_* product keys (app Info.plist file is the sole live source; dead pbxproj duplicates deleted)
  - Empirical proof that custom INFOPLIST_KEY_* settings never merge on this toolchain (closed documented key set) — governs all future BUILD-03-style work
  - Widget Info.plist delete-or-verify outcome recorded: file RETAINED (NSExtensionPointIdentifier is not auto-injected)
  - Zero media-dependency build residue (Giphy dSYM stub script phase gone; zero live references in all four real targets)
affects: [01-04 archive/entitlements verification, 01-05 BUILD-01 ASC upload validation, BUILD-04 follow-up on UIBackgroundModes, SHIP-02/03]

actuals:
  tokens: 1700
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Empirical merged-product-plist proof BEFORE deleting any plist key (delete-or-verify, extended from widget to app keys)"
    - "INFOPLIST_KEY_* merging has a closed documented key set — arbitrary custom prefixes are dead settings; never assume they contribute"

key-files:
  created:
    - .planning/phases/01-binary-manifest-truth/deferred-items.md
  modified:
    - StressMonitor/StressMonitor.xcodeproj/project.pbxproj

key-decisions:
  - "BUILD-03 direction inverted on empirical evidence: the six STOREKIT keys' single source is the app Info.plist FILE (custom INFOPLIST_KEY_* never merge); the dead build settings were deleted instead of the file-side copies"
  - "Widget Info.plist retained as the one-key NSExtension file — the delete branch was disproven by a fresh product build (auto-injection does not happen for this target)"
  - "BUILD-01 left unchecked: this plan only landed its media-residue portion; the ASC-upload validation proof belongs to 01-05 (which also declares BUILD-01)"

patterns-established:
  - "Delete-or-verify with retained-file fallback: any plist-key consolidation must first prove the merged product plist still resolves the key, on a completed build — never inspect partial/in-flight state"
  - "Golden-archive key-set diff (build-13) as the no-lost-keys regression reference for merged plists"

requirements-completed: [BUILD-03]

coverage:
  - id: D1
    description: "Single-source truth for the six STOREKIT_* keys — dead INFOPLIST_KEY_STOREKIT_* build settings removed (Debug+Release); app Info.plist file is the sole live source; merged product plist re-proven"
    requirement: BUILD-03
    verification:
      - kind: other
        ref: "plutil -extract on built app Info.plist: all six keys byte-equal (credits.large/small, premium.annual/monthly/weekly, group 22353146)"
        status: pass
      - kind: other
        ref: "key-set diff of merged app plist vs build-13 golden (.asc/artifacts) — no lost keys (only delta: toolchain-injected UIRequiredDeviceCapabilities=arm64 in the Release golden)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Widget plist delete-or-verify outcome recorded: RETAINED one-key file; NSExtensionPointIdentifier proven present in the built .appex product"
    requirement: BUILD-03
    verification:
      - kind: other
        ref: "plutil -extract NSExtension.NSExtensionPointIdentifier raw on built StressMonitorWidgetExtension.appex/Info.plist = com.apple.widgetkit-extension"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dead Giphy dSYM stub script phase fully removed (definition + reference + section markers); zero live Giphy/Kingfisher/exyte/MediaPicker references; builds green"
    requirement: BUILD-01
    verification:
      - kind: other
        ref: "grep -c 'F2A1B0012AAA000100DE6E8F\\|Giphy' project.pbxproj = 0; media-SDK grep across 4 real target dirs = 0 lines; xcodebuild app+widget schemes BUILD SUCCEEDED; xcodebuild -list parses 4 targets"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-09-03
status: complete
---

# Phase 1 Plan 3: Binary & Manifest Truth — plist consolidation + media-residue removal Summary

**Dead build machinery removed and plist key resolution collapsed to single sources: the six STOREKIT keys now live only in the app Info.plist file (the pbxproj INFOPLIST_KEY_STOREKIT_* duplicates were proven never to merge and deleted), the widget plist survived its delete-or-verify gate, and the Giphy dSYM stub script phase is gone**

## Performance

- **Duration:** 22 min
- **Started:** 2026-09-03T08:30:27Z
- **Completed:** 2026-09-03T08:51:58Z
- **Tasks:** 2
- **Files modified:** 1 production file (project.pbxproj, −35 lines); 1 planning artifact

## Accomplishments

- Removed the 12 `INFOPLIST_KEY_STOREKIT_*` build settings (Debug + Release) after empirically proving they never contributed to any merged product plist — the app Info.plist file is now the single source for the six product-ID keys (BUILD-03's no-overlap goal, achieved from the opposite direction than planned)
- Ran the widget delete-or-verify experiment to completion: deleted the widget plist + `INFOPLIST_FILE` settings, built fresh, found `NSExtensionPointIdentifier` MISSING from the product `.appex` (assumption A2 false), restored the one-key file per the plan's fallback — retained-file end-state, key re-proven present
- Deleted the dead "Generate Giphy dSYM Stub" PBXShellScriptBuildPhase (definition + app-target buildPhases reference + now-empty section markers) — zero Giphy/Kingfisher/exyte/MediaPicker references remain in any real target; StoreKit config carries only `com.stressmonitor.app.*` product IDs
- All verification green: six plutil key extracts byte-equal, GoogleSignIn URL scheme present, key-set diff vs build-13 golden shows no lost keys, both schemes BUILD SUCCEEDED, project parses

## Task Commits

Each task was committed atomically:

1. **Task 1: App plist consolidation + widget delete-or-verify, proven on merged product plists** - `388efe5` (chore)
2. **Task 2: Remove dead Giphy dSYM stub script phase, re-verify zero live media-dep references** - `4098d8b` (chore)

## Files Created/Modified

- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` - 12 dead `INFOPLIST_KEY_STOREKIT_*` settings removed (Task 1); 23-line dead script phase removed (Task 2)
- `StressMonitor/StressMonitor/Info.plist` - **net zero** (reduced to CFBundleURLTypes-only, then restored after the deviation below — committed state identical to HEAD~)
- `StressMonitor/StressMonitorWidget/Info.plist` - **net zero** (deleted, empirically disproven, restored — retained-file branch)
- `.planning/phases/01-binary-manifest-truth/deferred-items.md` - logged the out-of-scope UIBackgroundModes discovery

## Decisions Made

- **BUILD-03 inversion (evidence-driven):** the plan assumed the `INFOPLIST_KEY_STOREKIT_*` build settings were the live source and the file copies were the drift risk. Empirically false: Xcode merges only the documented, closed set of `INFOPLIST_KEY_*` settings (usage strings, orientations, launch screen, etc. all merge fine — verified present), while custom prefixes are ignored. The file was the sole live source all along (the golden build-13 archive proves it — its six keys came from the file). Deleting the dead pbxproj side achieves the same single-source, no-drift end-state the plan wanted.
- **Widget plist retained** (plan-encoded fallback): auto-injection disproven on a fresh build — without the file, the merged `.appex` plist lacks `NSExtensionPointIdentifier` and iOS would refuse to load the extension (T-03-02). The one-key file stays; this is an acceptable end-state per the plan's own Pitfall 3 branch.
- **BUILD-01 not marked complete:** this plan only landed BUILD-01's media-residue portion. The requirement's actual proof (ASC upload validation) belongs to 01-05, which also declares BUILD-01 — the shared-ID gate blocks it regardless.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] App plist reduction inverted: file restored, dead build settings deleted instead**
- **Found during:** Task 1 (merged-plist proof step — the plan's own `<automated>` verify failed its first assertion)
- **Issue:** Executing the planned file-side deletion made the merged product plist lose all six `STOREKIT_*` keys (`plutil -extract STOREKIT_CREDITS_LARGE_PRODUCT_ID` → "No value at that key path"). Root cause: the plan's premise that `INFOPLIST_KEY_STOREKIT_*` build settings contribute to the merged plist is false on Xcode 26.3 — the `INFOPLIST_KEY_*` merge mechanism has a closed, documented key set; custom prefixes are inert. The plan's own drift observation ("duplicated byte-identically") was the file being the only real source, with the settings as dead look-alikes.
- **Fix:** Restored the six keys in `StressMonitor/StressMonitor/Info.plist` (back to `CFBundleURLTypes` + six keys), then deleted the 12 dead `INFOPLIST_KEY_STOREKIT_*` lines from both pbxproj config blocks — eliminating the true duplicate side. This satisfies the plan's hard must-have (merged plist resolves all six keys byte-equal) and its no-overlap principle ("keys with no build-setting equivalent live only in the plist file" — which, empirically, includes these six).
- **Files modified:** `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (net; the plist file returned to its committed state)
- **Verification:** all six `plutil -extract` assertions pass with values byte-equal to the pbxproj strings transcribed before deletion; URL scheme present; key-set diff vs build-13 golden = no lost keys; app + widget scheme builds green
- **Committed in:** 388efe5 (Task 1 commit)

**2. [Rule 1 - Bug] Widget plist deletion rolled back via the plan's encoded fallback**
- **Found during:** Task 1 (empirical check, step 2)
- **Issue:** With the widget plist deleted and `INFOPLIST_FILE` removed, a fresh `StressMonitorWidgetExtension` build produced an `.appex` Info.plist with NO `NSExtension` key — assumption A2 (auto-injection) is false for this target shape.
- **Fix:** `git checkout` restored the one-key plist and both `INFOPLIST_FILE` settings; rebuild re-proved `NSExtensionPointIdentifier = com.apple.widgetkit-extension` in the product. Recorded branch: **retained file** (this is the plan's own acceptable outcome, not a scope change).
- **Files modified:** none (net)
- **Verification:** plutil extract on rebuilt `.appex` = `com.apple.widgetkit-extension`
- **Committed in:** folded into Task 1's evidence; net-zero diff

---

**Total deviations:** 2 auto-fixed (2× Rule 1)
**Impact on plan:** Task 1's literal acceptance criterion #1 ("source plist has exactly one top-level key") is unmet-as-written because it is empirically unachievable without breaking runtime key resolution — replaced by the inverted single-source outcome, which meets the criterion's intent and all other criteria. No scope creep; production delta is 35 deleted lines.

## Issues Encountered

- **Out-of-scope discovery logged:** `INFOPLIST_KEY_UIBackgroundModes = "fetch processing"` (app Debug+Release) also never merges — the key is absent from the shipped build-13 archive plist too, i.e. background fetch/processing has been silently absent from every shipped binary. Pre-existing (identical before/after this plan); not caused by and not fixed here. Recorded in `deferred-items.md` for BUILD-04/submission-hardening follow-up.
- **Windows ledger append skipped deliberately:** `.planning/WINDOWS.md` carries pre-existing uncommitted edits from another session in the working tree; appending + staging it would entangle those changes. The deviation above is fully recorded here, in `deferred-items.md`, and in STATE.md decisions instead.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 01-04 (BUILD-02 entitlements/AUTH-01/WIRE-01): app + widget schemes build green post-edits; merged-plist contract intact (verify-archive.sh check 2 semantics unchanged and meaningful)
- BUILD-03 traceability note for the phase verifier: requirement satisfied as "every key has exactly one home" (documented inversion above), not as "plist = CFBundleURLTypes only"
- BUILD-01 remains open pending 01-05's ASC upload validation

## Self-Check: PASSED

- Commits `388efe5` and `4098d8b` exist on `gsd/v1.2-submission-readiness` (verified via `git log`)
- `.planning/phases/01-binary-manifest-truth/deferred-items.md` exists on disk
- Re-ran consolidated verification post-both-commits: six STOREKIT extracts + URL scheme + zero-Giphy grep + build green (all logged above)

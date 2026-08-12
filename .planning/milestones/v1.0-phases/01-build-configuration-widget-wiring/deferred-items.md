# Deferred Items — Phase 01-01

Out-of-scope discoveries logged during 01-01-PLAN.md execution. Not fixed here per the
scope-boundary rule (only auto-fix issues directly caused by this plan's own changes).

## 1. Worktree missing the gitignored `spm-cache/` local build cache

**Discovered during:** Task 1 (baseline build/test establishment)

`StressMonitor/spm-cache/` (and `spm-cache.lock`) are gitignored (`.gitignore:167-169`) —
regenerated-locally build artifacts, not tracked in git. The main repo checkout at
`/Users/ddphuong/Projects/next-labs/stress-ai/ios-stress-app/StressMonitor/spm-cache/` already
had these regenerated from a prior manual session; this worktree, being a fresh git
worktree checkout, did not. Without it, `xcodebuild` cannot resolve the
`XCLocalSwiftPackageReference "proxy"` package (`relativePath = "spm-cache/packages/proxy"`)
and every build/test command fails at package-graph resolution before reaching any of this
plan's own code.

**Resolution applied (environment-only, not committed):** copied the `spm-cache/` directory
from the main repo checkout into this worktree so `xcodebuild` could resolve packages and
this plan's `<verify>` steps could actually run. This is a local build-cache copy, not a git
change — `git status` confirms `spm-cache/` never appears as tracked or untracked (it's
gitignored), so no commit carries this.

**Not fixed:** the underlying worktree-provisioning gap (parallel GSD executor worktrees
don't inherit gitignored local caches from the main checkout) is a harness/environment
concern, not a Phase 1 code fix. Future worktree-based phases touching this project will hit
the same gap until either (a) `spm-cache` regeneration is added to worktree setup, or (b) the
gitignored cache is made shareable across worktrees (e.g. via a shared cache directory
outside the per-worktree checkout).

## 2. `xcodebuild`/spm-cache tooling deletes the checked-in `Package.resolved` on every build

**Discovered during:** Tasks 1–3 (every `xcodebuild build`/`test` invocation)

`StressMonitor/StressMonitor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
is tracked in git (not gitignored — see `.gitignore:88-93`'s `xcshareddata/` allow-list), but
every `xcodebuild build` or `xcodebuild test` invocation in this session deleted it from disk
as a side effect of resolving the package graph through the local `spm-cache` proxy
mechanism (branch `feature/spm-cache-integration`'s own tooling, unrelated to anything this
plan's tasks touch). Each time, it was restored via `git checkout --
.../Package.resolved` before staging/committing this plan's actual file changes, so none of
this plan's 3 commits carry the deletion.

**Not fixed:** this is a pre-existing behavior of the spm-cache local-proxy build integration
(most recently touched by `e3d8e2f fix(spm-cache): re-integrate proxy with correct product
references`), reproducible on a clean build in this environment, and out of this plan's file
scope (`files_modified` lists only `project.pbxproj`, the `.xcscheme`, three
`PrivacyInfo.xcprivacy` files, and the top-level `Info.plist`). Whoever next touches the
spm-cache integration should confirm whether this is expected (the proxy mechanism
regenerating its own lock state) or a real regression worth a `.gitignore` update.

## 3. `xcodebuild test -only-testing:StressMonitorTests` baseline — see WINDOWS.md

Tracked in the cross-phase defect register (`.planning/WINDOWS.md`, kind `unrun-verify`) —
3 consecutive attempts failed at the CoreSimulator device-pairing/socket layer (Mach error
-308, then twice "No matching device ... in XCTestDevices"), unrelated to this plan's
changes. See 01-01-SUMMARY.md's "Task 1 Baseline" section for full detail.

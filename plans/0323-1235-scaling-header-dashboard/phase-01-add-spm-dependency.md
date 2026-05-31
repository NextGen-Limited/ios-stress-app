# Phase 1: Add SPM Dependency

## Overview
- **Priority:** P1
- **Status:** Pending
- **Effort:** 30m

Add `exyte/ScalingHeaderScrollView` package via SPM to the Xcode project.

## Key Insights

- Project currently has zero external deps besides `AnimatedTabBar` (already from exyte)
- ScalingHeaderScrollView requires iOS 14+ (we target iOS 17+, no conflict)
- SPM, not CocoaPods (deprecated after v1.1.4)

## Requirements

- Package resolves and builds without conflicts
- Only `StressMonitor` target links the library (not widget, watch, or test targets)

## Related Code Files

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` | Modify | Add SPM package reference |

## Implementation Steps

1. Open Xcode project or use `xcodebuild` to add package
2. Add SPM dependency: `https://github.com/exyte/ScalingHeaderScrollView.git`
3. Link to `StressMonitor` target only
4. Verify clean build: `mcp__XcodeBuildMCP__build_sim` or xcodebuild
5. Verify `import ScalingHeaderScrollView` compiles in a test file

## Todo List

- [ ] Add ScalingHeaderScrollView SPM package
- [ ] Link to StressMonitor target
- [ ] Verify build succeeds

## Success Criteria

- `import ScalingHeaderScrollView` compiles
- No dependency conflicts with existing `AnimatedTabBar` package

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Version conflict with AnimatedTabBar | Low | Both from exyte, likely compatible |
| Package resolution timeout | Low | Pin to latest release tag |

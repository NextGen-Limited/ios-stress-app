# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Test Commands

Use the `xc-all` MCP tools for Xcode operations:

### Building

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__xcode_build
// Build iOS app (auto-detects destination)
mcp__plugin_xclaude-plugin_xc-all__xcode_build(scheme: "StressMonitor")

// Build with specific destination
mcp__plugin_xclaude-plugin_xc-all__xcode_build(
    scheme: "StressMonitor",
    destination: "platform=iOS Simulator,name=iPhone 15,OS=18.0"
)

// Build watchOS app
mcp__plugin_xclaude-plugin_xc-all__xcode_build(
    scheme: "StressMonitorWatch",
    destination: "platform=watchOS Simulator,name=Apple Watch Series 9"
)
```

### Testing

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__xcode_test
// Run all tests
mcp__plugin_xclaude-plugin_xc-all__xcode_test(
    scheme: "StressMonitor",
    destination: "platform=iOS Simulator,name=iPhone 15"
)

// Run single test class
mcp__plugin_xclaude-plugin_xc-all__xcode_test(
    scheme: "StressMonitor",
    destination: "platform=iOS Simulator,name=iPhone 15",
    only_testing: ["StressMonitorTests/StressCalculatorTests"]
)

// Run single test method
mcp__plugin_xclaude-plugin_xc-all__xcode_test(
    scheme: "StressMonitor",
    destination: "platform=iOS Simulator,name=iPhone 15",
    only_testing: ["StressMonitorTests/StressCalculatorTests/testNormalStress"]
)
```

### Cleaning Build Artifacts

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__xcode_clean
// Clean all
mcp__plugin_xclaude-plugin_xc-all__xcode_clean()

// Clean specific scheme
mcp__plugin_xclaude-plugin_xc-all__xcode_clean(scheme: "StressMonitor")
```

### Simulator Management

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_list
// List available simulators
mcp__plugin_xclaude-plugin_xc-all__simulator_list(
    device_type: "iPhone",
    availability: "available"
)

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_boot
// Boot a simulator
mcp__plugin_xclaude-plugin_xc-all__simulator_boot(device_id: "iPhone 15")

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_shutdown
// Shutdown simulator
mcp__plugin_xclaude-plugin_xc-all__simulator_shutdown(device_id: "booted")
```

### App Installation & Launch

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_install_app
// Install .app bundle
mcp__plugin_xclaude-plugin_xc-all__simulator_install_app(
    device_id: "booted",
    app_path: "/path/to/StressMonitor.app"
)

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_launch_app
// Launch app by bundle ID
mcp__plugin_xclaude-plugin_xc-all__simulator_launch_app(
    device_id: "booted",
    app_identifier: "com.stressmonitor.app"
)
```

### UI Interaction & Testing

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__idb_describe
// Query accessibility tree
mcp__plugin_xclaude-plugin_xc-all__idb_describe(operation: "all")

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__idb_find_element
// Find UI element by label
mcp__plugin_xclaude-plugin_xc-all__idb_find_element(query: "Stress Level")

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__idb_tap
// Tap at coordinates
mcp__plugin_xclaude-plugin_xc-all__idb_tap(x: 200, y: 400)

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__idb_input
// Type text or press keys
mcp__plugin_xclaude-plugin_xc-all__idb_input(text: "test input")
mcp__plugin_xclaude-plugin_xc-all__idb_input(key: "return")
```

### Screenshots

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_screenshot
// Capture screenshot (auto-generated path)
mcp__plugin_xclaude-plugin_xc-all__simulator_screenshot(device_id: "booted")

// With custom output path
mcp__plugin_xclaude-plugin_xc-all__simulator_screenshot(
    device_id: "booted",
    output_path: "/Users/ddphuong/Downloads/screenshot.png"
)
```

### Xcode Info

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__xcode_version
// Get Xcode version
mcp__plugin_xclaude-plugin_xc-all__xcode_version()

// Check specific SDK
mcp__plugin_xclaude-plugin_xc-all__xcode_version(sdk: "iphoneos")

// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__xcode_list
// List schemes and targets
mcp__plugin_xclaude-plugin_xc-all__xcode_list()
```

### Environment Health Check

```swift
// MCP Tool: mcp__plugin_xclaude-plugin_xc-all__simulator_health_check
// Validate iOS dev environment
mcp__plugin_xclaude-plugin_xc-all__simulator_health_check()
```

---

### Demo Mode (Simulator Testing)

To test with simulated HealthKit data on simulator:

1. **Xcode** → Product → Scheme → Edit Scheme
2. **Run** → Arguments → Arguments Passed on Launch
3. Add `-demo-mode` (checkbox enabled)
4. Build and run on simulator

**What demo mode provides:**

| Feature | Behavior |
|---------|----------|
| 5-Factor Data | Dynamic HRV, HR, Sleep, Activity, Recovery cycling through all stress levels |
| Scenario Cycling | Relaxed → Mild → Moderate → High → Edge (30s each) |
| Live HR Updates | AsyncStream emits every 3-5 seconds |
| Historical Data | 7-14 days with circadian variation |
| Edge Cases | Low HRV (<20ms), extreme HR (100-115), missing factors, partial recovery |
| Real Pipeline | Uses actual `MultiFactorStressCalculator` + SwiftData (not static mocks) |
| Graceful Degradation | Edge scenario omits sleep/activity/recovery to test weight redistribution |

**Files:**
- `Services/HealthKit/SimulatorHealthKitService.swift` — dynamic data generator
- `Views/Components/DemoModeBannerView.swift` — "DEMO MODE" pill overlay
- `DemoMode.isEnabled` in `StressMonitorApp.swift` — launch argument check

---

## MCP Plugin Categories

- **xc-setup**: Simulator and environment setup (`simulator_boot`, `simulator_create`, `simulator_list`, `xcode_version`)
- **xc-build**: Build operations (`xcode_build`, `xcode_clean`, `xcode_list`)
- **xc-launch**: App lifecycle (`simulator_install_app`, `simulator_launch_app`)
- **xc-interact**: UI automation (`idb_tap`, `idb_input`, `idb_find_element`, `idb_gesture`)
- **xc-testing**: Test execution (`xcode_test`, `idb_describe`, `simulator_screenshot`)
- **xc-meta**: Management operations (`simulator_shutdown`, `simulator_delete`, `xcode_version`)

---

---

## Architecture Overview

This is an **iOS 17+ / watchOS 10+ stress monitoring app** using MVVM with SwiftUI. The app tracks stress via Heart Rate Variability (HRV) from HealthKit.

### Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI (no UIKit)
- **Persistence**: SwiftData (iOS 17+ native)
- **Health Data**: HealthKit
- **Cloud Sync**: CloudKit
- **Dependencies**: None - system frameworks only

### Data Flow

```
HealthKit (System) → HealthKitService → StressCalculator → StressRepository → SwiftData
                                      ↓
                               StressViewModel
                                      ↓
                                  SwiftUI Views
```

---

## Core Algorithm

The stress algorithm combines HRV (70% weight) and heart rate (30% weight):

```
Normalized HRV = (Baseline - HRV) / Baseline
Normalized HR = (HR - Resting HR) / Resting HR

HRV Component = Normalized HRV ^ 0.8
HR Component = atan(Normalized HR * 2) / (π/2)

Stress Level = (HRV Component * 0.7) + (HR Component * 0.3)
```

**Stress Categories** (0-100 scale):
- 0-25: Relaxed
- 25-50: Mild Stress
- 50-75: Moderate Stress
- 75-100: High Stress

**Confidence scoring** adjusts for:
- Low HRV readings (< 20ms)
- Extreme heart rates (< 40 or > 180 bpm)
- Sample count history

See `documentation/references/phase-3-core-algorithm.md` for full implementation.

---

## Key Service Protocols

### HealthKitServiceProtocol

```swift
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchLatestHRV() async throws -> HRVMeasurement?
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}
```

### StressAlgorithmServiceProtocol

```swift
protocol StressAlgorithmServiceProtocol {
    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult
    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double
}
```

### StressRepositoryProtocol

```swift
protocol StressRepositoryProtocol {
    func save(_ measurement: StressMeasurement) async throws
    func fetchRecent(limit: Int) async throws -> [StressMeasurement]
    func getBaseline() async throws -> PersonalBaseline
}
```

---

## Project Structure

```
StressMonitor/
├── App/
│   └── StressMonitorApp.swift
├── Models/
│   ├── HRVMeasurement.swift
│   ├── HeartRateSample.swift
│   └── StressMeasurement.swift
├── ViewModels/
│   └── StressViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── DashboardView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   └── Components/
│       └── StressRingView.swift
└── Services/
    ├── HealthKit/
    │   └── HealthKitManager.swift
    ├── Algorithm/
    │   ├── StressCalculator.swift
    │   └── BaselineCalculator.swift
    └── Repository/
        └── StressRepository.swift
```

---

## Code Style

### Imports
Group system frameworks alphabetically:
```swift
import Foundation
import HealthKit
import Observation
import SwiftData
import SwiftUI
```

### State Management
Use `@Observable` macro (iOS 17+) for ViewModels:
```swift
@Observable
class StressViewModel {
    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?
}
```

### Dependency Injection
Protocol-based with constructor injection:
```swift
class StressViewModel {
    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol

    init(healthKit: HealthKitServiceProtocol = DefaultHealthKitService(),
         algorithm: StressAlgorithmServiceProtocol = StressCalculator()) {
        self.healthKit = healthKit
        self.algorithm = algorithm
    }
}
```

### Async/Await
Prefer `async`/`await` over callbacks. Use `.task {}` for async work in views:
```swift
func fetchAndCalculate() async {
    isLoading = true
    defer { isLoading = false }

    do {
        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 10)
        let (hrvData, hrData) = try await (hrv, hr)
        currentStress = try await algorithm.calculateStress(hrv: hrvData.value, heartRate: hrData.first?.value ?? 0)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### SwiftData Models
Use `@Model` macro:
```swift
@Model
final class StressMeasurement {
    var timestamp: Date
    var stressLevel: Double
    var hrv: Double

    init(timestamp: Date, stressLevel: Double, hrv: Double) {
        self.timestamp = timestamp
        self.stressLevel = stressLevel
        self.hrv = hrv
    }
}
```

### Testing
- Use `XCTAssertEqual` with `accuracy` for floating point
- Name tests: `test[Condition]` or `test[Method]_[Condition]`

```swift
func testNormalStress() async throws {
    let result = try await calculator.calculateStress(hrv: 50, heartRate: 60)
    XCTAssertEqual(result.level, 0, accuracy: 10)
    XCTAssertEqual(result.category, .relaxed)
}
```

---

## UI/UX Design System

**All UI work must follow** `documentation/references/ui-ux-design-system.md`

### Key Requirements
- **Dual coding for stress levels**: Always combine color with icons/text (WCAG compliance)
- **Dynamic Type**: Use `.accessibleDynamicType()` modifier
- **Touch targets**: Minimum 44x44pt
- **Haptic feedback**: Use `HapticManager.shared.stressLevelChanged(to:)`

### Stress Colors
```swift
Color.stressColor(for: .relaxed)      // Green #34C759
Color.stressColor(for: .mild)         // Blue #007AFF
Color.stressColor(for: .moderate)      // Yellow #FFD60A
Color.stressColor(for: .high)          // Orange #FF9500
```

---

## Global Rules

- Please do not create git commit if I not required
- Keep rules under 500 lines, split large rules into multiple composable rules
- **NEVER** include Claude credentials or attribution in commit messages
- Do not add "🤖 Generated with [Claude Code](https://claude.ai/code)"
- Do not add "Co-Authored-By: Claude <noreply@anthropic.com>"
- **ALWAYS** use `Phuong Doan` as the author name in commit metadata

---

## Implementation Phases

Follow `documentation/references/README.md` for phased implementation:

1. **Project Foundation** - Project setup, protocols
2. **Data Layer** - SwiftData models, repository
3. **Core Algorithm** - Stress calculation, confidence scoring
4. **iPhone UI** - Dashboard, trends, settings
5. **watchOS App** - Watch app, complications (WidgetKit, not ClockKit)
6. **Background Notifications** - BGAppRefreshTask, alerts
7. **Data Sync** - CloudKit integration
8. **Testing & Polish** - Unit tests, accessibility, performance

---

## Key Technical Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Architecture | MVVM with @Observable | Clean state management, testable |
| Persistence | SwiftData | iOS 17+ native, SwiftUI-friendly |
| Cloud Sync | CloudKit | End-to-end encrypted, seamless |
| watchOS Complications | WidgetKit (NOT ClockKit) | Required for watchOS 10+ |
| Background Tasks | BGAppRefreshTask | System-managed, battery-efficient |
| Dependencies | None (system only) | Privacy-first, no bloat |

---

## Privacy & Security

- All health data stored locally via SwiftData (encrypted at rest)
- CloudKit sync is end-to-end encrypted
- HealthKit is read-only access (no writes)
- No third-party analytics or tracking
- No external API calls or servers

---

## Common Issues

### HealthKit Authorization Denied
Guide user to: Settings → Privacy & Security → Health → StressMonitor

### CloudKit Sync Errors
Check iCloud account status, handle network errors gracefully

### Background Tasks Not Running
Ensure Background Modes enabled in capabilities, verify device not in Low Power Mode

---

## References

- **Implementation Phases**: `documentation/references/README.md`
- **UI/UX Design System**: `documentation/references/ui-ux-design-system.md`
- **Algorithm Details**: `documentation/references/phase-3-core-algorithm.md`
- **Apple HIG**: https://developer.apple.com/design/human-interface-guidelines/
- **HealthKit**: https://developer.apple.com/documentation/healthkit

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **ios-stress-app** (3919 symbols, 4026 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/ios-stress-app/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/ios-stress-app/context` | Codebase overview, check index freshness |
| `gitnexus://repo/ios-stress-app/clusters` | All functional areas |
| `gitnexus://repo/ios-stress-app/processes` | All execution flows |
| `gitnexus://repo/ios-stress-app/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

# Phase 1: Build Configuration & Widget Wiring - Pattern Map

**Mapped:** 2026-08-09
**Files analyzed:** 5 (matching RESEARCH.md's five concrete gaps)
**Analogs found:** 5 / 5

**Framing:** This phase is gap-closure, not net-new implementation (per RESEARCH.md). Every pattern below is "copy an already-correct sibling configuration to a target/file that's missing it" — there is no new architectural pattern being introduced.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `StressMonitor.xcodeproj/project.pbxproj` (Widget target Debug+Release `XCBuildConfiguration` blocks, IDs `F211BBEF2FD9112200A6E25D` / `F211BBF02FD9112200A6E25D`) | config (build setting) | batch (static project config, read once by `xcodebuild`) | Same file, App target's `XCBuildConfiguration` blocks (IDs `F2E2EC0D2F1CC556000C2B53` / `F2E2EC0E2F1CC556000C2B53`) — has `CODE_SIGN_ENTITLEMENTS` already | exact (same key, same file, different target block) |
| `StressMonitorWidget/PrivacyInfo.xcprivacy` (new file) | config (Apple privacy manifest) | file-I/O (static plist read by ASC validator, not app code) | `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` | exact (same schema, new bundle) |
| `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` (edit: add `1C8F.1` reason, flip `Linked` to `true`) | config | file-I/O | itself (in-place edit — no external analog needed, edit within established schema) | exact |
| `StressMonitor/Info.plist` (delete) | config | n/a (deletion) | n/a — no analog needed, this is a `git rm` of a confirmed-orphaned file | n/a |
| `StressMonitorTests/WidgetPublisherKeyMatchingTests.swift` (new file) | test | transform (pure key-string / value round-trip assertion, no network/DB) | `StressMonitorTests/CharacterAssetResolverTests.swift` | exact (Swift Testing struct, `@Test`/`#expect`, no `setUp`/`tearDown`, same target) |

## Pattern Assignments

### `StressMonitor.xcodeproj/project.pbxproj` — Widget target CODE_SIGN_ENTITLEMENTS (config, batch)

**Analog:** the App target's own Debug/Release blocks in the same file (`project.pbxproj:750`, `:801`), and the Watch target's blocks (`:852`, `:894`).

**Pattern to copy** (verbatim key format used by both existing targets):
```
CODE_SIGN_ENTITLEMENTS = StressMonitor/StressMonitor.entitlements;
```
```
CODE_SIGN_ENTITLEMENTS = "StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements";
```
Note the quoting convention: paths with spaces are double-quoted; paths without spaces are bare.

**Apply to Widget target** (both `XCBuildConfiguration` blocks — Debug `F211BBEF2FD9112200A6E25D` and Release `F211BBF02FD9112200A6E25D`, currently missing the key entirely per RESEARCH.md verified grep). The widget's entitlements file has no space in its path, so follow the App target's bare (unquoted) style:
```
CODE_SIGN_ENTITLEMENTS = StressMonitorWidget/StressMonitorWidget.entitlements;
```

**Placement convention observed in both analog blocks:** insert alphabetically among other `CODE_SIGN_*` keys — immediately before `"CODE_SIGN_IDENTITY[sdk=iphoneos*]"` and `CODE_SIGN_STYLE`, which is where both the App and Watch blocks place it. The current Widget Debug block (read this session, lines ~552-586) has this ordering already for its other `CODE_SIGN_*` keys:
```
"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
CODE_SIGN_STYLE = Manual;
```
Insert the new line directly above `"CODE_SIGN_IDENTITY[sdk=iphoneos*]"` to match the App/Watch target ordering exactly.

**Do not touch:** the nested duplicate `StressMonitor/StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.pbxproj` — confirmed decoy per RESEARCH.md Risk 2. Always target the outer `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.

---

### `StressMonitorWidget/PrivacyInfo.xcprivacy` (new) — per-bundle Privacy Manifest (config, file-I/O)

**Analog:** `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` (full file read this session, 92 lines).

**Full structural pattern to copy** (top-level keys, verbatim from the main-app manifest):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>1C8F.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```
**Widget-specific delta from the main-app analog:**
- `NSPrivacyCollectedDataTypes` → empty array. The widget collects no user data itself (it only reads a snapshot the app already wrote); the 5-entry `NSPrivacyCollectedDataTypes` array in the main-app manifest (HealthAndFitness, PhotoVideo, ProductInteraction, DeviceID, OtherUserContent — lines 11-70 of the analog) describes app-level data collection, not the widget's.
- `NSPrivacyAccessedAPITypes` → only `1C8F.1` (App-Group UserDefaults), not `CA92.1` — the widget's only Required-Reason API usage per RESEARCH.md is `UserDefaults(suiteName: Self.appGroupID)` in `WidgetDataProvider.swift:45`. Do not carry over `CA92.1` or `C617.1` (`NSPrivacyAccessedAPICategoryFileTimestamp`) unless the widget's own code independently calls those APIs (not verified — grep the widget target's Swift files for `.creationDate`/`.modificationDate` before adding `C617.1`).
- Add this new `PrivacyInfo.xcprivacy` file to the `StressMonitorWidgetExtension` target's build phase (Copy Bundle Resources), matching how the main app's manifest is attached to the `StressMonitor` target.

**Same edit pattern applies to editing the existing main-app manifest** (Gap 1 + Gap 2 from RESEARCH.md), in place:
```xml
<!-- existing UserDefaults dict, add 1C8F.1 alongside CA92.1 -->
<key>NSPrivacyAccessedAPITypeReasons</key>
<array>
	<string>CA92.1</string>
	<string>1C8F.1</string>
</array>
```
```xml
<!-- HealthAndFitness entry, flip Linked false → true per D-01 -->
<key>NSPrivacyCollectedDataType</key>
<string>NSPrivacyCollectedDataTypeHealthAndFitness</string>
<key>NSPrivacyCollectedDataTypeLinked</key>
<true/>
```

---

### `StressMonitor/Info.plist` (delete) — orphan removal (config)

No code-pattern to copy — this is a `git rm StressMonitor/Info.plist` (repo-top-level orphan, confirmed by RESEARCH.md's `INFOPLIST_FILE` grep to be unreferenced by any target). Verify first with:
```
xcodebuild -showBuildSettings -project StressMonitor.xcodeproj -target StressMonitor | grep INFOPLIST_FILE
```
which must resolve to `StressMonitor/StressMonitor/Info.plist` (the nested, empty-`<dict/>` stub that *is* the real source), not the top-level file being deleted.

---

### `StressMonitorTests/WidgetPublisherKeyMatchingTests.swift` (new) — key-matching regression test (test, transform)

**Analog:** `StressMonitorTests/CharacterAssetResolverTests.swift` (full file read this session, 59 lines).

**Imports pattern** (lines 1-2 of analog):
```swift
import Testing
@testable import StressMonitor
```

**Core pattern** — plain `struct` (not `class`), no `init`/`setUp`/`teardown`, one `@Test` per case, `#expect` assertions:
```swift
struct CharacterAssetResolverTests {
    @Test("Resolves full asset name for valid combination")
    func resolvesFullAssetName() {
        let name = CharacterAssetResolver.assetName(
            characterId: "ripple",
            evolution: .droplet,
            mood: .serene
        )
        #expect(name == "ripple_droplet_serene")
    }
}
```

**Critical constraint discovered this session (not obvious from RESEARCH.md alone):** `WidgetPublisher.Keys` (`WidgetSharedData.swift:123`) and `WidgetDataProvider.Keys` (`WidgetDataProvider.swift:14`) are both `private enum Keys` nested inside their respective types — `private` scope in Swift is file-scoped, so **even `@testable import StressMonitor` cannot reach `WidgetPublisher.Keys` from a different file**, and `WidgetDataProvider` itself lives in a separate compiled target (`StressMonitorWidget`) that `StressMonitorTests` does not link against at all (its `TEST_HOST` is `StressMonitor.app` only). Therefore the new test **cannot** do `WidgetPublisher.Keys.latestStressLevel == WidgetDataProvider.Keys.latestStressLevel` — that call site does not compile.

**Concrete implementable pattern instead:** call the public API (`WidgetPublisher.publish(_:)`, which is internal/public and callable via `@testable import`), then read the App Group `UserDefaults` suite directly using literal key strings mirroring both files' key tables (both currently identical: `latest_stress_level`, `latest_stress_category`, `latest_hrv`, `latest_heart_rate`, `latest_timestamp`, `latest_confidence` — verified byte-identical this session across `WidgetSharedData.swift:124-129` and `WidgetDataProvider.swift:15-20`):
```swift
import Testing
@testable import StressMonitor

struct WidgetPublisherKeyMatchingTests {
    @Test("WidgetPublisher writes keys WidgetDataProvider expects to read")
    func publishesExpectedKeys() {
        let suiteName = "group.stress.ai.com"
        let defaults = UserDefaults(suiteName: suiteName)!
        let measurement = StressMeasurement(/* construct via existing test fixture pattern, see MockServices.swift */)

        WidgetPublisher.publish(measurement)

        #expect(defaults.object(forKey: "latest_stress_level") != nil)
        #expect(defaults.object(forKey: "latest_stress_category") != nil)
        #expect(defaults.object(forKey: "latest_hrv") != nil)
        #expect(defaults.object(forKey: "latest_heart_rate") != nil)
        #expect(defaults.object(forKey: "latest_timestamp") != nil)
        #expect(defaults.object(forKey: "latest_confidence") != nil)
    }
}
```
This is a value/presence assertion against the literal key contract, not a type-level equality check — the closest thing to "assert WidgetPublisher's keys match WidgetDataProvider's keys" that is actually compilable given the private-scope + separate-target constraints. If the planner wants a stronger cross-target guarantee, the only way is to make both `Keys` enums at least `internal` (not `private`) and duplicate them as a literal `[String]` constant in the test file to diff against — still not a real cross-target type-check, since `WidgetDataProvider` remains unreachable from `StressMonitorTests` regardless of access level.

**StressMeasurement fixture construction:** check `StressMonitorTests/` sibling test files (e.g. any test already constructing `StressMeasurement` for `StressRepository`-adjacent tests) or `MockServices.swift` for the established init pattern before hand-rolling one — not read this session, flag as a planning-time lookup.

## Shared Patterns

### Build-setting insertion ordering (pbxproj hygiene)
**Source:** App target (`project.pbxproj:745-751`) and Watch target (`:848-853`) `CODE_SIGN_*` key blocks
**Apply to:** the Widget target's Debug/Release `CODE_SIGN_ENTITLEMENTS` insertion
Keys within a `buildSettings` dict are alphabetically sorted in this project's existing style; `CODE_SIGN_ENTITLEMENTS` sorts before `"CODE_SIGN_IDENTITY[sdk=iphoneos*]"` and `CODE_SIGN_STYLE` in both existing analogs — preserve this ordering rather than appending at the end of the dict.

### Privacy manifest per-bundle scoping
**Source:** `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` (main-app manifest, already correct in structure)
**Apply to:** any new manifest for `StressMonitorWidgetExtension` (and, pending Open Question 1 in RESEARCH.md, possibly the Watch target)
Each compiled bundle gets its own manifest scoped to *that bundle's own* Required-Reason API usage and data collection — do not copy the main app's full `NSPrivacyCollectedDataTypes` array into the widget's manifest; only its own `NSPrivacyAccessedAPITypes` usage.

## No Analog Found

None — all 5 gap-closure files have a direct, exact-match analog already in the codebase (this phase is explicitly gap-closure against existing correct siblings, not novel architecture).

## Metadata

**Analog search scope:** `StressMonitor.xcodeproj/project.pbxproj` (targeted grep + offset reads), `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy`, `StressMonitorTests/*.swift`, `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`, `StressMonitorWidget/Models/WidgetDataProvider.swift`
**Files scanned:** 6
**Pattern extraction date:** 2026-08-09

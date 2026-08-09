# Phase 1: Build Configuration & Widget Wiring - Research

**Researched:** 2026-08-08
**Domain:** Xcode project configuration (entitlements, Info.plist, test targets), Apple Privacy Manifest schema, WidgetKit timeline/reload mechanics
**Confidence:** HIGH — every claim below was verified by reading the actual project files in this repo (not the audit reports describing an earlier state of them) and, for the two file-format questions, cross-checked with Apple documentation search results.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Privacy Contract):** Backend contract is authoritative — `StressContextPayload` continues sending derived stress-context (HRV, HR, sleep, activity, recovery) to the `/chat` backend for AI coaching quality. `CLAUDE.md`, `README.md`, `docs/system-architecture*.md`, the privacy policy, and the ASC nutrition label must all be corrected to disclose exactly which health fields are transmitted — the current "never sent" claim is false and must not survive this phase. Reversibility: costly.
- **D-02 (Widget Scope):** Ship the widget in v1. WIRE-01 stays in this phase's scope: wire `WidgetDataProvider.save*` to `StressViewModel`/`SyncManager`, call `WidgetCenter.reloadAllTimelines()` on update, add a staleness threshold with an explicit "no data" fallback state. Reversibility: reversible.
- **D-03 (App Group suite ID):** Canonical App Group suite ID is `group.stress.ai.com` (matches the actual bundle ID prefix `stress.ai.com`; the other two candidates — `group.com.stressmonitor.app`, `group.com.stressmonitor.watch` — are legacy names disconnected from the real bundle ID scheme). Applied consistently across the iPhone app, watch app, and widget extension entitlements. Reversibility: costly.
- **D-04 (Test convention):** New unit tests use Swift Testing (`@Test`/`#expect`); XCTest is kept only where `setUp`/`tearDown` lifecycle already exists (`BioAgeCalculatorTests.swift`). Confirms `.planning/codebase/TESTING.md`'s established convention.
- **D-05 (Info.plist):** Info.plist consolidates onto `INFOPLIST_KEY_*` build settings (the project's existing live pattern); the orphaned `StressMonitor/Info.plist` is deleted outright, not merged.

### Claude's Discretion

- Exact staleness threshold for the widget's "no data" fallback (e.g. 30 min vs. 1 hour since last measurement) — a reasonable value chosen during planning, not a product decision worth surfacing.
- Whether the new unit-test target reuses the existing (orphaned) `StressMonitorTests` product-reference name already in `project.pbxproj`, or is named freshly — reuse unless it conflicts.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. D1 (auth), D2 (CloudKit encryption), and the two non-blocking IAP product questions belong to Phases 2-4 and are intentionally not addressed here.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUILD-01 | Release archive uploads to ASC without Privacy Manifest validation failure (remove invalid `NSPrivacyAccessedAPICategoryHealthKit`; declare chat content per D3) | See "Current Implementation State → BUILD-01" and "Privacy Manifest Schema Reference" below — main-app manifest is 80% done, three concrete gaps remain including an entirely missing widget-extension manifest |
| BUILD-02 | Widget and complications read/write the same App Group suite as the app on a real device (one canonical suite ID) | See "Current Implementation State → BUILD-02" — suite ID rename is done everywhere in code, but the Widget target's `CODE_SIGN_ENTITLEMENTS` build setting is missing, so its entitlements file is never applied |
| BUILD-03 | `xcodebuild -showBuildSettings` shows a single Info.plist source of truth; orphaned `StressMonitor/Info.plist` removed | See "Current Implementation State → BUILD-03" — ground truth on which of the *three* Info.plist files in this repo is the orphan |
| BUILD-04 | `xcodebuild test` executes a real unit-test bundle | See "Current Implementation State → BUILD-04" — a real `bundle.unit-test` target already exists and is wired correctly; two verification risks remain |
| WIRE-01 | Home screen widget reflects a measurement taken seconds earlier (wired to live data + `WidgetCenter.reloadAllTimelines()`) | See "Current Implementation State → WIRE-01" — the write path exists and is called from `StressRepository.save()`; history/baseline publishing is explicitly deferred by a code comment, which the planner must accept or close |
</phase_requirements>

## Summary

**This is not a greenfield phase.** The working tree (branch `feature/spm-cache-integration`, all changes uncommitted) already contains a substantial, mostly-correct implementation of BUILD-01, BUILD-02, BUILD-04, and WIRE-01 — apparently written in a prior, uncommitted session on 2026-08-08 before this GSD planning cycle began. `git diff --stat HEAD` shows 34 files changed including a brand-new `StressMonitorTests` native target in `project.pbxproj`, App Group entitlements added to all three targets, the canonical suite ID `group.stress.ai.com` applied consistently across ~10 call sites, a `WidgetPublisher` enum wired into `StressRepository.save()`, and a staleness threshold in `StressWidgetProvider`. **The planner's job for this phase is primarily verification and gap-closure, not net-new implementation** — treating this as build-from-scratch would duplicate work and risk overwriting already-correct code.

Five concrete, verified gaps remain (detailed below): (1) the Widget extension target has no `CODE_SIGN_ENTITLEMENTS` build setting, so its App Group entitlements file is silently unused at build time; (2) the Widget extension (and possibly the Watch app) has no `PrivacyInfo.xcprivacy` of its own despite using Required-Reason UserDefaults APIs in its own compiled code; (3) the main app's manifest is missing the `1C8F.1` reason code for its now-extensive App-Group-suite UserDefaults usage; (4) the `HealthAndFitness` collected-data entry still declares `Linked: false`, contradicting D-01's now-disclosed identity-linked `/chat` payload; (5) the legacy orphaned `StressMonitor/Info.plist` has been *documented* as dead but not *deleted* per D-05. None of these gaps were visible from `plan.md`/`CONCERNS.md` alone because those documents describe an earlier commit, before this uncommitted work existed.

**Primary recommendation:** Plan this phase as an audit-and-complete pass. Task 1 must be establishing ground truth by running `xcodebuild build`/`xcodebuild test` against the current working tree (not assuming anything from the audit reports), then closing the five gaps above, then a final full-suite verification.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Privacy Manifest declaration | Build config (per-target) | — | Each compiled bundle (app, widget extension, watch app) is validated independently by ASC; this is a per-target artifact, not a shared one |
| App Group entitlement | Build config (per-target) + Apple Developer Portal (App ID capability) | Code (constant string) | The entitlement is meaningless without the matching App ID capability + provisioning profile; the code constant is the easy 10% |
| Info.plist source of truth | Build config (`INFOPLIST_KEY_*`) | — | Project already committed to build-setting-driven Info.plist generation (`GENERATE_INFOPLIST_FILE = YES`); orphaned literal files are dead weight, not competing sources |
| Unit-test execution | Build config (native target + scheme) | Service layer (protocol seam already exists) | The DI seam for mocking already exists app-wide; the missing piece was purely the target/scheme wiring, which is largely done |
| Widget live data | Service layer (`StressRepository` write) → Cross-process snapshot (App Group `UserDefaults`) → Widget extension (`StressWidgetProvider` read) | — | Cross-process boundary is snapshot-based per `ARCHITECTURE.md`; no shared SwiftData store is possible across the app/extension boundary |

## Current Implementation State (read this before planning)

Verified via `git diff --stat HEAD -- StressMonitor/` and `Read` on each file listed. All quotes below are verbatim from the working tree as of this research session.

### BUILD-01 — Privacy Manifest

**Done** [VERIFIED: StressMonitor/StressMonitor/PrivacyInfo.xcprivacy:1-92]:
- `NSPrivacyAccessedAPICategoryHealthKit` removed — confirmed absent from the current file; the only two `NSPrivacyAccessedAPIType` entries are `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`) and `NSPrivacyAccessedAPICategoryFileTimestamp` (reason `C617.1`).
- A `NSPrivacyCollectedDataTypeOtherUserContent` entry was added with `NSPrivacyCollectedDataTypeLinked = true` and purpose `NSPrivacyCollectedDataTypePurposeAppFunctionality` — this is the D-01-mandated disclosure of chat content leaving the device.

**Gap 1 — missing App-Group UserDefaults reason code.** [VERIFIED: StressMonitor/StressMonitor/PrivacyInfo.xcprivacy:76-81] The manifest declares only reason `CA92.1` for `NSPrivacyAccessedAPICategoryUserDefaults`. `CA92.1` covers "read/write app-specific configuration and state" — it does **not** cover UserDefaults access scoped to an App Group suite. [CITED: avanderlee.com/xcode/missing-api-declaration-required-reason-itms-91053] Apple's separate reason `1C8F.1` is defined for: *"access user defaults to read and write information that is only accessible to the apps, app extensions, and App Clips that are members of the same App Group as the app itself."* This repo now performs App-Group-suite UserDefaults access in at least 5 call sites added by this same uncommitted work: `UserDefaults(suiteName: WidgetConstants.appGroupID)` [VERIFIED: StressMonitor/StressMonitor/Models/WidgetSharedData.swift:136 — `guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) else { return }`], `WidgetDataProvider.init` [VERIFIED: StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift:45 — `guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {`], plus `ComplicationDataProvider.swift`, `WatchFacePreferences.swift`, and `CharacterCollectionViewModel.swift:120` (`UserDefaults(suiteName: suiteName)`). The manifest must add `1C8F.1` alongside the existing `CA92.1` (the app also uses plain `UserDefaults.standard` extensively — confirmed via grep across `AppearanceManager.swift`, `StressRepository.swift:444/453`, `SupabaseLLMService.swift`, `SettingsViewModel.swift` — so `CA92.1` must stay).

**Gap 2 — HealthAndFitness `Linked` flag contradicts D-01.** [VERIFIED: StressMonitor/StressMonitor/PrivacyInfo.xcprivacy:11-22] The `NSPrivacyCollectedDataTypeHealthAndFitness` entry still declares `NSPrivacyCollectedDataTypeLinked` = `false`. D-01 makes the backend contract authoritative: `StressContextPayload` sends HRV/HR/sleep/activity/recovery to `/chat`, which is called with `Authorization: Bearer <JWT>` (per root `CLAUDE.md`'s Auth flow contract) — i.e. the health data is associated with an identified session server-side. Apple's guidance is that "Linked" means the data is or can be connected to the user's identity via account/session; a JWT-scoped backend call is linkage. This entry should almost certainly flip to `true` once the doc corrections in D-01 land — otherwise the manifest and the (corrected) privacy policy/nutrition label will disagree with each other, which is exactly the D3 problem this phase exists to close.

**Gap 3 — the Widget extension (and possibly the Watch app) ships with *no* privacy manifest at all.** [VERIFIED: `find StressMonitor -iname "PrivacyInfo.xcprivacy"` returns exactly one file, at `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` — the main app target only.] [CITED: multiple sources via WebSearch, e.g. jochen-holzer.medium.com and capgo.app/blog/privacy-manifest-for-ios-apps — "For widget extensions specifically, you should create a PrivacyInfo.xcprivacy file that documents any required reason APIs used by the widget code, and ensure it's added to the widget extension's build target."] Apple validates required-reason API declarations **per compiled bundle**, not just once for the umbrella app. `WidgetDataProvider.swift` — which calls `UserDefaults(suiteName:)` — physically lives inside the `StressMonitorWidget` folder that the `PBXFileSystemSynchronizedRootGroup` at `project.pbxproj:133-138` assigns to the `StressMonitorWidgetExtension` target [VERIFIED: project.pbxproj:133-138 — `F211BBDD2FD9112000A6E25D /* StressMonitorWidget */ = { isa = PBXFileSystemSynchronizedRootGroup; ... path = StressMonitorWidget; }` referenced by the `StressMonitorWidgetExtension` target's file list at line 231]. That means the Required-Reason UserDefaults API call happens inside the widget extension's own `.appex` binary, which ships to ASC as a separate bundle needing its own manifest declaring `1C8F.1`. This is a **new finding not present in `plan.md`/`CONCERNS.md`** (those documents predate the App Group work). The Watch app's `ComplicationDataProvider.swift`/`WatchFacePreferences.swift` do the same `UserDefaults(suiteName:)` call inside the Watch target — check whether the Watch app already has (or needs) its own manifest too; not verified this session, flag as an open question below.

### BUILD-02 — App Group Entitlement

**Done** [VERIFIED: all three `.entitlements` files, read this session]:
- `StressMonitor/StressMonitor/StressMonitor.entitlements` — `<key>com.apple.security.application-groups</key><array><string>group.stress.ai.com</string></array>` present (plus new `com.apple.developer.icloud-container-identifiers` = `iCloud.stress.ai.com` and `com.apple.developer.icloud-services` = `CloudKit`, which is Phase 2 (CloudKit/DATA-03) groundwork bleeding into this same uncommitted batch — flag for the planner, don't strip it, but don't expand it either).
- `StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements` — identical App Group + iCloud block.
- `StressMonitor/StressMonitorWidget/StressMonitorWidget.entitlements` — `group.stress.ai.com` only (correctly scoped, no iCloud — the widget doesn't need it).
- Suite ID `group.stress.ai.com` is applied consistently in code: `WidgetDataProvider.swift:10`, `WidgetSharedData.swift:100`, `ComplicationDataProvider.swift:14`, `WatchFacePreferences.swift:15`, `CharacterCollectionViewModel.swift:112`, `DataManageView.swift:195`. [VERIFIED via grep across all non-spm-cache Swift/entitlements files — zero remaining references to the two legacy suite IDs `group.com.stressmonitor.app` / `group.com.stressmonitor.watch` in source or entitlements; only a stale mention survives in `StressMonitorWidget/README.md:30,88,92` (documentation only, not build-relevant, but should be fixed alongside the doc corrections D-01 already requires).]

**Gap 1 — the Widget extension's entitlements file is never applied at build time.** [VERIFIED: project.pbxproj — `grep -n "CODE_SIGN_ENTITLEMENTS"` returns exactly 4 lines: 750 and 801 (`CODE_SIGN_ENTITLEMENTS = StressMonitor/StressMonitor.entitlements;`, app target Debug/Release) and 852/894 (`CODE_SIGN_ENTITLEMENTS = "StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements";`, watch target Debug/Release). The Widget extension's build settings blocks (Debug at project.pbxproj:552-586, Release at 587-621) contain no `CODE_SIGN_ENTITLEMENTS` key at all.] This means `StressMonitorWidget/StressMonitorWidget.entitlements` — despite existing on disk with the correct App Group array — is **not wired into the widget extension's compiled binary**. The widget's `PBXFileSystemSynchronizedRootGroup` folder membership makes Xcode 16+ auto-discover source/resource files, but `CODE_SIGN_ENTITLEMENTS` is a build setting, not a folder-membership concern, and is never auto-inferred. Without this line, the widget process gets no App Group container access on a real device, and `WidgetDataProvider.init`'s `fatalError("Unable to create UserDefaults with app group...")` [VERIFIED: StressMonitorWidget/Models/WidgetDataProvider.swift:45-47] will fire at runtime — this is the exact crash `ARCHITECTURE.md`'s Anti-Patterns section warns about, and it is currently live in the working tree. **This is the single highest-priority fix for BUILD-02** — add `CODE_SIGN_ENTITLEMENTS = StressMonitorWidget/StressMonitorWidget.entitlements;` to both the Debug and Release build-setting blocks for the `StressMonitorWidgetExtension` target.

**Gap 2 — provisioning profiles do not yet know about the new capabilities.** Code signing is Manual with Fastlane Match (`CODE_SIGN_STYLE = Manual`, `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*] = "match Development stress.ai.com"` / `"match AppStore stress.ai.com"` [VERIFIED: project.pbxproj:775-781, 810-816]). [VERIFIED: fastlane/Matchfile:5-9] `app_identifier(["stress.ai.com", "stress.ai.com.watchkitapp", "stress.ai.com.widget"])` already lists all three bundle IDs, so the common "match silently skips the widget" trap [CITED: dev.to/snake_sun/the-fastlane-matchfile-bundle-id-trap-that-killed-my-ci-after-adding-a-widget] does not apply here. What *is* still required: (a) the App Groups capability (and the new iCloud container capability) must be enabled on all three App IDs in the Apple Developer Portal — Match does not create App ID capabilities, only profiles; (b) existing cached Match profiles must be regenerated to embed the new entitlements. [VERIFIED: fastlane/Fastfile:62-67] The only lane with write access is `match(type: "appstore", readonly: false, force: true, api_key: api_key)`; all other lanes use `readonly: true` [VERIFIED: fastlane/Fastfile:75-79, 109-113] — confirms `.planning/codebase/STACK.md`'s note that CI is Match-readonly. **This means CI cannot regenerate profiles** — someone with Developer Portal + Match repo write access must run the force-regenerate lane locally before any CI archive of this branch can succeed with the new entitlements. There is no `match(type: "development", ...)` lane in `Fastfile` at all; if Debug/simulator-signed builds also need the new capability locally, add one or run `bundle exec fastlane match development --force` ad hoc. Flag this as a `checkpoint:human-verify` task — an agent cannot complete Developer Portal or Match-write actions.

### BUILD-03 — Info.plist Consolidation

**Ground truth on the three Info.plist files in this repo** [VERIFIED: `find StressMonitor -maxdepth 2 -iname "Info.plist"` plus `grep -n "INFOPLIST_FILE"` in project.pbxproj]:

| Path (repo-relative) | Referenced by build? | Status |
|---|---|---|
| `StressMonitor/StressMonitor/Info.plist` | **Yes** — `INFOPLIST_FILE = StressMonitor/Info.plist` at project.pbxproj:758,809, which resolves relative to the project file's own directory (`StressMonitor/StressMonitor.xcodeproj/`), i.e. to this exact path | This is the *actual* source Xcode reads; it is an empty `<dict/>` [per `.planning/codebase/STACK.md`] since all real values come from `INFOPLIST_KEY_*` build settings. Correct as-is; do not touch. |
| `StressMonitor/Info.plist` (repo top-level, sibling of `StressMonitor.xcodeproj`) | **No** | This is the orphan. [VERIFIED: git diff shows a comment block was added to it this session: `"NOT REFERENCED BY THE BUILD. INFOPLIST_FILE in project.pbxproj points at StressMonitor/Info.plist (the empty stub one directory down)..."`] It belongs to the dead legacy source tree `.planning/codebase/CONCERNS.md` documents as referenced by zero targets. **The comment documents the orphan status but does not delete the file** — D-05 says "deleted outright, not merged." This file still needs an actual `git rm`. |
| `StressMonitor/StressMonitorWidget/Info.plist` | Yes, widget target only | Out of scope — widget-specific, already build-setting-driven (`com.apple.widgetkit-extension` key), not the file BUILD-03/D-05 refers to. |

**Gap: the orphaned top-level `StressMonitor/Info.plist` has been documented as dead but not deleted.** Since `CONCERNS.md` independently confirms this file's containing legacy tree (`StressMonitor/Views/`, `StressMonitor/Services/`, `StressMonitor/StressMonitorApp.swift`) is referenced by zero `PBXNativeTarget`, deleting just this one file is safe and does not require touching the rest of that legacy tree (which `.planning/REQUIREMENTS.md`'s Out-of-Scope table explicitly excludes from this milestone). Verify with `xcodebuild -showBuildSettings -target StressMonitor | grep INFOPLIST_FILE` before deleting, to have a documented "single source of truth" artifact for BUILD-03's acceptance criterion.

### BUILD-04 — Unit-Test Target

**Extensively done** [VERIFIED: project.pbxproj diff, full sections read]:
- A real `com.apple.product-type.bundle.unit-test` native target named `StressMonitorTests` exists [VERIFIED: project.pbxproj:264-281 — `productType = "com.apple.product-type.bundle.unit-test"`], reusing the pre-existing orphaned product reference name per Claude's-discretion guidance in CONTEXT.md.
- `TEST_HOST = "$(BUILT_PRODUCTS_DIR)/StressMonitor.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/StressMonitor"` and `BUNDLE_LOADER = "$(TEST_HOST)"` are set in both Debug and Release build configs [VERIFIED: project.pbxproj — Debug config `3709BE731D5C88C8B1EFCFF6`, Release config `E207A69D4B48703A2CE2AAF1`], which is exactly what `@testable import StressMonitor` requires to link against the host app's symbols.
- `CODE_SIGNING_ALLOWED = NO` / `CODE_SIGNING_REQUIRED = NO` — correct for a simulator-only test bundle under Manual code-signing style elsewhere in the project (avoids needing a signing identity for the test target).
- A `PBXTargetDependency` makes `StressMonitorTests` depend on the `StressMonitor` app target [VERIFIED: project.pbxproj:492-497], ensuring the host app builds first.
- The `StressMonitor.xcscheme`'s `TestAction` already references `StressMonitorTests.xctest` as a `TestableReference` [VERIFIED: `StressMonitor.xcodeproj/xcshareddata/xcschemes/StressMonitor.xcscheme`], so `xcodebuild test -scheme StressMonitor -only-testing:StressMonitorTests` (the exact command `.planning/codebase/TESTING.md` prescribes) should resolve correctly.
- The Sources build phase lists 9 test files, and **all 9 exist on disk** [VERIFIED: `ls StressMonitor/StressMonitorTests/`] — including 4 new, not-yet-tracked-by-git files (`CharacterEntitlementSyncTests.swift`, `StoreKitServiceTests.swift`, `StressContextPayloadTests.swift`, `SupabaseAuthServiceTests.swift`) that go well beyond BUILD-04's scope and appear to be Phase 3/4/5 test groundwork from the same uncommitted session. A `StressMonitorProducts.storekit` file was also added to the test target's Resources phase — this is Phase 5 (IAP) groundwork, not part of BUILD-04's acceptance criterion, but harmless to leave in place.
- `xcodebuild -list -project StressMonitor.xcodeproj` (run this session) confirms the project parses cleanly and lists all 4 targets including `StressMonitorTests`.

**Risk 1 — a dangling `StressMonitorUITests` testable reference.** [VERIFIED: `StressMonitor.xcscheme`'s `TestAction` also references a `StressMonitorUITests.xctest` `TestableReference`, but `grep -n "productType" project.pbxproj` shows only 4 `PBXNativeTarget`s total — `StressMonitorTests`, `StressMonitorWidgetExtension`, `StressMonitor`, `StressMonitorWatch Watch App`. There is no `StressMonitorUITests` native target.] `.planning/codebase/TESTING.md` independently confirms "No XCUITest target exists." Running `xcodebuild test -scheme StressMonitor` **without** `-only-testing:StressMonitorTests` may attempt to resolve/build the phantom `StressMonitorUITests` testable and fail. `-only-testing:StressMonitorTests` (the documented canonical command) likely sidesteps this, but this should be explicitly verified as part of BUILD-04's acceptance check, and the dangling reference removed from the scheme if it causes any friction (`xcodebuild test` reads the scheme's `Testables` list before applying `-only-testing` filters in some Xcode versions).

**Risk 2 — a nested duplicate `.xcodeproj` exists.** [VERIFIED: `.planning/codebase/CONCERNS.md` — "A second project bundle exists at `StressMonitor/StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.pbxproj`"; confirmed present via `find` this session, including a duplicate `xcshareddata/xcschemes/StressMonitor.xcscheme`.] This is out of Phase 1 scope per `REQUIREMENTS.md`'s Out-of-Scope table, but is a real risk for *any* pbxproj edit in this phase: always target `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (the outer one — confirmed as the one `xcodebuild -list` actually reads when invoked from `StressMonitor/`) and never the nested copy. State this explicitly as a plan constraint so an executor doesn't glob-match the wrong file.

**Not yet verified this session:** whether `xcodebuild test -only-testing:StressMonitorTests` actually **passes** against the current working tree (only that the project *parses* and the target/scheme wiring is structurally correct). The planner's first task should be running this command to establish a pass/fail baseline before making further changes — do not assume green.

### WIRE-01 — Widget Live Data

**Done** [VERIFIED: read StressRepository.swift, WidgetSharedData.swift, WidgetDataProvider.swift, StressWidgetProvider.swift in full this session]:
- `WidgetPublisher.publish(measurement)` [VERIFIED: StressMonitor/StressMonitor/Models/WidgetSharedData.swift:122-152] is called from `StressRepository.save(_:)` immediately after a successful local SwiftData save: `try modelContext.save() ... WidgetPublisher.publish(measurement)` [VERIFIED: StressMonitor/StressMonitor/Services/Repository/StressRepository.swift:47-58].
- `WidgetPublisher.publish` writes to `UserDefaults(suiteName: WidgetConstants.appGroupID)` using key names that **exactly match** `WidgetDataProvider.Keys` on the read side — verified by direct comparison: `latest_stress_level`, `latest_stress_category`, `latest_hrv`, `latest_heart_rate`, `latest_timestamp`, `latest_confidence` appear identically in both `WidgetSharedData.swift:123-129` (write side) and `WidgetDataProvider.swift:14-20` (read side). This is the classic two-target-can't-share-a-type failure mode `ARCHITECTURE.md` warns about ("cross-target types are duplicated by file") — verified it was done correctly, not just assumed.
- `WidgetPublisher.publish` calls `WidgetCenter.shared.reloadAllTimelines()` unconditionally after writing [VERIFIED: WidgetSharedData.swift:150].
- `StressWidgetProvider.getTimeline` adds a staleness threshold: `let stalenessThreshold: TimeInterval = 24 * 3600` and falls back to `isPlaceholder: latestStress == nil || isStale` [VERIFIED: StressMonitorWidget/Providers/StressWidgetProvider.swift:49-61]. This satisfies D-02's "staleness threshold with an explicit no-data fallback" by reusing the existing placeholder-rendering path as the fallback UI, rather than adding a distinct third visual state — a reasonable interpretation, but confirm with the planner that reusing the existing placeholder view (which shows synthetic sample numbers, not an explicit "no data" message) actually satisfies D-02's *"explicit 'no data' fallback state"* wording, or whether the placeholder view needs a visual variant that says "no recent measurement" rather than showing a fabricated 45/mild/50hrv/70bpm reading as if real.

**Gap — history and baseline are not published; only the single latest-value fields are.** [VERIFIED: WidgetSharedData.swift:113-120, code comment left in place by whoever wrote this] The comment states verbatim: *"Scope note: publishes latest-measurement only. History (sparkline) and baseline publishing are not yet wired — `StressWidgetProvider` degrades gracefully to an empty trend line when history is absent, so this still converts the widget from 'always fake' to 'shows real current data.'"* This means `WidgetDataProvider.saveHistory(_:)` and `saveBaseline(hrv:restingHeartRate:)` [VERIFIED: WidgetDataProvider.swift:95-105, 127-131] are still never called from anywhere in the app target — `getHistory()`/`getBaseline()` will keep returning empty/stale data indefinitely, so any widget UI that renders a trend sparkline or references the personal baseline will remain visually broken even after this fix. WIRE-01's acceptance text ("widget reflects a measurement taken seconds earlier") is satisfied by the latest-value wiring alone, but this is a scope decision the planner should make explicitly rather than silently ship a widget with a working headline number and a permanently-empty trend line — check what the widget's actual view code (`StressMonitorWidget/Views/`) renders for `history`/`baseline` before deciding whether to close this gap in this phase or explicitly defer it.

**Watch-out — reload-frequency budget.** [CITED: developer.apple.com/forums/thread/654331, thread/761210 — no single authoritative page returned by search, treat as community-corroborated rather than official] WidgetKit budgets roughly 40-70 timeline reloads per day per widget; `reloadAllTimelines()` calls beyond budget are silently deprioritized by the system, not queued or errored. Because `WidgetPublisher.publish` fires on every `StressRepository.save(_:)` call — not on a fixed timer — the real-world frequency depends on how often `StressViewModel`/`HealthBackgroundScheduler` actually persist a new measurement. Not measured this session; if background auto-refresh saves very frequently (sub-15-minute cadence), some reload requests will be silently dropped by the system and the widget will lag behind the App Group data it can already see. Low risk for v1 given the widget's own `getTimeline` already sets a 15-minute-ahead `.after(nextUpdate)` policy as a backstop, but worth a manual-QA note rather than a blocking gap.

## Package Legitimacy Audit

Not applicable — this phase makes no new SPM/CocoaPods/package additions. The two SPM package reference IDs changed in `project.pbxproj` (`XCLocalSwiftPackageReference "proxy"`, `XCSwiftPackageProductDependency` for `SwiftUICharts`/`ExyteChat`) are internal Xcode-generated GUID churn from the local SPM cache/proxy mechanism (see recent commit `e3d8e2f fix(spm-cache): re-integrate proxy with correct product references`), not new dependencies — no legitimacy check needed.

## Privacy Manifest Schema Reference

Apple's Required-Reason API has exactly five categories — `NSPrivacyAccessedAPICategoryUserDefaults`, `NSPrivacyAccessedAPICategoryFileTimestamp`, `NSPrivacyAccessedAPICategorySystemBootTime`, `NSPrivacyAccessedAPICategoryDiskSpace`, `NSPrivacyAccessedAPICategoryActiveKeyboards` [CITED: multiple corroborating sources via WebSearch — bugfender.com/blog/apple-privacy-requirements, medium.com/@sachinsiwal/apples-new-privacy-requirements-in-the-app-store-92fb5b3e8a32; the authoritative source is `developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api`, which returned only a title via WebFetch this session — treat category names as MEDIUM confidence, cross-checked across 2+ independent sources]. **`NSPrivacyAccessedAPICategoryHealthKit` does not exist in this list** — confirms the original audit finding and the fact that it's already been removed from this repo's manifest.

Reason codes relevant to this codebase [CITED: avanderlee.com/xcode/missing-api-declaration-required-reason-itms-91053]:
- `CA92.1` (UserDefaults) — read/write app-specific configuration and state (already declared).
- `1C8F.1` (UserDefaults) — access user defaults scoped to an App Group shared by app/extensions/App Clips (**missing — see BUILD-01 Gap 1 above**).
- `C617.1` (FileTimestamp) — access file creation/modification dates (already declared, unrelated to this phase's changes, not re-verified against actual file-timestamp call sites this session — low risk, pre-existing).

Collected-data-type constant used for chat content: `NSPrivacyCollectedDataTypeOtherUserContent` under the "User Content" category, with `NSPrivacyCollectedDataTypeLinked` and `NSPrivacyCollectedDataTypePurposes` siblings — already used correctly in this repo's manifest [VERIFIED: PrivacyInfo.xcprivacy:59-70].

## Architecture Patterns

### Recommended verification sequence (not a "build from scratch" plan)

```
1. Establish baseline
   xcodebuild build -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
   xcodebuild test  -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
     -only-testing:StressMonitorTests
   → confirms current pass/fail state of the uncommitted work before touching anything

2. Close BUILD-02 Gap 1 (highest priority — currently a live fatalError risk)
   Add CODE_SIGN_ENTITLEMENTS = StressMonitorWidget/StressMonitorWidget.entitlements;
   to both XCBuildConfiguration blocks for StressMonitorWidgetExtension (Debug + Release)

3. Close BUILD-01 gaps (manifest correctness)
   - Add 1C8F.1 reason alongside CA92.1 in the main app's PrivacyInfo.xcprivacy
   - Create StressMonitorWidget/PrivacyInfo.xcprivacy declaring 1C8F.1
   - Flip HealthAndFitness Linked to true (coordinate with D-01's doc-correction tasks)
   - Verify whether the Watch app target needs its own manifest too

4. Close BUILD-03 (delete, don't just document, the orphaned top-level Info.plist)

5. checkpoint:human-verify — Apple Developer Portal capability + fastlane match regeneration
   (agent cannot perform this; document exact commands for a human to run)

6. Decide + close (or explicitly defer) the WIRE-01 history/baseline scope gap

7. Re-run step 1's commands as the phase gate
```

### Pattern: cross-process snapshot publish/subscribe (already established, reuse exactly)

```swift
// Source: StressMonitor/StressMonitor/Models/WidgetSharedData.swift:122-153 (verified this session)
enum WidgetPublisher {
    private enum Keys {
        static let latestStressLevel = "latest_stress_level"
        // ... must match WidgetDataProvider.Keys byte-for-byte; no shared module exists
    }

    static func publish(_ measurement: StressMeasurement) {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) else { return }
        defaults.set(measurement.stressLevel, forKey: Keys.latestStressLevel)
        // ...
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```
Any future writer (e.g. if history/baseline publishing is added in this phase) must extend this same enum with the same key-matching discipline against `WidgetDataProvider.Keys` — do not introduce a second, differently-named publisher.

### Anti-Patterns to Avoid

- **Assuming plan.md/CONCERNS.md describe current state:** Both documents were generated before the uncommitted App Group/test-target work existed. Treat them as "what the last commit looked like," not "what's on disk now." Always `git diff` the specific file before planning a task against it.
- **Editing the nested duplicate `.xcodeproj`:** `StressMonitor/StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.pbxproj` exists and is a decoy. Confirm the target path before every pbxproj edit.
- **Adding a widget entitlements file without wiring `CODE_SIGN_ENTITLEMENTS`:** exactly the mistake already present in the working tree for the Widget target — the file existing is necessary but not sufficient.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-target constant sharing (App Group ID, UserDefaults keys) | A shared Swift module/framework target just for constants | Keep the existing duplicated-by-convention pattern (already established, already correct) | `ARCHITECTURE.md` explicitly documents "no shared module" as a project-wide constraint; introducing one now is out of this phase's scope and would touch build settings for all 3 targets unnecessarily |
| Widget "no data" UI state | A bespoke third rendering path | Reuse `StressEntry.isPlaceholder` (already exists, already wired to the staleness check) | The mechanism already correctly distinguishes "no data yet" and "stale" from "fresh" — only the *visual treatment* of the placeholder state may need a copy/label tweak, not new plumbing |
| Test target creation | Hand-writing a fresh `PBXNativeTarget` from a blog-post template, or introducing XcodeGen/Tuist | Verify and, if needed, lightly adjust the target that already exists in `project.pbxproj` (TEST_HOST/BUNDLE_LOADER pattern is already correct) | Re-generating this target risks producing a second, conflicting `StressMonitorTests` definition; XcodeGen/Tuist would be a much larger, unrequested migration for a project the team hand-maintains |

**Key insight:** every "don't hand-roll" item in this phase is really "don't re-do work that's already sitting correctly in the working tree" — the risk profile here is duplication/regression, not missing capability.

## Common Pitfalls

### Pitfall 1: Trusting the audit reports over `git diff`
**What goes wrong:** Planning a task to "remove NSPrivacyAccessedAPICategoryHealthKit" or "add the App Group entitlement" when both are already done, wasting a plan-review cycle or, worse, an executor re-adding something that was already correctly configured.
**Why it happens:** `plan.md` and `.planning/codebase/*.md` were generated by mapping the last **commit**, not the working tree with 34 uncommitted file changes.
**How to avoid:** Every task in this phase's PLAN.md should open with a `git diff` / `Read` check against current disk state, not just cite the audit line number.
**Warning signs:** A task description that quotes `plan.md`'s file:line citations verbatim without an independent verification step.

### Pitfall 2: An entitlements file that "exists" but isn't applied
**What goes wrong:** Confirming BUILD-02 as done because `StressMonitorWidget.entitlements` exists on disk with the right App Group array, without checking that `CODE_SIGN_ENTITLEMENTS` in `project.pbxproj` actually points at it.
**Why it happens:** Xcode's UI (Signing & Capabilities tab) usually manages both the entitlements file *and* the build setting together when you use the GUI; hand-editing (or an agent editing) the plist file alone leaves the build setting stale.
**How to avoid:** For every target that needs an entitlements change, grep `project.pbxproj` for `CODE_SIGN_ENTITLEMENTS` scoped to that target's build configuration IDs, not just check the `.entitlements` file content.
**Warning signs:** `WidgetDataProvider.init`'s `fatalError` firing on a real device despite the entitlements file "looking correct."

### Pitfall 3: Manual + Match code signing silently breaks on new capabilities
**What goes wrong:** CI archive fails with a cryptic "doesn't support the App Groups capability" error after this phase's entitlement changes land, even though the pbxproj/entitlements files are all correct.
**Why it happens:** `CODE_SIGN_STYLE = Manual` + Fastlane Match means Xcode never auto-registers new capabilities with the Developer Portal (that only happens under `CODE_SIGN_STYLE = Automatic`); the cached Match profiles simply don't know about the new entitlement until someone with write access force-regenerates them.
**How to avoid:** Sequence a `checkpoint:human-verify` task before any CI-dependent verification step in this phase, instructing a human to (a) enable App Groups + iCloud on all 3 App IDs in the Developer Portal, (b) run the write-access Match lane locally.
**Warning signs:** Any Fastfile lane invocation failing on `readonly: true` in CI right after this phase's entitlement changes are pushed.

## Runtime State Inventory

> Included because BUILD-02/D-03 changes the App Group suite ID, which is a rename of a live-at-runtime identifier.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — the app has never been submitted to or released via App Store/TestFlight (`plan.md`'s Verdict: "Not submittable"; this is the *first* submission attempt). No production or beta users hold data under either legacy suite ID (`group.com.stressmonitor.app`, `group.com.stressmonitor.watch`). | None — a pre-launch suite ID rename carries no migration burden. |
| Live service config | None — App Group suite IDs are not configured in any external dashboard (unlike, e.g., n8n workflows or Datadog tags); they only exist as entitlement-file/code constants, already fully covered by BUILD-02's verified-consistent rename above. | None. |
| OS-registered state | Simulator-only local dev builds may have a stale `group.com.stressmonitor.*` UserDefaults domain cached in `~/Library/Developer/CoreSimulator/.../Library/Preferences/`. | None required for correctness (a fresh suite ID simply creates a new, empty domain) — optionally advise a simulator reset during manual QA to avoid confusing stale-data debugging. |
| Secrets/env vars | None — no secret or env var name embeds either legacy suite ID string. | None. |
| Build artifacts | `StressMonitor/build/` (155MB, untracked, per `CONCERNS.md`) may contain a `.app` built against the old suite ID. | Clean build folder as part of this phase's verification pass so stale artifacts don't mask the rename's effect. |

**Nothing found requiring a data migration** — this category of risk exists in `CONTEXT.md`'s D-03 rationale purely as a *future* cost (post-launch), not a current one.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reason code `1C8F.1` is the correct/only additional reason needed for App-Group-scoped UserDefaults access (sourced from a third-party blog post, not Apple's own page directly, since WebFetch could not retrieve the official page's body text this session) | BUILD-01 Gap 1, Privacy Manifest Schema Reference | If wrong, the manifest fix could still fail ASC's automated validation; verify against Xcode's own reason-code autocomplete/Apple's official generator before submission, not just this research |
| A2 | The Watch app target needs its own `PrivacyInfo.xcprivacy` for its `UserDefaults(suiteName:)` calls in `ComplicationDataProvider`/`WatchFacePreferences` | BUILD-01 Gap 3 | Not verified this session (only confirmed the Widget extension has zero manifest) — if the Watch app already has one, no action needed; if it needs one and doesn't get one, same ASC-validation risk as the widget gap |
| A3 | Reusing the existing `isPlaceholder` rendering path (rather than a new distinct visual state) satisfies D-02's "explicit no-data fallback state" wording | WIRE-01 | If the product intent was a visually distinct "no data yet" message rather than a synthetic sample reading, this needs a small UI change the current code doesn't have |
| A4 | The WidgetKit reload budget figures (~40-70/day) are accurate for the current iOS version | WIRE-01 "Watch-out" | Community-sourced, not from an Apple engineering session transcript found this session; if materially wrong, could under- or over-estimate real reload-throttling risk, though this doesn't block the phase either way |

## Open Questions

1. **Does the Watch app target need its own Privacy Manifest?**
   - What we know: The Widget extension definitely needs one and doesn't have one (verified). The Watch app also calls `UserDefaults(suiteName:)` in its own compiled code.
   - What's unclear: Whether watchOS app targets are held to the same per-bundle manifest validation as iOS app extensions, and whether one already exists somewhere not caught by this session's `find` (which searched the whole repo and found none anywhere but the main app).
   - Recommendation: `find` again for `PrivacyInfo.xcprivacy` scoped explicitly to the Watch target's folder as an early planning task; if absent, add one alongside the Widget's.

2. **Does WIRE-01 require history/baseline widget publishing, or is latest-value sufficient for v1?**
   - What we know: The literal acceptance text ("widget reflects a measurement taken seconds earlier") is satisfied by latest-value alone; the existing code comment explicitly defers history/baseline as a documented scope cut.
   - What's unclear: What the widget's actual SwiftUI view code renders for `history`/`baseline` — if it shows a visibly broken/empty sparkline next to a correct headline number, that may read as "still broken" in a screenshot-based App Review, even though the acceptance criterion is technically met.
   - Recommendation: Read `StressMonitorWidget/Views/` during planning to see the actual rendered surface before deciding whether to close this gap in Phase 1 or note it for Phase 4/5 (Store Listing screenshots phase).

3. **Does `xcodebuild test -only-testing:StressMonitorTests` currently pass end-to-end?**
   - What we know: The project and scheme are structurally wired correctly (verified via `xcodebuild -list` and file reads).
   - What's unclear: Whether the 9 test files (4 of them brand-new and untracked) actually compile and pass against the current `StressMonitor` app target — not executed this session due to time budget.
   - Recommendation: Make this literally the first task/verification step of the plan.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | All of BUILD-01..04, WIRE-01 | ✓ | Confirmed runnable this session (`xcodebuild -list` succeeded); CI pins Xcode 26.3 per `.planning/codebase/TESTING.md` | — |
| Local SPM package cache/proxy | Project package resolution | ✓ | Resolved cleanly this session (`spm_cache_proxy`, `SwiftUICharts_proxy`, `Chat_proxy` all resolved) | — |
| iOS Simulator (for `xcodebuild test`) | BUILD-04 verification | Not explicitly probed this session — assume available per standard dev machine setup implied by `.planning/codebase/TESTING.md`'s `scripts/run-tests.py` | — | — |
| Apple Developer Portal access (App ID capability toggles) | BUILD-02 Gap 2 | ✗ (agent has no credentials) | — | `checkpoint:human-verify` task — no code-only fallback exists |
| Fastlane Match write access (git-based cert/profile repo) | BUILD-02 Gap 2 | ✗ (agent has no credentials; CI itself is also `readonly: true`) | — | Same `checkpoint:human-verify` task as above |

**Missing dependencies with no fallback:**
- Apple Developer Portal + Fastlane Match write access — both block BUILD-02's real-device acceptance criterion ("widget and complication read/write the same suite on a real device") and must be scheduled as a human task, not an agent task.

**Missing dependencies with fallback:**
- None — the two missing items above have no automatable fallback by design (Apple's signing model requires this).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`/`#expect`) for new tests per D-04; XCTest retained only for `BioAgeCalculatorTests.swift` [VERIFIED: `.planning/codebase/TESTING.md`] |
| Config file | None separate — driven by the `StressMonitorTests` native target + `StressMonitor.xcscheme`'s `TestAction` (both verified present and wired this session) |
| Quick run command | `xcodebuild test -project StressMonitor/StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:StressMonitorTests` |
| Full suite command | `CI=1 python3 scripts/run-tests.py` [VERIFIED: `.planning/codebase/TESTING.md`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUILD-04 | `xcodebuild test` executes the real bundle | integration (build-system-level, not a Swift test) | `xcodebuild test -only-testing:StressMonitorTests ...` (above) | ✅ target exists; not yet confirmed green this session |
| BUILD-01 | Manifest passes ASC validation | manual/tooling — no local automated equivalent to ASC's own validator | `xcrun altool --validate-app` (or Xcode Organizer's own pre-upload validation) against an actual archive | ❌ Wave 0 — no local script wraps this; archive-and-validate must be a manual/CI step |
| BUILD-02 | Widget/complication read the live App Group suite on a real device | manual — App Group behavior differs from simulator per `plan.md`'s Phase 2 acceptance note, applicable here too | Manual device QA: trigger a stress save, background the app, confirm widget updates | ❌ no automated device test exists or is expected for this |
| BUILD-03 | Single Info.plist source of truth | build-settings inspection, scriptable | `xcodebuild -showBuildSettings -project StressMonitor/StressMonitor.xcodeproj -target StressMonitor \| grep INFOPLIST_FILE` | ❌ Wave 0 — trivial to add as a one-line verification, not yet a checked-in script |
| WIRE-01 | Widget reflects a measurement taken seconds earlier | manual (real device) + optional unit test on `WidgetPublisher`'s key-matching | New unit test recommended: assert `WidgetPublisher`'s written keys match `WidgetDataProvider.Keys` (currently only verified by manual code comparison in this research) | ❌ Wave 0 — no test exists for this today; cheap to add given both enums are small |

### Sampling Rate
- **Per task commit:** `xcodebuild test -only-testing:StressMonitorTests` (quick run)
- **Per wave merge:** `CI=1 python3 scripts/run-tests.py` (full suite)
- **Phase gate:** Full suite green + a real or simulator-based manual pass on the widget wiring + `xcodebuild -showBuildSettings` single-Info.plist confirmation, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] A unit test asserting `WidgetPublisher`'s UserDefaults keys match `WidgetDataProvider.Keys` (regression-proofs the cross-target duplication-by-convention pattern) — covers WIRE-01
- [ ] A scripted `xcodebuild -showBuildSettings | grep INFOPLIST_FILE` check, ideally added to `scripts/run-tests.py` or a small new script — covers BUILD-03
- [ ] No automated equivalent exists (or should be built) for BUILD-01's ASC manifest validation or BUILD-02's real-device App Group check — both remain manual/CI-archive-time checks by nature

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Out of scope for this phase (Phase 3 territory) |
| V3 Session Management | No | Out of scope for this phase |
| V4 Access Control | No | Out of scope for this phase |
| V5 Input Validation | Marginal | The widget's `getLatestStress()` already validates for a "no data" sentinel (`if level == 0 && hrv == 0 && heartRate == 0 { return nil }`) — no new validation surface introduced by this phase's changes |
| V6 Cryptography | No | No cryptographic changes in this phase |

### Known Threat Patterns for this stack (Phase 1 scope only)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Over-broad App Group data exposure — any app/extension sharing the App Group can read all keys in the shared `UserDefaults` suite | Information Disclosure | Already minimal — only derived stress metrics (level/category/hrv/hr/confidence/timestamp) are written, never raw HealthKit samples or auth tokens; keep it that way when/if history/baseline publishing is added |
| Privacy Manifest under- or over-disclosure | Information Disclosure (to reviewers/regulators, not attackers) | Handled by this phase's BUILD-01 work; the main residual risk is under-disclosure (missing `1C8F.1`, `Linked: false` mismatch) rather than over-disclosure |

## Sources

### Primary (HIGH confidence — verified by reading the actual files this session)
- `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` (full file + `git diff`)
- `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (full `git diff`, targeted `Read` of build-configuration blocks, `grep` for `CODE_SIGN_ENTITLEMENTS`/`INFOPLIST_FILE`/`productType`)
- `StressMonitor/StressMonitor/StressMonitor.entitlements`, `StressMonitorWatch Watch App.entitlements`, `StressMonitorWidget.entitlements` (all three, full content + diff)
- `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift`, `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`, `StressMonitor/StressMonitorWidget/Providers/StressWidgetProvider.swift`, `StressMonitor/StressMonitor/Services/Repository/StressRepository.swift` (full content + diff)
- `fastlane/Matchfile`, `fastlane/Fastfile` (targeted reads)
- `.planning/codebase/STACK.md`, `CONCERNS.md`, `TESTING.md`, `ARCHITECTURE.md`
- `plans/0808-2042-appstore-submission-remediation/plan.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/01-build-configuration-widget-wiring/01-CONTEXT.md`
- `xcodebuild -list -project StressMonitor.xcodeproj` (run this session, output captured)

### Secondary (MEDIUM confidence — WebSearch/WebFetch, cross-checked across 2+ independent sources)
- Apple Required-Reason API's five categories and the non-existence of a HealthKit category (bugfender.com, medium.com/@sachinsiwal)
- `1C8F.1` reason code definition for App-Group-scoped UserDefaults (avanderlee.com)
- Per-bundle privacy manifest requirement for app extensions including widgets (jochen-holzer.medium.com, capgo.app)
- Fastlane Match's Matchfile bundle-ID trap for extensions (dev.to/snake_sun)

### Tertiary (LOW confidence — community forum threads, not officially confirmed this session)
- WidgetKit's ~40-70 reloads/day budget figure (developer.apple.com/forums threads 654331, 761210 — Apple engineer commentary in community forums, not an official published number)

## Metadata

**Confidence breakdown:**
- Current implementation state (what's already done vs. gaps): HIGH — every claim verified by reading the actual working-tree files and their diffs this session, with exact line-number citations and verbatim quotes
- Privacy Manifest schema (category/reason-code correctness): MEDIUM — official Apple page content could not be fetched directly this session; corroborated across multiple independent secondary sources instead
- Provisioning/Match mechanics: HIGH for what's in this repo (Matchfile/Fastfile read directly), MEDIUM for the general "Manual signing doesn't auto-register capabilities" claim (well-established community knowledge, not fetched from an official page this session)
- WidgetKit reload budget figures: LOW — included as a watch-item, not a blocking finding

**Research date:** 2026-08-08
**Valid until:** Re-verify the "Current Implementation State" section immediately before planning if any commits land on this branch between now and plan creation — this research is a snapshot of an actively-changing uncommitted working tree, not a stable released codebase. The Privacy Manifest schema portion is stable for ~30 days (Apple's Required-Reason API list changes infrequently).

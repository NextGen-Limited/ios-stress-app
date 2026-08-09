# App Store Screenshot & Metadata Validation Report — StressMonitor

**Date**: 2026-08-08
**Repo**: ios-stress-app (branch `feature/spm-cache-integration`)
**Scope**: App Store screenshot assets + fastlane screenshot/metadata pipeline for an iPhone + Apple Watch (+ widget) submission.
**Excluded per instructions**: `build/`, `DerivedData/`, `.build/`, `plans/`, `docs/`, `.planning/` (docs/ referenced only as a light cross-check, not audited for content).

---

## Bottom Line

**No App Store screenshots exist anywhere in this repository, for any device.** There is also no fastlane screenshot-generation setup (`Snapfile`) and no fastlane metadata folder (`fastlane/metadata/`, `Deliverfile`). The repo cannot currently produce a submittable App Store listing without additional work outside this codebase.

## Summary

| Severity | Count |
|---|---|
| CRITICAL | 2 |
| HIGH | 2 |
| MEDIUM | 1 |
| LOW | 1 |

**Submittable screenshots currently exist: NO.**

---

## Step 1–2: Discovery

Searched the entire repo (excluding `build/`, `DerivedData/`, `.build/`, `plans/`, `docs/`, `.planning/`) for:
- `fastlane/screenshots/`, `fastlane/Snapfile`, `fastlane/Deliverfile`, `fastlane/metadata/` — **none exist**. `fastlane/` only contains `Appfile`, `Fastfile`, `Matchfile`, `README.md`, `report.xml`.
- Any `*screenshot*`-named path in the repo — only hit was `plans/reports/stresswatch-screenshot.png` (1280×800), a leftover artifact from a prior audit/report session, not a device capture and not an App Store asset.
- `Screenshots/`, `screenshots/`, `marketing/`, `Assets/` folders outside Xcode asset catalogs — none. `assets/` at repo root contains 7 PNGs (`date-header.png`, `stress-status-view.png`, `horizontal-calender-ui.png`, `trends-home-ui.png`, `ui-setting.png`, `Trend.png`, `daily-timeline-chart.png`) — these are design/dev reference captures at logical point sizes (e.g. 390×2436, 371×433, 360×52), not App Store submission assets; none match any required device pixel dimension.
- `SnapshotHelper.swift`, any `*UITests*` target, or `Snapshot`/`UITests` references in the `.pbxproj` — **none found**. There is no XCUITest target wired for `fastlane snapshot` at all.
- `.xcassets` app icon marketing images exist (`StressMonitor-AppIcon-ios-marketing-1024.png`, widget equivalent) but these are icon assets, not screenshots — out of scope for this audit.

**Conclusion**: Zero App Store screenshots exist. Zero automated screenshot pipeline exists.

---

## Step 3–4: Dimension & Visual Checks

Not applicable — skipped because there are no image assets to check.

---

## Task 3: Required Sizes for This App's Submission Shape

Checked the actual Xcode target configuration (not assumed) to scope the requirement correctly:

- `StressMonitor` (main app) target → `TARGETED_DEVICE_FAMILY = 1` → **iPhone only, no iPad support**. (The `StressMonitorWidgetExtension` target is set to `"1,2"`, but the widget's own family setting does not create an iPad screenshot requirement — that's driven by the main app target.)
- `StressMonitorWatch Watch App` target → `TARGETED_DEVICE_FAMILY = 4`, no `WKRunsIndependentlyOfCompanionApp` entitlement found → **companion-only watch app**, bundled with and listed under the iPhone app (not an independent watchOS submission).
- `knownRegions = (en, Base)`, `developmentRegion = en` → **English-only, single locale.** No `.lproj` folders beyond Base were found. Only one locale's worth of metadata/screenshots is needed today.

### Required iPhone screenshot sizes (current App Store Connect spec)

| Device | Portrait | Landscape |
|---|---|---|
| iPhone 6.9" (Air, 17 Pro Max, 16 Pro Max) | 1260×2736 | 2736×1260 |
| iPhone 6.5" (14 Plus, 13 Pro Max, XS Max) | 1284×2778 or 1242×2688 | 2778×1284 or 2688×1242 |
| iPhone 6.3" (17 Pro, 16 Pro, 16, 15 Pro) | 1179×2556 or 1206×2622 | 2556×1179 or 2622×1206 |
| iPhone 6.1" (17e, 16e, 14, 13, 12) | 1170×2532, 1125×2436, or 1080×2340 | 2532×1170, 2436×1125, or 2340×1080 |
| iPhone 5.5" (8 Plus, 7 Plus) | 1242×2208 | 2208×1242 |

**Minimum required to submit**: App Store Connect now auto-scales a single, largest-size upload down to smaller iPhone size classes. You only need to provide **one** full set at **6.9" or 6.5"** (portrait, 2–10 images) for the primary locale. Uploading additional size classes is optional (useful mainly if you want size-specific compositions rather than auto-scaled ones).

**iPad**: not required — main app target is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`).

### Apple Watch screenshots

**Optional, not required**, because the Watch app here is a companion app bundled with the iPhone app (not an independent watchOS submission under its own listing). If you choose to add them for marketing purposes, App Store Connect's own uploader enforces the current per-model pixel dimensions at upload time (these shift slightly as new Watch case sizes ship — e.g. Series 10's 42/46mm redesign — so treat ASC's own validator as the source of truth rather than a hardcoded table here). The team's own `docs/deployment-guide-release.md` already scopes this correctly as "At least 1 screenshot" for Watch, i.e. optional/minimal.

### Locales

Only the primary locale (English) is needed — no other `.lproj` localizations exist in the project today.

---

## Task 4: Fastlane Metadata Check

`fastlane/metadata/` does not exist. There is no `Deliverfile`. Consequently:
- App description, keywords, promotional text, support URL, marketing URL, and privacy policy URL are **not present anywhere in version control** for `deliver` to upload. (Draft copy exists in `docs/aso/app-description.md` and `docs/aso/apple-editorial-checklist.md`, per repo convention docs/ is excluded from this audit's asset scan — noted only as a pointer, not content-audited here.)
- Because none of this is version-controlled, there's no way to check it here for placeholder text, missing privacy policy URL, etc. — it either lives only in the App Store Connect web UI today (unverifiable from the repo), or it has never been entered at all.

This directly interacts with `fastlane/Fastfile`'s `release` lane (see CRITICAL-2 below).

---

## CRITICAL Findings

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| No App Store screenshots exist for any device (iPhone or Watch) | Immediate — hard submission blocker | Blocks all App Store submissions; App Store Connect will not accept `submit_for_review` without at least one screenshot per required device size | Medium (capture + curate 2–10 images at one iPhone size class, ideally via a scripted snapshot flow) | High — unblocks the entire release |
| `fastlane/Fastfile`'s `release` lane calls `deliver` with `skip_metadata: false, skip_screenshots: false, submit_for_review: true`, but no local `fastlane/metadata/` or `fastlane/screenshots/` exist, and no `Deliverfile` exists | Immediate — pipeline will fail or silently no-op on first real run | Breaks the only automated App Store submission path in CI/CD (`bundle exec fastlane release`); on a first-ever submission, ASC itself will reject `submit_for_review: true` with no screenshots/metadata ever uploaded, regardless of `deliver`'s local-file behavior | Low–Medium (either populate `fastlane/metadata/` + `fastlane/screenshots/en-US/`, or explicitly set `skip_metadata: true` / `skip_screenshots: true` if metadata is intentionally managed only via the ASC web UI) | High — prevents a broken CI release lane from silently failing (or worse, submitting incomplete metadata) |

### #1 — No screenshots exist for any device
**What**: Zero App Store screenshot images anywhere in the repo (checked `fastlane/`, `assets/`, `design/`, `docs-site/`, and a repo-wide `*.png`/`*.jpg`/`*.jpeg` scan outside excluded/asset-catalog paths).
**Why it matters**: App Store Connect requires at least one screenshot per required device size class before a version can be submitted for review (Guideline 2.3.3 / ASC submission gate).
**Fix**: Capture at minimum one full set (2–10 images) at iPhone 6.9" or 6.5" for the `en-US` locale. Given demo mode exists specifically to produce realistic-looking data in the simulator (see HIGH-1 below), that's the natural capture path — but the DEMO MODE banner must be excluded from the final images.

### #2 — `release` lane will fail or partially submit with no local metadata/screenshots
**What**: `fastlane/Fastfile` lines defining lane `release` pass `skip_metadata: false` and `skip_screenshots: false` to `deliver`, with `submit_for_review: true`, but there is no `fastlane/metadata/`, no `fastlane/screenshots/`, and no `Deliverfile` anywhere in the repo.
**Why it matters**: If this is (or ever is) a first submission for this app record, App Store Connect cannot accept a review submission without screenshots — the lane will fail at the `deliver` step. If metadata/screenshots were instead entered by hand directly in the ASC web UI (unverifiable from this repo), the lane may "succeed" today, but the release process is then not reproducible or reviewable from version control, and a future contributor running this lane on a clean checkout will hit the same failure.
**Fix**: Either (a) populate `fastlane/metadata/en-US/` + `fastlane/screenshots/en-US/` and commit them so `deliver` has something real to push, or (b) if metadata/screenshots are intentionally managed by hand in ASC, change the lane to `skip_metadata: true, skip_screenshots: true` so the automation doesn't silently depend on state that lives outside the repo.

---

## HIGH Findings

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| No safeguard against the app's own "DEMO MODE" banner leaking into whatever screenshots get captured | High — this app was specifically built with a demo-data mode, making it the likely capture path | Would cause an actual App Store rejection (Guideline 2.3.3, misleading/inaccurate screenshot) if captured screenshots go out with the banner visible; also would look unprofessional if caught late | Low (one line of process discipline, or a UI-test flag to force-hide the banner during capture) | High — trivial to prevent, expensive to catch after the fact (resubmission cycle) |
| No `Snapfile`, no `SnapshotHelper.swift`, no XCUITest target wired for `fastlane snapshot` | Medium — makes screenshot capture entirely manual | Manual capture across 1–5 iPhone size classes × however many marketing images is slow and error-prone (inconsistent status bar/time, inconsistent data, easy to forget the demo-mode flag) | Medium (add a UI Test target, `SnapshotHelper.swift`, and a `Snapfile`) | Medium-High — pays off immediately and every future release cycle |

### #1 — DEMO MODE banner risk
**What**: `StressMonitorApp.swift` gates `DemoMode.isEnabled` on `ProcessInfo.processInfo.arguments.contains("-demo-mode")`, and `MainTabView.swift` renders `DemoModeBannerView()` as a persistent overlay whenever that's true. Demo mode exists precisely to produce dynamic, realistic-looking HRV/HR/sleep/activity data without a paired Watch — i.e., it's the most convenient way to get "good-looking" data into a simulator screenshot. Nothing in the repo (README, `docs/deployment-guide-release.md`, `docs/deployment-guide-environment.md`) warns that the `-demo-mode` launch argument must be OFF for real store captures.
**Why it matters**: A "DEMO MODE" pill visible in a submitted screenshot is a textbook Guideline 2.3.3 rejection (screenshot must reflect actual app experience, not a debug/demo overlay).
**Fix**: Add one line to the release/screenshot doc: "never capture App Store screenshots with `-demo-mode` enabled" — capture with real (or realistic seeded SwiftData) content instead. If demo data is still needed for consistent captures, that's fine, but the launch argument that triggers the banner must not be active during capture, or the banner view must be explicitly suppressed for the screenshot UI-test target.

### #2 — No fastlane snapshot / UI test screenshot automation
**What**: No `Snapfile`, no `SnapshotHelper.swift`, no XCUITest target referencing `snapshot(...)` calls exist in the `.pbxproj`.
**Why it matters**: Every screenshot has to be captured by hand, per device size, per locale, per release — the exact conditions under which inconsistent status bars, stale content, and (per #1) the demo banner slip through.
**Fix**: Standard fastlane `snapshot init`, add a `StressMonitorUITests` (or similar) target with `SnapshotHelper.swift`, write a UI test per screen that calls `snapshot("01Dashboard")` etc., configure `Snapfile` with the `en-US` locale and the target device(s) from the table above.

---

## MEDIUM Findings

- **`docs/deployment-guide-release.md`'s screenshot plan targets an outdated size class.** It specifies "iPhone 15 (6.1-inch)" as the capture device, but current App Store Connect accepts a single largest-size upload (6.9" or 6.5") that auto-scales down — 6.1" alone is no longer one of the ASC "master" fallback sizes. Not a live defect (no screenshots exist yet to be wrong), but if that doc is followed as-is, whoever captures screenshots first will need to re-capture at a larger size. Worth a one-line doc update whenever `docs/` gets touched next (flagged for awareness only, per instructions to skip `docs/` from asset scanning — not otherwise audited here).

---

## LOW Findings

- **Draft ASO copy exists but isn't wired into the fastlane pipeline.** `docs/aso/app-description.md` (126 lines) and `docs/aso/apple-editorial-checklist.md` (479 lines) contain drafted App Store description/keyword copy, but it has never been migrated into `fastlane/metadata/en-US/`. Not content-audited here (docs/ excluded from this audit's scope) — noted only as a pointer for whoever builds out CRITICAL-2's fix.

---

## Recommendations (priority order)

1. Decide whether `deliver`'s metadata/screenshots come from the repo (recommended, reproducible) or stay hand-managed in ASC — then either populate `fastlane/metadata/` + `fastlane/screenshots/` or set the `skip_*` flags accordingly in the `release` lane (CRITICAL-2).
2. Set up `fastlane snapshot` (Snapfile + UI test target) so screenshot capture is repeatable and consistent (HIGH-2) — do this before capturing anything by hand, since hand captures will need to be redone anyway once automated.
3. Capture and curate at least one full iPhone screenshot set (6.9" or 6.5", `en-US`, 2–10 images) with `-demo-mode` OFF and the DEMO MODE banner confirmed absent (CRITICAL-1 + HIGH-1).
4. Optionally add 1+ Apple Watch marketing screenshot (companion app, not required for submission).
5. Migrate `docs/aso/app-description.md` content into `fastlane/metadata/en-US/description.txt` etc. (LOW), checking it for placeholder text as part of that migration.
6. Re-run this screenshot validator once real assets exist, to catch dimension mismatches, placeholder content, and any demo-mode leakage before submission.

## Unresolved Questions

- Is there existing metadata/screenshot content already entered directly in App Store Connect for this app record? This repo has no way to verify that; if metadata/screenshots already exist there, CRITICAL-2's "will fail" characterization softens to "not reproducible from source control" rather than "will error."
- Is this the app's first submission, or an update to a previously-approved listing? First-submission vs. update changes how hard the "no screenshots" blocker bites (an update to an app that already has screenshots in ASC could, in theory, reuse existing ASC-side assets — but `deliver` with `skip_screenshots: false` and no local folder should be verified against the installed fastlane version's actual behavior before relying on it).

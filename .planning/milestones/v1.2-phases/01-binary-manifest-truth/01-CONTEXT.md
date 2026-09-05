# Phase 1: Binary & Manifest Truth - Context

**Gathered:** 2026-09-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Everything the shipped archive declares about itself is true: Apple's automated validation accepts the privacy manifest, all three targets agree on one App Group suite, Info.plist keys resolve from a single source (`INFOPLIST_KEY_*`), the Release binary leaks no credential, the widget either renders real data on a device or is not in the build, a Release archive is producible from the unmodified working tree (SPM-proxy migration complete), and CI's `fastlane match` readonly accepts the dual-cert profiles. Covers BUILD-01..03, AUTH-01, WIRE-01, ENV-04, ENV-05, and decisions D3 + D4 (resolved at this phase's discuss gate).

</domain>

<decisions>
## Implementation Decisions

### Privacy Contract & Manifest
- **D3 resolved: code is the contract.** `StressContextPayload`'s actual behavior (derived stress score/category/confidence/trend + per-factor scores under a Bearer-authenticated session; no raw HealthKit values) is the normative privacy statement. Root `CLAUDE.md` and the shipped privacy-policy wording are corrected to match — zero payload/code churn.
- Unused media dependencies (Giphy SDK, Kingfisher, exyte MediaPicker) are removed from the v1 build if grep shows no live references — closing privacy-manifest surface and App Review rejection risk.
- Required-reason API declarations (`NSPrivacyAccessedAPITypes`) are generated from a scan of APIs actually used (UserDefaults, file timestamps, etc.) and declared per target.
- Third-party SDK privacy manifests: verify each remaining SPM dependency ships its own; aggregate any gaps into the app target's manifest.

### Widget & App Group
- **D4 resolved: keep the widget and make it true.** It ships in TestFlight build 13 and its entitlement was wired in v1.0; removing a shipped surface right after external beta is a user-visible regression. WIRE-01 verified on a real device.
- Canonical App Group suite stays `group.com.stressmonitor.app` — audit all 3 targets for drift, no rename.
- WIRE-01 verification: physical-device widget gallery first; simulator gallery + documented human UAT as fallback evidence.
- Stale-data presentation: keep the v1.0 `WidgetDataState` fresh/stale/empty resolver behavior as-is — no redesign this phase.

### Build Config Truth
- Info.plist consolidation (BUILD-03): delete empty `Info.plist` files where the target supports generated plists; every key resolves from `INFOPLIST_KEY_*` build settings in the merged product plist.
- ENV-04: complete the user's in-flight SPM-cache proxy migration in place, preserving its direction (snapshot at `.asc/backup/spm-migration/`): add Firebase proxy products, give the GoogleSignIn proxy a non-colliding product name. Do NOT revert to HEAD package references.
- AUTH-01: run the `strings` check against the build-13 IPA in `.asc/artifacts/` as an immediate baseline, then re-run against the Phase-1-final archive as the gate.
- ENV-05: push `gsd/v1.2-submission-readiness` to origin after Phase 1 commits land to trigger the CI run that validates `fastlane match` readonly against the dual-cert profiles. Branch push only; `main` untouched.

### the agent's Discretion
Implementation details not covered above (scan tooling choice, exact plist key mapping, proxy package structure) are the executor's discretion within repo conventions.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Per-bundle `PrivacyInfo.xcprivacy` files already exist across all three compiled targets (wired v1.0 Phase 1) — extend, don't recreate.
- `WidgetDataState` resolver (fresh/stale/empty) with unit tests — v1.0 deliverable, behavior frozen per decision above.
- Build-13 Release IPA + `.xcarchive` at `.asc/artifacts/` — AUTH-01 baseline artifact; no rebuild needed for the baseline pass.
- SPM migration snapshot at `.asc/backup/spm-migration/` (pbxproj + Package.resolved as the user left them).

### Established Patterns
- Runtime config: Info.plist build setting → process env → UserDefaults (`SupabaseConfig` precedent; keys now `STOREKIT_*`).
- Entitlements: both app + watch entitlements declare only `com.apple.developer.healthkit`; App Group lives in the entitlements wired v1.0.
- Signing: dual-cert App Store profiles (WTV47CUC2N + XPT2DHR688), local UUIDs 48ca5457 / 3def31a2 / 18db81c0.

### Integration Points
- `StressMonitor.xcodeproj/project.pbxproj` — 3 targets (app `stress.ai.com`, watch `.watchkitapp`, widget `.widget`); SPM package references; `INFOPLIST_KEY_*` settings.
- `.proxies/` spm-cache proxy packages — GoogleSignIn shim collides with upstream product name; Firebase proxies absent.
- CI: GitHub Actions `macos-15`/Xcode 26.3 (`.github/workflows/`) + Xcode Cloud `ci_scripts/`; Fastlane Match readonly on CI.

</code_context>

<specifics>
## Specific Ideas

- D3 doc fixes must list every overshoot: root `CLAUDE.md` ("HealthKit never sent" claim), EN/VI privacy policy, and any docs-site privacy prose.
- The proxy migration was mid-flight when the release session paused — treat `.asc/backup/spm-migration/` + working tree as one continuous piece of user work, not a fresh task.
- Match readonly must pass WITHOUT `setup_match` regeneration; if it fails, the documented fallback (one `setup_match` run, then re-swap dual-cert locally) requires user awareness.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

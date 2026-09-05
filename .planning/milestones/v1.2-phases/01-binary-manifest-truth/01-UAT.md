---
status: complete
phase: 01-binary-manifest-truth
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md, 01-06-SUMMARY.md]
started: 2026-09-03T21:30:00+07:00
updated: 2026-09-03T21:45:00+07:00
---

## Current Test

[testing complete]

## Tests

### 1. EN↔VI privacy-policy parity read
expected: Read docs-site/legal/privacy.md (EN) and docs-site/vi/legal/privacy.md (VI) side by side. Both describe the same contract: derived stress scores (never raw HealthKit values) sent to https://stress-api.dropitx.site under a Bearer-authenticated session via Firebase Auth (anonymous sign-in or Google Sign-In), with all five collected-data types (HealthAndFitness, PhotoVideo, OtherUserContent, DeviceID, ProductInteraction) listed for app functionality only, no tracking, and the VI phrasing reading naturally — not as a mechanical translation.
result: pass

### 2. Physical-device widget parity (WIRE-01)
expected: On a physical iPhone running a build with the wired save path: open the app (dashboard shows a live stress score), add the StressMonitor widget to the home screen, refresh the app, then check the widget. The widget shows the same stress level/tier the app dashboard shows after the refresh — a live value, not the "No Data" empty state. (Expected MATCH: the write path is wired and simulator evidence already shows same-tick parity; this closes WIRE-01 end-to-end.)
result: pass

### 3. verify-archive.sh artifact gate (01-01 D1)
expected: verify-archive.sh green on build-13 golden archive, red on planted secret
result: pass
source: automated
coverage_id: 01-01/D1

### 4. SPM proxy migration completed in place (01-01 D2)
expected: Firebase_proxy shims + collision-free renames + exact-revision pins verified by resolve/grep
result: pass
source: automated
coverage_id: 01-01/D2

### 5. Release archive producible from working tree (01-01 D3)
expected: Phase1-Verify.xcarchive ARCHIVE SUCCEEDED, passes gate incl. SDK privacy-manifest bundles
result: pass
source: automated
coverage_id: 01-01/D3

### 6. Watch manifest CA92.1 + 1C8F.1 (01-02 D1)
expected: All three manifests lint OK; watch reasons ["CA92.1","1C8F.1"]; app/widget untouched
result: pass
source: automated
coverage_id: 01-02/D1

### 7. CLAUDE.md backend contract truth (01-02 D2)
expected: Zero Supabase-era references; StressAPIClient → stress-api.dropitx.site under Firebase Auth
result: pass
source: automated
coverage_id: 01-02/D2

### 8. STOREKIT keys single-sourced (01-03 D1)
expected: Six keys byte-equal in merged product plist; dead build settings removed; build-13 key-set diff clean
result: pass
source: automated
coverage_id: 01-03/D1

### 9. Widget plist retained one-key (01-03 D2)
expected: NSExtensionPointIdentifier present in built .appex product
result: pass
source: automated
coverage_id: 01-03/D2

### 10. Dead Giphy build machinery removed (01-03 D3)
expected: Zero Giphy/Kingfisher/exyte references; app+widget builds green
result: pass
source: automated
coverage_id: 01-03/D3

### 11. One App Group suite ×3 targets (01-04 D1)
expected: group.stress.ai.com in all entitlements + 6 constants + test pin; gate ENTITLEMENTS PASS ×3
result: pass
source: automated
coverage_id: 01-04/D1

### 12. No extractable credential (01-04 D2)
expected: verify-archive gate exit 0 on Phase1-Final archive; benign allowlist documented; AIza only in plist resource
result: pass
source: automated
coverage_id: 01-04/D2

### 13. Draft PR + green clean CI (01-05 D1)
expected: PR #49 draft; CI run 33745603902 green (4/4 jobs) on clean hardware
result: pass
source: automated
coverage_id: 01-05/D1

### 14. Match readonly GREEN (01-05 D2)
expected: Run 33749862925: 3 profiles + cert installed, zero regeneration
result: pass
source: automated
coverage_id: 01-05/D2

### 15. ASC processing cleared (01-05 D3)
expected: TestFlight build 14 VALID, no ITMS-91053, no missing-SDK-manifest error
result: pass
source: automated
coverage_id: 01-05/D3

### 16. Live widget write trigger (01-06 D1)
expected: Guarded save in loadCurrentStress; 3 tests RED→GREEN (keys, integration, dedupe)
result: pass
source: automated
coverage_id: 01-06/D1

### 17. Frozen contracts byte-identical (01-06 D2)
expected: Range-diff over frozen set = 0 lines
result: pass
source: automated
coverage_id: 01-06/D2

### 18. Full-suite regression green (01-06 D3)
expected: 217 tests / 40 suites TEST SUCCEEDED
result: pass
source: automated
coverage_id: 01-06/D3

### 19. Simulator same-value widget evidence (01-06 D4)
expected: Same-tick machine-read: dashboard "Elevated" + widget "Tense" both derive from latest_stress_level 73.19
result: pass
source: automated
coverage_id: 01-06/D4

## Summary

total: 19
passed: 19
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]

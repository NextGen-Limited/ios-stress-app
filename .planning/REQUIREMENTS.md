# Requirements: StressMonitor — v1.2 Submission Readiness

**Defined:** 2026-09-03
**Core Value:** Every feature that ships in the binary must actually work end-to-end for a real user — not just compile. This milestone closes the remaining gaps between "shipped to TestFlight" and "submittable to App Review."

## v1 Requirements

Requirements for v1.2. Each maps to roadmap phases.

### Build Configuration

- [ ] **BUILD-01**: Privacy manifest (`PrivacyInfo.xcprivacy`) passes ASC upload validation (requires decision D3: privacy contract authority)
- [ ] **BUILD-02**: One canonical App Group suite ID across app, widget, and watch targets
- [ ] **BUILD-03**: Info.plist consolidated onto `INFOPLIST_KEY_*` build settings
- [ ] **BUILD-04**: CI and dev docs pin `-parallel-testing-enabled NO` (residual — suite itself green since v1.1 TEST-01)

### Data Integrity

- [ ] **DATA-01**: Two-device CloudKit-propagation delete verified end-to-end (residual — local, Keychain, App-Group, and server-session halves verified separately)
- [ ] **DATA-04**: Regression test pins the v1.0 CR-01 CloudKit batch-delete failure propagation (needs a test seam below `CloudKitResetServiceProtocol`)

### Auth

- [ ] **AUTH-01**: Empirical `strings` check of the Release binary finds no extractable credentials (`#if DEBUG` fix shipped; the empirical confirmation remains)

### Widget Wiring

- [ ] **WIRE-01**: Widget renders live stress data on a real device, not placeholder (requires decision D4: widget in v1)

### Ship Readiness

- [ ] **SHIP-01**: App Store screenshot set captured with demo mode disabled
- [ ] **SHIP-02**: Fastlane `release` lane matches actual readiness (metadata-only upload path)
- [ ] **SHIP-03**: ASC privacy questionnaire answered consistent with the actual `/chat` payload (requires decision D3)

### Accessibility

- [ ] **A11Y-01**: All touch targets meet the 44pt minimum
- [ ] **A11Y-02**: Color contrast passes WCAG AA on primary surfaces
- [ ] **A11Y-03**: Reduce Motion respected for animated views
- [ ] **A11Y-04**: Dynamic Type adopted on primary screens
- [ ] **A11Y-05**: Orphaned redesign views deleted

### Environment Debt

- [ ] **ENV-01**: WINDOWS.md #8 CoreSimulator cold-launch crash lineage documented and accepted (or fixed)
- [ ] **ENV-02**: `CharacterEntitlementSyncTests` quarantine resolved — root cause diagnosed and tests restored, or permanent skip documented with rationale
- [ ] **ENV-03**: WR-03 (DEBUG money path uses MockStoreKitService) and WR-04 (`.unverified` consumables finished) advisories dispositioned — fixed or documented accept

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Documentation

- **DOCS-01**: Nyquist VALIDATION.md files for v1.1 phases 1-3 reconciled via validate-phase (optional per #2117 — coverage TODO, not compliance failure)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| v1.1 product features (coherent breathing patterns, stress-triggers tracking, weekly digest, localization) | Not submission blockers; per `docs/project-roadmap.md` |
| v2.0 concept features (ML/CoreML stress prediction, iPad app, Siri Shortcuts) | Explicitly future per roadmap |
| Dedicated watchOS/Widget unit-test targets | Deferred unless trivially reachable while wiring BUILD-04 |
| Multi-locale App Store listing | Single-locale first submission is deliberate |
| Automating Fastlane `deliver` for release submission | SHIP-02 takes the manual ASC path for this first release; automation after one hand-exercised cycle |
| Legacy duplicate source tree / nested duplicate `.xcodeproj` cleanup (~5k dead lines) | Real debt, orthogonal to submission readiness; candidate for a later milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUILD-01 | — | Pending |
| BUILD-02 | — | Pending |
| BUILD-03 | — | Pending |
| BUILD-04 | — | Pending |
| DATA-01 | — | Pending |
| DATA-04 | — | Pending |
| AUTH-01 | — | Pending |
| WIRE-01 | — | Pending |
| SHIP-01 | — | Pending |
| SHIP-02 | — | Pending |
| SHIP-03 | — | Pending |
| A11Y-01 | — | Pending |
| A11Y-02 | — | Pending |
| A11Y-03 | — | Pending |
| A11Y-04 | — | Pending |
| A11Y-05 | — | Pending |
| ENV-01 | — | Pending |
| ENV-02 | — | Pending |
| ENV-03 | — | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19 ⚠️ (roadmapper assigns)

---
*Requirements defined: 2026-09-03*
*Last updated: 2026-09-03 after initial definition*

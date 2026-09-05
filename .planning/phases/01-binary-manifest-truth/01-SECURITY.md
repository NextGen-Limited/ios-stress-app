---
phase: 1
slug: binary-manifest-truth
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-09-03
---

# Phase 1 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| working tree → SPM network resolution | swift package resolve fetches firebase-ios-sdk from github.com | signed source at pinned revision |
| pbxproj → Xcode dependency graph | 3-place proxy rename resolves atomically or breaks builds | build configuration |
| local binary → extraction (attacker with IPA) | credential-scan models strings over the shipped artifact | any embedded secret would cross |
| declared manifest ↔ ASC validation | under-declaration is an ITMS-91053 rejection | privacy declarations |
| public privacy prose ↔ actual payload | prose must match StressContextPayload's derived-score behavior | privacy claims |
| plist file + build settings → merged product plist | wrong deletions starve runtime key consumers | StoreKit product config |
| shipped binary → extraction | same as above, per-bundle entitlements | entitlements blob |
| local repo → origin/CI → ASC + match secrets | CI runners hold distribution credentials | signing material |
| match git repo ↔ Apple portal | dual-cert mirror state is what ENV-05 tests | profiles/certs |
| user approval → TestFlight visibility | upload_beta is externally visible | binary artifact |
| HealthKit → pipeline → App Group suite → widget | trigger lengthens an existing on-device path; suite is same-team only | derived stress values (local) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Tampering (supply chain) | SPM network fetch of firebase-ios-sdk | high | mitigate | Exact-revision pin fdc352faba… in shim + umbrella; Package.resolved regains 11.15.0; no floating requirements | closed — pins grep-verified, clean-CI resolve green |
| T-01-02 | Tampering | Proxy product rename (3-place atomic) | medium | mitigate | Shim + proxy root + pbxproj in one change; resolve check after | closed — commits feb3bf1/1afb401, resolve green |
| T-01-03 | Information Disclosure | verify-archive.sh echoing secret material | low | accept | Script prints pattern names/paths, never matched content | closed (accepted) |
| T-01-04 | DoS | Migration half-done → no archive | medium | mitigate | Task 3 archive gate is definition of done | closed — Phase1-Verify + Phase1-Final archives pass gate |
| T-02-01 | Repudiation (compliance) | Watch manifest missing CA92.1 | high | mitigate | Scan-then-declare; plutil lint | closed — reasons ["CA92.1","1C8F.1"], build 14 VALID |
| T-02-02 | Tampering | Docs drifting from code truth | medium | mitigate | read_first pins normative sources; zero-code-churn proof | closed — payload byte-identical |
| T-02-03 | Info Disclosure (false assurance) | Privacy prose overstating privacy | medium | mitigate | Prose aligned with payload + manifest entries | closed — 5 types both locales, UAT parity pass |
| T-03-01 | Tampering (silent drift) | Merged-plist key loss | high | mitigate | Byte-equal plutil assertions ×6 + build-13 key-set diff | closed — all six keys equal, diff clean |
| T-03-02 | DoS | Widget ext fails without NSExtensionPointIdentifier | medium | mitigate | Empirical check; retained-file fallback | closed — key present in built .appex |
| T-03-03 | Tampering | Dead Giphy script phase surviving | medium | mitigate | Definition+reference+markers deleted; zero greps | closed — pbxproj greps 0, builds green |
| T-04-01 | Information Disclosure | Credential extractable from Release binary (AUTH-01 anchor) | critical | mitigate | §7 strings pipeline + verify-archive gate + triage + report.xml check | closed — gate exit 0 on Phase1-Final, allowlist documented |
| T-04-02 | Elevation/DoS | Entitlement confusion (build-12 class) | high | mitigate | Per-bundle chain: plutil ×3 + codesign dump + suite tests | closed — ENTITLEMENTS PASS ×3, tests green |
| T-04-03 | Spoofing | Demo data as live evidence | low | mitigate | Mandatory demo-mode disclosure in evidence | closed — disclosure present §8 |
| T-05-01 | Tampering | Match repo cert handling / silent regeneration | high | mitigate | readonly only routine path; fallback user-gated | closed — readonly green, zero regeneration, fallback unused |
| T-05-02 | Information Disclosure | CI secrets in logs/report.xml | medium | mitigate | report.xml + artifact review before verdict | closed — clean (01-04 task 2, 01-05 log scan) |
| T-05-03 | Spoofing | False ENV-05 pass | medium | mitigate | Run URL + match log excerpt required in record | closed — 01-ENV-05-CI-RECORD.md |
| T-05-04 | Elevation (process) | TestFlight build without consent | high | mitigate | blocking checkpoint precedes dispatch; approval pre-timestamp | closed — approval recorded before 11:28:20Z dispatch |
| T-06-01 | Tampering (integrity) | Duplicate saves skew statistics | medium | mitigate | lastPersistedReadingDate set synchronously before await; pinned test | closed — same-reading-twice test green |
| T-06-02 | Information Disclosure | Suite now holds real derived values | low | accept | Same-team App Group; no new egress; /chat untouched | closed (accepted) |
| T-06-03 | DoS (resource) | reloadAllTimelines on every save | low | mitigate | Reload rides dedupe guard; demo cadence compiled out of Release | closed |
| T-06-04 | Spoofing (evidence) | Demo data as live evidence | low | mitigate | Standing disclosure; machine-verified writes | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-03 | T-01-03 | verify-archive.sh output trusted-local-operator triage; prints patterns not content | plan 01-01 threat model | 2026-09-03 |
| AR-01-06 | T-06-02 | Device-local same-team App Group holding derived scores; no egress change | plan 01-06 threat model | 2026-09-03 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-03 | 18 | 18 | 0 | verify-work verify:post (ASVS L1, plan-time register, all mitigations verified against executed evidence) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-03

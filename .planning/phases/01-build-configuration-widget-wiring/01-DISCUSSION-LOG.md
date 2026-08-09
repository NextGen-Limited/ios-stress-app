# Phase 1: Build Configuration & Widget Wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-08
**Phase:** 1-Build Configuration & Widget Wiring
**Areas discussed:** Privacy Contract Authority (D3), Widget Scope (D4), Build Configuration Details (auto-resolved)

---

## Privacy Contract Authority (D3)

| Option | Description | Selected |
|--------|-------------|----------|
| Backend contract is authoritative | Keep sending derived stress-context to chat backend; correct docs and ASC disclosure | ✓ |
| On-device claim is authoritative | Strip raw biometrics from the chat payload; keep the existing privacy promise true | |

**User's choice:** Backend contract is authoritative.
**Notes:** Resolves the CLAUDE.md-vs-StressContextPayload.swift contradiction flagged independently by both the remediation audit and `.planning/codebase/CONCERNS.md`. Chosen over stripping the payload to preserve chat coaching quality; the cost is corrected docs and an honest ASC privacy nutrition label declaration in BUILD-01/SHIP-03.

---

## Widget Scope (D4)

| Option | Description | Selected |
|--------|-------------|----------|
| Ship it — wire live data | Wire WidgetDataProvider to live data this phase (WIRE-01 stays in scope) | ✓ |
| Exclude the widget target for v1 | Drop WIRE-01, remove the extension from the release build | |

**User's choice:** Ship it — wire live data.
**Notes:** Widget is an advertised feature in README/project-roadmap.md; excluding it would be a regression from what's already marketed. Recommended option, confirmed by user.

---

## Build Configuration Details (auto-resolved, not asked)

| Item | Selected | Rationale |
|------|----------|-----------|
| Canonical App Group suite ID | `group.stress.ai.com` | Matches actual bundle ID prefix `stress.ai.com`; other two candidates are legacy/disconnected names |
| Test framework for BUILD-04 | Swift Testing (new tests), XCTest only where lifecycle already exists | Already the established convention per `.planning/codebase/TESTING.md` — confirmed, not reopened |
| Info.plist consolidation | Delete orphaned `StressMonitor/Info.plist`, standardize on `INFOPLIST_KEY_*` | Matches the project's existing live build-settings pattern; plan already specified this |

**Notes:** These were auto-resolved per `--auto` mode's single-pass design (low-stakes, reversible, or already-established conventions) rather than escalated to the user, unlike D3/D4 above which are genuine product/compliance decisions.

---

## Claude's Discretion

- Widget "no data" staleness threshold (exact minutes) — left to planning.
- New unit-test target naming — reuse existing `StressMonitorTests` product-reference name unless it conflicts.

## Deferred Ideas

None — discussion stayed within Phase 1 scope. D1, D2, and the two IAP product questions are explicitly out of scope here and belong to later phases' discuss-phase runs.

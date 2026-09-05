---
status: testing
phase: 02-delete-correctness-test-suite-trust
source: [02-VERIFICATION.md]
started: 2026-09-04T07:20:00Z
updated: 2026-09-04T07:20:00Z
audit_acknowledged:
  milestone: v1.2
  at: 2026-09-05
  gap_snapshot: "testing::scenarios=1"
---

## Current Test

number: 1
name: DATA-01 live two-surface CloudKit delete verification
expected: |
  All enumerated record types reach stable-empty (two consecutive zero-count rounds)
  within a documented, measured propagation delay after the factory-reset trigger.
  If any type (especially the newly-fixed Habit mirror) remains non-empty after
  several stable-empty rounds for the others, that is a live finding to record, not a pass.
awaiting: user response

## Tests

### 1. DATA-01 live two-surface CloudKit delete verification

expected: |
  On a physical iPhone signed into the team iCloud account (container
  iCloud.stress.ai.com), seed real data across every swept model (StressMeasurement,
  an unlocked CharacterUnlock, a logged Habit), trigger Settings → Data Management →
  Factory Reset, then poll the CloudKit Console private database (or a second
  physical iPhone if available) per record type — including live enumeration of the
  NSPersistentCloudKitContainer-mirrored types for CharacterUnlock/Habit — at a fixed
  interval until two consecutive rounds read zero rows for every type. Fill in
  02-DATA-01-EVIDENCE.md §2 (environment) and §4 (timestamped poll-round table +
  computed propagation delay).
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

- Execution reminders (from 02-SECURITY.md T-02-12, low): redact account identifiers
  from any screenshot before filing; the evidence note's screenshots must show
  record-type queries, not account pages.

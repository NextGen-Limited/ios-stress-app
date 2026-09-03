# Privacy Policy

*Last updated: 2026-08-09*

## Overview

StressMonitor is committed to protecting your privacy. All health data is processed locally on your device. We do not sell or rent your personal information.

## Data We Access

- **Heart Rate Variability (HRV)** — read-only from Apple Health
- **Resting Heart Rate** — read-only from Apple Health
- **Calculated Stress Scores** — computed on-device, stored locally via SwiftData

## Data We Do Not Collect

- Raw HealthKit readings are never transmitted to our servers — the only exception is the derived data described in "AI Coaching Chat" below
- No third-party analytics or advertising trackers
- No advertising identifiers
- HealthKit data is never used for advertising or marketing

## iCloud Sync

If you enable iCloud sync, your stress history syncs across your own Apple devices via CloudKit. This data is end-to-end encrypted by Apple. We cannot access it.

## AI Coaching Chat

When you open AI Coaching Chat, the app sends derived values to StressMonitor's backend to generate a coaching response: your stress score, stress category, confidence, trend, and a per-factor breakdown of normalized HRV, heart rate, sleep, activity, and recovery scores. Raw HealthKit sample values (e.g. exact HRV readings in milliseconds, exact heart rate in bpm) are never included.

This request carries an authenticated session (a Bearer JWT, established via Firebase Auth — anonymous sign-in or Google Sign-In). Chat messages and this derived context are retained according to the backend's own chat-history retention policy, separate from the on-device health store described above.

## HealthKit

StressMonitor has **read-only** access to HealthKit. We never write data back to Apple Health.

## Data Retention

All data is stored on your device. You can delete all data at any time from StressMonitor → Settings → Data Management → Delete All Data.

## Children

StressMonitor is not directed to children under 18.

## Changes

We may update this policy. Continued use of the app after changes constitutes acceptance.

## Contact

privacy questions: **support@stressmonitor.app**

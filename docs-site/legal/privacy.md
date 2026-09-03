# Privacy Policy

*Last updated: 2026-09-03*

## Overview

StressMonitor is committed to protecting your privacy. All health data is processed locally on your device. We do not sell or rent your personal information.

## Data We Access

- **Heart Rate Variability (HRV)** — read-only from Apple Health
- **Resting Heart Rate** — read-only from Apple Health
- **Calculated Stress Scores** — computed on-device, stored locally via SwiftData
- **Photos & Videos** — only the photos or videos you choose to share in AI Coaching Chat; sent with your message to generate a response (see "AI Coaching Chat")
- **Chat Message Content** — messages you send in AI Coaching Chat, retained under the backend's chat-history retention policy (see "AI Coaching Chat")
- **Device & App Identifiers** — device and app identifiers transmitted to Google (Firebase Auth / Google Sign-In) strictly for authentication and app functionality; never used for tracking or advertising
- **Product Interaction** — basic app-interaction data (for example, which features are used) shared via Google Firebase for app functionality; never used for tracking or advertising

## Data We Do Not Collect

- Raw HealthKit readings are never transmitted to our servers — the only exception is the derived data described in "AI Coaching Chat" below
- No third-party analytics or advertising trackers (Google/Firebase is used for sign-in only — see "Device & App Identifiers" above)
- No advertising identifiers
- HealthKit data is never used for advertising or marketing

## iCloud Sync

If you enable iCloud sync, your stress history syncs across your own Apple devices via CloudKit. This data is end-to-end encrypted by Apple. We cannot access it.

## AI Coaching Chat

When you open AI Coaching Chat, the app sends derived values to StressMonitor's backend to generate a coaching response: your stress score, stress category, confidence, trend, and a per-factor breakdown of normalized HRV, heart rate, sleep, activity, and recovery scores. Raw HealthKit sample values (e.g. exact HRV readings in milliseconds, exact heart rate in bpm) are never included.

This request carries an authenticated session (a Bearer JWT, established via Firebase Auth — anonymous sign-in or Google Sign-In). Chat messages and this derived context are retained according to the backend's own chat-history retention policy, separate from the on-device health store described above. If you attach a photo or video in chat, it is sent with your message and covered by the same retention policy.

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

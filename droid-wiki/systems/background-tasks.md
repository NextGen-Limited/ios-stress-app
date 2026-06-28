# Background tasks and notifications

Background refresh for stress measurements and local notifications for stress alerts. iOS keeps the app's data fresh when it is not in the foreground and posts notifications when stress crosses a threshold.

## Key abstractions

| Type | File | Description |
| --- | --- | --- |
| `HealthBackgroundScheduler` | `StressMonitor/StressMonitor/Services/Background/HealthBackgroundScheduler.swift` | Registers and schedules `BGAppRefreshTask` instances. |
| `NotificationManager` | `StressMonitor/StressMonitor/Services/Background/NotificationManager.swift` | Requests authorization and schedules local notifications. |

## Background app refresh

`HealthBackgroundScheduler` registers a `BGAppRefreshTask` request identifier with `BGTaskScheduler`. When the system wakes the app, the handler fetches the latest HealthKit samples, runs the stress calculation pipeline, saves the measurement through `StressRepository`, and updates the widget snapshot in the App Group. The system decides when refresh actually fires based on battery, usage patterns, and Low Power Mode state.

The Background Modes capability must be enabled in the app target's Signing & Capabilities with "Background fetch" checked. Without it, `BGTaskScheduler` rejects registration.

## Notifications

`NotificationManager` requests `UNAuthorizationOptions` (alert, sound, badge) and schedules `UNTimeIntervalNotificationTrigger` or `UNCalendarNotificationTrigger` for stress alerts. Notifications are local only; no push server is involved.

Typical triggers:

- Stress level crossing into `high` or `severe` for the first time in a session.
- A breathing exercise suggestion after sustained elevated HR.
- Daily morning readiness summary.

## Entry points for modification

- **Add a new background task**: declare a new `BGTaskRequest` identifier, register it in `HealthBackgroundScheduler`, and add a case to the handler closure.
- **Add a new notification trigger**: add a scheduling method to `NotificationManager` and call it from the relevant ViewModel state change.

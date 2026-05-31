# Watch Face Not Updating Automatically

Due to Apple Watch system limitations, all watch face complications may experience delays. **A lag of up to 15–30 minutes is normal** — Apple Watch does not update complications in real time to conserve battery. Developers cannot directly control complication refresh rates.

If the complication hasn't updated for several hours, or only updates when you open the Watch app, follow this checklist:

## Step 1: Verify Health Data Is Flowing

Can the iPhone app display current HRV data?

- **iPhone:** Settings → Privacy & Security → Health → StressMonitor → ensure all data types are enabled
- **Apple Watch:** Settings → Health → Data Sources & Access → Apps & Services → StressMonitor → enable all data types

## Step 2: Verify Notifications Are Working

If you receive stress notifications on your iPhone, the data pipeline is working. If not, see [Notification Issues](../user-guide/notifications-troubleshoot) first — fixing notifications usually resolves complication updates too.

## Step 3: Enable Background App Refresh on Watch

On Apple Watch: **Settings → General → Background App Refresh** → enable for StressMonitor.

Despite Apple's documentation suggesting this doesn't affect complications, testing shows it does impact update frequency.

## Step 4: Restart Your Watch

If all settings are correct but the complication still won't update, restart your Apple Watch. This is especially common on watchOS 10.

## iPhone Home Screen Widget Not Updating

If the iPhone widget is stale:

1. Open StressMonitor and wait for the dashboard to refresh
2. Return to your home screen — the widget should update within a few minutes

If still stuck, remove and re-add the widget: long-press home screen → **–** to remove → **+** to add again.

Also ensure **Settings → General → Background App Refresh** is enabled for StressMonitor.

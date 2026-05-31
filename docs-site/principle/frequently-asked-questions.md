# Frequently Asked Questions

Apple Watch and iOS have certain limitations and known bugs. Issues such as complication refresh delays and HRV collection frequency are often caused by watchOS or iOS system constraints — not StressMonitor bugs.

## HRV & Data

**Why isn't my HRV data updating?**

Apple Watch records HRV approximately every 2–5 hours when worn properly. Data collection stops when:
- Low Power Mode is enabled
- An exercise session is active
- You are in a high-movement state
- The watch is not worn securely or is locked
- watchOS is version 7 or earlier

Check the Health app directly — if heart rate data is stuck at one timestamp, your watch and iPhone may have lost connection or your watch may need a restart.

**Why is real-time stress data not updating?**

Real-time stress is calculated from recent heart rate and HRV data. New users need 3–7 days to accumulate sufficient baseline data. Frequent movement automatically excludes data from calculations (marked as "Frequent Movement" on graphs).

**Can I delete HRV data?**

Yes. In the Health app: Heart → Heart Rate Variability → Show All Data → swipe to delete individual entries.

## Watch Face & Complications

**Why is my complication blank after adding it?**

This is usually a temporary issue after the watch app installs or updates. If elements remain missing, configure the watch face directly on your Apple Watch rather than through the iPhone Watch app — long-press the watch face, tap Edit, then add the StressMonitor complication from the Complications tab.

**Why does the watch face update slowly?**

Apple Watch complications do not update in real-time. A delay of up to 30 minutes is normal and outside developers' control. If the face hasn't updated for several hours, ensure:
- Health permissions are enabled for StressMonitor on both iPhone and Watch
- Background App Refresh is on for StressMonitor
- Stress notifications are being received (indicates the pipeline is working)

## Permissions & Background Refresh

**Do I really need to enable Background App Refresh?**

Yes. Many StressMonitor features — including notifications and complication updates — require Background App Refresh to function. The app is optimized to minimize battery consumption.

Enable it at: **Settings → General → Background App Refresh → StressMonitor**

**The app keeps asking me to enable Health permissions.**

Go to **Settings → Privacy & Security → Health → StressMonitor** and enable all data types. Also check your Apple Watch: **Settings → Health → Data Sources & Access → StressMonitor**.

## Stress Knowledge

**Can StressMonitor monitor emotional or cognitive stress?**

No. StressMonitor monitors physical stress using HRV and heart rate data. While emotional and cognitive stress often manifest as physical stress responses, the app cannot directly detect mental or emotional states.

**What does a Stress Overload notification mean?**

Your physical stress indicators (HRV and resting heart rate) have moved significantly from your personal baseline into the high-stress range. Consider rest, hydration, and reducing activity. Notifications are informational — not medical diagnoses.

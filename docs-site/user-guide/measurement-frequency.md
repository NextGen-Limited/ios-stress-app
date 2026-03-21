# Measurement Frequency & Manual Measurement

## Automatic Measurement Frequency

Under normal circumstances, Apple Watch automatically measures HRV every **2 to 5 hours**. StressMonitor reads this data from Apple Health — it does not independently control sensor sampling.

Apple Watch pauses automatic HRV monitoring when:
- Low Power Mode is enabled
- A workout session is active
- You are in a high-movement state
- The watch is not worn securely or is locked
- watchOS 7 or earlier is installed

> **Note:** As developers, we cannot adjust the Apple Watch's built-in HRV monitoring frequency.

## Increasing Monitoring Frequency (Optional)

For users outside mainland China, you can prompt Apple Watch to check HRV every ~15 minutes by enabling **AFib History**:

1. Open the **Health** app on iPhone → Heart → AFib History → Enable
2. Open the **Watch** app → Heart → AFib History → Enable

Be aware this increases battery consumption. This is currently the only way to increase Apple Watch HRV sampling frequency.

## Manual Measurement

To trigger an immediate HRV reading:

1. Open the **Mindfulness** app on your Apple Watch
2. Start a **Breathe** session — select **3 minutes or longer** for accuracy
3. Ensure the watch is fitted snugly; keep your body still and breathe naturally (don't follow the guide rhythm)
4. After the session completes, lock then unlock your iPhone
5. Wait about 1 minute — StressMonitor will receive the data and update

> Due to Apple Watch limitations, data may occasionally take longer to appear. If it hasn't updated after 30 minutes, try again later.

### Best Time to Measure Manually

We recommend measuring **within 10 minutes of waking up**, before food, coffee, exercise, or social activity. This captures your true baseline state.

Ideal conditions:
- Sitting or lying down
- Minimal physical activity
- No recent large meals, alcohol, or caffeine
- Emotionally calm

### When to Avoid Manual Measurement

- Within 30 minutes of intense exercise (elevated HR interferes with results)
- When emotionally charged or stressed
- After consuming alcohol or caffeine
- After smoking or taking medication affecting heart rate

## Why Data May Appear Stale

HRV is most meaningful over longer sampling windows. If you check mid-afternoon without a recent rest period, the reading reflects an earlier measurement — this is expected behavior, not a bug.

If data hasn't updated for more than half a day, check:
- iPhone and Watch are connected
- Background App Refresh is enabled for StressMonitor
- Apple Watch has recent heart rate data in the Health app

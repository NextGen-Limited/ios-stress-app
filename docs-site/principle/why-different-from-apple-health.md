# Why Are HRV Values Different from Apple Health?

You may notice that the HRV number shown in StressMonitor differs from what you see in the Apple Health app. This is expected — the two apps use different HRV calculation methods.

## Apple Health Uses SDNN

Apple Health displays **SDNN** (Standard Deviation of Normal-to-Normal intervals) — the standard deviation of all normal heart rate intervals. SDNN reflects overall heart rate variability, capturing effects from both the sympathetic and parasympathetic nervous systems. Larger SDNN values generally suggest higher variability and stronger cardiac adaptability.

## StressMonitor Uses RMSSD

StressMonitor uses **RMSSD** (Root Mean Square of Successive Differences) — the square root of the average of squared differences between consecutive heartbeat intervals. RMSSD primarily measures parasympathetic nervous system activity and short-term recovery capacity.

## Key Differences

| | SDNN | RMSSD |
|---|------|-------|
| Scope | Overall HRV (long + short-term) | Short-term HRV only |
| Focus | All interval variations | Adjacent interval differences |
| Sensitivity | Longer timeframe changes | Short-term subtle changes |
| Best for | Overall cardiac autonomic assessment | Short-term stress status |

## Why StressMonitor Chose RMSSD

RMSSD is more sensitive than SDNN and better suited to capturing subtle, real-time changes in the body — making it a more appropriate indicator for short-term stress monitoring and alerts.

This is why the numbers look different. Both metrics are valid; they simply measure different aspects of heart rate variability.

# Entitlement Map — Free vs Premium

> **Design principle:** Soft paywall. Users can monitor their stress fully without paying.
> Premium unlocks advanced analytics, premium cosmetics, and convenience features — never core health monitoring.
>
> Strategy reference: StressWatch reached 5M installs by keeping core monitoring genuinely free.

## FREE — Core Experience (No Purchase Required)

| Feature | Details |
|---|---|
| **Stress Monitoring** | Full multi-factor stress score (HRV, HR, sleep, activity, recovery). Real-time, unlimited readings. |
| **Notifications** | All push notifications: stress alerts, daily check-ins, breathing reminders. No paywall. |
| **Ripple Character** | The default companion character (Ripple). Full interaction, mood reactions, breathing companion. |
| **Basic History** | 7-day stress history chart and timeline. Enough to see short-term patterns. |
| **Watch Complications** | All Apple Watch complications (circular, rectangular, inline). Real-time stress level on wrist. |
| **Breathing Exercises** | All guided breathing sessions. Core stress-reduction tool stays free. |
| **Mini Walks** | Action subscreen walks with Ripple companion. |
| **Health Data Sync** | HealthKit read/write. Core data flow never gated. |
| **Cloud Sync** | CloudKit backup and multi-device sync. |

## PREMIUM — Enhanced Experience (Subscription Required)

| Feature | Details | Why Premium |
|---|---|---|
| **AI Coach** | Context-aware AI stress coaching with personalized insights and recommendations. | LLM API cost per interaction. |
| **Advanced Trends** | 30-day and 90-day stress trend analysis, pattern detection, correlation insights. | Advanced analytics compute. |
| **Premium Characters** | Ember and Zephyr companion characters with unique animations and personalities. | Cosmetic content creation cost. |
| **Data Export** | Export stress data as CSV/PDF for sharing with healthcare providers. | Convenience + processing. |
| **Bio Age** | Biological age calculation from stress and recovery metrics. | Proprietary algorithm. |

## Subscription Plans

| Period | Price (default) | Product ID Key | Billing |
|---|---|---|---|
| **Weekly** | $6.99/week | `STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID` | Billed weekly — low-commitment entry point |
| **Monthly** | $19.99/month | `STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID` | Billed monthly |
| **Annual** | $179.88/year ($14.99/mo) | `STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID` | Billed annually — best value (25% savings) |

### Product ID Resolution Order

Product IDs resolve from (first wins):
1. `Bundle.main` Info.plist keys
2. `ProcessInfo.processInfo.environment` (CI-friendly)
3. `UserDefaults.standard` fallback keys

### Weekly Billing Rationale

StressWatch's $6.99/weekly plan drives higher trial-to-paid conversion because:
- Lower perceived commitment than monthly
- Aligns with short-term wellness sprints
- Cancels before the user forgets, improving perceived trust
- Captures impulse buyers who balk at $19.99/month

## Implementation Guidelines

### What to Lock (Premium Features)

Use `PremiumLockOverlay` **only** for:
- AI Coach entry point (`AIChatCard`, `AIInsightCard`)
- 30-day / 90-day trend views in `StressOverTimeChart` (7-day stays free)
- `BioAgeCardView`
- Ember/Zephyr character detail in `CharacterDetailView`
- Data export buttons
- Advanced trend correlation views in `TrendsView`

### What NOT to Lock (Core Features)

**Never** apply `PremiumLockOverlay` to:
- Stress score display (current reading, category badge)
- Stress monitoring / HealthKit data collection
- Notifications (any type)
- 7-day history chart
- Ripple character
- Watch complications
- Breathing exercises
- Mini walks
- Dashboard / home screen core cards

### Soft Paywall Verification Checklist

- [ ] A free user can see their current stress level without any paywall
- [ ] A free user can view 7 days of history
- [ ] A free user receives all notifications
- [ ] A free user can use all breathing exercises
- [ ] A free user has full Ripple character interaction
- [ ] A free user sees watch complications update
- [ ] Premium locks appear ONLY on AI Coach, 30/90-day trends, Bio Age, premium characters, data export
- [ ] No core monitoring feature is hidden behind a paywall

---

*Last updated: Soft Paywall Strategy implementation. See `StoreKitProductCatalog.swift`, `PremiumLockOverlay.swift`, `StressOverTimeChart.swift` for code-level enforcement.*

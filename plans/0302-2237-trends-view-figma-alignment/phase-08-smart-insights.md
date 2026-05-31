# Phase 8 — Smart Insights Teaser

**Priority:** Low | **Effort:** Small | **Status:** Completed

## Overview

Replace dynamic pattern insights with a static "Smart Insights — Coming Soon" teaser card matching Figma.

## Design Specs
- Title: "Smart Insights" (bold)
- Subtitle: "Personalized analysis based on your rhythm" (grey)
- Yellow "Coming Soon" pill button
- Cat mascot peeking from bottom-right corner

## New Component — SmartInsightsTeaser.swift

```swift
struct SmartInsightsTeaser: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Insights")
                    .font(Typography.title3)
                    .fontWeight(.bold)

                Text("Personalized analysis based on your rhythm")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                Button(action: {}) {
                    Text("Coming Soon")
                        .font(Typography.caption1.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FFD60A"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image("CharacterSleeping")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .offset(x: -8, y: 8)
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }
}
```

### TrendsView.swift
Replace insights section:
```swift
// OLD
if let insight = viewModel.weeklyInsight { ... }
ForEach(viewModel.patternInsights ...) { ... }

// NEW
SmartInsightsTeaser()
    .padding(.horizontal)
```

## Files
- **New:** `Views/Trends/Components/SmartInsightsTeaser.swift`
- **Modified:** `Views/Trends/TrendsView.swift` — replace insights with teaser

## Success Criteria
- "Smart Insights" card with "Coming Soon" yellow button
- Cat mascot visible in corner
- No dynamic insight cards shown

## Completion Notes

Completed 2026-03-02. New `SmartInsightsTeaser.swift` created: "Smart Insights" title, grey subtitle, disabled yellow `#FFD60A` "Coming Soon" capsule, `CharacterSleeping` peeking bottom-right at 60pt offset. `TrendsView.swift` insight section replaced — `weeklyInsight` and `patternInsights` blocks removed.

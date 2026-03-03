# Phase 3 — Mascot Speech Bubble

**Priority:** Medium | **Effort:** Small | **Status:** Completed

## Overview

Add conversational mascot section below premium banner. Small cat + speech bubble with prompt text.

## Design Specs
- Small cat mascot (left) — use `CharacterConcerned` or `CharacterCalm` asset, ~50pt
- White speech bubble (right) with subtle border
- Text: "I've been keeping an eye on your days! Want to see how stress changed this week?"

## New Component

### MascotSpeechBubbleView.swift
```swift
struct MascotSpeechBubbleView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("CharacterConcerned")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)

            Text(message)
                .font(Typography.caption1)
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderLight, lineWidth: 0.5)
                )
        }
    }
}
```

### TrendsView.swift
Add between PremiumBannerView and stressOverTimeCard:
```swift
MascotSpeechBubbleView(
    message: "I've been keeping an eye on your days! Want to see how stress changed this week?"
)
.padding(.horizontal)
```

## Files
- **New:** `Views/Trends/Components/MascotSpeechBubbleView.swift`
- **Modified:** `Views/Trends/TrendsView.swift` — add speech bubble

## Success Criteria
- Cat + speech bubble visible between premium banner and stress chart

## Completion Notes

Completed 2026-03-02. New `MascotSpeechBubbleView.swift` created. Uses `CharacterConcerned` (50pt), white card bubble with `borderLight` stroke, `caption1` text. Inserted in `TrendsView.swift` between `PremiumBannerView` and bar chart card.

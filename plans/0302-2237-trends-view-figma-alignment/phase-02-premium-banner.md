# Phase 2 — Redesign PremiumBannerView

**Priority:** High | **Effort:** Medium | **Status:** Completed

## Overview

Redesign to match Figma: light blue gradient background, large "UNLOCK PREMIUM" text, subtitle, orange "Upgrade Now" button, cat mascot illustration.

## Design Specs (from Figma)
- **Background:** Soft light blue gradient (top to bottom)
- **Title:** "UNLOCK PREMIUM" — large, uppercase, bold, blue text
- **Subtitle:** "Unlimited Access to premium features" — smaller, dark grey
- **CTA:** "Upgrade Now" — orange bg (#F39C12), white bold text, rounded pill shape
- **Mascot:** Large cat character on left side — use `CharacterCalm` asset
- **Sparkles:** Decorative elements around button (SF Symbols `sparkle` or skip)

## Changes

### PremiumBannerView.swift — Full rewrite
```swift
struct PremiumBannerView: View {
    var action: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "#B8E4F0"), Color(hex: "#D4F1F9")],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                // Cat mascot
                Image("CharacterCalm")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                Spacer()
            }

            // Content overlay
            VStack(spacing: 8) {
                Text("UNLOCK PREMIUM")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#1A6B8A"))

                Text("Unlimited Access to premium features")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                Button(action: action) {
                    Text("Upgrade Now")
                        .font(Typography.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#F39C12"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
    }
}
```

## Files Modified
- `Views/Trends/Components/PremiumBannerView.swift` — full redesign

## Assets Required
- `CharacterCalm` (exists in Assets.xcassets)

## Success Criteria
- Light blue gradient background visible
- Cat mascot on left/bottom area
- "UNLOCK PREMIUM" in bold blue
- Orange "Upgrade Now" pill button

## Completion Notes

Completed 2026-03-02. Full rewrite of `PremiumBannerView.swift`. Light-blue gradient bg (`#B8E4F0` → `#D4F1F9`), `CharacterCalm` mascot at bottom-left, sparkle SF Symbol decorations, "UNLOCK PREMIUM" title, subtitle, and orange `#F39C12` "Upgrade Now" capsule button.

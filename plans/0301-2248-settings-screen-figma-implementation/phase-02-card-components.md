# Phase 2: Card Components

<!-- Updated: Validation Session 1 - Added Lato font registration requirement -->

## Overview
Create reusable card components for the Settings screen using Lato custom font.

## Prerequisites

### Lato Font Registration
Ensure Lato font files are added to project:
- [x] Add `Lato-Regular.ttf` to Resources
- [x] Add `Lato-Bold.ttf` to Resources
- [x] Register in Info.plist under `UIAppFonts` key
- [x] Verify font loading with `UIFont.familyNames`

## Components to Create

### 1. SettingsCard (Base Container)

```swift
// Views/DesignSystem/Components/SettingsCard.swift

struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.settingsCardPadding)
            .background(Color.adaptiveCardBackground) // Dark mode support
            .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
            .shadow(
                color: Color(hex: "18274B").opacity(0.08),
                radius: 5.71,
                x: 0,
                y: 2.85
            )
    }
}
```

### 2. PremiumCard

```swift
// Views/Settings/Components/PremiumCard.swift

struct PremiumCard: View {
    var body: some View {
        SettingsCard {
            HStack(spacing: 23) {
                // Star icon (48x48)
                Image("premium-star")
                    .resizable()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium")
                        .font(.custom("Lato-Bold", size: 18))
                        .foregroundColor(.premiumGold)

                    Text("Upgrade to unlock all features")
                        .font(.custom("Lato-Regular", size: 13))
                        .foregroundColor(.textDescriptive)
                }

                Spacer()
            }
        }
    }
}
```

### 3. SectionHeader

```swift
// Views/Settings/Components/SettingsSectionHeader.swift

struct SettingsSectionHeader: View {
    let icon: String
    let iconImage: String? // SF Symbol or asset name
    let title: String

    var body: some View {
        HStack(spacing: 13) {
            if let imageName = iconImage {
                Image(imageName)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
            }

            Text(title)
                .font(.custom("Lato-Bold", size: 18))
                .foregroundColor(.accentTeal)
        }
    }
}
```

### 4. ComplicationWidget (Placeholder)

```swift
// Views/Settings/Components/ComplicationWidget.swift

struct ComplicationWidget: View {
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            // Widget preview (85x44)
            ZStack {
                RoundedRectangle(cornerRadius: 10.9)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.9)
                            .stroke(Color.widgetBorder, lineWidth: 0.91)
                    )

                // Placeholder content
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.widgetBorder)
                        .frame(width: 21, height: 21)

                    // Skeleton bars
                    RoundedRectangle(cornerRadius: 10.9)
                        .fill(Color.widgetBorder)
                        .frame(width: 31, height: 3.6)
                    RoundedRectangle(cornerRadius: 10.9)
                        .fill(Color.widgetBorder)
                        .frame(width: 25, height: 3.6)
                }
            }
            .frame(width: 85.6, height: 43.7)

            Text(title)
                .font(.custom("Lato-Regular", size: 13))
                .foregroundColor(.primary)
        }
        .frame(width: 147.5, height: 112.9)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderLight, lineWidth: 2)
        )
    }
}
```

### 5. AddComplicationButton

```swift
// Views/Settings/Components/AddComplicationButton.swift

struct AddComplicationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text("Add Complication")
            }
            .font(.custom("Lato-Bold", size: 14.9))
            .foregroundColor(.white)
            .frame(maxWidth: 277)
            .frame(height: 35.5)
            .background(Color.accentTeal)
            .clipShape(Capsule())
            .shadow(
                color: Color(hex: "18274B").opacity(0.08),
                radius: 5.71,
                x: 0,
                y: 2.85
            )
        }
    }
}
```

## Implementation Steps

- [x] 1. Create `Views/DesignSystem/Components/SettingsCard.swift`
- [x] 2. Create `Views/Settings/Components/` directory
- [x] 3. Create `PremiumCard.swift`
- [x] 4. Create `SettingsSectionHeader.swift`
- [x] 5. Create `ComplicationWidget.swift`
- [x] 6. Create `AddComplicationButton.swift`
- [x] 7. Create `ShareButton.swift` (similar to AddComplicationButton)
- [x] 8. Build and verify

## Status: ✅ Complete

## Files to Create

| File | Purpose |
|------|---------|
| `Views/DesignSystem/Components/SettingsCard.swift` | Base card container |
| `Views/Settings/Components/PremiumCard.swift` | Premium upgrade card |
| `Views/Settings/Components/SettingsSectionHeader.swift` | Section header |
| `Views/Settings/Components/ComplicationWidget.swift` | Widget placeholder |
| `Views/Settings/Components/AddComplicationButton.swift` | Add button |
| `Views/Settings/Components/ShareButton.swift` | Share button |

## Validation
- [x] Each component builds independently
- [x] Components match Figma dimensions (±2px)
- [x] Preview providers work in Xcode

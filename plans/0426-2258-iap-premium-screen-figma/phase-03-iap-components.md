# Phase 3: Build IAP Screen Components

**Priority:** High | **Effort:** Medium | **Status:** Pending

## Overview
Build the reusable SwiftUI components that compose the IAP Premium screen. Each component is self-contained and matches the Figma design spec.

## Key Insights
- Figma border radius: 20px cards/buttons, 8px icon buttons
- Shadow pattern matches existing `AppShadow` approach
- Color and typography tokens from Phase 1
- Each file must stay under 200 lines

## Related Code Files
- **Create:** `Views/Premium/Components/IAPNavBar.swift`
- **Create:** `Views/Premium/Components/IAPHeroSection.swift`
- **Create:** `Views/Premium/Components/PlanSelectionCard.swift`
- **Create:** `Views/Premium/Components/IAPCTAButton.swift`
- **Create:** `Views/Premium/Components/IAPUtilityRow.swift`

## Implementation Steps

### 3.1 IAPNavBar
File: `Views/Premium/Components/IAPNavBar.swift`

Custom nav bar replacing the default navigation title. Matches Figma:
- Left: Back button (36x36, rounded 8px, border `#9EA7B8`)
- Center: "Premium" text (Lato Bold 18, `#808080`)
- Right: Close button (36x36, rounded 8px, border `#9EA7B8`)

```swift
struct IAPNavBar: View {
    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Back button - 36x36, rounded 8px
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "5D6A85"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.iapIconBorder, lineWidth: 0.75)
                    )
            }
            Spacer()
            Text("Premium")
                .font(.custom("Lato-Bold", size: 18))
                .foregroundColor(Color.iapTextMuted)
            Spacer()
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "5D6A85"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.iapIconBorder, lineWidth: 0.75)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
```

**Note**: Figma right button uses same chevron-left — should be `xmark` (close). Flagged in analysis.

### 3.2 IAPHeroSection
File: `Views/Premium/Components/IAPHeroSection.swift`

Hero area with illustration + gradient tagline. The illustration is an SVG asset (meditation scene).

```swift
struct IAPHeroSection: View {
    var body: some View {
        VStack(spacing: 0) {
            // Meditation illustration (placeholder image asset)
            Image("iap-hero-illustration")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -50) // Extend beyond margins like Figma

            // Tagline with gradient
            Text("CARE FOR YOUR MENTAL BALANCE")
                .font(.custom("Lato-Black", size: 21))
                .kerning(-0.32)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.iapGradientStart, Color.iapGradientEnd],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
}
```

**Asset note**: The hero illustration is a complex SVG. Export from Figma as PNG @2x/@3x and add to Assets.xcassets. The image node ID is `4502:1777`.

### 3.3 PlanSelectionCard
File: `Views/Premium/Components/PlanSelectionCard.swift`

Selectable plan card matching Figma spec:
- White bg, 20px radius, 82px height
- Selected state: 2px amber border + "Best Value" badge
- Content: plan name, price, optional subtitle + savings

```swift
struct PlanSelectionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .top) {
                // Card content
                VStack(spacing: 4) {
                    // Top row: name + price
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.displayName)
                                .font(.custom("Lato-Bold", size: 13))
                                .foregroundColor(Color.iapTextPrimary)

                            if let subtitle = plan.subtitle {
                                Text(subtitle)
                                    .font(.custom("Lato-Regular", size: 11.5))
                                    .foregroundColor(Color.iapTextSecondary)
                            }
                        }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(plan.priceDisplay)
                                .font(.custom("Lato-Bold", size: 20))
                                .foregroundColor(Color.iapTextPrimary)
                            Text("/month")
                                .font(.custom("Lato-Regular", size: 11.5))
                                .foregroundColor(Color.iapTextSecondary)
                        }
                    }

                    // Bottom row: savings (if annual)
                    if let savings = plan.savingsDisplay {
                        HStack {
                            Spacer()
                            Text(savings)
                                .font(.custom("Lato-Bold", size: 12))
                                .foregroundColor(Color.iapSavingsGreen)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 19)
                .frame(maxWidth: .infinity, minHeight: 82)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(AppShadow.iapPlanCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.iapAmber : Color.clear, lineWidth: 2)
                )

                // "Best Value" badge (overlaps top border)
                if plan.isBestValue && isSelected {
                    Text("Best Value")
                        .font(.custom("Lato-Bold", size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 21)
                        .padding(.vertical, 5)
                        .background(Color.iapAmber)
                        .clipShape(Capsule())
                        .offset(y: -13)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
```

### 3.4 IAPCTAButton
File: `Views/Premium/Components/IAPCTAButton.swift`

Primary CTA button "Unlock Premium":
- Pill shape (20px radius), 242x40px
- Teal bg `#85C9C9`, white text centered
- Loading state with ProgressView

```swift
struct IAPCTAButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Unlock Premium")
                        .font(.custom("Lato-Bold", size: 14))
                        .kerning(-0.21)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 242, height: 40)
            .background(Color.iapCTATeal)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}
```

### 3.5 IAPUtilityRow
File: `Views/Premium/Components/IAPUtilityRow.swift`

Utility row button (Restore/Manage/History):
- 357x48px, white bg, 20px radius, shadow
- Layout: [icon] [label] [spacer] [chevron]

```swift
struct IAPUtilityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 13, height: 13)

                // Label
                Text(title)
                    .font(.custom("Lato-Medium", size: 13))
                    .kerning(-0.195)
                    .foregroundColor(Color.iapTextPrimary)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.iapChevronGray)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(AppShadow.iapUtilityRow)
        }
        .buttonStyle(.plain)
    }
}
```

## Success Criteria
- [ ] All 5 components render in previews without errors
- [ ] PlanSelectionCard shows correct selected/unselected states
- [ ] IAPCTAButton shows loading spinner when `isLoading = true`
- [ ] IAPUtilityRow matches Figma spacing (icon-label-gap-chevron)
- [ ] IAPNavBar has correct button sizes (36x36) and border radius (8px)
- [ ] Each file under 200 lines

## Risk Assessment
- **Medium risk**: Hero illustration asset must be exported from Figma
- **Low risk**: All components are pure UI, no business logic
- **Gradient text**: `.foregroundStyle(LinearGradient)` works on iOS 17+ — matches project target

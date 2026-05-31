# Phase 4: Build Main IAP Screen + Wire Navigation

**Priority:** High | **Effort:** Medium | **Status:** Pending

## Overview
Compose all IAP components into the main `IAPPremiumView` screen and wire navigation from `PremiumCard` in SettingsView. Also export the hero illustration from Figma.

## Key Insights
- SettingsView uses `.navigationDestination(isPresented:)` pattern — follow same approach
- PremiumCard currently shows "Set widget now!" — needs update to show "Premium" and navigate to IAP
- MainTabView already has NavigationStack wrapping content — no new nav container needed
- Screen is scrollable (390x1145px content vs ~844px viewport)
- `@AppStorage("isPremiumUser")` used across the app — PremiumViewModel must update this

## Related Code Files
- **Create:** `Views/Premium/IAPPremiumView.swift`
- **Modify:** `Views/Settings/Components/PremiumCard.swift`
- **Modify:** `Views/Settings/SettingsView.swift`
- **Modify:** `Views/Dashboard/Components/PremiumLockOverlay.swift` — wire to new IAP screen
- **Modify:** `Views/Dashboard/Components/PremiumBanner.swift` — wire to new IAP screen
- **Modify:** `Views/Trends/Components/PremiumBannerView.swift` — wire to new IAP screen
- **Asset:** Export hero illustration from Figma → `Assets.xcassets`

## Implementation Steps

### 4.1 Build Main IAP Screen
File: `Views/Premium/IAPPremiumView.swift`

Compose all components into scrollable screen matching Figma layout:

```swift
import SwiftUI

struct IAPPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumViewModel

    init(storeKit: StoreKitServiceProtocol) {
        _viewModel = State(initialValue: PremiumViewModel(storeKit: storeKit))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Nav bar
                IAPNavBar(onBack: { dismiss() }, onClose: { dismiss() })

                // Hero section (illustration + tagline)
                IAPHeroSection()
                    .padding(.top, 8)

                // Plan selection
                VStack(spacing: 24) {
                    Text("CHOOSE YOUR PLAN")
                        .font(.custom("Lato-Bold", size: 16))
                        .kerning(-0.24)
                        .foregroundColor(Color.iapHeaderTeal)

                    VStack(spacing: 11) {
                        ForEach(viewModel.plans) { plan in
                            PlanSelectionCard(
                                plan: plan,
                                isSelected: viewModel.selectedPlan == plan.id,
                                onSelect: { viewModel.selectedPlan = plan.id }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)

                // CTA + Utility section
                VStack(spacing: 20) {
                    IAPCTAButton(isLoading: viewModel.isLoading) {
                        Task { await viewModel.purchaseSelectedPlan() }
                    }

                    // Utility rows
                    VStack(spacing: 16) {
                        IAPUtilityRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .iapRestoreBlue,
                            title: "Restore Purchases"
                        ) {
                            Task { await viewModel.restorePurchases() }
                        }

                        IAPUtilityRow(
                            icon: "gearshape",
                            iconColor: .iapManageDark,
                            title: "Manage Subscriptions"
                        ) {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }

                        IAPUtilityRow(
                            icon: "receipt",
                            iconColor: .iapManageDark,
                            title: "Purchase History"
                        ) {
                            // Future: show purchase history sheet
                        }
                    }

                    // Terms & Privacy (App Store requirement)
                    VStack(spacing: 4) {
                        Text("Subscription auto-renews. Cancel anytime.")
                            .font(.custom("Lato-Regular", size: 11))
                            .foregroundColor(Color.iapTextSecondary)
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: DocsURL.terms.url)
                            Text("•")
                            Link("Privacy Policy", destination: DocsURL.privacy.url)
                        }
                        .font(.custom("Lato-Regular", size: 11))
                        .foregroundColor(Color.iapHeaderTeal)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 17)
                .padding(.top, 40)
            }
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task { await viewModel.loadInitialData() }
        .alert("Purchase Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
}
```

### 4.2 Export Hero Illustration from Figma
Use the Figma MCP to download the illustration:

- File key: `EHvjgTBOvThoVuk0cyE6tp`
- Node ID: `4502:1777` (the meditation illustration)
- Export as PNG @2x/@3x
- Add to `Assets.xcassets` as `iap-hero-illustration`

Alternatively, if the SVG is too complex, use the full IAP frame background illustration. Check quality during implementation.

### 4.3 Update PremiumCard
Modify `Views/Settings/Components/PremiumCard.swift`:
- Change text from "Set widget now!" to "Premium"
- Change subtitle from "Widgets that nudge you with insights" to "Unlock advanced features"
- Add tap action to navigate to IAP screen
- Add navigation state parameter

```swift
struct PremiumCard: View {
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            SettingsCard {
                HStack(spacing: 23) {
                    Image("premium-star")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 48, height: 48)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(-0.27)
                            .foregroundColor(.premiumGold)

                        Text("Unlock advanced features")
                            .font(.system(size: 13, weight: .regular))
                            .tracking(-0.195)
                            .foregroundColor(.textDescriptive)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textDescriptive)
                }
                .padding(.horizontal, 5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Premium. Unlock advanced features.")
    }
}
```

### 4.4 Wire Existing Premium Overlays to IAP Screen
<!-- Red Team Fix: Finding #1 — Primary conversion funnel was broken -->

The existing premium overlays (PremiumLockOverlay, PremiumBanner, PremiumBannerView) all need to navigate to the new IAP screen instead of showing dead-end views.

**Approach:** Add an `onUpgrade` closure parameter to each overlay/banner, similar to how `PremiumCard` gets `onTap`. The parent view passes the navigation trigger.

Files to modify:
- `Views/Dashboard/Components/PremiumLockOverlay.swift` — add `onUpgrade: () -> Void`
- `Views/Dashboard/Components/PremiumBanner.swift` — add `onUpgrade: () -> Void`
- `Views/Trends/Components/PremiumBannerView.swift` — add `onUpgrade: () -> Void`
- `Views/Dashboard/DashboardView.swift` — pass `navigateToPremium` to overlays
- `Views/Trends/TrendsView.swift` — pass navigation to PremiumBannerView

Each overlay's "Subscribe Now" / "Upgrade Now" button calls `onUpgrade()` instead of its current dead-end action.

### 4.5 Wire Navigation in SettingsView
Modify `Views/Settings/SettingsView.swift`:
- Add `@State private var navigateToPremium = false`
- Pass `onTap` closure to PremiumCard
- Add `.navigationDestination` for IAP

Changes to make:
```swift
// Add state
@State private var navigateToPremium = false

// Update PremiumCard
PremiumCard(onTap: { navigateToPremium = true })
    .padding(.top, 8)

// Add navigation destination
.navigationDestination(isPresented: $navigateToPremium) {
    #if DEBUG
    IAPPremiumView(storeKit: MockStoreKitService())
    #else
    // TODO: Replace with real StoreKit service
    IAPPremiumView(storeKit: MockStoreKitService())
    #endif
}
```

## File Size Check

| File | Est. Lines | Under 200? |
|------|-----------|------------|
| IAPPremiumView.swift | ~100 | Yes |
| PremiumCard.swift (modified) | ~45 | Yes |
| SettingsView.swift (modified) | ~95 | Yes |

## Success Criteria
- [ ] IAPPremiumView renders matching Figma design
- [ ] Navigation from Settings → PremiumCard → IAP screen works
- [ ] Plan selection toggles between Annual/Monthly
- [ ] "Unlock Premium" button triggers mock purchase
- [ ] "Restore Purchases" triggers mock restore
- [ ] "Manage Subscriptions" opens App Store URL
- [ ] Back/Close buttons dismiss the screen
- [ ] Hero illustration displays correctly
- [ ] No compilation errors
- [ ] Build succeeds on simulator

## Risk Assessment
- **Medium risk**: Hero illustration quality from Figma export — may need manual asset preparation
- **Low risk**: Navigation follows existing SettingsView pattern
- **Low risk**: PremiumCard change is backward-compatible (optional closure with default nil)

## Security Considerations
- "Manage Subscriptions" opens App Store URL — safe, standard pattern
- No real payment processing in this phase — mock only
- `@AppStorage("isPremiumUser")` is client-side only — real StoreKit will validate receipts later

## Next Steps
After this phase:
1. Test on simulator with demo mode
2. Screenshot comparison with Figma design
3. Plan real StoreKit 2 integration (future phase)

import SwiftUI

/// Thin wrapper around `IAPPremiumView`.
///
/// Presented **full-screen from anywhere** via `PaywallController.present(reason:)`,
/// which drives the root `.fullScreenCover(item:)` (see `MainTabView`).
///
/// The `StoreKitServiceProtocol` instance comes from the environment —
/// `StressMonitorApp` owns exactly one for the app's process lifetime, so
/// its `Transaction.updates` listener runs continuously instead of only
/// while this view happens to be on screen. This view must never construct
/// its own instance; that was the original bug.
///
/// Above the plan list it renders the live server credit balance (remaining
/// count, or "Unlimited" for premium) — the DEC-2 placement-a tracer surface.
/// The full paywall rework is plan 02-04.
struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.storeKitService) private var storeKitService
    @Environment(CreditService.self) private var creditService

    init(reason: PaywallReason = .general) {
        self.reason = reason
    }

    var body: some View {
        VStack(spacing: 0) {
            if let balance = creditService.balance {
                balanceLine(balance)
            }
            IAPPremiumView(storeKit: storeKitService, premiumState: PremiumState.shared)
        }
        .task { try? await creditService.refreshBalance() }
    }

    // MARK: - Balance Line

    private func balanceLine(_ balance: CreditBalance) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "circlebadge.2")
            Text(balance.displayDescription)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.top, DesignTokens.Spacing.sm)
        .accessibilityLabel("Credit balance: \(balance.displayDescription)")
    }
}

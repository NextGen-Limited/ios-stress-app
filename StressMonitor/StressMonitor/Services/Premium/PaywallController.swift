import Foundation
import Observation

/// Why the paywall is being shown. Drives analytics (and, later, per-reason
/// header copy). Keep cases coarse and meaningful.
enum PaywallReason: Hashable {
    case general
    case trendsLongRange
    case bioAgeDetail
    case characters
    case breathingAdvanced
    case feature(named: String)
}

/// Identifiable presentation envelope so `.fullScreenCover(item:)` can drive
/// off a single value instead of a raw boolean.
struct PaywallPresentation: Identifiable, Hashable {
    let id = UUID()
    let reason: PaywallReason
}

/// Single source of truth for presenting the paywall **full-screen, from
/// anywhere in the app**.
///
/// Mounted once at the app root (see `StressMonitorApp`):
/// ```swift
/// .fullScreenCover(item: paywall.presentationBinding) { presentation in
///     PaywallView(reason: presentation.reason)
/// }
/// ```
/// Any view — inside a tab, inside a sheet, a locked-feature overlay, a
/// notification handler — can present the paywall with:
/// ```swift
/// @Environment(PaywallController.self) private var paywall
/// paywall.present(reason: .trendsLongRange)
/// ```
///
/// `present(_:)` is a no-op when the user is already premium (decision: never
/// show the paywall to an unlocked user).
@MainActor
@Observable
final class PaywallController {
    /// The active presentation, or `nil` when dismissed. Settable so the root
    /// `.fullScreenCover(item:)` binding can write `nil` on dismiss; use
    /// `present(reason:)` to show (it enforces the premium guard).
    var presentation: PaywallPresentation?

    /// Premium status consulted by the no-op guard. Injectable for tests.
    private let premiumState: PremiumState

    init(premiumState: PremiumState = .shared) {
        self.premiumState = premiumState
    }

    /// Present the paywall full-screen for `reason`.
    /// No-ops when the user already has premium.
    func present(reason: PaywallReason) {
        guard !premiumState.isPremiumUser else { return }
        presentation = PaywallPresentation(reason: reason)
    }

    /// Dismiss the paywall.
    func dismiss() {
        presentation = nil
    }
}

import SwiftUI

/// Lets `StressMonitorApp` own a single `StoreKitServiceProtocol` instance for
/// the app's whole lifetime and hand it to `PaywallView` via `.environment`,
/// instead of `PaywallView` constructing a fresh one on every presentation.
///
/// That per-presentation construction was the root cause of the
/// `Transaction.updates` listener only running while the paywall happened to
/// be on screen — entitlement changes (renewal, refund, Family Sharing,
/// delayed Ask-to-Buy) that arrive the rest of the time were never observed.
private struct StoreKitServiceKey: EnvironmentKey {
    static let defaultValue: StoreKitServiceProtocol = MockStoreKitService(premiumState: .shared)
}

extension EnvironmentValues {
    var storeKitService: StoreKitServiceProtocol {
        get { self[StoreKitServiceKey.self] }
        set { self[StoreKitServiceKey.self] = newValue }
    }
}

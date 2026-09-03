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
    #if DEBUG
    // WR-03 site B: same decision logic as
    // StressMonitorApp.makeStoreKitService — the real service by default,
    // MockStoreKitService only behind the explicit `-mock-iap` launch-arg
    // opt-in. This default backs views outside the app's `.environment`
    // injection (PaywallView); it must not leave a no-op money path.
    static let defaultValue: StoreKitServiceProtocol = if MockIAPMode.isEnabled() {
        MockStoreKitService(premiumState: .shared)
    } else {
        StoreKitService(premiumState: .shared)
    }
    #else
    static let defaultValue: StoreKitServiceProtocol = StoreKitService(premiumState: .shared)
    #endif
}

extension EnvironmentValues {
    var storeKitService: StoreKitServiceProtocol {
        get { self[StoreKitServiceKey.self] }
        set { self[StoreKitServiceKey.self] = newValue }
    }
}

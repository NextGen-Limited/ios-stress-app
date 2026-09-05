#if DEBUG
import SwiftUI
import Testing
@testable import StressMonitor

/// WR-03 pin: DEBUG builds must default to the REAL StoreKit service at BOTH
/// wiring sites — the app factory (`StressMonitorApp.makeStoreKitService`) and
/// the environment fallback (`EnvironmentValues.storeKitService` default, which
/// backs `PaywallView` when a surface reads it outside the app's `.environment`
/// injection). `MockStoreKitService` may resolve ONLY behind the explicit
/// `-mock-iap` launch-argument opt-in; Release excludes the mock at compile
/// time, so this suite wraps in `#if DEBUG` (the mock type exists nowhere else).
///
/// The factory assertions go through the factory with injected arguments — a
/// test process cannot change its own launch arguments, so the shared decision
/// helper (`MockIAPMode.isEnabled(arguments:)`) accepts them as a parameter.
/// The environment-default assertion runs against the process's own arguments
/// (which never carry the opt-in in CI/dev test runs), pinning the fallback
/// surface `PaywallView` would hit.
@MainActor
@Suite("StoreKit Service Wiring")
struct StoreKitServiceWiringTests {

    @Test("factory resolves the real service absent the -mock-iap opt-in")
    func factoryResolvesRealServiceAbsentOptIn() {
        let service = StressMonitorApp.makeStoreKitService(
            creditService: CreditService(),
            arguments: ["StressMonitor"] // argv without the flag
        )

        #expect(
            service is StoreKitService,
            "DEBUG must default to the real StoreKitService (WR-03): a silent no-op mock money path masked real-path defects in every debug run"
        )
    }

    @Test("factory resolves the mock when the -mock-iap opt-in is present")
    func factoryResolvesMockWithOptIn() {
        let service = StressMonitorApp.makeStoreKitService(
            creditService: CreditService(),
            arguments: ["StressMonitor", MockIAPMode.launchArgument]
        )

        #expect(
            service is MockStoreKitService,
            "The mock must remain reachable for manual demo/debug runs, but only behind the explicit opt-in"
        )
    }

    @Test("environment default resolves the real service absent the opt-in")
    func environmentDefaultResolvesRealService() {
        #expect(
            EnvironmentValues().storeKitService is StoreKitService,
            "StoreKitServiceKey.defaultValue backs views outside the app injection (PaywallView) — it must not be the DEBUG no-op mock (WR-03 site B)"
        )
    }
}
#endif

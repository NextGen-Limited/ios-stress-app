import StoreKitTest

/// StoreKitTest connects exactly one `SKTestSession` to its process-wide
/// daemon at a time. Any test file that constructs its own
/// `SKTestSession(configurationFileNamed:)` silently detaches whatever
/// session another test file was already using, and purchases made against
/// one session's product (e.g. consuming an introductory-offer eligibility)
/// persist for the rest of the test process regardless of which session
/// object made the purchase.
///
/// All StoreKit-backed test files must call `session()` instead of
/// constructing their own `SKTestSession`, so the whole run shares one
/// daemon connection and one reset discipline.
enum StoreKitTestSessionProvider {
    private static let shared: SKTestSession = {
        // swiftlint:disable:next force_try
        try! SKTestSession(configurationFileNamed: "StressMonitorProducts.storekit")
    }()

    /// Returns the shared session, fully reset (including introductory-offer
    /// eligibility and transaction history) so each test starts clean.
    static func session() -> SKTestSession {
        shared.resetToDefaultState()
        shared.disableDialogs = true
        return shared
    }
}

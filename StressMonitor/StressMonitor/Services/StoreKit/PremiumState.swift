import Foundation

/// Single source of truth for premium status.
/// All views read from here. Eliminates scattered @AppStorage reads.
@MainActor
@Observable
final class PremiumState {
    static let shared = PremiumState()

    private let defaults = UserDefaults.standard
    private let key = "isPremiumUser"

    var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: key) }
    }

    private init() {
        isPremiumUser = defaults.bool(forKey: key)
    }
}

import Foundation

/// Single source of truth for premium status.
/// All views read from here. Eliminates scattered @AppStorage reads.
@MainActor
@Observable
final class PremiumState {
    static let shared = PremiumState()

    private let defaults: UserDefaults
    private let key: String

    var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: key) }
    }

    init(defaults: UserDefaults = .standard, key: String = "isPremiumUser") {
        self.defaults = defaults
        self.key = key
        self.isPremiumUser = defaults.bool(forKey: key)
    }
}

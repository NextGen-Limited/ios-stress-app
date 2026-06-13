import SwiftUI

// MARK: - AppearanceManager

/// Manages the user's dark-mode preference via UserDefaults.
/// Applied at the app root via `.preferredColorScheme()`.
@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()

    enum Mode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }

    var preferredScheme: Mode {
        didSet {
            UserDefaults.standard.set(preferredScheme.rawValue, forKey: Self.key)
        }
    }

    /// The `ColorScheme?` to pass to `.preferredColorScheme()` (nil = follow system).
    var colorScheme: ColorScheme? {
        switch preferredScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private static let key = "appearance.preferredMode"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? Mode.system.rawValue
        preferredScheme = Mode(rawValue: raw) ?? .system
    }
}

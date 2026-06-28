import Foundation

// MARK: - SeasonalTheme

/// Optional costume / overlay themes for the watch character, toggled
/// seasonally. `.none` is the default and renders the companion without
/// any overlay.
enum SeasonalTheme: String, CaseIterable, Codable, Sendable {
    case none
    case spring
    case lunarNewYear
    case halloween
    case holiday

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .none:         return "Default"
        case .spring:       return "Spring"
        case .lunarNewYear: return "Lunar New Year"
        case .halloween:    return "Halloween"
        case .holiday:      return "Holiday"
        }
    }

    /// SF Symbol used as a preview icon in the picker carousel.
    var icon: String {
        switch self {
        case .none:         return "sparkles"
        case .spring:       return "leaf.fill"
        case .lunarNewYear: return "fanblade.fill"
        case .halloween:    return "moon.stars.fill"
        case .holiday:      return "snowflake"
        }
    }

    /// Hex colour used for the theme's accent swatch.
    var primaryColorHex: String {
        switch self {
        case .none:         return "#4FC3F7" // Ripple accent
        case .spring:       return "#A5D6A7" // Blossom green
        case .lunarNewYear: return "#E53935" // Festive red
        case .halloween:    return "#FF7043" // Pumpkin
        case .holiday:      return "#EF5350" // Holly red
        }
    }

    /// Logical asset name for the character costume overlay. Resolve via
    /// the character renderer; `.none` means no overlay is drawn.
    var characterOverlay: String {
        switch self {
        case .none:         return ""
        case .spring:       return "overlay.spring.blossom"
        case .lunarNewYear: return "overlay.lunar.lantern"
        case .halloween:    return "overlay.halloween.mask"
        case .holiday:      return "overlay.holiday.scarf"
        }
    }
}

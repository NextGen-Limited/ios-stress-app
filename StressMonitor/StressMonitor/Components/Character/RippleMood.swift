import SwiftUI

/// Mood states for the Ripple water-droplet character used in Action subscreens.
/// Each mood drives visibly different eyes/mouth and an associated body tint.
enum RippleMood: String, CaseIterable, Sendable {
    case serene
    case focused
    case relaxed
    case happy
    case celebrating
    case worried
    case determined
    case tired

    /// VoiceOver-friendly description of the character's state.
    var accessibilityLabel: String {
        switch self {
        case .serene:       return "Ripple is serene and calm"
        case .focused:      return "Ripple is focused and attentive"
        case .relaxed:      return "Ripple is relaxed and at ease"
        case .happy:        return "Ripple is happy and content"
        case .celebrating:  return "Ripple is celebrating joyfully"
        case .worried:      return "Ripple is feeling worried"
        case .determined:   return "Ripple is determined and strong"
        case .tired:        return "Ripple is tired and sleepy"
        }
    }

    /// Base body tint — slightly shifts the water-droplet fill per mood.
    var bodyTint: Color {
        switch self {
        case .serene:       return HomeCharacterDesignTokens.Ripple.primary
        case .focused:      return HomeCharacterDesignTokens.Ripple.deep
        case .relaxed:      return HomeCharacterDesignTokens.Ripple.mid
        case .happy:        return HomeCharacterDesignTokens.Ripple.primary
        case .celebrating:  return HomeCharacterDesignTokens.Ripple.light
        case .worried:      return Color(hex: "#42A5F5")   // slightly muted blue
        case .determined:   return HomeCharacterDesignTokens.Ripple.deep
        case .tired:        return Color(hex: "#64B5F6")   // faded blue
        }
    }

    /// Display name for legends and labels.
    var displayName: String {
        rawValue.capitalized
    }
}

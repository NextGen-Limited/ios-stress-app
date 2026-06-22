import SwiftUI

/// Compact source pill used by habit rows to indicate where the value comes from.
///
/// - `.auto` → tinted with the Ripple accent (blue), reads "AUTO"
/// - `.manual` → neutral fill, reads "LOG"
///
/// Created here because the Action tab's HabitLogRow is its first consumer;
/// Phase 4 reuses it on Settings without owning it.
struct SourcePill: View {
    let source: HabitSource
    var tint: Color = HomeCharacterDesignTokens.Ripple.primary

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(foreground)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
            .accessibilityLabel("Source: \(label)")
    }

    private var label: String {
        switch source {
        case .auto:   return "Auto"
        case .manual: return "Log"
        }
    }

    private var background: Color {
        switch source {
        case .auto:   return tint.opacity(0.14)
        case .manual: return Color.Wellness.adaptiveSecondaryText.opacity(0.14)
        }
    }

    private var foreground: Color {
        switch source {
        case .auto:   return tint
        case .manual: return Color.Wellness.adaptiveSecondaryText
        }
    }

    private var border: Color {
        switch source {
        case .auto:   return tint.opacity(0.30)
        case .manual: return Color.Wellness.adaptiveSecondaryText.opacity(0.24)
        }
    }
}

#Preview("SourcePill") {
    HStack {
        SourcePill(source: .auto)
        SourcePill(source: .manual)
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}

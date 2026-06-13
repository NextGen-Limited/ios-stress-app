import SwiftUI

// MARK: - StressTier (Trends)

/// Five-band stress representation for the Ripple 💧 character in the Trends tab.
///
/// **Design rule:** never show a numeric stress score.
/// The character's facial expression *is* the indicator.
///
/// - 0…20   → 😴  "Calm"
/// - 21…40  → 😊  "Good"
/// - 41…60  → 😐  "Balanced"
/// - 61…80  → 😰  "Stressed"
/// - 81…100 → 🐌  "Overwhelmed"
enum StressTier: Int, CaseIterable, Sendable {
    case calm = 0
    case good = 1
    case balanced = 2
    case stressed = 3
    case overwhelmed = 4

    /// Resolve the tier directly from a 0–100 stress level.
    static func from(level: Double) -> StressTier {
        switch level {
        case ..<21:   return .calm
        case ..<41:   return .good
        case ..<61:   return .balanced
        case ..<81:   return .stressed
        default:      return .overwhelmed
        }
    }

    /// Emoji face used wherever the character appears — never a score.
    var emoji: String {
        switch self {
        case .calm:        return "😴"
        case .good:        return "😊"
        case .balanced:    return "😐"
        case .stressed:    return "😰"
        case .overwhelmed: return "🐌"
        }
    }

    /// Short, non-numeric mood word.
    var label: String {
        switch self {
        case .calm:        return "Calm"
        case .good:        return "Good"
        case .balanced:    return "Balanced"
        case .stressed:    return "Stressed"
        case .overwhelmed: return "Overwhelmed"
        }
    }

    /// Tier colour: calm = blue → overwhelmed = red ramp.
    var color: Color {
        switch self {
        case .calm:        return TrendsPalette.tierCalm
        case .good:        return TrendsPalette.tierGood
        case .balanced:    return TrendsPalette.tierBalanced
        case .stressed:    return TrendsPalette.tierStressed
        case .overwhelmed: return TrendsPalette.tierOverwhelmed
        }
    }
}

// MARK: - TrendsPalette

/// Colour tokens for the Trends tab redesign (dark canvas + Ripple blue).
enum TrendsPalette {
    static let darkCanvas = Color(hex: "#0A0A0F")
    static let darkCard   = Color(hex: "#1A1A2E")
    static let rippleBlue = Color(hex: "#4FC3F7")
    static let mutedInk   = Color(hex: "#777986")

    /// 5-tier ramp: calm (blue) → overwhelmed (red)
    static let tierCalm        = Color(hex: "#4FC3F7")
    static let tierGood        = Color(hex: "#A5D6A7")
    static let tierBalanced    = Color(hex: "#7986CB")
    static let tierStressed    = Color(hex: "#FFAB91")
    static let tierOverwhelmed = Color(hex: "#EF5350")

    /// Linear gradient across all five tiers (for legend strips).
    static var tierGradient: LinearGradient {
        LinearGradient(
            colors: [tierCalm, tierGood, tierBalanced, tierStressed, tierOverwhelmed],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - RippleMoodFace

/// Compact Ripple mood face — tier emoji on an accent ring.
/// Used on bar-chart heads, calendar dots, and heatmap legend.
/// **Never shows a numeric score.**
struct RippleMoodFace: View {
    let tier: StressTier
    var size: CGFloat = 28
    var showsRing: Bool = true
    var glow: Bool = false

    var body: some View {
        ZStack {
            if glow {
                Circle()
                    .fill(tier.color.opacity(0.25))
                    .frame(width: size * 1.15, height: size * 1.15)
                    .blur(radius: size * 0.12)
            }

            if showsRing {
                Circle()
                    .fill(tier.color.opacity(0.12))
                Circle()
                    .stroke(tier.color.opacity(0.5), lineWidth: max(1.5, size * 0.07))
            }

            Text(tier.emoji)
                .font(.system(size: size * (showsRing ? 0.46 : 0.62)))
        }
        .frame(width: size, height: size)
        .accessibilityLabel(tier.label)
    }
}

// MARK: - Glass Card Modifier

/// Applies the Trends glass-card treatment: dark fill #1A1A2E + subtle border.
struct TrendsGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(TrendsPalette.darkCard.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    /// Trends-tab glass card style on the dark canvas.
    func trendsGlassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(TrendsGlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

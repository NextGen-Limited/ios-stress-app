import SwiftUI

// MARK: - StressTier

/// Five-band stress representation for the Ripple 💧 character.
///
/// The design rule is explicit: **never show a numeric stress score**.
/// The character's facial expression *is* the indicator. This enum maps a
/// raw 0–100 level to one of five expressions and the accent colour that
/// accompanies it.
///
/// Mapping (per product spec):
/// - 0…20  → 😴  "Resting"
/// - 21…40 → 😊  "Calm"
/// - 41…60 → 😐  "Balanced"
/// - 61…80 → 😰  "Tense"
/// - 81…100→ 🐚  "Overwhelmed"
enum StressTier: Int, CaseIterable, Sendable {
    case resting = 0      // 😴
    case calm = 1         // 😊
    case balanced = 2     // 😐
    case tense = 3        // 😰
    case overwhelmed = 4  // 🐚

    /// Resolve the tier directly from a 0–100 stress level.
    static func from(level: Double) -> StressTier {
        switch level {
        case ..<21:   return .resting
        case ..<41:   return .calm
        case ..<61:   return .balanced
        case ..<81:   return .tense
        default:      return .overwhelmed
        }
    }

    /// Emoji face used wherever the character appears (app, complications).
    var emoji: String {
        switch self {
        case .resting:     return "😴"
        case .calm:        return "😊"
        case .balanced:    return "😐"
        case .tense:       return "😰"
        case .overwhelmed: return "🐚"
        }
    }

    /// Short, non-numeric mood word (safe to display — never a score).
    var label: String {
        switch self {
        case .resting:     return "Resting"
        case .calm:        return "Calm"
        case .balanced:    return "Balanced"
        case .tense:       return "Tense"
        case .overwhelmed: return "Overwhelmed"
        }
    }

    /// Accent colour sourced from the `HomeCharacterDesignTokens` palette.
    var accent: Color {
        switch self {
        case .resting:     return StressCharacterPalette.ripple
        case .calm:        return StressCharacterPalette.blossom
        case .balanced:    return StressCharacterPalette.lumi
        case .tense:       return StressCharacterPalette.ember
        case .overwhelmed: return StressCharacterPalette.zephyr
        }
    }

    /// VoiceOver description of the character's current state.
    var accessibilityLabel: String {
        switch self {
        case .resting:     return "Ripple is resting peacefully. Very low stress."
        case .calm:        return "Ripple is calm. Low stress."
        case .balanced:    return "Ripple feels balanced. Moderate stress."
        case .tense:       return "Ripple feels tense. Elevated stress."
        case .overwhelmed: return "Ripple is overwhelmed. High stress."
        }
    }
}

// MARK: - StressCharacterPalette

/// Watch-local copy of the `HomeCharacterDesignTokens` colour ramp.
///
/// The canonical tokens live in the iOS app target (`HomeCharacterDesignTokens`),
/// which is not visible to the watch target. These hex values are kept in sync
/// with that source of truth so the character looks identical on every surface.
enum StressCharacterPalette {
    static let ripple  = Color(hex: "#4FC3F7") // Ripple.primary
    static let blossom = Color(hex: "#A5D6A7") // Blossom.primary
    static let lumi    = Color(hex: "#7986CB") // Lumi.primary
    static let ember   = Color(hex: "#FFAB91") // Ember.primary
    static let zephyr  = Color(hex: "#B39DDB") // Zephyr.accent

    static let darkCanvas = Color(hex: "#0A0A0F") // darkCanvas
    static let darkCard   = Color(hex: "#1A1A2E") // darkCard
    static let mutedInk   = Color(hex: "#777986") // mutedInk
}

// MARK: - CharacterFaceView

/// The reusable Ripple character face.
///
/// Renders the emoji expression centred on an optional accent-coloured ring so
/// the same view drives the watch home screen, the history list, every
/// complication and (mirrored) the iOS widgets. No numeric score is ever shown.
struct CharacterFaceView: View {
    let tier: StressTier
    var size: CGFloat = 80
    var showsRing: Bool = true
    var glow: Bool = false

    var body: some View {
        ZStack {
            if showsRing {
                Circle()
                    .stroke(tier.accent.opacity(0.25), lineWidth: ringWidth)

                Circle()
                    .trim(from: 0, to: fillFraction)
                    .stroke(
                        tier.accent,
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8),
                               value: fillFraction)
            }

            if glow {
                Circle()
                    .fill(tier.accent.opacity(0.18))
                    .frame(width: size * 0.66, height: size * 0.66)
                    .blur(radius: size * 0.08)
            }

            Text(tier.emoji)
                .font(.system(size: emojiSize))
                .scaleEffect(animateScale ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                           value: animateScale)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(tier.accessibilityLabel)
    }

    // An ambient "breathing" idle motion for the in-app face.
    @State private var animateScale = false

    private var ringWidth: CGFloat { max(3, size * 0.05) }
    private var emojiSize: CGFloat { size * (showsRing ? 0.42 : 0.6) }
    private var fillFraction: CGFloat { CGFloat(tier.rawValue + 1) / CGFloat(StressTier.allCases.count) }

    /// Toggle the idle animation once the view appears.
    func startIdleAnimation() -> some View {
        self.onAppear { animateScale = true }
    }
}

#if DEBUG
#Preview("Tiers") {
    HStack {
        ForEach(StressTier.allCases, id: \.self) { tier in
            VStack(spacing: 6) {
                CharacterFaceView(tier: tier, size: 70, glow: true).startIdleAnimation()
                Text(tier.label)
                    .font(.system(size: 10))
                    .foregroundStyle(StressCharacterPalette.mutedInk)
            }
        }
    }
    .padding()
    .background(StressCharacterPalette.darkCanvas)
}
#endif

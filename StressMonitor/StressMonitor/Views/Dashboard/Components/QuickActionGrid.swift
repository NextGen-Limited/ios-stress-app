import SwiftUI

/// Mid-screen intervention cards — two-up grid of quick actions.
///
/// Per the 04-home spec, actions live mid-screen rather than buried at the
/// bottom. Breathing (Ripple blue / calm focus) and Walk (green / reset) carry
/// two distinct accents justified by meaning, not decoration.
///
/// Spec reference: design/screens/04-home.html — `.quick-actions`.
struct QuickActionGrid<DestinationA: View, DestinationB: View>: View {
    let first: QuickActionTile<DestinationA>
    let second: QuickActionTile<DestinationB>

    var body: some View {
        HStack(spacing: 10) {
            first
            second
        }
    }
}

/// Single gradient-backed quick action tile with an icon bubble, title, and a
/// mono meta line (duration + intent).
struct QuickActionTile<Destination: View>: View {
    enum Accent {
        case breathing
        case walk

        var gradient: [Color] {
            switch self {
            case .breathing:
                return [Color(hex: "#E1F5FE"), Color(hex: "#B3E5FC")]
            case .walk:
                return [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9")]
            }
        }

        var foreground: Color {
            switch self {
            case .breathing: return Color(hex: "#01579B")
            case .walk:      return Color(hex: "#1B5E20")
            }
        }
    }

    let accent: Accent
    let symbol: String
    let title: String
    let meta: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent.foreground)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .tracking(-0.3)
                        .foregroundStyle(accent.foreground)
                    Text(meta)
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundStyle(accent.foreground.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 108)
            .background(
                LinearGradient(
                    colors: accent.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(meta)")
        .accessibilityHint("Double tap to start")
    }
}

// MARK: - Convenience factory

extension QuickActionTile where Destination == BreathingExerciseView {
    static var boxBreathing: QuickActionTile<BreathingExerciseView> {
        QuickActionTile(
            accent: .breathing,
            symbol: "wind",
            title: "Box Breathing",
            meta: "3 MIN · CALM FOCUS",
            destination: { BreathingExerciseView() }
        )
    }
}

extension QuickActionTile where Destination == MiniWalkView {
    static var miniWalk: QuickActionTile<MiniWalkView> {
        QuickActionTile(
            accent: .walk,
            symbol: "figure.walk",
            title: "Mini Walk",
            meta: "3 MIN · RESET",
            destination: { MiniWalkView() }
        )
    }
}

// MARK: - Preview

#Preview("QuickActionGrid") {
    NavigationStack {
        QuickActionGrid(first: .boxBreathing, second: .miniWalk)
            .padding()
            .background(HomeCharacterDesignTokens.homeBackground)
    }
}

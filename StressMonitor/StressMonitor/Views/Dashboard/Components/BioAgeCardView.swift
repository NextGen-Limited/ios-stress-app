import SwiftUI

// MARK: - BioAgeCardView

/// Dashboard card displaying estimated biological age with character expression.
/// Dark glass theme with color-coded indicator: younger = celebratory, older = encouraging.
/// Never shows raw sub-scores — uses character expression and age difference instead.
struct BioAgeCardView: View {
    let result: BioAgeResult

    @State private var appearScale: CGFloat = 0.92
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 16) {
            headerRow

            Divider()
                .overlay(HomeCharacterDesignTokens.Ripple.primary.opacity(0.15))

            ageDisplay

            characterExpressionView

            if result.isCelebratory {
                celebrationBadge
            }
        }
        .padding(20)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: accentColor.opacity(result.isCelebratory ? 0.25 : 0.12),
            radius: result.isCelebratory ? 20 : 12,
            x: 0, y: 8
        )
        .scaleEffect(appearScale)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appearScale = 1.0
            }
            if result.isCelebratory {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 28, height: 28)
                Image(systemName: AppIconSystem.Action.bodyScan.sfSymbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text("Biological Age")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color.Wellness.adaptiveSecondaryText)

            Spacer()

            trendBadge
        }
    }

    private var ageDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(result.estimatedAge)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(ageGradient)
                .minimumScaleFactor(0.8) // dated exception 2026-09-05: 56pt gauge numeral (D-09); width clamp, not DT

            Text("years")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.Wellness.adaptiveSecondaryText.opacity(0.72))

            Spacer()

            differenceIndicator
        }
    }

    private var differenceIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Image(systemName: differenceIcon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(accentColor)

            Text(result.differenceLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var characterExpressionView: some View {
        Text(result.characterExpression)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(Color.Wellness.adaptiveSecondaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
    }

    private var celebrationBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
            Text("Thriving!")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(HomeCharacterDesignTokens.Blossom.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(HomeCharacterDesignTokens.Blossom.primary.opacity(0.16))
        .clipShape(Capsule())
        .opacity(glowPulse ? 0.7 : 1.0)
    }

    private var trendBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: result.trend.icon)
                .font(.system(size: 10, weight: .bold))
            Text(result.trend.label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trendColor.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Computed Properties

    private var accentColor: Color {
        switch result.difference {
        case ...(-5): return HomeCharacterDesignTokens.Blossom.accent
        case -4 ... -1: return HomeCharacterDesignTokens.Ripple.primary
        case 0: return HomeCharacterDesignTokens.Ripple.mid
        case 1 ... 4: return HomeCharacterDesignTokens.Ember.accent
        default: return HomeCharacterDesignTokens.Ember.primary
        }
    }

    private var ageGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var differenceIcon: String {
        if result.difference < 0 { return "arrow.down.right" }
        if result.difference > 0 { return "arrow.up.right" }
        return "equal"
    }

    private var trendColor: Color {
        switch result.trend {
        case .improving: return HomeCharacterDesignTokens.Blossom.accent
        case .declining: return HomeCharacterDesignTokens.Ember.accent
        case .stable: return Color.Wellness.adaptiveSecondaryText
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                HomeCharacterDesignTokens.darkCard.opacity(0.92),
                HomeCharacterDesignTokens.darkCard.opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(accentColor.opacity(0.20), lineWidth: 1)
    }

    private var accessibilityLabel: String {
        var parts: [String] = [
            "Biological age: \(result.estimatedAge) years",
            result.differenceLabel,
            result.trend.label
        ]
        parts.append(result.characterExpression)
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("BioAge - Younger") {
    BioAgeCardView(
        result: BioAgeResult(
            estimatedAge: 28,
            chronologicalAge: 35,
            trend: .improving,
            confidence: 0.8
        )
    )
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}

#Preview("BioAge - Older") {
    BioAgeCardView(
        result: BioAgeResult(
            estimatedAge: 42,
            chronologicalAge: 35,
            trend: .stable,
            confidence: 0.6
        )
    )
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}

#Preview("BioAge - On Par") {
    BioAgeCardView(
        result: BioAgeResult(
            estimatedAge: 35,
            chronologicalAge: 35,
            trend: .stable,
            confidence: 0.5
        )
    )
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}

import SwiftUI

/// Ripple Insights Teaser — blue-tinted card with a ghosted Ripple character.
///
/// Messaging: "Ripple is learning your patterns".
struct SmartInsightsTeaser: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                // Title row with learning indicator
                HStack(spacing: 8) {
                    Text("Smart Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Pulsing learning dot
                    LearningPulse()
                }

                Text("Ripple is learning your patterns")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: 220, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: {}) {
                    Text("Coming Soon")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(TrendsPalette.rippleBlue.opacity(0.25))
                        .overlay(Capsule().stroke(TrendsPalette.rippleBlue.opacity(0.4), lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Ghosted Ripple character in the corner
            RippleGhostCharacter()
                .frame(width: 72, height: 72)
                .offset(x: 4, y: 6)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(TrendsPalette.darkCard.opacity(0.92))
                // Subtle blue tint overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [TrendsPalette.rippleBlue.opacity(0.12), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TrendsPalette.rippleBlue.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Learning Pulse

private struct LearningPulse: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(TrendsPalette.rippleBlue)
                .frame(width: 7, height: 7)
                .opacity(animate ? 0.4 : 1.0)

            Text("Learning")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(TrendsPalette.rippleBlue.opacity(0.8))
        }
        .onAppear { animate = true }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
    }
}

// MARK: - Ghost Ripple

/// A faint, ghosted Ripple droplet character for the teaser corner.
private struct RippleGhostCharacter: View {
    var body: some View {
        ZStack {
            // Water ripple rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(TrendsPalette.rippleBlue.opacity(0.15), lineWidth: 1.5)
                    .scaleEffect(1.0 - CGFloat(i) * 0.22)
            }

            // Droplet body
            Image(systemName: "drop.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [TrendsPalette.rippleBlue.opacity(0.4), TrendsPalette.rippleBlue.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Sleeping face
            Text("😴")
                .font(.system(size: 16))
        }
        .opacity(0.7)
    }
}

// MARK: - Preview

struct SmartInsightsTeaser_Previews: PreviewProvider {
    static var previews: some View {
        SmartInsightsTeaser()
            .padding()
            .background(TrendsPalette.darkCanvas)
    }
}

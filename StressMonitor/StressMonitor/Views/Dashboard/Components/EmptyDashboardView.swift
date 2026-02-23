import SwiftUI

/// Empty state view for dashboard when no data available
/// Shows friendly character illustration and action CTAs
struct EmptyDashboardView: View {
    let onMeasure: () -> Void
    let onLearnMore: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Character illustration using existing StressCharacterCard
            StressCharacterCard(
                mood: .calm,
                stressLevel: 0,
                hrv: nil,
                size: .dashboard
            )
            .frame(width: 140, height: 140)
            .accessibilityHidden(true)

            // Message
            VStack(spacing: 12) {
                Text("No Stress Data Yet")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("Start your first measurement to begin tracking your stress levels and see personalized insights.")
                    .font(.subheadline)
                    .foregroundColor(.oledTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)

            // CTA buttons
            VStack(spacing: 16) {
                Button(action: onMeasure) {
                    Label("Take First Measurement", systemImage: "waveform.path.ecg")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Take your first stress measurement")
                .accessibilityHint("Double tap to start measuring your stress level")

                Button(action: onLearnMore) {
                    HStack(spacing: 4) {
                        Text("Learn How It Works")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primaryBlue)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Learn how stress monitoring works")
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("No stress data available. Tap to take your first measurement.")
    }
}

// MARK: - Preview

#Preview("Empty State - Dark") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()
        EmptyDashboardView(
            onMeasure: {},
            onLearnMore: {}
        )
    }
}

#Preview("Empty State - Light") {
    ZStack {
        Color.backgroundLight.ignoresSafeArea()
        EmptyDashboardView(
            onMeasure: {},
            onLearnMore: {}
        )
    }
    .preferredColorScheme(.light)
}

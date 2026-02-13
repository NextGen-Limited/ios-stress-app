import SwiftUI

// MARK: - Breathing Exercise CTA Card

/// Call-to-action card for breathing exercise
/// Displayed on dashboard to encourage stress relief
struct BreathingExerciseCTA: View {
    let action: () -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                iconSection

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Try Breathing Exercise")
                        .font(Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("4-7-8 technique to reduce stress")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        Color.Wellness.calmBlue.opacity(0.1),
                        Color.Wellness.healthGreen.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius)
                    .strokeBorder(Color.Wellness.calmBlue.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(DesignTokens.Layout.cornerRadius)
        }
        .buttonStyle(BreathingCTAButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Try breathing exercise")
        .accessibilityHint("4-7-8 breathing technique to help reduce stress. Double tap to start.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.Wellness.calmBlue.opacity(0.15))
                .frame(width: 50, height: 50)

            Image(systemName: "wind")
                .font(.title2)
                .foregroundStyle(Color.Wellness.calmBlue)
        }
    }

    // MARK: - Actions

    private func handleTap() {
        HapticManager.shared.buttonPress()
        action()
    }
}

// MARK: - Button Style

struct BreathingCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BreathingExerciseCTA {
            print("Breathing exercise tapped")
        }

        BreathingExerciseCTA {
            print("Breathing exercise tapped")
        }
        .environment(\.colorScheme, .dark)
    }
    .padding()
    .background(Color.Wellness.background)
}

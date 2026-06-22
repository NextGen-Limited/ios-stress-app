import SwiftUI

/// Post-session summary screen — Ripple redesign.
/// Dark canvas, celebrating Ripple, mood shift card, stat grid, HRV chart, Ripple message.
struct BreathingSummaryView: View {
    let result: BreathingSessionResult
    @Environment(\.dismiss) private var dismiss

    // Ripple design tokens
    private let darkCanvas = HomeCharacterDesignTokens.darkCanvas
    private let ripplePrimary = HomeCharacterDesignTokens.Ripple.primary  // #4FC3F7
    private let rippleDeep = HomeCharacterDesignTokens.Ripple.deep        // #0288D1
    private let rippleMid = HomeCharacterDesignTokens.Ripple.mid          // #81D4FA
    private let rippleLight = HomeCharacterDesignTokens.Ripple.light      // #B3E5FC

    // Bounce animation
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 24)

                // Celebrating Ripple character
                ZStack {
                    // Glow background
                    Circle()
                        .fill(ripplePrimary.opacity(0.08))
                        .frame(width: 140, height: 140)
                        .blur(radius: 8)

                    // Sparkles around character
                    sparkleAt(angle: -45, radius: 56)
                    sparkleAt(angle: 45, radius: 60)
                    sparkleAt(angle: 180, radius: 58)
                    sparkleAt(angle: 225, radius: 52)

                    RippleCharacterView(mood: .celebrating, size: 100)
                        .offset(y: bounceOffset)
                        .accessibilityLabel("Ripple is celebrating your achievement")
                }
                .frame(height: 120)

                // Title
                VStack(spacing: 4) {
                    Text("Amazing! 🎉")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Ripple is so proud of you!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Mood shift card
                moodShiftCard

                // Stat grid
                statGrid

                // HRV before/after comparison
                BeforeAfterHRVChart(
                    before: result.preSessionHRV,
                    after: result.postSessionHRV
                )
                .padding(.horizontal, 24)

                // Ripple message card
                rippleMessageCard

                Spacer().frame(height: 8)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27)
                                    .fill(
                                        LinearGradient(
                                            colors: [ripplePrimary, rippleDeep],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: ripplePrimary.opacity(0.3), radius: 12, y: 4)
                    }
                    .accessibilityLabel("Done")

                    Button(action: { shareResult() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Result")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(rippleMid)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel("Share Result")
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)
            }
        }
        .background(darkCanvas)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounceOffset = -10
            }
        }
    }

    // MARK: - Sparkle Helper

    private func sparkleAt(angle: Double, radius: CGFloat) -> some View {
        let radians = angle * .pi / 180
        return Image(systemName: "sparkle")
            .font(.system(size: 14, design: .rounded))
            .foregroundStyle(rippleLight.opacity(0.6))
            .offset(x: cos(radians) * radius, y: sin(radians) * radius)
    }

    // MARK: - Mood Shift Card

    private var moodShiftCard: some View {
        HStack(spacing: 12) {
            // Before — worried Ripple
            VStack(spacing: 8) {
                RippleCharacterView(mood: .worried, size: 54)
                Text("Before")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 255/255, green: 138/255, blue: 101/255).opacity(0.08))
            )

            // Arrow + improvement
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ripplePrimary.opacity(0.6))
                Text("+\(Int(result.percentageImprovement))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#81C784"))
            }

            // After — serene Ripple
            VStack(spacing: 8) {
                RippleCharacterView(mood: .serene, size: 54)
                Text("After")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 129/255, green: 199/255, blue: 132/255).opacity(0.08))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mood shifted from worried to serene, improvement \(Int(result.percentageImprovement)) percent")
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        HStack(spacing: 12) {
            // Duration tile
            VStack(spacing: 6) {
                Text("⏱️")
                    .font(.system(size: 24, design: .rounded))
                Text("\(Int(result.duration / 60))m \(Int(result.duration.truncatingRemainder(dividingBy: 60)))s")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("Duration")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Duration, \(Int(result.duration / 60)) minutes")

            // Cycles tile
            VStack(spacing: 6) {
                Text("🔄")
                    .font(.system(size: 24, design: .rounded))
                Text("\(result.cyclesCompleted)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("Cycles")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cycles completed, \(result.cyclesCompleted)")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Ripple Message Card

    private var rippleMessageCard: some View {
        HStack(spacing: 12) {
            RippleCharacterView(mood: .happy, size: 48)
                .accessibilityLabel("Ripple avatar")

            VStack(alignment: .leading, spacing: 4) {
                Text("Ripple says:")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(rippleMid)
                Text("Your heart rhythm improved \(Int(result.percentageImprovement))%! I can feel you are calmer now.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(rippleLight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(ripplePrimary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(ripplePrimary.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Share

    private func shareResult() {
        let text = """
        Breathing Session Complete 🧘

        Duration: \(Int(result.duration / 60)) minutes
        Cycles: \(result.cyclesCompleted)

        HRV Improvement: +\(Int(result.improvement))ms (\(Int(result.percentageImprovement))%)
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

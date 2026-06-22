import SwiftUI

// MARK: - Welcome Screen (Screen 0)
// Emotional hook: meet Ripple, feel the calm. Animated rings + feature pills + CTA.
struct OnboardingWelcomeView: View {
    @State private var viewModel = OnboardingWelcomeViewModel()
    @State private var appearAnimation = false

    var onGetStarted: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Ripple otter creature with animated breathing rings
            welcomeHero
                .padding(.bottom, 28)

            // Headline
            Text("Meet your Stress Buddy")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#E8E8F0"))
                .multilineTextAlignment(.center)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 12)
                .accessibilityAddTraits(.isHeader)

            // Subtitle
            Text("A tiny creature that lives on your phone and reflects how your body feels — so you can take better care of yourself.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 310)
                .padding(.top, 10)
                .padding(.bottom, 28)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 12)

            // Feature pills
            featurePills
                .padding(.bottom, 28)

            // Primary CTA
            Button(action: { onGetStarted?() }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [HomeCharacterDesignTokens.Ripple.primary, HomeCharacterDesignTokens.Ripple.deep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: HomeCharacterDesignTokens.Ripple.primary.opacity(0.28), radius: 12, y: 6)
            }
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 12)

            // Secondary CTA
            Button(action: { viewModel.handleSignIn() }) {
                Text("I already have an account")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
            }
            .padding(.top, 10)
            .opacity(appearAnimation ? 1 : 0)

            Spacer().frame(height: 48)
        }
        .padding(.horizontal, 28)
        .background(HomeCharacterDesignTokens.darkCanvas)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Hero with animated rings

    private var welcomeHero: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.08), lineWidth: 2)
                .frame(width: 240, height: 240)
                .scaleEffect(viewModel.breathPhase ? 1.06 : 1.0)
                .opacity(viewModel.breathPhase ? 0.7 : 1.0)

            // Middle ring
            Circle()
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.12), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(viewModel.breathPhase2 ? 1.06 : 1.0)
                .opacity(viewModel.breathPhase2 ? 0.7 : 1.0)

            // Inner ring
            Circle()
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.18), lineWidth: 2)
                .frame(width: 160, height: 160)
                .scaleEffect(viewModel.breathPhase3 ? 1.06 : 1.0)
                .opacity(viewModel.breathPhase3 ? 0.7 : 1.0)

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HomeCharacterDesignTokens.Ripple.primary.opacity(0.18),
                            HomeCharacterDesignTokens.Blossom.primary.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(viewModel.breathPhase2 ? 1.06 : 1.0)

            // Ripple character — happy mood to introduce the buddy
            RippleCharacterView(mood: .happy, size: 120)
                .shadow(color: HomeCharacterDesignTokens.Ripple.primary.opacity(0.35), radius: 24)
                .offset(y: viewModel.floatOffset ? -10 : 0)
        }
        .frame(width: 240, height: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ripple the Water Otter creature with animated breathing rings")
    }

    // MARK: - Value props

    private var featurePills: some View {
        VStack(spacing: 10) {
            ValuePropRow(
                icon: "waveform.path.ecg",
                title: "Real-time stress score",
                subtitle: "HRV and heart rate, translated into a number you understand."
            )
            ValuePropRow(
                icon: "leaf.fill",
                title: "Calm in minutes",
                subtitle: "Guided breathing and mini-walks whenever tension rises."
            )
            ValuePropRow(
                icon: "chart.xyaxis.line",
                title: "See your patterns",
                subtitle: "Trends and bio-age insights from data already on your phone."
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 12)
    }
}

// MARK: - Value Prop Row

private struct ValuePropRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                .frame(width: 40, height: 40)
                .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E8E8F0"))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(HomeCharacterDesignTokens.darkCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingWelcomeView()
}

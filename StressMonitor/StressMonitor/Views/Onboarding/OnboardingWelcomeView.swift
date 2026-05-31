import SwiftUI

struct OnboardingWelcomeView: View {
    @State private var viewModel = OnboardingWelcomeViewModel()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Hero illustration
            ZStack {
                Circle()
                    .stroke(Color.stressRelaxed.opacity(0.2), lineWidth: 4)
                    .frame(width: 160, height: 160)

                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.stressRelaxed)

                // Orbiting ring animation
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.stressRelaxed, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: viewModel.isAnimating)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Heart icon with rotating ring")

            // Headline
            Text("Understand Your Stress")
                .font(.system(size: 28, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "checkmark.circle.fill", text: "Accurate HRV-based stress monitoring")
                FeatureRow(icon: "checkmark.circle.fill", text: "Personalized baseline calculations")
                FeatureRow(icon: "checkmark.circle.fill", text: "Actionable health insights")
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Features list")

            Spacer()

            // CTAs
            VStack(spacing: 12) {
                Button(action: { viewModel.handleGetStarted() }) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .accessibilityHint("Begins health kit authorization")

                Button(action: { viewModel.handleSignIn() }) {
                    Text("Already have an account? Sign in")
                        .font(.subheadline)
                }
                .accessibilityHint("Opens sign in flow (coming soon)")
            }
        }
        .padding(24)
        .onAppear {
            viewModel.isAnimating = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.stressRelaxed)
                .font(.title3)
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    OnboardingWelcomeView()
}

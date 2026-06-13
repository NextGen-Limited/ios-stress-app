import SwiftUI

// MARK: - Permissions Screen (Screen 1)
// Frictionless: one screen, toggle-based, privacy-first. 4 toggles on one page.
struct OnboardingHealthSyncView: View {
    @State private var viewModel = OnboardingHealthSyncViewModel()
    @State private var appearAnimation = false

    var onAuthorize: (() -> Void)?
    var onBack: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: { onBack?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Lock icon
                    Text("🔐")
                        .font(.system(size: 52))
                        .shadow(color: HomeCharacterDesignTokens.Ripple.primary.opacity(0.2), radius: 12)
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    // Title
                    Text("Quick permissions")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "#E8E8F0"))
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("Ripple needs health data to read your stress. Everything stays on your device.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 310)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Toggle rows
                    VStack(spacing: 8) {
                        PermissionToggleRow(
                            emoji: "❤️",
                            iconBgColor: Color(hex: "#EF5350").opacity(0.1),
                            title: "Heart Rate",
                            subtitle: "Resting & active BPM",
                            isOn: $viewModel.heartRateEnabled
                        )

                        PermissionToggleRow(
                            emoji: "📈",
                            iconBgColor: Color(hex: "#7986CB").opacity(0.1),
                            title: "Heart Rate Variability",
                            subtitle: "Primary stress indicator",
                            isOn: $viewModel.hrvEnabled
                        )

                        PermissionToggleRow(
                            emoji: "😴",
                            iconBgColor: HomeCharacterDesignTokens.Ripple.primary.opacity(0.1),
                            title: "Sleep Analysis",
                            subtitle: "Recovery quality tracking",
                            isOn: $viewModel.sleepEnabled
                        )

                        PermissionToggleRow(
                            emoji: "🏃",
                            iconBgColor: HomeCharacterDesignTokens.Blossom.primary.opacity(0.1),
                            title: "Activity & Exercise",
                            subtitle: "Optional — improves accuracy",
                            isOn: $viewModel.activityEnabled
                        )
                    }
                    .padding(.bottom, 12)

                    // Privacy box
                    privacyBox
                        .padding(.bottom, 20)
                }
            }

            // Authorize CTA — pinned to bottom
            Button(action: { Task { await authorizeAndContinue() } }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Authorize & Continue")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
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
            .disabled(viewModel.isLoading)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 28)
        .background(HomeCharacterDesignTokens.darkCanvas)
        .alert("Authorization Error", isPresented: .constant(viewModel.authorizationError != nil)) {
            Button("OK") {
                viewModel.authorizationError = nil
            }
        } message: {
            if let error = viewModel.authorizationError {
                Text(error)
            }
        }
    }

    // MARK: - Privacy Box

    private var privacyBox: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🔒")
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 0) {
                Text("Privacy Promise: ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.primary)
                +
                Text("Zero data collection. No servers. Your health data never leaves this iPhone.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(HomeCharacterDesignTokens.Ripple.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func authorizeAndContinue() async {
        await viewModel.requestSelectedPermissions()
        if viewModel.healthKitAuthorized {
            onAuthorize?()
        }
    }
}

// MARK: - Permission Toggle Row

private struct PermissionToggleRow: View {
    let emoji: String
    let iconBgColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(iconBgColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E8E8F0"))
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(HomeCharacterDesignTokens.mutedInk)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HomeCharacterDesignTokens.Blossom.primary)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
    OnboardingHealthSyncView()
}

import SwiftUI

/// About and support card with links, Ripple mascot, and version info.
struct AboutCard: View {
    let onHelp: () -> Void
    let onContactSupport: () -> Void
    let onPrivacyPolicy: () -> Void
    let onTermsOfService: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(
                    icon: "info.circle.fill",
                    title: "About and Support",
                    color: .settingsRippleBlue
                )

                VStack(alignment: .leading, spacing: 12) {
                    supportLink("Help & FAQ", action: onHelp)
                    supportLink("Contact Support", action: onContactSupport)
                    supportLink("Privacy Policy", action: onPrivacyPolicy)
                    supportLink("Terms of Service", action: onTermsOfService)
                }

                rippleMascot
            }
        }
    }

    private var rippleMascot: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.settingsRippleBlue.opacity(0.14))
                    .frame(width: 112, height: 112)
                    .blur(radius: 8)

                Text("💧👋")
                    .font(.system(size: 58))
                    .accessibilityHidden(true)
            }
            .frame(height: 106)

            Text("💧 Ripple is happy you're here")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("StressMonitor v1.0.0")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }

    private func supportLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.settingsRippleBlue)
        }
        .accessibilityLabel(title)
    }
}

struct AboutCard_Previews: PreviewProvider {
    static var previews: some View {
        AboutCard(
            onHelp: {},
            onContactSupport: {},
            onPrivacyPolicy: {},
            onTermsOfService: {}
        )
        .padding()
        .background(Color.adaptiveSettingsBackground)
    }
}

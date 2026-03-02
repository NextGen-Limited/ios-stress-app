import SwiftUI

/// About and support card with links, cat illustration, and version info
struct AboutCard: View {
    let onContactSupport: () -> Void
    let onPrivacyPolicy: () -> Void
    let onTermsOfService: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(icon: "info.circle.fill", title: "About and Support")

                // Support links
                VStack(alignment: .leading, spacing: 12) {
                    supportLink("Contact Support", action: onContactSupport)
                    supportLink("Privacy Policy", action: onPrivacyPolicy)
                    supportLink("Terms of Service", action: onTermsOfService)
                }

                // Cat illustration fallback + version
                VStack(spacing: 8) {
                    Group {
                        if UIImage(named: "cat-illustration") != nil {
                            Image("cat-illustration")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "pawprint.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.accentTeal)
                        }
                    }
                    .frame(height: 100)
                    .accessibilityHidden(true)

                    Text("StressMonitor v1.0.0")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
        }
    }

    private func supportLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primaryBlue)
        }
        .accessibilityLabel(title)
    }
}

#Preview {
    AboutCard(
        onContactSupport: {},
        onPrivacyPolicy: {},
        onTermsOfService: {}
    )
    .padding()
    .background(Color.adaptiveSettingsBackground)
}

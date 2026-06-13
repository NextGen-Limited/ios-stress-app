import SwiftUI

/// Privacy settings card with iCloud sync toggle, privacy note, and CSV export.
struct PrivacyCard: View {
    @Binding var iCloudSyncEnabled: Bool
    let onExportCSV: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(
                    icon: "lock.shield.fill",
                    title: "Privacy",
                    color: .settingsIconPurple
                )

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("iCloud Sync")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Sync settings across devices")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $iCloudSyncEnabled)
                        .labelsHidden()
                        .tint(.primaryGreen)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("iCloud sync. Sync settings across devices.")

                privacyBanner

                Button(action: onExportCSV) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Export CSV")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.settingsRippleBlue)
                }
                .accessibilityLabel("Export data as CSV")
            }
        }
    }

    private var privacyBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🛡️")
                .font(.system(size: 22))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Your data stays yours")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                Text("Raw RR intervals stay on device. Export only when you choose.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.primary.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.settingsAmberInfo)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.settingsIconYellow.opacity(0.38), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Privacy note. Your data stays yours. Raw RR intervals stay on device. Export only when you choose.")
    }
}

struct PrivacyCard_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyCard(iCloudSyncEnabled: .constant(true), onExportCSV: {})
            .padding()
            .background(Color.adaptiveSettingsBackground)
    }
}

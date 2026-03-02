import SwiftUI

/// Privacy settings card with iCloud sync toggle, privacy note, and CSV export
struct PrivacyCard: View {
    @Binding var iCloudSyncEnabled: Bool
    let onExportCSV: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(icon: "lock.shield.fill", title: "Privacy")

                // iCloud Sync toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.system(size: 15, weight: .regular))
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

                // Privacy assurance banner
                Text("We never upload raw RR intervals. All processing happens on your device.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.bannerYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 4, x: 0, y: 2)
                    .accessibilityLabel("Privacy note: We never upload raw RR intervals. All processing happens on your device.")

                // Export CSV button
                Button(action: onExportCSV) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 14))
                        Text("Export CSV")
                            .font(.system(size: 14, weight: .regular))
                    }
                    .foregroundColor(.accentTeal)
                }
                .accessibilityLabel("Export data as CSV")
            }
        }
    }
}

#Preview {
    @Previewable @State var iCloud = true

    PrivacyCard(iCloudSyncEnabled: $iCloud, onExportCSV: {})
        .padding()
        .background(Color.adaptiveSettingsBackground)
}

import SwiftUI

/// Data sharing card for Settings screen with export and sync options
struct DataSharingCard: View {
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                SettingsSectionHeader(
                    iconImage: "menu-icon",
                    title: "Data Sharing"
                )

                // Widgets Row
                HStack(spacing: 23) {
                    ComplicationWidget(title: "Export", icon: "square.and.arrow.up")
                    ComplicationWidget(title: "Sync", icon: "arrow.triangle.2.circlepath")
                }
                .padding(.top, 23)

                // Button
                HStack {
                    Spacer()
                    ShareButton {
                        // Placeholder action
                    }
                    Spacer()
                }
                .padding(.top, 24)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    DataSharingCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}

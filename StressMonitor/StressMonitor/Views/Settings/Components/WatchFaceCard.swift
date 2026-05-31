import SwiftUI

/// Watch face and complications card for Settings screen
struct WatchFaceCard: View {
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                SettingsSectionHeader(
                    iconImage: "watch-icon",
                    title: "Watch face & Complications"
                )

                // Widgets Row
                HStack(spacing: 23) {
                    ComplicationWidget(title: "Circular")
                    ComplicationWidget(title: "Graphic")
                }
                .padding(.top, 23)

                // Button
                HStack {
                    Spacer()
                    AddComplicationButton {
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
    WatchFaceCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}

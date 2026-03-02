import SwiftUI

/// Widget size selection card for Settings screen (iOS home screen widgets)
struct WidgetCard: View {
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                SettingsSectionHeader(
                    icon: "rectangle.3.group",
                    title: "Widget"
                )

                // Widget size previews
                HStack(spacing: 23) {
                    ComplicationWidget(title: "Medium", icon: "rectangle.fill")
                    ComplicationWidget(title: "Small", icon: "square.fill")
                }
                .padding(.top, 23)

                // Add widget button
                HStack {
                    Spacer()
                    AddWidgetButton {
                        // Placeholder: open widget picker
                    }
                    Spacer()
                }
                .padding(.top, 24)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Add widget button for iOS home screen widget setup
private struct AddWidgetButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text("Add Widget")
                    .font(.system(size: 14.9, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 277)
            .frame(height: 35.5)
            .background(Color.accentTeal)
            .clipShape(Capsule())
            .shadow(AppShadow.settingsCard)
        }
        .accessibilityLabel("Add widget to home screen")
    }
}

#Preview {
    WidgetCard()
        .padding()
        .background(Color.adaptiveSettingsBackground)
}

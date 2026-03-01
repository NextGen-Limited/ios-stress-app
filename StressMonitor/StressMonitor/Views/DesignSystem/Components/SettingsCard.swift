import SwiftUI

/// Card container for Settings screen with shadow and adaptive background
struct SettingsCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.settingsCardPadding

    init(padding: CGFloat = Spacing.settingsCardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
            .shadow(AppShadow.settingsCard)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsCard {
            Text("Settings Card Content")
                .foregroundColor(.primary)
        }
        SettingsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("Card description text goes here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .background(Color.adaptiveSettingsBackground)
}

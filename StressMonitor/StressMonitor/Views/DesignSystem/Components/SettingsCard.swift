import SwiftUI

/// Card container for Settings screen with shadow and adaptive background
struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    var padding: CGFloat = Spacing.settingsCardPadding

    init(padding: CGFloat = Spacing.settingsCardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(cardShape)
            .shadow(
                color: colorScheme == .dark ? Color.clear : Color.settingsCardShadowColor.opacity(0.07),
                radius: colorScheme == .dark ? 0 : 10,
                x: 0,
                y: colorScheme == .dark ? 0 : 4
            )
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.settingsCardRadius, style: .continuous)
    }
}

struct SettingsCard_Previews: PreviewProvider {
    static var previews: some View {
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
}

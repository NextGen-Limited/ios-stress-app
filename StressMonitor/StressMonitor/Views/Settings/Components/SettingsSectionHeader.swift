import SwiftUI

/// Section header for Settings cards with icon and title
struct SettingsSectionHeader: View {
    let icon: String?
    let iconImage: String?
    let title: String

    init(icon: String? = nil, iconImage: String? = nil, title: String) {
        self.icon = icon
        self.iconImage = iconImage
        self.title = title
    }

    var body: some View {
        HStack(spacing: 13) {
            if let imageName = iconImage {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.accentTeal)
                    .frame(width: 24, height: 24)
            } else if let systemIcon = icon {
                Image(systemName: systemIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentTeal)
                    .frame(width: 24, height: 24)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.accentTeal)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsSectionHeader(iconImage: "watch-icon", title: "Watch face & Complications")
        SettingsSectionHeader(icon: "gear", title: "General Settings")
    }
    .padding()
}
